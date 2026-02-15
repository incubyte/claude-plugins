# TDD Plan: Bee Coach Phase 1 -- Slice 1: Stop Hook

## Execution Instructions
Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] -> [x]).
Continue until all items are done.
If stuck after 3 attempts, mark with a warning and move to the next independent step.

## Context
- **Source**: `docs/specs/bee-coach-phase-1.md`
- **Slice**: Stop Hook (`.claude/hooks/stop-session.sh`)
- **Risk**: LOW
- **Acceptance Criteria**:
  1. Shell script reads JSON from stdin (session_id, transcript_path, cwd)
  2. Reads JSONL transcript, computes metrics: message counts, token usage, tool use counts, bee workflow flags, file counts, errors
  3. Detects bee workflow usage by scanning for spec writes, TDD plan writes, verification/review agent calls
  4. Resolves git branch from cwd
  5. Computes session duration from first/last timestamps
  6. Appends one JSON line to `.claude/bee-insights/session-log.jsonl` (creates dir/file if needed)
  7. Follows discovery schema
  8. Exits silently on success
  9. Exits gracefully on missing/unreadable transcript
  10. Registered in `.claude/settings.json` under hooks.Stop

## Codebase Analysis

### File Structure
- Implementation: `.claude/hooks/stop-session.sh`
- Test harness: `.claude/hooks/test-stop-session.sh`
- Test fixtures: `.claude/hooks/fixtures/` (sample JSONL transcripts)
- Settings: `.claude/settings.json` (add hook registration)

### Test Infrastructure
- Framework: None -- pure shell. Tests are a bash script that pipes fixture data into the hook and asserts output using `diff`, `jq`, and exit codes.
- Run command: `bash .claude/hooks/test-stop-session.sh`
- Existing helpers: None. We create the test harness as the first step.
- Dependencies: `jq` (JSON processing), `git` (branch resolution)

### Test Strategy

Since this is a shell script, each "test" is a function in the test harness that:
1. Sets up a temp directory with fixture files
2. Pipes JSON stdin into the hook script
3. Checks the output file (session-log.jsonl) or exit code
4. Prints PASS/FAIL with the behavior name

The test harness creates and tears down a temp directory per test run. All file paths are relative to the temp dir so tests are isolated.

---

## Behavior 0: Test Harness Skeleton

- [x] **RED**: Create `.claude/hooks/test-stop-session.sh` with a helper framework
  - A `setup` function that creates a temp dir and sets `TEST_DIR`
  - A `teardown` function that removes the temp dir
  - An `assert_eq` function that compares two values and prints PASS/FAIL
  - An `assert_file_exists` function
  - A `run_hook` function that pipes stdin JSON into the hook script, setting `BEE_INSIGHTS_DIR` to the temp dir
  - One placeholder test that calls the hook with empty stdin and expects it to exit without crashing
  - Run it. It fails because `.claude/hooks/stop-session.sh` does not exist yet.

- [x] **GREEN**: Create `.claude/hooks/stop-session.sh` as an empty script with `#!/usr/bin/env bash` and `set -euo pipefail`. Make it executable. The placeholder test should now pass (script exists and exits 0).

- [x] **RUN**: Confirm the harness runs and the placeholder test passes.

- [x] **COMMIT**: "chore: add stop hook test harness and empty hook script"

---

## Behavior 1: Read JSON from stdin and handle missing transcript gracefully

**Given** stdin contains `{"session_id":"s1","transcript_path":"/nonexistent/path","cwd":"/tmp"}`
**When** the hook runs
**Then** exit code is 0, no output to stdout or stderr, no session-log.jsonl created

- [x] **RED**: Write test `test_missing_transcript_exits_gracefully`
  - Pipe the JSON with a nonexistent transcript_path
  - Assert exit code is 0
  - Assert no output on stdout or stderr (capture with `2>&1`)
  - Assert `.claude/bee-insights/session-log.jsonl` does NOT exist in the test dir

- [x] **RUN**: Confirm test FAILS (script does not parse stdin yet)

- [x] **GREEN**: Implement stdin reading with `jq`
  - Read stdin into a variable
  - Extract `session_id`, `transcript_path`, `cwd` using `jq -r`
  - Check if transcript file exists/is readable; if not, `exit 0` silently

- [x] **RUN**: Confirm test PASSES

- [x] **REFACTOR**: None needed yet.

- [x] **COMMIT**: "feat: hook reads stdin JSON and exits gracefully on missing transcript"

