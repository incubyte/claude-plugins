# TDD Plan: LSP-Enhanced review-tests + qc-planner -- Slice 2

## Execution Instructions
Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] -> [x]).
Continue until all items are done.
If stuck after 3 attempts, mark with a warning and move to the next independent step.

## Context
- **Source**: `docs/specs/lsp-integration-spec.md`, Slice 2
- **Slice**: review-tests and qc-planner get LSP-enhanced analysis
- **Risk**: LOW
- **Nature**: Markdown-only edits to two existing agent files. No runtime code.
- **Acceptance Criteria**:
  1. `review-tests.md` references `skills/lsp-analysis/SKILL.md` in its Skills section
  2. review-tests Step 5 (Coverage Gaps): uses find-references from test files back to source to detect which public functions have zero test references
  3. `qc-planner.md` references `skills/lsp-analysis/SKILL.md` in its Skills section
  4. qc-planner Step 3 (Assess Testability): uses call-hierarchy (outgoing) to measure dependency chain depth when judging whether something is a low-hanging fruit
  5. Both agents retain grep-based fallback for each LSP-enhanced step
  6. Both agents include the LSP/text-based signaling note in output

## Codebase Analysis

### File Structure
- Implementation: `bee/agents/review-tests.md` and `bee/agents/qc-planner.md`
- Skill reference: `bee/skills/lsp-analysis/SKILL.md` (already exists from Slice 0)
- Pattern reference: `bee/agents/review-coupling.md` (already updated in Slice 1)
- No runtime tests -- all deliverables are markdown agent files

### Verification Method
Since this is a markdown-only change, each "test" is a structural verification: grep or read the file and confirm the expected content exists. The RED phase describes what to look for that does NOT yet exist. The GREEN phase adds it. The verification confirms it.

### Current File Structure (review-tests.md)
- Frontmatter: `tools: Read, Glob, Grep`
- Skills section: references only `skills/tdd-practices/SKILL.md`
- Process: Steps 1-6 (Find Test Files, Behavior vs Implementation, Test Isolation, Test Naming, Coverage Gaps, Categorize)
- Output Format: markdown template with Working Well + Findings
- Rules: read-only, no sub-agents, test quality guidance

### Current File Structure (qc-planner.md)
- Frontmatter: `tools: Read, Write, Glob, Grep`
- Skills section: references `skills/tdd-practices/SKILL.md` and `skills/clean-code/SKILL.md`
- Process: Steps 1-5 (Compute Hotspot Scores, Cross-Reference, Assess Testability, Test Pyramid, Produce the Plan)
- Output Format: fixed-format plan template with tables
- Rules: no sub-agents, cap at 5-10, test pyramid priority, fixed format

---

## Behavior 1: Skill reference added to review-tests Skills section

**Given** the review-tests Skills section references only `skills/tdd-practices/SKILL.md`
**When** the agent file is updated
**Then** the Skills section also references `skills/lsp-analysis/SKILL.md`

- [x] **RED**: Verify `bee/agents/review-tests.md` does NOT contain `lsp-analysis/SKILL.md`
  - Grep for `lsp-analysis` in the file -- expect zero matches

- [x] **GREEN**: Add the skill reference
  - In the Skills section, add a second bullet: `- \`skills/lsp-analysis/SKILL.md\` -- LSP-enhanced analysis, availability checking, graceful degradation`
  - Keep the existing tdd-practices skill reference unchanged

- [x] **VERIFY**: Grep for `lsp-analysis/SKILL.md` in the file -- expect one match in the Skills section

---

## Behavior 2: LSP tools added to review-tests frontmatter

**Given** the review-tests frontmatter has `tools: Read, Glob, Grep`
**When** the agent file is updated
**Then** the frontmatter includes LSP tools alongside the existing ones

- [x] **RED**: Verify frontmatter `tools:` line does NOT contain any LSP tool names

- [x] **GREEN**: Update the `tools:` line in the frontmatter
  - Change to: `tools: Read, Glob, Grep, mcp__lsp__find-references, mcp__lsp__document-symbols`
  - Only the tools review-tests actually uses: find-references (for coverage gaps) and document-symbols (for availability check)

- [x] **VERIFY**: The `tools:` line contains both original tools and the two LSP tools

