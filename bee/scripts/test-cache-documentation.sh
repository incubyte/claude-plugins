#!/usr/bin/env bash
#
# Test Suite: Playwright-BDD Cache Documentation (Slice 7)
#
# Validates that bee/CLAUDE.md contains complete cache behavior documentation
# covering all 5 acceptance criteria from the spec.
#
# Usage: bash bee/scripts/test-cache-documentation.sh

set -euo pipefail

# Test framework setup
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# File under test
CLAUDE_MD="/Users/akashincubyte/Documents/incubyte/Repo/claude plugins/claude-plugins/bee/CLAUDE.md"

# Test helpers
assert_file_exists() {
    local file="$1"
    local test_name="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ -f "$file" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} $test_name"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        echo -e "${RED}✗${NC} $test_name"
        echo "   Expected file to exist: $file"
        return 1
    fi
}

assert_contains() {
    local file="$1"
    local pattern="$2"
    local test_name="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if grep -q "$pattern" "$file"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} $test_name"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        echo -e "${RED}✗${NC} $test_name"
        echo "   Expected to find pattern: $pattern"
        return 1
    fi
}

assert_section_exists() {
    local file="$1"
    local section_pattern="$2"
    local test_name="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if grep -q "$section_pattern" "$file"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} $test_name"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        echo -e "${RED}✗${NC} $test_name"
        echo "   Expected to find section: $section_pattern"
        return 1
    fi
}

assert_multiline_pattern() {
    local file="$1"
    local pattern1="$2"
    local pattern2="$3"
    local test_name="$4"

    TESTS_RUN=$((TESTS_RUN + 1))

    # Check if both patterns exist in the file (not necessarily adjacent)
    # Use grep -F for literal string matching and -- to prevent option interpretation
    if grep -qF -- "$pattern1" "$file" && grep -qF -- "$pattern2" "$file"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} $test_name"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        echo -e "${RED}✗${NC} $test_name"
        echo "   Expected to find both patterns:"
        echo "     1: $pattern1"
        echo "     2: $pattern2"
        return 1
    fi
}

# Test suite header
echo "=========================================="
echo "Playwright-BDD Cache Documentation Tests"
echo "Slice 7 - AC Coverage"
echo "=========================================="
echo ""

# Prerequisite test
assert_file_exists "$CLAUDE_MD" "bee/CLAUDE.md file exists"
echo ""

# AC1: Add cache behavior section to bee/CLAUDE.md documenting where cache lives
echo "AC1: Cache location documentation"
echo "------------------------------------------"
assert_section_exists "$CLAUDE_MD" "## Playwright-BDD Cache" "Cache section exists in CLAUDE.md"
assert_section_exists "$CLAUDE_MD" "### Cache Location" "Cache Location subsection exists"
assert_contains "$CLAUDE_MD" "docs/playwright-init.md" "Documents cache file path (docs/playwright-init.md)"
assert_contains "$CLAUDE_MD" "Cache file:" "Explicitly labels cache file location"
echo ""

# AC2: Document what triggers invalidation (±2 feature files OR ±2 step files)
echo "AC2: Cache invalidation triggers"
echo "------------------------------------------"
assert_section_exists "$CLAUDE_MD" "### Cache Invalidation" "Cache Invalidation subsection exists"
assert_contains "$CLAUDE_MD" "Feature file count changes by 2 or more" "Documents feature file threshold (±2)"
assert_contains "$CLAUDE_MD" "Step file count changes by 2 or more" "Documents step file threshold (±2)"
assert_contains "$CLAUDE_MD" "\\.feature" "Mentions .feature files as trigger"
assert_contains "$CLAUDE_MD" "\\.steps\\.ts" "Mentions .steps.ts files as trigger"
assert_multiline_pattern "$CLAUDE_MD" "Invalidation Triggers:" "Feature file count changes by 2 or more" "Invalidation triggers section is properly structured"
echo ""

# AC3: Document how to force re-analysis (interactive prompt options)
echo "AC3: Force re-analysis documentation"
echo "------------------------------------------"
assert_section_exists "$CLAUDE_MD" "### Forcing Re-Analysis" "Forcing Re-Analysis subsection exists"
assert_contains "$CLAUDE_MD" "Re-analyze anyway" "Documents 'Re-analyze anyway' option"
assert_contains "$CLAUDE_MD" "manually delete.*docs/playwright-init.md" "Documents manual cache deletion option"
assert_section_exists "$CLAUDE_MD" "### Interactive Prompts" "Interactive Prompts subsection exists"
assert_contains "$CLAUDE_MD" "recommended option" "Mentions recommended option selection"
echo ""

# AC4: Document cache structure overview (metadata, context, flow/pattern/steps catalogs)
echo "AC4: Cache structure overview"
echo "------------------------------------------"
assert_section_exists "$CLAUDE_MD" "### Cache Contents" "Cache Contents subsection exists"
assert_section_exists "$CLAUDE_MD" "### Cache Structure" "Cache Structure subsection exists"
assert_contains "$CLAUDE_MD" "Context Summary" "Documents Context Summary catalog"
assert_contains "$CLAUDE_MD" "Flow Catalog" "Documents Flow Catalog"
assert_contains "$CLAUDE_MD" "Pattern Catalog" "Documents Pattern Catalog"
assert_contains "$CLAUDE_MD" "Steps Catalog" "Documents Steps Catalog"
assert_contains "$CLAUDE_MD" "last_updated" "Documents metadata: last_updated timestamp"
assert_contains "$CLAUDE_MD" "feature_file_count" "Documents metadata: feature_file_count"
assert_contains "$CLAUDE_MD" "step_file_count" "Documents metadata: step_file_count"
echo ""

# AC5: Include example cache file snippet showing format
echo "AC5: Example cache file snippet"
echo "------------------------------------------"
assert_contains "$CLAUDE_MD" "\`\`\`markdown" "Contains markdown code block for example"
assert_multiline_pattern "$CLAUDE_MD" "---" "last_updated:" "Example shows frontmatter with last_updated"
assert_multiline_pattern "$CLAUDE_MD" "# Playwright-BDD Initialization Cache" "## Summary" "Example shows cache file structure"
assert_contains "$CLAUDE_MD" "Flows:" "Example includes flow count in summary"
assert_contains "$CLAUDE_MD" "Patterns:" "Example includes pattern count in summary"
assert_contains "$CLAUDE_MD" "Step Definitions:" "Example includes step definition count in summary"
echo ""

# Additional quality checks
echo "Quality checks"
echo "------------------------------------------"
assert_section_exists "$CLAUDE_MD" "### Cache Updates" "Documents cache update behavior"
assert_section_exists "$CLAUDE_MD" "### Empty Repository Handling" "Documents empty repository edge case"
assert_contains "$CLAUDE_MD" "all-or-nothing" "Explains all-or-nothing cache write policy"
assert_contains "$CLAUDE_MD" "Fresh Cache:" "Documents fresh cache state"
assert_contains "$CLAUDE_MD" "Stale Cache:" "Documents stale cache state"
echo ""

# Test summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}FAILED TESTS:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo "  - $test"
    done
    echo ""
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    echo ""
    exit 0
fi
