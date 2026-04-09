# Discovery: Playwright-BDD Test Generation

## Why

When QA teams provide test scenarios, they write them in natural, inconsistent language. A QA might write "A search is made using doctors name" when there's already an existing step definition for "user searches by Doctor name." Developers must manually scan through step definitions to find reusable steps, often missing close matches and creating duplicates. Sometimes the right move is to modify an existing step definition rather than write a new one, but finding that opportunity requires scanning every step file. This wastes time, creates maintenance burden from duplicate steps, and breaks the reuse patterns that make BDD frameworks valuable.

## Who

**Developers implementing Playwright-BDD tests** -- they receive feature files with scenarios from QA teams and need to convert them into working test code. They work in codebases that may be UI-only (features → step definitions → page objects → utilities), API-only (features → step definitions → services → utilities), or hybrid (both UI and API layers). They need help identifying reusable step definitions, generating new ones when needed, and building out the supporting page objects, services, and utilities following their repo's existing patterns.

## Success Criteria

- Developer receives a feature file from QA and can generate working test code without manually scanning for reusable steps
- Plugin detects when an existing step definition is a close semantic match and surfaces it with confidence scores, reducing duplicate step creation
- Generated code follows the repo's existing patterns -- detected automatically from repo structure and reference framework (incubyte/playwright-bdd-hybrid-framework)
- Each scenario is implemented step-by-step with approval checkpoints, not generated in one shot
- For hybrid repos, plugin asks what needs implementation (UI, API, or both) and handles each accordingly
- Generated tests can be executed using existing package.json scripts without manual configuration

## Problem Statement

Developers implementing Playwright-BDD tests face a manual, error-prone workflow when converting QA scenarios into code. QA teams write scenarios in varied language with no consistency, making it hard to identify when an existing step definition could be reused. Developers must manually search through step definition files, often missing close matches and creating duplicate steps. Sometimes the right move is parameterizing an existing step instead of writing a new one, but discovering that opportunity requires scanning every step and understanding its usage context. This leads to wasted implementation time, accumulating technical debt from duplicates, and missed opportunities to strengthen the test suite's reusability. This plugin turns that manual, fragile process into a guided workflow where semantic step matching surfaces reuse opportunities with confidence scores, code generation follows the repo's existing patterns, and the developer maintains control through approval checkpoints at every decision.

## Hypotheses

- H1: Semantic similarity scoring can reliably identify when a new scenario step matches an existing step definition closely enough to reuse (with developer confirmation) -- this reduces duplicate step creation without false positives that break tests
- H2: Showing developers which feature files currently use a step definition provides enough context to confidently decide reuse vs. create new -- the usage context is more valuable than showing the step's implementation code
- H3: Detecting repo structure (UI-only, API-only, hybrid) from directory patterns (src/pages/, src/services/) is sufficient to generate code in the right layers without asking the developer about architecture every time
- H4: For scenario outline conversion, detecting "only keywords changing with constant flow" is specific enough that suggesting conversions on-demand (not automatic) keeps false positives low
- H5: Step-by-step code generation (step definition → page object/service → utility, with approval after each) provides enough control that developers trust the output without needing to review everything after the fact
- H6: Analyzing existing page objects and services with confidence-based matching (like step matching) reduces "which POM should this use?" questions to edge cases where similarity is genuinely ambiguous
- H7: Parsing package.json scripts to find test execution commands is reliable enough to run generated tests without asking the developer about test runners or configurations

## Out of Scope

- Test data management -- fixtures, test data files, and data generation strategies are handled separately by developers
- Environment configuration -- changes to playwright.config.ts, environment variables, and test environment setup are outside this workflow
- CI/CD integration -- pipeline configuration, test orchestration in CI, and deployment of test suites remain manual tasks
- Scenario authoring or validation -- this assumes QA has already written the feature file; it doesn't help QAs write better scenarios or validate Gherkin syntax

## Milestone Map

### Phase 1: Core Step Matching and Step Definition Generation

The walking skeleton -- a developer can provide a feature file, get semantic matches for existing step definitions with confidence scores, approve reuse vs. create decisions, and generate new step definition code for a single scenario. No page objects, no services, just step definitions. This proves the semantic matching engine works and establishes the approval workflow.

- Developer invokes `/bee:playwright path/to/feature.feature`
- Plugin uses context-gatherer to analyze repo structure (detect UI/API/hybrid from directory patterns)
@bee in case of hybrid ask user what needs to be implemented UI/API/Both
- Plugin analyzes existing step definition files and indexes them for semantic matching
- For the first scenario in the feature file, plugin analyzes each Given/When/Then step
- For each step, plugin performs semantic similarity search against existing step definitions and returns ranked candidates with confidence scores
- Plugin shows matches with context: confidence score + which feature files currently use this step definition
- Developer approves reuse vs. create new for each step (file-based approval with checkboxes)
- For steps marked "create new," plugin generates step definition code following detected repo patterns
- Plugin presents generated step definitions in a review file with `[ ] Reviewed` checkbox
- Developer approves, plugin commits code, scenario is marked complete

