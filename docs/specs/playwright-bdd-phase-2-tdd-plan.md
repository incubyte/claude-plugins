# TDD Plan: Playwright-BDD Plugin — Phase 2 (Page Object Generation)

## Execution Instructions

Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] → [x]).
Continue until all items are done.
If stuck after 3 attempts, mark ⚠️ and move to the next independent step.

## Context

- **Source**: `/Users/akashincubyte/Documents/incubyte/Repo/claude plugins/claude-plugins/docs/specs/playwright-bdd-phase-2.md`
- **Phase**: Phase 2 — Page Object Generation
- **Risk Level**: MODERATE
- **Architecture**: Command + Agent Delegation (extend existing playwright-bdd command, add 3 new agents)
- **Pattern References**: Phase 1 workflow, existing agent delegation patterns
- **Dependencies**: Phase 1 must be complete (step definitions with TODO comments)

## Codebase Analysis

### File Structure
- Command orchestrator: `bee/commands/playwright-bdd.md` (EXTEND)
- New POM matcher agent: `bee/agents/playwright-pom-matcher.md` (CREATE)
- New POM generator agent: `bee/agents/playwright-pom-generator.md` (CREATE)
- New locator generator agent: `bee/agents/playwright-locator-generator.md` (CREATE)
- Reuse: `bee/agents/context-gatherer.md` (existing)

### Test Infrastructure
- Framework: Behavior-driven (markdown specs with acceptance criteria checkboxes)
- Validation: Manual verification against acceptance criteria in spec
- Pattern: Create → Validate → Iterate (no automated unit tests for markdown agents)

### Conventions
- Commands delegate to agents via Task tool
- Agents have frontmatter with allowed tools and skills
- File-based approval workflow with `[ ] Reviewed` checkboxes
- Error messages must be actionable and specific
- Multi-step workflow with sequential approval gates

---

## Implementation Strategy

Phase 2 extends Phase 1's workflow by adding page object generation after step definition creation. The TDD approach:

1. **RED**: Write agent/command definition that satisfies specific acceptance criteria
2. **GREEN**: Validate the definition against the acceptance criteria
3. **REFACTOR**: Improve structure, error handling, and delegation flow

We'll build in **4 slices**, each delivering a meaningful unit of behavior:

---

## Slice 1: UI Step Detection & Classification

**Goal**: Automatically detect which steps require page object methods vs API/data steps.

**Acceptance Criteria (from spec)**:
- Analyze each step to classify: UI vs non-UI
- Use LLM-based classification with UI keyword detection
- Handle ambiguous cases with developer question
- Skip Phase 2 entirely if no UI steps detected

### Behavior 1: Integrate Phase 2 trigger into Phase 1 workflow

**Given** Phase 1 completes step definition generation for a scenario
**When** workflow proceeds to Phase 2
**Then** show "Analyzing steps for page object requirements..." before starting

- [ ] **RED**: Extend `bee/commands/playwright-bdd.md` to add Phase 2 entry point
  - Location: After Phase 1 completion (after step definitions written)
  - Add section: "Phase 2: Page Object Generation"
  - Show message: "Analyzing steps for page object requirements..."

- [ ] **RUN**: Verify Phase 2 trigger is clear

- [ ] **GREEN**: Implement Phase 2 entry
  - Add conditional: if step definitions were generated, proceed to Phase 2
  - Add message before delegation
  - Prepare to delegate to POM matcher agent

- [ ] **RUN**: Verify flow transition is smooth

- [ ] **REFACTOR**: Add comment explaining Phase 1 → Phase 2 handoff

- [ ] **COMMIT**: "feat: add phase 2 entry point after step generation"

---

### Behavior 2: Create POM matcher agent with UI classification

**Given** need to classify steps as UI or non-UI
**When** creating agent structure
**Then** POM matcher agent exists with classification capability

- [ ] **RED**: Create `bee/agents/playwright-pom-matcher.md`
  - Location: `bee/agents/playwright-pom-matcher.md`
  - Frontmatter: name, description, tools (Read, Grep, Glob), model, color
  - Skills: pattern-matching, clean-code
  - Mission: Classify steps, match to page objects, score confidence

- [ ] **RUN**: Verify frontmatter matches existing agent patterns

