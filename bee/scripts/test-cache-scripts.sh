#!/usr/bin/env bash
set -eo pipefail

# test-cache-scripts.sh — Test suite for cache-writer.sh and cache-reader.sh
#
# Tests all acceptance criteria from Slice 1:
# - Cache file creation with all required fields
# - Cache reading and parsing
# - Cache validation (missing, corrupt, fresh, stale)
# - File count metadata tracking
# - Multi-line field encoding

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

# Test temp directory
TEST_DIR="$PROJECT_ROOT/.test-cache-tmp"
TEST_CACHE_FILE="$TEST_DIR/docs/playwright-init.md"

# --- Test Helpers ---

setup() {
  rm -rf "$TEST_DIR"
  mkdir -p "$TEST_DIR"
  cd "$TEST_DIR"
}

teardown() {
  cd "$PROJECT_ROOT"
  rm -rf "$TEST_DIR"
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$expected" == "$actual" ]]; then
    echo -e "${GREEN}PASS${NC} - $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}FAIL${NC} - $test_name"
    echo "  Expected: '$expected'"
    echo "  Actual:   '$actual'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_file_exists() {
  local file="$1"
  local test_name="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ -f "$file" ]]; then
    echo -e "${GREEN}PASS${NC} - $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}FAIL${NC} - $test_name"
    echo "  File not found: $file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_file_not_exists() {
  local file="$1"
  local test_name="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ ! -f "$file" ]]; then
    echo -e "${GREEN}PASS${NC} - $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}FAIL${NC} - $test_name"
    echo "  File should not exist: $file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$haystack" == *"$needle"* ]]; then
    echo -e "${GREEN}PASS${NC} - $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}FAIL${NC} - $test_name"
    echo "  Expected to contain: '$needle'"
    echo "  Actual: '$haystack'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_matches() {
  local text="$1"
  local pattern="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if echo "$text" | grep -qE "$pattern"; then
    echo -e "${GREEN}PASS${NC} - $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}FAIL${NC} - $test_name"
    echo "  Expected to match pattern: '$pattern'"
    echo "  Actual: '$text'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# --- Test Suites ---

test_cache_writer_basic() {
  echo ""
  echo "=== Testing cache-writer.sh basic functionality ==="

  setup

  # Test 1: Write cache with minimal fields
  bash "$SCRIPT_DIR/cache-writer.sh" write \
    --flows "5" \
    --patterns "3" \
    --steps "20" \
    --feature-files "10" \
    --step-files "6" \
    > /dev/null

  assert_file_exists "$TEST_CACHE_FILE" "cache file created"

  # Test 2: Cache has valid YAML frontmatter
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$TEST_CACHE_FILE")

  assert_contains "$frontmatter" "last_updated:" "frontmatter contains last_updated"
  assert_contains "$frontmatter" "feature_file_count: 10" "frontmatter contains feature_file_count"
  assert_contains "$frontmatter" "step_file_count: 6" "frontmatter contains step_file_count"

  # Test 3: Cache has required sections
  local content
  content=$(cat "$TEST_CACHE_FILE")

  assert_contains "$content" "# Playwright-BDD Initialization Cache" "cache has title"
  assert_contains "$content" "## Summary" "cache has Summary section"
  assert_contains "$content" "## Context Summary" "cache has Context Summary section"
  assert_contains "$content" "## Flow Catalog" "cache has Flow Catalog section"
  assert_contains "$content" "## Pattern Catalog" "cache has Pattern Catalog section"
  assert_contains "$content" "## Steps Catalog" "cache has Steps Catalog section"

  # Test 4: Summary shows correct counts
  assert_contains "$content" "- Flows: 5" "summary shows flows count"
  assert_contains "$content" "- Patterns: 3" "summary shows patterns count"
  assert_contains "$content" "- Step Definitions: 20" "summary shows steps count"

  # Test 5: Timestamp is in ISO format
  local timestamp
  timestamp=$(sed -n '/^---$/,/^---$/p' "$TEST_CACHE_FILE" | grep "last_updated:" | sed 's/last_updated: "\(.*\)"/\1/')

  assert_matches "$timestamp" "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$" "timestamp is ISO 8601 format"

  teardown
}

