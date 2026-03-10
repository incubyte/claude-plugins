#!/bin/bash
#
# Test Suite: Suggestion Generation in playwright-step-matcher.md
#
# Tests for Slice 5: Gap Suggestion Generation
# Validates that the agent markdown file contains correct suggestion generation logic
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
echo "Suggestion Generation Test Suite - Slice 5"
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
# AC 1: Generate suggestions using pattern catalog (find similar patterns,
#       adapt to current step)
# ============================================================================

echo "AC 1: Pattern-based suggestion generation"
echo "---"

# Test 1.1: Pattern-based suggestion section exists
if grep -q "Generate Pattern-Based Suggestions" "$AGENT_FILE"; then
  test_pass "Pattern-based suggestion section exists"
else
  test_fail "Pattern-based suggestion section missing" "Expected '1. Generate Pattern-Based Suggestions' heading"
fi

# Test 1.2: Uses matched patterns from gap metadata
if grep -A 5 "Generate Pattern-Based Suggestions" "$AGENT_FILE" | grep -q "For each matched pattern in gapMetadata.patternSimilarity.matchedPatterns"; then
  test_pass "Iterates through matched patterns from gap detection"
else
  test_fail "Pattern iteration missing" "Should iterate through gapMetadata.patternSimilarity.matchedPatterns"
fi

# Test 1.3: Uses LLM to generate step definition
if grep -A 30 "Generate Pattern-Based Suggestions" "$AGENT_FILE" | grep -q "Use LLM to generate step definition text"; then
  test_pass "Uses LLM for step definition generation from patterns"
else
  test_fail "LLM generation for patterns missing" "Expected LLM-based step definition generation"
fi

# Test 1.4: LLM prompt includes Cucumber expression requirements
if grep -A 50 "Generate Pattern-Based Suggestions" "$AGENT_FILE" | grep -q "Include Cucumber expression parameters where appropriate ({string}, {int}, {float}, {word})"; then
  test_pass "LLM prompt requires Cucumber expression parameters"
else
  test_fail "Cucumber parameter requirement missing" "Prompt should mention {string}, {int}, {float}, {word}"
fi

# Test 1.5: Pattern suggestions tagged with source
if grep -A 60 "Generate Pattern-Based Suggestions" "$AGENT_FILE" | grep -q 'Tag source as "pattern_catalog"'; then
  test_pass "Pattern suggestions tagged with 'pattern_catalog' source"
else
  test_fail "Pattern source tagging missing" "Should tag source as 'pattern_catalog'"
fi

# Test 1.6: Pattern suggestions include score and metadata
if grep -A 70 "Generate Pattern-Based Suggestions" "$AGENT_FILE" | grep -q "Store: step definition text, score, source, pattern type"; then
  test_pass "Pattern suggestions store complete metadata"
else
  test_fail "Pattern metadata incomplete" "Should store: step definition, score, source, pattern type"
fi

# Test 1.7: Example pattern-based suggestion documented
if grep -q "Example pattern-based suggestion:" "$AGENT_FILE"; then
  test_pass "Example pattern-based suggestion documented"
else
  test_fail "Pattern example missing" "Should include example showing pattern-based suggestion"
fi

echo ""

# ============================================================================
# AC 2: Generate suggestions using flow catalog (identify related actions,
#       use flow terminology)
# ============================================================================

echo "AC 2: Flow-based suggestion generation"
echo "---"

# Test 2.1: Flow-based suggestion section exists
if grep -q "Generate Flow-Based Suggestions" "$AGENT_FILE"; then
  test_pass "Flow-based suggestion section exists"
else
  test_fail "Flow-based suggestion section missing" "Expected '2. Generate Flow-Based Suggestions' heading"
fi

# Test 2.2: Uses matched flows from gap metadata
if grep -A 5 "Generate Flow-Based Suggestions" "$AGENT_FILE" | grep -q "For each matched flow in gapMetadata.flowSimilarity.matchedFlows"; then
  test_pass "Iterates through matched flows from gap detection"
else
  test_fail "Flow iteration missing" "Should iterate through gapMetadata.flowSimilarity.matchedFlows"
fi

# Test 2.3: Analyzes flow sequence and stage
if grep -A 10 "Generate Flow-Based Suggestions" "$AGENT_FILE" | grep -q "Analyze flow sequence and stage"; then
  test_pass "Analyzes flow sequence and stage for context"
else
  test_fail "Flow analysis missing" "Should analyze flow sequence and stage"