---

## Behavior 3: review-tests Step 5 gets LSP availability check + find-references path

**Given** Step 5 (Coverage Gaps) currently only uses qualitative assessment via reading source files
**When** the agent file is updated
**Then** Step 5 first performs the availability check, then uses find-references to trace from test files back to source functions, with the original approach as fallback

- [x] **RED**: Verify Step 5 has no mention of LSP, `document-symbols`, or `find-references`

- [x] **GREEN**: Rewrite Step 5 to add LSP-first path
  - Add availability check at the top of Step 5: attempt `document-symbols` on one source file in scope; if it returns symbols, LSP is available for this step. Decide once; do not retry if it fails.
  - Add LSP path: use `document-symbols` on source files to list public functions/methods, then use `find-references` on each to check whether any references come from test files. Public functions with zero test-file references are coverage gaps. This turns the qualitative assessment into a precise inventory.
  - Keep the existing qualitative assessment instructions as the explicit fallback under a "Fallback (LSP unavailable)" sub-section -- the original bullets about error paths, edge cases, complex functions, and happy paths
  - Preserve the closing line about qualitative assessment vs coverage percentage

- [x] **VERIFY**: Step 5 contains `document-symbols` (availability check), `find-references` (LSP path), and retains the original qualitative assessment as fallback

---

## Behavior 4: review-tests output format includes signaling note

**Given** the Output Format section has no mention of analysis method signaling
**When** the agent file is updated
**Then** the output template includes the signaling line from the skill

- [x] **RED**: Verify Output Format section has no mention of "Analysis method"

- [x] **GREEN**: Add signaling to the Output Format template
  - Add a line after `## Test Quality Review` and before `### Working Well`: `Analysis method: [LSP-enhanced analysis | text-based pattern matching]`

- [x] **VERIFY**: Output Format contains the signaling line with both options indicated

---

## Behavior 5: Skill reference added to qc-planner Skills section

**Given** the qc-planner Skills section references `skills/tdd-practices/SKILL.md` and `skills/clean-code/SKILL.md`
**When** the agent file is updated
**Then** the Skills section also references `skills/lsp-analysis/SKILL.md`

- [x] **RED**: Verify `bee/agents/qc-planner.md` does NOT contain `lsp-analysis/SKILL.md`
  - Grep for `lsp-analysis` in the file -- expect zero matches

- [x] **GREEN**: Add the skill reference
  - In the Skills section, add a third bullet: `- \`skills/lsp-analysis/SKILL.md\` -- LSP-enhanced analysis, availability checking, graceful degradation`
  - Keep the existing tdd-practices and clean-code skill references unchanged

- [x] **VERIFY**: Grep for `lsp-analysis/SKILL.md` in the file -- expect one match in the Skills section

---

## Behavior 6: LSP tools added to qc-planner frontmatter

**Given** the qc-planner frontmatter has `tools: Read, Write, Glob, Grep`
**When** the agent file is updated
**Then** the frontmatter includes LSP tools alongside the existing ones (including Write)

- [x] **RED**: Verify frontmatter `tools:` line does NOT contain any LSP tool names

- [x] **GREEN**: Update the `tools:` line in the frontmatter
  - Change to: `tools: Read, Write, Glob, Grep, mcp__lsp__call-hierarchy, mcp__lsp__document-symbols`
  - Keep Write (qc-planner needs it to write the plan file)
  - Only the tools qc-planner actually uses: call-hierarchy (for testability assessment) and document-symbols (for availability check)

- [x] **VERIFY**: The `tools:` line contains Read, Write, Glob, Grep and the two LSP tools

---

## Behavior 7: qc-planner Step 3 gets LSP availability check + call-hierarchy path

**Given** Step 3 (Assess Testability) currently identifies testability blockers through manual inspection of code patterns
**When** the agent file is updated
**Then** Step 3 first performs the availability check, then uses call-hierarchy (outgoing) to measure dependency chain depth, with the original approach as fallback

- [x] **RED**: Verify Step 3 has no mention of LSP, `document-symbols`, or `call-hierarchy`

