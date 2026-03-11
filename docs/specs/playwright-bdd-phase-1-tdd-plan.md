# TDD Plan: Playwright-BDD Plugin — Phase 1 (Walking Skeleton)

## Execution Instructions

Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] → [x]).
Continue until all items are done.
If stuck after 3 attempts, mark ⚠️ and move to the next independent step.

## Context

- **Source**: `/Users/akashincubyte/Documents/incubyte/Repo/claude plugins/claude-plugins/docs/specs/playwright-bdd-phase-1.md`
- **Phase**: Phase 1 — Walking Skeleton
- **Risk Level**: MODERATE
- **Architecture**: Command + Agent Delegation (following `build.md`, `qc.md`, `browser-test.md` patterns)
- **Pattern References**: Existing bee commands for orchestration; agent delegation via Task tool

## Codebase Analysis

### File Structure
- Command orchestrator: `bee/commands/playwright-bdd.md`
- Step matcher agent: `bee/agents/playwright-step-matcher.md`
- Code generator agent: `bee/agents/playwright-code-generator.md`
- Reuse: `bee/agents/context-gatherer.md` (existing)
- Test files: No test infrastructure detected — this is a markdown-based agent system
- Agent frontmatter: YAML with `name`, `description`, `model`, `color`, `tools`, `skills`, `examples`

### Test Infrastructure
- Framework: Behavior-driven (markdown specs with acceptance criteria checkboxes)
- Validation: Manual verification against acceptance criteria in spec
- Pattern: Create → Validate → Iterate (no automated unit tests for markdown agents)

### Conventions
- Commands live in `bee/commands/`
- Agents live in `bee/agents/`
- Commands delegate to agents via Task tool
- Agents have frontmatter with allowed tools and skills
- State management via bash scripts (`update-bee-state.sh`)
- File-based approval workflow with `[ ] Reviewed` checkboxes
- Error messages must be actionable and specific

---

## Implementation Strategy

This is a command + agent system, not a traditional codebase. The "tests" are the acceptance criteria in the spec. The TDD approach is:

1. **RED**: Write agent/command definition that satisfies specific acceptance criteria
2. **GREEN**: Validate the definition against the acceptance criteria
3. **REFACTOR**: Improve structure, error handling, and delegation flow

We'll build in **6 slices**, each delivering a meaningful unit of behavior:

---

## Slice 1: Command Interface & Path Validation

**Goal**: Command accepts .feature file path and validates it before any processing.

**Acceptance Criteria (from spec)**:
- Command accepts absolute path to .feature file
- Rejects relative paths with clear error
- Rejects directory paths (not .feature file)
- Rejects non-existent files
- Validates Gherkin syntax upfront

### Behavior 1: Command accepts absolute path to .feature file

**Given** a valid absolute path to a .feature file
**When** developer invokes `/bee:playwright /absolute/path/to/feature.feature`
**Then** command accepts the path and proceeds to validation

- [ ] **RED**: Create `bee/commands/playwright-bdd.md` with basic structure
  - Location: `bee/commands/playwright-bdd.md`
  - Include frontmatter: `description`, `allowed-tools`, agent delegation pattern
  - Define command invocation pattern: `/bee:playwright [path]`
  - Acceptance: Command definition exists with path parameter handling

- [ ] **RUN**: Verify command structure follows `build.md` pattern

- [ ] **GREEN**: Implement path acceptance logic
  - Parse `$ARGUMENTS` to extract file path
  - Store path for downstream processing
  - Include detailed comments explaining flow

- [ ] **RUN**: Verify path extraction logic is clear

- [ ] **REFACTOR**: Ensure error handling structure is in place for next behaviors

- [ ] **COMMIT**: "feat: add playwright-bdd command with path parameter"

---

### Behavior 2: Reject relative paths

**Given** a relative path is provided
**When** developer invokes `/bee:playwright ./feature.feature`
**Then** command shows error: "Please provide absolute path to .feature file"

- [ ] **RED**: Add path validation — check if path starts with `/` (Unix) or drive letter (Windows)
  - Implementation: Check path format before proceeding
  - Error message: "Please provide absolute path to .feature file"

- [ ] **RUN**: Verify error message matches spec exactly

- [ ] **GREEN**: Implement absolute path check
  - Add validation step after path extraction
  - Return error and exit if relative path detected

- [ ] **RUN**: Verify validation prevents further processing

- [ ] **REFACTOR**: Extract path validation into clear section with comment

- [ ] **COMMIT**: "feat: validate absolute path requirement"

---

### Behavior 3: Reject directory paths

**Given** path points to a directory, not a .feature file
**When** developer invokes `/bee:playwright /path/to/directory`
**Then** command shows error: "Path must be a .feature file, not a directory"

