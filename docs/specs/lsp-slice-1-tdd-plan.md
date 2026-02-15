# TDD Plan: LSP-Enhanced review-coupling -- Slice 1

## Execution Instructions
Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] -> [x]).
Continue until all items are done.
If stuck after 3 attempts, mark with a warning and move to the next independent step.

## Context
- **Source**: `docs/specs/lsp-integration-spec.md`, Slice 1
- **Slice**: review-coupling gets LSP-enhanced analysis
- **Risk**: LOW
- **Nature**: Markdown-only edit to an existing agent file. No runtime code.
- **Acceptance Criteria**:
  1. Agent references `skills/lsp-analysis/SKILL.md` in its Skills section
  2. Agent lists LSP tools in its frontmatter tools list
  3. Step 1 (Map Dependencies): LSP availability check, then find-references for dependency graph
  4. Step 2 (Afferent Coupling): find-references to count actual consumers
  5. Step 3 (Efferent Coupling): call-hierarchy (outgoing) for transitive dependencies
  6. Step 5 (Boundary Violations): find-references for cross-boundary calls
  7. Each step retains grep-based fallback when LSP is unavailable
  8. Output format unchanged -- same markdown structure, same categorization
  9. Output includes signaling note (LSP-enhanced or text-based)

## Codebase Analysis

### File Structure
- Implementation: `bee/agents/review-coupling.md`
- Skill reference: `bee/skills/lsp-analysis/SKILL.md` (already exists)
- No runtime tests exist in this project -- all deliverables are markdown agent files

### Verification Method
Since this is a markdown-only change, each "test" is a structural verification: grep or read the file and confirm the expected content exists. The RED phase describes what to look for that does NOT yet exist. The GREEN phase adds it. The verification confirms it.

### Current File Structure (review-coupling.md)
- Frontmatter: `tools: Read, Glob, Grep`
- Skills section: references only `skills/code-review/SKILL.md`
- Process: Steps 1-5 (Map Dependencies, Afferent, Efferent, Change Amplifiers, Boundary Violations) + Step 6 (Categorize)
- Output Format: markdown template with Working Well + Findings
- Rules: read-only, no sub-agents, coupling guidance

---

## Behavior 1: Skill reference added to Skills section

**Given** the current Skills section references only `skills/code-review/SKILL.md`
**When** the agent file is updated
**Then** the Skills section also references `skills/lsp-analysis/SKILL.md`

- [x] **RED**: Verify `bee/agents/review-coupling.md` does NOT contain `lsp-analysis/SKILL.md`
  - Grep for `lsp-analysis` in the file -- expect zero matches

- [x] **GREEN**: Add the skill reference
  - In the Skills section, add a second bullet: `- \`skills/lsp-analysis/SKILL.md\` -- LSP-enhanced dependency analysis, availability checking, graceful degradation`
  - Keep the existing code-review skill reference unchanged

- [x] **VERIFY**: Grep for `lsp-analysis/SKILL.md` in the file -- expect one match in the Skills section

---

## Behavior 2: LSP tools added to frontmatter

**Given** the frontmatter has `tools: Read, Glob, Grep`
**When** the agent file is updated
**Then** the frontmatter includes LSP tools alongside the existing ones

- [x] **RED**: Verify frontmatter `tools:` line does NOT contain any LSP tool names

- [x] **GREEN**: Update the `tools:` line in the frontmatter
  - Change to: `tools: Read, Glob, Grep, mcp__lsp__find-references, mcp__lsp__call-hierarchy, mcp__lsp__document-symbols`
  - Note: use the exact tool naming convention from the skill file. If the project uses a different MCP tool naming pattern, match that instead.

- [x] **VERIFY**: The `tools:` line contains both original tools and LSP tools

---

## Behavior 3: Step 1 gets LSP availability check + find-references path

**Given** Step 1 (Map Dependencies) currently only uses Grep for import patterns
**When** the agent file is updated
**Then** Step 1 first performs the availability check from the skill, then uses find-references if LSP is available, with grep as fallback

- [x] **RED**: Verify Step 1 has no mention of LSP, `document-symbols`, or `find-references`

- [x] **GREEN**: Rewrite Step 1 to add LSP-first path
  - Add availability check at the top of Step 1: attempt `document-symbols` on one target file; if it returns symbols, LSP is available for all subsequent steps
  - Add LSP path: use `find-references` on key exports to build the dependency graph
  - Keep existing grep instructions as the explicit fallback under a "Fallback" or "If LSP is not available" sub-section
  - The availability result carries forward -- do not re-check in later steps

- [x] **VERIFY**: Step 1 contains `document-symbols` (availability check), `find-references` (LSP path), and retains grep-based instructions as fallback

---

## Behavior 4: Step 2 gets find-references for afferent coupling

