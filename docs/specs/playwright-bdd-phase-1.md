# Spec: Playwright-BDD Plugin — Phase 1 (Walking Skeleton)

## Overview

Phase 1 establishes the core workflow for Playwright-BDD test generation: semantic step matching, reuse vs. create decisions, and step definition code generation. A developer provides a Gherkin feature file, the plugin analyzes each step in the first scenario, performs semantic matching against existing step definitions with confidence scores, presents candidates with usage context, accepts developer approval for reuse vs. create decisions, and generates new step definition code following the repo's existing patterns. No page objects, no services — just step definitions. This validates that semantic matching works and establishes the approval workflow foundation for all future phases.

**What Phase 1 Delivers:**
- Command invocation: `/bee:playwright /absolute/path/to/feature.feature`
- Repo structure detection (UI/API/hybrid) via context-gatherer
- Step definition indexing with Cucumber expression support
- LLM-based semantic step matching with confidence scores (0-100 scale, hide <50%)
- Match display showing confidence + feature file usage context
- File-based approval workflow for reuse vs. create decisions
- Step definition code generation matching repo patterns
- Per-scenario processing with "Continue to next scenario?" flow
- Review file for entire feature with `[ ] Reviewed` checkpoint

## Acceptance Criteria

### Command Interface

- [ ] Command accepts absolute path to .feature file: `/bee:playwright /absolute/path/to/feature.feature`
- [ ] Command rejects relative paths with clear error: "Please provide absolute path to .feature file"
- [ ] If path points to directory (not .feature file), error immediately: "Path must be a .feature file, not a directory"
- [ ] If .feature file does not exist at path, error: "Feature file not found at [path]"
- [ ] If .feature file exists but has Gherkin syntax errors, validate upfront and show clear error: "Invalid Gherkin syntax at line X: [description]" before any matching
- [ ] Command invokes context-gatherer agent before starting step matching to analyze repo structure

### Repo Structure Detection

- [ ] Context-gatherer detects repo structure: UI-only (features/ + src/steps/ + src/pages/), API-only (features/ + src/steps/ + src/services/), or hybrid (both src/pages/ and src/services/)
- [ ] If repo structure is hybrid, ask developer: "What needs to be implemented? [UI only / API only / Both]" and store answer for future phases (not used in Phase 1)
- [ ] If repo structure doesn't match expected patterns (no src/steps/, no features/), ask developer: "Where should step definitions be created?" and use provided path
- [ ] Repo structure detection happens once at workflow start, cached for entire feature file processing

### Step Definition Indexing

- [ ] Plugin scans repo for existing step definition files (*.steps.ts, *.steps.js patterns)
- [ ] Plugin parses Cucumber expression format: `Given('user is on {string} page', ...)`, `When('user clicks {int} times', ...)`, `Then('result is {word}', ...)`
- [ ] Plugin indexes step text, file path, and line number for each step definition
- [ ] Plugin tracks usage: which feature files reference each step definition (by searching feature files for matching step text)
- [ ] If duplicate step definitions exist (same step text in multiple files), flag as error: "Duplicate step definitions detected: [step text] in [file1], [file2]. Please consolidate before proceeding."
- [ ] If no existing step definitions found (empty repo), show single message: "No existing step definitions detected. All steps will be created as new." and skip matching phase

### Scenario Processing

- [ ] For feature file with multiple scenarios, process first scenario only initially
- [ ] After first scenario completes (step matching, approval, code generation, review), ask: "Continue to next scenario in this feature? [Yes / No]"
- [ ] If "Yes", process next scenario with same workflow (matching, approval, generation, review)
- [ ] If "No", exit with message: "Scenario complete. Re-invoke command to process remaining scenarios."
- [ ] Process scenarios sequentially (never batch mode)

### Semantic Step Matching