- [ ] **RED**: Add directory detection
  - Implementation: Check if path is a directory using file system check
  - Error message: "Path must be a .feature file, not a directory"

- [ ] **RUN**: Verify error message matches spec

- [ ] **GREEN**: Implement directory check
  - Use Read tool to attempt reading path
  - If error indicates directory, show specific error

- [ ] **RUN**: Verify directory detection works

- [ ] **REFACTOR**: Consolidate validation checks into validation section

- [ ] **COMMIT**: "feat: reject directory paths with clear error"

---

### Behavior 4: Reject non-existent files

**Given** path points to non-existent file
**When** developer invokes `/bee:playwright /path/to/nonexistent.feature`
**Then** command shows error: "Feature file not found at [path]"

- [ ] **RED**: Add file existence check
  - Implementation: Attempt to read file with Read tool
  - Error message: "Feature file not found at [path]"

- [ ] **RUN**: Verify error message is actionable

- [ ] **GREEN**: Implement file existence validation
  - Attempt Read before any processing
  - Catch error and show clear message with exact path

- [ ] **RUN**: Verify error handling

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "feat: validate feature file existence"

---

### Behavior 5: Validate Gherkin syntax upfront

**Given** .feature file exists but has invalid Gherkin
**When** command reads the file
**Then** show error: "Invalid Gherkin syntax at line X: [description]" before any matching

- [ ] **RED**: Add Gherkin validation step
  - Implementation: Parse Gherkin content to detect syntax errors
  - Error format: "Invalid Gherkin syntax at line X: [description]"
  - Note: Actual parsing logic will be in step matcher agent

- [ ] **RUN**: Verify validation happens before delegation

- [ ] **GREEN**: Implement validation delegation
  - Read .feature file content
  - Add note that syntax validation will be first step of processing
  - Plan to delegate to step matcher agent for actual parsing

- [ ] **RUN**: Verify flow is clear

- [ ] **REFACTOR**: Add comments explaining delegation to step matcher

- [ ] **COMMIT**: "feat: add gherkin syntax validation placeholder"

---

## Slice 2: Repo Structure Detection via Context-Gatherer

**Goal**: Detect repo structure and determine where step definitions should be created.

**Acceptance Criteria (from spec)**:
- Invoke context-gatherer to analyze repo structure
- Detect UI-only, API-only, or hybrid
- Handle hybrid case with user question
- Handle unrecognized structure with user question
- Cache detection result for entire feature

### Behavior 1: Invoke context-gatherer before step matching

**Given** path validation passed
**When** command proceeds to processing
**Then** context-gatherer agent is invoked to analyze repo structure

- [ ] **RED**: Add context-gatherer delegation
  - Location: `bee/commands/playwright-bdd.md` (after validation section)
  - Delegation: Use Task tool to invoke `context-gatherer` agent
  - Pass: Task description requesting Playwright repo analysis

- [ ] **RUN**: Verify delegation follows existing command patterns

- [ ] **GREEN**: Implement delegation
  - Add section "Step 1: Analyze Repo Structure"
  - Call Task tool with subagent_type `bee:context-gatherer`
  - Request analysis of Playwright test structure (features/, src/steps/, src/pages/, src/services/)

- [ ] **RUN**: Verify Task call structure

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "feat: delegate to context-gatherer for repo analysis"

---

### Behavior 2: Detect repo structure types

**Given** context-gatherer returns analysis
**When** analyzing the structure
**Then** identify as UI-only, API-only, hybrid, or unrecognized

- [ ] **RED**: Define expected context-gatherer output structure
  - Document expected fields: structure type, stepDefinitionsPath, patterns
  - Reference spec API shape for context-gatherer output

- [ ] **RUN**: Verify output structure matches spec

- [ ] **GREEN**: Add structure detection logic
  - Parse context-gatherer output for structure indicators
  - Map to: "UI", "API", "hybrid", "unrecognized"
  - Store for downstream use

- [ ] **RUN**: Verify structure detection is clear

- [ ] **REFACTOR**: Add comments explaining each structure type

- [ ] **COMMIT**: "feat: parse repo structure from context-gatherer"

---

### Behavior 3: Handle hybrid structure with user question

**Given** repo structure is hybrid
**When** processing context-gatherer result
**Then** ask: "What needs to be implemented? [UI only / API only / Both]" and store answer

- [ ] **RED**: Add hybrid handling
  - Implementation: Check if structure === "hybrid"
  - User question via AskUserQuestion tool
  - Options: "UI only" / "API only" / "Both"

- [ ] **RUN**: Verify question matches spec exactly

