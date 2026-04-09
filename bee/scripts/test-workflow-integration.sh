#!/usr/bin/env bash
set -eo pipefail

# test-workflow-integration.sh — Test suite for Playwright-BDD workflow integration
#
# Tests Slice 2 acceptance criteria (Step 1.5 cache integration):
# - Step 1.5 exists and is correctly positioned in workflow
# - Cache check logic uses cache-reader.sh validate command
# - All four cache states (missing/fresh/stale/corrupt) have appropriate prompts
# - Prompt options match spec exactly
# - Workflow branching logic is correct (skip agents when using cache, run agents when re-analyzing)
# - Confirmation messages match spec
#
# Tests Slice 6 acceptance criteria (Gap suggestion approval format):
# - Approval file generation includes gap suggestions section for each missing step
# - Suggestions grouped by gap (one section per missing step)
# - Status shows "Gap detected (no existing matches found)" for each gap
# - Suggested step definitions listed with target file location
# - Source shown for each suggestion (pattern catalog / flow catalog / existing steps)
# - Choice provided: "Use suggestion #N" / "Create custom step definition"
# - One-by-one approval required (no bulk creation action)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Path to the playwright-bdd command file
COMMAND_FILE="$PROJECT_ROOT/bee/commands/playwright-bdd.md"

# --- Test Helpers ---

assert_true() {
  local condition="$1"
  local test_name="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$condition" == "true" ]]; then
    echo -e "${GREEN}PASS${NC} - $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}FAIL${NC} - $test_name"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ -f "$file" ]] && grep -qF -- "$pattern" "$file"; then
    echo -e "${GREEN}PASS${NC} - $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}FAIL${NC} - $test_name"
    echo "  Expected to find: '$pattern'"
    if [[ ! -f "$file" ]]; then
      echo "  File not found: $file"
    else
      echo "  In file: $file"
    fi
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_file_contains_regex() {
  local file="$1"
  local pattern="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ -f "$file" ]] && grep -qE "$pattern" "$file"; then
    echo -e "${GREEN}PASS${NC} - $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}FAIL${NC} - $test_name"
    echo "  Expected to match regex: '$pattern'"
    if [[ ! -f "$file" ]]; then
      echo "  File not found: $file"
    else
      echo "  In file: $file"
    fi
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_section_exists() {
  local file="$1"
  local section_header="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ -f "$file" ]] && grep -qF "$section_header" "$file"; then
    echo -e "${GREEN}PASS${NC} - $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}FAIL${NC} - $test_name"
    echo "  Expected section header: '$section_header'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_section_before_section() {
  local file="$1"
  local section1="$2"
  local section2="$3"
  local test_name="$4"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ ! -f "$file" ]]; then
    echo -e "${RED}FAIL${NC} - $test_name"
    echo "  File not found: $file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return
  fi

  local line1
  line1=$(grep -n "^### $section1$" "$file" | cut -d: -f1 | head -1)
  local line2
  line2=$(grep -n "^### $section2$" "$file" | cut -d: -f1 | head -1)

  if [[ -n "$line1" && -n "$line2" && "$line1" -lt "$line2" ]]; then
    echo -e "${GREEN}PASS${NC} - $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}FAIL${NC} - $test_name"
    echo "  Expected '$section1' (line $line1) to come before '$section2' (line $line2)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

extract_step_section() {
  local file="$1"
  local step_header="$2"

  # Extract content between step header and next ### or end of file
  sed -n "/^### $step_header$/,/^### /p" "$file" | sed '$d'
}

# --- Test Suites ---

test_step_1_5_exists() {
  echo ""
  echo "=== Testing Step 1.5 existence and positioning ==="

  # Test 1: Step 1.5 section exists
  assert_section_exists "$COMMAND_FILE" "### Step 1.5: Cache Check and Invalidation" \
    "Step 1.5 section header exists"

  # Test 2: Step 1.5 comes after Step 1 (Validate Input Path)
  assert_section_before_section "$COMMAND_FILE" "Step 1: Validate Input Path" "Step 1.5: Cache Check and Invalidation" \
    "Step 1.5 positioned after Step 1"

  # Test 3: Step 1.5 comes before Step 2 (Repository Structure Detection)
  assert_section_before_section "$COMMAND_FILE" "Step 1.5: Cache Check and Invalidation" "Step 2: Repository Structure Detection" \
    "Step 1.5 positioned before Step 2"
}