- [ ] For each Given/When/Then step in the scenario, perform LLM-based semantic similarity matching against all indexed step definitions
- [ ] Use Claude to compare step text: "Rate semantic similarity between '[feature step]' and '[existing step]' on 0-100 scale considering meaning, not just wording"
- [ ] Hide any matches with confidence score below 50%
- [ ] If multiple candidates have same confidence score, order by usage frequency (show most-used step first)
- [ ] If no matches above 50% confidence, show: "No matches found. Creating new step definition." and proceed to code generation for that step

### Match Display

- [ ] For each step with matches ≥50% confidence, show candidates in this format:

```
Step: "[step text from feature file]"

Candidates:
1. "[existing step text]" - [confidence]% confidence
   Used in: [feature-file-1.feature] (line X), [feature-file-2.feature] (line Y)

2. "[existing step text]" - [confidence]% confidence
   Used in: [feature-file-3.feature] (line Z)

Decision:
- [ ] Reuse candidate #1
- [ ] Reuse candidate #2
- [ ] Create new step definition
```

- [ ] Show confidence score as integer percentage (e.g., "85% confidence")
- [ ] Show all feature files that use each candidate step (file path + line number)
- [ ] Present all steps in the scenario for approval in a single file before code generation starts

### Approval Workflow

- [ ] Create approval file at `docs/specs/playwright-bdd-approval-[feature-name]-scenario-[N].md` with all steps and their match candidates
- [ ] Use checkbox format for developer decisions: `[ ] Reuse candidate #1`, `[ ] Reuse candidate #2`, `[ ] Create new step definition`
- [ ] Wait for developer to check exactly one box per step before proceeding
- [ ] If developer checks multiple boxes for one step, error: "Please select only one decision per step"
- [ ] If developer checks no boxes for any step, error: "Please make a decision for all steps before proceeding"

### Code Generation — File Naming

- [ ] For new step definitions, create one file per feature: if feature is `features/search.feature`, create `src/steps/search.steps.ts`
- [ ] If step definition file already exists for this feature, append new steps to existing file
- [ ] If repo uses different file extension (.js instead of .ts), match the existing pattern
- [ ] Place generated files in the step definitions directory detected by context-gatherer (or developer-specified path if structure is unrecognized)

### Code Generation — Step Definition Template

- [ ] Analyze existing step definition files to detect code structure pattern (imports, parameter style, formatting)
- [ ] Generate new step definitions matching exactly the structure found in existing files:
  - Same import statements (e.g., `import { Given, When, Then } from '@cucumber/cucumber'`)
  - Same parameter destructuring style (e.g., `async ({ page })` vs `async function(world)`)
  - Same formatting (indentation, spacing, quote style)
  - Same naming conventions
- [ ] For Cucumber expression parameters, preserve parameter types: `{string}`, `{int}`, `{word}`, etc.
- [ ] Include `// TODO: Implement step` comment in function body for developer to complete
- [ ] If no existing step definitions exist (empty repo), use minimal template:

```typescript
Given('[step text]', async ({ page }) => {
  // TODO: Implement step
});
```

### Code Generation — Review File

- [ ] Create single review file for entire feature (all scenarios) at `docs/specs/playwright-bdd-review-[feature-name].md`
- [ ] Include all generated step definitions organized by scenario
- [ ] Show file path, full code block for each generated step, and single `[ ] Reviewed` checkbox at end
- [ ] Format:

```markdown
# Generated Step Definitions - [Feature Name]

## Scenario: [Scenario 1 Name]

### src/steps/[feature].steps.ts

```typescript
Given('[step text]', async ({ page }) => {
  // TODO: Implement step
});

When('[step text]', async ({ page }) => {
  // TODO: Implement step
});
```

## Scenario: [Scenario 2 Name]

### src/steps/[feature].steps.ts

```typescript
Then('[step text]', async ({ page }) => {
  // TODO: Implement step
});
```

- [ ] Reviewed
```

- [ ] Wait for developer to check `[ ] Reviewed` before writing files to disk
- [ ] After approval, write all generated step definition files to their target paths
- [ ] Confirm completion: "Step definitions written to [file paths]. Scenario [N] complete."

### Error Handling

