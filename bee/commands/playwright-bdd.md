---
description: Generate Playwright-BDD step definitions from feature files with semantic step matching
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/update-bee-state.sh:*)", "Bash(npm:*)", "Bash(node:*)", "AskUserQuestion", "Skill", "Task"]
---

# Playwright-BDD Test Generation Command

You are orchestrating the complete Playwright-BDD workflow across 5 phases:
- **Phase 1**: Semantic step matching and step definition generation
- **Phase 2**: Page Object Model generation (UI tests)
- **Phase 3**: Service layer generation (API tests)
- **Phase 4**: Utility extraction and generation
- **Phase 5**: Scenario outline conversion and test execution

## Command Invocation

```
/bee:playwright /absolute/path/to/feature.feature
```

## Workflow

### Step 1: Validate Input Path

The developer provides: `$ARGUMENTS`

**@ Mention Detection:**
- Check if `$ARGUMENTS` starts with `@` character
- If yes, proceed to @ mention path resolution
- If no, continue with existing absolute path validation

**@ Mention Path Resolution:**

**Detection:**
- If `$ARGUMENTS` starts with `@`, extract filename: `@search.feature` → `search.feature`
- If `@` with no filename: error "@ mention requires a filename. Example: @search.feature"
- If multiple arguments detected (contains space after first argument): error "Command accepts only one feature file path. Please specify one: @search.feature OR /absolute/path.feature"

**Filename Validation:**
- Check if filename ends with `.feature` extension
- If no extension: error "@ mention must include .feature extension. Example: @search.feature"
- If wrong extension (e.g., `@test.txt`): error "@ mention must reference a .feature file. Found: @[filename]"

**File Search:**
- Use Glob tool to search recursively in:
  - `features/**/*.feature`
  - `tests/features/**/*.feature`
  - `e2e/features/**/*.feature`
- Filter results to exact filename match (case-sensitive)
- Limit search to first 50 feature files found (performance constraint)
- If more than 50 files in search directories: show "Found N feature files. Scanning first 50 for @ mention resolution."

**Result Handling:**

**Zero matches:**
```
Error: File not found via @ mention: '@[filename]'

Searched in:
- features/
- tests/features/
- e2e/features/

No matches found. Check spelling or provide absolute path starting with /
```
Do not proceed to path validation.

**Single match:**
- Resolve to absolute path automatically (no confirmation needed)
- Continue to existing path validation below (file exists, .feature extension, Gherkin syntax)

**Multiple matches (2+):**
- Use AskUserQuestion to present all matching paths
- Format: "Found multiple files named '[filename]'. Which one?"
- Options: Show each absolute path as separate option + "Cancel" option
- If developer selects a path: use that path, continue to validation
- If developer cancels: exit workflow with "Feature file selection cancelled."

**Path Validation:**
- If @ mention was resolved: use resolved absolute path
- Otherwise: extract file path from arguments
- Check if path is absolute (starts with `/` on Unix or drive letter on Windows)
- If relative path: error with helpful conversion suggestions:
  ```
  Error: Relative path provided: '[input-path]'

  Playwright-BDD requires absolute paths.

  Did you mean one of these?
  - [cwd]/[input-path] (current directory)
  - [repo-root]/[input-path] (repository root)

  Or provide full path starting with / (Unix) or C:\ (Windows)
  ```
- Check if path points to a directory (not a .feature file)
- If directory: error with file listing:
  ```
  Error: Path is a directory, not a .feature file: '[path]'

  Feature files in this directory:
  [list .feature files in directory, max 10]

  Specify which file to process, for example:
  /bee:playwright [path-to-specific-file]
  ```
- Check if file exists at the provided path
- If not found: error with diagnostics:
  ```
  Error: Feature file not found: '[path]'

  Checking for common issues:
  - File exists with different case? [check case-insensitive match]
  - File has typo in extension? [check .features, .gherkin]
  - File in different directory? [search repo for filename]

  [If alternatives found:]
  Did you mean: '[found-path]'?

  [If not found:]
  Create the feature file first, then run /bee:playwright
  ```
- Check file extension is `.feature`
- If wrong extension: error with suggestion:
  ```
  Error: File must have .feature extension: '[path]' (has '[actual-ext]')

  [If extension is .features, .gherkin, .spec, .test:]
  This appears to be a feature file with non-standard extension.
  Rename to: '[path-with-feature-ext]'
  Then re-run /bee:playwright
  ```

