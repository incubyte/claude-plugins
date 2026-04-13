# TDD Plan: LSP-Enhanced architecture-test-writer + review-code-quality -- Slices 4 and 5

## Execution Instructions
Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] -> [x]).
Continue until all items are done.
If stuck after 3 attempts, mark with a warning and move to the next independent step.

## Context
- **Source**: User-provided spec for Slices 4 and 5
- **Slice 4**: architecture-test-writer gets LSP-enhanced analysis
- **Slice 5**: review-code-quality gets LSP-enhanced analysis
- **Risk**: LOW
- **Nature**: Markdown-only edits to two existing agent files. No runtime code.
- **Acceptance Criteria**:
  1. `architecture-test-writer.md` references `skills/lsp-analysis/SKILL.md` in its Skills section
  2. architecture-test-writer Steps 3-4 (Generate Passing/Failing Tests): uses find-references to validate boundary assertions with real dependency data instead of grep for import statements
  3. `review-code-quality.md` references `skills/lsp-analysis/SKILL.md` in its Skills section
  4. review-code-quality Step 2 (Review Each File): uses hover for type information when assessing complexity, and LSP diagnostics for compiler-level warnings
  5. Both agents retain grep-based fallback for each LSP-enhanced step
  6. Both agents include the signaling note in output

## Codebase Analysis

### File Structure
- Implementation: `bee/agents/architecture-test-writer.md` and `bee/agents/review-code-quality.md`
- Skill reference: `bee/skills/lsp-analysis/SKILL.md` (already exists from Slice 0)
- Pattern reference: `bee/agents/review-coupling.md` (Slice 1), `bee/agents/review-tests.md` and `bee/agents/qc-planner.md` (Slice 2), `bee/agents/context-gatherer.md` and `bee/agents/domain-language-extractor.md` (Slice 3) -- already updated with LSP
- No runtime tests -- all deliverables are markdown agent files

### Verification Method
Since this is a markdown-only change, each "test" is a structural verification: grep or read the file and confirm the expected content exists. The RED phase describes what to look for that does NOT yet exist. The GREEN phase adds it. The verification confirms it.

### Current File Structure (architecture-test-writer.md)
- Frontmatter: `tools: Read, Write, Glob, Grep`
- Skills section: references architecture-patterns, clean-code, and tdd-practices
- Process: Steps 1-5 (Detect Test Framework, Determine Test Output Location, Generate Passing Boundary Tests, Generate Failing Architecture Leak Tests, Write Test Files with Comment Headers)
- Output Format: markdown template with Files Created + Summary + What This Means
- Rules: do not modify existing test files, no sub-agents, runnable as-is, one assertion per test

### Current File Structure (review-code-quality.md)
- Frontmatter: `tools: Read, Glob, Grep`
- Skills section: references clean-code and architecture-patterns
- Process: Steps 1-4 (Prioritize Files, Review Each File, Distinguish Active vs Dormant Debt, Categorize)
- Output Format: markdown template with Working Well + Findings
- Rules: read-only, no sub-agents, every finding needs a WHY, be specific, don't nitpick stable code

---

## Behavior 1: Skill reference added to architecture-test-writer Skills section

**Given** the architecture-test-writer Skills section references architecture-patterns, clean-code, and tdd-practices
**When** the agent file is updated
**Then** the Skills section also references `skills/lsp-analysis/SKILL.md`

- [x] **RED**: Verify `bee/agents/architecture-test-writer.md` does NOT contain `lsp-analysis/SKILL.md`
  - Grep for `lsp-analysis` in the file -- expect zero matches

- [x] **GREEN**: Add the skill reference
  - In the Skills section, add a fourth bullet: `- \`skills/lsp-analysis/SKILL.md\` -- LSP-enhanced analysis, availability checking, graceful degradation`
  - Keep the existing three skill references unchanged

- [x] **VERIFY**: Grep for `lsp-analysis/SKILL.md` in the file -- expect one match in the Skills section

---

## Behavior 2: LSP tools added to architecture-test-writer frontmatter

**Given** the architecture-test-writer frontmatter has `tools: Read, Write, Glob, Grep`
**When** the agent file is updated
**Then** the frontmatter includes LSP tools alongside the existing ones (preserving Write)

- [x] **RED**: Verify frontmatter `tools:` line does NOT contain any LSP tool names

- [x] **GREEN**: Update the `tools:` line in the frontmatter
  - Change to: `tools: Read, Write, Glob, Grep, mcp__lsp__find-references, mcp__lsp__document-symbols`
  - Keep Write (architecture-test-writer needs it to create test files)
  - Only the tools this agent actually uses: find-references (for boundary validation in Steps 3-4) and document-symbols (for availability check)

- [x] **VERIFY**: The `tools:` line contains Read, Write, Glob, Grep and the two LSP tools

---

## Behavior 3: architecture-test-writer Step 3 gets LSP-first path for passing boundary tests