- [ ] **GREEN**: Implement agent skeleton
  - Add agent description: UI step detection and semantic POM matching
  - Include LLM prompt template for UI classification (from spec lines 426-440)
  - Define classification logic: keywords + page/element mentions

- [ ] **RUN**: Verify structure follows conventions

- [ ] **REFACTOR**: Ensure classification approach is clear

- [ ] **COMMIT**: "feat: create playwright-pom-matcher agent skeleton"

---

### Behavior 3: Classify each step as UI vs non-UI

**Given** step definitions from Phase 1
**When** analyzing each step text
**Then** classify using UI keywords and LLM reasoning

- [ ] **RED**: Add step classification logic
  - Implementation: For each step definition from Phase 1, analyze step text
  - UI keywords: navigate, click, enter, fill, select, type, press, upload, scroll, hover, check, toggle, open, close, submit
  - UI indicators: mentions page/screen/button/form/input/link
  - LLM prompt from spec (lines 426-440)

- [ ] **RUN**: Verify classification approach matches spec

- [ ] **GREEN**: Implement classification
  - Add "Step 1: Classify Steps" section
  - Process steps in order (Given → When → Then)
  - For each step: check keywords OR use LLM for semantic classification
  - Store: { stepText, type: 'UI' | 'NON-UI', filePath, lineNumber }

- [ ] **RUN**: Verify classification is accurate

- [ ] **REFACTOR**: Extract classification logic to clear subsection

- [ ] **COMMIT**: "feat: classify steps as UI or non-UI"

---

### Behavior 4: Handle no UI steps case

**Given** all steps classified as non-UI
**When** no UI interactions detected
**Then** show "No UI interactions detected. Scenario complete." and skip Phase 2

- [ ] **RED**: Add no-UI-steps exit path
  - Implementation: Count UI-classified steps
  - If zero, show message from spec exactly
  - Skip all POM matching and generation phases

- [ ] **RUN**: Verify message matches spec

- [ ] **GREEN**: Implement no-UI-steps handling
  - Add conditional after classification
  - Show message and exit Phase 2
  - Return to Phase 1 flow for next scenario question

- [ ] **RUN**: Verify skip logic works

- [ ] **REFACTOR**: Add comment explaining fast path

- [ ] **COMMIT**: "feat: skip phase 2 when no UI steps detected"

---

### Behavior 5: Handle ambiguous step classification

**Given** step classification is uncertain
**When** LLM cannot confidently determine UI vs non-UI
**Then** ask developer: "Does this step require UI interaction? [Yes / No / Skip for now]"

- [ ] **RED**: Add ambiguous case handling
  - Implementation: Check classification confidence
  - If ambiguous, use AskUserQuestion
  - Options match spec exactly
  - "Skip for now" → leave `// TODO: Implement step`

- [ ] **RUN**: Verify question is clear

- [ ] **GREEN**: Implement ambiguous handling
  - Add confidence check after classification
  - Use AskUserQuestion for uncertain steps
  - Store developer's choice
  - If "Skip", mark step as no-POM-needed

- [ ] **RUN**: Verify all options work

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "feat: handle ambiguous step classification with developer question"

---

## Slice 2: Page Object Indexing & Semantic Matching

**Goal**: Scan existing page objects and perform semantic similarity matching for UI steps.

**Acceptance Criteria (from spec)**:
- Scan repo for existing page object files
- Parse class names, methods, locators
- Track usage in step definitions
- Perform LLM-based semantic matching at class and method level
- Hide matches below 50% confidence

### Behavior 1: Scan and index existing page objects

**Given** repo structure known from Phase 1
**When** starting POM matching
**Then** scan for page object files and parse structure

- [ ] **RED**: Add page object scanning logic
  - Implementation: Use Glob to find `src/pages/**/*.ts` and `src/pages/**/*.js`
  - Parse each file to extract: class name, file path, methods (name + parameters), locators
  - Build index structure matching spec API shape (lines 460-477)

- [ ] **RUN**: Verify scanning approach

- [ ] **GREEN**: Implement POM indexing
  - Add "Step 2: Index Existing Page Objects" section
  - Use Glob with page object patterns
  - Parse each file with Grep for class and method definitions
  - Build index: { className, filePath, methods, locators, usedInSteps }