**Gherkin Syntax Validation:**
- Read the feature file content
- Validate Gherkin syntax using basic parser (check for Feature:, Scenario:, Given/When/Then keywords)
- If syntax errors found: error with detailed guidance:
  ```
  Error: Invalid Gherkin syntax in '[path]'

  Line [X]: [line content]
  Error: [specific syntax error description]

  Example of correct syntax:
  [show corrected line or similar valid example]

  Fix the syntax and re-run /bee:playwright
  ```
- Do not proceed to matching if validation fails

### Step 1.5: Cache Check and Invalidation

**Count current files:**
- Use Glob to count `.feature` files recursively in common directories (features/, tests/features/, e2e/features/)
- Use Glob to count step definition files: `**/*.steps.ts` and `**/*.steps.js`
- Store counts: `current_feature_count`, `current_step_count`

**Check cache status:**
- Use Bash to invoke cache-reader.sh: `bash bee/scripts/cache-reader.sh validate $current_feature_count $current_step_count`
- Script returns one of: `missing`, `fresh`, `stale`, `corrupt`
- Note: Partial cache (missing expected sections) is detected by cache-reader.sh and returned as `missing` status
- Store result: `cache_status`

**Handle cache status:**

**If `cache_status == "missing"`:**
- **Check for zero files scenario:**
  - If `current_feature_count == 0` AND `current_step_count == 0`:
    - Show message: "Repository has zero feature files and zero step files. Creating empty cache."
    - Invoke: `bash bee/scripts/cache-writer.sh write --empty`
    - Show confirmation: "Empty cache created with warning note. Cache will be invalidated when files are added."
    - Exit workflow with message: "No feature files to process. Add feature files and re-run /bee:playwright-bdd"
  - Otherwise:
    - Show message: "No cache found. Running initial analysis..."
    - Continue to Step 2 (all 4 agents will run)
    - After all agents complete successfully (Step 3.5 writes cache using cache-writer.sh)
      - Invoke: `bash bee/scripts/cache-writer.sh write --flows "N" --patterns "M" --steps "P" --feature-files "$current_feature_count" --step-files "$current_step_count" --context "context text" --flow-catalog "flow text" --pattern-catalog "pattern text" --steps-catalog "steps text"`
      - Show confirmation: "Cache updated with latest analysis"

**If `cache_status == "corrupt"`:**
- Use AskUserQuestion: "Cache file is corrupt. Re-analyze? [Yes / Cancel]"
- If "Yes": continue to Step 2 (run all agents), write cache after completion
- If "Cancel": exit workflow with message "Workflow cancelled. Fix or delete docs/playwright-init.md to proceed."

**If `cache_status == "stale"`:**
- Read cached counts using cache-reader.sh:
  - `cached_features=$(bash bee/scripts/cache-reader.sh get --field feature_file_count)`
  - `cached_steps=$(bash bee/scripts/cache-reader.sh get --field step_file_count)`
- Calculate deltas:
  - `feature_delta = current_feature_count - cached_features`
  - `step_delta = current_step_count - cached_steps`
- Use AskUserQuestion: "Cache is stale (file count changed: ${feature_delta} features, ${step_delta} steps). Re-analyze? [Yes (Recommended) / Use stale cache / Cancel]"
- Recommended option: "Yes (Recommended)" is auto-selected
- If "Yes (Recommended)": continue to Step 2 (run all agents), write cache after completion
- If "Use stale cache": load cached data, skip agents, continue to Step 4 with cached results
  - Read cache: `cached_data=$(bash bee/scripts/cache-reader.sh get)`
  - Parse Summary section for counts
  - Show message: "Using cached analysis from [last_updated]. Cache contains: N flows, M patterns, P step definitions"
  - Store cached context, flow analysis, pattern selections, step index in workflow state
  - Skip Steps 2, 2.25, 2.5, 3 (agents will not run)
- If "Cancel": exit workflow with message "Workflow cancelled."

**If `cache_status == "fresh"`:**
- Read last updated timestamp: `last_updated=$(bash bee/scripts/cache-reader.sh get --field last_updated)`
- Format timestamp for display (extract from cache using cache-reader.sh)
- Use AskUserQuestion: "Cache is fresh (last updated: ${formatted_timestamp}). [Use cache (Recommended) / Re-analyze anyway / Cancel]"
- Recommended option: "Use cache (Recommended)" is auto-selected
- If "Use cache (Recommended)": load cached data, skip agents, continue to Step 4 with cached results
  - Read cache: `cached_data=$(bash bee/scripts/cache-reader.sh get)`
  - Parse Summary section for counts
  - Show message: "Using cached analysis from [formatted_timestamp]. Cache contains: N flows, M patterns, P step definitions"
  - Store cached context, flow analysis, pattern selections, step index in workflow state
  - Skip Steps 2, 2.25, 2.5, 3 (agents will not run)