test_cache_writer_multiline() {
  echo ""
  echo "=== Testing cache-writer.sh multi-line field encoding ==="

  setup

  # Test with multi-line fields using | separator
  bash "$SCRIPT_DIR/cache-writer.sh" write \
    --flows "2" \
    --patterns "1" \
    --steps "5" \
    --feature-files "3" \
    --step-files "2" \
    --context "Line 1|Line 2|Line 3" \
    --flow-catalog "Flow A|Flow B" \
    --pattern-catalog "Pattern X" \
    --steps-catalog "Step 1|Step 2|Step 3|Step 4" \
    > /dev/null

  local content
  content=$(cat "$TEST_CACHE_FILE")

  # Extract Context Summary section
  local context_section
  context_section=$(sed -n '/^## Context Summary$/,/^## /p' "$TEST_CACHE_FILE" | sed '1d;$d')

  assert_contains "$context_section" "Line 1" "context has line 1"
  assert_contains "$context_section" "Line 2" "context has line 2"
  assert_contains "$context_section" "Line 3" "context has line 3"

  # Extract Flow Catalog section
  local flow_section
  flow_section=$(sed -n '/^## Flow Catalog$/,/^## /p' "$TEST_CACHE_FILE" | sed '1d;$d')

  assert_contains "$flow_section" "Flow A" "flow catalog has Flow A"
  assert_contains "$flow_section" "Flow B" "flow catalog has Flow B"

  # Extract Steps Catalog section (last section, no closing ##)
  local steps_section
  steps_section=$(sed -n '/^## Steps Catalog$/,$p' "$TEST_CACHE_FILE" | sed '1d')

  assert_contains "$steps_section" "Step 1" "steps catalog has Step 1"
  assert_contains "$steps_section" "Step 2" "steps catalog has Step 2"
  assert_contains "$steps_section" "Step 3" "steps catalog has Step 3"
  assert_contains "$steps_section" "Step 4" "steps catalog has Step 4"

  teardown
}

test_cache_writer_defaults() {
  echo ""
  echo "=== Testing cache-writer.sh default values ==="

  setup

  # Write cache with only required fields (optional fields should default to "n/a")
  bash "$SCRIPT_DIR/cache-writer.sh" write \
    --flows "1" \
    --patterns "1" \
    --steps "1" \
    --feature-files "1" \
    --step-files "1" \
    > /dev/null

  local content
  content=$(cat "$TEST_CACHE_FILE")

  # Default values should be "n/a" for unspecified catalog fields
  assert_contains "$content" "n/a" "cache contains default n/a values"

  teardown
}

test_cache_writer_validation() {
  echo ""
  echo "=== Testing cache-writer.sh validation ==="

  setup

  # Test: Cache writer accepts partial arguments (uses defaults for missing fields)
  # This is intentional - allows creating empty/minimal caches
  bash "$SCRIPT_DIR/cache-writer.sh" write --flows "1" --patterns "1" > /dev/null

  assert_file_exists "$TEST_CACHE_FILE" "cache created with partial arguments uses defaults"

  local content
  content=$(cat "$TEST_CACHE_FILE")

  # Verify defaults were applied for missing fields
  assert_contains "$content" "Step Definitions: 0" "missing steps field defaults to 0"
  assert_contains "$content" "feature_file_count: 0" "missing feature-files field defaults to 0"

  teardown
}

test_cache_writer_clear() {
  echo ""
  echo "=== Testing cache-writer.sh clear command ==="

  setup

  # Create a cache file
  bash "$SCRIPT_DIR/cache-writer.sh" write \
    --flows "1" \
    --patterns "1" \
    --steps "1" \
    --feature-files "1" \
    --step-files "1" \
    > /dev/null

  assert_file_exists "$TEST_CACHE_FILE" "cache file created before clear"

  # Clear the cache
  bash "$SCRIPT_DIR/cache-writer.sh" clear > /dev/null

  assert_file_not_exists "$TEST_CACHE_FILE" "cache file removed after clear"

  teardown
}

