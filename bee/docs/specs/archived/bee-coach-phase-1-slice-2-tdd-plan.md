# TDD Plan: Bee Coach Command -- Slice 2

## Execution Instructions
Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] -> [x]).
Continue until all items are done.
If stuck after 3 attempts, mark with a warning and move to the next independent step.

## Context
- **Source**: `docs/specs/bee-coach-phase-1.md`
- **Slice**: `/bee:coach` Command (`commands/coach.md`)
- **Risk**: LOW
- **Acceptance Criteria**:
  1. Command file exists at `commands/coach.md` with YAML frontmatter matching existing conventions
  2. Default behavior (no flags): reads last session transcript for deep analysis + trend from last 5 sessions
  3. `--last N` flag: trend summary across last N sessions
  4. `--all` flag: trend summary across all sessions
  5. Analyzes across four categories: workflow adoption, prompt quality, session efficiency, code quality signals
  6. Produces 2-4 specific, actionable coaching insights (not generic advice)
  7. Each insight names a concrete thing done well or a specific improvement to try
  8. Coaching tone is encouraging and non-judgmental
  9. Insights printed to terminal as conversational output
  10. Insights saved to `.bee-insights/coaching-report-YYYY-MM-DD.md`
  11. Same-day runs overwrite the report file
  12. Report file includes session date, 2-4 insights, and trend summary
  13. Trend summary reads from `.bee-insights/session-log.jsonl`
  14. Shows directional changes: spec adoption rate, avg token usage, workflow phase completeness, message counts
  15. Uses relative framing (not absolute scores)
  16. Shows helpful message when fewer than 2 sessions exist

## Codebase Analysis

### File Structure
- Implementation: `commands/coach.md` (new file -- markdown command with YAML frontmatter)
- Tests: `.claude/hooks/test-bee-coach-command.sh` (bash structural tests, following Slice 1 pattern)
- Reference command: `commands/bee.md` (YAML frontmatter convention)
- Data source: `.bee-insights/session-log.jsonl` (created by Slice 1 stop hook)

### Test Infrastructure
- Framework: Custom bash test harness (same as `.claude/hooks/test-stop-session.sh`)
- Run command: `bash .claude/hooks/test-bee-coach-command.sh`
- Helpers: `assert_eq`, `assert_file_exists` pattern from Slice 1 tests
- Key insight: This is a markdown prompt file, not executable code. "Tests" verify structural properties -- file exists, frontmatter is valid, required sections are present.

### Frontmatter Convention (from `commands/bee.md`)
```yaml
---
description: [one-line description of what the command does]
---
```

---

## Behavior 1: Command file exists with correct frontmatter

**Given** the commands directory exists
**When** we check for `commands/coach.md`
**Then** the file exists and has YAML frontmatter with a `description` field

- [x] **RED**: Write failing test
  - Location: `.claude/hooks/test-bee-coach-command.sh`
  - Test name: `test_command_file_exists_with_frontmatter`
  - Create the test harness with `assert_eq`, `assert_file_exists` helpers (reuse pattern from `test-stop-session.sh`)
  - Assert file exists at `commands/coach.md`
  - Assert file starts with `---` (YAML frontmatter delimiter)
  - Assert frontmatter contains `description:` field

- [x] **RUN**: Confirm test FAILS (file does not exist yet)

- [x] **GREEN**: Create `commands/coach.md`
  - Add YAML frontmatter with `description` matching the pattern from `bee.md`
  - Description should convey: "Analyze your development sessions and get actionable coaching insights"
  - Add a minimal body placeholder

- [x] **RUN**: Confirm test PASSES

- [x] **REFACTOR**: None needed

---

## Behavior 2: Command describes the three invocation modes

**Given** the command file exists
**When** we check its content
**Then** it contains instructions for default behavior, `--last N`, and `--all` flags

- [x] **RED**: Write failing test
  - Test name: `test_command_describes_invocation_modes`
  - Use `grep -q` to check the file contains references to all three modes:
    - Default behavior (last session + last 5 trend)
    - `--last` flag
    - `--all` flag

- [x] **RUN**: Confirm test FAILS

- [x] **GREEN**: Add an invocation modes section to `commands/coach.md`
  - Describe default: read last session transcript for deep analysis, show trend from last 5
  - Describe `--last N`: trend summary across last N sessions
  - Describe `--all`: trend summary across all sessions
  - Instruct Claude to parse `$ARGUMENTS` for flag detection

- [x] **RUN**: Confirm test PASSES

- [x] **REFACTOR**: None needed

---

## Behavior 3: Command references all four coaching categories

**Given** the command file exists
**When** we check its content
**Then** it contains instructions to analyze across workflow adoption, prompt quality, session efficiency, and code quality signals

- [x] **RED**: Write failing test
  - Test name: `test_command_references_four_coaching_categories`
  - Use `grep -q` to verify all four category names appear in the file

- [x] **RUN**: Confirm test FAILS