- [ ] **GREEN**: Implement hybrid question
  - Add conditional branch for hybrid detection
  - Use AskUserQuestion with exact wording from spec
  - Store answer for future phases (not used in Phase 1, but prepare for Phase 2+)

- [ ] **RUN**: Verify flow handles all options

- [ ] **REFACTOR**: Add comment noting this is for future phase use

- [ ] **COMMIT**: "feat: handle hybrid repo structure with user question"

---

### Behavior 4: Handle unrecognized structure

**Given** repo structure doesn't match expected patterns
**When** context-gatherer returns "unrecognized"
**Then** ask: "Where should step definitions be created?" and use provided path

- [ ] **RED**: Add unrecognized structure handling
  - Implementation: Check if structure === "unrecognized"
  - User question: "Where should step definitions be created? Provide absolute path to step definitions directory."
  - Validate provided path exists and is writable

- [ ] **RUN**: Verify question is actionable

- [ ] **GREEN**: Implement unrecognized handling
  - Add conditional for unrecognized structure
  - Use AskUserQuestion for path
  - Validate path with Read tool
  - Store validated path for code generation phase

- [ ] **RUN**: Verify validation catches invalid paths

- [ ] **REFACTOR**: Extract path validation to reusable logic

- [ ] **COMMIT**: "feat: handle unrecognized repo structure"

---

### Behavior 5: Cache structure detection result

**Given** repo structure is detected
**When** processing multiple scenarios
**Then** reuse cached structure for entire feature file

- [ ] **RED**: Add caching logic
  - Implementation: Store context-gatherer result at workflow start
  - Reference stored result for all scenarios

- [ ] **RUN**: Verify caching approach is clear

- [ ] **GREEN**: Implement caching
  - Store context-gatherer output in workflow state
  - Add comment that this runs once per feature, not per scenario

- [ ] **RUN**: Verify flow is efficient

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "feat: cache repo structure for entire feature"

---

## Slice 3: Step Definition Indexing

**Goal**: Scan and index existing step definitions with Cucumber expression support.

**Acceptance Criteria (from spec)**:
- Scan repo for existing step definition files (*.steps.ts, *.steps.js)
- Parse Cucumber expression format
- Index step text, file path, line number
- Track usage (which features reference each step)
- Detect and flag duplicate step definitions
- Handle empty repo (no existing steps)

### Behavior 1: Create step matcher agent skeleton

**Given** need to index step definitions
**When** creating agent structure
**Then** step matcher agent exists with proper frontmatter

- [ ] **RED**: Create `bee/agents/playwright-step-matcher.md`
  - Location: `bee/agents/playwright-step-matcher.md`
  - Frontmatter: name, description, tools (Read, Grep, Glob), model, color
  - Skills: pattern-matching, clean-code

- [ ] **RUN**: Verify frontmatter matches existing agent patterns

- [ ] **GREEN**: Implement agent skeleton
  - Add agent description: semantic step matching with confidence scoring
  - Include example usage in frontmatter
  - Define mission: index, match, score

- [ ] **RUN**: Verify structure follows conventions

- [ ] **REFACTOR**: Ensure description is clear

- [ ] **COMMIT**: "feat: create playwright-step-matcher agent skeleton"

---

### Behavior 2: Scan for step definition files

**Given** repo structure is known
**When** step matcher agent starts indexing
**Then** scan for *.steps.ts and *.steps.js files

- [ ] **RED**: Add file scanning logic
  - Implementation: Use Glob tool to find `**/*.steps.ts` and `**/*.steps.js`
  - Respect stepDefinitionsPath from context-gatherer

- [ ] **RUN**: Verify glob patterns match spec

- [ ] **GREEN**: Implement scanning
  - Add "Step 1: Scan for Step Definition Files" section
  - Use Glob with both .ts and .js patterns
  - Store list of files found

- [ ] **RUN**: Verify scanning logic is complete

- [ ] **REFACTOR**: Add error handling for scan failures

- [ ] **COMMIT**: "feat: scan repo for step definition files"

---

### Behavior 3: Parse Cucumber expression format

**Given** step definition files found
**When** parsing each file
**Then** extract step text from Given(), When(), Then() calls with Cucumber expressions

- [ ] **RED**: Add Cucumber expression parsing
  - Implementation: Use Grep to find patterns like `Given('...', ...)` with regex
  - Support parameter types: {string}, {int}, {word}, etc.
  - Extract step text, file path, line number

- [ ] **RUN**: Verify parsing approach handles all parameter types