**Success signal:** Developer can implement a simple scenario (3-5 steps) where 2 steps are reused and 3 are newly generated, with approval checkpoints surfacing the right existing steps and generating syntactically correct new ones.

### Phase 2: Page Object and Service Layer Generation for UI Tests

Extends Phase 1 to generate supporting page object code for UI test steps. When a step definition needs a page interaction (click, fill, navigate), the plugin detects which page object should handle it, reuses existing page objects where possible, and generates new page objects or methods when needed.

- After step definition generation, plugin analyzes each new step to detect if it requires page object methods (UI interactions)
- For UI steps, plugin performs similarity matching against existing page objects (same confidence-based approach as step matching)
- Plugin shows POM candidates: "SearchPage exists with 85% confidence based on step text 'user is on search page'"
- If no confident match, plugin asks: "Which page object should this step use? [Existing list / Create new]"
@bee incase of create New ask user to provide HTML body of element to be created or page to understnd what all new elements are required and use exisitng structure of oblect selection
- Plugin generates page object methods or new page object classes following repo's page object patterns (detected from existing POMs)
- Plugin presents generated POM code for approval
- After approval, scenario is complete with step definitions and page objects wired together

**Success signal:** Developer can implement a UI scenario where step definitions correctly call methods on existing page objects for some steps, and new page object methods are generated for others, with the plugin asking only when POM matching is genuinely ambiguous.

### Phase 3: Service Layer Generation for API Tests

Parallel to Phase 2, but for API test steps. When a step definition makes an API call, the plugin detects which service layer method should handle it, reuses existing services, and generates new service methods when needed.

- After step definition generation, plugin analyzes each new step to detect if it requires API service methods (HTTP calls)
- Plugin performs similarity matching against existing service layer files
- Plugin shows service candidates with confidence scores
- For API responses, plugin either logs response from actual API call OR asks developer for response JSON structure (to generate type-safe parsing)
- Plugin generates service layer methods following repo's service patterns (detected from existing services)
- Plugin presents generated service code for approval

**Success signal:** Developer can implement an API scenario where step definitions correctly call existing service methods for some steps, new service methods are generated for others, and API response handling is either inferred or user-provided.

### Phase 4: Hybrid Repo Support and Utility Generation

Adds support for repos with both UI and API layers, and generates utility functions when genuinely needed (not inline in step definitions or page objects). Handles the developer's requirement that if a scenario should be implemented for "both" UI and API, it's done UI-first, then API.

- At workflow start, if repo structure is detected as hybrid (both src/pages/ and src/services/ exist), plugin asks: "What needs implementation for this scenario? [UI only / API only / Both]"
- If "Both," plugin implements UI path completely (step defs + POMs + utilities), presents for approval, then implements API path (step defs + services + utilities)
- When generating step definition, POM, or service code, plugin detects if complex logic should be extracted to a utility (e.g., data transformation, reusable helper)
- Plugin performs similarity matching against existing utilities
- Plugin asks: "Should this logic be a utility function, or inline in [step definition/POM/service]?"
- Plugin generates utility code following repo patterns if approved

**Success signal:** Developer working in a hybrid repo can implement a scenario for both UI and API paths without manually duplicating work, and utility functions are suggested only when logic is genuinely complex or reusable, not for every helper.

### Phase 5: Scenario Outline Conversion and Test Execution

Adds on-demand scenario outline conversion (parameterizing scenarios with Examples tables) and test execution integration. Developer can request outline analysis, approve conversions, and run generated tests using existing package.json scripts.

- Developer can invoke plugin with `--suggest-outlines` flag or answer "yes" to "Analyze for scenario outline opportunities?"
- Plugin detects scenarios in the feature file where "only keywords change, rest of flow is constant"
- Plugin presents outline conversion suggestions: shows which scenarios would merge, what the Examples table would look like
- Developer approves conversions scenario-by-scenario
- Plugin rewrites feature file with scenario outlines, updates or creates parameterized step definitions
- After code generation, plugin parses package.json to detect test execution scripts (e.g., `npm run test:bdd`, `npm run test:api`)
- Plugin asks: "Run tests now using [detected script]? [Yes / No / Use different script]"
- Plugin executes tests, captures output, presents results

**Success signal:** Developer can convert 3 similar scenarios into a scenario outline with an Examples table, generate parameterized step definitions, and execute the tests using their repo's existing test scripts without manually running npm commands.

## Open Questions

