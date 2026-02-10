#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMMAND_FILE="$REPO_ROOT/commands/bee-coach.md"

PASS_COUNT=0
FAIL_COUNT=0

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

assert_grep() {
  local label="$1" pattern="$2" file="$3"
  if grep -q "$pattern" "$file" 2>/dev/null; then
    echo "  PASS: $label"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: $label (pattern '$pattern' not found)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# --- Tests ---

test_command_file_exists_with_frontmatter() {
  echo "TEST: command file exists with correct frontmatter"
  assert_file_exists "bee-coach.md exists" "$COMMAND_FILE"
  local first_line
  first_line=$(head -n 1 "$COMMAND_FILE")
  assert_eq "starts with YAML delimiter" "---" "$first_line"
  assert_grep "has description field" "^description:" "$COMMAND_FILE"
}

test_command_describes_invocation_modes() {
  echo "TEST: command describes three invocation modes"
  assert_grep "describes default behavior" "last session" "$COMMAND_FILE"
  assert_grep "describes --last flag" "\-\-last" "$COMMAND_FILE"
  assert_grep "describes --all flag" "\-\-all" "$COMMAND_FILE"
  assert_grep "references ARGUMENTS" "ARGUMENTS" "$COMMAND_FILE"
}

test_command_references_four_coaching_categories() {
  echo "TEST: command references four coaching categories"
  assert_grep "workflow adoption category" "[Ww]orkflow [Aa]doption" "$COMMAND_FILE"
  assert_grep "prompt quality category" "[Pp]rompt [Qq]uality" "$COMMAND_FILE"
  assert_grep "session efficiency category" "[Ss]ession [Ee]fficiency" "$COMMAND_FILE"
  assert_grep "code quality signals category" "[Cc]ode [Qq]uality [Ss]ignals" "$COMMAND_FILE"
}

test_command_instructs_report_saving() {
  echo "TEST: command instructs saving the coaching report"
  assert_grep "report save path" "\.bee-insights/coaching-report-" "$COMMAND_FILE"
  assert_grep "overwrite behavior" "[Oo]verwrite" "$COMMAND_FILE"
  assert_grep "report includes insights" "insights" "$COMMAND_FILE"
  assert_grep "report includes trend" "trend" "$COMMAND_FILE"
}

test_command_instructs_trend_analysis() {
  echo "TEST: command instructs trend analysis from session log"
  assert_grep "references session-log.jsonl" "session-log.jsonl" "$COMMAND_FILE"
  assert_grep "relative framing" "relative\|directional\|went from\|compared to" "$COMMAND_FILE"
  assert_grep "fewer than 2 sessions" "fewer than 2\|less than 2\|not enough" "$COMMAND_FILE"
}

test_command_sets_coaching_tone() {
  echo "TEST: command sets encouraging coaching tone"
  assert_grep "encouraging tone" "encouraging" "$COMMAND_FILE"
  assert_grep "non-judgmental tone" "non-judgmental\|nonjudgmental" "$COMMAND_FILE"
  assert_grep "2-4 insights" "2-4" "$COMMAND_FILE"
  assert_grep "actionable insights" "actionable\|specific" "$COMMAND_FILE"
}

test_command_is_valid_markdown() {
  echo "TEST: command file is well-formed markdown"
  local second_delimiter
  second_delimiter=$(sed -n '2,$ p' "$COMMAND_FILE" | grep -n "^---$" | head -1 | cut -d: -f1)
  assert_eq "frontmatter closes with ---" "true" "$( [[ -n "$second_delimiter" ]] && echo true || echo false )"
  local line_count
  line_count=$(wc -l < "$COMMAND_FILE" | tr -d ' ')
  assert_eq "file has more than 10 lines" "true" "$( [[ "$line_count" -gt 10 ]] && echo true || echo false )"
}

test_frontmatter_has_only_description() {
  echo "TEST: frontmatter matches bee.md convention"
  local frontmatter
  frontmatter=$(sed -n '2,/^---$/p' "$COMMAND_FILE" | sed '$d')
  local has_desc
  has_desc=$(echo "$frontmatter" | grep -c "description:" || true)
  assert_eq "frontmatter has description" "1" "$has_desc"
  local key_count
  key_count=$(echo "$frontmatter" | grep -c "^[a-z]" || true)
  assert_eq "frontmatter has exactly 1 key" "1" "$key_count"
}

# --- Run all tests ---

run_tests() {
  echo "=== Bee Coach Command Test Suite ==="
  echo ""

  test_command_file_exists_with_frontmatter
  test_command_describes_invocation_modes
  test_command_references_four_coaching_categories
  test_command_instructs_report_saving
  test_command_instructs_trend_analysis
  test_command_sets_coaching_tone
  test_command_is_valid_markdown
  test_frontmatter_has_only_description

  echo ""
  echo "=== Results: $PASS_COUNT passed, $FAIL_COUNT failed ==="

  if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
  fi
}

run_tests