**Given** Step 3 (Generate Passing Boundary Tests) currently validates boundaries by checking module existence, dependency direction, and concept ownership without LSP
**When** the agent file is updated
**Then** Step 3 first performs the availability check, then uses find-references to validate real cross-module dependency data, with the original approach as fallback

- [x] **RED**: Verify Step 3 has no mention of LSP, `document-symbols`, or `find-references`

- [x] **GREEN**: Add LSP-first path to Step 3
  - Add availability check at the top of Step 3: attempt `document-symbols` on one source file; if it returns symbols, LSP is available for this step. Decide once; do not retry if it fails.
  - Add LSP path: use `find-references` on key module exports to discover actual cross-module dependencies. Instead of generating tests that grep for import statements, generate tests that assert dependency direction based on real reference data. For example, if `find-references` on an Orders module export shows references only from allowed modules, generate a passing test documenting that boundary.
  - Keep the existing approach (module existence, dependency direction via imports, concept ownership) as the explicit fallback under a "Fallback (LSP unavailable)" sub-section
  - Preserve the framework-specific syntax examples and descriptive naming guidance

- [x] **VERIFY**: Step 3 contains `document-symbols` (availability check), `find-references` (real dependency validation), and retains the original approach as fallback

---

## Behavior 4: architecture-test-writer Step 4 gets LSP-first path for failing leak tests

**Given** Step 4 (Generate Failing Architecture Leak Tests) currently asserts desired state based on assessment report mismatches without LSP
**When** the agent file is updated
**Then** Step 4 uses find-references to confirm boundary violations with real reference data, with the original approach as fallback

- [x] **RED**: Verify Step 4 has no mention of LSP or `find-references`

- [x] **GREEN**: Add LSP-first path to Step 4
  - Add LSP path (availability already determined in Step 3 -- reuse that decision): use `find-references` on symbols identified in boundary violations to confirm the actual cross-boundary references exist. This produces more precise failing tests because the test assertions reference real dependency paths rather than inferred ones from the assessment report alone.
  - Keep the existing approach (vocabulary drift tests, boundary violation tests from report) as the explicit fallback under a "Fallback (LSP unavailable)" sub-section
  - Preserve the FIXME comment guidance, the explanation comments requirement, and the rule about not using skip/pending markers

- [x] **VERIFY**: Step 4 contains `find-references` (LSP path) and retains the original mismatch-based approach as fallback

---

## Behavior 5: architecture-test-writer output format includes signaling note

**Given** the Output Format section has no mention of analysis method signaling
**When** the agent file is updated
**Then** the output template includes the signaling line

- [x] **RED**: Verify Output Format section has no mention of "Analysis method"

- [x] **GREEN**: Add signaling to the Output Format template
  - Add a line after `## Architecture Tests Generated` and before `### Files Created`: `Analysis method: [LSP-enhanced analysis | text-based pattern matching]`

- [x] **VERIFY**: Output Format contains the signaling line with both options indicated

---

## Behavior 6: Skill reference added to review-code-quality Skills section

**Given** the review-code-quality Skills section references clean-code and architecture-patterns
**When** the agent file is updated
**Then** the Skills section also references `skills/lsp-analysis/SKILL.md`

- [x] **RED**: Verify `bee/agents/review-code-quality.md` does NOT contain `lsp-analysis/SKILL.md`
  - Grep for `lsp-analysis` in the file -- expect zero matches

- [x] **GREEN**: Add the skill reference
  - In the Skills section, add a third bullet: `- \`skills/lsp-analysis/SKILL.md\` -- LSP-enhanced analysis, availability checking, graceful degradation`
  - Keep the existing clean-code and architecture-patterns skill references unchanged

- [x] **VERIFY**: Grep for `lsp-analysis/SKILL.md` in the file -- expect one match in the Skills section

---

## Behavior 7: LSP tools added to review-code-quality frontmatter

**Given** the review-code-quality frontmatter has `tools: Read, Glob, Grep`
**When** the agent file is updated
**Then** the frontmatter includes LSP tools alongside the existing ones

- [x] **RED**: Verify frontmatter `tools:` line does NOT contain any LSP tool names

- [x] **GREEN**: Update the `tools:` line in the frontmatter
  - Change to: `tools: Read, Glob, Grep, mcp__lsp__hover, mcp__lsp__document-symbols`
  - Only the tools this agent actually uses: hover (for type-aware complexity assessment) and document-symbols (for availability check)

- [x] **VERIFY**: The `tools:` line contains Read, Glob, Grep and the two LSP tools

---

## Behavior 8: review-code-quality Step 2 gets LSP-first path for type-aware review

**Given** Step 2 (Review Each File) currently checks against clean code principles using only text-based reading
**When** the agent file is updated
**Then** Step 2 first performs the availability check, then uses hover for type information and document-symbols for structural overview, with the original approach as fallback

- [x] **RED**: Verify Step 2 has no mention of LSP, `document-symbols`, or `hover`

