# TDD Plan: bee:qc Command -- Slice 2 (PR Mode)

## Execution Instructions
Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] -> [x]).
Continue until all items are done.
If stuck after 3 attempts, mark with a warning and move to the next independent step.

## Context
- **Source**: `docs/specs/qc-spec.md`
- **Slice**: Slice 2 -- PR Mode (analyze, refactor, verify, test)
- **Risk**: LOW (internal tooling, markdown instruction files)
- **Files to modify**: `bee/commands/qc.md`
- **Files to verify (read-only)**: `bee/agents/qc-planner.md`, `bee/agents/verifier.md`

## Codebase Analysis

### What Slice 1 Already Built
Slice 1 implemented the full `bee/commands/qc.md` orchestrator and `bee/agents/qc-planner.md`. Critically, Slice 1 already wrote the PR mode execution loop (Step 4), commit conventions, and most of the scope resolution for PR mode (Step 1).

### Gap Analysis: Slice 2 ACs vs Existing Content

**PR Scoping (3 ACs) -- all covered:**
- PR scoping via `gh pr diff` -- Step 1, lines 39-44
- Parallel agent analysis scoped to PR files -- Step 2 uses resolved scope
- qc-planner produces PR-scoped plan -- Step 3 + qc-planner.md accepts `mode: "pr"`

**Execution Loop (9 ACs) -- all covered:**
- Baseline test run -- Step 4, item 1
- Change + test for each step -- Step 4, item 2a-b
- Verifier spawn after each step -- Step 4, item 2c
- Rollback on verification fail -- Step 4, item 2d
- Commit with WHY on pass -- Step 4, item 2e
- One concern per commit -- Commit conventions section
- Tests in separate commits after refactoring -- Step 4, item 3
- No mixed commits -- Commit conventions section
- Final verification -- Step 4, item 4

**Error Cases (3 ACs) -- gaps filled:**
- No changed files: COVERED
- `gh` CLI not available: ADDED — gh --version check before gh pr diff
- Baseline tests fail: REFINED — explicit AskUserQuestion with continue/stop options

---

## Behavior 1: Check for gh CLI availability before PR mode

- [x] **READ**: Read `bee/commands/qc.md` Step 1, PR mode section
- [x] **WRITE**: Added `gh --version` check before `gh pr diff`, with actionable error message
- [x] **VERIFY**: Check happens before any `gh pr diff` call. Error message tells developer what to do.

---

## Behavior 2: Explicit baseline test failure handling

- [x] **READ**: Read `bee/commands/qc.md` Step 4, item 1
- [x] **WRITE**: Made baseline failure handling explicit with AskUserQuestion pattern and both continue/stop paths
- [x] **VERIFY**: Uses AskUserQuestion (consistent with Bee). Both paths described.

---

## Behavior 3: Full cross-reference verification

- [x] **VERIFY PR Scoping ACs**: All 3 covered in qc.md Step 1 + Step 2
- [x] **VERIFY Execution Loop ACs**: All 9 covered in qc.md Step 4 + Commit conventions
- [x] **VERIFY Error Cases ACs**: All 3 covered (no files, no gh, failing baseline)
- [x] **VERIFY qc-planner.md PR awareness**: Accepts `mode: "pr"`, uses "PR #N" in title

---

## Final Check

- [x] **Read `bee/commands/qc.md` end to end**: Handles both modes completely. Error cases explicit.
- [x] **Cross-reference every Slice 2 AC**: All 15 ACs map to specific content.
- [x] **No Slice 1 regressions**: Additions are additive, no contradictions.

## Deliverables Summary
| File | Change | Status |
|------|--------|--------|
| `bee/commands/qc.md` | Added gh CLI check + refined baseline failure handling | DONE |
| `bee/agents/qc-planner.md` | Verified, no changes needed | DONE |
