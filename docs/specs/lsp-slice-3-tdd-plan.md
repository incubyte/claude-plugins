# TDD Plan: LSP-Enhanced context-gatherer + domain-language-extractor -- Slice 3

## Execution Instructions
Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] -> [x]).
Continue until all items are done.
If stuck after 3 attempts, mark with a warning and move to the next independent step.

## Context
- **Source**: `docs/specs/lsp-integration-spec.md`, Slice 3
- **Slice**: context-gatherer and domain-language-extractor get LSP-enhanced analysis
- **Risk**: LOW
- **Nature**: Markdown-only edits to two existing agent files. No runtime code.
- **Acceptance Criteria**:
  1. `context-gatherer.md` references the skill in its Skills section
  2. context-gatherer uses document-symbols and workspace-symbols for language-aware module detection instead of relying solely on folder names
  3. `domain-language-extractor.md` references the skill in its Skills section
  4. domain-language-extractor Step 3 (Infer Vocabulary from Code): uses hover for type definitions and document-symbols for interface/type names
  5. Both agents retain grep-based fallback for each LSP-enhanced step
  6. Both agents include the signaling note in output

## Codebase Analysis

### File Structure
- Implementation: `bee/agents/context-gatherer.md` and `bee/agents/domain-language-extractor.md`
- Skill reference: `bee/skills/lsp-analysis/SKILL.md` (already exists from Slice 0)
- Pattern reference: `bee/agents/review-coupling.md` (Slice 1), `bee/agents/review-tests.md` and `bee/agents/qc-planner.md` (Slice 2) -- already updated with LSP
- No runtime tests -- all deliverables are markdown agent files

### Verification Method
Since this is a markdown-only change, each "test" is a structural verification: grep or read the file and confirm the expected content exists. The RED phase describes what to look for that does NOT yet exist. The GREEN phase adds it. The verification confirms it.

### Current File Structure (context-gatherer.md)
- Frontmatter: `tools: Read, Glob, Grep`
- No formal Skills section -- inline instruction on line 12 references clean-code and architecture-patterns skills
- Process: Sections 1-8 (Project Structure, Architecture Pattern, Test Framework, Project Conventions, Change Area, Existing Documentation, Tidy Opportunities, Design System Signals)
- Output Format: markdown template with Context Summary subsections
- No Rules section

### Current File Structure (domain-language-extractor.md)
- Frontmatter: `tools: Read, Glob, Grep, WebFetch`
- Skills section: references `skills/architecture-patterns/SKILL.md` and `skills/clean-code/SKILL.md`
- Process: Steps 1-4 (Extract from Documentation, Extract from Website, Infer from Code, Compare Against Code)
- Output Format: markdown template with Domain Language Analysis subsections
- Rules: read-only, no sub-agents, AskUserQuestion sparingly, always produce output, record sources, lead with healthy boundaries

---

## Behavior 1: Create formal Skills section in context-gatherer and add all skill references

**Given** context-gatherer has no formal Skills section, just an inline instruction referencing clean-code and architecture-patterns
**When** the agent file is updated
**Then** a formal Skills section exists referencing clean-code, architecture-patterns, AND lsp-analysis, and the inline instruction is replaced

- [x] **RED**: Verify `bee/agents/context-gatherer.md` does NOT contain `lsp-analysis/SKILL.md`
  - Grep for `lsp-analysis` in the file -- expect zero matches
  - Also note: the inline skill reference on line 12 is not in a formal `## Skills` section

- [x] **GREEN**: Replace the inline instruction with a formal Skills section
  - Remove the inline instruction line: "Read the `clean-code` skill at `skills/clean-code/SKILL.md` and the `architecture-patterns` skill at `skills/architecture-patterns/SKILL.md` -- these inform what you look for during analysis."
  - Add a `## Skills` section after the opening paragraph ("You are a codebase analyst...") with three bullets:
    - `skills/clean-code/SKILL.md` -- clean code principles, naming, SRP
    - `skills/architecture-patterns/SKILL.md` -- architecture pattern recognition
    - `skills/lsp-analysis/SKILL.md` -- LSP-enhanced analysis, availability checking, graceful degradation
  - Keep the instruction to read them: "Before starting, read these skill files for reference:"

- [x] **VERIFY**: Grep for `## Skills` in the file -- expect one match. Grep for `lsp-analysis/SKILL.md` -- expect one match. Grep for the old inline instruction text -- expect zero matches.

---

## Behavior 2: LSP tools added to context-gatherer frontmatter

**Given** the context-gatherer frontmatter has `tools: Read, Glob, Grep`
**When** the agent file is updated
**Then** the frontmatter includes LSP tools alongside the existing ones

