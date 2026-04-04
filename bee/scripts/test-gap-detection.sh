#!/bin/bash
#
# Test Suite: Gap Detection in playwright-step-matcher.md
#
# Tests for Slice 4: Smart Gap Identification
# Validates that the agent markdown file contains correct gap detection logic
#

set -e

AGENT_FILE="/Users/akashincubyte/Documents/incubyte/Repo/claude plugins/claude-plugins/bee/agents/playwright/playwright-step-matcher.md"
PASS_COUNT=0
FAIL_COUNT=0

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test result tracking
test_pass() {
  echo -e "${GREEN}✓${NC} $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

test_fail() {
  echo -e "${RED}✗${NC} $1"
  echo -e "  ${YELLOW}Detail:${NC} $2"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

echo "=========================================="
echo "Gap Detection Test Suite - Slice 4"
echo "=========================================="
echo ""

# Validate agent file exists
if [ ! -f "$AGENT_FILE" ]; then
  echo -e "${RED}FATAL:${NC} Agent file not found at $AGENT_FILE"
  exit 1
fi

echo "Testing: $AGENT_FILE"
echo ""

# ============================================================================
# AC 1: Enhance playwright-step-matcher to detect gaps only for scenarios
#       being generated in current run
# ============================================================================

echo "AC 1: Gap detection for current run scenarios only"
echo "---"

# Test 1.1: Gap detection section exists
if grep -q "Gap Detection (when no confident matches found)" "$AGENT_FILE"; then
  test_pass "Gap detection section exists in agent"
else
  test_fail "Gap detection section missing" "Expected 'Gap Detection (when no confident matches found)' heading"
fi

# Test 1.2: Scenario context is included in gap metadata
if grep -q '"scenarioContext": \[' "$AGENT_FILE"; then
  test_pass "Scenario context is captured in gap metadata"
else
  test_fail "Scenario context not captured" "Expected scenarioContext field in gapMetadata structure"
fi

# Test 1.3: Gap detection only runs when no confident matches (semantic < 50%)
if grep -q "When all semantic matches score below 50%" "$AGENT_FILE"; then
  test_pass "Gap detection triggered only when no confident matches"
else
  test_fail "Gap detection trigger condition missing" "Should only run when semantic scores < 50%"
fi

echo ""

# ============================================================================
# AC 2: When step has no matches, check pattern catalog for similar
#       Given/When/Then structures
# ============================================================================

echo "AC 2: Pattern catalog similarity check"
echo "---"

# Test 2.1: Pattern catalog check logic exists
if grep -q "Check Pattern Catalog for Similar Structures" "$AGENT_FILE"; then
  test_pass "Pattern catalog check section exists"
else
  test_fail "Pattern catalog check missing" "Expected 'Check Pattern Catalog for Similar Structures' section"
fi

# Test 2.2: Pattern similarity uses LLM comparison
if grep -q "use LLM to compare semantic similarity" "$AGENT_FILE" && grep -A 20 "Check Pattern Catalog" "$AGENT_FILE" | grep -q "Prompt template"; then
  test_pass "Pattern similarity uses LLM semantic comparison"
else
  test_fail "LLM comparison for patterns not found" "Expected LLM-based similarity scoring for pattern catalog"
fi

# Test 2.3: Pattern similarity threshold is 60
if grep -q "Keep patterns with score ≥ 60" "$AGENT_FILE"; then
  test_pass "Pattern similarity threshold is 60 (correct)"
else
  test_fail "Pattern similarity threshold incorrect" "Expected threshold of 60 for pattern matches"
fi

# Test 2.4: Matched patterns stored in gap metadata
if grep -q '"matchedPatterns": \[' "$AGENT_FILE" && grep -A 5 '"matchedPatterns"' "$AGENT_FILE" | grep -q '"description"'; then
  test_pass "Matched patterns stored with description, type, and examples"
else
  test_fail "Pattern metadata structure incomplete" "Expected matchedPatterns with description, type, examples"
fi

echo ""

# ============================================================================
# AC 3: When step has no matches, check flow catalog for domain language match
# ============================================================================

echo "AC 3: Flow catalog domain language check"
echo "---"

# Test 3.1: Flow catalog check logic exists
if grep -q "Check Flow Catalog for Domain Language Match" "$AGENT_FILE"; then
  test_pass "Flow catalog check section exists"
else
  test_fail "Flow catalog check missing" "Expected 'Check Flow Catalog for Domain Language Match' section"
fi

# Test 3.2: Flow relevance uses LLM evaluation
if grep -q "Use LLM to evaluate domain relevance" "$AGENT_FILE" && grep -A 20 "Check Flow Catalog" "$AGENT_FILE" | grep -q "Evaluate if this new step uses domain language"; then
  test_pass "Flow relevance uses LLM domain language evaluation"
else
  test_fail "LLM evaluation for flows not found" "Expected LLM-based domain relevance scoring for flow catalog"
fi

# Test 3.3: Flow similarity threshold is 60
if grep -q "Keep flows with score ≥ 60" "$AGENT_FILE"; then
  test_pass "Flow similarity threshold is 60 (correct)"
else
  test_fail "Flow similarity threshold incorrect" "Expected threshold of 60 for flow matches"
fi

# Test 3.4: Matched flows stored in gap metadata
if grep -q '"matchedFlows": \[' "$AGENT_FILE" && grep -A 5 '"matchedFlows"' "$AGENT_FILE" | grep -q '"sequence"'; then
  test_pass "Matched flows stored with sequence and flowStage"
else
  test_fail "Flow metadata structure incomplete" "Expected matchedFlows with sequence and flowStage"
fi

echo ""

# ============================================================================
# AC 4: Flag as gap only if patterns OR flows suggest the step should exist
# ============================================================================

echo "AC 4: Gap flagging uses OR condition"
echo "---"

# Test 4.1: OR condition explicitly stated
if grep -q "patternScore ≥ 60 OR flowScore ≥ 60" "$AGENT_FILE"; then
  test_pass "Gap detection uses OR condition (pattern OR flow)"
else
  test_fail "OR condition not found" "Expected 'patternScore ≥ 60 OR flowScore ≥ 60' logic"
fi

# Test 4.2: Gap determination logic exists
if grep -q "Determine if This is a Gap" "$AGENT_FILE"; then
  test_pass "Gap determination step exists"
else
  test_fail "Gap determination step missing" "Expected explicit 'Determine if This is a Gap' section"
fi

# Test 4.3: Rationale for OR condition documented
if grep -q "If patterns OR flows suggest this step should exist" "$AGENT_FILE"; then
  test_pass "OR condition rationale documented"
else
  test_fail "OR condition rationale missing" "Expected explanation of why OR is used"
fi

# Test 4.4: isGap flag set correctly
if grep -q '"isGap": true' "$AGENT_FILE"; then
  test_pass "isGap flag included in gap metadata"
else
  test_fail "isGap flag missing" "Expected 'isGap: true' in gap metadata when gap detected"
fi

echo ""

# ============================================================================
# AC 5: Return gap metadata with step text, scenario context, similarity scores
# ============================================================================

echo "AC 5: Gap metadata structure"
echo "---"

# Test 5.1: gapMetadata structure exists
if grep -q 'gapMetadata?: {' "$AGENT_FILE"; then
  test_pass "gapMetadata field defined in output structure"
else
  test_fail "gapMetadata field missing" "Expected gapMetadata in TypeScript output type"
fi

# Test 5.2: Step text included
if grep -A 20 'gapMetadata' "$AGENT_FILE" | grep -q 'stepText: string'; then
  test_pass "Step text included in gap metadata"
else
  test_fail "Step text missing from gap metadata" "Expected stepText field"
fi

# Test 5.3: Scenario context included
if grep -A 20 'gapMetadata' "$AGENT_FILE" | grep -q 'scenarioContext: string\[\]'; then
  test_pass "Scenario context included in gap metadata"
else
  test_fail "Scenario context missing from gap metadata" "Expected scenarioContext array"
fi

# Test 5.4: Pattern similarity structure included
if grep -A 20 'gapMetadata' "$AGENT_FILE" | grep -q 'patternSimilarity: {' && \
   grep -A 25 'gapMetadata' "$AGENT_FILE" | grep -q 'score: number' && \
   grep -A 25 'gapMetadata' "$AGENT_FILE" | grep -q 'matchedPatterns'; then
  test_pass "Pattern similarity structure complete (score + matchedPatterns)"
else
  test_fail "Pattern similarity structure incomplete" "Expected score and matchedPatterns fields"
fi

# Test 5.5: Flow similarity structure included
if grep -A 30 'gapMetadata' "$AGENT_FILE" | grep -q 'flowSimilarity: {' && \
   grep -A 35 'gapMetadata' "$AGENT_FILE" | grep -q 'score: number' && \
   grep -A 35 'gapMetadata' "$AGENT_FILE" | grep -q 'matchedFlows'; then
  test_pass "Flow similarity structure complete (score + matchedFlows)"
else
  test_fail "Flow similarity structure incomplete" "Expected score and matchedFlows fields"
fi

# Test 5.6: isGap boolean included
if grep -A 40 'gapMetadata' "$AGENT_FILE" | grep -q 'isGap: boolean'; then
  test_pass "isGap boolean field included in gap metadata"
else
  test_fail "isGap field missing from gap metadata" "Expected isGap: boolean field"
fi

echo ""

# ============================================================================
# Additional Logic Validation Tests
# ============================================================================

echo "Additional Logic Validation"
echo "---"

# Test 6.1: Skip gap detection if both catalogs are null
if grep -q "Skip gap detection if:" "$AGENT_FILE" && \
   grep -A 3 "Skip gap detection if:" "$AGENT_FILE" | grep -q "Pattern catalog AND flow catalog are both null"; then
  test_pass "Gap detection skipped when both catalogs unavailable"
else
  test_fail "Missing null catalog handling" "Should skip gap detection if both catalogs are null"
fi

# Test 6.2: Run gap detection if either catalog available
if grep -q "Run gap detection if either catalog is available" "$AGENT_FILE"; then
  test_pass "Gap detection runs if either catalog available"
else
  test_fail "Either-catalog logic missing" "Should run gap detection if pattern OR flow catalog is available"
fi

# Test 6.3: decision field set to "gap_detected"
if grep -q '"decision": "gap_detected"' "$AGENT_FILE"; then
  test_pass "decision field set to 'gap_detected' when gap found"
else
  test_fail "gap_detected decision value missing" "Expected decision: 'gap_detected' in output"
fi

# Test 6.4: no_matches returned when no gap detected
if grep -A 10 "If no gap detected" "$AGENT_FILE" | grep -q '"decision": "no_matches"'; then
  test_pass "decision field set to 'no_matches' when no gap detected"
else
  test_fail "no_matches fallback missing" "Expected decision: 'no_matches' when both scores < 60"
fi

# Test 6.5: Example gap detection scenario exists
if grep -q "Example Gap Detection:" "$AGENT_FILE"; then
  test_pass "Example gap detection scenario documented"
else
  test_fail "Example scenario missing" "Expected example showing gap detection in action"
fi

echo ""

# ============================================================================
# Summary
# ============================================================================

echo "=========================================="
echo "Test Summary"
echo "=========================================="
TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo "Total tests: $TOTAL"
echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
echo -e "${RED}Failed: $FAIL_COUNT${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC} Gap detection logic is correctly implemented."
  exit 0
else
  echo -e "${RED}Some tests failed.${NC} Review the gap detection implementation."
  exit 1
fi