- [ ] If context-gatherer agent fails, error: "Could not analyze repo structure. [error details]"
- [ ] If semantic matching API call fails, retry once, then error: "Semantic matching failed for step '[step text]'. [error details]"
- [ ] If code generation fails (template analysis error), error: "Could not generate step definition for '[step text]'. [error details]"
- [ ] If file write fails (permissions, disk full), error: "Could not write file [path]. [error details]"
- [ ] All errors should include actionable next steps for developer

## Edge Cases

### Empty Repo (No Existing Steps)
- When indexing finds zero step definitions:
  - Show single upfront message: "No existing step definitions detected. All steps will be created as new."
  - Skip semantic matching phase entirely (no per-step "No matches found" messages)
  - Proceed directly to code generation using minimal template (no existing patterns to analyze)
  - Use default file naming: `src/steps/[feature-name].steps.ts`

### Malformed Feature File
- Before any processing, validate Gherkin syntax using parser
- If syntax errors found, show error with line number and description before any matching
- Example error: "Invalid Gherkin syntax at line 12: Expected 'Given/When/Then' but found 'And' at start of scenario"
- Do not proceed to matching or generation phases

### Unrecognized Repo Structure
- If context-gatherer cannot detect standard directory patterns:
  - Ask developer: "Where should step definitions be created? Provide absolute path to step definitions directory."
  - Validate provided path exists and is writable
  - Use provided path for all file generation in this workflow
  - Store answer for future scenarios in same session

### Duplicate Step Definitions
- During indexing, if same step text appears in multiple files:
  - Collect all occurrences with file paths
  - Error before matching phase: "Duplicate step definitions detected: '[step text]' defined in [file1] (line X), [file2] (line Y). Please consolidate duplicates before proceeding."
  - Do not continue until developer resolves duplicates manually

### Confidence Score Ties
- When multiple candidates have identical confidence scores:
  - Count feature file usage for each candidate
  - Order by usage frequency descending (most-used first)
  - If usage frequency is also tied, order alphabetically by existing step text
  - Display order is deterministic (same input always produces same candidate order)

### Zero High-Confidence Matches
- When all semantic match scores are below 50%:
  - Show: "No matches found. Creating new step definition."
  - Do not show low-confidence matches (no "Show anyway" option)
  - Proceed directly to code generation for that step
  - Developer has no reuse decision to make

### Multiple Scenarios Per Feature
- Process scenarios sequentially, never in parallel
- After scenario N completes (approval + generation + review):
  - Ask: "Continue to next scenario in this feature? [Yes / No]"
  - If Yes: repeat workflow for scenario N+1
  - If No: exit gracefully with summary
- All scenarios for one feature write to same step definition file (append mode)
- Review file accumulates all scenarios (one review file per feature, not per scenario)

## Workflow Diagram

```
Developer: /bee:playwright /path/to/feature.feature
    ↓
Validate: path is absolute, file exists, Gherkin syntax is valid
    ↓
Invoke context-gatherer: detect repo structure (UI/API/hybrid)
    ↓
If hybrid: ask "What needs implementation? UI/API/Both" (store for future phases)
    ↓
If unrecognized structure: ask "Where should step definitions be created?"
    ↓
Index existing step definitions (scan *.steps.ts files, parse Cucumber expressions)
    ↓
If duplicates found: error and exit
    ↓
If no steps found: show "All steps will be created as new" and skip matching
    ↓
For first scenario: extract all Given/When/Then steps
    ↓
For each step: perform LLM-based semantic matching (0-100 score)
    ↓
Generate approval file with candidates (hide <50% confidence)
    ↓
Developer approves: check boxes for reuse vs. create decisions
    ↓
Analyze existing step files to detect code structure patterns
    ↓
Generate new step definitions matching repo patterns
    ↓
Present review file with all generated code + [ ] Reviewed checkbox
    ↓
Developer checks [ ] Reviewed
    ↓
Write step definition files to disk
    ↓
Ask: "Continue to next scenario? [Yes/No]"
    ↓
If Yes: repeat for next scenario (append to same files)
If No: exit with summary
```

