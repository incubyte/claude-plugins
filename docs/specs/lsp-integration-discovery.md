# Discovery: LSP-Enhanced Analysis Agents

## Why

Bee's analysis agents rely on grep and glob to understand code structure -- import patterns, dependency graphs, module boundaries. This works for surface-level analysis but produces inaccurate results when the real dependency picture is more complex than what text patterns reveal. When Bee says "this is a low-hanging fruit" and it turns out to be a dependency hell, developers stop trusting the recommendations. Accuracy is what upholds Bee's reputation. If recommendations are mostly wrong, people start ignoring them -- and then Bee is just noise.

Claude Code already has built-in LSP support (since v2.0.74) with go-to-definition, find-references, and hover documentation. Language server lifecycle is managed automatically. This means Bee can get precise dependency graphs without building infrastructure, adopting third-party servers, or adding runtime code. The agents just need updated instructions to use LSP tools when available.

## Who

<!-- -------- bee-comment -------- -->
> **@developer**: is there a way that instead of talking about specific command we make it more generic? either we can add it to skills, or rather say that whatever commands bee adds, if it involves code analysis, and if a LSP exists then it will use LSP and a knowledge graph, otherwise it will fallback, and tell it to the end user to explore the relevant lsp
> **@bee**: Reframed the entire approach. Instead of per-command LSP integration, this is now a **skill** (`bee/skills/lsp-analysis/SKILL.md`) that any agent doing code analysis can reference. The "Who" section now describes any Bee agent, not specific commands. The Design Philosophy and Milestone Map are updated to reflect the skill-first architecture — the skill defines when/how to use LSP, and agents just reference it like they reference `clean-code` or `tdd-practices`.
> - [x] mark as resolved
<!-- -------- /bee-comment -------- -->

**Any Bee agent that performs code analysis.** Today that's the agents behind `/bee:qc`, `/bee:review`, `/bee:architect`, and `/bee:migrate`. Tomorrow it's whatever new commands Bee adds. The LSP integration is a **skill** — shared reference knowledge at `bee/skills/lsp-analysis/SKILL.md` — not a per-command feature. Any agent that involves code analysis references this skill and gets LSP-enhanced accuracy automatically.

**Developers using Bee** -- they need recommendations they can trust. When Bee says "these modules are independent," that must be true. When it says "easy to unit test," it must actually be easy.

**Tech leads evaluating Bee** -- if early recommendations are wrong, trust is lost and adoption stalls. Accuracy on first contact matters disproportionately.

## Design Philosophy

This is an accuracy enhancement, not a feature addition. The agents already do the right analysis -- they just do it with imprecise tools. LSP gives them precise tools. The wingman philosophy applies: better data in, better recommendations out, same digestible output.

Bee stays pure-markdown. No runtime code, no MCP servers to build, no infrastructure to maintain. The LSP integration lives as a **skill** (`bee/skills/lsp-analysis/SKILL.md`) — the same pattern as `clean-code`, `tdd-practices`, and `code-review`. Any agent that does code analysis references this skill. The skill defines: which LSP operations to use, how to check availability, the graceful degradation pattern, and what to tell the end user about configuring a language server. Agents don't need to reinvent this — they just follow the skill.

When LSP is not available, agents fall back silently to grep-based analysis — the current behavior — with a note in the output suggesting the user explore the relevant LSP for their language.

## Success Criteria

- When LSP is available, the review-coupling agent produces dependency graphs that include indirect dependencies (call chains, type hierarchies) -- not just direct import statements
- Developers stop encountering "this looked simple but turned into a cascade" surprises from Bee's coupling analysis
- The QC planner's "low-hanging fruit" assessments reflect actual testability -- accounting for hidden dependencies, inherited methods, and framework-injected coupling
- Migration ordering recommendations account for indirect coupling, not just import-level dependencies
- When LSP is unavailable, every agent works exactly as it does today -- no regressions, no failures
- Agent output includes a clear signal about whether LSP was used, so developers understand the confidence level of the analysis

## Problem Statement

Bee's analysis agents use text-based pattern matching (grep for imports, glob for file structure) to build dependency graphs and assess code relationships. This approach has a fundamental blind spot: it sees what files say they import, but not what they actually depend on through call chains, type hierarchies, interface implementations, and framework-level coupling.

