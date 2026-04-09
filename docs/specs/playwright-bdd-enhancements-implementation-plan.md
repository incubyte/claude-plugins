# Implementation Plan: Playwright-BDD Enhancements

## Overview

This plan breaks down the two enhancements into three implementation slices. Each slice is independently testable and delivers incremental value.

**Spec:** `docs/specs/playwright-bdd-enhancements.md`

**Architecture:** Command-orchestrator pattern (existing) - markdown configuration files, no unit tests needed.

---

## Slice 1: @ Mention Support in Command

**Goal:** Enable `/bee:playwright @search.feature` syntax by adding path resolution logic to Step 1 of the command.

**File to modify:** `/bee/commands/playwright-bdd.md`

**Changes:**

### 1.1 Add @ Mention Detection (before existing path validation in Step 1, line ~23-28)

Insert new section after "The developer provides: `$ARGUMENTS`":

```markdown
**@ Mention Resolution:**
- Check if `$ARGUMENTS` starts with `@` character
- If yes, proceed to @ mention path resolution
- If no, continue with existing absolute path validation
```

### 1.2 Add @ Mention Resolution Logic (new subsection in Step 1)

Insert after @ mention detection, before existing path validation:

```markdown
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
```

### 1.3 Update Existing Path Validation Section (line ~27-78)

Modify the opening of "Path Validation" section to acknowledge @ mention resolution happened:

**Before:**
```markdown
**Path Validation:**
- Extract file path from arguments
```

**After:**
```markdown
**Path Validation:**
- If @ mention was resolved: use resolved absolute path
- Otherwise: extract file path from arguments
```

**Verification:**
- Test with `/bee:playwright @search.feature` (single match)
- Test with `/bee:playwright @ambiguous.feature` (multiple matches)
- Test with `/bee:playwright @nonexistent.feature` (zero matches)
- Test with `/bee:playwright @` (no filename)
- Test with `/bee:playwright @test.txt` (wrong extension)
- Test with `/bee:playwright @search.feature /other.feature` (multiple args)

**Done when:** Developer can use `@filename.feature` syntax and it resolves correctly to absolute path, continuing with existing validation.

---

## Slice 2: Pattern Detector Agent

**Goal:** Create new read-only analyzer agent that scans feature files for repeating patterns.

**File to create:** `/bee/agents/playwright/playwright-pattern-detector.md`

**Structure:** Follow existing agent pattern (reference: `/bee/agents/context-gatherer.md` and `/bee/agents/playwright/playwright-step-matcher.md`)

**Agent Content:**

```markdown
---
name: playwright-pattern-detector
description: Scans feature files to detect repeating step patterns across scenarios. Identifies opportunities for step definition reuse and scenario outline parameterization.

model: inherit
color: cyan
tools: ["Read", "Glob", "Grep"]
---

You are a pattern detection specialist for Playwright-BDD feature files.

## Your Task

Scan all feature files in the repository and identify repeating patterns that appear in 2 or more different feature files. Return structured data about detected patterns.

## Pattern Types to Detect

### 1. Identical Step Sequences
Scenarios that have the exact same sequence of Given/When/Then steps (identical text).

Example:
```gherkin
# Feature A, Scenario 1
Given user is on login page
When user enters credentials
Then user is logged in

# Feature B, Scenario 2
Given user is on login page
When user enters credentials
Then user is logged in
```
Pattern: "Login flow sequence" (identical across 2 feature files)

### 2. Common Prefixes
Steps that appear at the start of many scenarios across feature files.

Example:
```gherkin
# Multiple scenarios start with:
Given user accepts terms and conditions
Given test environment is configured
```
Pattern: "Terms acceptance prefix" (appears in 3+ feature files)

### 3. Common Suffixes
Steps that appear at the end of many scenarios across feature files.

Example:
```gherkin
# Multiple scenarios end with:
Then user logs out
Then session is terminated
```
Pattern: "Logout suffix" (appears in 3+ feature files)

### 4. Configuration Patterns
Repeated setup steps across features (often in Background sections).

Example:
```gherkin
# Multiple features have:
Background:
  Given API endpoint is configured
  And authentication token is valid