- If "Re-analyze anyway": continue to Step 2 (run all agents), write cache after completion
- If "Cancel": exit workflow with message "Workflow cancelled."

**Cache write after agent completion:**
- Only write cache if ALL agents complete successfully (context-gatherer, flow-analyzer, pattern-detector, step-matcher)
- If any agent fails: do NOT write cache (preserve existing cache or remain cache-missing)
- Write cache in Step 3.5 (after Step 3: Step Definition Indexing completes successfully)
- Gather data from all agent results:
  - Flow count from flow-analyzer result
  - Pattern count from pattern-detector result
  - Step count from step-matcher result
  - Context text from context-gatherer result
  - Flow catalog text from flow-analyzer result
  - Pattern catalog text from pattern-detector result
  - Steps catalog text from step-matcher result
- Invoke cache-writer.sh with all required fields
- Show confirmation: "Cache updated with latest analysis"

**Skip agent invocations when using cache:**
- When cache is loaded (fresh or stale): set workflow flag `using_cache = true`
- In Step 2: if `using_cache == true`, skip context-gatherer invocation, load cached context instead
- In Step 2.25: if `using_cache == true`, skip flow-analyzer invocation, load cached flow catalog instead
- In Step 2.5: if `using_cache == true`, skip pattern-detector invocation, load cached pattern selections instead
- In Step 3: if `using_cache == true`, skip step-matcher invocation, load cached steps catalog instead
- In Step 3.5: if `using_cache == true`, skip cache write (no agents ran, cache was loaded)
- Continue to Step 4 with cached data

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
  - Store answer: `hybrid_mode = "UI" | "API" | "Both"`
  - If "Both": implement UI path completely (Phase 2), then API path (Phase 3)
  - Note: Phase 1 only generates step definitions, no POMs or services yet

### Step 2.25: Application Flow Analysis

**Check if flow analysis should run:**
- Only run if 3 or more feature files exist in repo (minimum for meaningful flow patterns)
- Skip if repo is empty or has fewer than 3 feature files (show message: "Fewer than 3 feature files found. Skipping flow analysis.")

**Delegate to flow analyzer:**
- Invoke `bee:playwright-flow-analyzer` agent via Task tool
- Pass: repo root path, feature files directory (from context-gatherer)
- Agent scans all feature files and returns flow analysis with common sequences, flow graph, and step positions
- Store result in workflow state for step-matcher to access

**Handle results:**

**If agent fails:**
- Log error: "Flow analysis failed: [error]. Continuing with step matching."
- Continue to Step 2.5 without blocking workflow
- Step-matcher will use semantic matching only (without flow context)

**If insufficient data:**
- If agent returns warning about insufficient feature files: show warning
- Continue to Step 2.5 (no flow context available for step-matcher)

**If flow analysis succeeds:**
- Show summary: "Analyzed N feature files, identified M common sequences"
- Store flow analysis result for step-matcher to use in Step 5
- Continue to Step 2.5

### Step 2.5: Pattern Detection (Optional)

**Check if pattern detection should run:**
- Only run if 2 or more feature files exist in repo
- Skip if repo is empty (no feature files found)
- Skip if only 1 feature file exists (show message: "Only one feature file found. Skipping pattern detection.")

**Delegate to pattern detector:**
- Invoke `bee:playwright-pattern-detector` agent via Task tool
- Pass repo root path
- Agent scans feature files (max 50) and returns detected patterns JSON

**Handle results:**

**If agent fails:**
- Log error: "Pattern detection failed: [error]. Continuing with step matching."
- Continue to Step 3 without blocking workflow

**If no patterns detected:**
- Show message: "No repeating patterns detected across feature files."
- Continue to Step 3

**If patterns detected:**
- For each pattern in results:
  - Show pattern description
  - Show number of feature files using this pattern
  - Show 2-3 example scenarios
  - Use AskUserQuestion: "Found repeating pattern '[description]' in N feature files. Extract as reusable step/utility?"
  - Options: "Yes (Recommended)" / "No" / "Skip remaining patterns"
  - If developer selects "Skip remaining patterns": stop showing patterns, continue to Step 3
  - If developer selects "Yes": add pattern description to selections array
  - If developer selects "No": skip this pattern, continue to next

**Store pattern selections:**
- After all patterns processed (or developer skips remaining):
  - Store selections in Bee state via update-bee-state.sh
  - Command: `scripts/update-bee-state.sh set --playwright-patterns-selected '[pattern1, pattern2, ...]'`
  - Format: JSON array of pattern descriptions marked for extraction
- Pattern selections are available for Phase 4 (Utility Generation) to read from state