This blind spot causes three concrete problems:
1. **Coupling blindness** -- the coupling agent says "these modules are independent" when they share deep call chains through shared abstractions
2. **Hidden test dependencies** -- the QC planner says "easy to unit test" when the function depends on framework-injected services, inherited methods, or dynamic dispatch that makes isolation hard
3. **Wrong migration order** -- the migrate command says "move this module first, it has few dependencies" but misses indirect coupling, creating rework

All three trace to the same root cause: not knowing the real dependency graph. LSP provides that graph through find-references, call-hierarchy, and type information.

## Hypotheses

- H1: Claude Code's built-in LSP tools (find-references, call-hierarchy, hover) provide sufficient semantic precision to replace grep-based dependency analysis in the review-coupling agent -- no additional tooling needed.
- H2: Improving dependency graph accuracy in review-coupling will have a multiplier effect on QC and migrate, since both consume coupling data to make prioritization decisions.
- H3: The primary LSP operations needed across all agents are find-references and call-hierarchy. Go-to-definition and hover are useful but secondary.
- H4: Most projects that would benefit from LSP-enhanced analysis already have a language server available (TypeScript, Java, Python, Go all have mature LSP implementations) -- the barrier is .mcp.json configuration, not language server availability.
- H5: Silent degradation (fall back to grep, note in output) is sufficient -- developers do not need an interactive setup wizard for LSP configuration.

## Out of Scope

- Building or adopting MCP-LSP bridge servers -- Claude Code's built-in LSP support eliminates this need
- Adding runtime code to Bee -- the plugin stays pure-markdown
- Tree-sitter integration -- LSP provides the semantic precision we need; tree-sitter's structural analysis is a separate concern for potential future exploration
- Language server installation or management -- Bee uses whatever LSP is configured in .mcp.json; it does not install language servers
- Interactive LSP setup wizard -- if LSP is not configured, Bee notes it in output and continues with grep
- Modifying LSP tool behavior in Claude Code itself -- we consume LSP as a tool, we do not extend it

## Graceful Degradation Pattern

Every agent that uses LSP follows the same pattern:

1. **Check availability**: attempt an LSP operation early in the analysis (e.g., find-references on a known file)
2. **If available**: use LSP for dependency analysis, note "LSP-enhanced analysis" in output
3. **If unavailable**: fall back to current grep/glob approach with no behavior change
4. **Note in output**: "Note: LSP was not available for this analysis. Results use text-based pattern matching. For more accurate dependency analysis, configure a language server in .mcp.json."

This pattern is universal across all agents. LSP is an enhancement, never a requirement.

## Milestone Map

### Phase 0: Create the LSP analysis skill

Create `bee/skills/lsp-analysis/SKILL.md` — the shared reference that any code-analysis agent can draw on. This skill defines:

- **Available LSP operations**: find-references, call-hierarchy, go-to-definition, hover, document-symbols, workspace-symbols, diagnostics
- **When to use each**: find-references for dependency mapping, call-hierarchy for transitive dependency depth, hover for type information, document-symbols for module structure
- **Availability check pattern**: attempt a lightweight LSP operation early; if it fails, set a flag and use grep for the rest of the analysis
- **Graceful degradation**: fall back to grep/glob, add a note in output telling the user which language server to explore for their ecosystem
- **Output signaling**: "LSP-enhanced analysis" vs "text-based pattern matching" so developers know the confidence level
- **Per-language LSP recommendations**: a reference table mapping common languages to their LSP servers (typescript-language-server, jdtls, gopls, pyright, rust-analyzer, etc.) for the degradation note

**Done when:** the skill file exists and can be referenced by any agent. No agent changes yet.

### Phase 1: review-coupling references the skill (walking skeleton)

This is the highest-value, lowest-risk starting point. The review-coupling agent already has a clear "Map Dependencies" step that says "use Grep to find import patterns." LSP find-references is the direct upgrade.

**What changes in the agent instructions:**

