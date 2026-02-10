#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/stop-session.sh"

PASS_COUNT=0
FAIL_COUNT=0
TEST_DIR=""

setup() {
  TEST_DIR="$(mktemp -d)"
  export BEE_INSIGHTS_DIR="$TEST_DIR/.bee-insights"
}

teardown() {
  if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
    rm -rf "$TEST_DIR"
  fi
}

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $label"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: $label (expected '$expected', got '$actual')"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_file_exists() {
  local label="$1" path="$2"
  if [[ -f "$path" ]]; then
    echo "  PASS: $label"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: $label (file not found: $path)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_file_not_exists() {
  local label="$1" path="$2"
  if [[ ! -f "$path" ]]; then
    echo "  PASS: $label"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: $label (file should not exist: $path)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

run_hook() {
  local stdin_json="$1"
  echo "$stdin_json" | bash "$HOOK_SCRIPT" 2>/dev/null
}

run_hook_capture() {
  local stdin_json="$1"
  echo "$stdin_json" | bash "$HOOK_SCRIPT" 2>&1
}

get_log_field() {
  local field="$1"
  jq -r "$field" "$BEE_INSIGHTS_DIR/session-log.jsonl"
}

# --- Tests ---

test_hook_exists_and_runs() {
  echo "TEST: hook exists and runs without crashing"
  setup
  local output
  output=$(echo '{}' | bash "$HOOK_SCRIPT" 2>&1) || true
  assert_eq "exit without crash" "" "$output"
  teardown
}

test_missing_transcript_exits_gracefully() {
  echo "TEST: missing transcript exits gracefully"
  setup
  local output exit_code
  output=$(run_hook_capture '{"session_id":"s1","transcript_path":"/nonexistent/path","cwd":"/tmp"}') || true
  exit_code=$?
  assert_eq "no output" "" "$output"
  assert_file_not_exists "no session log created" "$BEE_INSIGHTS_DIR/session-log.jsonl"
  teardown
}

test_counts_tool_usage() {
  echo "TEST: counts tool usage by name"
  setup
  local fixture="$SCRIPT_DIR/fixtures/basic-session.jsonl"
  run_hook "{\"session_id\":\"s1\",\"transcript_path\":\"$fixture\",\"cwd\":\"/tmp\"}"
  local log_line="$BEE_INSIGHTS_DIR/session-log.jsonl"
  assert_eq "Read count" "1" "$(jq -r '.tools_used.Read' "$log_line")"
  assert_eq "Write count" "0" "$(jq -r '.tools_used.Write' "$log_line")"
  assert_eq "Bash count" "0" "$(jq -r '.tools_used.Bash' "$log_line")"
  assert_eq "Glob count" "0" "$(jq -r '.tools_used.Glob' "$log_line")"
  assert_eq "Grep count" "0" "$(jq -r '.tools_used.Grep' "$log_line")"
  assert_eq "Task count" "0" "$(jq -r '.tools_used.Task' "$log_line")"
  teardown
}

test_sums_token_usage() {
  echo "TEST: sums token usage"
  setup
  local fixture="$SCRIPT_DIR/fixtures/basic-session.jsonl"
  run_hook "{\"session_id\":\"s1\",\"transcript_path\":\"$fixture\",\"cwd\":\"/tmp\"}"
  local log_line="$BEE_INSIGHTS_DIR/session-log.jsonl"
  assert_eq "input_tokens" "450" "$(jq -r '.token_usage.input_tokens' "$log_line")"
  assert_eq "output_tokens" "150" "$(jq -r '.token_usage.output_tokens' "$log_line")"
  teardown
}

test_counts_messages_by_type() {
  echo "TEST: counts messages by type"
  setup
  local fixture="$SCRIPT_DIR/fixtures/basic-session.jsonl"
  run_hook "{\"session_id\":\"s1\",\"transcript_path\":\"$fixture\",\"cwd\":\"/tmp\"}"
  local log_line="$BEE_INSIGHTS_DIR/session-log.jsonl"
  assert_file_exists "session log created" "$log_line"
  assert_eq "user count" "3" "$(jq -r '.message_counts.user' "$log_line")"
  assert_eq "assistant count" "3" "$(jq -r '.message_counts.assistant' "$log_line")"
  assert_eq "tool_use count" "1" "$(jq -r '.message_counts.tool_use' "$log_line")"
  assert_eq "tool_result count" "1" "$(jq -r '.message_counts.tool_result' "$log_line")"
  teardown
}

test_resolves_git_branch() {
  echo "TEST: resolves git branch from cwd"
  setup
  local git_dir="$TEST_DIR/repo"
  mkdir -p "$git_dir"
  git -C "$git_dir" init -q -b test-branch
  git -C "$git_dir" commit -q --allow-empty -m "init"
  local fixture="$SCRIPT_DIR/fixtures/basic-session.jsonl"
  run_hook "{\"session_id\":\"s1\",\"transcript_path\":\"$fixture\",\"cwd\":\"$git_dir\"}"
  local log_line="$BEE_INSIGHTS_DIR/session-log.jsonl"
  assert_eq "git_branch" "test-branch" "$(jq -r '.git_branch' "$log_line")"
  teardown
}

test_computes_session_duration() {
  echo "TEST: computes session duration from timestamps"
  setup
  local fixture="$SCRIPT_DIR/fixtures/basic-session.jsonl"
  run_hook "{\"session_id\":\"s1\",\"transcript_path\":\"$fixture\",\"cwd\":\"/tmp\"}"
  local log_line="$BEE_INSIGHTS_DIR/session-log.jsonl"
  assert_eq "duration_seconds" "930" "$(jq -r '.duration_seconds' "$log_line")"
  teardown
}

test_detects_bee_workflow_flags() {
  echo "TEST: detects bee workflow flags"
  setup
  local fixture="$SCRIPT_DIR/fixtures/workflow-session.jsonl"
  run_hook "{\"session_id\":\"s1\",\"transcript_path\":\"$fixture\",\"cwd\":\"/tmp\"}"
  local log_line="$BEE_INSIGHTS_DIR/session-log.jsonl"
  assert_eq "spec_written" "true" "$(jq -r '.bee_workflow.spec_written' "$log_line")"
  assert_eq "tdd_plan_written" "false" "$(jq -r '.bee_workflow.tdd_plan_written' "$log_line")"
  assert_eq "verification_run" "true" "$(jq -r '.bee_workflow.verification_run' "$log_line")"
  assert_eq "review_run" "false" "$(jq -r '.bee_workflow.review_run' "$log_line")"
  teardown
}

test_counts_files_modified() {
  echo "TEST: counts files modified and test files"
  setup
  local fixture="$SCRIPT_DIR/fixtures/workflow-session.jsonl"
  run_hook "{\"session_id\":\"s1\",\"transcript_path\":\"$fixture\",\"cwd\":\"/tmp\"}"
  local log_line="$BEE_INSIGHTS_DIR/session-log.jsonl"
  assert_eq "files_modified" "3" "$(jq -r '.files_modified' "$log_line")"
  assert_eq "test_files_modified" "1" "$(jq -r '.test_files_modified' "$log_line")"
  teardown
}

test_counts_errors() {
  echo "TEST: counts errors observed"
  setup
  local fixture="$SCRIPT_DIR/fixtures/workflow-session.jsonl"
  run_hook "{\"session_id\":\"s1\",\"transcript_path\":\"$fixture\",\"cwd\":\"/tmp\"}"
  local log_line="$BEE_INSIGHTS_DIR/session-log.jsonl"
  assert_eq "errors_observed" "2" "$(jq -r '.errors_observed' "$log_line")"
  teardown
}

test_full_schema_output() {
  echo "TEST: full schema output with all fields"
  setup
  local fixture="$SCRIPT_DIR/fixtures/basic-session.jsonl"
  run_hook "{\"session_id\":\"s1\",\"transcript_path\":\"$fixture\",\"cwd\":\"/tmp\"}"
  local log_line="$BEE_INSIGHTS_DIR/session-log.jsonl"
  assert_file_exists "session log exists" "$log_line"
  assert_eq "has session_id" "true" "$(jq 'has("session_id")' "$log_line")"
  assert_eq "has timestamp" "true" "$(jq 'has("timestamp")' "$log_line")"
  assert_eq "has duration_seconds" "true" "$(jq 'has("duration_seconds")' "$log_line")"
  assert_eq "has cwd" "true" "$(jq 'has("cwd")' "$log_line")"
  assert_eq "has git_branch" "true" "$(jq 'has("git_branch")' "$log_line")"
  assert_eq "has message_counts" "true" "$(jq 'has("message_counts")' "$log_line")"
  assert_eq "has token_usage" "true" "$(jq 'has("token_usage")' "$log_line")"
  assert_eq "has tools_used" "true" "$(jq 'has("tools_used")' "$log_line")"
  assert_eq "has bee_workflow" "true" "$(jq 'has("bee_workflow")' "$log_line")"
  assert_eq "has files_modified" "true" "$(jq 'has("files_modified")' "$log_line")"
  assert_eq "has test_files_modified" "true" "$(jq 'has("test_files_modified")' "$log_line")"
  assert_eq "has errors_observed" "true" "$(jq 'has("errors_observed")' "$log_line")"
  assert_eq "has transcript_path" "true" "$(jq 'has("transcript_path")' "$log_line")"
  local line_count
  line_count=$(wc -l < "$log_line" | tr -d ' ')
  assert_eq "exactly 1 line" "1" "$line_count"
  teardown
}

test_appends_to_existing_log() {
  echo "TEST: appends to existing log, does not overwrite"
  setup
  local fixture="$SCRIPT_DIR/fixtures/basic-session.jsonl"
  run_hook "{\"session_id\":\"s1\",\"transcript_path\":\"$fixture\",\"cwd\":\"/tmp\"}"
  run_hook "{\"session_id\":\"s2\",\"transcript_path\":\"$fixture\",\"cwd\":\"/tmp\"}"
  local log_line="$BEE_INSIGHTS_DIR/session-log.jsonl"
  local line_count
  line_count=$(wc -l < "$log_line" | tr -d ' ')
  assert_eq "2 lines after 2 runs" "2" "$line_count"
  local first_id second_id
  first_id=$(sed -n '1p' "$log_line" | jq -r '.session_id')
  second_id=$(sed -n '2p' "$log_line" | jq -r '.session_id')
  assert_eq "first session_id" "s1" "$first_id"
  assert_eq "second session_id" "s2" "$second_id"
  teardown
}

test_settings_has_stop_hook() {
  echo "TEST: settings.json has Stop hook registered"
  local settings="$SCRIPT_DIR/../settings.json"
  local hook_count
  hook_count=$(jq '.hooks.Stop | length' "$settings" 2>/dev/null || echo "0")
  assert_eq "Stop hook array exists" "true" "$(jq 'has("hooks") and (.hooks | has("Stop"))' "$settings" 2>/dev/null || echo "false")"
  local has_command
  has_command=$(jq '.hooks.Stop[0].hooks[0].command | test("stop-session.sh")' "$settings" 2>/dev/null || echo "false")
  assert_eq "hook points to stop-session.sh" "true" "$has_command"
}

test_empty_transcript_file() {
  echo "TEST: empty transcript file exits gracefully"
  setup
  local empty_file="$TEST_DIR/empty.jsonl"
  touch "$empty_file"
  local output
  output=$(echo "{\"session_id\":\"s1\",\"transcript_path\":\"$empty_file\",\"cwd\":\"/tmp\"}" | bash "$HOOK_SCRIPT" 2>&1) || true
  assert_eq "no crash on empty file" "0" "$?"
  teardown
}

test_transcript_with_unknown_message_types() {
  echo "TEST: unknown message types are ignored"
  setup
  local fixture="$TEST_DIR/unknown.jsonl"
  printf '%s\n' \
    '{"type":"user","message":{"role":"user","content":"hi"},"timestamp":"2024-01-01T10:00:00Z"}' \
    '{"type":"foobar","message":{},"timestamp":"2024-01-01T10:01:00Z"}' \
    '{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"ok"}],"usage":{"input_tokens":10,"output_tokens":5}},"timestamp":"2024-01-01T10:02:00Z"}' \
    > "$fixture"
  run_hook "{\"session_id\":\"s1\",\"transcript_path\":\"$fixture\",\"cwd\":\"/tmp\"}"
  local log_line="$BEE_INSIGHTS_DIR/session-log.jsonl"
  assert_file_exists "log created despite unknown types" "$log_line"
  assert_eq "user count correct" "1" "$(jq -r '.message_counts.user' "$log_line")"
  assert_eq "assistant count correct" "1" "$(jq -r '.message_counts.assistant' "$log_line")"
  teardown
}

test_no_git_repo_at_cwd() {
  echo "TEST: no git repo at cwd"
  setup
  local no_git_dir="$TEST_DIR/no-git"
  mkdir -p "$no_git_dir"
  local fixture="$SCRIPT_DIR/fixtures/basic-session.jsonl"
  run_hook "{\"session_id\":\"s1\",\"transcript_path\":\"$fixture\",\"cwd\":\"$no_git_dir\"}"
  local log_line="$BEE_INSIGHTS_DIR/session-log.jsonl"
  assert_eq "git_branch is unknown" "unknown" "$(jq -r '.git_branch' "$log_line")"
  teardown
}

# --- Run all tests ---

run_tests() {
  echo "=== Stop Hook Test Suite ==="
  echo ""

  test_hook_exists_and_runs
  test_missing_transcript_exits_gracefully
  test_counts_messages_by_type
  test_sums_token_usage
  test_counts_tool_usage
  test_detects_bee_workflow_flags
  test_counts_files_modified
  test_counts_errors
  test_resolves_git_branch
  test_computes_session_duration
  test_full_schema_output
  test_appends_to_existing_log
  test_settings_has_stop_hook
  test_empty_transcript_file
  test_transcript_with_unknown_message_types
  test_no_git_repo_at_cwd

  echo ""
  echo "=== Results: $PASS_COUNT passed, $FAIL_COUNT failed ==="

  if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
  fi
}

run_tests
