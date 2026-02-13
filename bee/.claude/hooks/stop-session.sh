#!/usr/bin/env bash
set -eo pipefail

BEE_INSIGHTS_DIR="${BEE_INSIGHTS_DIR:-.claude/bee-insights}"

INPUT=$(cat) || true
if [[ -z "$INPUT" ]]; then
  exit 0
fi

session_id=$(echo "$INPUT" | jq -r '.session_id // empty')
transcript_path=$(echo "$INPUT" | jq -r '.transcript_path // empty')
cwd=$(echo "$INPUT" | jq -r '.cwd // empty')

if [[ -z "$transcript_path" || ! -r "$transcript_path" ]]; then
  exit 0
fi

count_messages() {
  local file="$1"
  local user_count assistant_count tool_use_count tool_result_count

  user_count=$(jq -s '[.[] | select(.type == "user")] | length' "$file")
  assistant_count=$(jq -s '[.[] | select(.type == "assistant")] | length' "$file")
  tool_use_count=$(jq -s '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use")] | length' "$file")
  tool_result_count=$(jq -s '[.[] | select(.type == "user") | .message.content | if type == "array" then .[] else empty end | select(.type == "tool_result")] | length' "$file")

  jq -n \
    --argjson user "$user_count" \
    --argjson assistant "$assistant_count" \
    --argjson tool_use "$tool_use_count" \
    --argjson tool_result "$tool_result_count" \
    '{user: $user, assistant: $assistant, tool_use: $tool_use, tool_result: $tool_result}'
}

sum_token_usage() {
  local file="$1"
  local input_tokens output_tokens

  input_tokens=$(jq -s '[.[] | select(.type == "assistant") | .message.usage.input_tokens // 0] | add // 0' "$file")
  output_tokens=$(jq -s '[.[] | select(.type == "assistant") | .message.usage.output_tokens // 0] | add // 0' "$file")

  jq -n \
    --argjson input_tokens "$input_tokens" \
    --argjson output_tokens "$output_tokens" \
    '{input_tokens: $input_tokens, output_tokens: $output_tokens}'
}

count_tools() {
  local file="$1"
  local tool_uses

  tool_uses=$(jq -s '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use") | .name]' "$file")

  jq -n \
    --argjson tools "$tool_uses" \
    '{
      Read: [$tools[] | select(. == "Read")] | length,
      Write: [$tools[] | select(. == "Write")] | length,
      Bash: [$tools[] | select(. == "Bash")] | length,
      Glob: [$tools[] | select(. == "Glob")] | length,
      Grep: [$tools[] | select(. == "Grep")] | length,
      Task: [$tools[] | select(. == "Task")] | length
    }'
}

detect_workflow() {
  local file="$1"
  local all_tool_uses

  all_tool_uses=$(jq -s '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use")]' "$file")

  local spec_written tdd_plan_written verification_run review_run

  spec_written=$(echo "$all_tool_uses" | jq '[.[] | select(.name == "Write" and (.input.file_path | test("docs/specs/.*\\.md$")))] | length > 0')
  tdd_plan_written=$(echo "$all_tool_uses" | jq '[.[] | select(.name == "Write" and (.input.file_path | test("tdd-plan")))] | length > 0')
  verification_run=$(echo "$all_tool_uses" | jq '[.[] | select(.name == "Task" and ((.input.prompt // "") + " " + (.input.subagent_type // "") | test("verifier")))] | length > 0')
  review_run=$(echo "$all_tool_uses" | jq '[.[] | select(.name == "Task" and ((.input.prompt // "") + " " + (.input.subagent_type // "") | test("reviewer")))] | length > 0')

  jq -n \
    --argjson spec_written "$spec_written" \
    --argjson tdd_plan_written "$tdd_plan_written" \
    --argjson verification_run "$verification_run" \
    --argjson review_run "$review_run" \
    '{spec_written: $spec_written, tdd_plan_written: $tdd_plan_written, verification_run: $verification_run, review_run: $review_run}'
}

count_files() {
  local file="$1"
  local write_paths

  write_paths=$(jq -s '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use" and .name == "Write") | .input.file_path] | unique' "$file")

  local files_modified test_files_modified

  files_modified=$(echo "$write_paths" | jq 'length')
  test_files_modified=$(echo "$write_paths" | jq '[.[] | select(test("\\.(test|spec)\\.|test_|_test\\."))] | length')

  echo "$files_modified $test_files_modified"
}

count_errors() {
  local file="$1"
  jq -s '[.[] | select(.type == "user") | .message.content | if type == "array" then .[] else empty end | select(.type == "tool_result" and .is_error == true)] | length' "$file"
}

resolve_git_branch() {
  local dir="$1"
  git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"
}

compute_duration() {
  local file="$1"
  local first_ts last_ts

  first_ts=$(jq -s '[.[] | select(.timestamp) | .timestamp] | first' -r "$file")
  last_ts=$(jq -s '[.[] | select(.timestamp) | .timestamp] | last' -r "$file")

  if [[ -z "$first_ts" || -z "$last_ts" || "$first_ts" == "null" || "$last_ts" == "null" ]]; then
    echo 0
    return
  fi

  local first_epoch last_epoch
  first_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$first_ts" "+%s" 2>/dev/null || date -d "$first_ts" "+%s" 2>/dev/null || echo 0)
  last_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" "+%s" 2>/dev/null || date -d "$last_ts" "+%s" 2>/dev/null || echo 0)

  echo $(( last_epoch - first_epoch ))
}

message_counts=$(count_messages "$transcript_path")
token_usage=$(sum_token_usage "$transcript_path")
tools_used=$(count_tools "$transcript_path")
bee_workflow=$(detect_workflow "$transcript_path")
file_counts=$(count_files "$transcript_path")
files_modified=$(echo "$file_counts" | awk '{print $1}')
test_files_modified=$(echo "$file_counts" | awk '{print $2}')
errors_observed=$(count_errors "$transcript_path")
git_branch=$(resolve_git_branch "$cwd")
duration_seconds=$(compute_duration "$transcript_path")
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$BEE_INSIGHTS_DIR"

jq -n -c \
  --arg session_id "$session_id" \
  --arg timestamp "$timestamp" \
  --argjson duration_seconds "$duration_seconds" \
  --arg cwd "$cwd" \
  --arg git_branch "$git_branch" \
  --argjson message_counts "$message_counts" \
  --argjson token_usage "$token_usage" \
  --argjson tools_used "$tools_used" \
  --argjson bee_workflow "$bee_workflow" \
  --argjson files_modified "$files_modified" \
  --argjson test_files_modified "$test_files_modified" \
  --argjson errors_observed "$errors_observed" \
  --arg transcript_path "$transcript_path" \
  '{
    session_id: $session_id,
    timestamp: $timestamp,
    duration_seconds: $duration_seconds,
    cwd: $cwd,
    git_branch: $git_branch,
    message_counts: $message_counts,
    token_usage: $token_usage,
    tools_used: $tools_used,
    bee_workflow: $bee_workflow,
    files_modified: $files_modified,
    test_files_modified: $test_files_modified,
    errors_observed: $errors_observed,
    transcript_path: $transcript_path
  }' >> "$BEE_INSIGHTS_DIR/session-log.jsonl"