test_cache_reader_check() {
  echo ""
  echo "=== Testing cache-reader.sh check command ==="

  setup

  # Test 1: Check when cache is missing
  local status
  status=$(bash "$SCRIPT_DIR/cache-reader.sh" check)

  assert_equals "missing" "$status" "check returns 'missing' when cache doesn't exist"

  # Test 2: Create a valid cache
  bash "$SCRIPT_DIR/cache-writer.sh" write \
    --flows "5" \
    --patterns "3" \
    --steps "10" \
    --feature-files "8" \
    --step-files "4" \
    > /dev/null

  status=$(bash "$SCRIPT_DIR/cache-reader.sh" check)

  assert_equals "fresh" "$status" "check returns 'fresh' when cache is valid"

  # Test 3: Corrupt cache (missing frontmatter)
  echo "# Invalid Cache" > "$TEST_CACHE_FILE"

  status=$(bash "$SCRIPT_DIR/cache-reader.sh" check)

  assert_equals "corrupt" "$status" "check returns 'corrupt' when frontmatter is missing"

  # Test 4: Partial cache (missing required sections) - returns 'missing' as of Slice 3
  cat > "$TEST_CACHE_FILE" <<EOF
---
last_updated: "2026-03-10T12:00:00Z"
feature_file_count: 5
step_file_count: 3
---

# Playwright-BDD Initialization Cache

## Summary
- Flows: 1
EOF

  status=$(bash "$SCRIPT_DIR/cache-reader.sh" check)

  assert_equals "missing" "$status" "check returns 'missing' when sections are missing (partial cache detection)"

  teardown
}

test_cache_reader_validate() {
  echo ""
  echo "=== Testing cache-reader.sh validate command (staleness detection) ==="

  setup

  # Create a cache with specific file counts
  bash "$SCRIPT_DIR/cache-writer.sh" write \
    --flows "5" \
    --patterns "3" \
    --steps "10" \
    --feature-files "10" \
    --step-files "5" \
    > /dev/null

  # Test 1: Fresh cache (counts within ±1)
  local status
  status=$(bash "$SCRIPT_DIR/cache-reader.sh" validate 10 5)

  assert_equals "fresh" "$status" "validate returns 'fresh' when counts match exactly"

  status=$(bash "$SCRIPT_DIR/cache-reader.sh" validate 11 5)

  assert_equals "fresh" "$status" "validate returns 'fresh' when feature count is +1"

  status=$(bash "$SCRIPT_DIR/cache-reader.sh" validate 10 6)

  assert_equals "fresh" "$status" "validate returns 'fresh' when step count is +1"

  status=$(bash "$SCRIPT_DIR/cache-reader.sh" validate 9 4)

  assert_equals "fresh" "$status" "validate returns 'fresh' when both counts are -1"

  # Test 2: Stale cache (feature count changed by ±2 or more)
  status=$(bash "$SCRIPT_DIR/cache-reader.sh" validate 12 5)

  assert_equals "stale" "$status" "validate returns 'stale' when feature count is +2"

  status=$(bash "$SCRIPT_DIR/cache-reader.sh" validate 8 5)

  assert_equals "stale" "$status" "validate returns 'stale' when feature count is -2"

  # Test 3: Stale cache (step count changed by ±2 or more)
  status=$(bash "$SCRIPT_DIR/cache-reader.sh" validate 10 7)

  assert_equals "stale" "$status" "validate returns 'stale' when step count is +2"

  status=$(bash "$SCRIPT_DIR/cache-reader.sh" validate 10 3)

  assert_equals "stale" "$status" "validate returns 'stale' when step count is -2"

  # Test 4: Stale cache (both counts changed but only one by ±2)
  status=$(bash "$SCRIPT_DIR/cache-reader.sh" validate 12 6)

  assert_equals "stale" "$status" "validate returns 'stale' when one count is +2 even if other is +1"

  teardown
}