- Add a reference to the `lsp-analysis` skill
- **Step 1 (Map Dependencies)**: before grepping for imports, follow the skill's availability check. If LSP responds, use find-references on key exports to build the dependency graph from actual reference data. If not, fall back to grep.
- **Step 2 (Afferent Coupling)**: use find-references to count actual consumers of a module's exports -- not just files that import it, but files that call its functions.
- **Step 3 (Efferent Coupling)**: use call-hierarchy (outgoing calls) to map what a module actually reaches into, including transitive dependencies through shared abstractions.
- **Step 5 (Boundary Violations)**: use find-references to detect cross-boundary calls that grep misses -- e.g., a domain function called from infrastructure through an intermediary.

**LSP operations used:**
- `find-references` -- who actually uses this symbol?
- `call-hierarchy` (outgoing) -- what does this function call, transitively?

**What stays the same:**
- Output format (unchanged -- same markdown structure)
- Categorization logic (Critical/Suggestion/Nitpick)
- The agent's role as a read-only analyst
- All grep-based analysis as the fallback path

**Done when:**
- review-coupling produces more accurate dependency graphs on a project with LSP configured vs the same project without
- The agent degrades gracefully when LSP is absent
- Output clearly signals whether LSP was used

### Phase 2: review-tests + QC planner (test accuracy)

Builds on Phase 1. The QC planner already consumes coupling data -- Phase 1 makes that data better. Phase 2 adds LSP awareness to the test agent directly.

- **review-tests**: use find-references from test files back to source to map actual test coverage. Detect which public functions have zero references from any test file. This makes "no tests" vs "partial tests" assessment precise instead of heuristic.
- **qc-planner**: when assessing testability ("is this a low-hanging fruit?"), use call-hierarchy to check how deep the dependency chain goes. A function that calls 3 other functions which each call 3 more is not a low-hanging fruit, even if it only has one direct import.

**LSP operations used:**
- `find-references` -- which source functions are referenced from test files?
- `call-hierarchy` (outgoing) -- how deep is the dependency chain for this function?

### Phase 3: context-gatherer + domain-language-extractor (structural understanding)

- **context-gatherer**: use document-symbols and workspace-symbols for language-aware module detection. Instead of inferring architecture from folder names, detect actual class hierarchies, interface implementations, and module exports.
- **domain-language-extractor**: use hover for type definitions and document-symbols for interface/type names. Vocabulary extraction from the actual type system instead of grepping for class declarations.

**LSP operations used:**
- `document-symbols` -- what symbols does this file export?
- `workspace-symbols` -- find symbols by name across the project
- `hover` -- get type information for a symbol

### Phase 4: architecture-test-writer (boundary validation)

- **architecture-test-writer**: use find-references to validate boundary assertions with real dependency data. When generating a test like "orders module should not import from payments internals," verify with find-references that the boundary actually holds (or doesn't), rather than relying on grep for import statements.

**LSP operations used:**
- `find-references` -- validate that no symbol from module A is referenced in module B

### Phase 5 (future): review-code-quality (diagnostics and type-aware quality)

- **review-code-quality**: use LSP diagnostics for compiler warnings/errors, hover for type information when assessing complexity. This is the least urgent enhancement -- the code quality agent's grep-based analysis is less affected by the dependency blind spot than the other agents.

**LSP operations used:**
- `hover` -- type information for complexity assessment
- Diagnostics -- compiler-level warnings the agent currently cannot see

## Open Questions

- Which specific LSP operations does Claude Code's built-in support expose? The discovery identified find-references, go-to-definition, and hover. Call-hierarchy support needs to be verified -- it is critical for Phase 1.
- How does Claude Code's LSP handle multi-language projects? Does each language need its own entry in .mcp.json, and do agents need to detect which language server to query for a given file?
- What is the latency profile of LSP operations within Claude Code? If find-references takes several seconds per symbol, agents may need to be selective about which symbols they query rather than querying everything.
- Should the graceful degradation note recommend specific language servers per ecosystem (e.g., "For TypeScript projects, configure typescript-language-server in .mcp.json")? Or keep it generic?
- How do we measure accuracy improvement? Is there a way to compare "grep-based dependency graph" vs "LSP-based dependency graph" on a real project to validate H1 before rolling out to all agents?

## Revised Assessment

Size: FEATURE -- Phase 1 is a markdown-only change to one agent (review-coupling). No runtime code, no infrastructure. Later phases follow the same pattern. The work is in writing precise agent instructions, not building systems.
Greenfield: no -- this enhances existing agents within an established plugin architecture.

[s] Reviewed
