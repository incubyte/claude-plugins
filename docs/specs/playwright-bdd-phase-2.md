# Spec: Playwright-BDD Plugin — Phase 2 (Page Object Generation)

## Overview

Phase 2 extends Phase 1's step definition workflow to generate supporting page object code for UI test steps. After step definitions are generated in Phase 1, Phase 2 analyzes each new step to detect if it requires page object methods (UI interactions like click, fill, navigate). For UI steps, the plugin performs semantic similarity matching against existing page objects (using the same confidence-based approach as step matching), shows POM candidates with confidence scores, and either reuses existing page objects or generates new page object methods/classes when needed. All page object code follows the repo's existing POM patterns (detected from the codebase), and the developer provides HTML outerHTML for accurate locator generation. Generated page objects are wired into step definitions, presented for approval, and written to disk after developer confirms.

**What Phase 2 Delivers:**
- UI step detection (identify steps that require page interactions)
- Page object semantic matching with confidence scores (same 50% threshold as step matching)
- POM candidate display showing existing page objects that might handle this step
- Developer choice: reuse existing POM, extend existing POM with new method, or create new POM class
- outerHTML collection from developer for locator generation
- Page object code generation following repo's existing POM structure patterns
- Step definition updates to wire in page object method calls
- File-based approval workflow for generated POM code with `[ ] Reviewed` checkpoint

**Phase 2 builds on Phase 1:** Phase 1 generates step definitions with `// TODO: Implement step` comments. Phase 2 replaces those TODOs with page object method calls for UI steps, and generates the corresponding page object code.

## Acceptance Criteria

### Workflow Integration with Phase 1

- [ ] Phase 2 starts automatically after Phase 1 completes step definition generation for a scenario
- [ ] Before generating page objects, show message: "Analyzing steps for page object requirements..."
- [ ] Process steps in order (Given → When → Then) to maintain flow context
- [ ] For each step definition generated in Phase 1, analyze whether it requires UI interaction
- [ ] If no UI steps detected in scenario (all API/data steps), skip Phase 2 entirely and show: "No UI interactions detected. Scenario complete."
- [ ] After all POM generation completes, ask: "Continue to next scenario? [Yes / No]" (same flow as Phase 1)

### UI Step Detection

- [ ] Analyze step text using LLM to classify step type: "UI interaction" vs "API call" vs "data setup" vs "assertion"
- [ ] UI interaction keywords: navigate, click, enter, fill, select, type, press, upload, drag, scroll, hover, check, uncheck, toggle, open, close, expand, collapse, submit
- [ ] Classify as UI step if step text contains UI interaction keywords OR mentions page/screen/button/form/input/link elements
- [ ] For Given steps: likely UI if mentions navigation ("user is on X page", "user navigates to X")
- [ ] For When steps: likely UI if mentions user action ("user clicks X", "user enters Y", "user selects Z")
- [ ] For Then steps: likely UI if mentions visual verification ("page shows X", "button is visible", "error message displays")
- [ ] If step classification is ambiguous, ask developer: "Does this step require UI interaction? [Yes / No / Skip for now]"
- [ ] If "Skip for now", leave step definition as-is with `// TODO: Implement step` comment

### Page Object Indexing

- [ ] Scan repo for existing page object files (src/pages/**/*.ts, src/pages/**/*.js patterns)
- [ ] Parse each page object class to extract: class name, file path, methods (name + parameters), locators (selectors defined in class)
- [ ] Index page object methods with their intent (e.g., `clickSearchButton()`, `fillEmailInput()`, `navigateToHomePage()`)
- [ ] Track which step definitions currently call methods on each page object (by searching step definition files for POM imports and method calls)
- [ ] If no existing page objects found, show: "No existing page objects detected. Will create new page objects for all UI steps."

### Page Object Semantic Matching