test_cache_reader_get() {
  echo ""
  echo "=== Testing cache-reader.sh get command ==="

  setup

  # Create a cache
  bash "$SCRIPT_DIR/cache-writer.sh" write \
    --flows "7" \
    --patterns "4" \
    --steps "25" \
    --feature-files "12" \
    --step-files "8" \
    --context "Test context" \
    > /dev/null

  # Test 1: Get full content
  local content
  content=$(bash "$SCRIPT_DIR/cache-reader.sh" get)

  assert_contains "$content" "Playwright-BDD Initialization Cache" "get returns full cache content"
  assert_contains "$content" "Flows: 7" "get includes summary with correct counts"

  # Test 2: Get specific field
  local last_updated
  last_updated=$(bash "$SCRIPT_DIR/cache-reader.sh" get --field last_updated)

  assert_matches "$last_updated" "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$" "get --field last_updated returns ISO timestamp"

  local feature_count
  feature_count=$(bash "$SCRIPT_DIR/cache-reader.sh" get --field feature_file_count)

  assert_equals "12" "$feature_count" "get --field feature_file_count returns correct value"

  local step_count
  step_count=$(bash "$SCRIPT_DIR/cache-reader.sh" get --field step_file_count)

  assert_equals "8" "$step_count" "get --field step_file_count returns correct value"

  # Test 3: Error when cache doesn't exist
  rm -f "$TEST_CACHE_FILE"

  local result
  result=$(bash "$SCRIPT_DIR/cache-reader.sh" get 2>&1 || true)

  assert_contains "$result" "Error" "get shows error when cache file not found"

  teardown
}

test_integration_write_read_cycle() {
  echo ""
  echo "=== Testing integration: full write-read cycle ==="

  setup

  # Write a cache with all fields
  bash "$SCRIPT_DIR/cache-writer.sh" write \
    --flows "15" \
    --patterns "8" \
    --steps "42" \
    --feature-files "20" \
    --step-files "12" \
    --context "Multi-line|Context|Summary" \
    --flow-catalog "Flow 1|Flow 2|Flow 3" \
    --pattern-catalog "Pattern A|Pattern B" \
    --steps-catalog "Given step|When step|Then step" \
    > /dev/null

  # Verify cache status
  local status
  status=$(bash "$SCRIPT_DIR/cache-reader.sh" check)

  assert_equals "fresh" "$status" "full cache is reported as fresh"

  # Validate staleness with matching counts
  status=$(bash "$SCRIPT_DIR/cache-reader.sh" validate 20 12)

  assert_equals "fresh" "$status" "full cache validates as fresh with matching counts"

  # Read back the content
  local content
  content=$(bash "$SCRIPT_DIR/cache-reader.sh" get)

  assert_contains "$content" "Flows: 15" "read cycle returns correct flow count"
  assert_contains "$content" "Patterns: 8" "read cycle returns correct pattern count"
  assert_contains "$content" "Step Definitions: 42" "read cycle returns correct step count"
  assert_contains "$content" "Multi-line" "read cycle preserves multi-line context"
  assert_contains "$content" "Flow 3" "read cycle preserves flow catalog"
  assert_contains "$content" "Pattern B" "read cycle preserves pattern catalog"
  assert_contains "$content" "Then step" "read cycle preserves steps catalog"

  teardown
}

test_edge_cases() {
  echo ""
  echo "=== Testing edge cases ==="

  setup

  # Test 1: Zero counts
  bash "$SCRIPT_DIR/cache-writer.sh" write \
    --flows "0" \
    --patterns "0" \
    --steps "0" \
    --feature-files "0" \
    --step-files "0" \
    > /dev/null

  local content
  content=$(cat "$TEST_CACHE_FILE")

  assert_contains "$content" "Flows: 0" "cache accepts zero flow count"
  assert_contains "$content" "Patterns: 0" "cache accepts zero pattern count"
  assert_contains "$content" "Step Definitions: 0" "cache accepts zero step count"

  # Validate with zero counts (should be fresh)
  local status
  status=$(bash "$SCRIPT_DIR/cache-reader.sh" validate 0 0)

  assert_equals "fresh" "$status" "validate handles zero counts correctly"

  # Test 2: Large counts
  bash "$SCRIPT_DIR/cache-writer.sh" write \
    --flows "999" \
    --patterns "888" \
    --steps "777" \
    --feature-files "666" \
    --step-files "555" \
    > /dev/null

  content=$(cat "$TEST_CACHE_FILE")

  assert_contains "$content" "Flows: 999" "cache accepts large flow count"
  assert_contains "$content" "feature_file_count: 666" "cache accepts large feature file count"

  # Test 3: Empty string fields
  bash "$SCRIPT_DIR/cache-writer.sh" write \
    --flows "1" \
    --patterns "1" \
    --steps "1" \
    --feature-files "1" \
    --step-files "1" \
    --context "" \
    --flow-catalog "" \
    > /dev/null

  status=$(bash "$SCRIPT_DIR/cache-reader.sh" check)

  assert_equals "fresh" "$status" "cache handles empty string fields"

  teardown
}