- [ ] **RUN**: Verify index structure is complete

- [ ] **REFACTOR**: Extract parsing logic to subsection

- [ ] **COMMIT**: "feat: scan and index existing page objects"

---

### Behavior 2: Track page object usage in step definitions

**Given** page objects indexed
**When** analyzing usage
**Then** identify which step definition files import and use each page object

- [ ] **RED**: Add usage tracking
  - Implementation: Grep step definition files for POM imports
  - Track which steps call methods on each page object
  - Store in usedInSteps array with file paths

- [ ] **RUN**: Verify tracking approach

- [ ] **GREEN**: Implement usage tracking
  - Add "Step 3: Track POM Usage" section
  - For each page object, grep step files for imports
  - Count method calls per step file
  - Store usage data in index

- [ ] **RUN**: Verify usage data is accurate

- [ ] **REFACTOR**: Consider performance for large repos

- [ ] **COMMIT**: "feat: track page object usage in step definitions"

---

### Behavior 3: Handle empty repo (no page objects)

**Given** no existing page objects found
**When** indexing completes
**Then** show "No existing page objects detected. Will create new page objects for all UI steps." and skip matching

- [ ] **RED**: Add empty POM repo handling
  - Implementation: Check if index is empty after scanning
  - Show message from spec exactly
  - Set flag to skip semantic matching phase

- [ ] **RUN**: Verify message matches spec

- [ ] **GREEN**: Implement empty repo path
  - Add conditional after scanning
  - Show upfront message
  - Skip to POM generation phase (all UI steps create new POMs)

- [ ] **RUN**: Verify skip logic works

- [ ] **REFACTOR**: Add comment explaining fast path

- [ ] **COMMIT**: "feat: handle empty page object repo"

---

### Behavior 4: Perform semantic matching at class level

**Given** UI steps and indexed page objects
**When** comparing each UI step to page objects
**Then** use LLM to rate class-level similarity 0-100

- [ ] **RED**: Add class-level semantic matching
  - Implementation: For each UI step, compare to all page object classes
  - Use LLM prompt from spec (lines 443-457)
  - Compare step text against class name + existing methods
  - Generate confidence score 0-100

- [ ] **RUN**: Verify prompt matches spec template

- [ ] **GREEN**: Implement class-level matching
  - Add "Step 4: Semantic Matching - Class Level" section
  - For each UI step, iterate indexed page objects
  - Send comparison prompt to Claude (internal reasoning)
  - Parse numeric score
  - Build candidates: { className, confidence, methods, usedInSteps }

- [ ] **RUN**: Verify matching produces expected output

- [ ] **REFACTOR**: Add error handling for non-numeric responses

- [ ] **COMMIT**: "feat: llm-based class-level semantic matching"

---

### Behavior 5: Perform method-level matching for high-confidence classes

**Given** class-level match ≥50%
**When** checking if existing methods can handle the step
**Then** compare step action to method names in that class

- [ ] **RED**: Add method-level matching
  - Implementation: For classes with confidence ≥50%, check method match
  - Compare step action text to method names
  - Generate method-level confidence score
  - Decision logic from spec (lines 55-60):
    - Class >70% AND method >70% → "Reuse existing method"
    - Class >70% AND method <50% → "Add new method to existing class"
    - Class <50% → "Create new page object class"

- [ ] **RUN**: Verify decision logic matches spec

- [ ] **GREEN**: Implement method-level matching
  - Add "Step 5: Semantic Matching - Method Level" section
  - For each high-confidence class, compare to methods
  - Calculate method match score
  - Apply decision rules
  - Store recommendation

- [ ] **RUN**: Verify recommendations are correct

- [ ] **REFACTOR**: Extract decision rules to clear subsection

- [ ] **COMMIT**: "feat: method-level semantic matching with decision logic"

---

### Behavior 6: Filter and order POM candidates

**Given** semantic matching complete
**When** preparing candidates for display
**Then** hide <50% confidence, sort by confidence DESC then usage DESC

- [ ] **RED**: Add candidate filtering and sorting
  - Implementation: Filter candidates to keep only ≥50% confidence
  - Sort: primary by confidence DESC, secondary by usageCount DESC
  - Match sorting approach from Phase 1

