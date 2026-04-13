# TDD Plan: LSP Analysis Skill -- Slice 0

## Execution Instructions
Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] -> [x]).
Continue until all items are done.
If stuck after 3 attempts, mark a warning and move to the next independent step.

## Context
- **Source**: `docs/specs/lsp-integration-spec.md`
- **Slice**: Slice 0 -- LSP Analysis Skill
- **Risk**: LOW
- **Nature**: Markdown-only skill file. No runtime code. Each "behavior" is a verifiable section of content.

## Codebase Analysis

### File Structure
- Implementation: `bee/skills/lsp-analysis/SKILL.md` (new file)
- Tests: Manual verification -- content checks against ACs
- Related files: All existing skills follow the same pattern (frontmatter + H1 + H2 sections)

### Existing Skill Pattern
Every skill file has:
1. YAML frontmatter with `name` and `description`
2. An H1 title matching the skill's purpose
3. H2 sections for each concept area
4. Actionable, prescriptive prose (tells the agent what to do)
5. No code blocks unless demonstrating code patterns

### Verification Method
Since this is markdown, "RED" means writing a content requirement, "GREEN" means writing the content that satisfies it, and "REFACTOR" means tightening the prose. Each step's pass/fail is verified by reading the file and confirming the AC is met.

---

## Behavior 1: Skill file exists with standard frontmatter

**Given** the skill directory `bee/skills/lsp-analysis/` does not exist
**When** we create `SKILL.md`
**Then** the file has YAML frontmatter with `name: lsp-analysis` and a `description` field, plus an H1 title

- [x] **RED**: Confirm `bee/skills/lsp-analysis/SKILL.md` does not exist
- [x] **GREEN**: Create the file with frontmatter and H1 title
  - `name: lsp-analysis`
  - `description`: one-line summary of what the skill teaches agents
  - H1: something like "LSP-Enhanced Analysis"
  - Follow the exact frontmatter format from `bee/skills/clean-code/SKILL.md`
- [x] **VERIFY**: File exists, frontmatter parses correctly, H1 is present

---

## Behavior 2: Documents available LSP operations

**Given** the skill file exists with frontmatter
**When** we add the operations reference section
**Then** it lists all six LSP operations with a brief description of each

- [x] **RED**: Confirm no LSP operations section exists yet
- [x] **GREEN**: Add an H2 section listing each operation with a one-line description:
  - `find-references` -- find all usages of a symbol across the workspace
  - `call-hierarchy` (incoming) -- who calls this function
  - `call-hierarchy` (outgoing) -- what does this function call
  - `go-to-definition` -- jump to where a symbol is defined
  - `hover` -- get type information and documentation for a symbol
  - `document-symbols` -- list all symbols in a file (functions, classes, interfaces)
  - `workspace-symbols` -- search for symbols across the entire workspace
- [x] **VERIFY**: All six operations (with call-hierarchy split into incoming/outgoing) are documented
- [x] **REFACTOR**: Ensure descriptions are concise and action-oriented

---

## Behavior 3: Describes when to use each operation

**Given** the operations are listed
**When** we add usage guidance
**Then** each operation has a "when to use" context mapped to analysis tasks

- [x] **RED**: Confirm no usage guidance exists yet
- [x] **GREEN**: Add an H2 section (or extend the operations section) with guidance:
  - `find-references` -- dependency mapping, counting consumers of exports, detecting cross-boundary calls
  - `call-hierarchy` (incoming) -- understanding who depends on a function, afferent coupling
  - `call-hierarchy` (outgoing) -- transitive dependency depth, efferent coupling
  - `go-to-definition` -- resolving what an imported symbol actually is
  - `hover` -- type info for complexity assessment, understanding interfaces without reading source
  - `document-symbols` -- module structure overview, listing exports
  - `workspace-symbols` -- finding types/interfaces by name across the codebase
- [x] **VERIFY**: Each operation has clear "use this when..." guidance
- [x] **REFACTOR**: Remove any overlap or redundancy between operation descriptions and usage guidance -- consider combining into a single reference if cleaner

---

## Behavior 4: Graph reasoning guidance

**Given** the operations and usage guidance exist
**When** we add graph reasoning guidance
**Then** agents understand that LSP data is a knowledge graph, not search results, and know how to reason over it

- [x] **RED**: Confirm no graph reasoning section exists yet
- [x] **GREEN**: Add an H2 section teaching agents the mental model:
  - LSP responses are **graph edges**, not search results. Each findReferences call returns edges in a dependency graph. Build the graph, then reason over it.
  - **Transitivity**: don't stop at direct callers/callees. Use call-hierarchy to follow chains. A → B → C means A depends on C.
  - **Completeness**: findReferences returns ALL usages, not a sample. Count them. "3 callers" vs "47 callers" is the difference between loosely and tightly coupled.
  - **Quantify coupling**: fan-in (incomingCalls count) = how many things depend on this. Fan-out (outgoingCalls count) = how many things this depends on.
  - **Blast radius** = incomingCalls depth. How far does a change propagate?
  - **Testability** = outgoingCalls depth. How many things must be mocked/stubbed to test in isolation?
  - Contrast with grep: grep finds text matches, LSP finds semantic connections. Grep misses re-exports, aliased imports, inherited methods, framework injection.