fi

# Test 2.4: Uses domain terminology from flow
if grep -A 15 "Generate Flow-Based Suggestions" "$AGENT_FILE" | grep -q "Identify domain terms and action verbs from flow steps"; then
  test_pass "Extracts domain terminology from flow steps"
else
  test_fail "Domain terminology extraction missing" "Should identify domain terms and action verbs"
fi

# Test 2.5: Uses LLM to generate step definition using flow terminology
if grep -A 25 "Generate Flow-Based Suggestions" "$AGENT_FILE" | grep -q "Use LLM to generate step definition text using flow terminology"; then
  test_pass "Uses LLM for step definition generation from flows"
else
  test_fail "LLM generation for flows missing" "Expected LLM-based step definition generation"
fi

# Test 2.6: Flow LLM prompt includes Cucumber expression requirements
if grep -A 50 "Generate Flow-Based Suggestions" "$AGENT_FILE" | grep -q "Include Cucumber expression parameters for variable parts ({string}, {int}, {float})"; then
  test_pass "Flow LLM prompt requires Cucumber expression parameters"
else
  test_fail "Cucumber parameter requirement missing in flow prompt" "Should mention {string}, {int}, {float}"
fi

# Test 2.7: Flow suggestions tagged with source
if grep -A 60 "Generate Flow-Based Suggestions" "$AGENT_FILE" | grep -q 'Tag source as "flow_catalog"'; then
  test_pass "Flow suggestions tagged with 'flow_catalog' source"
else
  test_fail "Flow source tagging missing" "Should tag source as 'flow_catalog'"
fi

# Test 2.8: Flow suggestions include flowStage in metadata
if grep -A 70 "Generate Flow-Based Suggestions" "$AGENT_FILE" | grep -q "Store: step definition text, score, source, flow stage"; then
  test_pass "Flow suggestions store complete metadata including flowStage"
else
  test_fail "Flow metadata incomplete" "Should store: step definition, score, source, flow stage"
fi

# Test 2.9: Example flow-based suggestion documented
if grep -q "Example flow-based suggestion:" "$AGENT_FILE"; then
  test_pass "Example flow-based suggestion documented"
else
  test_fail "Flow example missing" "Should include example showing flow-based suggestion"
fi

echo ""

# ============================================================================
# AC 3: Generate suggestions using existing steps catalog (find related steps
#       like counterpart actions)
# ============================================================================

echo "AC 3: Existing-steps-based suggestion generation"
echo "---"

# Test 3.1: Existing-steps suggestion section exists
if grep -q "Generate Existing-Steps-Based Suggestions" "$AGENT_FILE"; then
  test_pass "Existing-steps suggestion section exists"
else
  test_fail "Existing-steps suggestion section missing" "Expected '3. Generate Existing-Steps-Based Suggestions' heading"
fi

# Test 3.2: Identifies counterpart actions
if grep -A 15 "Generate Existing-Steps-Based Suggestions" "$AGENT_FILE" | grep -q "Identify counterpart actions from step text"; then
  test_pass "Counterpart action identification logic exists"
else
  test_fail "Counterpart action logic missing" "Should identify counterpart actions (add→remove, etc.)"
fi

# Test 3.3: Counterpart examples documented
if grep -A 20 "Generate Existing-Steps-Based Suggestions" "$AGENT_FILE" | grep -q 'If step contains "add" → search for "remove", "delete", "create"' && \
   grep -A 20 "Generate Existing-Steps-Based Suggestions" "$AGENT_FILE" | grep -q 'If step contains "login" → search for "logout"'; then
  test_pass "Counterpart action examples documented (add/remove, login/logout)"
else
  test_fail "Counterpart examples incomplete" "Should document common counterpart pairs"
fi

# Test 3.4: Searches for related steps with multiple criteria
if grep -A 30 "Generate Existing-Steps-Based Suggestions" "$AGENT_FILE" | grep -q "Steps with counterpart action verbs (highest priority)" && \
   grep -A 30 "Generate Existing-Steps-Based Suggestions" "$AGENT_FILE" | grep -q "Steps with same domain entities" && \
   grep -A 30 "Generate Existing-Steps-Based Suggestions" "$AGENT_FILE" | grep -q "Steps with similar Cucumber expression patterns"; then
  test_pass "Searches indexed steps by: counterpart actions, domain entities, patterns"
else
  test_fail "Related step search criteria incomplete" "Should search by counterpart actions, domain entities, and patterns"
fi