test_cache_check_logic() {
  echo ""
  echo "=== Testing cache check logic ==="

  local step_content
  step_content=$(extract_step_section "$COMMAND_FILE" "Step 1.5: Cache Check and Invalidation")

  # Test 1: Uses Glob to count feature files
  assert_true "$(echo "$step_content" | grep -q "Glob.*\.feature" && echo true || echo false)" \
    "Step 1.5 uses Glob to count .feature files"

  # Test 2: Uses Glob to count step definition files
  assert_true "$(echo "$step_content" | grep -qE "Glob.*\*\.steps\.(ts|js)" && echo true || echo false)" \
    "Step 1.5 uses Glob to count step definition files"

  # Test 3: Stores current file counts
  assert_file_contains_regex "$COMMAND_FILE" "current_feature_count.*current_step_count" \
    "Step 1.5 stores current file counts"

  # Test 4: Uses cache-reader.sh validate command
  assert_file_contains "$COMMAND_FILE" "bash bee/scripts/cache-reader.sh validate" \
    "Step 1.5 uses cache-reader.sh validate command"

  # Test 5: Passes current counts to validate command
  assert_file_contains_regex "$COMMAND_FILE" "cache-reader.sh validate.*current_feature_count.*current_step_count" \
    "Step 1.5 passes current counts to validate"

  # Test 6: Stores cache status result
  assert_file_contains_regex "$COMMAND_FILE" "(cache_status|Store result:.*cache_status)" \
    "Step 1.5 stores cache status result"
}

test_cache_missing_state() {
  echo ""
  echo "=== Testing cache missing state handling ==="

  local step_content
  step_content=$(extract_step_section "$COMMAND_FILE" "Step 1.5: Cache Check and Invalidation")

  # Test 1: Checks for missing state
  assert_file_contains "$COMMAND_FILE" 'cache_status == "missing"' \
    "Step 1.5 checks for missing cache state"

  # Test 2: Shows correct message for missing cache
  assert_file_contains "$COMMAND_FILE" "No cache found. Running initial analysis..." \
    "Step 1.5 shows correct message for missing cache"

  # Test 3: Continues to Step 2 when cache is missing
  assert_file_contains "$COMMAND_FILE" "Continue to Step 2 (all 4 agents will run)" \
    "Step 1.5 continues to Step 2 when cache is missing"

  # Test 4: Writes cache after agent completion
  assert_file_contains "$COMMAND_FILE" "bash bee/scripts/cache-writer.sh write" \
    "Step 1.5 writes cache after agents complete"

  # Test 5: Shows confirmation after cache write
  assert_file_contains "$COMMAND_FILE" "Cache updated with latest analysis" \
    "Step 1.5 shows confirmation message after cache write"
}

test_cache_corrupt_state() {
  echo ""
  echo "=== Testing cache corrupt state handling ==="

  # Test 1: Checks for corrupt state
  assert_file_contains "$COMMAND_FILE" 'cache_status == "corrupt"' \
    "Step 1.5 checks for corrupt cache state"

  # Test 2: Uses AskUserQuestion for corrupt cache
  assert_file_contains "$COMMAND_FILE" "Use AskUserQuestion: \"Cache file is corrupt" \
    "Step 1.5 uses AskUserQuestion for corrupt cache"

  # Test 3: Prompt text matches spec
  assert_file_contains "$COMMAND_FILE" "Cache file is corrupt. Re-analyze?" \
    "Step 1.5 shows correct corrupt cache prompt"

  # Test 4: Offers Yes/Cancel options
  assert_file_contains_regex "$COMMAND_FILE" "corrupt.*\[Yes / Cancel\]" \
    "Step 1.5 offers Yes/Cancel options for corrupt cache"

  # Test 5: Yes choice runs agents
  assert_file_contains_regex "$COMMAND_FILE" 'If "Yes".*continue to Step 2.*run all agents' \
    "Step 1.5 runs all agents when Yes is selected for corrupt cache"

  # Test 6: Cancel choice exits workflow
  assert_file_contains_regex "$COMMAND_FILE" 'If "Cancel".*exit workflow' \
    "Step 1.5 exits workflow when Cancel is selected for corrupt cache"

  # Test 7: Exit message mentions the cache file
  assert_file_contains "$COMMAND_FILE" "Workflow cancelled. Fix or delete docs/playwright-init.md" \
    "Step 1.5 shows helpful exit message for corrupt cache"
}