**Continue workflow:**
- After pattern detection completes, continue to Step 3 (Step Definition Indexing)
- No changes to Step 3 or later steps

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

### Step 3.5: Write Cache (If Agents Ran)

**Check if cache write should occur:**
- Only write cache if `using_cache == false` (agents ran, not loaded from cache)
- Only write if ALL 4 agents completed successfully (context-gatherer, flow-analyzer, pattern-detector, step-matcher)
- If any agent failed: do NOT write cache (preserve existing cache or remain cache-missing)
- If cache was loaded: skip this step entirely

**Gather data from agent results:**
- Extract from workflow state (stored during Steps 2, 2.25, 2.5, 3):
  - Context text from context-gatherer result
  - Flow catalog text from flow-analyzer result (or empty string if flow analysis was skipped)
  - Pattern catalog text from pattern-detector result (or empty string if pattern detection was skipped)
  - Steps catalog text from step-matcher result
- Extract counts from agent results:
  - Flow count from flow-analyzer result (or 0 if skipped)
  - Pattern count from pattern-detector result (or 0 if skipped)
  - Step count from step-matcher result
- Use file counts from Step 1.5: `current_feature_count`, `current_step_count`

**Invoke cache writer:**
- Command: `bash bee/scripts/cache-writer.sh write --flows "N" --patterns "M" --steps "P" --feature-files "$current_feature_count" --step-files "$current_step_count" --context "context text" --flow-catalog "flow text" --pattern-catalog "pattern text" --steps-catalog "steps text"`
- Replace placeholders:
  - `N` = flow count from flow-analyzer
  - `M` = pattern count from pattern-detector
  - `P` = step count from step-matcher
  - `"context text"` = full context summary from context-gatherer
  - `"flow text"` = flow catalog from flow-analyzer (or empty string)
  - `"pattern text"` = pattern catalog from pattern-detector (or empty string)
  - `"steps text"` = steps catalog from step-matcher

**Confirm completion:**
- Show message: "Cache updated with latest analysis"
- Cache is now ready for next workflow run

**Continue to next step:**
- Proceed to Step 4 (Parse Feature File and Extract Scenarios)

### Step 4: Parse Feature File and Extract Scenarios

**Parse Gherkin:**
- Read feature file content (already validated in Step 1)
- Extract scenarios: scenario name, Given/When/Then steps
- Store all scenarios for processing

**Process First Scenario:**
- Select first scenario from list
- Extract steps: step keyword (Given/When/Then), step text
- Prepare for matching phase

### Step 4.5: Scenario Implementation Filtering

**Check scenario count:**
- If only one scenario exists: skip filtering, proceed to Step 5 with that scenario
- If multiple scenarios exist: continue with filtering workflow

**Present implementation status question:**
- Use AskUserQuestion: "This feature file has N scenarios. Which scenarios already have step definitions?"
- multiSelect: true
- Options: One checkbox per scenario with scenario name
- Example option format: "Scenario 1: User searches for products"
- Default: all unchecked (assume all scenarios are new)

**Handle selection outcomes:**

**If ALL scenarios marked as implemented:**
- Show message: "All scenarios already implemented. Extracting patterns for future use."
- For each marked scenario:
  - Extract step texts (Given/When/Then)
  - Add to pattern catalog with comment: "# Pattern from implemented scenario: [scenario name]"
- Store enriched patterns in workflow state
- Show confirmation: "Extracted N steps as patterns from M scenarios. Patterns available for gap detection in future workflows."
- Exit workflow with message: "No new scenarios to process. Re-run with a feature file containing unimplemented scenarios."

**If NONE marked as implemented:**
- Show message: "Processing all N scenarios as new."
- Store all scenarios in queue for processing
- Continue to Step 5 with first scenario

**If SOME marked as implemented:**
- Calculate counts: `implemented_count = marked scenarios`, `unimplemented_count = total - marked`
- Show message: "Processing M unimplemented scenarios. Extracting patterns from N implemented scenarios."
- For each marked scenario:
  - Extract step texts (Given/When/Then)
  - Add to pattern catalog with comment: "# Pattern from implemented scenario: [scenario name]"
- Store enriched patterns in workflow state
- Filter scenario queue: keep only unimplemented scenarios
- Show confirmation: "Pattern extraction complete. Proceeding with M unimplemented scenarios."
- Continue to Step 5 with first unimplemented scenario

**Pattern extraction format:**
- Extract each step as: `[keyword] [step text]` (e.g., "Given I am on the homepage")
- Group by scenario name for traceability
- Pass to step-matcher in Step 5 as additional context for semantic matching
- Patterns inform gap detection suggestions but do not create new step definitions