**Given** Step 2 (Afferent Coupling) currently identifies dependents through general code inspection
**When** the agent file is updated
**Then** Step 2 uses find-references to count actual consumers of a module's exports

- [x] **RED**: Verify Step 2 has no mention of `find-references`

- [x] **GREEN**: Add LSP-first path to Step 2
  - LSP path: use `find-references` on each module's exported symbols to count actual consumers (not just files that import it)
  - Reference the skill's guidance: count references for fan-in, "3 callers vs 47 callers" distinction
  - Fallback: retain existing grep-based approach for when LSP is unavailable

- [x] **VERIFY**: Step 2 contains `find-references`, mentions counting consumers, and retains fallback

---

## Behavior 5: Step 3 gets call-hierarchy (outgoing) for efferent coupling

**Given** Step 3 (Efferent Coupling) currently identifies dependencies through general inspection
**When** the agent file is updated
**Then** Step 3 uses call-hierarchy (outgoing) to map transitive dependencies

- [x] **RED**: Verify Step 3 has no mention of `call-hierarchy`

- [x] **GREEN**: Add LSP-first path to Step 3
  - LSP path: use `call-hierarchy` (outgoing) to map transitive dependencies through shared abstractions
  - Reference the skill's guidance: outgoingCalls depth measures fragility and testability
  - Fallback: retain existing grep-based approach

- [x] **VERIFY**: Step 3 contains `call-hierarchy`, mentions outgoing/transitive, and retains fallback

---

## Behavior 6: Step 5 gets find-references for boundary violations

**Given** Step 5 (Boundary Violations) currently checks for imports that cross boundaries via code inspection
**When** the agent file is updated
**Then** Step 5 uses find-references to detect cross-boundary calls that grep misses

- [x] **RED**: Verify Step 5 has no mention of `find-references`

- [x] **GREEN**: Add LSP-first path to Step 5
  - LSP path: use `find-references` on boundary-defining symbols (e.g., domain interfaces, public APIs) to detect cross-boundary calls that grep misses (re-exports, inherited methods, framework injection)
  - Fallback: retain existing grep-based import checking

- [x] **VERIFY**: Step 5 contains `find-references`, mentions cross-boundary detection, and retains fallback

---

## Behavior 7: Output format includes signaling note

**Given** the Output Format section has no mention of analysis method signaling
**When** the agent file is updated
**Then** the output template includes the signaling line from the skill

- [x] **RED**: Verify Output Format section has no mention of "Analysis method"

- [x] **GREEN**: Add signaling to the Output Format template
  - Add a line near the top of the output template: `Analysis method: [LSP-enhanced analysis | text-based pattern matching]`
  - This matches the skill's Output Signaling section exactly

- [x] **VERIFY**: Output Format contains the signaling line with both options indicated

---

## Behavior 8: Output format structure and categorization unchanged

**Given** the existing output format uses `## Structural Coupling Review`, `### Working Well`, `### Findings`, and `Critical/Suggestion/Nitpick` categorization
**When** all changes are applied
**Then** these structural elements remain exactly as they were

- [x] **VERIFY**: Output Format still contains `## Structural Coupling Review`, `### Working Well`, `### Findings`, and `Critical/Suggestion/Nitpick`
  - Read the full Output Format section and compare structure against the original

---

## Edge Cases (Low Risk)

### Fallback consistency check
- [x] **VERIFY**: Every step that gained an LSP path (Steps 1, 2, 3, 5) also has explicit fallback language
  - Grep for "fallback" or "LSP is not available" or "If LSP" -- expect matches in Steps 1, 2, 3, and 5

### No changes to unrelated sections
- [x] **VERIFY**: Step 4 (Change Amplifiers) and Step 6 (Categorize) are unchanged
  - These steps have no LSP enhancement in the spec -- confirm they remain as-is

### Rules section unchanged
- [x] **VERIFY**: Rules section still contains all original rules (read-only, no sub-agents, coupling guidance)

---

## Final Check

- [x] **Read the full file**: `bee/agents/review-coupling.md` top to bottom
- [x] **Frontmatter**: tools line includes Read, Glob, Grep + LSP tools
- [x] **Skills**: references both code-review and lsp-analysis skills
- [x] **Step 1**: availability check + find-references + grep fallback
- [x] **Step 2**: find-references for consumer counting + grep fallback
- [x] **Step 3**: call-hierarchy outgoing + grep fallback
- [x] **Step 4**: unchanged
- [x] **Step 5**: find-references for boundary detection + grep fallback
- [x] **Step 6**: unchanged
- [x] **Output Format**: signaling line added, structure preserved
- [x] **Rules**: unchanged

## Verification Summary
| Category | # Checks | Status |
|----------|----------|--------|
| Core behaviors (1-8) | 8 | ✅ |
| Edge cases | 3 | ✅ |
| Final check | 11 | ✅ |
| **Total** | **22** | ✅ |

[x] Reviewed