test_cache_stale_state() {
  echo ""
  echo "=== Testing cache stale state handling ==="

  # Test 1: Checks for stale state
  assert_file_contains "$COMMAND_FILE" 'cache_status == "stale"' \
    "Step 1.5 checks for stale cache state"

  # Test 2: Reads cached counts
  assert_file_contains "$COMMAND_FILE" "cached_features=\$(bash bee/scripts/cache-reader.sh get --field feature_file_count)" \
    "Step 1.5 reads cached feature count"

  assert_file_contains "$COMMAND_FILE" "cached_steps=\$(bash bee/scripts/cache-reader.sh get --field step_file_count)" \
    "Step 1.5 reads cached step count"

  # Test 3: Calculates deltas
  assert_file_contains_regex "$COMMAND_FILE" "feature_delta.*=.*current_feature_count - cached_features" \
    "Step 1.5 calculates feature count delta"

  assert_file_contains_regex "$COMMAND_FILE" "step_delta.*=.*current_step_count - cached_steps" \
    "Step 1.5 calculates step count delta"

  # Test 4: Uses AskUserQuestion with delta information
  assert_file_contains "$COMMAND_FILE" "Cache is stale (file count changed:" \
    "Step 1.5 shows file count change in stale cache prompt"

  # Test 5: Shows deltas in prompt
  assert_file_contains_regex "$COMMAND_FILE" '\$\{feature_delta\}.*features.*\$\{step_delta\}.*steps' \
    "Step 1.5 shows deltas in stale cache prompt"

  # Test 6: Offers three options with correct text
  assert_file_contains "$COMMAND_FILE" "[Yes (Recommended) / Use stale cache / Cancel]" \
    "Step 1.5 offers correct options for stale cache"

  # Test 7: Yes (Recommended) is marked as recommended
  assert_file_contains_regex "$COMMAND_FILE" 'Recommended option: "Yes \(Recommended\)".*auto-selected' \
    "Step 1.5 marks Yes as recommended for stale cache"

  # Test 8: Yes choice runs agents
  assert_file_contains_regex "$COMMAND_FILE" 'If "Yes \(Recommended\)".*continue to Step 2.*run all agents' \
    "Step 1.5 runs all agents when Yes is selected for stale cache"

  # Test 9: Use stale cache choice loads cache
  assert_file_contains_regex "$COMMAND_FILE" 'If "Use stale cache".*load cached data' \
    "Step 1.5 loads cache when Use stale cache is selected"

  # Test 10: Use stale cache skips agents
  assert_file_contains_regex "$COMMAND_FILE" 'Use stale cache.*skip agents' \
    "Step 1.5 skips agents when using stale cache"

  # Test 11: Shows confirmation with timestamp when using cache
  assert_file_contains "$COMMAND_FILE" "Using cached analysis from [last_updated]" \
    "Step 1.5 shows timestamp when using stale cache"

  # Test 12: Shows cache summary when using cache
  assert_file_contains "$COMMAND_FILE" "Cache contains: N flows, M patterns, P step definitions" \
    "Step 1.5 shows cache summary when using stale cache"

  # Test 13: Cancel choice exits
  assert_file_contains_regex "$COMMAND_FILE" 'If "Cancel".*exit workflow.*"Workflow cancelled\."' \
    "Step 1.5 exits workflow when Cancel is selected for stale cache"
}

test_cache_fresh_state() {
  echo ""
  echo "=== Testing cache fresh state handling ==="

  # Test 1: Checks for fresh state
  assert_file_contains "$COMMAND_FILE" 'cache_status == "fresh"' \
    "Step 1.5 checks for fresh cache state"

  # Test 2: Reads last updated timestamp
  assert_file_contains "$COMMAND_FILE" "last_updated=\$(bash bee/scripts/cache-reader.sh get --field last_updated)" \
    "Step 1.5 reads last updated timestamp"

  # Test 3: Formats timestamp for display
  assert_file_contains "$COMMAND_FILE" "Format timestamp for display" \
    "Step 1.5 formats timestamp for display"

  # Test 4: Uses AskUserQuestion with formatted timestamp
  assert_file_contains "$COMMAND_FILE" "Cache is fresh (last updated: \${formatted_timestamp})" \
    "Step 1.5 shows formatted timestamp in fresh cache prompt"

  # Test 5: Offers three options with correct text
  assert_file_contains "$COMMAND_FILE" "[Use cache (Recommended) / Re-analyze anyway / Cancel]" \
    "Step 1.5 offers correct options for fresh cache"

  # Test 6: Use cache is marked as recommended
  assert_file_contains_regex "$COMMAND_FILE" 'Recommended option: "Use cache \(Recommended\)".*auto-selected' \
    "Step 1.5 marks Use cache as recommended for fresh cache"

  # Test 7: Use cache choice loads cache
  assert_file_contains_regex "$COMMAND_FILE" 'If "Use cache \(Recommended\)".*load cached data' \
    "Step 1.5 loads cache when Use cache is selected"

  # Test 8: Use cache skips agents
  assert_file_contains_regex "$COMMAND_FILE" 'Use cache.*skip agents' \
    "Step 1.5 skips agents when using fresh cache"

  # Test 9: Shows confirmation with timestamp
  assert_file_contains "$COMMAND_FILE" "Using cached analysis from [formatted_timestamp]" \
    "Step 1.5 shows formatted timestamp when using fresh cache"

  # Test 10: Shows cache summary
  assert_file_contains "$COMMAND_FILE" "Cache contains: N flows, M patterns, P step definitions" \
    "Step 1.5 shows cache summary when using fresh cache"

  # Test 11: Re-analyze anyway runs agents
  assert_file_contains_regex "$COMMAND_FILE" 'If "Re-analyze anyway".*continue to Step 2.*run all agents' \
    "Step 1.5 runs all agents when Re-analyze anyway is selected"

  # Test 12: Cancel exits workflow
  assert_file_contains_regex "$COMMAND_FILE" 'If "Cancel".*exit workflow.*"Workflow cancelled\."' \
    "Step 1.5 exits workflow when Cancel is selected for fresh cache"
}