- [ ] **GREEN**: Implement parsing
  - Add "Step 2: Parse Step Definitions" section
  - Use Grep with pattern: `(Given|When|Then)\(['"](.*?)['"]`
  - Build index structure: { text, filePath, lineNumber, usedInFeatures, usageCount }

- [ ] **RUN**: Verify index structure matches spec API shape

- [ ] **REFACTOR**: Extract parsing logic to clear subsection

- [ ] **COMMIT**: "feat: parse cucumber expressions from step files"

---

### Behavior 4: Track step usage in features

**Given** steps are indexed
**When** analyzing usage
**Then** identify which feature files reference each step

- [ ] **RED**: Add usage tracking
  - Implementation: Grep all .feature files for exact step text matches
  - Store feature path + line number for each match
  - Calculate usageCount (total references)

- [ ] **RUN**: Verify tracking approach is efficient

- [ ] **GREEN**: Implement usage tracking
  - Add "Step 3: Track Usage" section
  - For each indexed step, Grep features/ for matching text
  - Build usedInFeatures array with { featurePath, lineNumber }
  - Calculate usageCount

- [ ] **RUN**: Verify usage data is complete

- [ ] **REFACTOR**: Consider performance for large repos (note in comments)

- [ ] **COMMIT**: "feat: track step definition usage across features"

---

### Behavior 5: Detect duplicate step definitions

**Given** multiple step files exist
**When** indexing finds same step text in multiple files
**Then** error: "Duplicate step definitions detected: [step text] in [file1], [file2]"

- [ ] **RED**: Add duplicate detection
  - Implementation: Check for duplicate step text during indexing
  - Error format matches spec exactly
  - Prevent continuation if duplicates found

- [ ] **RUN**: Verify error message is actionable

- [ ] **GREEN**: Implement duplicate check
  - Add "Step 4: Validate No Duplicates" section
  - Track step text in Set/Map during parsing
  - On duplicate, collect all occurrences with file paths
  - Show error and exit

- [ ] **RUN**: Verify duplicate detection works

- [ ] **REFACTOR**: Ensure error lists all duplicates, not just first two

- [ ] **COMMIT**: "feat: detect and flag duplicate step definitions"

---

### Behavior 6: Handle empty repo (no steps)

**Given** no existing step definitions found
**When** indexing completes
**Then** show: "No existing step definitions detected. All steps will be created as new." and skip matching

- [ ] **RED**: Add empty repo handling
  - Implementation: Check if index is empty after scanning
  - Show message exactly as in spec
  - Set flag to skip semantic matching phase

- [ ] **RUN**: Verify message matches spec

- [ ] **GREEN**: Implement empty repo path
  - Add conditional after scanning
  - Show upfront message
  - Return early with empty index (no matching needed)

- [ ] **RUN**: Verify skip logic works

- [ ] **REFACTOR**: Add comment explaining fast path for empty repos

- [ ] **COMMIT**: "feat: handle empty repo case with skip matching"

---

## Slice 4: Semantic Step Matching with LLM

**Goal**: Use Claude to compare steps semantically and generate confidence scores.

**Acceptance Criteria (from spec)**:
- LLM-based semantic similarity for each Given/When/Then step
- Confidence score 0-100 scale
- Hide matches below 50%
- Order by confidence, then usage frequency
- Handle zero high-confidence matches

### Behavior 1: Extract steps from first scenario

**Given** feature file is valid
**When** starting semantic matching
**Then** extract Given/When/Then steps from first scenario only

- [ ] **RED**: Add scenario extraction
  - Implementation: Parse Gherkin to find first scenario
  - Extract only Given/When/Then lines (not Background, not other scenarios)

- [ ] **RUN**: Verify extraction focuses on first scenario

- [ ] **GREEN**: Implement scenario extraction
  - Add "Step 5: Extract First Scenario Steps" section
  - Parse Gherkin structure to identify Scenario blocks
  - Extract step lines from first scenario
  - Store as array of { type: 'Given'|'When'|'Then', text: '...' }

- [ ] **RUN**: Verify structure is correct

- [ ] **REFACTOR**: Add validation for scenarios with no steps

- [ ] **COMMIT**: "feat: extract steps from first scenario"

---

### Behavior 2: Perform LLM semantic matching

**Given** steps extracted and index populated
**When** comparing each feature step to indexed steps
**Then** use LLM to rate similarity 0-100

- [ ] **RED**: Add LLM matching logic
  - Implementation: For each feature step, compare to all indexed steps
  - Use LLM prompt from spec: "Rate semantic similarity between '[feature step]' and '[existing step]' on 0-100 scale"
  - Prompt includes: identical meaning = 100, very similar = 70-99, related = 50-69, unrelated = 0-49

- [ ] **RUN**: Verify prompt matches spec template

