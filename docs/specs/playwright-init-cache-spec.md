# Spec: Playwright-BDD Initialization and Caching System

## Overview

Create a persistent caching system for the `/bee:playwright-bdd` workflow that stores analysis results (flows, patterns, steps, repo context) to avoid repeating expensive operations, preserve project knowledge between sessions, and reduce token usage.

## Phase 1: Cache Infrastructure

### Cache Storage and Retrieval

[x] Create cache file at `docs/playwright-init.md` with human-readable markdown format
[x] Cache includes summary section showing counts (N flows, M patterns, P step definitions)
[x] Cache includes "last updated" timestamp in ISO format
[x] Cache includes file count metadata (number of .feature files, number of step files)
[x] Cache stores results from all 4 agents: context-gatherer, flow-analyzer, pattern-detector, step-matcher
[x] Cache structure is organized in sections: Metadata, Context Summary, Flow Catalog, Pattern Catalog, Steps Catalog
[x] Cache reader parses `docs/playwright-init.md` and returns structured data for agents to consume
[x] Cache validation checks file exists, is readable, and has valid structure

### Cache Invalidation

[x] Track feature file count (.feature files) at cache write time
[x] Track step file count (.steps.ts and .steps.js files) at cache write time
[x] Cache marked stale if feature file count changes by 2 or more
[x] Cache marked stale if step file count changes by 2 or more
[x] Cache marked fresh if both file counts are within ±1 of cached values

### Workflow Integration

- [x] Add Step 1.5 to `/bee:playwright-bdd` workflow after path validation
- [x] When cache missing: show "No cache found. Running initial analysis..." then proceed with all 4 agents
- [x] When cache fresh: prompt "Cache is fresh (last updated: [timestamp]). [Use cache (Recommended) / Re-analyze anyway / Cancel]"
- [x] When cache stale: prompt "Cache is stale (file count changed: N features, M steps). Re-analyze? [Yes (Recommended) / Use stale cache / Cancel]"
- [x] Recommended option is auto-selected (developer presses Enter to accept)
- [x] Choice "Use cache": skip agent invocations, load cached data, continue workflow
- [x] Choice "Re-analyze anyway" or "Yes": run all 4 agents, overwrite cache
- [x] Choice "Use stale cache": load cached data despite staleness warning
- [x] Choice "Cancel": exit workflow gracefully
- [x] After cache write: show "Cache updated with latest analysis" confirmation message
- [x] After cache read: show "Using cached analysis from [date]" with summary counts

### Error Handling

- [x] When cache file is corrupt (parse error): prompt "Cache file is corrupt. Re-analyze? [Yes / Cancel]"
- [x] When any of the 4 agents fails during analysis: do not write cache (all-or-nothing)
- [x] When repo has zero feature files and zero step files: create empty cache with structure and warning note
- [x] When partial cache detected (missing expected sections): treat as missing cache and run full analysis

## Phase 2: Intelligent Gap Detection

### Smart Gap Identification

- [x] Enhance `playwright-step-matcher` to detect gaps only for scenarios being generated in current run
- [x] When step has no matches, check pattern catalog for similar Given/When/Then structures
- [x] When step has no matches, check flow catalog for domain language match
- [x] Flag as gap only if patterns OR flows suggest the step should exist
- [x] Return gap metadata: step text, scenario context, similarity scores

### Gap Suggestion Generation

- [x] Generate suggestions using pattern catalog (find similar Given/When/Then patterns, adapt to current step)
- [x] Generate suggestions using flow catalog (identify related actions, suggest step text with flow terminology)
- [x] Generate suggestions using existing steps catalog (find related steps like counterpart actions)
- [x] Combine all three sources and rank suggestions by relevance
- [x] Include Cucumber expression parameters in suggestions (e.g., {string}, {int})
- [x] Determine recommended file location based on feature name and existing step file patterns

### Inline Suggestion Presentation

- [x] Modify approval file generation to include gap suggestions section for each missing step
- [x] Group suggestions by gap (one section per missing step)
- [x] Show status "Gap detected (no existing matches found)" for each gap
- [x] List suggested step definitions with target file location
- [x] Show source of each suggestion (pattern catalog / flow catalog / existing steps)
- [x] Provide choice: "Use suggestion #N" / "Create custom step definition"
- [x] Require one-by-one approval (no bulk creation action)