test_workflow_branching() {
  echo ""
  echo "=== Testing workflow branching logic ==="

  # Test 1: Sets using_cache flag when loading cache
  assert_file_contains_regex "$COMMAND_FILE" "using_cache = true" \
    "Step 1.5 sets using_cache flag"

  # Test 2: Step 2 checks using_cache flag
  assert_file_contains_regex "$COMMAND_FILE" "Step 2.*if.*using_cache == true.*skip" \
    "Step 2 checks using_cache flag and skips context-gatherer"

  # Test 3: Step 2.25 checks using_cache flag
  assert_file_contains_regex "$COMMAND_FILE" "Step 2.25.*if.*using_cache == true.*skip" \
    "Step 2.25 checks using_cache flag and skips flow-analyzer"

  # Test 4: Step 2.5 checks using_cache flag
  assert_file_contains_regex "$COMMAND_FILE" "Step 2.5.*if.*using_cache == true.*skip" \
    "Step 2.5 checks using_cache flag and skips pattern-detector"

  # Test 5: Step 3 checks using_cache flag
  assert_file_contains_regex "$COMMAND_FILE" "Step 3.*if.*using_cache == true.*skip" \
    "Step 3 checks using_cache flag and skips step-matcher"

  # Test 6: Loads cached context instead of running agent
  assert_file_contains_regex "$COMMAND_FILE" "using_cache == true.*load cached context" \
    "Workflow loads cached context when using cache"

  # Test 7: Loads cached flow catalog
  assert_file_contains_regex "$COMMAND_FILE" "using_cache == true.*load cached flow catalog" \
    "Workflow loads cached flow catalog when using cache"

  # Test 8: Loads cached pattern selections
  assert_file_contains_regex "$COMMAND_FILE" "using_cache == true.*load cached pattern.*selections" \
    "Workflow loads cached pattern selections when using cache"

  # Test 9: Loads cached steps catalog
  assert_file_contains_regex "$COMMAND_FILE" "using_cache == true.*load cached steps catalog" \
    "Workflow loads cached steps catalog when using cache"

  # Test 10: Continues to Step 4 after loading cache
  assert_file_contains "$COMMAND_FILE" "Continue to Step 4 with cached data" \
    "Workflow continues to Step 4 after loading cache"
}

test_cache_write_logic() {
  echo ""
  echo "=== Testing cache write logic ==="

  # Test 1: Only writes cache after all agents complete
  assert_file_contains "$COMMAND_FILE" "Only write cache if ALL agents complete successfully" \
    "Step 1.5 only writes cache after all agents succeed"

  # Test 2: Lists all required agents
  assert_file_contains "$COMMAND_FILE" "context-gatherer, flow-analyzer, pattern-detector, step-matcher" \
    "Step 1.5 documents all required agents"

  # Test 3: Does not write cache if any agent fails
  assert_file_contains "$COMMAND_FILE" "If any agent fails: do NOT write cache" \
    "Step 1.5 does not write cache on agent failure"

  # Test 4: Writes cache after Step 3 completes
  assert_file_contains_regex "$COMMAND_FILE" "Write cache only after Step 3.*completes successfully" \
    "Step 1.5 writes cache after Step 3 completion"

  # Test 5: Gathers data from all agent results
  assert_file_contains "$COMMAND_FILE" "Flow count from flow-analyzer result" \
    "Step 1.5 gathers flow count from agent results"

  assert_file_contains "$COMMAND_FILE" "Pattern count from pattern-detector result" \
    "Step 1.5 gathers pattern count from agent results"

  assert_file_contains "$COMMAND_FILE" "Step count from step-matcher result" \
    "Step 1.5 gathers step count from agent results"

  # Test 6: Passes all required fields to cache-writer.sh
  assert_file_contains_regex "$COMMAND_FILE" "cache-writer.sh write.*--flows.*--patterns.*--steps" \
    "Step 1.5 passes count fields to cache-writer"

  assert_file_contains_regex "$COMMAND_FILE" "cache-writer.sh write.*--feature-files.*--step-files" \
    "Step 1.5 passes file count fields to cache-writer"

  assert_file_contains_regex "$COMMAND_FILE" "cache-writer.sh write.*--context.*--flow-catalog.*--pattern-catalog.*--steps-catalog" \
    "Step 1.5 passes catalog fields to cache-writer"

  # Test 7: Shows confirmation message after write
  assert_file_contains "$COMMAND_FILE" "Show confirmation: \"Cache updated with latest analysis\"" \
    "Step 1.5 shows confirmation after cache write"
}