- [ ] **RUN**: Verify filtering threshold is 50% exactly

- [ ] **GREEN**: Implement filtering and sorting
  - Add filter step after matching
  - Multi-level sort
  - Deterministic ordering

- [ ] **RUN**: Verify sorting is consistent

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "feat: filter and sort POM candidates"

---

## Slice 3: POM Decision Approval & outerHTML Collection

**Goal**: Present POM candidates to developer and collect outerHTML for new page object methods.

**Acceptance Criteria (from spec)**:
- Create approval file showing candidates with confidence scores
- Display existing methods and usage
- Use checkbox format for decisions (reuse/extend/create)
- Collect outerHTML from developer for new methods/classes
- Validate HTML structure

### Behavior 1: Generate POM approval file with candidates

**Given** semantic matching complete for all UI steps
**When** presenting POM decisions
**Then** create `docs/specs/playwright-bdd-pom-approval-[feature-name]-scenario-[N].md`

- [ ] **RED**: Add POM approval file generation
  - Location: Use Write tool to create approval file
  - Path: `docs/specs/playwright-bdd-pom-approval-[feature-name]-scenario-[N].md`
  - Format matches spec exactly (lines 63-99)
  - Show: step text, candidates with confidence, existing methods, usage stats, decision checkboxes

- [ ] **RUN**: Verify format matches spec

- [ ] **GREEN**: Implement approval file generation
  - Add "Step 6: Generate POM Approval File" section
  - For each UI step, format as:
    ```
    Step: "[step text]"

    Page Object Candidates:
    1. [ClassName] - N% confidence
       Existing methods: [method1(), method2()]
       Used in: [files]
       Method match: [existing method or "No existing method"]

    Decision:
    - [ ] Add new method to [Class] (Recommended)
    - [ ] Reuse [Class].[method]()
    - [ ] Create new page object
    ```
  - Write file with Write tool

- [ ] **RUN**: Verify file structure

- [ ] **REFACTOR**: Extract formatting to helper section

- [ ] **COMMIT**: "feat: generate pom approval file with candidates"

---

### Behavior 2: Wait for developer POM decisions

**Given** approval file created
**When** waiting for decision
**Then** instruct developer to check exactly one box per UI step

- [ ] **RED**: Add approval wait instruction
  - Implementation: Clear message to developer
  - Explain: "Review POM approval file, check one box per step, save, and confirm"
  - Use AskUserQuestion

- [ ] **RUN**: Verify instruction is clear

- [ ] **GREEN**: Implement wait
  - Add message after file write
  - Use AskUserQuestion: "POM approval file created. Review and check one box per UI step, then confirm."
  - Options: "I've made my decisions, proceed" / "Cancel workflow"

- [ ] **RUN**: Verify user flow

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "feat: wait for developer pom decisions"

---

### Behavior 3: Validate exactly one decision per UI step

**Given** developer confirms approval
**When** reading approval file
**Then** validate each UI step has exactly one checkbox marked

- [ ] **RED**: Add POM approval validation
  - Implementation: Read approval file back
  - Parse checkboxes: count [x] per step section
  - Error if 0 or 2+ boxes checked for any step
  - Error messages match spec (lines 99-100)

- [ ] **RUN**: Verify validation catches errors

- [ ] **GREEN**: Implement validation
  - Add "Step 7: Validate POM Approval" section
  - Parse file to extract decisions per UI step
  - Check: each step has exactly 1 [x]
  - Show actionable error messages

- [ ] **RUN**: Verify all error cases

- [ ] **REFACTOR**: Extract parsing logic to subsection

- [ ] **COMMIT**: "feat: validate pom approval selections"

---

### Behavior 4: Collect outerHTML for new methods/classes

**Given** decisions include "add new method" or "create new POM"
**When** generating page object code
**Then** ask developer for outerHTML of target element

- [ ] **RED**: Add outerHTML collection
  - Implementation: For each decision needing new code, prompt for outerHTML
  - Show prompt from spec (lines 105-106)
  - Accept multiline HTML input
  - Validate HTML structure (must be valid HTML)
  - Error message matches spec (line 108)

- [ ] **RUN**: Verify prompt is clear

