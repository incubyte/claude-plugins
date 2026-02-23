---
description: Generate Playwright-BDD step definitions from feature files with semantic step matching
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/update-bee-state.sh:*)", "Bash(npm:*)", "Bash(node:*)", "AskUserQuestion", "Skill", "Task"]
---

# Playwright-BDD Test Generation Command

You are orchestrating Phase 1 of the Playwright-BDD plugin: semantic step matching and step definition generation.

## Command Invocation

```
/bee:playwright /absolute/path/to/feature.feature
```

## Workflow

### Step 1: Validate Input Path

The developer provides: `$ARGUMENTS`

**Path Validation:**
- Extract file path from arguments
- Check if path is absolute (starts with `/` on Unix or drive letter on Windows)
- If relative path: error immediately with "Please provide absolute path to .feature file"
- Check if path points to a directory (not a .feature file)
- If directory: error with "Path must be a .feature file, not a directory"
- Check if file exists at the provided path
- If not found: error with "Feature file not found at [path]"
- Check file extension is `.feature`
- If wrong extension: error with "Path must point to a .feature file"

**Gherkin Syntax Validation:**
- Read the feature file content
- Validate Gherkin syntax using basic parser (check for Feature:, Scenario:, Given/When/Then keywords)
- If syntax errors found: error with "Invalid Gherkin syntax at line X: [description]"
- Do not proceed to matching if validation fails

### Step 2: Repository Structure Detection

**Delegate to context-gatherer:**
- Invoke `bee:context-gatherer` agent via Task tool
- Pass task description: "Analyze Playwright-BDD repo structure. Detect if this is UI-only (features/ + src/steps/ + src/pages/), API-only (features/ + src/steps/ + src/services/), or hybrid (both UI and API layers). Identify step definition file patterns, import styles, and parameter conventions."
- Store result: repo structure type (UI/API/hybrid/unrecognized), step definitions path, code patterns

**Handle Unrecognized Structure:**
- If context-gatherer returns "unrecognized":
  - Use AskUserQuestion: "Where should step definitions be created? Provide absolute path to step definitions directory."
  - Validate provided path exists and is writable
  - Store path for file generation

**Hybrid Repo Handling:**
- If structure is "hybrid":
  - Use AskUserQuestion: "What needs to be implemented? [UI only / API only / Both]"
  - Store answer for future phases (not used in Phase 1)
  - Note: Phase 1 only generates step definitions, no POMs or services yet

### Step 3: Step Definition Indexing

**Delegate to step-matcher agent:**
- Create agent invocation (will create agent file in Slice 3 of TDD plan)
- Invoke `bee:playwright-step-matcher` via Task tool
- Pass: repo root path, step definitions directory path
- Agent scans for `*.steps.ts` and `*.steps.js` files
- Agent parses Cucumber expressions: `Given('text {string}', ...)`, `When('count {int}', ...)`, etc.
- Agent builds index: step text, file path, line number, usage in feature files

**Handle Duplicate Steps:**
- If agent detects duplicate steps (same text in multiple files):
  - Error with "Duplicate step definitions detected: '[step text]' defined in [file1] (line X), [file2] (line Y). Please consolidate duplicates before proceeding."
  - Do not continue until developer resolves

**Handle Empty Repo:**
- If agent finds zero step definitions:
  - Show message: "No existing step definitions detected. All steps will be created as new."
  - Skip matching phase, proceed to code generation with minimal template

### Step 4: Parse Feature File and Extract Scenarios

**Parse Gherkin:**
- Read feature file content (already validated in Step 1)
- Extract scenarios: scenario name, Given/When/Then steps
- Store all scenarios for processing

**Process First Scenario:**
- Select first scenario from list
- Extract steps: step keyword (Given/When/Then), step text
- Prepare for matching phase

### Step 5: Semantic Step Matching

**For each step in the scenario:**
- Delegate to `bee:playwright-step-matcher` agent via Task tool
- Pass: step text, indexed step definitions
- Agent performs LLM-based semantic matching (prompt: "Rate semantic similarity 0-100")
- Agent returns ranked candidates with confidence scores
- Agent filters candidates below 50% confidence
- Agent orders by confidence, then by usage frequency if tied