test_cache_read_logic() {
  echo ""
  echo "=== Testing cache read logic ==="

  # Test 1: Uses cache-reader.sh get command
  assert_file_contains "$COMMAND_FILE" "cached_data=\$(bash bee/scripts/cache-reader.sh get)" \
    "Step 1.5 uses cache-reader.sh get to read cache"

  # Test 2: Parses Summary section for counts
  assert_file_contains_regex "$COMMAND_FILE" "Parse Summary section.*counts" \
    "Step 1.5 parses Summary section for counts"

  # Test 3: Stores cached context in workflow state
  assert_file_contains_regex "$COMMAND_FILE" "Store cached context.*workflow state" \
    "Step 1.5 stores cached context"

  # Test 4: Stores flow analysis in workflow state
  assert_file_contains_regex "$COMMAND_FILE" "Store.*flow analysis.*workflow state" \
    "Step 1.5 stores cached flow analysis"

  # Test 5: Stores pattern selections in workflow state
  assert_file_contains_regex "$COMMAND_FILE" "Store.*pattern selections.*workflow state" \
    "Step 1.5 stores cached pattern selections"

  # Test 6: Stores step index in workflow state
  assert_file_contains_regex "$COMMAND_FILE" "Store.*step index.*workflow state" \
    "Step 1.5 stores cached step index"
}

test_confirmation_messages() {
  echo ""
  echo "=== Testing confirmation messages ==="

  # Test 1: Missing cache message
  assert_file_contains "$COMMAND_FILE" "No cache found. Running initial analysis..." \
    "Missing cache message matches spec"

  # Test 2: Cache write confirmation
  assert_file_contains "$COMMAND_FILE" "Cache updated with latest analysis" \
    "Cache write confirmation matches spec"

  # Test 3: Using cache message includes timestamp
  assert_file_contains_regex "$COMMAND_FILE" "Using cached analysis from.*timestamp" \
    "Using cache message includes timestamp"

  # Test 4: Using cache message includes summary
  assert_file_contains "$COMMAND_FILE" "Cache contains: N flows, M patterns, P step definitions" \
    "Using cache message includes summary counts"

  # Test 5: Workflow cancelled message
  assert_file_contains "$COMMAND_FILE" "Workflow cancelled." \
    "Cancel message matches spec"

  # Test 6: Corrupt cache exit message
  assert_file_contains "$COMMAND_FILE" "Workflow cancelled. Fix or delete docs/playwright-init.md to proceed." \
    "Corrupt cache cancel message includes helpful guidance"
}

test_zero_files_handling() {
  echo ""
  echo "=== Testing zero files handling (Slice 3) ==="

  local step_content
  step_content=$(extract_step_section "$COMMAND_FILE" "Step 1.5: Cache Check and Invalidation")

  # Test 1: Checks for zero files scenario within missing cache state
  assert_file_contains "$COMMAND_FILE" "Check for zero files scenario:" \
    "Step 1.5 checks for zero files scenario when cache is missing"

  # Test 2: Checks both feature and step file counts are zero
  assert_file_contains "$COMMAND_FILE" "current_feature_count == 0" \
    "Step 1.5 checks feature count is zero"

  assert_file_contains "$COMMAND_FILE" "current_step_count == 0" \
    "Step 1.5 checks step count is zero"

  # Test 3: Shows correct message for zero files
  assert_file_contains "$COMMAND_FILE" "Repository has zero feature files and zero step files. Creating empty cache." \
    "Step 1.5 shows correct message for zero files scenario"

  # Test 4: Invokes cache-writer.sh with --empty flag
  assert_file_contains "$COMMAND_FILE" "bash bee/scripts/cache-writer.sh write --empty" \
    "Step 1.5 invokes cache-writer.sh with --empty flag"

  # Test 5: Shows confirmation after empty cache creation
  assert_file_contains "$COMMAND_FILE" "Empty cache created with warning note. Cache will be invalidated when files are added." \
    "Step 1.5 shows confirmation after empty cache creation"

  # Test 6: Exits workflow after empty cache creation
  assert_file_contains "$COMMAND_FILE" "No feature files to process. Add feature files and re-run /bee:playwright-bdd" \
    "Step 1.5 exits workflow after empty cache creation"

  # Test 7: Zero files is handled BEFORE running agents (exit happens in zero files scenario)
  assert_file_contains "$COMMAND_FILE" "Exit workflow with message" \
    "Step 1.5 exits before running agents in zero files scenario"

  # Test 8: Non-zero files continue to normal flow
  assert_file_contains "$COMMAND_FILE" "Otherwise:" \
    "Step 1.5 has otherwise branch for non-zero files"

  assert_file_contains "$COMMAND_FILE" "No cache found. Running initial analysis..." \
    "Step 1.5 continues to normal flow for non-zero files"
}