- [ ] **GREEN**: Implement semantic matching
  - Add "Step 6: Semantic Matching" section
  - For each feature step, iterate indexed steps
  - Send comparison prompt to Claude (as agent, this is internal reasoning)
  - Parse response to extract numeric score
  - Build candidates array: { stepText, confidence, filePath, lineNumber, usage }

- [ ] **RUN**: Verify matching produces expected output

- [ ] **REFACTOR**: Add error handling for non-numeric LLM responses

- [ ] **COMMIT**: "feat: llm-based semantic step matching"

---

### Behavior 3: Hide matches below 50% confidence

**Given** semantic matching returns candidates with varied scores
**When** filtering candidates
**Then** only show candidates with confidence >= 50%

- [ ] **RED**: Add confidence filtering
  - Implementation: Filter candidates array to keep only confidence >= 50
  - If all candidates below 50%, set flag for "no matches"

- [ ] **RUN**: Verify threshold is 50% exactly

- [ ] **GREEN**: Implement filtering
  - Add filter step after matching
  - Keep only candidates where confidence >= 50
  - Count filtered candidates

- [ ] **RUN**: Verify filtering logic

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "feat: filter out low-confidence matches"

---

### Behavior 4: Order candidates by confidence then usage

**Given** multiple candidates remain after filtering
**When** ordering for display
**Then** sort by confidence DESC, then by usageCount DESC, then alphabetically

- [ ] **RED**: Add sorting logic
  - Implementation: Multi-level sort
  - Primary: confidence descending
  - Secondary: usageCount descending
  - Tertiary: stepText alphabetically ascending

- [ ] **RUN**: Verify sort order matches spec

- [ ] **GREEN**: Implement sorting
  - Add sort step after filtering
  - Use multi-field comparator
  - Result is deterministic (same input → same order)

- [ ] **RUN**: Verify determinism

- [ ] **REFACTOR**: Add comment explaining sort priority

- [ ] **COMMIT**: "feat: sort candidates by confidence and usage"

---

### Behavior 5: Handle zero high-confidence matches

**Given** all matches score below 50%
**When** no candidates remain after filtering
**Then** show: "No matches found. Creating new step definition."

- [ ] **RED**: Add no-match handling
  - Implementation: Check if candidates array is empty
  - Message matches spec exactly
  - Mark step for code generation (no approval needed)

- [ ] **RUN**: Verify message and flow

- [ ] **GREEN**: Implement no-match case
  - Add conditional after filtering
  - Show "No matches found" message
  - Set flag: createNew = true (skip approval for this step)

- [ ] **RUN**: Verify flow proceeds to generation

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "feat: handle zero high-confidence matches"

---

## Slice 5: Approval Workflow

**Goal**: Present match candidates to developer for reuse vs. create decisions.

**Acceptance Criteria (from spec)**:
- Create approval file showing all steps and candidates
- Use checkbox format for decisions
- Wait for developer to check exactly one box per step
- Validate developer selections

### Behavior 1: Generate approval file with match display

**Given** semantic matching complete for all steps in scenario
**When** presenting results
**Then** create `docs/specs/playwright-bdd-approval-[feature-name]-scenario-[N].md` with formatted matches

- [ ] **RED**: Add approval file generation
  - Location: Use Write tool to create approval file
  - Path: `docs/specs/playwright-bdd-approval-[feature-name]-scenario-[N].md`
  - Format matches spec exactly (see lines 63-79 in spec)

- [ ] **RUN**: Verify format matches spec

- [ ] **GREEN**: Implement approval file generation
  - Add "Step 7: Generate Approval File" section
  - For each step, format as:
    ```
    Step: "[step text]"

    Candidates:
    1. "[existing]" - N% confidence
       Used in: [files]

    Decision:
    - [ ] Reuse candidate #1
    - [ ] Create new step definition
    ```
  - Write file with Write tool

- [ ] **RUN**: Verify file structure

- [ ] **REFACTOR**: Extract formatting to helper section

- [ ] **COMMIT**: "feat: generate approval file with candidates"

---

### Behavior 2: Wait for developer approval

**Given** approval file is written
**When** waiting for decision
**Then** instruct developer to check exactly one box per step

- [ ] **RED**: Add approval wait instruction
  - Implementation: Clear message to developer
  - Explain: "Review the approval file, check one box per step, save, and confirm"

- [ ] **RUN**: Verify instruction is clear

- [ ] **GREEN**: Implement wait
  - Add message after file write
  - Use AskUserQuestion: "Approval file created. Review and check one box per step, then confirm."
  - Options: "I've made my decisions, proceed" / "Cancel workflow"