## Phase 3: Documentation and Polish

### Cache Documentation

- [x] Add cache behavior section to `bee/CLAUDE.md` documenting where cache lives
- [x] Document what triggers invalidation (±2 feature files OR ±2 step files)
- [x] Document how to force re-analysis (interactive prompt options)
- [x] Document cache structure overview (metadata, context, flow/pattern/steps catalogs)
- [x] Include example cache file snippet showing format

### Cache Introspection

- [x] Show "Using cached analysis from [date]" when cache is reused
- [x] Show "Cache updated with latest analysis" after successful re-analysis
- [x] Show cache summary after read: "Cache contains: N flows, M patterns, P step definitions"
- [x] Show "No cache found. Running initial analysis..." on first workflow run
- [x] Include timestamp in all cache-related messages for transparency

### User Experience Polish

- [x] Recommended options are auto-selected in all prompts
- [x] All cache operations complete without requiring Write/Edit tool permissions (silent persistence)
- [x] Cache file is human-readable and git-friendly (can be committed, diffed, merged)
- [x] Error messages are actionable (tell developer what to do next)
- [x] Progress messages shown during analysis to indicate workflow is working

## API Shape

### Cache File Format

```markdown
---
last_updated: "2026-03-10T14:30:00Z"
feature_file_count: 12
step_file_count: 8
---

# Playwright-BDD Initialization Cache

## Summary
- Flows: 15
- Patterns: 8
- Step Definitions: 42
- Last Updated: March 10, 2026 at 2:30 PM

## Context Summary
[Human-readable repo context from context-gatherer]

## Flow Catalog
[Human-readable flow patterns from flow-analyzer]

## Pattern Catalog
[Human-readable repeating patterns from pattern-detector]

## Steps Catalog
[Human-readable step definition index from step-matcher]
```

### Workflow Step 1.5 Pseudocode

```typescript
// After path validation, before agent invocations
const cache = checkCache('docs/playwright-init.md');

if (!cache.exists) {
  showMessage("No cache found. Running initial analysis...");
  runAnalysis();
  writeCache();
} else if (cache.isCorrupt) {
  const choice = prompt("Cache file is corrupt. Re-analyze? [Yes / Cancel]");
  if (choice === 'Yes') {
    runAnalysis();
    writeCache();
  } else {
    exit();
  }
} else if (cache.isStale) {
  const choice = prompt("Cache is stale (file count changed). Re-analyze? [Yes / Use stale / Cancel]");
  if (choice === 'Yes') {
    runAnalysis();
    writeCache();
  } else if (choice === 'Use stale') {
    loadCache();
  } else {
    exit();
  }
} else {
  const choice = prompt("Cache is fresh. [Use cache (Recommended) / Re-analyze anyway / Cancel]");
  if (choice === 'Use cache') {
    loadCache();
    showMessage("Using cached analysis from [date]");
  } else if (choice === 'Re-analyze anyway') {
    runAnalysis();
    writeCache();
  } else {
    exit();
  }
}
```

## Out of Scope

- Cache versioning or migration logic (manual deletion to rebuild if schema changes)
- Partial cache updates (cache is all-or-nothing, not per-agent)
- Cache sharing across projects (each project has its own cache)
- Cache expiration by time (only file count triggers staleness)
- Cache compression or size optimization
- Multi-project cache aggregation or global caching
- Automatic backup of old cache (git history is the backup)
- Gap detection for entire codebase (only current run scenarios)
- Bulk creation of suggested steps (one-by-one approval required)

## Technical Context

- Project: Markdown-based Claude Code plugin (bee/)
- Architecture: Command-orchestrator pattern
- Workflow: `/bee:playwright-bdd` in `bee/commands/playwright-bdd.md`
- State management: Uses `scripts/update-bee-state.sh` for `.claude/bee-state.local.md`
- Modified files:
  - `bee/commands/playwright-bdd.md` - add Step 1.5 cache check
  - `bee/agents/playwright/playwright-step-matcher.md` - add gap detection
  - `bee/CLAUDE.md` - document cache behavior
- New file: `docs/playwright-init.md` - cache file (created at runtime)
- Risk level: MODERATE (cache invalidation must be reliable, gap detection needs tuning)

[X] Reviewed