**Update scenario numbering:**
- When generating approval files in Step 5:
  - If filtering was skipped (single scenario): use "Scenario 1"
  - If all scenarios processed: use "Scenario 1", "Scenario 2", etc. (original numbering)
  - If some filtered: renumber to reflect unimplemented queue (e.g., if Scenarios 1 and 3 are unimplemented, they become "Scenario 1" and "Scenario 2" in approval files)
  - Store mapping: `original_scenario_number -> queue_position` for developer reference

### Step 5: Semantic Step Matching

**For each step in the scenario:**
- Delegate to `bee:playwright-step-matcher` agent via Task tool
- Pass: step text, indexed step definitions, flow analysis result (from Step 2.25, null if skipped), current scenario step sequence
- Agent performs LLM-based semantic matching (prompt: "Rate semantic similarity 0-100")
- Agent applies flow context filtering (if flow analysis available): checks position, preceding/following context, flow stage
- Agent returns ranked candidates with confidence scores
- Agent filters candidates below 50% confidence (semantic) AND low contextual relevance (if flow context available)
- Agent orders by confidence, then by usage frequency if tied

**Generate Approval File:**
- Create file: `docs/specs/playwright-bdd-approval-[feature-name]-scenario-[N].md`
- For each step from step-matcher results, handle based on decision type:

**When decision is "candidates_found":**
  ```markdown
  ## Step: "[step text]"

  Candidates:
  1. "[existing step]" - [confidence]% confidence
     Used in: [feature-file-1] (line X), [feature-file-2] (line Y)

  Decision:
  - [ ] Reuse candidate #1
  - [ ] Create new step definition
  ```

**When decision is "gap_detected":**
  ```markdown
  ## Step: "[step text]"

  **Status:** Gap detected (no existing matches found)

  **Suggested Step Definitions:**

  Based on your codebase patterns, here are recommended implementations:

  ### Suggestion 1 (Score: [score])
  **Step Definition:**
  ```typescript
  [stepDefinition text]
  ```
  **Source:** [pattern catalog / flow catalog / existing steps]
  **Target File:** `[recommendedLocation.filePath]` ([createNew ? "new file" : "add to existing"])
  [If pattern_catalog: **Pattern Type:** [metadata.patternType]]
  [If flow_catalog: **Flow Stage:** [metadata.flowStage]]
  [If existing_steps: **Related Step:** `[metadata.relatedStep]` ([metadata.relationshipType])]

  ### Suggestion 2 (Score: [score])
  [... repeat structure for each suggestion, up to 5 ...]

  **Decision:**
  - [ ] Use suggestion #1
  - [ ] Use suggestion #2
  [... one option per suggestion ...]
  - [ ] Create custom step definition

  **Note:** Only one choice allowed per step.
  ```

**When decision is "no_matches":**
  ```markdown
  ## Step: "[step text]"

  **Status:** No matches found

  **Decision:**
  - [ ] Create new step definition

  **Note:** This step will be created from scratch.
  ```

- Add file header with instructions:
  ```markdown
  # Playwright-BDD Approval - [Feature Name] - Scenario [N]

  Review each step and select ONE decision per step. Type 'check' when ready.

  **Instructions:**
  - For steps with candidates: choose to reuse or create new
  - For gaps with suggestions: choose a suggestion OR create custom implementation
  - For steps with no matches: creation is automatic

  ---
  ```

- Add note at bottom: "Check exactly one box per step"

### Step 6: Wait for Approval

- Tell developer: "Review approval file at [path]. Check one decision per step. Type 'check' when ready."
- Wait for developer to mark checkboxes
- Read approval file
- Validate: exactly one box checked per step
- If multiple boxes checked: error with "Please select only one decision per step"
- If no boxes checked: error with "Please make a decision for all steps before proceeding"
- Parse decisions for each step:
  - **Reuse candidate**: store file path and line number of existing step
  - **Create new**: flag as new step creation (no suggestion used)
  - **Use suggestion #N**: store suggestion index, step definition text, and target file location from gapMetadata
  - **Create custom**: flag as new step creation (gap detected but custom implementation chosen)

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

### Step 9: Write Step Definition Files to Disk

- Write generated step definition files to their target paths
- Confirm completion: "Step definitions written to [file paths]."

### Step 10: Phase 2 — Page Object Generation (UI Tests Only)

**Check if Phase 2 should run:**
- If repo structure is "API-only": skip Phase 2, go to Step 11
- If repo structure is "UI-only": proceed with Phase 2
- If repo structure is "hybrid":
  - If `hybrid_mode = "API"`: skip Phase 2, go to Step 11
  - If `hybrid_mode = "UI"` or `hybrid_mode = "Both"`: proceed with Phase 2