- [x] **GREEN**: Rewrite Step 3 to add LSP-first path
  - Add availability check at the top of Step 3: attempt `document-symbols` on one hotspot file; if it returns symbols, LSP is available for this step. Decide once; do not retry if it fails.
  - Add LSP path: use `call-hierarchy` (outgoing) on public functions of each hotspot to measure dependency chain depth. A function with shallow outgoing calls (1-2 levels) is a low-hanging fruit for unit testing. A function with deep outgoing chains (many transitive dependencies) needs more mocking or refactoring before it can be tested in isolation. Reference the skill's guidance: "outgoingCalls depth measures testability."
  - Keep the existing testability assessment instructions as the explicit fallback under a "Fallback (LSP unavailable)" sub-section -- the existing "Testable as-is" and "Needs refactoring first" blocks with all their bullet points
  - Preserve the extensive refactoring rule about 4+ steps

- [x] **VERIFY**: Step 3 contains `document-symbols` (availability check), `call-hierarchy` (LSP path with outgoing depth measurement), and retains all original testability assessment content as fallback

---

## Behavior 8: qc-planner output format includes signaling note

**Given** the Output Format section (the plan template in Step 5) has no mention of analysis method signaling
**When** the agent file is updated
**Then** the output template includes the signaling line from the skill

- [x] **RED**: Verify the plan template in Step 5 has no mention of "Analysis method"

- [x] **GREEN**: Add signaling to the plan output template
  - In the plan template inside Step 5, add a line in the Analysis Summary section or just above it: `Analysis method: [LSP-enhanced analysis | text-based pattern matching]`

- [x] **VERIFY**: The plan template contains the signaling line with both options indicated

---

## Edge Cases (Low Risk)

### Fallback consistency check -- review-tests
- [x] **VERIFY**: Step 5 of review-tests has explicit fallback language
  - Grep for "fallback" or "LSP unavailable" or "LSP is not available" in review-tests.md -- expect at least one match in Step 5

### Fallback consistency check -- qc-planner
- [x] **VERIFY**: Step 3 of qc-planner has explicit fallback language
  - Grep for "fallback" or "LSP unavailable" or "LSP is not available" in qc-planner.md -- expect at least one match in Step 3

### No changes to unrelated steps -- review-tests
- [x] **VERIFY**: Steps 1-4 and Step 6 of review-tests are unchanged
  - These steps have no LSP enhancement in the spec -- confirm they remain as-is by reading the file

### No changes to unrelated steps -- qc-planner
- [x] **VERIFY**: Steps 1, 2, 4, 5 of qc-planner are unchanged
  - These steps have no LSP enhancement in the spec -- confirm they remain as-is by reading the file

### Rules sections unchanged
- [x] **VERIFY**: Rules section of review-tests still contains all original rules (read-only, no sub-agents, etc.)
- [x] **VERIFY**: Rules section of qc-planner still contains all original rules (no sub-agents, cap at 5-10, fixed format, etc.)

---

## Final Check

- [x] **Read the full file**: `bee/agents/review-tests.md` top to bottom
- [x] **Frontmatter**: tools line includes Read, Glob, Grep + find-references + document-symbols
- [x] **Skills**: references both tdd-practices and lsp-analysis skills
- [x] **Steps 1-4**: unchanged
- [x] **Step 5**: availability check + find-references for coverage gap detection + qualitative fallback
- [x] **Step 6**: unchanged
- [x] **Output Format**: signaling line added, structure preserved
- [x] **Rules**: unchanged

- [x] **Read the full file**: `bee/agents/qc-planner.md` top to bottom
- [x] **Frontmatter**: tools line includes Read, Write, Glob, Grep + call-hierarchy + document-symbols
- [x] **Skills**: references tdd-practices, clean-code, and lsp-analysis skills
- [x] **Steps 1-2**: unchanged
- [x] **Step 3**: availability check + call-hierarchy outgoing for testability depth + original assessment as fallback
- [x] **Steps 4-5**: unchanged (except signaling line in the plan template)
- [x] **Output Format**: signaling line added to plan template
- [x] **Rules**: unchanged

## Verification Summary
| Category | # Checks | Status |
|----------|----------|--------|
| Core behaviors (1-8) | 8 | ✅ |
| Edge cases | 6 | ✅ |
| Final check | 16 | ✅ |
| **Total** | **30** | ✅ |

[x] Reviewed