- [ ] **GREEN**: Implement outerHTML collection
  - Add "Step 8: Collect outerHTML" section
  - For each new method/class, use AskUserQuestion
  - Prompt: "Provide HTML outerHTML for: [step text]. Paste the outerHTML from browser DevTools."
  - Validate HTML structure
  - Store for locator generation

- [ ] **RUN**: Verify validation works

- [ ] **REFACTOR**: Add example of valid outerHTML in prompt

- [ ] **COMMIT**: "feat: collect outerhtml for new page object methods"

---

### Behavior 5: Handle invalid or missing outerHTML

**Given** developer provides invalid HTML or says "I don't have it yet"
**When** validating outerHTML
**Then** error with clear instructions or offer to skip

- [ ] **RED**: Add outerHTML error handling
  - Implementation: Validate HTML structure
  - If invalid, show detailed error from spec (lines 332-338)
  - If developer says "Skip", leave `// TODO: Add page object method` in step definition

- [ ] **RUN**: Verify error message is actionable

- [ ] **GREEN**: Implement error handling
  - Add HTML validation with clear error
  - Offer "Skip this step's page object generation? [Yes / No]"
  - If skip, mark step as incomplete

- [ ] **RUN**: Verify skip logic works

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "feat: handle invalid or missing outerhtml"

---

## Slice 4: Locator Generation & Code Generation

**Goal**: Generate Playwright locators from outerHTML and create page object code matching repo patterns.

**Acceptance Criteria (from spec)**:
- Parse outerHTML to extract stable attributes
- Generate Playwright locators following best practices
- Detect existing page object patterns
- Generate new methods or classes matching patterns
- Update step definitions to call page object methods
- Create review file with [ ] Reviewed checkpoint

### Behavior 1: Create locator generator agent

**Given** need to generate Playwright locators from outerHTML
**When** creating agent structure
**Then** locator generator agent exists with parsing capability

- [ ] **RED**: Create `bee/agents/playwright-locator-generator.md`
  - Location: `bee/agents/playwright-locator-generator.md`
  - Frontmatter: name, description, tools (none needed - pure logic), model, color
  - Skills: clean-code
  - Mission: Parse HTML, prioritize attributes, generate best-practice locators

- [ ] **RUN**: Verify frontmatter structure

- [ ] **GREEN**: Implement agent skeleton
  - Add agent description: HTML-to-locator conversion following Playwright best practices
  - Include attribute priority from spec (lines 115-120)
  - Define locator generation patterns (lines 121-129)

- [ ] **RUN**: Verify structure

- [ ] **REFACTOR**: Ensure locator logic is clear

- [ ] **COMMIT**: "feat: create playwright-locator-generator agent skeleton"

---

### Behavior 2: Parse outerHTML to extract attributes

**Given** outerHTML collected from developer
**When** generating locator
**Then** extract key attributes: data-testid, id, aria-label, role, name, class

- [ ] **RED**: Add HTML parsing logic
  - Implementation: Parse outerHTML string
  - Extract attributes in priority order from spec
  - Handle missing attributes gracefully

- [ ] **RUN**: Verify parsing approach

- [ ] **GREEN**: Implement HTML parsing
  - Add "Step 1: Parse outerHTML" section in locator generator agent
  - Extract all relevant attributes
  - Store for locator decision

- [ ] **RUN**: Verify extraction works

- [ ] **REFACTOR**: Add error handling for malformed HTML

- [ ] **COMMIT**: "feat: parse outerhtml to extract attributes"

---

### Behavior 3: Generate Playwright locator following best practices

**Given** attributes extracted from outerHTML
**When** creating locator
**Then** prioritize: data-testid > id > role/aria-label > name > class

- [ ] **RED**: Add locator generation logic
  - Implementation: Apply priority order from spec (lines 115-120)
  - Generate appropriate Playwright API call:
    - `page.getByTestId('...')` if data-testid exists
    - `page.getByRole('button', { name: '...' })` for semantic elements
    - `page.getByLabel('...')` for form inputs
    - `page.locator('#id')` if id is stable
    - `page.locator('.class')` only as last resort
  - Never generate XPath or nth-child selectors

- [ ] **RUN**: Verify locator patterns match spec