- [x] **GREEN**: Add coaching analysis section to `commands/coach.md`
  - Describe each category and what to look for in the transcript/session log data
  - Workflow adoption: spec usage, TDD plans, verification, review phases
  - Prompt quality: clarity, specificity, context provided
  - Session efficiency: token usage, message counts, error rates
  - Code quality signals: test file modifications, tool usage patterns

- [x] **RUN**: Confirm test PASSES

- [x] **REFACTOR**: Review the four category descriptions -- are they specific enough for Claude to act on?

---

## Behavior 4: Command instructs saving the coaching report

**Given** the command file exists
**When** we check its content
**Then** it contains instructions to save insights to `.bee-insights/coaching-report-YYYY-MM-DD.md`

- [x] **RED**: Write failing test
  - Test name: `test_command_instructs_report_saving`
  - Use `grep -q` to verify the file references:
    - `.bee-insights/coaching-report-` (the save path pattern)
    - Overwrite behavior for same-day runs
    - Report should include date, insights, and trend summary

- [x] **RUN**: Confirm test FAILS

- [x] **GREEN**: Add report output section to `commands/coach.md`
  - Instruct Claude to save insights to `.bee-insights/coaching-report-YYYY-MM-DD.md`
  - Instruct overwrite (not append) if file already exists
  - Specify report format: date header, 2-4 insights, trend summary

- [x] **RUN**: Confirm test PASSES

- [x] **REFACTOR**: None needed

---

## Behavior 5: Command instructs reading session-log.jsonl for trends

**Given** the command file exists
**When** we check its content
**Then** it contains instructions to read `.bee-insights/session-log.jsonl` and produce trend summaries with relative framing

- [x] **RED**: Write failing test
  - Test name: `test_command_instructs_trend_analysis`
  - Use `grep -q` to verify the file references:
    - `session-log.jsonl` (data source)
    - Directional/relative framing language (e.g., "relative" or "directional" or "went from")
    - Fewer than 2 sessions handling

- [x] **RUN**: Confirm test FAILS

- [x] **GREEN**: Add trend summary section to `commands/coach.md`
  - Instruct Claude to read session-log.jsonl
  - Describe the four trend metrics: spec adoption rate, avg token usage, workflow phase completeness, message counts
  - Instruct relative framing ("your X went from Y to Z") not absolute scores
  - Instruct a friendly fallback when fewer than 2 sessions exist

- [x] **RUN**: Confirm test PASSES

- [x] **REFACTOR**: None needed

---

## Behavior 6: Command sets encouraging, non-judgmental coaching tone

**Given** the command file exists
**When** we check its content
**Then** it contains tone guidance that is encouraging and non-judgmental

- [x] **RED**: Write failing test
  - Test name: `test_command_sets_coaching_tone`
  - Use `grep -q` to verify the file references tone instructions:
    - "encouraging" or "non-judgmental" or similar tone guidance
    - "2-4" insights (quantity constraint)
    - "actionable" or "specific" (quality constraint)

- [x] **RUN**: Confirm test FAILS

- [x] **GREEN**: Add tone and output quality section to `commands/coach.md`
  - Instruct encouraging, non-judgmental tone
  - Instruct exactly 2-4 insights per session
  - Each insight must name a concrete behavior (not generic advice)
  - Highlight growth, not failures

- [x] **RUN**: Confirm test PASSES

- [x] **REFACTOR**: Review the full command file end-to-end. Is it clear enough for Claude to follow? Are sections logically ordered? Remove any redundancy.

---

## Edge Cases (Low Risk)

### File is well-formed markdown
- [x] **RED**: Test -- `test_command_is_valid_markdown`
  - Assert frontmatter closes with a second `---`
  - Assert file has more than 10 lines (not just a stub)
- [x] **GREEN -> REFACTOR**

### Frontmatter matches bee.md convention exactly
- [x] **RED**: Test -- `test_frontmatter_has_only_description`
  - Assert frontmatter contains `description:` and no unexpected keys that differ from `bee.md` convention
  - Note: Check the `allowed-tools` pattern from `bee.md` -- if present there, it may be needed here too
- [x] **GREEN -> REFACTOR**

- [x] **COMMIT**: "feat: add /bee:coach command file with coaching instructions"

---

## Final Check

- [x] **Run full test suite**: `bash .claude/hooks/test-bee-coach-command.sh` -- 26 assertions, 8 tests, all pass
- [x] **Run Slice 1 tests**: `bash .claude/hooks/test-stop-session.sh` -- 50 assertions, 16 tests, still green (no regressions)
- [x] **Review test names**: Read them top to bottom -- they describe the command's structure clearly
- [x] **Review command file**: Read `commands/coach.md` end-to-end -- instructions are clear enough for Claude to produce good coaching output

## Test Summary
| Category | # Tests | Status |
|----------|---------|--------|
| Core behaviors | 6 | PASS |
| Edge cases | 2 | PASS |
| **Total** | **8** (26 assertions) | **ALL PASS** |
