---
name: lsp-analysis
description: "This skill should be used when performing precise dependency analysis with LSP tools. Contains availability checking, graph reasoning, and graceful degradation."
---

# LSP-Enhanced Analysis

Claude Code provides built-in LSP (Language Server Protocol) tools that give you semantic code understanding — actual dependency graphs instead of text pattern matching. When LSP is available, use it. When it's not, fall back to grep/glob silently.

This skill applies to any agent that performs code analysis — coupling, test coverage, architecture boundaries, migration scoping, or structural understanding.

---

## LSP Operations

| Operation | What it does | Use it for |
|-----------|-------------|------------|
| `find-references` | Find all usages of a symbol across the workspace | Dependency mapping, counting consumers of exports, detecting cross-boundary calls |
| `call-hierarchy` (incoming) | Find all functions that call the target function | Afferent coupling — who depends on this? Blast radius of a change |
| `call-hierarchy` (outgoing) | Find all functions the target function calls | Efferent coupling — what does this depend on? Transitive dependency depth |
| `go-to-definition` | Jump to where a symbol is defined | Resolving what an imported symbol actually is, following re-exports |
| `hover` | Get type information and documentation for a symbol | Type info for complexity assessment, understanding interfaces without reading source |
| `document-symbols` | List all symbols in a file (functions, classes, interfaces) | Module structure overview, listing exports, quick structural scan |
| `workspace-symbols` | Search for symbols by name across the entire workspace | Finding types, interfaces, or classes by name across the codebase |

---

## Graph Reasoning

LSP responses are **graph edges**, not search results. Each `find-references` call returns edges in a dependency graph. Each `call-hierarchy` call returns paths through that graph. Build the graph, then reason over it.

**Transitivity.** Don't stop at direct callers or callees. Use call-hierarchy to follow chains. If A calls B and B calls C, then A depends on C. Grep only shows you A→B and B→C as separate matches — LSP gives you the chain directly.

**Completeness.** `find-references` returns ALL usages, not a sample. Count them. "3 callers" vs "47 callers" is the difference between loosely coupled and tightly coupled. Grep misses re-exports, aliased imports, inherited methods, and framework-injected references.

**Quantify coupling with fan-in and fan-out.**
- Fan-in = incomingCalls count. How many things depend on this symbol? High fan-in means changes here propagate widely.
- Fan-out = outgoingCalls count. How many things does this symbol depend on? High fan-out means this is fragile — many reasons for it to break.

**Blast radius** = incomingCalls depth. How far does a change propagate through the call graph? A function with 3 direct callers might have 50 transitive dependents.

**Testability** = outgoingCalls depth. How many things must be mocked or stubbed to test this in isolation? A function with 1 import but 15 transitive outgoing calls is not a low-hanging fruit for unit testing.

**Why this matters more than grep.** Grep finds text matches. LSP finds semantic connections. Grep misses:
- Re-exported symbols used under a different name
- Inherited methods called on a subclass
- Framework-injected dependencies (decorators, annotations, DI containers)
- Dynamic dispatch through interfaces or abstract classes

When you have LSP data, reason over the graph structure. When you don't, acknowledge that grep-based analysis is an approximation.

---

## Availability Check

Check LSP availability once at the start of your analysis, not per-operation.

1. Early in your analysis, attempt `document-symbols` on one of the target files.
2. If it returns symbols: LSP is available. Use LSP operations for the rest of your analysis.
3. If it fails or returns nothing: LSP is not available. Use grep/glob for all analysis steps.

Decide once. Don't retry LSP after it fails — repeated failures waste time and add noise. Set a flag and move on.

---

## Graceful Degradation

When LSP is not available:

- **Do not error.** Do not warn during analysis. Fall back silently to grep/glob — the same analysis the agent did before LSP existed.
- **Every LSP-enhanced step must have a grep fallback.** If the agent used `find-references` for dependency mapping, the fallback is `Grep` for import/require patterns. If it used `call-hierarchy` for coupling depth, the fallback is reading files and tracing calls manually.
- **Note at the end of output.** After the analysis is complete, add: "Note: LSP was not available for this analysis. Results use text-based pattern matching. For more accurate dependency analysis, consider configuring a language server — see the language server reference table below."
- **Reference the language table** so the developer knows which server to explore for their ecosystem.

---

## Output Signaling

Include one of these phrases in your analysis output so the developer knows the confidence level:

- **When LSP was used:** "Analysis method: LSP-enhanced analysis"
- **When LSP was not available:** "Analysis method: text-based pattern matching"

Place this near the top of the output, before the findings. This is a single line — not a paragraph, not a disclaimer.

---

## Language Server Reference

| Language | LSP Server |
|----------|-----------|
| TypeScript / JavaScript | typescript-language-server |
| Java | jdtls (Eclipse JDT Language Server) |
| Go | gopls |
| Python | pyright |
| Rust | rust-analyzer |
| C / C++ | clangd |
| Ruby | solargraph |
| C# | omnisharp |
| Kotlin | kotlin-language-server |
| PHP | intelephense |
| Swift | sourcekit-lsp |
