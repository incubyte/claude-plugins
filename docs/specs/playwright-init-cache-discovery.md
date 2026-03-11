# Discovery: Playwright-BDD Initialization and Caching System

## Why

The Playwright-BDD workflow currently repeats expensive analysis operations every time it runs:
- **Repeating analysis** — scanning all feature files, step definitions, and patterns on every invocation wastes time
- **Loss of project knowledge** — context gathered about flows, patterns, and steps is not preserved between sessions
- **Huge token usage** — re-analyzing the same files repeatedly burns through API tokens unnecessarily

This creates friction for developers who run the workflow multiple times on the same project, especially during iterative test development.

## Who

**Primary user**: Developers using the `/bee:playwright-bdd` command for test generation.

**Benefit**: Faster workflow execution, persistent project knowledge, lower token costs.

## Success Criteria

- Analysis runs once per project (or when explicitly requested)
- Cache is automatically checked and reused on subsequent runs
- Token usage drops significantly for repeat invocations
- Developers can easily trigger re-analysis when needed
- Gap detection becomes smarter by leveraging cached flow and pattern knowledge

## Problem Statement

The `/bee:playwright-bdd` workflow delegates to 4 agents that perform analysis: context-gatherer (repo structure), playwright-flow-analyzer (application flows), playwright-pattern-detector (repeating patterns), and playwright-step-matcher (step definition indexing). Every invocation repeats this analysis from scratch, even when the repo hasn't changed. This wastes time, tokens, and loses valuable project knowledge between sessions. Developers need a persistent initialization system that caches analysis results and intelligently reuses them.

## Hypotheses

### H1: Cache in `docs/playwright-init.md` provides visibility and version control
**Confirms**: Markdown format makes cache human-readable, diffable, and versionable in git.
**Rejects**: Binary or hidden cache formats (e.g., `.cache/`, JSON in `.claude/`).

### H2: File count threshold (±2) balances sensitivity and stability
**Confirms**: Changes of 2+ files indicate meaningful repo evolution (new flows, refactored steps).
**Rejects**: Every single file change (too aggressive), or manual-only invalidation (too passive).

### H3: Intelligent gap detection reduces noise
**Confirms**: Checking patterns catalog and flow catalog before flagging gaps prevents false positives.
**Rejects**: Blindly flagging every "no_matches" as a gap (too noisy).

### H4: Combined suggestion algorithm provides actionable guidance
**Confirms**: Using pattern catalog + flow catalog + existing steps catalog together generates high-quality suggestions.
**Rejects**: Single-source suggestions (e.g., only from patterns) which miss context.

### H5: Upfront cache check optimizes for common case (cache hit)
**Confirms**: Checking cache once at workflow start (Step 1.5) avoids redundant agent invocations.
**Rejects**: Per-agent cache checks (duplicated logic) or no caching (current state).

### H6: Developer retains control over cache freshness
**Confirms**: Interactive prompts for stale cache and re-analysis requests give developers agency.
**Rejects**: Auto-invalidation without choice, or no way to force re-analysis.

## Out of Scope

- **Cache versioning** — no migration logic if cache schema changes (manual deletion to rebuild)
- **Partial cache updates** — cache is all-or-nothing (not per-agent caching)
- **Cache sharing across projects** — each project has its own `docs/playwright-init.md`
- **Cache expiration by time** — only file count changes trigger staleness
- **Cache compression** — markdown stays readable, not optimized for size
- **Multi-project cache aggregation** — no global cache across repos

## Milestone Map

### Phase 1: Cache Infrastructure

**Capability**: Cache storage and retrieval
- Create cache file structure: `docs/playwright-init.md` with three sections (flow catalog, pattern catalog, steps catalog)
- Implement cache writer: aggregate results from 4 agents (context-gatherer, flow-analyzer, pattern-detector, step-matcher) and serialize to markdown
- Implement cache reader: parse `docs/playwright-init.md` and return structured data
- Add cache validation: check if cache file exists, is readable, has valid structure

**Capability**: Cache invalidation strategy
- Track file counts at cache write time: number of `.feature` files, number of `.steps.ts/.steps.js` files
- Implement staleness detection: compare current file counts to cached counts, flag stale if delta >= 2
- Store file counts in cache metadata section

**Capability**: Workflow integration
- Add Step 1.5 to `/bee:playwright-bdd` workflow: check cache after path validation
- Implement cache prompt logic:
  - Cache missing: run analysis (no prompt)
  - Cache fresh: "Cache is fresh. [Use cache (Recommended) / Re-analyze anyway / Cancel]"
  - Cache stale: "Cache is stale (file count changed). Re-analyze? [Yes / Use stale / Cancel]"
- Route decisions: Use cache → skip agents, Re-analyze → run agents + update cache, Cancel → exit workflow