- [ ] For each UI step, perform LLM-based semantic similarity matching against all indexed page object classes
- [ ] Compare step text against: page object class name + existing method names in that class
- [ ] Use same confidence scoring as Phase 1 (0-100 scale)
- [ ] Hide matches with confidence score below 50%
- [ ] Match at two levels:
  1. **Class-level match:** "Should this step use SearchPage class?" (based on page name in step text)
  2. **Method-level match:** "Does SearchPage already have a method for this action?" (based on action in step text)
- [ ] If class match >70% AND method match >70%, suggest: "Reuse existing method"
- [ ] If class match >70% AND method match <50%, suggest: "Add new method to existing class"
- [ ] If class match <50%, suggest: "Create new page object class"

### POM Candidate Display

- [ ] For each UI step with matches ≥50% confidence, show candidates in this format:

```
Step: "user clicks the search button"

Page Object Candidates:
1. SearchPage - 85% confidence
   Existing methods: navigateToSearch(), fillSearchInput(), getSearchResults()
   Used in: search.steps.ts (3 methods), advanced-search.steps.ts (1 method)

   Method match: No existing method for "click search button" action

2. HomePage - 62% confidence
   Existing methods: navigateToHome(), clickHeaderLink(), getPageTitle()
   Used in: home.steps.ts (2 methods)

   Method match: clickHeaderLink() - 55% confidence

Decision:
- [ ] Add new method to SearchPage (Recommended)
- [ ] Reuse HomePage.clickHeaderLink()
- [ ] Create new page object
```

- [ ] Show class confidence score and existing methods in that class
- [ ] Show which step definition files use this page object (with method count)
- [ ] If existing method is a close match, highlight it with confidence score
- [ ] Recommend the highest-confidence option
- [ ] Present all UI steps in the scenario for POM decisions in a single approval file before code generation

### Approval Workflow — POM Decisions

- [ ] Create approval file at `docs/specs/playwright-bdd-pom-approval-[feature-name]-scenario-[N].md`
- [ ] Use checkbox format: `[ ] Add new method to [Class]`, `[ ] Reuse [Class].[method]()`, `[ ] Create new page object`
- [ ] Wait for developer to check exactly one box per UI step before proceeding
- [ ] If developer checks multiple boxes for one step, error: "Please select only one decision per step"
- [ ] If developer checks no boxes for any step, error: "Please make a POM decision for all UI steps before proceeding"

### outerHTML Collection

- [ ] For each UI step that needs new page object method OR new page object class, ask developer for outerHTML
- [ ] Show prompt: "Provide HTML outerHTML for: [step text]. Paste the outerHTML of the target element from browser DevTools."
- [ ] Accept multiline HTML input (entire outerHTML snippet including attributes, nested elements)
- [ ] Validate HTML structure (must be valid HTML, not plain text or CSS selector)
- [ ] If invalid HTML provided, error: "Invalid HTML. Please provide complete outerHTML from DevTools (right-click element → Copy → Copy outerHTML)."
- [ ] Store outerHTML for locator analysis (do not ask for outerHTML again if same step analyzed multiple times)
- [ ] If developer says "Skip" or "I don't have it yet", leave that step's page object generation incomplete with `// TODO: Add page object method` comment

### Locator Generation from outerHTML

- [ ] Parse outerHTML to extract key attributes: id, class, data-testid, aria-label, role, name, placeholder, type
- [ ] Prioritize attributes for locator in this order:
  1. `data-testid` (most stable)
  2. `id` (stable if not dynamically generated)
  3. `aria-label` or `role` (accessibility-friendly)
  4. `name` (for form inputs)
  5. Class + text content combination (less stable, last resort)
- [ ] Generate Playwright locator following best practices:
  - Prefer `page.getByTestId('...')` if data-testid exists
  - Prefer `page.getByRole('button', { name: '...' })` for semantic elements
  - Prefer `page.getByLabel('...')` for form inputs with labels
  - Use `page.locator('#id')` if id is stable
  - Use `page.locator('.class')` only if no better option
- [ ] If element has no stable attributes, warn: "No stable selector found. Generated locator may be fragile: [locator]. Consider adding data-testid to element."
- [ ] Never generate XPath selectors (Playwright best practice)
- [ ] Never generate CSS selectors with nth-child or complex nesting (brittle)