test_partial_cache_workflow_handling() {
  echo ""
  echo "=== Testing partial cache workflow handling (Slice 3) ==="

  # Test 1: Mentions partial cache detection in Step 1.5
  assert_file_contains "$COMMAND_FILE" "Partial cache (missing expected sections) is detected by cache-reader.sh" \
    "Step 1.5 documents partial cache detection"

  # Test 2: Partial cache returned as missing status
  assert_file_contains "$COMMAND_FILE" "returned as \`missing\` status" \
    "Step 1.5 documents that partial cache returns missing status"

  # Test 3: Partial cache note is in check cache status section
  assert_file_contains "$COMMAND_FILE" "Script returns one of: \`missing\`, \`fresh\`, \`stale\`, \`corrupt\`" \
    "Step 1.5 check cache status section includes all statuses"

  # Test 4: Partial cache comment explains the detection
  assert_file_contains "$COMMAND_FILE" "Note: Partial cache (missing expected sections) is detected by cache-reader.sh and returned as \`missing\` status" \
    "Step 1.5 has explanatory note about partial cache detection"

  # Test 5: When partial cache detected (returns missing), workflow runs full analysis
  # This is implicit - if cache-reader.sh returns "missing", it follows missing cache path
  assert_file_contains "$COMMAND_FILE" "No cache found. Running initial analysis..." \
    "Step 1.5 treats partial cache (missing status) as missing cache and runs full analysis"

  # Test 6: Missing cache path includes running all 4 agents
  assert_file_contains "$COMMAND_FILE" "Continue to Step 2 (all 4 agents will run)" \
    "Step 1.5 runs all 4 agents when cache is missing (includes partial cache case)"
}

test_gap_suggestions_approval_format() {
  echo ""
  echo "=== Testing gap suggestions approval file format (Slice 6) ==="

  # Test 1: Gap detected decision type exists in Step 5
  assert_file_contains "$COMMAND_FILE" 'When decision is "gap_detected"' \
    "Step 5 has gap_detected decision type"

  # Test 2: Gap status message is shown
  assert_file_contains "$COMMAND_FILE" "**Status:** Gap detected (no existing matches found)" \
    "Gap status message matches spec"

  # Test 3: Suggested Step Definitions section header exists
  assert_file_contains "$COMMAND_FILE" "**Suggested Step Definitions:**" \
    "Gap suggestions section header exists"

  # Test 4: Section includes introductory text
  assert_file_contains "$COMMAND_FILE" "Based on your codebase patterns, here are recommended implementations:" \
    "Gap suggestions section includes introductory text"

  # Test 5: Suggestion format includes score
  assert_file_contains_regex "$COMMAND_FILE" "### Suggestion [0-9]+ \(Score: \[score\]\)" \
    "Each suggestion includes score in header"

  # Test 6: Suggestion format includes step definition code block
  assert_file_contains "$COMMAND_FILE" "**Step Definition:**" \
    "Each suggestion includes step definition section"

  # Test 7: Step definition is in code block
  assert_file_contains "$COMMAND_FILE" '```typescript' \
    "Step definition is in typescript code block"

  # Test 8: Suggestion includes source attribution
  assert_file_contains "$COMMAND_FILE" "**Source:** [pattern catalog / flow catalog / existing steps]" \
    "Each suggestion includes source attribution"

  # Test 9: Suggestion includes target file location
  assert_file_contains "$COMMAND_FILE" "**Target File:**" \
    "Each suggestion includes target file location"

  # Test 10: Target file indicates if new or existing
  assert_file_contains_regex "$COMMAND_FILE" '\[createNew \? "new file" : "add to existing"\]' \
    "Target file indicates if new or existing"
}

test_gap_suggestions_conditional_metadata() {
  echo ""
  echo "=== Testing gap suggestions conditional metadata (Slice 6) ==="

  # Test 1: Pattern catalog metadata is conditional
  assert_file_contains "$COMMAND_FILE" "[If pattern_catalog: **Pattern Type:** [metadata.patternType]]" \
    "Pattern Type metadata is conditional on pattern_catalog source"

  # Test 2: Flow catalog metadata is conditional
  assert_file_contains "$COMMAND_FILE" "[If flow_catalog: **Flow Stage:** [metadata.flowStage]]" \
    "Flow Stage metadata is conditional on flow_catalog source"

  # Test 3: Existing steps metadata is conditional
  assert_file_contains "$COMMAND_FILE" "[If existing_steps: **Related Step:** \`[metadata.relatedStep]\` ([metadata.relationshipType])]" \
    "Related Step metadata is conditional on existing_steps source"

  # Test 4: All three conditional metadata types exist
  # Check each exists independently since they're on separate lines
  assert_file_contains "$COMMAND_FILE" "[If pattern_catalog:" \
    "Pattern catalog conditional exists"

  assert_file_contains "$COMMAND_FILE" "[If flow_catalog:" \
    "Flow catalog conditional exists"

  assert_file_contains "$COMMAND_FILE" "[If existing_steps:" \
    "Existing steps conditional exists"
}