- [x] **VERIFY**: An agent reading this section would reason over LSP data as a graph, not use findReferences like a fancy grep
- [x] **REFACTOR**: Keep it concise — this is a mental model, not a tutorial

---

## Behavior 5: Defines the availability check pattern

**Given** the operations, usage guidance, and graph reasoning guidance exist
**When** we add the availability check pattern
**Then** agents know to attempt a lightweight LSP call early and branch based on success/failure

- [x] **RED**: Confirm no availability check pattern exists yet
- [x] **GREEN**: Add an H2 section defining the pattern:
  - Early in analysis, attempt one lightweight LSP operation (e.g., `document-symbols` on the target file)
  - If it succeeds: LSP is available, use LSP operations for the rest of the analysis
  - If it fails: LSP is not available, fall back to grep/glob for the rest
  - Key point: decide once at the start, not per-operation (avoids repeated failures)
- [x] **VERIFY**: Pattern is clear enough that an agent can follow it mechanically

---

## Behavior 6: Defines the graceful degradation pattern

**Given** the availability check pattern exists
**When** we add the degradation pattern
**Then** agents know to fall back silently and inform the user about language server options

- [x] **RED**: Confirm no degradation section exists yet
- [x] **GREEN**: Add an H2 section (or subsection) defining:
  - Fall back silently -- do not error, do not warn during analysis
  - Use grep/glob as the fallback for every LSP-enhanced step
  - At the end of output, add a note telling the user which language server they could install for better results
  - Reference the per-language table (Behavior 7) for the server name
- [x] **VERIFY**: Degradation is silent during analysis, informative at the end

---

## Behavior 7: Defines output signaling

**Given** the degradation pattern exists
**When** we add output signaling
**Then** agents know the exact phrases to include in their output

- [x] **RED**: Confirm no output signaling section exists yet
- [x] **GREEN**: Add a section defining the two signal phrases:
  - When LSP was used: include "LSP-enhanced analysis" in the output
  - When LSP was not available: include "text-based pattern matching" in the output
  - Specify where in the output this goes (e.g., a note at the top or bottom of the analysis)
- [x] **VERIFY**: Both exact phrases are documented, placement is clear

---

## Behavior 8: Per-language reference table

**Given** all patterns are defined
**When** we add the language server reference
**Then** a table maps languages to their LSP server names

- [x] **RED**: Confirm no language table exists yet
- [x] **GREEN**: Add an H2 section with a markdown table:
  - TypeScript/JavaScript -> typescript-language-server
  - Java -> jdtls
  - Go -> gopls
  - Python -> pyright
  - Rust -> rust-analyzer
  - C/C++ -> clangd
  - Ruby -> solargraph
  - (Add 2-3 more common ones if appropriate: C# -> omnisharp, Kotlin -> kotlin-language-server, etc.)
- [x] **VERIFY**: Table is present, maps languages to server names only (no config snippets)

---

## Behavior 9: No .mcp.json configuration snippets

**Given** the complete skill file
**When** we review the entire content
**Then** there are zero .mcp.json examples, zero configuration snippets -- server names only

- [x] **RED**: Search the file for `.mcp.json`, `configuration`, JSON code blocks
- [x] **VERIFY**: None found. The file references server names but never shows how to configure them.

---

## Final Check

- [x] **Read the complete file top to bottom**: Does it flow logically? (operations -> when to use -> graph reasoning -> check pattern -> degradation -> signaling -> language table)
- [x] **Check against all 9 ACs from the spec**: Each one is satisfied
- [x] **Check tone**: Prescriptive and actionable, matching the style of existing skills (clean-code, tdd-practices)
- [x] **Check length**: Concise -- no padding, no repetition. A skill file should be a quick reference, not a tutorial.

## Verification Summary
| AC | Description | Verified |
|----|-------------|----------|
| 1 | Skill file exists with standard frontmatter | ✅ |
| 2 | Documents all LSP operations | ✅ |
| 3 | Describes when to use each operation | ✅ |
| 4 | Graph reasoning guidance | ✅ |
| 5 | Availability check pattern | ✅ |
| 6 | Graceful degradation pattern | ✅ |
| 7 | Output signaling phrases | ✅ |
| 8 | Per-language reference table | ✅ |
| 9 | No .mcp.json config snippets | ✅ |

[x] Reviewed