---

## Behavior 2: Compute message counts from transcript JSONL

**Given** a transcript JSONL fixture with known message types (user, assistant, tool_use, tool_result)
**When** the hook runs
**Then** the output JSON line has correct `message_counts`

- [x] **RED**: Write test `test_counts_messages_by_type`
  - Create a fixture file with ~6 JSONL lines: 3 user, 3 assistant, 1 tool_use, 1 tool_result
  - Pipe stdin pointing to that fixture
  - Read the resulting session-log.jsonl line
  - Assert `message_counts.user == 3`, `.assistant == 3`, `.tool_use == 1`, `.tool_result == 1` using `jq`

- [x] **RUN**: Confirm test FAILS

- [x] **GREEN**: Add transcript reading logic
  - Read the JSONL file with `jq -s` for slurp mode
  - Count messages by `type` field, tool_use/tool_result from nested content arrays
  - Build the output JSON with `message_counts` populated
  - Append to `$BEE_INSIGHTS_DIR/session-log.jsonl` (create dir with `mkdir -p`)

- [x] **RUN**: Confirm test PASSES

- [x] **REFACTOR**: Extracted counting logic into `count_messages` function.

- [x] **COMMIT**: "feat: hook computes message counts from transcript"

---

## Behavior 3: Compute token usage totals

**Given** a transcript fixture where messages have `usage.input_tokens` and `usage.output_tokens` fields
**When** the hook runs
**Then** the output JSON line has correct `token_usage` sums

- [x] **RED**: Write test `test_sums_token_usage`
  - Fixture has 3 assistant messages with usage: 100+200+150 input, 50+75+25 output
  - Assert `token_usage.input_tokens == 450`, `.output_tokens == 150`

- [x] **RUN**: Confirm test FAILS

- [x] **GREEN**: Add `sum_token_usage` function using `jq -s` to sum across assistant messages

- [x] **RUN**: Confirm test PASSES

- [x] **REFACTOR**: Each metric function does its own pass. Will consolidate in Behavior 10.

- [x] **COMMIT**: "feat: hook computes token usage totals"

---

## Behavior 4: Count tool usage by tool name

**Given** a transcript fixture with tool_use messages referencing different tool names (Read, Write, Bash, etc.)
**When** the hook runs
**Then** the output JSON line has correct `tools_used` counts

- [x] **RED**: Write test `test_counts_tool_usage`
  - Fixture has 1 Read tool_use
  - Assert `tools_used.Read == 1`, others == 0

- [x] **RUN**: Confirm test FAILS

- [x] **GREEN**: Add `count_tools` function — extracts tool names from assistant content, counts per known tool

- [x] **RUN**: Confirm test PASSES

- [x] **REFACTOR**: None needed.

- [x] **COMMIT**: "feat: hook counts tool usage by name"

---

## Behavior 5: Detect bee workflow flags

**Given** a transcript fixture where Write tool was called on `docs/specs/my-feature.md` and a Task tool call mentions "verifier"
**When** the hook runs
**Then** `bee_workflow.spec_written == true`, `bee_workflow.verification_run == true`, others false

- [x] **RED**: Write test `test_detects_bee_workflow_flags`
- [x] **RUN**: Confirm test FAILS
- [x] **GREEN**: Add `detect_workflow` function — concatenates prompt + subagent_type for matching
- [x] **RUN**: Confirm test PASSES
- [x] **REFACTOR**: Extracted into `detect_workflow` function.
- [x] **COMMIT**: "feat: hook detects bee workflow usage from transcript"

---

## Behavior 6: Count files modified and test files modified

**Given** a transcript with Write tool calls to 3 unique files, 1 of which matches a test pattern (e.g., `*.test.ts`)
**When** the hook runs
**Then** `files_modified == 3`, `test_files_modified == 1`

- [x] **RED**: Write test `test_counts_files_modified`
- [x] **RUN**: Confirm test FAILS
- [x] **GREEN**: Add `count_files` function
- [x] **RUN**: Confirm test PASSES
- [x] **COMMIT**: "feat: hook counts modified files and test files"

---

## Behavior 7: Count errors observed

**Given** a transcript with tool_result messages, some containing `is_error: true`
**When** the hook runs
**Then** `errors_observed` equals the count of error results

- [x] **RED**: Write test `test_counts_errors`
- [x] **RUN**: Confirm test FAILS
- [x] **GREEN**: Add `count_errors` function
- [x] **RUN**: Confirm test PASSES
- [x] **COMMIT**: "feat: hook counts errors observed"

