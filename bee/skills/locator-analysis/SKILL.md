# Identify Locators Skill

**Purpose**: Analyze any UI repository to identify available locators and provide a workflow for identifying selectors for testing, whether or not test automation currently exists.

**Trigger**: When the user asks "how to identify locators", "locator workflow", "how to find selectors", "identify locators for [page name]", or similar questions.

---

## Skill Execution Strategy

This skill has **two paths** depending on whether test automation exists:

### Path A: Repository WITH Test Automation
- Analyze existing test framework and patterns
- Document current locator strategy
- Provide workflow based on existing patterns

### Path B: Repository WITHOUT Test Automation (or starting fresh)
- Analyze UI framework and source code
- Identify available locators in components
- Recommend locator strategy
- Suggest where to add test attributes

---

## Step 1: Initial Repository Analysis

### 1.1 Detect UI Framework

**Read package.json and check for:**

```javascript
// Frontend frameworks
- react, react-dom, next
- vue, nuxt
- angular, @angular/core
- ember-source, ember-cli
- svelte, sveltekit
- solid-js
- preact

// Template engines
- handlebars, hbs
- ejs, pug, jade
```

### 1.2 Detect Testing Framework (if exists)

**Check package.json for test dependencies:**

```javascript
// Test frameworks
- cypress, @cypress/*
- playwright, @playwright/test
- selenium-webdriver, webdriverio
- puppeteer, puppeteer-core
- @testing-library/*, testing-library
- nightwatch, testcafe
- protractor (Angular)

// BDD frameworks
- @cucumber/cucumber, @badeball/cypress-cucumber-preprocessor
- jest-cucumber
```

### 1.3 Identify Project Structure

**Use Glob to find:**

```bash
# UI source directories
- app/**, src/**, components/**, pages/**
- lib/**, views/**, templates/**

# Test directories (if exist)
- cypress/**, test/**, tests/**, __tests__/**
- e2e/**, integration/**, spec/**
- features/** (BDD)
```

---

## Step 2: Analyze Based on Detection

### Path A: WITH Test Automation

#### 2A.1 Analyze Test Files

**Find and read 3-5 test files:**

```bash
# Search patterns
- **/*.spec.{js,ts,jsx,tsx}
- **/*.test.{js,ts,jsx,tsx}
- **/*.feature (Gherkin)
- **/e2e/**/*.{js,ts}
- **/cypress/integration/**/*.{js,ts}
```

#### 2A.2 Identify Locator Strategy

**Search for patterns in test files:**

```javascript
// Data attribute strategies
- data-test, data-testid, data-cy, data-qa
- data-automation-id, data-test-id
- test-id, testid

// Selector patterns
- cy.get('[data-test="..."]')
- screen.getByTestId('...')
- page.locator('[data-test="..."]')
- driver.findElement(By.css('[data-test="..."]'))

// Helper functions
- dt(), sel(), testId()
- getByDataTest(), clickDt()

// Accessibility selectors
- getByRole(), getByLabel(), getByText()
- role=, aria-label=
```

#### 2A.3 Find Helper Utilities

**Look for:**

```bash
- utils/dt.js, utils/selectors.js, utils/locators.js
- support/commands.js, support/helpers.js
- helpers/test-helpers.js
- page-objects/**, pages/**
```

### Path B: WITHOUT Test Automation

#### 2B.1 Analyze UI Source Code

**Search for existing test attributes in components:**

```bash
# Use Grep to find patterns
- data-test=
- data-testid=
- data-cy=
- data-qa=
- data-automation=
```

**Read sample component files** (5-10 files) to understand structure:

```bash
# Component patterns based on framework
# React: src/components/**/*.{jsx,tsx}
# Vue: src/components/**/*.vue
# Angular: src/app/**/*.component.{ts,html}
# Ember: app/components/**/*.{js,hbs}
# Svelte: src/**/*.svelte
```

#### 2B.2 Analyze Component Structure

**For each UI framework, identify:**

**React/JSX:**
```jsx
// Look for patterns like:
<button data-test="submit-button" />
<div data-testid="modal-container" />
<input id="email-input" />
<form className="login-form" />
```

**Vue:**
```vue
<template>
  <button data-test="submit-btn" />
  <div :data-test="`item-${id}`" />
</template>
```

**Angular:**
```html
<button data-test="submit-button" />
<div [attr.data-test]="'modal-' + id" />
```