- [x] **RED**: Verify frontmatter `tools:` line does NOT contain any LSP tool names

- [x] **GREEN**: Update the `tools:` line in the frontmatter
  - Change to: `tools: Read, Glob, Grep, mcp__lsp__document-symbols, mcp__lsp__workspace-symbols`
  - Only the tools context-gatherer actually uses: document-symbols (for structural scan + availability check) and workspace-symbols (for architecture marker search)

- [x] **VERIFY**: The `tools:` line contains Read, Glob, Grep and the two LSP tools

---

## Behavior 3: context-gatherer Section 2 gets LSP-first path for architecture detection

**Given** Section 2 (Architecture Pattern) currently only looks for evidence via folder names
**When** the agent file is updated
**Then** Section 2 first performs the availability check, then uses document-symbols and workspace-symbols for language-aware module detection, with the original folder-name approach as fallback

- [x] **RED**: Verify Section 2 has no mention of LSP, `document-symbols`, or `workspace-symbols`

- [x] **GREEN**: Rewrite Section 2 to add LSP-first path
  - Add availability check at the top of Section 2: attempt `document-symbols` on one source file; if it returns symbols, LSP is available for this section. Decide once; do not retry if it fails.
  - Add LSP path: use `document-symbols` on key source files to find classes, interfaces, and types that reveal architecture (e.g., finding a class named `OrderController` or an interface named `OrderPort` is stronger evidence than a folder named `controllers/`). Use `workspace-symbols` to search for architectural markers: Controller, Service, Repository, Port, Adapter, Handler, UseCase, Gateway, etc. This detects architecture from actual code structure, not just folder conventions.
  - Keep the existing folder-name evidence list as the explicit fallback under a "Fallback (LSP unavailable)" sub-section -- the full list of directory patterns (domain/, ports/, controllers/, events/, commands/, etc.)
  - Preserve the opening instruction and the "Describe what you actually found" guidance

- [x] **VERIFY**: Section 2 contains `document-symbols` (availability check + structural scan), `workspace-symbols` (architecture marker search), and retains the full folder-name evidence list as fallback

---

## Behavior 4: context-gatherer output format includes signaling note

**Given** the Output Format section has no mention of analysis method signaling
**When** the agent file is updated
**Then** the output template includes the signaling line from the skill

- [x] **RED**: Verify Output Format section has no mention of "Analysis method"

- [x] **GREEN**: Add signaling to the Output Format template
  - Add a line after `## Context Summary` and before `### Project Structure`: `Analysis method: [LSP-enhanced analysis | text-based pattern matching]`

- [x] **VERIFY**: Output Format contains the signaling line with both options indicated

---

## Behavior 5: Skill reference added to domain-language-extractor Skills section

**Given** the domain-language-extractor Skills section references architecture-patterns and clean-code
**When** the agent file is updated
**Then** the Skills section also references `skills/lsp-analysis/SKILL.md`

- [x] **RED**: Verify `bee/agents/domain-language-extractor.md` does NOT contain `lsp-analysis/SKILL.md`
  - Grep for `lsp-analysis` in the file -- expect zero matches

- [x] **GREEN**: Add the skill reference
  - In the Skills section, add a third bullet: `- \`skills/lsp-analysis/SKILL.md\` -- LSP-enhanced analysis, availability checking, graceful degradation`
  - Keep the existing architecture-patterns and clean-code skill references unchanged

- [x] **VERIFY**: Grep for `lsp-analysis/SKILL.md` in the file -- expect one match in the Skills section

---

## Behavior 6: LSP tools added to domain-language-extractor frontmatter

**Given** the domain-language-extractor frontmatter has `tools: Read, Glob, Grep, WebFetch`
**When** the agent file is updated
**Then** the frontmatter includes LSP tools alongside the existing ones

- [x] **RED**: Verify frontmatter `tools:` line does NOT contain any LSP tool names

- [x] **GREEN**: Update the `tools:` line in the frontmatter
  - Change to: `tools: Read, Glob, Grep, WebFetch, mcp__lsp__document-symbols, mcp__lsp__hover`
  - Keep WebFetch (domain-language-extractor needs it for website analysis)
  - Only the tools this agent actually uses: document-symbols (for interface/type names + availability check) and hover (for type definitions)

- [x] **VERIFY**: The `tools:` line contains Read, Glob, Grep, WebFetch and the two LSP tools

---

## Behavior 7: domain-language-extractor Step 3 gets LSP-first path for vocabulary extraction