### Page Object Pattern Detection

- [ ] Analyze existing page object files to detect code structure patterns:
  - Class naming convention (e.g., `SearchPage`, `LoginPage`, `PageObjectName`)
  - Constructor parameters (e.g., `constructor(private page: Page)`)
  - Locator definition style (e.g., private properties, getter methods, inline in methods)
  - Method naming convention (e.g., `clickButton()`, `fillInput()`, `navigateTo()`)
  - Method return types (e.g., `Promise<void>`, `Promise<string>`, chaining with `this`)
  - Import statements and formatting
- [ ] Match detected pattern exactly when generating new page objects or methods
- [ ] If no existing page objects found (empty repo), use minimal template:

```typescript
export class PageName {
  constructor(private page: Page) {}

  async methodName() {
    // implementation
  }
}
```

### Code Generation — New Page Object Method

- [ ] When adding method to existing page object class:
  1. Read existing page object file
  2. Analyze method structure (async/await, return type, parameter style)
  3. Generate new method matching existing method patterns exactly
  4. Insert new method at end of class (before closing brace)
  5. Add locator if needed (following class's locator definition style)
- [ ] Generated method name follows class naming convention:
  - If class uses `click*` prefix: generate `clickSearchButton()`
  - If class uses verb-only: generate `search()`
  - If class uses full action: generate `clickOnSearchButton()`
- [ ] Method includes JSDoc comment if existing methods have JSDoc
- [ ] Method body uses locator generated from outerHTML
- [ ] For navigation steps, use `await this.page.goto('...')` or match existing navigation pattern
- [ ] For interaction steps, use `await this.locator.click()` or `.fill()` or `.selectOption()` etc.
- [ ] For assertion steps, return value or throw error (match existing pattern)

### Code Generation — New Page Object Class

- [ ] When creating new page object class:
  1. Derive class name from page/feature mentioned in step text (e.g., "search page" → `SearchPage`)
  2. Create file at `src/pages/[page-name].page.ts` (match existing file naming pattern)
  3. Generate class with constructor, locators, and methods
  4. Include all locators needed for this step at top of class
  5. Include method for this step action
  6. Use same imports, formatting, and structure as existing page objects
- [ ] Class name uses PascalCase and ends with "Page" (unless existing pattern differs)
- [ ] File name uses kebab-case and ends with `.page.ts` or `.page.js` (match existing pattern)
- [ ] If multiple UI steps in scenario target same new page, group all methods in one class

### Code Generation — Step Definition Updates

- [ ] Update step definition to replace `// TODO: Implement step` with page object method call
- [ ] Add page object import at top of step definition file (following existing import style)
- [ ] Instantiate page object and call method:

```typescript
Given('user clicks the search button', async ({ page }) => {
  const searchPage = new SearchPage(page);
  await searchPage.clickSearchButton();
});
```

- [ ] If step definition already has other page object imports, group new import with existing
- [ ] If step definition uses dependency injection (not direct instantiation), match existing pattern
- [ ] Preserve any existing code in step definition (don't overwrite non-TODO content)

### Code Generation — Review File

- [ ] Create single review file for all generated POM code at `docs/specs/playwright-bdd-pom-review-[feature-name]-scenario-[N].md`
- [ ] Include both updated step definitions AND page object code (new methods or new classes)
- [ ] Show file path, full code block for each change, organized by step
- [ ] Format:

```markdown
# Generated Page Objects - [Feature Name] Scenario [N]

## Step: "user clicks the search button"

### Updated: src/steps/search.steps.ts

```typescript
import { Given } from '@cucumber/cucumber';
import { SearchPage } from '../pages/search.page';

Given('user clicks the search button', async ({ page }) => {
  const searchPage = new SearchPage(page);
  await searchPage.clickSearchButton();
});
```

### Updated: src/pages/search.page.ts

```typescript
// ... existing code ...

async clickSearchButton() {
  await this.page.getByTestId('search-button').click();
}

// ... existing code ...
```

## Step: "user enters search term {string}"

### Updated: src/steps/search.steps.ts

```typescript
When('user enters search term {string}', async ({ page }, searchTerm: string) => {
  const searchPage = new SearchPage(page);
  await searchPage.fillSearchInput(searchTerm);
});
```

### Updated: src/pages/search.page.ts

```typescript
async fillSearchInput(text: string) {
  await this.page.getByLabel('Search').fill(text);
}
```

- [ ] Reviewed
```

- [ ] Wait for developer to check `[ ] Reviewed` before writing files to disk
- [ ] After approval, write all updated step definition files AND page object files to disk
- [ ] Confirm completion: "Page objects written to [file paths]. Step definitions updated in [file paths]. Scenario [N] complete."

### Error Handling

- [ ] If page object indexing fails (parse error in existing POM), warn: "Could not parse [file path]. Skipping this page object in matching."
- [ ] If semantic matching API call fails for POM matching, retry once, then error: "POM matching failed for step '[step text]'. [error details]"
- [ ] If outerHTML parsing fails (invalid HTML), error: "Could not parse outerHTML. Please provide valid HTML from DevTools."
- [ ] If locator generation produces no selector, error: "Could not generate locator from outerHTML. Element has no identifiable attributes. Consider adding data-testid."
- [ ] If code generation fails (template analysis error for POM), error: "Could not generate page object code for '[step text]'. [error details]"
- [ ] If file write fails for POM files, error: "Could not write file [path]. [error details]"
- [ ] All errors include actionable next steps for developer

## Edge Cases

### No UI Steps in Scenario
- When all steps are classified as non-UI (API calls, data setup, assertions without visual verification):
  - Show single message: "No UI interactions detected. Scenario complete."
  - Skip POM matching and generation phases entirely
  - Move to next scenario (if multi-scenario feature) or exit
- Example scenario with no UI:
  ```gherkin
  Given API is available
  When user submits order via API
  Then order status is "confirmed"
  ```

### No Existing Page Objects (Empty Repo)
- When indexing finds zero page object files:
  - Show: "No existing page objects detected. Will create new page objects for all UI steps."
  - Skip POM matching phase (no candidates to show)
  - For each UI step, ask: "What page should this step belong to? Provide page name (e.g., 'Search', 'Login', 'Checkout'):"
  - Create new page object class for each unique page name
  - Use minimal template (no existing patterns to analyze)

### Ambiguous UI Step Classification
- When LLM cannot confidently classify step as UI or non-UI:
  - Ask developer: "Does '[step text]' require UI interaction? [Yes / No / Skip for now]"
  - If "Yes": proceed with POM matching
  - If "No": skip POM generation, leave step definition as-is
  - If "Skip for now": leave `// TODO: Implement step` comment, move to next step
- Example ambiguous steps:
  - "user waits 2 seconds" (could be UI wait or arbitrary delay)
  - "order is created" (could be UI form submission or API call)

### Zero High-Confidence POM Matches
- When all page object match scores are below 50%:
  - Show: "No matching page objects found."
  - Present decision:
    ```
    Decision:
    - [ ] Create new page object
    - [ ] Add to existing page object (show dropdown with all existing POM classes)
    ```
  - If developer chooses existing class, ask: "Which page object class should this step use?" with list of all existing classes
  - Proceed with code generation using developer's choice

### Multiple Steps Target Same New Page Object
- When scenario has 3 steps that all create new page objects and developer names them all "SearchPage":
  - Detect duplicate page name during approval phase
  - Group all methods into single SearchPage class
  - Show in review file: one SearchPage class with all 3 methods
  - Do not create SearchPage1, SearchPage2, SearchPage3 (consolidate)

### Invalid or Missing outerHTML
- When developer provides invalid HTML or says "I don't have it yet":
  - If invalid: error immediately with example of correct format
  - If missing: ask "Skip this step's page object generation? [Yes / No]"
  - If "Yes": leave step definition with `// TODO: Add page object method` comment
  - If "No": re-prompt for outerHTML with more guidance
- Example error message:
  ```
  Invalid HTML provided. Please copy outerHTML from browser DevTools:
  1. Right-click element in browser
  2. Select "Inspect" to open DevTools
  3. Right-click element in Elements tab
  4. Select "Copy" → "Copy outerHTML"
  5. Paste here
  ```

### Unstable Locators (No data-testid)
- When outerHTML has no stable attributes (no data-testid, no id, only generated class names):
  - Generate best-effort locator (e.g., role + text, or class + text)
  - Include warning comment in generated code:
    ```typescript
    // WARNING: Fragile locator. Consider adding data-testid="search-button" to element.
    await this.page.locator('.btn-primary').click();
    ```
  - Show warning in review file: "Locator for '[step]' may be fragile. Consider improving element attributes."
  - Developer can approve with warning or reject and provide better outerHTML

### Hybrid Repo (Phase 1 Stored "Both" Answer)
- When Phase 1 detected hybrid repo and developer answered "Both" for implementation:
  - Phase 2 runs for UI path only
  - Phase 3 will handle API path (out of scope for Phase 2)
  - Show message: "Implementing UI path. API path will be handled in next phase."

### Existing Page Object with Conflicting Method Name
- When generating new method but existing page object already has method with same name:
  - Detect naming conflict during code generation
  - Append number to method name: `clickSearchButton()` → `clickSearchButton2()`
  - Show in review file with comment:
    ```typescript
    // Note: Renamed to clickSearchButton2() to avoid conflict with existing method
    async clickSearchButton2() {
      await this.page.getByTestId('search-button').click();
    }
    ```
  - Developer can approve auto-renamed method or manually rename in review

### Step Definition File Already Imports Same Page Object
- When step definition file already imports `SearchPage` and new step also uses `SearchPage`:
  - Do not add duplicate import
  - Reuse existing import statement
  - Add new method call only in step definition body

## Workflow Diagram

```
Phase 1 completes (step definitions generated with TODO comments)
    ↓
Show: "Analyzing steps for page object requirements..."
    ↓
For each step definition: classify as UI vs non-UI
    ↓
If no UI steps: show "No UI interactions detected" and exit Phase 2
    ↓
Index existing page objects (scan src/pages/, parse classes and methods)
    ↓
If no POMs found: show "Will create new page objects" and skip matching
    ↓
For each UI step: perform LLM-based semantic matching against page objects
    ↓
Generate POM approval file with candidates (class-level + method-level matches)
    ↓
Developer approves: reuse existing method / add new method to class / create new class
    ↓
For each decision that needs new code:
  → Ask developer for outerHTML of target element
  → Validate HTML structure
  → Parse outerHTML to extract attributes
  → Generate Playwright locator (prioritize data-testid, role, label)
  → Warn if locator is fragile (no stable attributes)
    ↓
Analyze existing page objects to detect code structure patterns
    ↓
Generate new page object methods OR new page object classes (match repo patterns)
    ↓
Update step definitions to replace TODO comments with POM method calls
    ↓
Present review file with updated step defs + POM code + [ ] Reviewed checkbox
    ↓
Developer checks [ ] Reviewed
    ↓
Write step definition files and page object files to disk
    ↓
Confirm: "Page objects written. Step definitions updated."
    ↓
Ask: "Continue to next scenario? [Yes/No]"
    ↓
If Yes: repeat Phase 1 + Phase 2 for next scenario
If No: exit with summary
```

## API Shape (Internal)

### UI Step Classification LLM Prompt Template
```
Classify this test step as UI interaction or non-UI action.

Step text: "[step text]"

UI interaction indicators:
- Navigation: navigate, go to, visit, open, on page, at page
- Clicks: click, press, tap, select, choose
- Input: enter, fill, type, input, upload, paste
- Visual: see, visible, displayed, shows, appears, hidden
- Forms: submit, check, uncheck, toggle, enable, disable

Respond with ONLY: "UI" or "NON-UI"
```

### Page Object Semantic Matching LLM Prompt Template
```
Compare test step with page object class to determine if this page object should handle the step.

Step text: "[step text]"
Page object class name: "[ClassName]"
Existing methods in class: [method1(), method2(), method3()]

Rate similarity on 0-100 scale where:
- 100 = step clearly belongs to this page (page name mentioned in step)
- 70-99 = step likely belongs to this page (related page concept)
- 50-69 = step might belong to this page (ambiguous)
- 0-49 = step does not belong to this page

Respond with ONLY a number 0-100.
```

### Page Object Index Structure
```typescript
interface PageObject {
  className: string;               // e.g., "SearchPage"
  filePath: string;                // e.g., "/repo/src/pages/search.page.ts"
  methods: Array<{
    name: string;                  // e.g., "clickSearchButton"
    parameters: string[];          // e.g., ["searchTerm: string"]
    returnType: string;            // e.g., "Promise<void>"
    lineNumber: number;
  }>;
  locators: Array<{
    name: string;                  // e.g., "searchButton"
    selector: string;              // e.g., "page.getByTestId('search-btn')"
    lineNumber: number;
  }>;
  usedInSteps: string[];          // step definition file paths that import this POM
}
```

### Generated Locator Examples
```typescript
// Best case: data-testid
await this.page.getByTestId('search-button').click();

// Good: role + name
await this.page.getByRole('button', { name: 'Search' }).click();

// Good: label for inputs
await this.page.getByLabel('Email address').fill(email);

// Acceptable: stable id
await this.page.locator('#search-btn').click();

// Last resort: class + text (fragile warning)
// WARNING: Fragile locator. Consider adding data-testid="search-button".
await this.page.locator('.btn-primary:has-text("Search")').click();
```

## Out of Scope for Phase 2

- **API service layer generation** — deferred to Phase 3
- **Utility function generation** — deferred to Phase 4
- **Test data management** — fixtures, test data files are separate concerns
- **Custom Playwright matchers** — Phase 2 uses built-in Playwright assertions only
- **Visual regression testing** — screenshot comparison not covered
- **Multi-page flows** — Phase 2 handles each step independently; complex flows across pages are manual
- **Page object refactoring** — Phase 2 only adds methods or creates new classes (no modification of existing methods)
- **Locator optimization** — Phase 2 generates one locator per element; optimization is manual
- **Shadow DOM support** — Phase 2 handles standard DOM only
- **iFrame handling** — Phase 2 assumes single-page context
- **Dynamic element waiting** — Phase 2 generates basic locators; custom wait conditions are manual
- **Mobile/responsive testing** — Phase 2 generates desktop locators only
- **Browser-specific locators** — Phase 2 generates Playwright cross-browser locators

## Technical Context

- **Patterns to follow:** incubyte/playwright-bdd-hybrid-framework (reference for page object structure, locator patterns, method naming conventions)
- **Key dependencies:** Phase 1 (step definitions with TODO comments), context-gatherer agent (POM pattern detection), Gherkin parser (step text extraction), Claude API (UI classification, POM semantic matching), HTML parser (outerHTML → locator generation)
- **Files to extend:**
  - `bee/commands/playwright-bdd.md` (add Phase 2 orchestration after Phase 1)
  - `bee/agents/playwright-pom-matcher.md` (new agent for POM semantic matching)
  - `bee/agents/playwright-pom-generator.md` (new agent for POM code generation)
  - `bee/agents/playwright-locator-generator.md` (new agent for outerHTML → locator conversion)
- **Approval workflow:** File-based with `[ ] Reviewed` checkboxes (consistent with Phase 1 and bee collaboration loop)
- **Risk level:** MODERATE — LLM-based UI classification can be ambiguous, outerHTML input quality varies, locator stability depends on frontend code quality, POM pattern detection must handle varied structures

## Success Signal

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

- [x] Reviewed
[x] Reviewed