**Delegate to POM matcher:**
- Invoke `bee:playwright-pom-matcher` agent via Task tool
- Pass: generated step definitions, page objects directory path
- Agent classifies steps as UI vs non-UI
- Agent performs semantic matching against existing page objects
- Returns: UI steps with POM matches, non-UI steps, ambiguous steps

**Handle ambiguous classifications:**
- If ambiguous steps found: use AskUserQuestion for each
- "Is this step UI or non-UI? [UI / non-UI]"
- Update classification based on developer input

**Skip if no UI steps:**
- If all steps are non-UI: show "No UI steps detected. Skipping page object generation."
- Go to Step 11

**Generate POM approval file:**
- Create file: `docs/specs/playwright-bdd-pom-approval-[feature]-scenario-[N].md`
- For each UI step, show POM candidates:
  ```markdown
  ## Step: "[step text]"

  Page Object Candidates:
  1. "[POM class name]" - [confidence]% confidence
     Methods: "[method name]" ([confidence]%)
     Used in: [step-file-1] (line X)

  Decision:
  - [ ] Reuse existing method from candidate #1
  - [ ] Add new method to candidate #1
  - [ ] Create new page object class
  ```
- If no candidates found: only show "Create new page object class" option

**Wait for POM approval:**
- Tell developer: "Review POM approval file at [path]. Check one decision per UI step."
- Wait for developer to check boxes
- Validate: exactly one box per UI step
- Parse decisions

**Choose locator generation strategy:**

**Step 1: Offer three-option choice:**
- Use AskUserQuestion: "How should I generate locators for UI elements?"
- Options:
  - "Chrome DevTools - inspect running app (Recommended)" - if app is running locally
  - "Analyze UI repository" - if component source code is available
  - "Provide outerHTML manually" - fallback for both above
- Developer selects one strategy

**Step 2: Execute chosen strategy:**