- [ ] **GREEN**: Implement locator generation
  - Add "Step 2: Generate Locator" section
  - Apply priority rules
  - Build locator string using Playwright API
  - Return generated locator

- [ ] **RUN**: Verify generated locators follow best practices

- [ ] **REFACTOR**: Extract locator decision logic

- [ ] **COMMIT**: "feat: generate playwright locators following best practices"

---

### Behavior 4: Warn about unstable locators

**Given** outerHTML has no stable attributes
**When** generating locator
**Then** warn: "No stable selector found. Generated locator may be fragile."

- [ ] **RED**: Add unstable locator warning
  - Implementation: Check if only class-based or text-based locator possible
  - Include warning comment in generated code (lines 343-347)
  - Show warning in review file

- [ ] **RUN**: Verify warning is actionable

- [ ] **GREEN**: Implement warning
  - Add stability check after locator generation
  - If unstable, add warning comment to generated code
  - Include in review file output

- [ ] **RUN**: Verify warning appears

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "feat: warn about unstable locators"

---

### Behavior 5: Create POM generator agent

**Given** need to generate page object code
**When** creating agent structure
**Then** POM generator agent exists with pattern detection capability

- [ ] **RED**: Create `bee/agents/playwright-pom-generator.md`
  - Location: `bee/agents/playwright-pom-generator.md`
  - Frontmatter: name, description, tools (Read, Write, Grep, Glob), model, color
  - Skills: clean-code, design-fundamentals
  - Mission: Analyze existing POM patterns, generate matching code

- [ ] **RUN**: Verify frontmatter structure

- [ ] **GREEN**: Implement agent skeleton
  - Add agent description: Generate page objects matching repo patterns
  - Include pattern detection requirements (lines 132-151)
  - Define code generation strategy

- [ ] **RUN**: Verify structure

- [ ] **REFACTOR**: Ensure mission is clear

- [ ] **COMMIT**: "feat: create playwright-pom-generator agent skeleton"

---

### Behavior 6: Detect existing page object patterns

**Given** repo has existing page objects
**When** POM generator starts
**Then** analyze code structure patterns (naming, constructor, methods, imports)

- [ ] **RED**: Add pattern detection logic
  - Implementation: Read 2-3 existing page object files
  - Extract patterns from spec (lines 132-139):
    - Class naming convention
    - Constructor parameters
    - Locator definition style
    - Method naming convention
    - Return types
    - Import statements
  - Store as template configuration

- [ ] **RUN**: Verify pattern detection is comprehensive

- [ ] **GREEN**: Implement pattern detection
  - Add "Step 1: Detect POM Patterns" section in POM generator
  - Read existing page objects
  - Parse structure with Grep
  - Build pattern template

- [ ] **RUN**: Verify detection works

- [ ] **REFACTOR**: Handle inconsistent patterns (use most common)

- [ ] **COMMIT**: "feat: detect existing page object patterns"

---

### Behavior 7: Generate new page object method

**Given** decision is "add new method to existing class"
**When** generating code
**Then** add method matching existing method patterns

- [ ] **RED**: Add method generation logic
  - Implementation: Read existing page object file
  - Analyze method structure from spec (lines 154-169)
  - Generate new method matching patterns
  - Insert at end of class
  - Include JSDoc if existing methods have JSDoc

- [ ] **RUN**: Verify method generation approach

- [ ] **GREEN**: Implement method generation
  - Add "Step 2: Generate New Method" section
  - Read target page object file
  - Generate method matching style
  - Use locator from locator generator
  - Format with proper async/await

- [ ] **RUN**: Verify generated method is syntactically correct

- [ ] **REFACTOR**: Extract method template logic

- [ ] **COMMIT**: "feat: generate new page object methods"

---

### Behavior 8: Generate new page object class

**Given** decision is "create new page object"
**When** generating code
**Then** create class matching repo patterns

- [ ] **RED**: Add class generation logic
  - Implementation: Derive class name from step text (lines 173-174)
  - Create file at `src/pages/[page-name].page.ts`
  - Generate class with constructor, locators, methods (lines 175-182)
  - Use detected patterns or minimal template if empty repo

- [ ] **RUN**: Verify class generation approach