---

## Behavior 8: Resolve git branch from cwd

**Given** stdin cwd points to a git repository
**When** the hook runs
**Then** `git_branch` contains the current branch name

- [x] **RED**: Write test `test_resolves_git_branch`
- [x] **RUN**: Confirm test FAILS
- [x] **GREEN**: Add `resolve_git_branch` function
- [x] **RUN**: Confirm test PASSES
- [x] **COMMIT**: "feat: hook resolves git branch from cwd"

---

## Behavior 9: Compute session duration from timestamps

**Given** a transcript where the first message has timestamp `2024-01-01T10:00:00Z` and last has `2024-01-01T10:15:30Z`
**When** the hook runs
**Then** `duration_seconds == 930`

- [x] **RED**: Write test `test_computes_session_duration`
- [x] **RUN**: Confirm test FAILS
- [x] **GREEN**: Add `compute_duration` function using `date` conversion
- [x] **RUN**: Confirm test PASSES
- [x] **COMMIT**: "feat: hook computes session duration from timestamps"

---

## Behavior 10: Full schema output and file creation

**Given** a complete transcript fixture with all fields
**When** the hook runs
**Then** the output JSON line contains ALL schema fields (session_id, timestamp, duration_seconds, cwd, git_branch, message_counts, token_usage, tools_used, bee_workflow, files_modified, test_files_modified, errors_observed, transcript_path) and the `.claude/bee-insights/` directory and file were created

- [x] **RED**: Write test `test_full_schema_output`
- [x] **RUN**: Confirm test FAILS
- [x] **GREEN**: All fields already present from incremental builds
- [x] **RUN**: Confirm test PASSES
- [x] **REFACTOR**: Functions already extracted: `count_messages`, `sum_token_usage`, `count_tools`, `detect_workflow`, `count_files`, `count_errors`, `resolve_git_branch`, `compute_duration`
- [x] **COMMIT**: "feat: hook outputs complete schema and creates insights directory"

---

## Behavior 11: Appends (not overwrites) on subsequent runs

**Given** session-log.jsonl already has 1 line from a previous run
**When** the hook runs again with a different session
**Then** session-log.jsonl has 2 lines

- [x] **RED**: Write test `test_appends_to_existing_log`
- [x] **RUN**: Passed (append was already implemented with `>>`)
- [x] **GREEN**: Regression guard confirmed
- [x] **COMMIT**: "feat: hook appends to session log, does not overwrite"

---

## Behavior 12: Register hook in settings.json

**Given** the current `.claude/settings.json`
**When** we add the Stop hook registration
**Then** `hooks.Stop` array contains the hook command pointing to `.claude/hooks/stop-session.sh`

- [x] **RED**: Write test `test_settings_has_stop_hook`
- [x] **RUN**: Confirm test FAILS
- [x] **GREEN**: Updated `.claude/settings.json` with Stop hook registration
- [x] **RUN**: Confirm test PASSES
- [x] **COMMIT**: "feat: register stop hook in settings.json"

---

## Edge Cases

### Always (LOW risk -- happy path + 1-2 edge cases)

- [x] **RED**: Test `test_empty_transcript_file` — exits 0 on empty file
- [x] **GREEN -> REFACTOR**: Passes (empty file produces no jq errors, exits gracefully)

- [x] **RED**: Test `test_transcript_with_unknown_message_types` — unknown types ignored, known types counted
- [x] **GREEN -> REFACTOR**: Passes (jq selectors only match known types)

- [x] **RED**: Test `test_no_git_repo_at_cwd` — git_branch is "unknown"
- [x] **GREEN -> REFACTOR**: Passes (fallback `|| echo "unknown"` works)

- [x] **COMMIT**: "test: stop hook edge cases"

---

## Final Check

- [x] **Run full test suite**: `bash .claude/hooks/test-stop-session.sh` -- 50 assertions, 16 tests, all pass
- [x] **Review test names**: Clear and descriptive
- [x] **Review implementation**: 8 focused functions, no dead code, clean naming
- [x] **Verify silent operation**: Hook produces zero stdout/stderr output

## Test Summary
| Category | # Tests | Status |
|----------|---------|--------|
| Core behaviors | 12 | PASS |
| Edge cases | 3 | PASS |
| **Total** | **15** (50 assertions) | **ALL PASS** |

[x] Reviewed