**Ember/Handlebars:**
```handlebars
<button data-test="submit-button" />
<div data-test={{this.testId}} />
```

#### 2B.3 Identify Available Selectors

**Create inventory of what's available:**
- Semantic HTML elements (button, nav, form)
- IDs (if present)
- Classes (note: often unstable for testing)
- ARIA attributes (role, aria-label, aria-describedby)
- Text content
- Existing data-* attributes

---

## Step 3: Generate Workflow Document

### 3.1 Summary Section

**Provide clear summary:**

```markdown
## Repository Analysis Summary

**UI Framework**: [React/Vue/Angular/Ember/etc.]
**Test Automation**: [Yes - Cypress/Playwright/etc. | No - None detected]
**Locator Strategy**: [data-test | data-testid | Accessibility | Mixed | Not established]
**Component Structure**: [Component-based/Page-based/Mixed]
**Existing Patterns**: [List patterns found]
```

### 3.2 Detailed Workflow for the Specific Page

When user asks about a specific page (e.g., "maps page", "login page"):

#### For repos WITH test automation:

```markdown
## Workflow for [Page Name]

### 1. Find Existing Tests
- Location: [path to test files]
- Test file: [specific file if found]

### 2. Review Current Locators
[List all locators found in existing tests for this page]

### 3. Identify UI Components
[List component files that make up this page]

### 4. Available Selectors
[Table of elements and their current selectors]

### 5. Add New Locators (if needed)
[Step-by-step process based on their patterns]

### 6. Use in Tests
[Code examples using their conventions]
```

#### For repos WITHOUT test automation:

```markdown
## Workflow for [Page Name]

### 1. Locate Page Components
[List relevant component files]

### 2. Current Selector Inventory
| Element | Type | Current Selector Options | Recommendation |
|---------|------|-------------------------|----------------|
| Login Button | button | .btn-primary, #login-btn | Add data-test="login-button" |
| Email Input | input | .email-input, [name="email"] | Add data-test="email-input" |

### 3. Recommended Locator Strategy
[Suggest best approach for their framework]

### 4. Implementation Steps
[How to add data-test attributes to components]

### 5. Future Testing Setup
[Suggestions for test framework that would work well]
```

### 3.3 Best Practices Section

**Always include:**

```markdown
## Locator Best Practices

### Priority Order (Most to Least Stable):
1. **Accessibility attributes** - role, aria-label, aria-describedby
   - Benefit: Enforces accessibility
   - Example: `getByRole('button', { name: 'Submit' })`

2. **Data-test attributes** - data-test, data-testid
   - Benefit: Explicit test hooks
   - Example: `[data-test="submit-button"]`

3. **Semantic HTML** - button, nav, header, footer
   - Benefit: Meaningful structure
   - Example: `cy.get('nav').within(() => ...)`

4. **Text content** - getByText, contains
   - Benefit: User-facing
   - Caution: May change with copy updates

5. **IDs** (if stable) - #unique-id
   - Benefit: Fast, unique
   - Caution: May not be stable across environments

6. **Classes** (last resort) - .class-name
   - Caution: Often change with styling updates
   - Avoid: Tailwind/utility classes

### Anti-Patterns (Avoid):
❌ XPath (brittle, hard to read)
❌ Complex CSS selectors (div > div > span:nth-child(3))
❌ Styling classes (btn-primary, text-red-500)
❌ Positional selectors without context (.item:nth-child(5))
```

### 3.4 Framework-Specific Guidance

**Based on detected UI framework, provide specific advice:**

**For React:**
```jsx
// Recommended approach
<button data-test="submit-button" onClick={handleSubmit}>
  Submit
</button>

// Or using constants
const TEST_IDS = {
  SUBMIT_BUTTON: 'submit-button'
}

<button data-test={TEST_IDS.SUBMIT_BUTTON}>
```

**For Vue:**
```vue
<button data-test="submit-button" @click="submit">
  Submit
</button>
```

**For Angular:**
```typescript
<button data-test="submit-button" (click)="submit()">
  Submit
</button>
```

**For Ember/Handlebars:**
```handlebars
<button data-test="submit-button" {{on "click" this.submit}}>
  Submit
</button>
```

### 3.5 Code Examples from Codebase

**Include real examples:**

```markdown
## Examples from Your Codebase

### Current Pattern:
[Show actual code from their repo]

### How to Add New Locators:
[Show modified version with proper locators]

### How to Use in Tests:
[Show test code using their framework]
```

---