test_gap_suggestions_decision_format() {
  echo ""
  echo "=== Testing gap suggestions decision format (Slice 6) ==="

  # Test 1: Decision section exists for gaps
  assert_file_contains "$COMMAND_FILE" "**Decision:**" \
    "Gap suggestions include Decision section"

  # Test 2: Use suggestion options are present
  assert_file_contains "$COMMAND_FILE" "- [ ] Use suggestion #1" \
    "Gap decision includes Use suggestion #1 option"

  # Test 3: Multiple suggestion options shown
  assert_file_contains "$COMMAND_FILE" "- [ ] Use suggestion #2" \
    "Gap decision includes Use suggestion #2 option"

  # Test 4: Create custom option exists
  assert_file_contains "$COMMAND_FILE" "Create custom step definition" \
    "Gap decision includes create custom option"

  # Test 5: Comment about repeating structure
  assert_file_contains "$COMMAND_FILE" "[... repeat structure for each suggestion, up to 5 ...]" \
    "Gap suggestions format notes structure repeats for each suggestion"

  # Test 6: Comment about one option per suggestion
  assert_file_contains "$COMMAND_FILE" "[... one option per suggestion ...]" \
    "Gap decision notes one option per suggestion"

  # Test 7: Note about one choice allowed
  assert_file_contains "$COMMAND_FILE" "**Note:** Only one choice allowed per step." \
    "Gap decision includes note about one choice per step"
}

test_gap_suggestions_grouping() {
  echo ""
  echo "=== Testing gap suggestions grouping (Slice 6) ==="

  # Test 1: Each gap has its own step section
  assert_file_contains "$COMMAND_FILE" '## Step: "[step text]"' \
    "Each gap has its own step section"

  # Test 2: Suggestions are grouped under the step
  assert_file_contains "$COMMAND_FILE" "### Suggestion 1 (Score: [score])" \
    "Suggestions are grouped under the step section"

  # Test 3: Multiple suggestions per gap supported
  assert_file_contains "$COMMAND_FILE" "### Suggestion 2 (Score: [score])" \
    "Multiple suggestions per gap are supported"

  # Test 4: Up to 5 suggestions mentioned
  assert_file_contains "$COMMAND_FILE" "up to 5" \
    "Format documents up to 5 suggestions"
}

test_gap_suggestions_no_bulk_creation() {
  echo ""
  echo "=== Testing gap suggestions require one-by-one approval (Slice 6) ==="

  # Test 1: Each suggestion has individual checkbox
  assert_file_contains "$COMMAND_FILE" "- [ ] Use suggestion #1" \
    "Suggestion #1 has individual checkbox"

  assert_file_contains "$COMMAND_FILE" "- [ ] Use suggestion #2" \
    "Suggestion #2 has individual checkbox"

  # Test 2: Only one choice allowed note exists
  assert_file_contains "$COMMAND_FILE" "**Note:** Only one choice allowed per step." \
    "Note confirms one-by-one approval"

  # Test 3: No bulk action mentioned in gap_detected section
  local gap_section
  gap_section=$(sed -n '/When decision is "gap_detected"/,/When decision is "no_matches"/p' "$COMMAND_FILE")

  if ! echo "$gap_section" | grep -Eqi "bulk|create all|batch"; then
    echo -e "${GREEN}PASS${NC} - No bulk creation action in gap_detected section"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}FAIL${NC} - Bulk creation mentioned in gap_detected section"
    echo "  Gap section should not mention bulk/all/batch actions"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))

  # Test 4: Decision validation requires one choice per step
  assert_file_contains "$COMMAND_FILE" "exactly one box checked per step" \
    "Validation requires exactly one choice per step"
}

test_gap_suggestions_vs_candidates() {
  echo ""
  echo "=== Testing gap_detected differs from candidates_found (Slice 6) ==="

  # Test 1: candidates_found section still exists
  assert_file_contains "$COMMAND_FILE" 'When decision is "candidates_found"' \
    "candidates_found decision type still exists"

  # Test 2: candidates_found has different format than gap_detected
  assert_file_contains "$COMMAND_FILE" "Candidates:" \
    "candidates_found uses Candidates section"

  assert_file_contains "$COMMAND_FILE" "**Suggested Step Definitions:**" \
    "gap_detected uses Suggested Step Definitions section"

  # Test 3: candidates_found shows confidence and usage
  assert_file_contains "$COMMAND_FILE" "confidence" \
    "candidates_found shows confidence"

  assert_file_contains "$COMMAND_FILE" "Used in:" \
    "candidates_found shows usage"

  # Test 4: gap_detected shows source and target file
  assert_file_contains "$COMMAND_FILE" "**Source:**" \
    "gap_detected shows source"

  assert_file_contains "$COMMAND_FILE" "**Target File:**" \
    "gap_detected shows target file"

  # Test 5: candidates_found has reuse/create options
  assert_file_contains "$COMMAND_FILE" "- [ ] Reuse candidate #1" \
    "candidates_found has reuse option"

  # Test 6: gap_detected has use suggestion/create custom options
  assert_file_contains "$COMMAND_FILE" "- [ ] Use suggestion #1" \
    "gap_detected has use suggestion option"

  assert_file_contains "$COMMAND_FILE" "Create custom step definition" \
    "gap_detected has create custom option"
}

