# Spec: Playwright-BDD Enhancements — @ Mention Support & Pattern Detection

## Overview

Two independent enhancements to the `/bee:playwright` workflow that improve developer experience: (1) @ mention support for feature file paths (type `@search.feature` instead of absolute paths), and (2) automatic detection of repeating patterns across feature files with extraction suggestions. Both enhancements integrate into the existing workflow without breaking changes.

## Enhancement 1: @ Mention Support for File Paths

### Acceptance Criteria

**@ Mention Detection:**
- [ ] In Step 1 (Path Validation), check if `$ARGUMENTS` starts with `@` character
- [ ] If starts with `@`, extract filename from argument (e.g., `@search.feature` → `search.feature`)
- [ ] If `@` detected with no filename after it, show error: "@ mention requires a filename. Example: @search.feature"

**File Search:**
- [ ] Search recursively in standard Playwright-BDD directories: `features/`, `tests/features/`, `e2e/features/`
- [ ] Match filename exactly (case-sensitive): `@search.feature` matches only files named `search.feature`
- [ ] Search includes subdirectories: `@search.feature` matches `features/admin/search.feature` or `features/subfolder/search/search.feature`
- [ ] Use Glob tool with patterns: `features/**/*.feature`, `tests/features/**/*.feature`, `e2e/features/**/*.feature`
- [ ] Limit search to first 50 feature files found for performance

**Performance Handling:**
- [ ] If more than 50 feature files exist in search directories, show message: "Found N feature files. Scanning first 50 for @ mention resolution."
- [ ] Continue search with 50-file limit
- [ ] Developer can still use absolute paths to bypass search if needed

**Zero Matches:**
- [ ] If no files found matching `@filename`, show error:
  ```
  Error: File not found via @ mention: '@[filename]'

  Searched in:
  - features/
  - tests/features/
  - e2e/features/

  No matches found. Check spelling or provide absolute path starting with /
  ```
- [ ] Do not proceed to path validation

**Single Match (Happy Path):**
- [ ] If exactly 1 file found, resolve to absolute path automatically
- [ ] Continue to existing path validation (file exists, .feature extension, Gherkin syntax)
- [ ] No confirmation prompt to developer (fast workflow)

**Multiple Matches:**
- [ ] If 2 or more files found with same name, use AskUserQuestion to present all matches
- [ ] Show full paths for each match
- [ ] Format: "Found multiple files named '[filename]'. Which one? [option1: /path/to/first / option2: /path/to/second / Cancel]"
- [ ] Developer selects one, or cancels
- [ ] If selection made, use chosen path and continue to validation

**Edge Cases:**
- [ ] If `@` provided with no `.feature` extension (e.g., `@search`), show error: "@ mention must include .feature extension. Example: @search.feature"
- [ ] If `@filename.txt` (wrong extension), show error: "@ mention must reference a .feature file. Found: @[filename.txt]"
- [ ] If multiple arguments provided (e.g., `@search.feature /absolute/path/other.feature`), show error: "Command accepts only one feature file path. Please specify one: @search.feature OR /absolute/path.feature"
- [ ] If absolute path provided (starts with `/` or drive letter), skip @ mention logic entirely (existing behavior)

### Integration Point

- @ mention resolution happens BEFORE existing path validation in Step 1
- After resolution, flow continues with existing validation: check file exists, check .feature extension, validate Gherkin syntax
- Error handling follows PR #16 comprehensive error pattern (actionable errors with context, causes, next steps)

## Enhancement 2: Repeating Pattern Detection

### Acceptance Criteria

**Pattern Detection Trigger:**
- [ ] Run pattern detection AFTER Step 2 (Repository Structure Detection) completes
- [ ] Run BEFORE Step 3 (Step Definition Indexing) starts
- [ ] Only run if 2 or more feature files exist in repo (skip for empty/single-file repos)
- [ ] Skip if repo is empty (no feature files found)