- How should confidence score thresholds be set for step matching? Should scores below 60% be hidden entirely, or always shown with a "low confidence" warning? This affects how many false positives the developer sees. 
@bee anything below 50% confidence should be hidden
- When generating page object methods, should the plugin infer locators from step text (e.g., "search button" → `page.locator('button:has-text("Search")')`), or always ask the developer for locators? Inference saves time but risks incorrect selectors.
@bee always asks developer to provide outerhtml
- For API response parsing in Phase 3, when should the plugin attempt to call the API to log the response vs. ask the developer for JSON structure? If the API requires authentication or setup, automatic calls may fail.
@bee idealy as we follow step by step structure the previous step should provide JSON structure which could be logged , we are follwinng this structure so each step provides input for next step.
- Should the plugin support batch mode where a developer approves all step matches across all scenarios in a feature file upfront, then watches code generation happen scenario-by-scenario? Or always require per-scenario approval before generation starts?
@bee always go on pre scenario basis as if we give a complete lot user might not read it and which might cause a lot of rework at end
- When scenario outline conversion changes step definitions to accept parameters, should the plugin automatically update all feature files that use those steps, or only update the current file and warn about others?
@bee in case we identified an existing step which can be converted for scenario outline it that case we should also update existing feature files also

## Key Workflow Details

### Repo Structure Detection

Plugin uses context-gatherer to analyze directory patterns:
- **UI-only**: `features/` + `src/steps/` + `src/pages/` + `src/utils/` (no src/services/)
- **API-only**: `features/` + `src/steps/` + `src/services/` + `src/utils/` (no src/pages/)
- **Hybrid**: Both `src/pages/` and `src/services/` exist

Detection happens once at workflow start. For hybrid repos, plugin asks explicitly what needs implementation (UI / API / both).

### Step Matching Display Format

When showing step match candidates:

```
Step: "A search is made using doctors name"

Candidates:
1. "user searches by Doctor name" - 85% confidence
   Used in: features/search/doctor-search.feature (line 12), features/admin/user-management.feature (line 34)

2. "user performs search using name" - 72% confidence
   Used in: features/search/patient-search.feature (line 8)

3. "a search is made for doctor" - 68% confidence
   Used in: features/search/advanced-search.feature (line 45)

Choose: [Reuse #1 / Reuse #2 / Reuse #3 / Create new step]
```

Developer sees confidence score + usage context (which feature files use this step). This is enough to make the reuse decision without seeing step implementation code.

### Step-by-Step Code Generation Flow

For each scenario:
1. Plugin analyzes all steps and shows match candidates for all steps
2. Developer approves reuse vs. create decisions for all steps (one approval checkpoint)
3. Plugin generates code step-by-step:
   - **Step 1**: Generate step definition → present for approval → generate POM/service (if needed) → present for approval → generate utility (if needed) → present for approval
   - **Step 2**: Same flow
   - **Step 3**: Same flow
4. After all steps complete, scenario is done → move to next scenario

Each approval uses file-based review with `[ ] Reviewed` checkbox (consistent with bee's collaboration loop).

### Scenario Outline Conversion Logic

Plugin suggests scenario outline conversion when:
- Multiple scenarios in the same feature file
- Same step structure (same Given/When/Then flow)
- Only specific keywords/data values change (not step types or flow)

Conversion is **opt-in** (not automatic). Developer must explicitly request outline analysis or answer "yes" to a prompt. Plugin shows which scenarios would merge and what the Examples table would be, developer approves each conversion.

### Test Execution Integration

After code generation completes:
1. Plugin reads package.json and looks for scripts matching patterns: `test`, `test:bdd`, `test:e2e`, `test:api`, `playwright`, etc.
2. Plugin shows detected scripts: "Found test scripts: npm run test:bdd, npm run test:api. Which should I use?"
3. Developer picks a script or provides a custom command
4. Plugin executes the command, captures output, presents results in a readable format

No changes to playwright.config.ts or environment setup -- plugin uses what's already configured.

## Technical Constraints

- **Extension to bee plugin** -- not a standalone tool; integrates as a bee command following existing orchestration patterns
- **File-based approval with checkboxes** -- all approval checkpoints use `[ ] Reviewed` format consistent with bee's collaboration loop
- **Reuse context-gatherer agent** -- for repo structure analysis and pattern detection; don't reimplement codebase understanding
- **Follow reference framework patterns** -- study https://github.com/incubyte/playwright-bdd-hybrid-framework for step definition structure, page object patterns, service layer conventions, and utility organization
- **Semantic matching engine** -- requires embedding model or similarity scoring approach for step matching (implementation detail for builder, but discovery should acknowledge this is non-trivial)

## Revised Assessment

Size: **EPIC** -- this has 5 distinct phases, each delivering independently valuable capabilities. Phase 1 alone (step matching + step definition generation) is a meaningful unit of work. Phases 2-5 build incrementally on the foundation. Each phase could be a separate PR and deployment.

Greenfield: **no** -- this extends the existing bee plugin with a new command (commands/playwright-bdd.md or similar), following established orchestration patterns and reusing context-gatherer. The playwright-bdd framework repo patterns already exist as reference.

[X] Reviewed
