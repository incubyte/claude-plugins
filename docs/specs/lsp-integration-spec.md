# Spec: LSP-Enhanced Analysis

## Overview

Add an `lsp-analysis` skill that teaches any Bee agent to use Claude Code's built-in LSP operations for precise dependency analysis, with graceful degradation to grep when LSP is unavailable. Then integrate the skill into each code-analysis agent incrementally.

All changes are markdown-only. Bee stays pure-markdown -- no runtime code.

## Slice 0: LSP Analysis Skill

Create `bee/skills/lsp-analysis/SKILL.md` -- the shared reference for all code-analysis agents.

- [x]Skill file exists at `bee/skills/lsp-analysis/SKILL.md` with standard frontmatter (name, description)
- [x]Documents available LSP operations: find-references, call-hierarchy (incoming + outgoing), go-to-definition, hover, document-symbols, workspace-symbols
- [x]Describes when to use each operation (find-references for dependency mapping, call-hierarchy for transitive depth, hover for type info, document-symbols for module structure)
- [x]Defines the availability check pattern: attempt a lightweight LSP operation early in analysis; if it fails, fall back to grep for the rest
- [x]Defines the graceful degradation pattern: fall back silently to grep/glob, add a note in output telling the user which language server to explore
- [x]Defines output signaling: "LSP-enhanced analysis" when LSP was used, "text-based pattern matching" when it was not
- [x]Includes a per-language reference table mapping languages to LSP server names (typescript-language-server, jdtls, gopls, pyright, rust-analyzer, clangd, solargraph, etc.)
- [x]Includes a "Graph Reasoning" section teaching agents how to use LSP data as a knowledge graph — LSP responses are graph edges not search results, build the graph then reason over it, use transitivity (follow call chains, don't stop at direct callers), quantify coupling by counting references, blast radius = incomingCalls depth, testability = outgoingCalls depth
- [x]Does not include .mcp.json configuration snippets -- names only

## Slice 1: review-coupling (walking skeleton)

Update `bee/agents/review-coupling.md` to reference the skill and use LSP when available.

- [x]Agent references `skills/lsp-analysis/SKILL.md` in its Skills section
- [x]Agent lists LSP tools in its frontmatter tools list (alongside Read, Glob, Grep)
- [x]Step 1 (Map Dependencies): before grepping imports, follows the skill's availability check; if LSP responds, uses find-references on key exports to build the dependency graph
- [x]Step 2 (Afferent Coupling): uses find-references to count actual consumers of a module's exports, not just files that import it
- [x]Step 3 (Efferent Coupling): uses call-hierarchy (outgoing) to map transitive dependencies through shared abstractions
- [x]Step 5 (Boundary Violations): uses find-references to detect cross-boundary calls that grep misses
- [x]Each step retains the existing grep-based approach as the fallback when LSP is unavailable
- [x]Output format is unchanged -- same markdown structure, same categorization (Critical/Suggestion/Nitpick)
- [x]Output includes the skill's signaling note indicating whether LSP or text-based matching was used

## Slice 2: review-tests + qc-planner

Update both agents to reference the skill and use LSP for test coverage and testability assessment.

- [x]`review-tests.md` references `skills/lsp-analysis/SKILL.md` in its Skills section
- [x]review-tests Step 5 (Coverage Gaps): uses find-references from test files back to source to detect which public functions have zero test references
- [x]`qc-planner.md` references `skills/lsp-analysis/SKILL.md` in its Skills section
- [x]qc-planner Step 3 (Assess Testability): uses call-hierarchy (outgoing) to measure dependency chain depth when judging whether something is a low-hanging fruit
- [x]Both agents retain grep-based fallback for each LSP-enhanced step
- [x]Both agents include the LSP/text-based signaling note in output

## Slice 3: context-gatherer + domain-language-extractor

Update both agents to use LSP for structural understanding and vocabulary extraction.

- [x]`context-gatherer.md` references the skill in its Skills section
- [x]context-gatherer uses document-symbols and workspace-symbols for language-aware module detection instead of relying solely on folder names
- [x]`domain-language-extractor.md` references the skill in its Skills section
- [x]domain-language-extractor Step 3 (Infer Vocabulary from Code): uses hover for type definitions and document-symbols for interface/type names
- [x]Both agents retain grep-based fallback
- [x]Both agents include the signaling note in output

## Slice 4: architecture-test-writer

Update the agent to use LSP for boundary validation.

- [x]`architecture-test-writer.md` references the skill in its Skills section
- [x]Steps 3-4 (Generate Passing/Failing Tests): uses find-references to validate boundary assertions with real dependency data instead of grep for import statements
- [x]Retains grep-based fallback
- [x]Includes the signaling note in output

## Slice 5: review-code-quality

Update the agent to use LSP for type-aware quality analysis.

- [x]`review-code-quality.md` references the skill in its Skills section
- [x]Step 2 (Review Each File): uses hover for type information when assessing complexity, and LSP diagnostics for compiler-level warnings
- [x]Retains grep-based fallback
- [x]Includes the signaling note in output

## Out of Scope

- Building or adopting MCP-LSP bridge servers
- Adding runtime code to Bee
- Tree-sitter integration
- Language server installation or management
- Interactive LSP setup wizard
- .mcp.json configuration examples in the skill
- Modifying LSP tool behavior in Claude Code itself

## Technical Context

- **Patterns to follow**: existing skill format (see `bee/skills/clean-code/SKILL.md` for structure); existing agent format with frontmatter, Skills section, Process steps, Output Format, Rules
- **Key dependencies**: Claude Code built-in LSP (find-references ~50ms/query, call-hierarchy confirmed available, hover, document-symbols, workspace-symbols)
- **Integration point**: each agent already has a Skills section where references are added, and a Process section where steps get the LSP-first-then-grep pattern
- **Risk level**: LOW -- all changes are markdown instruction edits to existing files, plus one new skill file

[x] Reviewed