**Generate Approval File:**
- Create file: `docs/specs/playwright-bdd-approval-[feature-name]-scenario-[N].md`
- For each step, show:
  ```markdown
  ## Step: "[step text]"

  Candidates:
  1. "[existing step]" - [confidence]% confidence
     Used in: [feature-file-1] (line X), [feature-file-2] (line Y)

  Decision:
  - [ ] Reuse candidate #1
  - [ ] Create new step definition
  ```
- If no matches found for a step: skip approval, mark as "create new"
- Add note at bottom: "Check exactly one box per step"

### Step 6: Wait for Approval

- Tell developer: "Review approval file at [path]. Check one decision per step. Type 'check' when ready."
- Wait for developer to mark checkboxes
- Read approval file
- Validate: exactly one box checked per step
- If multiple boxes checked: error with "Please select only one decision per step"
- If no boxes checked: error with "Please make a decision for all steps before proceeding"
- Parse decisions: which steps to reuse (and from which file), which to create new

### Step 7: Generate Step Definitions

**Delegate to code-generator agent:**
- Create agent invocation (will create agent file in Slice 6 of TDD plan)
- Invoke `bee:playwright-code-generator` via Task tool
- Pass: approved decisions, repo structure context, step definitions directory
- Agent analyzes existing step files to detect code structure (imports, parameter style, formatting)
- Agent generates new step definitions matching repo patterns
- Agent handles reused steps (no code generation needed)

**File Naming:**
- One file per feature: `features/search.feature` → `src/steps/search.steps.ts`
- If file already exists: append new steps
- Use file extension matching existing files (.ts or .js)

### Step 8: Review Generated Code

**Create Review File:**
- Create file: `docs/specs/playwright-bdd-review-[feature-name].md`
- Format:
  ```markdown
  # Generated Step Definitions - [Feature Name]

  ## Scenario: [Scenario Name]

  ### src/steps/[feature].steps.ts

  ```typescript
  Given('[step text]', async ({ page }) => {
    // TODO: Implement step
  });
  ```

  - [ ] Reviewed
  ```
- Include all generated code for this scenario

**Wait for Review Approval:**
- Tell developer: "Review generated code at [path]. Mark [x] Reviewed when ready."
- Read review file
- Check for `[x] Reviewed` checkbox
- If not checked: wait for developer
- If checked: proceed to write files

### Step 9: Write Files to Disk

- Write generated step definition files to their target paths
- Confirm completion: "Step definitions written to [file paths]. Scenario [N] complete."

### Step 10: Continue to Next Scenario

- Check if more scenarios exist in feature file
- If yes:
  - Use AskUserQuestion: "Continue to next scenario in this feature? [Yes / No]"
  - If "Yes": repeat from Step 4 (parse next scenario)
  - If "No": exit with "Feature processing complete. Re-invoke command for remaining scenarios."
- If no more scenarios: "All scenarios complete. Step definitions written."

## Error Handling

- **Context-gatherer fails**: "Could not analyze repo structure. [error details]"
- **Semantic matching fails**: Retry once, then error: "Semantic matching failed for step '[step text]'. [error details]"
- **Code generation fails**: "Could not generate step definition for '[step text]'. [error details]"
- **File write fails**: "Could not write file [path]. [error details]"
- All errors include actionable next steps

## State Management

Use the state script for tracking:
- Current feature file path
- Current scenario number
- Repo structure detection result (cached)

Update state at key transitions:
- After validation: `set --current-phase "validating feature file"`
- After repo detection: `set --current-phase "analyzing repo structure"`
- During matching: `set --current-slice "Scenario [N]: matching steps"`
- During generation: `set --current-slice "Scenario [N]: generating code"`
- After completion: `set --current-phase "playwright-bdd complete"`

## Notes

- Phase 1 only generates step definitions (no page objects or services)
- Follows existing bee patterns: command orchestrates, agents execute
- File-based approval workflow with `[ ] Reviewed` checkpoints
- One scenario at a time (not batch mode)