test_cache_writer_empty_flag() {
  echo ""
  echo "=== Testing cache-writer.sh --empty flag (Slice 3) ==="

  setup

  # Test 1: Create empty cache with --empty flag
  bash "$SCRIPT_DIR/cache-writer.sh" write --empty > /dev/null

  assert_file_exists "$TEST_CACHE_FILE" "empty cache file created with --empty flag"

  # Test 2: Empty cache has valid structure
  local content
  content=$(cat "$TEST_CACHE_FILE")

  assert_contains "$content" "# Playwright-BDD Initialization Cache" "empty cache has title"
  assert_contains "$content" "## Summary" "empty cache has Summary section"
  assert_contains "$content" "## Context Summary" "empty cache has Context Summary section"
  assert_contains "$content" "## Flow Catalog" "empty cache has Flow Catalog section"
  assert_contains "$content" "## Pattern Catalog" "empty cache has Pattern Catalog section"
  assert_contains "$content" "## Steps Catalog" "empty cache has Steps Catalog section"

  # Test 3: Empty cache has zero counts
  assert_contains "$content" "- Flows: 0" "empty cache shows 0 flows"
  assert_contains "$content" "- Patterns: 0" "empty cache shows 0 patterns"
  assert_contains "$content" "- Step Definitions: 0" "empty cache shows 0 step definitions"

  # Test 4: Empty cache has zero file counts in frontmatter
  local frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$TEST_CACHE_FILE")

  assert_contains "$frontmatter" "feature_file_count: 0" "empty cache frontmatter has 0 feature files"
  assert_contains "$frontmatter" "step_file_count: 0" "empty cache frontmatter has 0 step files"

  # Test 5: Empty cache has warning note
  assert_contains "$content" "**Warning**" "empty cache contains warning"
  assert_contains "$content" "zero feature files and zero step definition files" "empty cache warning mentions zero files"
  assert_contains "$content" "No analysis was performed" "empty cache warning mentions no analysis"
  assert_contains "$content" "cache will be invalidated automatically" "empty cache warning mentions invalidation"

  # Test 6: Empty cache sections have appropriate messages
  assert_contains "$content" "No repository context available (zero files detected)" "empty cache context section has zero files message"
  assert_contains "$content" "No flows detected (zero feature files)" "empty cache flows section has zero files message"
  assert_contains "$content" "No patterns detected (zero feature files)" "empty cache patterns section has zero files message"
  assert_contains "$content" "No step definitions detected (zero step files)" "empty cache steps section has zero files message"

  # Test 7: Empty cache is valid and reports as fresh
  local status
  status=$(bash "$SCRIPT_DIR/cache-reader.sh" check)

  assert_equals "fresh" "$status" "empty cache check returns fresh"

  # Test 8: Empty cache validates as fresh with zero counts
  status=$(bash "$SCRIPT_DIR/cache-reader.sh" validate 0 0)

  assert_equals "fresh" "$status" "empty cache validates as fresh with 0 0 counts"

  # Test 9: Empty cache is marked stale when files are added
  status=$(bash "$SCRIPT_DIR/cache-reader.sh" validate 2 2)

  assert_equals "stale" "$status" "empty cache becomes stale when files are added"

  teardown
}