- [ ] **RUN**: Verify user flow

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "feat: wait for developer approval"

---

### Behavior 3: Validate exactly one box checked per step

**Given** developer confirms approval
**When** reading approval file
**Then** validate each step has exactly one checkbox marked

- [ ] **RED**: Add approval validation
  - Implementation: Read approval file back
  - Parse checkboxes: count [x] per step section
  - Error if 0 or 2+ boxes checked for any step

- [ ] **RUN**: Verify validation catches multiple/zero selections

- [ ] **GREEN**: Implement validation
  - Add "Step 8: Validate Approval" section
  - Parse file to extract decisions per step
  - Check: each step has exactly 1 [x]
  - Error messages match spec:
    - Multiple: "Please select only one decision per step"
    - None: "Please make a decision for all steps before proceeding"

- [ ] **RUN**: Verify all error cases

- [ ] **REFACTOR**: Extract parsing logic to subsection

- [ ] **COMMIT**: "feat: validate approval selections"

---

### Behavior 4: Parse approved decisions

**Given** approval validation passed
**When** extracting decisions
**Then** build decision map: step → reuse candidate #N | create new

- [ ] **RED**: Add decision parsing
  - Implementation: Extract which checkbox was marked for each step
  - Build structure: { stepText, decision: 'reuse-1' | 'reuse-2' | 'create' }

- [ ] **RUN**: Verify parsing extracts correct decisions

- [ ] **GREEN**: Implement parsing
  - Scan each step section in approval file
  - Identify which checkbox has [x]
  - Map to decision type
  - Store for code generation phase

- [ ] **RUN**: Verify data structure

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "feat: parse developer approval decisions"

---

## Slice 6: Code Generation & Review

**Goal**: Generate step definition code matching repo patterns and present for review.

**Acceptance Criteria (from spec)**:
- One file per feature (append if exists)
- Analyze existing files to detect code structure patterns
- Generate matching the detected patterns
- Include TODO comments for implementation
- Create review file with [ ] Reviewed checkpoint
- Write files only after review approval

### Behavior 1: Create code generator agent skeleton

**Given** need to generate step definitions
**When** creating agent structure
**Then** code generator agent exists with proper frontmatter

- [ ] **RED**: Create `bee/agents/playwright-code-generator.md`
  - Location: `bee/agents/playwright-code-generator.md`
  - Frontmatter: name, description, tools (Read, Write, Grep, Glob), model, color
  - Skills: clean-code, design-fundamentals

- [ ] **RUN**: Verify frontmatter structure

- [ ] **GREEN**: Implement agent skeleton
  - Add agent description: generate step definitions following repo patterns
  - Include example usage
  - Define mission: analyze patterns, generate code, match style

- [ ] **RUN**: Verify structure

- [ ] **REFACTOR**: Ensure description is clear

- [ ] **COMMIT**: "feat: create playwright-code-generator agent skeleton"

---

### Behavior 2: Analyze existing step file patterns

**Given** repo has existing step definitions
**When** code generator starts
**Then** detect code structure patterns (imports, parameter style, formatting)

- [ ] **RED**: Add pattern analysis
  - Implementation: Read existing step files
  - Extract: import statements, function signature style, indentation, quote style
  - Example patterns to detect:
    - `import { Given, When, Then } from '@cucumber/cucumber'`
    - `async ({ page })` vs `async function(world)`
    - 2-space vs 4-space indentation
    - Single vs double quotes

- [ ] **RUN**: Verify pattern detection is comprehensive

- [ ] **GREEN**: Implement pattern analysis
  - Add "Step 1: Analyze Existing Patterns" section
  - Read 2-3 existing step files
  - Extract common patterns
  - Store as template configuration

- [ ] **RUN**: Verify detection works

- [ ] **REFACTOR**: Add handling for inconsistent patterns (use most common)

- [ ] **COMMIT**: "feat: analyze existing step file patterns"

---

### Behavior 3: Determine target file path

**Given** feature file name and repo structure
**When** determining where to write
**Then** use pattern: `src/steps/[feature-name].steps.ts`

- [ ] **RED**: Add file path determination
  - Implementation: Extract feature name from .feature file path
  - Build path: `{stepDefinitionsPath}/[feature-name].steps.{ext}`
  - Respect file extension from pattern analysis (.ts vs .js)

- [ ] **RUN**: Verify path construction

- [ ] **GREEN**: Implement path determination
  - Add "Step 2: Determine Target File" section
  - Parse feature file name (remove path and extension)
  - Construct step file path
  - Check if file already exists (append mode)

- [ ] **RUN**: Verify append mode detection

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "feat: determine step definition file path"

---