- [ ] **GREEN**: Implement class generation
  - Add "Step 3: Generate New Page Object Class" section
  - Build class structure
  - Include all locators needed
  - Add methods for steps targeting this page
  - Match file naming convention

- [ ] **RUN**: Verify generated class is complete

- [ ] **REFACTOR**: Handle multiple steps targeting same new page (group methods)

- [ ] **COMMIT**: "feat: generate new page object classes"

---

### Behavior 9: Update step definitions to call page object methods

**Given** page object code generated
**When** updating step definitions
**Then** replace `// TODO: Implement step` with POM method call

- [ ] **RED**: Add step definition update logic
  - Implementation: Read step definition file
  - Replace TODO comment with page object instantiation and method call (lines 189-199)
  - Add page object import at top
  - Preserve existing code

- [ ] **RUN**: Verify update approach

- [ ] **GREEN**: Implement step definition updates
  - Add "Step 4: Update Step Definitions" section
  - For each UI step, replace TODO
  - Add import if not already present
  - Use detected parameter style (e.g., `{ page }`)

- [ ] **RUN**: Verify step definitions are updated correctly

- [ ] **REFACTOR**: Handle duplicate imports (don't add if exists)

- [ ] **COMMIT**: "feat: update step definitions to call page object methods"

---

### Behavior 10: Generate review file for POM code

**Given** all page object code generated
**When** presenting to developer
**Then** create `docs/specs/playwright-bdd-pom-review-[feature-name]-scenario-[N].md`

- [ ] **RED**: Add POM review file generation
  - Location: `docs/specs/playwright-bdd-pom-review-[feature-name]-scenario-[N].md`
  - Format matches spec (lines 207-260)
  - Show: updated step definitions AND page object code (new methods or new classes)
  - Organized by step
  - Single `[ ] Reviewed` checkbox at end

- [ ] **RUN**: Verify format matches spec

- [ ] **GREEN**: Implement review file generation
  - Add "Step 5: Generate Review File" section
  - Format as markdown with code blocks
  - Show file path + code for each change
  - Include warning comments if locators are fragile
  - Add [ ] Reviewed checkbox

- [ ] **RUN**: Verify file structure

- [ ] **REFACTOR**: Extract formatting logic

- [ ] **COMMIT**: "feat: generate pom review file"

---

### Behavior 11: Write page object files after review approval

**Given** developer marked [ ] Reviewed
**When** proceeding to file write
**Then** write or update page object files and step definition files

- [ ] **RED**: Add file write logic
  - Implementation: Use Write tool
  - Write new page object classes
  - Update existing page object classes (insert methods)
  - Update step definition files (replace TODOs)
  - Confirm completion with file paths

- [ ] **RUN**: Verify write logic

- [ ] **GREEN**: Implement file writing
  - Add "Step 6: Write Files to Disk" section
  - Write all page object changes
  - Write all step definition changes
  - Show confirmation: "Page objects written to [paths]. Step definitions updated in [paths]."

- [ ] **RUN**: Verify files are written correctly

- [ ] **REFACTOR**: Add error handling for write failures

- [ ] **COMMIT**: "feat: write page object files to disk"

---

## Edge Cases (Moderate Risk)

### Edge Case 1: Zero high-confidence POM matches

**Given** all page object match scores below 50%
**When** no candidates to show
**Then** present decision: create new POM or add to existing (dropdown)

- [ ] **RED**: Add zero-match handling
  - Implementation: Check if candidates array is empty
  - Show decision from spec (lines 306-315)
  - If developer chooses existing class, show dropdown with all classes

- [ ] **GREEN**: Implement zero-match case
  - Add conditional after filtering
  - Show "No matching page objects found."
  - Present decision options
  - Handle developer choice

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "fix: handle zero high-confidence pom matches"

---

### Edge Case 2: Multiple steps target same new page object

**Given** scenario has 3 steps creating new POMs with same page name
**When** generating code
**Then** consolidate all methods into single page object class

- [ ] **RED**: Add duplicate page detection
  - Implementation: Track page names during approval
  - Detect duplicates during code generation
  - Group all methods into one class (lines 317-322)

- [ ] **GREEN**: Implement consolidation
  - Add duplicate detection in POM generator
  - Group methods by page name
  - Generate single class with all methods
  - Show in review file as one class

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "fix: consolidate multiple steps into single page object"

---

### Edge Case 3: Existing page object with conflicting method name

**Given** generating new method but name already exists in class
**When** detecting naming conflict
**Then** append number to method name: `clickButton2()`

- [ ] **RED**: Add method name conflict detection
  - Implementation: Check existing method names before generating
  - Append number if conflict (lines 358-368)
  - Show note in review file

- [ ] **GREEN**: Implement conflict resolution
  - Add name conflict check
  - Auto-rename with number suffix
  - Include comment in generated code

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "fix: handle conflicting method names in page objects"

---

### Edge Case 4: Step definition already imports same page object

**Given** step file already imports SearchPage
**When** new step also uses SearchPage
**Then** reuse existing import, don't add duplicate

- [ ] **RED**: Add duplicate import detection
  - Implementation: Check existing imports before adding
  - If import exists, skip adding (lines 371-374)

- [ ] **GREEN**: Implement duplicate import prevention
  - Add import check in step definition update logic
  - Only add import if not present

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "fix: prevent duplicate page object imports"

---

### Edge Case 5: Page object indexing parse error

**Given** existing POM file has parse errors
**When** indexing page objects
**Then** warn and skip that file: "Could not parse [file path]. Skipping this page object in matching."

- [ ] **RED**: Add indexing error handling
  - Implementation: Try/catch around parsing
  - Show warning from spec (line 266)
  - Continue with other files

- [ ] **GREEN**: Implement error handling
  - Add try/catch in indexing loop
  - Log warning for unparseable files
  - Continue indexing

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "fix: handle page object parse errors gracefully"

---

### Edge Case 6: Locator generation produces no selector

**Given** outerHTML has no identifiable attributes
**When** attempting to generate locator
**Then** error: "Could not generate locator from outerHTML. Element has no identifiable attributes. Consider adding data-testid."

- [ ] **RED**: Add locator generation failure handling
  - Implementation: Check if locator is empty after generation
  - Show error from spec (line 269)
  - Suggest adding data-testid

- [ ] **GREEN**: Implement error handling
  - Add validation after locator generation
  - Show actionable error
  - Offer to skip this step's POM generation

- [ ] **REFACTOR**: None needed

- [ ] **COMMIT**: "fix: handle locator generation failure"

---

## Final Integration Check

- [ ] **Verify Phase 1 → Phase 2 flow**: Command transitions smoothly after step definitions written
- [ ] **Verify agent delegation**: All three new agents properly delegated via Task tool
- [ ] **Verify error handling**: All error messages match spec and are actionable
- [ ] **Verify approval workflow**: Both approval files (POM approval and review) have clear instructions
- [ ] **Verify file paths**: All generated files use correct paths
- [ ] **Review agent frontmatter**: All new agents have proper tools, skills, examples

---

## Test Summary

| Category | # Items | Status |
|----------|---------|--------|
| Slice 1: UI Step Detection | 5 behaviors | [ ] |
| Slice 2: POM Indexing & Matching | 6 behaviors | [ ] |
| Slice 3: Approval & outerHTML Collection | 5 behaviors | [ ] |
| Slice 4: Locator & Code Generation | 11 behaviors | [ ] |
| Edge Cases | 6 cases | [ ] |
| **Total** | **33 items** | [ ] |

---

## Success Signal (from spec)

Developer can provide a feature file with UI scenario containing 4-5 steps where:
- 3 steps are classified as UI interactions
- 2 steps match existing page objects with high confidence (>70%)
- Developer approves: reuse 1 existing method, add 1 new method to existing POM
- 1 step has no POM match → developer creates new page object
- Developer provides outerHTML for 2 new methods
- Plugin generates locators using data-testid and role-based selectors
- Generated page object code matches repo's existing POM structure exactly
- Step definitions are updated to call page object methods (TODO comments replaced)
- Developer reviews and approves all generated POM code
- Generated code compiles without errors and tests can run

**Done when:** Developer can successfully implement a UI scenario using Phase 2 workflow where step definitions automatically call page object methods, new page object methods are generated with stable locators from outerHTML, and all code follows the repo's existing POM patterns without manual page object creation or locator writing.

---

[x] Reviewed
[x] Reviewed