test_cache_reader_partial_cache_detection() {
  echo ""
  echo "=== Testing cache-reader.sh partial cache detection (Slice 3) ==="

  setup

  # Create cache directory
  mkdir -p "$(dirname "$TEST_CACHE_FILE")"

  # Test 1: Partial cache with only Summary section
  cat > "$TEST_CACHE_FILE" <<EOF
---
last_updated: "2026-03-10T12:00:00Z"
feature_file_count: 5
step_file_count: 3
---

# Playwright-BDD Initialization Cache

## Summary
- Flows: 1
- Patterns: 1
- Step Definitions: 1
EOF

  local status
  status=$(bash "$SCRIPT_DIR/cache-reader.sh" check)

  assert_equals "missing" "$status" "partial cache (only Summary) detected as missing"

  # Test 2: Partial cache with Summary and Context Summary only
  cat > "$TEST_CACHE_FILE" <<EOF
---
last_updated: "2026-03-10T12:00:00Z"
feature_file_count: 5
step_file_count: 3
---

# Playwright-BDD Initialization Cache

## Summary
- Flows: 1

## Context Summary
Some context here
EOF

  status=$(bash "$SCRIPT_DIR/cache-reader.sh" check)

  assert_equals "missing" "$status" "partial cache (Summary + Context) detected as missing"

  # Test 3: Partial cache missing Steps Catalog (4 out of 5 sections)
  cat > "$TEST_CACHE_FILE" <<EOF
---
last_updated: "2026-03-10T12:00:00Z"
feature_file_count: 5
step_file_count: 3
---

# Playwright-BDD Initialization Cache

## Summary
- Flows: 1

## Context Summary
Context

## Flow Catalog
Flows

## Pattern Catalog
Patterns
EOF

  status=$(bash "$SCRIPT_DIR/cache-reader.sh" check)

  assert_equals "missing" "$status" "partial cache (missing Steps Catalog) detected as missing"

  # Test 4: Partial cache missing Pattern and Steps Catalogs (3 out of 5 sections)
  cat > "$TEST_CACHE_FILE" <<EOF
---
last_updated: "2026-03-10T12:00:00Z"
feature_file_count: 5
step_file_count: 3
---

## Summary
- Flows: 1

## Context Summary
Context

## Flow Catalog
Flows
EOF

  status=$(bash "$SCRIPT_DIR/cache-reader.sh" check)

  assert_equals "missing" "$status" "partial cache (3/5 sections) detected as missing"

  # Test 5: Complete cache with all 5 sections is NOT partial
  bash "$SCRIPT_DIR/cache-writer.sh" write \
    --flows "5" \
    --patterns "3" \
    --steps "10" \
    --feature-files "8" \
    --step-files "4" \
    > /dev/null

  status=$(bash "$SCRIPT_DIR/cache-reader.sh" check)

  assert_equals "fresh" "$status" "complete cache (all 5 sections) is not detected as partial"

  # Test 6: Partial cache detected by validate command
  cat > "$TEST_CACHE_FILE" <<EOF
---
last_updated: "2026-03-10T12:00:00Z"
feature_file_count: 5
step_file_count: 3
---

## Summary
- Flows: 1

## Context Summary
Context
EOF

  status=$(bash "$SCRIPT_DIR/cache-reader.sh" validate 5 3)

  assert_equals "missing" "$status" "validate command also detects partial cache as missing"

  # Test 7: Empty file (zero sections) is not partial, it's missing
  echo "" > "$TEST_CACHE_FILE"

  status=$(bash "$SCRIPT_DIR/cache-reader.sh" check)

  assert_equals "corrupt" "$status" "empty file (0 sections) detected as corrupt, not partial"

  teardown
}

# --- Main Execution ---

echo "========================================"
echo "Cache Scripts Test Suite"
echo "========================================"

test_cache_writer_basic
test_cache_writer_multiline
test_cache_writer_defaults
test_cache_writer_validation
test_cache_writer_clear
test_cache_reader_check
test_cache_reader_validate
test_cache_reader_get
test_integration_write_read_cycle
test_edge_cases
test_cache_writer_empty_flag
test_cache_reader_partial_cache_detection

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