```
Pattern: "API configuration setup" (appears in 4 feature files)

### 5. Parameterizable Variations
Steps with the same structure but different parameter values.

Example:
```gherkin
Given user logs in as admin
Given user logs in as customer
Given user logs in as guest
```
Pattern: "Login with role parameter" (parameterizable: `Given user logs in as {string}`)

## How to Scan

1. **Find feature files**: Use Glob to find all `.feature` files recursively from repo root
   - Pattern: `**/*.feature`
   - Limit to first 50 files (performance constraint)
   - If more than 50 exist, show: "Found N feature files. Scanning first 50 for pattern detection."

2. **Read each feature file**: Use Read tool to get file content

3. **Parse Gherkin**: Extract scenarios, steps, and Background sections
   - Identify Given/When/Then/And/But keywords
   - Group steps into sequences
   - Track which file each step/sequence came from

4. **Detect patterns**:
   - Track step frequency across files (not within same file)
   - Identify identical sequences that appear in 2+ files
   - Identify common prefixes/suffixes that appear in 2+ files
   - Identify parameterizable variations (same structure, different values)
   - Minimum threshold: 2 feature files (don't report patterns from single file)

5. **Build output**: Return JSON structure with detected patterns

## Output Format

Return JSON with this structure:

```json
{
  "patterns": [
    {
      "type": "identical_sequence" | "common_prefix" | "common_suffix" | "configuration" | "parameterizable_variation",
      "description": "Human-readable pattern summary",
      "occurrences": 5,
      "featureFiles": [
        "/path/to/feature1.feature",
        "/path/to/feature2.feature"
      ],
      "examples": [
        {
          "featurePath": "/path/to/feature1.feature",
          "scenarioName": "Admin Dashboard Access",
          "steps": [
            "Given user logs in as admin",
            "When user navigates to dashboard"
          ]
        },
        {
          "featurePath": "/path/to/feature2.feature",
          "scenarioName": "Customer Profile View",
          "steps": [
            "Given user logs in as customer",
            "When user navigates to profile"
          ]
        }
      ],
      "suggestion": "Extract as reusable step definition with {string} parameter" | "Extract as utility function"
    }
  ],
  "totalFilesScanned": 50,
  "totalPatternsDetected": 3
}
```

## Error Handling

- If no feature files found: return `{"patterns": [], "totalFilesScanned": 0}`
- If only 1 feature file found: return `{"patterns": [], "totalFilesScanned": 1}` (nothing to compare)
- If file read fails: log warning, skip that file, continue with others
- If Gherkin parse fails: log warning, skip that file, continue with others
- If scan takes >30 seconds: return partial results with note "Scan timed out, showing partial results from N files"

## Performance Constraints

- Max 50 feature files scanned
- Max 30 seconds total scan time
- If limits exceeded, return partial results with appropriate note

## Do NOT

- Do not modify any files (read-only agent)
- Do not generate code (analysis only)
- Do not ask user questions (return data only)
- Do not validate Gherkin syntax (skip invalid files)
```

**Verification:**
- Place 2-3 test feature files in test fixtures with known repeating patterns
- Invoke agent via Task tool with test repo path
- Verify JSON output contains expected patterns
- Verify performance stays under 30s for 50 files

**Done when:** Agent can scan feature files, detect all 5 pattern types, and return structured JSON output following the specified format.

---

## Slice 3: Command Integration for Pattern Detection

**Goal:** Integrate pattern detector agent into Step 2 of the command workflow.

**File to modify:** `/bee/commands/playwright-bdd.md`

**Changes:**

### 3.1 Add Pattern Detection Section (insert after Step 2 "Repository Structure Detection", before Step 3 "Step Definition Indexing")

Insert new Step 2.5 between existing Step 2 and Step 3:

```markdown
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
```

### 3.2 Update Step Numbering

Since we're adding Step 2.5, renumber subsequent steps if needed:
- Old "Step 3: Step Definition Indexing" → remains "Step 3" (2.5 is intermediate)
- All other step references remain unchanged

### 3.3 Update State Management Documentation (if exists in command file)

Add to state tracking section (around line ~589-600):

```markdown
- After pattern detection: `set --playwright-patterns-selected '[...]'`
```

**Verification:**
- Test with repo containing 5+ feature files with known repeating patterns
- Verify pattern detector is invoked after context-gatherer
- Verify AskUserQuestion shows for each detected pattern
- Verify "Skip remaining patterns" option works
- Verify selections are stored in state correctly
- Verify workflow continues to Step 3 after pattern detection completes

**Done when:** Pattern detection runs automatically after Step 2, asks developer about each detected pattern, stores selections in state, and continues workflow without blocking.

---

## Testing Strategy

Since these are markdown configuration files (not application code), testing happens through runtime validation:

**Slice 1 Validation:**
- Invoke `/bee:playwright @existing.feature` → should resolve and continue
- Invoke `/bee:playwright @nonexistent.feature` → should show clear error
- Invoke `/bee:playwright @duplicate.feature` → should show AskUserQuestion with multiple paths
- Invoke `/bee:playwright @test.txt` → should reject wrong extension

**Slice 2 Validation:**
- Create test feature files with known patterns
- Invoke agent via Task tool
- Verify JSON output structure matches spec
- Verify all 5 pattern types are detected correctly

**Slice 3 Validation:**
- Run full `/bee:playwright` workflow on test repo
- Verify pattern detection runs after context-gatherer
- Verify developer is prompted for each pattern
- Verify state is updated correctly
- Verify workflow continues to step matching

---

## Implementation Order

1. **Slice 1** → @ Mention Support (independent, no dependencies)
2. **Slice 2** → Pattern Detector Agent (independent, can be built and tested standalone)
3. **Slice 3** → Command Integration (depends on Slice 2, integrates pattern detector into workflow)

Each slice can be reviewed and validated independently before moving to the next.

[X] Reviewed