# Test 3.5: Limits results to top 3
if grep -A 35 "Generate Existing-Steps-Based Suggestions" "$AGENT_FILE" | grep -q "limit to top 3"; then
  test_pass "Limits existing-steps search to top 3 results"
else
  test_fail "Result limit missing" "Should limit to top 3 related steps"
fi

# Test 3.6: Uses LLM to adapt related step structure
if grep -A 40 "Generate Existing-Steps-Based Suggestions" "$AGENT_FILE" | grep -q "Use LLM to adapt related step structure to new step"; then
  test_pass "Uses LLM to adapt existing step structure to new step"
else
  test_fail "LLM adaptation missing" "Should use LLM to adapt related step structure"
fi

# Test 3.7: Existing-steps LLM prompt preserves parameter patterns
if grep -A 60 "Generate Existing-Steps-Based Suggestions" "$AGENT_FILE" | grep -q "Preserve parameter patterns from related step ({string}, {int}, etc.)"; then
  test_pass "LLM prompt preserves Cucumber parameter patterns from related step"
else
  test_fail "Parameter preservation missing" "Should preserve {string}, {int} patterns from related step"
fi

# Test 3.8: Scores based on relationship strength
if grep -A 70 "Generate Existing-Steps-Based Suggestions" "$AGENT_FILE" | grep -q "Counterpart action: 80" && \
   grep -A 70 "Generate Existing-Steps-Based Suggestions" "$AGENT_FILE" | grep -q "Same entity: 70"; then
  test_pass "Scores suggestions based on relationship strength (counterpart=80, entity=70)"
else
  test_fail "Relationship scoring missing" "Should score: counterpart=80, entity=70, pattern=60"
fi

# Test 3.9: Existing-steps suggestions tagged with source
if grep -A 80 "Generate Existing-Steps-Based Suggestions" "$AGENT_FILE" | grep -q 'Tag source as "existing_steps"'; then
  test_pass "Existing-steps suggestions tagged with 'existing_steps' source"
else
  test_fail "Existing-steps source tagging missing" "Should tag source as 'existing_steps'"
fi

# Test 3.10: Metadata includes related step path and relationship type
if grep -A 85 "Generate Existing-Steps-Based Suggestions" "$AGENT_FILE" | grep -q "Store: step definition text, score, source, relationship type, related step path"; then
  test_pass "Existing-steps metadata includes relationship type and related step path"
else
  test_fail "Existing-steps metadata incomplete" "Should store: step definition, score, source, relationship type, related step path"
fi

# Test 3.11: Example existing-steps suggestion documented
if grep -q "Example existing-steps-based suggestion:" "$AGENT_FILE"; then
  test_pass "Example existing-steps suggestion documented"
else
  test_fail "Existing-steps example missing" "Should include example showing existing-steps suggestion"
fi

echo ""

# ============================================================================
# AC 4: Combine all three sources and rank suggestions by relevance
# ============================================================================

echo "AC 4: Combine and rank suggestions"
echo "---"

# Test 4.1: Combine and rank section exists
if grep -q "Combine and Rank Suggestions" "$AGENT_FILE"; then
  test_pass "Combine and rank suggestions section exists"
else
  test_fail "Combine and rank section missing" "Expected '4. Combine and Rank Suggestions' heading"
fi

# Test 4.2: Deduplication logic exists
if grep -A 5 "Combine and Rank Suggestions" "$AGENT_FILE" | grep -q "Deduplicate suggestions"; then
  test_pass "Deduplication logic exists"
else
  test_fail "Deduplication missing" "Should deduplicate suggestions"
fi

# Test 4.3: Deduplication keeps higher score
if grep -A 10 "Combine and Rank Suggestions" "$AGENT_FILE" | grep -q "keep the one with higher score"; then
  test_pass "Deduplication keeps suggestion with higher score"
else
  test_fail "Deduplication logic incomplete" "Should keep suggestion with higher score when duplicates found"
fi

# Test 4.4: Normalizes text for comparison
if grep -A 10 "Combine and Rank Suggestions" "$AGENT_FILE" | grep -q "Normalize text for comparison (trim whitespace, normalize quotes)"; then
  test_pass "Normalizes text for deduplication comparison"
else
  test_fail "Text normalization missing" "Should normalize whitespace and quotes for comparison"
fi

# Test 4.5: Ranking by relevance documented
if grep -A 15 "Combine and Rank Suggestions" "$AGENT_FILE" | grep -q "Rank suggestions by relevance"; then
  test_pass "Ranking by relevance section exists"