**Pattern Detector Agent:**
- [ ] Create new agent: `bee/agents/playwright/playwright-pattern-detector.md`
- [ ] Agent scans all feature files in repository using Glob tool
- [ ] Agent limits scan to first 50 feature files found (performance constraint)
- [ ] If more than 50 feature files exist, show message: "Found N feature files. Scanning first 50 for pattern detection."

**Pattern Types to Detect:**
- [ ] Identical step sequences: same Given/When/Then order across scenarios (exact text match or parameterizable variation)
- [ ] Common prefixes: steps that appear at start of many scenarios (e.g., "Given user accepts terms and conditions")
- [ ] Common suffixes: steps that appear at end of many scenarios (e.g., "Then user logs out")
- [ ] Configuration patterns: repeated setup steps across features (e.g., "Given test environment is configured")
- [ ] Parameterizable variations: steps with same structure but different values (e.g., "Given user logs in as admin" vs "Given user logs in as customer")

**Minimum Threshold:**
- [ ] Only report patterns that appear in 2 or more different feature files
- [ ] Do not flag patterns that appear only within one feature file (local to that feature)

**Pattern Presentation:**
- [ ] For each detected pattern, show:
  - Pattern description (human-readable summary)
  - Number of feature files using this pattern
  - Example scenarios (show 2-3 examples)
  - Suggestion: "Extract as reusable step definition" or "Extract as utility function"
- [ ] Use AskUserQuestion for each pattern: "Found repeating pattern '[description]' in N feature files. Extract as reusable step/utility? [Yes (Recommended) / No / Skip remaining patterns]"
- [ ] If developer selects "Skip remaining patterns", stop pattern detection and continue to Step 3

**Pattern Selection Storage:**
- [ ] Store developer's selections (Yes/No for each pattern) in Bee state using `scripts/update-bee-state.sh`
- [ ] State key: `playwright-patterns-selected`
- [ ] State value: JSON array of pattern descriptions marked for extraction
- [ ] Do not implement extraction in this enhancement (extraction happens in Phase 4 - Utility Generation)

**Continue Workflow:**
- [ ] After pattern detection completes (all patterns processed or developer skips remaining), continue to Step 3 (Step Definition Indexing)
- [ ] Pattern selections are available for Phase 4 to read from state and implement extractions
- [ ] No changes to Step 3 or later steps in Phase 1

**Edge Cases:**
- [ ] If 0 feature files exist in repo, skip pattern detection entirely (show no message)
- [ ] If only 1 feature file exists, skip pattern detection (show message: "Only one feature file found. Skipping pattern detection.")
- [ ] If no patterns detected (all scenarios are unique), show message: "No repeating patterns detected across feature files." and continue to Step 3
- [ ] If pattern detection agent fails (error during scan), log error and continue to Step 3 without blocking workflow: "Pattern detection failed: [error]. Continuing with step matching."

**Performance Handling:**
- [ ] Limit scan to 50 feature files (same as @ mention search)
- [ ] If scan takes longer than 30 seconds, show progress indicator: "Analyzing feature files for patterns... [N of 50 scanned]"
- [ ] If timeout occurs, skip remaining files and proceed with partial results

**Optional/Skippable:**
- [ ] Pattern detection is optional and does not block single-scenario workflows
- [ ] Developer can skip all patterns via "Skip remaining patterns" option
- [ ] If developer skips, workflow continues immediately to Step 3
- [ ] Pattern detection results are not required for Phase 1 to complete successfully

## API Shape (Internal)

### @ Mention Resolution Flow
```typescript
// Input
{
  arguments: "@search.feature" | "/absolute/path/search.feature"
}

// If starts with @:
// 1. Extract filename: "search.feature"
// 2. Glob search: features/**/*.feature, tests/features/**/*.feature, e2e/features/**/*.feature
// 3. Filter results by exact filename match
// 4. Return matches array

// Output (0 matches)
{
  resolved: false,
  error: "File not found via @ mention: '@search.feature'"
}

// Output (1 match)
{
  resolved: true,
  absolutePath: "/Users/name/repo/features/search.feature"
}

// Output (2+ matches)
{
  resolved: false,
  multipleMatches: [
    "/Users/name/repo/features/search.feature",
    "/Users/name/repo/tests/features/admin/search.feature"
  ]
}
```