**Deliverable**: Working cache system integrated into `/bee:playwright-bdd` that stores and reuses analysis results.

---

### Phase 2: Intelligent Gap Detection

**Capability**: Smart gap identification
- Enhance `playwright-step-matcher` agent to detect gaps intelligently:
  - When `decision: "no_matches"` occurs, check patterns catalog for similar Given/When/Then structures
  - Check flow catalog for domain language match (does step text use terms from known flows?)
  - Flag as gap only if patterns OR flows suggest this step should exist
- Return gap metadata: step text, scenario context, similarity scores

**Capability**: Gap suggestion generation
- Implement suggestion algorithm in `playwright-step-matcher`:
  - **Source 1 (Patterns)**: Find similar Given/When/Then patterns in patterns catalog, adapt to current step text
  - **Source 2 (Flows)**: Identify related actions in flow catalog, suggest step text using flow terminology
  - **Source 3 (Existing steps)**: Find related steps in steps catalog (e.g., "add item" suggests counterpart "remove item")
  - Combine all three sources, rank by relevance
- Generate step text suggestions with Cucumber expression parameters (e.g., `{string}`, `{int}`)
- Determine recommended file location based on feature name and existing step file patterns

**Capability**: Inline suggestion presentation
- Modify approval file generation (`docs/specs/playwright-bdd-approval-*.md`) to include gap suggestions section:
  ```markdown
  ## Step: "user adds item to cart"

  Status: Gap detected (no existing matches found)

  ### Suggested Steps
  1. "user adds {string} to cart" → `src/steps/cart.steps.ts`
     Source: Pattern catalog (similar to "user removes {string} from cart")
  2. "user adds item to shopping cart" → `src/steps/cart.steps.ts`
     Source: Flow catalog (cart flow domain language)

  Decision:
  - [ ] Use suggestion #1
  - [ ] Use suggestion #2
  - [ ] Create custom step definition
  ```

**Deliverable**: Step matcher that detects gaps intelligently and generates actionable suggestions inline in approval files.

---

### Phase 3: Documentation and Polish

**Capability**: Cache reference in CLAUDE.md
- Add section to `bee/CLAUDE.md` documenting cache behavior:
  - Where cache lives (`docs/playwright-init.md`)
  - What triggers invalidation (file count ±2)
  - How to force re-analysis (interactive prompt)
  - Cache structure overview (flow/pattern/steps catalogs)

**Capability**: Cache introspection
- Add helpful messages during workflow:
  - "Using cached analysis from [date]" when cache is reused
  - "Cache updated with latest analysis" after re-analysis
  - "Cache contains: N flows, M patterns, P step definitions" (summary after cache read)

**Capability**: Error handling
- Handle corrupt cache gracefully: if `docs/playwright-init.md` is malformed, prompt "Cache file is corrupt. Re-analyze? [Yes / Cancel]"
- Handle partial cache: if cache missing expected sections, treat as missing cache (run full analysis)

**Deliverable**: Complete, documented caching system with polished user experience.

## Module Structure

**Greenfield**: No (enhancing existing `/bee:playwright-bdd` workflow)

**Modified modules**:
- `bee/commands/playwright-bdd.md` — add Step 1.5 cache check and prompts
- `bee/agents/playwright/playwright-step-matcher.md` — add gap detection and suggestion generation
- `bee/CLAUDE.md` — document cache behavior

**New artifacts**:
- `docs/playwright-init.md` — cache file (created at runtime by workflow)

## Open Questions

**Q1: Cache schema evolution**
- If cache structure changes in future versions, how to handle migration?
- **Resolution for Phase 1**: Manual deletion and rebuild (developer deletes `docs/playwright-init.md`, re-runs workflow)

**Q2: Cache conflicts in team environments**
- Multiple developers might have different local caches if not committed to git.
- **Resolution for Phase 1**: Commit `docs/playwright-init.md` to version control. Treat git conflicts like any other doc conflict.

**Q3: Suggestion ranking algorithm**
- How to weight pattern vs flow vs existing-steps sources when combining suggestions?
- **Deferred to Phase 2**: Start with equal weight, tune based on empirical feedback.

**Q4: Gap detection sensitivity**
- What similarity threshold determines "pattern catalog has similar structure"?
- **Deferred to Phase 2**: Use same 50% semantic confidence threshold as step matching, adjust if too strict/lenient.

## Revised Assessment

**Size**: FEATURE

**Greenfield**: No (enhancement to existing workflow)

**Risk**: MODERATE
- Cache invalidation logic must be reliable (false negatives = stale cache used incorrectly)
- Gap detection algorithm needs tuning to avoid false positives
- Approval file format changes might break existing tooling (mitigated by backward-compatible additions)

[X] Reviewed