else
  test_fail "Ranking section missing" "Should document ranking logic"
fi

# Test 4.6: Primary sort by score descending
if grep -A 20 "Combine and Rank Suggestions" "$AGENT_FILE" | grep -q "Primary sort: score descending (highest first)"; then
  test_pass "Primary sort: score descending (highest relevance first)"
else
  test_fail "Primary sort missing" "Should sort by score descending as primary criteria"
fi

# Test 4.7: Secondary sort by source priority
if grep -A 20 "Combine and Rank Suggestions" "$AGENT_FILE" | grep -q "Secondary sort: source priority (pattern_catalog > flow_catalog > existing_steps)"; then
  test_pass "Secondary sort: source priority (pattern > flow > existing_steps)"
else
  test_fail "Secondary sort missing" "Should use source priority as secondary sort"
fi

# Test 4.8: Tertiary sort alphabetically
if grep -A 20 "Combine and Rank Suggestions" "$AGENT_FILE" | grep -q "Tertiary sort: alphabetically by step definition text"; then
  test_pass "Tertiary sort: alphabetically by step definition text"
else
  test_fail "Tertiary sort missing" "Should sort alphabetically as tertiary criteria"
fi

# Test 4.9: Returns top 5 suggestions
if grep -A 25 "Combine and Rank Suggestions" "$AGENT_FILE" | grep -q "Return top 5 suggestions"; then
  test_pass "Returns top 5 suggestions (or fewer if less generated)"
else
  test_fail "Top 5 limit missing" "Should return top 5 suggestions"
fi

echo ""

# ============================================================================
# AC 5: Include Cucumber expression parameters in suggestions
#       (e.g., {string}, {int})
# ============================================================================

echo "AC 5: Cucumber expression parameters in all suggestion types"
echo "---"

# Test 5.1: Pattern suggestions require Cucumber parameters
if grep -A 50 "Generate Pattern-Based Suggestions" "$AGENT_FILE" | \
   grep "Requirements:" -A 10 | \
   grep -q "Include Cucumber expression parameters"; then
  test_pass "Pattern suggestions explicitly require Cucumber parameters"
else
  test_fail "Cucumber parameters not required in pattern suggestions" "LLM prompt should require {string}, {int}, etc."
fi

# Test 5.2: Flow suggestions require Cucumber parameters
if grep -A 50 "Generate Flow-Based Suggestions" "$AGENT_FILE" | \
   grep "Requirements:" -A 10 | \
   grep -q "Include Cucumber expression parameters"; then
  test_pass "Flow suggestions explicitly require Cucumber parameters"
else
  test_fail "Cucumber parameters not required in flow suggestions" "LLM prompt should require {string}, {int}, etc."
fi

# Test 5.3: Existing-steps suggestions preserve parameters
if grep -A 60 "Generate Existing-Steps-Based Suggestions" "$AGENT_FILE" | \
   grep "Requirements:" -A 10 | \
   grep -q "Preserve parameter patterns from related step"; then
  test_pass "Existing-steps suggestions preserve Cucumber parameters"
else
  test_fail "Parameter preservation not documented" "Should preserve {string}, {int} patterns"
fi

# Test 5.4: Supported parameter types documented
if grep -q "{string}" "$AGENT_FILE" && \
   grep -q "{int}" "$AGENT_FILE" && \
   grep -q "{float}" "$AGENT_FILE" && \
   grep -q "{word}" "$AGENT_FILE"; then
  test_pass "Cucumber parameter types documented: {string}, {int}, {float}, {word}"
else
  test_fail "Parameter types incomplete" "Should document {string}, {int}, {float}, {word}"
fi

# Test 5.5: Example suggestions include parameters
if grep -A 10 "Example pattern-based suggestion:" "$AGENT_FILE" | grep -q '{string}'; then
  test_pass "Example pattern suggestion includes Cucumber parameters"
else
  test_fail "Pattern example lacks parameters" "Example should show {string} or other parameters"
fi

if grep -A 10 "Example flow-based suggestion:" "$AGENT_FILE" | grep -q '{string}'; then
  test_pass "Example flow suggestion includes Cucumber parameters"
else
  test_fail "Flow example lacks parameters" "Example should show {string} or other parameters"
fi

if grep -A 10 "Example existing-steps-based suggestion:" "$AGENT_FILE" | grep -q '{string}'; then
  test_pass "Example existing-steps suggestion includes Cucumber parameters"