**If "Chrome DevTools" selected:**
- Check Chrome MCP availability (call tabs_context_mcp)
- If unavailable: Show message "Chrome MCP not available. Install Claude in Chrome extension." → Fall back to asking for repo or outerHTML choice
- If available:
  - Detect dev server command from package.json (priority: "dev" > "start" > "serve")
  - Use AskUserQuestion: "Start dev server using `npm run dev`?"
    - Options: "Yes (start server)" / "Already running at URL" / "Use different command"
  - If "Yes": Execute command via Bash with run_in_background
  - If "Already running": Accept developer-provided URL (validate http:// or https://)
  - If "Use different command": Accept custom command and execute
  - Verify server accessibility (HTTP request to base URL)
  - If server fails: Show error + logs, prompt "Server failed to start. [Check configuration / Provide different command / Fall back to outerHTML]"
  - Store dev server URL for locator generator
  - Keep server running (do not shut down - Phase 1 limitation)

**If "Analyze UI repository" selected:**
- Use AskUserQuestion: "Provide UI repository location:"
  - Options: "GitHub URL" / "Local path"
- If GitHub URL: validate format (starts with https://github.com/), store for locator generator
- If local path: validate format (absolute path), store for locator generator

**If "Provide outerHTML manually" selected:**
- For each step marked "Add new method" or "Create new":
  - Use AskUserQuestion: "Provide outerHTML for '[step text]' element:"
  - Accept HTML string input
  - Store outerHTML for each UI element

**Delegate to locator generator:**
- Invoke `bee:playwright-locator-generator` agent via Task tool
- Pass:
  - Step description (e.g., "search button", "email input field")
  - Action type (click/fill/select)
  - Strategy preference: "chrome" | "repo" | "html"
  - Dev server URL (if Chrome strategy, otherwise null)
  - UI repo path (if repo strategy, otherwise null)
  - outerHTML (if HTML strategy, otherwise null)
- Agent workflow:
  1. **Chrome strategy**: Create tab, navigate to dev server, find element (hybrid: find tool → javascript fallback), extract attributes, generate locator, test interaction, return with validation status
  2. **Repo strategy**: Analyze component files for existing data-testid/ARIA attributes, return locators from repo code
  3. **HTML strategy**: Parse outerHTML to extract attributes and generate locators
  4. **Graceful degradation**: Chrome unavailable → fall back to repo or HTML
- Returns: locator string, strategy, stability, warnings, source, validated (true for Chrome strategy with successful interaction test)

**Phase 1 limitation for Chrome strategy:**
- Generates locator for ONE element only (first UI step requiring new method/class)
- Multi-element support comes in Phase 2 of Chrome DevTools integration
- If multiple UI elements need locators in this scenario, Chrome strategy is invoked once, then falls back to repo/HTML for remaining elements

**Delegate to POM generator:**
- Invoke `bee:playwright-pom-generator` agent via Task tool
- Pass: approved decisions, generated locators, existing POM patterns, step definitions to update
- Agent generates new POM methods or classes
- Agent updates step definitions (replaces TODO with POM method calls)
- Returns: generated POMs, updated step definitions

**Create POM review file:**
- Create file: `docs/specs/playwright-bdd-pom-review-[feature]-scenario-[N].md`
- Format:
  ```markdown
  # Generated Page Objects - [Feature] - Scenario [N]

  ## Page Objects

  ### src/pages/SearchPage.ts
  ```typescript
  [generated POM code]
  ```

  ## Updated Step Definitions

  ### src/steps/search.steps.ts
  ```typescript
  [updated step definition with POM calls]
  ```

  - [ ] Reviewed
  ```

**Wait for POM review approval:**
- Tell developer: "Review generated POMs at [path]. Mark [x] Reviewed when ready."
- Read review file
- Check for `[x] Reviewed` checkbox
- If checked: proceed to write files

**Write POM files and updated step definitions:**
- Write new/updated page object files
- Write updated step definition files (with POM calls instead of TODOs)
- Confirm: "Page objects and step definitions updated."

### Step 11: Phase 3 — Service Layer Generation (API Tests Only)

**Check if Phase 3 should run:**
- If repo structure is "UI-only": skip Phase 3, go to Step 12
- If repo structure is "API-only": proceed with Phase 3
- If repo structure is "hybrid":
  - If `hybrid_mode = "UI"`: skip Phase 3, go to Step 12
  - If `hybrid_mode = "API"` or `hybrid_mode = "Both"`: proceed with Phase 3

**Delegate to service matcher:**
- Invoke `bee:playwright-service-matcher` agent via Task tool
- Pass: generated step definitions, services directory path
- Agent classifies steps as API vs non-API
- Agent performs semantic matching against existing services
- Returns: API steps with service matches, non-API steps

**Skip if no API steps:**
- If all steps are non-API: show "No API steps detected. Skipping service generation."
- Go to Step 12

**Generate service approval file:**
- Create file: `docs/specs/playwright-bdd-service-approval-[feature]-scenario-[N].md`
- Show service candidates with confidence scores
- Developer decides: reuse method / add new method / create new service

**Collect API response structures:**
- For new methods/services: ask developer for JSON response example or schema
- Store for type-safe parsing

**Delegate to service generator:**
- Invoke `bee:playwright-service-generator` agent via Task tool
- Pass: approved decisions, response structures, existing service patterns
- Agent generates service methods or classes
- Agent updates step definitions (replaces TODO with service calls)

**Create service review file:**
- Format same as POM review file but for services
- Wait for `[x] Reviewed` approval

**Write service files and updated step definitions:**
- Write new/updated service files
- Write updated step definition files
- Confirm: "Services and step definitions updated."

### Step 12: Phase 4 — Utility Generation

**Detect utility opportunities:**
- Invoke `bee:playwright-utility-generator` agent via Task tool
- Pass: all generated code (step definitions, POMs, services)
- Agent detects: data transformation, duplicated logic, complex calculations

**Skip if no opportunities:**
- If agent finds zero utility opportunities: go to Step 13

**Ask developer for each opportunity:**
- Use AskUserQuestion for each detected opportunity
- "Should this logic be a utility function? [Yes / No / Inline]"
- Show code snippet

**Generate utilities if approved:**
- Agent generates utility functions following existing patterns
- Agent updates calling code to import and use utilities

**Create utility review file:**
- Format same as previous review files
- Wait for `[x] Reviewed` approval

**Write utility files and updated code:**
- Write new utility files to `src/utils/`
- Write updated step definitions/POMs/services with utility imports
- Confirm: "Utilities generated and integrated."

### Step 13: Phase 5 (Optional) — Scenario Outline Conversion

**Ask if developer wants outline analysis:**
- Use AskUserQuestion: "Analyze for scenario outline opportunities? [Yes / No]"
- If "No": skip to Step 14

**Delegate to outline converter:**
- Invoke `bee:playwright-outline-converter` agent via Task tool
- Pass: complete feature file content, all scenarios
- Agent detects scenarios with identical structure but varying data
- Returns: conversion suggestions with Examples tables

**Skip if no opportunities:**
- If agent finds zero conversion opportunities: "No outline opportunities detected."
- Go to Step 14

**Show conversion suggestions:**
- For each suggested conversion:
  - Show before/after preview
  - Show which step definitions need updating
  - Show which other feature files would be affected
- Use AskUserQuestion: "Convert these scenarios to outline? [Yes / No]" (per conversion)

**Apply approved conversions:**
- Update feature file: replace scenarios with scenario outline
- Update step definitions: add parameter support (e.g., hardcoded → `{string}`)
- Update other affected feature files if developer approved

**Create outline review file:**
- Show updated feature file with scenario outline
- Show updated step definitions
- Wait for `[x] Reviewed` approval

**Write updated files:**
- Write feature file with scenario outlines
- Write parameterized step definitions
- Confirm: "Scenario outlines created."

### Step 14: Phase 5 (Optional) — Test Execution

**Ask if developer wants to run tests:**
- Use AskUserQuestion: "Run generated tests now? [Yes / No]"
- If "No": skip to Step 15

**Delegate to test executor:**
- Invoke `bee:playwright-test-executor` agent via Task tool
- Pass: package.json path, feature file name
- Agent detects test scripts (test:bdd, test:e2e, playwright)
- Returns: detected scripts

**Ask which script to use:**
- Show detected scripts
- Use AskUserQuestion: "Which script should I use? [script1 / script2 / Custom]"

**Execute tests:**
- Agent runs selected script
- Captures stdout, stderr, exit code
- Returns results with pass/fail summary

**Show test results:**
- Format output
- Show: "X tests passed, Y failed"
- If failures: show error details
- Confirm: "Test execution complete."

### Step 15: Continue to Next Scenario

- Check if more scenarios exist in the unimplemented scenario queue (filtered in Step 4.5)
- If yes:
  - Use AskUserQuestion: "Continue to next scenario in this feature? [Yes / No]"
  - If "Yes": repeat from Step 5 (semantic step matching) with next scenario from queue
  - If "No": exit with "Feature processing complete. Re-invoke command for remaining scenarios."
- If no more scenarios: "All scenarios complete. All phases done."

**Note:** Step 4.5 filtering is not re-run for subsequent scenarios - the queue established in Step 4.5 persists throughout the workflow.

## Error Handling

### Agent Delegation Error Handling

For EVERY agent invocation via Task tool, implement robust error handling:

1. **On agent failure (invocation, crash, or invalid output)**:
   - Log error: "Agent [agent-name] failed at [phase-name]: [error message]"
   - Include context: agent name, input parameters, phase description
   - Show user:
     ```
     Error: Playwright-BDD failed during [phase name]

     Agent: [agent-name]
     Phase: [description]
     Error: [error message]

     Possible causes:
     - [specific cause based on error type]
     - [additional causes]

     Next steps:
     - Check [file] for partial results
     - Re-run from Step X, or
     - Abort and investigate error
     ```

2. **On agent timeout**:
   - Do NOT silently continue to next phase
   - Error:
     ```
     Error: Agent [name] timed out after [duration]

     This may indicate:
     - Large repository (too many files to analyze)
     - Network issues (API calls)
     - Resource constraints (memory/CPU)

     Next steps:
     - Try with smaller feature file (fewer scenarios)
     - Check system resources
     - Re-run with increased timeout
     ```

3. **On malformed agent output**:
   - Validate agent response structure before using
   - Error:
     ```
     Error: Agent [name] returned invalid output

     Expected: [structure description]
     Received: [summary of what was received]

     This indicates an agent implementation issue.
     Next steps:
     - Report this issue with repro steps
     - Abort current workflow
     ```

### Specific Phase Errors

- **Context-gatherer fails**:
  ```
  Error: Could not analyze repo structure

  [Technical error details in collapsible/log]

  Cannot automatically detect repository structure.

  Options:
  1. Specify structure manually:
     - Step definitions directory: [provide path]
     - POMs directory (if UI tests): [provide path]
     - Services directory (if API tests): [provide path]

  2. Fix context gathering issue:
     - [Specific guidance based on error type]
     Then re-run /bee:playwright

  3. Abort workflow
  ```

- **Semantic matching fails**: Retry once with user notification, then error:
  ```
  Error: Semantic matching failed for step '[step text]' after 2 attempts

  Possible causes:
  - API rate limiting (wait and retry)
  - Network connectivity issues
  - API authentication failure

  Error details: [full error message]

  Next steps:
  - Check API connectivity
  - Verify API key is valid
  - If rate limited, wait 60 seconds and re-run
  ```

- **Code generation fails**: "Could not generate step definition for '[step text]'. [error details with recovery options]"
- **File write fails**: "Could not write file [path]. [error details - check permissions, disk space, path validity]"
- **Approval validation fails**: Specify WHICH steps have invalid selections with line numbers for easy navigation
- All errors include actionable next steps and context for debugging

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