## Step 4: Page-Specific Analysis (When Requested)

When user asks about a specific page:

### 4.1 Find Page Components

```bash
# Search for page name in different patterns
- **/[page-name].{jsx,tsx,vue,hbs,html}
- **/[page-name]-page.{jsx,tsx,vue,hbs,html}
- **/pages/[page-name]/**
- **/views/[page-name]/**
- **/*-[page-name]*.{jsx,tsx,vue,hbs,html}

# Example for "maps" or "map"
- **/map.jsx, **/map-page.vue
- **/maps/**, **/map-view/**
```

### 4.2 Extract Elements

**Read the component file and identify:**
- All interactive elements (buttons, inputs, links)
- Major container/section elements
- Dynamic elements (lists, modals, tooltips)
- Form elements

### 4.3 Create Locator Map

**Generate a table:**

```markdown
## [Page Name] - Locator Map

| Element | Purpose | Current Selector | Recommended | Priority |
|---------|---------|------------------|-------------|----------|
| Search Button | Triggers search | .btn-search | data-test="search-button" | High |
| Map Container | Displays map | #map | data-test="map-container" | High |
| Zoom Controls | Map zoom | .mapbox-zoom | data-test="zoom-controls" | Medium |
| Result Cards | Shows results | .result-card | data-test="result-card" | High |
```

### 4.4 Provide Implementation Code

**Show exact changes needed:**

```markdown
## Implementation Steps

### 1. Update Component File
**File**: `app/components/map-view.jsx`

**Current**:
```jsx
<div className="map-container">
  <button className="zoom-in">+</button>
</div>
```

**Updated**:
```jsx
<div className="map-container" data-test="map-container">
  <button className="zoom-in" data-test="zoom-in-button">+</button>
</div>
```

### 2. Use in Tests (if automation exists)
**File**: `cypress/integration/map.spec.js`

```javascript
cy.get('[data-test="map-container"]').should('be.visible')
cy.get('[data-test="zoom-in-button"]').click()
```
```

---

## Step 5: Generate Quick Reference

**Create a cheat sheet:**

```markdown
## Quick Reference

### Finding Locators in This Project

1. **Check UI components**: `[path to components]`
2. **Check test files** (if exist): `[path to tests]`
3. **Search for pattern**: `[their data-test pattern]`

### Adding New Locators

```[language]
// Template for this project
[show their pattern]
```

### Using Locators in Tests

```[language]
// Using [their test framework]
[show examples]
```

### Common Locators in This Project

[If automation exists, list frequently used locators]

```

---

## Output Format

Present findings in this structure:

1. **📊 Repository Analysis**
   - UI Framework
   - Test automation status
   - Locator strategy
   - Key findings

2. **📋 Workflow for [Page Name]** (if specific page requested)
   - Component locations
   - Current locators
   - Recommendations
   - Implementation steps

3. **✅ Best Practices**
   - Locator priority guide
   - Framework-specific tips
   - Anti-patterns to avoid

4. **💻 Code Examples**
   - Real examples from their code
   - Before/after comparisons
   - Test usage examples

5. **🚀 Quick Reference**
   - Cheat sheet
   - Common commands
   - Useful patterns

---

## Tools to Use

1. **Read** - package.json, config files, component files, test files
2. **Glob** - Find components, tests, patterns
3. **Grep** - Search for specific patterns (data-test, selectors)
4. **Agent** (if needed) - Deep codebase exploration for complex repos
5. **mcp__serena__** tools - For semantic code analysis if available

---

## Example Prompts This Skill Handles

- "How do I identify locators for the maps page?"
- "What locator strategy should I use?"
- "Show me available selectors on the login page"
- "Identify locators for checkout flow"
- "What test attributes exist in this repo?"
- "How to add data-test attributes to components?"
- "Analyze locator patterns in this project"

---

## Success Criteria

✅ Correctly identified UI framework
✅ Determined if test automation exists
✅ Identified or recommended locator strategy
✅ Provided repo-specific workflow
✅ Included real code examples
✅ Clear, actionable recommendations
✅ Page-specific analysis (when requested)

---

## Error Handling

**If unable to determine UI framework:**
- Check broader patterns in source code
- Look at file extensions and structure
- Ask user to clarify

**If no clear page found:**
- List similar/possible matches
- Ask user for clarification
- Suggest searching in different locations

**If mixed patterns found:**
- Document all patterns found
- Recommend standardizing on one approach
- Provide migration guidance