else
  test_fail "Existing-steps example lacks parameters" "Example should show {string} or other parameters"
fi

echo ""

# ============================================================================
# AC 6: Determine recommended file location based on feature name and
#       existing step file patterns
# ============================================================================

echo "AC 6: File location recommendation logic"
echo "---"

# Test 6.1: File location determination section exists
if grep -q "Determine Target File Location" "$AGENT_FILE"; then
  test_pass "File location determination section exists"
else
  test_fail "File location section missing" "Expected '5. Determine Target File Location' heading"
fi

# Test 6.2: Analyzes existing step file patterns
if grep -A 10 "Determine Target File Location" "$AGENT_FILE" | grep -q "Analyze existing step file patterns"; then
  test_pass "Analyzes existing step file naming patterns"
else
  test_fail "Pattern analysis missing" "Should analyze existing file naming patterns"
fi

# Test 6.3: Groups files by naming pattern
if grep -A 15 "Analyze existing step file patterns:" "$AGENT_FILE" | grep -q "Group files by naming pattern" && \
   grep -A 15 "Analyze existing step file patterns:" "$AGENT_FILE" | grep -q "By feature:" && \
   grep -A 15 "Analyze existing step file patterns:" "$AGENT_FILE" | grep -q "By domain:"; then
  test_pass "Groups files by naming pattern: feature-name, domain, generic"
else
  test_fail "Naming pattern grouping incomplete" "Should identify feature-name, domain, and generic patterns"
fi

# Test 6.4: Identifies dominant pattern
if grep -A 15 "Analyze existing step file patterns:" "$AGENT_FILE" | grep -q "Identify dominant pattern"; then
  test_pass "Identifies dominant naming pattern"
else
  test_fail "Dominant pattern detection missing" "Should identify which pattern most files follow"
fi

# Test 6.5: Recommendation logic - feature name first
if grep -A 10 "Determine recommended file location:" "$AGENT_FILE" | grep -q "If feature name is available" && \
   grep -A 15 "Determine recommended file location:" "$AGENT_FILE" | grep -q "Check if file"; then
  test_pass "Feature name-based recommendation (priority 1)"
else
  test_fail "Feature name logic missing" "Should check for [feature-name].steps.ts first"
fi

# Test 6.6: Recommendation logic - domain inference second
if grep -A 20 "Determine recommended file location:" "$AGENT_FILE" | grep -q "If domain can be inferred" && \
   grep -A 25 "Determine recommended file location:" "$AGENT_FILE" | grep -q "Check if file"; then
  test_pass "Domain-based recommendation (priority 2)"
else
  test_fail "Domain inference logic missing" "Should infer domain from step text"
fi

# Test 6.7: Recommendation logic - related steps third
if grep -A 30 "Determine recommended file location:" "$AGENT_FILE" | grep -q "If no clear pattern" && \
   grep -A 35 "Determine recommended file location:" "$AGENT_FILE" | grep -q "Recommend the file with most related steps"; then
  test_pass "Related steps recommendation (priority 3)"
else
  test_fail "Related steps logic missing" "Should recommend file with most related steps"
fi

# Test 6.8: Recommendation logic - empty catalog fallback
if grep -A 40 "Determine recommended file location:" "$AGENT_FILE" | grep -q "If no existing step files" && \
   grep -A 45 "Determine recommended file location:" "$AGENT_FILE" | grep -q "Recommend creating"; then
  test_pass "Empty catalog fallback: creates new file with feature name"
else
  test_fail "Empty catalog fallback missing" "Should handle empty catalog case"
fi

# Test 6.9: File location format documented
if grep -A 70 "Determine Target File Location" "$AGENT_FILE" | grep -q "Format file location recommendation" && \
   grep -A 75 "Determine Target File Location" "$AGENT_FILE" | grep -q 'filePath: string' && \
   grep -A 75 "Determine Target File Location" "$AGENT_FILE" | grep -q 'reason: string' && \
   grep -A 75 "Determine Target File Location" "$AGENT_FILE" | grep -q 'createNew: boolean'; then
  test_pass "File location format: filePath, reason, createNew"
else
  test_fail "File location format incomplete" "Should include: filePath, reason, createNew"
fi

# Test 6.10: Example file location recommendation documented
if grep -q "Example file location recommendation:" "$AGENT_FILE"; then
  test_pass "Example file location recommendation documented"
else
  test_fail "File location example missing" "Should include example showing file location recommendation"
fi