### Behavior 4: Generate step definitions for "create new" decisions

**Given** approval decisions include "create new"
**When** generating code
**Then** produce step definitions matching detected patterns with TODO comments

- [ ] **RED**: Add code generation logic
  - Implementation: For each "create new" decision:
    - Use detected import pattern
    - Use detected parameter style
    - Use detected formatting
    - Include `// TODO: Implement step` in body
  - Preserve Cucumber expressions ({string}, {int}, etc.)

- [ ] **RUN**: Verify generated code matches patterns

- [ ] **GREEN**: Implement generation
  - Add "Step 3: Generate New Step Definitions" section
  - Build code string for each new step:
    ```typescript
    Given('[step text]', async ({ page }) => {
      // TODO: Implement step
    });
    ```
  - Apply detected patterns to format

- [ ] **RUN**: Verify code is syntactically correct

- [ ] **REFACTOR**: Extract generation to template function

- [ ] **COMMIT**: "feat: generate step definitions matching repo patterns"

---

### Behavior 5: Handle empty repo (no existing patterns)

**Given** no existing step definitions to analyze
**When** generating code
**Then** use minimal template from spec

- [ ] **RED**: Add minimal template for empty repos
  - Implementation: Check if pattern analysis found no files
  - Use default template:
    ```typescript
    Given('[step text]', async ({ page }) => {
      // TODO: Implement step
    });
    ```

- [ ] **RUN**: Verify minimal template matches spec

- [ ] **GREEN**: Implement empty repo path
  - Add conditional in generation logic
  - Use minimal template when no patterns detected
  - Default file extension: .ts

- [ ] **RUN**: Verify generation works without existing patterns

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "feat: use minimal template for empty repos"

---

### Behavior 6: Create review file for generated code

**Given** step definitions generated
**When** presenting to developer
**Then** create `docs/specs/playwright-bdd-review-[feature-name].md` with [ ] Reviewed checkpoint

- [ ] **RED**: Add review file generation
  - Location: `docs/specs/playwright-bdd-review-[feature-name].md`
  - Format matches spec (lines 120-153):
    - Feature name header
    - Scenario section
    - File path + code block for each step
    - Single `[ ] Reviewed` checkbox at end

- [ ] **RUN**: Verify format matches spec

- [ ] **GREEN**: Implement review file generation
  - Add "Step 4: Generate Review File" section
  - Format as markdown with code blocks
  - Show all generated step definitions
  - Add [ ] Reviewed checkbox

- [ ] **RUN**: Verify structure

- [ ] **REFACTOR**: Extract formatting logic

- [ ] **COMMIT**: "feat: generate review file with approval checkpoint"

---

### Behavior 7: Wait for review approval

**Given** review file created
**When** waiting for developer
**Then** instruct to check [ ] Reviewed before writing files

- [ ] **RED**: Add review wait instruction
  - Implementation: Message to developer
  - Explain: "Review the generated code in review file, check [ ] Reviewed when satisfied"

- [ ] **RUN**: Verify instruction is clear

- [ ] **GREEN**: Implement review wait
  - Add message after review file write
  - Use AskUserQuestion: "Review file created. Check the code and mark [ ] Reviewed to proceed."
  - Options: "Reviewed, write files" / "I need to adjust something"

- [ ] **RUN**: Verify user flow

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "feat: wait for review approval"

---

### Behavior 8: Write step definition files to disk

**Given** developer marked [ ] Reviewed
**When** proceeding to file write
**Then** write or append step definitions to target files

- [ ] **RED**: Add file write logic
  - Implementation: Use Write tool
  - If file exists: append new steps (read, concatenate, write)
  - If file doesn't exist: create with imports + steps

- [ ] **RUN**: Verify write/append logic

- [ ] **GREEN**: Implement file writing
  - Add "Step 5: Write Step Definition Files" section
  - Check if target file exists
  - Append mode: read existing, add new steps, write
  - Create mode: write complete file with imports + steps
  - Confirm completion: "Step definitions written to [paths]"

- [ ] **RUN**: Verify files are written correctly

- [ ] **REFACTOR**: Add error handling for write failures

- [ ] **COMMIT**: "feat: write step definition files to disk"

---

### Behavior 9: Handle "continue to next scenario" flow

**Given** first scenario complete
**When** feature has multiple scenarios
**Then** ask: "Continue to next scenario in this feature? [Yes / No]"

- [ ] **RED**: Add multi-scenario flow
  - Implementation: Check if feature file has more scenarios
  - User question matches spec exactly
  - Yes: loop back to Step 5 (extract next scenario)
  - No: exit with summary

- [ ] **RUN**: Verify flow is clear