- [x] **GREEN**: Add LSP-first path to Step 2
  - Add availability check at the top of Step 2: attempt `document-symbols` on one source file in scope; if it returns symbols, LSP is available for this step. Decide once; do not retry if it fails.
  - Add LSP path: use `hover` on function signatures and key variables to get type information for more precise complexity assessment -- e.g., a function returning `Promise<Result<Order, ValidationError>>` reveals more about SRP than reading the function body alone. Use `hover` on imports to understand actual dependency types (interface vs concrete class) for dependency direction analysis. LSP diagnostics (compiler warnings, unused variables, type errors) supplement the manual checks.
  - Keep the existing seven review criteria (SRP, DRY, YAGNI, Naming, Small functions, Error handling, Dependency direction) as the explicit fallback under a "Fallback (LSP unavailable)" sub-section -- all seven bullet points preserved exactly
  - Preserve the opening instruction about checking against clean code principles

- [x] **VERIFY**: Step 2 contains `document-symbols` (availability check), `hover` (type-aware assessment), and retains all seven original review criteria as fallback

---

## Behavior 9: review-code-quality output format includes signaling note

**Given** the Output Format section has no mention of analysis method signaling
**When** the agent file is updated
**Then** the output template includes the signaling line

- [x] **RED**: Verify Output Format section has no mention of "Analysis method"

- [x] **GREEN**: Add signaling to the Output Format template
  - Add a line after `## Code Quality Review` and before `### Working Well`: `Analysis method: [LSP-enhanced analysis | text-based pattern matching]`

- [x] **VERIFY**: Output Format contains the signaling line with both options indicated

---

## Edge Cases (Low Risk)

### Fallback consistency check -- architecture-test-writer Step 3
- [x] **VERIFY**: Step 3 of architecture-test-writer has explicit fallback language
  - Grep for "fallback" or "LSP unavailable" or "LSP is not available" in architecture-test-writer.md -- expect at least one match in Step 3

### Fallback consistency check -- architecture-test-writer Step 4
- [x] **VERIFY**: Step 4 of architecture-test-writer has explicit fallback language
  - Grep for "fallback" or "LSP unavailable" or "LSP is not available" in architecture-test-writer.md -- expect at least one match in Step 4

### Fallback consistency check -- review-code-quality
- [x] **VERIFY**: Step 2 of review-code-quality has explicit fallback language
  - Grep for "fallback" or "LSP unavailable" or "LSP is not available" in review-code-quality.md -- expect at least one match in Step 2

### No changes to unrelated steps -- architecture-test-writer
- [x] **VERIFY**: Steps 1, 2, 5 of architecture-test-writer are unchanged
  - These steps have no LSP enhancement in the spec -- confirm they remain as-is by reading the file

### No changes to unrelated steps -- review-code-quality
- [x] **VERIFY**: Steps 1, 3, 4 of review-code-quality are unchanged
  - These steps have no LSP enhancement in the spec -- confirm they remain as-is by reading the file

### Rules sections unchanged
- [x] **VERIFY**: Rules section of architecture-test-writer still contains all original rules (do not modify existing test files, no sub-agents, runnable as-is, one assertion per test, etc.)
- [x] **VERIFY**: Rules section of review-code-quality still contains all original rules (read-only, no sub-agents, every finding needs a WHY, be specific, don't nitpick stable code)

### Write tool preserved in architecture-test-writer
- [x] **VERIFY**: The frontmatter `tools:` line in architecture-test-writer still includes `Write` -- this agent creates test files and must retain write capability

---

## Final Check

- [x] **Read the full file**: `bee/agents/architecture-test-writer.md` top to bottom
- [x] **Frontmatter**: tools line includes Read, Write, Glob, Grep + find-references + document-symbols
- [x] **Skills**: references architecture-patterns, clean-code, tdd-practices, and lsp-analysis
- [x] **Steps 1-2**: unchanged
- [x] **Step 3**: availability check + find-references for real dependency validation + original approach as fallback
- [x] **Step 4**: find-references for confirming boundary violations + original mismatch approach as fallback
- [x] **Step 5**: unchanged
- [x] **Output Format**: signaling line added, structure preserved
- [x] **Rules**: unchanged

- [x] **Read the full file**: `bee/agents/review-code-quality.md` top to bottom
- [x] **Frontmatter**: tools line includes Read, Glob, Grep + hover + document-symbols
- [x] **Skills**: references clean-code, architecture-patterns, and lsp-analysis
- [x] **Step 1**: unchanged
- [x] **Step 2**: availability check + hover for type-aware complexity + all seven review criteria preserved as fallback
- [x] **Steps 3-4**: unchanged
- [x] **Output Format**: signaling line added, structure preserved
- [x] **Rules**: unchanged

## Verification Summary
| Category | # Checks | Status |
|----------|----------|--------|
| Core behaviors (1-9) | 9 | ✅ |
| Edge cases | 8 | ✅ |
| Final check | 17 | ✅ |
| **Total** | **34** | ✅ |

[x] Reviewed