echo ""

# ============================================================================
# Integration Tests: Verify Complete Suggestion Flow
# ============================================================================

echo "Integration: Complete suggestion generation flow"
echo "---"

# Test 7.1: Suggestion generation only runs when gap detected
if grep -A 5 "Step 2.5: Generate Suggestions for Gaps" "$AGENT_FILE" | grep -q 'Only run if gap was detected (decision is "gap_detected")'; then
  test_pass "Suggestion generation conditional on gap detection"
else
  test_fail "Gap detection condition missing" "Should only generate suggestions when gap_detected"
fi

# Test 7.2: Skip if all catalogs unavailable
if grep -A 10 "Step 2.5: Generate Suggestions for Gaps" "$AGENT_FILE" | grep -q "Skip suggestion generation if:" && \
   grep -A 15 "Step 2.5: Generate Suggestions for Gaps" "$AGENT_FILE" | grep -q "All three catalogs are null or unavailable"; then
  test_pass "Skips suggestion generation if all catalogs unavailable"
else
  test_fail "Catalog availability check missing" "Should skip if all three catalogs are null"
fi

# Test 7.3: suggestions field added to gapMetadata
if grep -A 20 "Return Suggestion Results" "$AGENT_FILE" | grep -q 'suggestions: Array<{'; then
  test_pass "suggestions field added to gapMetadata structure"
else
  test_fail "suggestions field missing" "gapMetadata should include suggestions array"
fi

# Test 7.4: Suggestion structure complete
if grep -A 25 "Return Suggestion Results" "$AGENT_FILE" | grep -q 'stepDefinition: string' && \
   grep -A 25 "Return Suggestion Results" "$AGENT_FILE" | grep -q 'score: number' && \
   grep -A 25 "Return Suggestion Results" "$AGENT_FILE" | grep -q 'source: "pattern_catalog" | "flow_catalog" | "existing_steps"'; then
  test_pass "Suggestion structure includes: stepDefinition, score, source, metadata"
else
  test_fail "Suggestion structure incomplete" "Should include stepDefinition, score, source, metadata"
fi

# Test 7.5: recommendedLocation field added to gapMetadata
if grep -A 35 "Return Suggestion Results" "$AGENT_FILE" | grep -q 'recommendedLocation: {'; then
  test_pass "recommendedLocation field added to gapMetadata structure"
else
  test_fail "recommendedLocation field missing" "gapMetadata should include recommendedLocation object"
fi

# Test 7.6: recommendedLocation structure complete
if grep -A 40 "Return Suggestion Results" "$AGENT_FILE" | grep -q 'filePath: string' && \
   grep -A 40 "Return Suggestion Results" "$AGENT_FILE" | grep -q 'reason: string' && \
   grep -A 40 "Return Suggestion Results" "$AGENT_FILE" | grep -q 'createNew: boolean'; then
  test_pass "recommendedLocation structure includes: filePath, reason, createNew"
else
  test_fail "recommendedLocation structure incomplete" "Should include filePath, reason, createNew"
fi

# Test 7.7: Complete example with suggestions documented
if grep -q "Example with suggestions:" "$AGENT_FILE"; then
  test_pass "Complete example with suggestions documented"
else
  test_fail "Complete example missing" "Should include full example showing suggestions in gapMetadata"
fi

# Test 7.8: Example shows all three suggestion sources
if grep -A 100 "Example with suggestions:" "$AGENT_FILE" | grep -q '"source": "pattern_catalog"' && \
   grep -A 100 "Example with suggestions:" "$AGENT_FILE" | grep -q '"source": "flow_catalog"' && \
   grep -A 100 "Example with suggestions:" "$AGENT_FILE" | grep -q '"source": "existing_steps"'; then
  test_pass "Example includes suggestions from all three sources"
else
  test_fail "Example sources incomplete" "Example should show pattern_catalog, flow_catalog, and existing_steps"
fi

# Test 7.9: Notes section updated for Slice 5
if grep -A 15 "## Notes" "$AGENT_FILE" | grep -q "Suggestion generation (Phase 2, Slice 5)"; then
  test_pass "Notes section documents Slice 5 suggestion generation"
else
  test_fail "Notes section not updated" "Should mention Slice 5 in notes"
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
  echo -e "${GREEN}All tests passed!${NC} Suggestion generation logic is correctly implemented."
  exit 0
else
  echo -e "${RED}Some tests failed.${NC} Review the suggestion generation implementation."
  exit 1
fi