## API Shape (Internal)

### Context-Gatherer Agent Input
```typescript
{
  command: "analyze-playwright-repo",
  repoRoot: "/absolute/path/to/repo"
}
```

### Context-Gatherer Agent Output
```typescript
{
  structure: "UI" | "API" | "hybrid" | "unrecognized",
  stepDefinitionsPath: "/absolute/path/to/src/steps" | null,
  patterns: {
    fileExtension: ".ts" | ".js",
    importStyle: "es6" | "commonjs",
    parameterStyle: "destructured" | "world-object"
  }
}
```

### Semantic Matching LLM Prompt Template
```
Compare these two test steps semantically. Rate their similarity on a 0-100 scale where:
- 100 = identical meaning (even if wording differs)
- 70-99 = very similar intent, likely the same test action
- 50-69 = related but distinct actions
- 0-49 = unrelated

Feature file step: "[new step text]"
Existing step definition: "[existing step text with Cucumber expressions]"

Consider:
1. Are they testing the same behavior?
2. Would parameter substitution make them identical?
3. Is the domain action the same?

Respond with ONLY a number 0-100.
```

### Step Definition Index Structure
```typescript
interface StepDefinition {
  text: string;                    // e.g., "user is on {string} page"
  filePath: string;                // e.g., "/repo/src/steps/navigation.steps.ts"
  lineNumber: number;              // e.g., 15
  usedInFeatures: Array<{         // where this step is used
    featurePath: string;
    lineNumber: number;
  }>;
  usageCount: number;              // total number of feature file references
}
```

## Out of Scope for Phase 1

- **Page object generation** — deferred to Phase 2
- **Service layer generation** — deferred to Phase 3
- **Utility function generation** — deferred to Phase 4
- **Scenario outline conversion** — deferred to Phase 5
- **Test execution integration** — deferred to Phase 5
- **Regex pattern support** — Phase 1 only supports Cucumber expressions (plain strings + `{string}`, `{int}`, `{word}`, etc.)
- **Batch mode** — Phase 1 always processes per-scenario with approval checkpoints
- **Tabular test case format** — Phase 1 only supports Gherkin .feature files
- **Jira ticket format** — deferred to future phases
- **Directory scanning** — Phase 1 requires explicit .feature file path
- **Automatic POM/service detection** — Phase 1 generates step definitions only (no page object or service references)
- **Step definition refactoring** — Phase 1 only creates new steps or reuses existing (no modification of existing steps)

## Technical Context

- **Patterns to follow:** incubyte/playwright-bdd-hybrid-framework (reference for step definition structure, Cucumber expression usage, file organization)
- **Key dependencies:** context-gatherer agent (repo structure analysis), Gherkin parser (syntax validation), Claude API (semantic matching)
- **Files to create:**
  - `bee/commands/playwright-bdd.md` (command orchestrator)
  - `bee/agents/playwright-step-matcher.md` (semantic matching agent)
  - `bee/agents/playwright-code-generator.md` (step definition generator agent)
- **Approval workflow:** File-based with `[ ] Reviewed` checkboxes (consistent with bee collaboration loop pattern)
- **Risk level:** MODERATE — LLM-based semantic matching is non-deterministic, confidence threshold tuning required, code generation must match varied repo patterns

## Success Signal

Developer can provide a Gherkin feature file with 3-5 steps in first scenario where:
- 2 steps have high-confidence matches (>70%) to existing step definitions
- Developer approves reuse for those 2 steps
- 3 steps have no confident matches
- Plugin generates 3 new step definitions matching repo's code style
- Generated step definitions are syntactically correct TypeScript/JavaScript
- Generated code compiles without errors
- Developer reviews and approves generated code
- All steps (reused + generated) are ready for implementation

**Done when:** Developer can successfully implement their first scenario using Phase 1 workflow from command invocation to approved generated code without manual step definition searching or file creation.

- [x] Reviewed