- [ ] **GREEN**: Implement multi-scenario handling
  - Add "Step 6: Check for More Scenarios" section
  - Count scenarios in feature file
  - If more remain, ask via AskUserQuestion
  - Handle both responses appropriately

- [ ] **RUN**: Verify loop logic

- [ ] **REFACTOR**: Add comment about sequential processing

- [ ] **COMMIT**: "feat: support multiple scenarios per feature"

---

## Edge Cases (Moderate Risk)

### Edge Case 1: Malformed Gherkin syntax error details

**Given** Gherkin parser detects syntax error
**When** reporting to developer
**Then** include line number and specific description

- [ ] **RED**: Enhance error reporting
  - Implementation: Extract line number from parser error
  - Format: "Invalid Gherkin syntax at line X: [parser message]"

- [ ] **GREEN**: Implement detailed error
  - Parse error object for line number
  - Include specific error description
  - Show before any processing continues

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "fix: detailed gherkin syntax error messages"

---

### Edge Case 2: Duplicate steps with line numbers in error

**Given** duplicate detection finds multiple occurrences
**When** showing error
**Then** include file path AND line number for each occurrence

- [ ] **RED**: Enhance duplicate error format
  - Implementation: Format as "[file1] (line X), [file2] (line Y)"

- [ ] **GREEN**: Implement detailed duplicate error
  - Include line numbers from index
  - Show all occurrences, not just first two

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "fix: include line numbers in duplicate step error"

---

### Edge Case 3: File write permissions error

**Given** target directory is not writable
**When** attempting to write step definition file
**Then** error: "Could not write file [path]. [error details]" with actionable next steps

- [ ] **RED**: Add write permission error handling
  - Implementation: Catch write errors
  - Error format matches spec
  - Suggest: check permissions, verify path exists

- [ ] **GREEN**: Implement error handling
  - Try/catch around Write tool
  - Extract error details from exception
  - Show actionable message

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "fix: handle file write permission errors"

---

### Edge Case 4: Context-gatherer failure handling

**Given** context-gatherer agent fails
**When** delegation returns error
**Then** error: "Could not analyze repo structure. [error details]"

- [ ] **RED**: Add delegation error handling
  - Implementation: Check Task result for errors
  - Error format matches spec

- [ ] **GREEN**: Implement error handling
  - Check for error in Task response
  - Show clear error message
  - Exit workflow (don't proceed without structure info)

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "fix: handle context-gatherer failure"

---

### Edge Case 5: Semantic matching API failure with retry

**Given** LLM call fails during semantic matching
**When** error occurs
**Then** retry once, then error: "Semantic matching failed for step '[step text]'. [error details]"

- [ ] **RED**: Add retry logic for LLM calls
  - Implementation: Try matching, catch error, retry once
  - After 2 failures, show error per spec

- [ ] **GREEN**: Implement retry
  - Wrap matching in try/catch
  - Retry counter (max 2 attempts)
  - Error message includes step text and error details

- [ ] **REFACTOR**: Extract retry logic to reusable pattern

- [ ] **COMMIT**: "fix: retry semantic matching on failure"

---

### Edge Case 6: Empty scenario (no steps)

**Given** scenario has no Given/When/Then steps
**When** extracting steps
**Then** show warning: "Scenario has no steps. Skipping." and continue to next scenario

- [ ] **RED**: Add empty scenario check
  - Implementation: Count extracted steps
  - If zero, show warning and skip

- [ ] **GREEN**: Implement check
  - After extraction, validate step count > 0
  - Show clear warning
  - Continue to next scenario if available

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "fix: handle empty scenarios gracefully"

---

## Final Integration Check

- [ ] **Verify command orchestration flow**: Command delegates to agents in correct order
- [ ] **Verify error handling**: All error messages match spec exactly and are actionable
- [ ] **Verify approval workflow**: Both approval files have clear instructions
- [ ] **Verify file paths**: All generated files use correct paths
- [ ] **Review agent frontmatter**: All agents have proper tools, skills, examples

---

## Test Summary

| Category | # Items | Status |
|----------|---------|--------|
| Slice 1: Command Interface | 5 behaviors | [ ] |
| Slice 2: Repo Structure Detection | 5 behaviors | [ ] |
| Slice 3: Step Indexing | 6 behaviors | [ ] |
| Slice 4: Semantic Matching | 5 behaviors | [ ] |
| Slice 5: Approval Workflow | 4 behaviors | [ ] |
| Slice 6: Code Generation | 9 behaviors | [ ] |
| Edge Cases | 6 cases | [ ] |
| **Total** | **40 items** | [ ] |

---

## Success Signal (from spec)

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

---

[x] Reviewed