test_gap_suggestions_approval_file_header() {
  echo ""
  echo "=== Testing approval file header mentions gap suggestions (Slice 6) ==="

  # Test 1: Approval file header includes gap suggestions instruction
  assert_file_contains "$COMMAND_FILE" "For gaps with suggestions: choose a suggestion OR create custom implementation" \
    "Approval file header includes gap suggestions instruction"

  # Test 2: Header instructions mention all three decision types
  assert_file_contains "$COMMAND_FILE" "For steps with candidates" \
    "Header mentions candidates"

  assert_file_contains "$COMMAND_FILE" "For gaps with suggestions" \
    "Header mentions gaps with suggestions"

  assert_file_contains "$COMMAND_FILE" "For steps with no matches" \
    "Header mentions steps with no matches"

  # Test 3: Instructions are in correct order (candidates, gaps, no matches)
  local header_section
  header_section=$(sed -n '/# Playwright-BDD Approval/,/---/p' "$COMMAND_FILE")

  local candidates_line
  candidates_line=$(echo "$header_section" | grep -n "For steps with candidates" | cut -d: -f1)
  local gaps_line
  gaps_line=$(echo "$header_section" | grep -n "For gaps with suggestions" | cut -d: -f1)
  local no_matches_line
  no_matches_line=$(echo "$header_section" | grep -n "For steps with no matches" | cut -d: -f1)

  if [[ -n "$candidates_line" && -n "$gaps_line" && -n "$no_matches_line" && \
        "$candidates_line" -lt "$gaps_line" && "$gaps_line" -lt "$no_matches_line" ]]; then
    echo -e "${GREEN}PASS${NC} - Instructions are in correct order"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}FAIL${NC} - Instructions order is incorrect"
    echo "  Expected: candidates < gaps < no_matches"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_gap_suggestions_step_6_parsing() {
  echo ""
  echo "=== Testing Step 6 parses gap suggestion decisions (Slice 6) ==="

  # Test 1: Step 6 handles Use suggestion decision
  assert_file_contains "$COMMAND_FILE" "**Use suggestion #N**: store suggestion index, step definition text, and target file location from gapMetadata" \
    "Step 6 parses Use suggestion decision"

  # Test 2: Step 6 handles Create custom decision
  assert_file_contains "$COMMAND_FILE" "**Create custom**: flag as new step creation (gap detected but custom implementation chosen)" \
    "Step 6 parses Create custom decision"

  # Test 3: Step 6 stores suggestion index
  assert_file_contains "$COMMAND_FILE" "store suggestion index" \
    "Step 6 stores suggestion index"

  # Test 4: Step 6 stores step definition text from suggestion
  assert_file_contains "$COMMAND_FILE" "step definition text" \
    "Step 6 stores step definition text from suggestion"

  # Test 5: Step 6 stores target file location
  assert_file_contains "$COMMAND_FILE" "target file location from gapMetadata" \
    "Step 6 stores target file location from gapMetadata"

  # Test 6: Create custom is distinguished from Use suggestion
  assert_file_contains "$COMMAND_FILE" "gap detected but custom implementation chosen" \
    "Create custom is distinguished from Use suggestion"
}

# --- Main Execution ---

echo "========================================"
echo "Workflow Integration Test Suite"
echo "========================================"
echo "Testing: Slice 2 (Step 1.5 Cache Check)"
echo "         Slice 6 (Gap Suggestion Approval)"
echo ""

# Check if command file exists
if [[ ! -f "$COMMAND_FILE" ]]; then
  echo -e "${RED}ERROR${NC}: Command file not found: $COMMAND_FILE"
  exit 1
fi

test_step_1_5_exists
test_cache_check_logic
test_cache_missing_state
test_cache_corrupt_state
test_cache_stale_state
test_cache_fresh_state
test_workflow_branching
test_cache_write_logic
test_cache_read_logic
test_confirmation_messages
test_zero_files_handling
test_partial_cache_workflow_handling
test_gap_suggestions_approval_format
test_gap_suggestions_conditional_metadata
test_gap_suggestions_decision_format
test_gap_suggestions_grouping
test_gap_suggestions_no_bulk_creation
test_gap_suggestions_vs_candidates
test_gap_suggestions_approval_file_header
test_gap_suggestions_step_6_parsing

echo ""
echo "========================================"
echo "Test Summary"
echo "========================================"
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo "========================================"

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed.${NC}"
  exit 1
fi