**Given** Step 3 (Infer Vocabulary from Code) currently uses Glob for directory names and Grep for class/module/function declarations
**When** the agent file is updated
**Then** Step 3 first performs the availability check, then uses document-symbols for interface/type names and hover for type definitions, with the original approach as fallback

- [x] **RED**: Verify Step 3 has no mention of LSP, `document-symbols`, or `hover`

- [x] **GREEN**: Rewrite Step 3 to add LSP-first path
  - Add availability check at the top of Step 3: attempt `document-symbols` on one source file; if it returns symbols, LSP is available for this step. Decide once; do not retry if it fails.
  - Add LSP path: use `document-symbols` on key source files to extract interface names, type aliases, class names, and enum values -- these are domain vocabulary expressed in code. Use `hover` on key symbols to get type definitions, which reveal domain relationships (e.g., hovering over `order.shipment` reveals whether Shipment is its own type or just a string field). This produces richer vocabulary than directory names and grep patterns alone.
  - Keep the existing approach as the explicit fallback under a "Fallback (LSP unavailable)" sub-section -- the four existing bullets about Glob for directories, reading directory names, Grep for declarations, and looking for naming patterns
  - Preserve the closing instruction about recording each code-derived concept with its source

- [x] **VERIFY**: Step 3 contains `document-symbols` (availability check + interface/type extraction), `hover` (type definitions), and retains all four original bullets as fallback

---

## Behavior 8: domain-language-extractor output format includes signaling note

**Given** the Output Format section has no mention of analysis method signaling
**When** the agent file is updated
**Then** the output template includes the signaling line from the skill

- [x] **RED**: Verify Output Format section has no mention of "Analysis method"

- [x] **GREEN**: Add signaling to the Output Format template
  - Add a line after `## Domain Language Analysis` and before `### Domain Vocabulary`: `Analysis method: [LSP-enhanced analysis | text-based pattern matching]`

- [x] **VERIFY**: Output Format contains the signaling line with both options indicated

---

## Edge Cases (Low Risk)

### Fallback consistency check -- context-gatherer
- [x] **VERIFY**: Section 2 of context-gatherer has explicit fallback language
  - Grep for "fallback" or "LSP unavailable" or "LSP is not available" in context-gatherer.md -- expect at least one match in Section 2

### Fallback consistency check -- domain-language-extractor
- [x] **VERIFY**: Step 3 of domain-language-extractor has explicit fallback language
  - Grep for "fallback" or "LSP unavailable" or "LSP is not available" in domain-language-extractor.md -- expect at least one match in Step 3

### No changes to unrelated sections -- context-gatherer
- [x] **VERIFY**: Sections 1, 3-8 of context-gatherer are unchanged
  - These sections have no LSP enhancement in the spec -- confirm they remain as-is by reading the file

### No changes to unrelated steps -- domain-language-extractor
- [x] **VERIFY**: Steps 1, 2, 4 of domain-language-extractor are unchanged
  - These steps have no LSP enhancement in the spec -- confirm they remain as-is by reading the file

### Rules section unchanged -- domain-language-extractor
- [x] **VERIFY**: Rules section of domain-language-extractor still contains all original rules (read-only, no sub-agents, AskUserQuestion sparingly, always produce output, record sources, lead with healthy boundaries)

---

## Final Check

- [x] **Read the full file**: `bee/agents/context-gatherer.md` top to bottom
- [x] **Frontmatter**: tools line includes Read, Glob, Grep + document-symbols + workspace-symbols
- [x] **Skills**: formal section referencing clean-code, architecture-patterns, and lsp-analysis
- [x] **Inline instruction removed**: the old inline skill reference line is gone
- [x] **Section 1**: unchanged
- [x] **Section 2**: availability check + document-symbols for structural scan + workspace-symbols for architecture markers + folder-name fallback
- [x] **Sections 3-8**: unchanged
- [x] **Output Format**: signaling line added, structure preserved

- [x] **Read the full file**: `bee/agents/domain-language-extractor.md` top to bottom
- [x] **Frontmatter**: tools line includes Read, Glob, Grep, WebFetch + document-symbols + hover
- [x] **Skills**: references architecture-patterns, clean-code, and lsp-analysis
- [x] **Steps 1-2**: unchanged
- [x] **Step 3**: availability check + document-symbols for interface/type names + hover for type definitions + original approach as fallback
- [x] **Step 4**: unchanged
- [x] **Output Format**: signaling line added, structure preserved
- [x] **Rules**: unchanged

## Verification Summary
| Category | # Checks | Status |
|----------|----------|--------|
| Core behaviors (1-8) | 8 | ✅ |
| Edge cases | 5 | ✅ |
| Final check | 16 | ✅ |
| **Total** | **29** | ✅ |

[x] Reviewed