### Pattern Detector Agent Input
```typescript
{
  repoRoot: "/absolute/path/to/repo",
  featureFiles: ["/path/to/feature1.feature", "/path/to/feature2.feature"],
  maxFiles: 50
}
```

### Pattern Detector Agent Output
```typescript
{
  patterns: [
    {
      type: "identical_sequence" | "common_prefix" | "common_suffix" | "configuration" | "parameterizable_variation",
      description: "User login flow with role parameter",
      occurrences: 5, // number of feature files
      examples: [
        {
          featurePath: "/repo/features/admin.feature",
          scenarioName: "Admin Dashboard Access",
          steps: ["Given user logs in as admin", "When user navigates to dashboard"]
        },
        {
          featurePath: "/repo/features/customer.feature",
          scenarioName: "Customer Profile View",
          steps: ["Given user logs in as customer", "When user navigates to profile"]
        }
      ],
      suggestion: "Extract as reusable step definition with {string} parameter"
    }
  ]
}
```

### State Storage Format
```bash
# After pattern detection, store selections via:
scripts/update-bee-state.sh set --playwright-patterns-selected '[
  "User login flow with role parameter",
  "Terms acceptance configuration"
]'
```

## Out of Scope

**Enhancement 1:**
- Fuzzy matching for filenames (only exact filename match supported)
- @ mention support for directories (only files)
- @ mention autocomplete/suggestions (developer types exact filename)
- Configurable search directories (hardcoded to `features/`, `tests/features/`, `e2e/features/`)

**Enhancement 2:**
- Automatic extraction of patterns (Phase 4 responsibility)
- Pattern refactoring across existing feature files (detection only, no modification)
- Pattern detection across non-feature files (step definitions, page objects, etc.)
- ML-based pattern detection (simple text matching and sequence comparison)
- Cross-repo pattern detection (single repo only)

## Technical Context

**Patterns to follow:**
- PR #16 comprehensive error handling (lines 484-586 in `/bee/commands/playwright-bdd.md`)
- File-based approval workflow with AskUserQuestion
- State management via `scripts/update-bee-state.sh` (not Write/Edit)
- Agent delegation via Task tool

**Key dependencies:**
- Glob tool for file search
- context-gatherer agent (already invoked in Step 2)
- playwright-step-matcher agent (provides context about existing steps)
- New playwright-pattern-detector agent (to be created)

**Files to modify:**
- `/bee/commands/playwright-bdd.md` (Step 1 for @ mention, Step 2 for pattern detection)

**Files to create:**
- `/bee/agents/playwright/playwright-pattern-detector.md` (new agent)

**Risk level:** MODERATE
- Internal developer tooling (easier to revert if issues)
- Affects developer workflow (errors could block feature development)
- Pattern detection could have performance implications on large repos (mitigated by 50-file limit)
- @ mention resolution could fail silently if search logic has bugs (comprehensive error handling required)

## Success Signal

**Enhancement 1 Success:**
Developer can type `/bee:playwright @search.feature` and the workflow:
- Finds the file in `features/search.feature` or subdirectory
- Resolves to absolute path automatically
- Continues with existing validation and workflow
- If multiple matches, shows clear choice
- If no matches, shows actionable error with search locations

**Enhancement 2 Success:**
Developer runs `/bee:playwright` on a repo with 5+ feature files where:
- 2 scenarios share "Given user logs in as admin" step
- 3 scenarios share "Given user accepts terms" prefix
- Pattern detector identifies both patterns
- Developer is asked to approve extraction for each
- Developer selects "Yes" for login pattern, "No" for terms pattern
- Selections are stored in Bee state
- Workflow continues to Step 3 without blocking
- Phase 4 can read stored selections and implement extractions

**Done when:**
Both enhancements integrate seamlessly into existing workflow without breaking current functionality. Developer can use @ mentions for faster file selection, and pattern detection surfaces reuse opportunities without adding friction to single-scenario workflows.

[X] Reviewed
