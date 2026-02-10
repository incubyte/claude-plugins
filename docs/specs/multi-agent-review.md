# Spec: Multi-Agent Review

## Overview

Refactor `/bee:review` from a monolithic single-pass reviewer into an orchestrator that spawns 7 specialist review sub-agents in parallel. Each agent focuses on one review dimension, produces structured findings, and the orchestrator merges results into a unified review with deduplication and an improvement roadmap.

## Acceptance Criteria

### Orchestrator (commands/review.md)

- [x] Orchestrator determines scope from the user's natural language request (files, folders, modules, commits, PRs, "entire codebase") -- same scope interpretation as today
- [x] Orchestrator resolves scope into a concrete file list and git history range before spawning agents
- [x] When scope is ambiguous, orchestrator states its interpretation before proceeding
- [x] When scope matches no files, orchestrator reports this clearly and stops (no agents spawned)
- [x] Orchestrator spawns all 7 review agents in parallel, passing each the resolved scope (file list + git range)
- [x] Orchestrator collects results from all 7 agents after they complete
- [x] Orchestrator deduplicates findings when multiple agents flag the same file:line
- [x] Orchestrator merges agent outputs into the unified output format (see Output section)
- [x] Orchestrator generates the Improvement Roadmap by sorting all findings by impact-to-effort ratio
- [x] Orchestrator annotates Code Quality findings with hotspot data from Behavioral Analysis (e.g., "this SRP violation is in a hotspot file -- high priority")
- [x] When an agent produces no findings, its section is omitted from the final output
- [x] When an agent fails or times out, the orchestrator completes the review with the remaining agents and notes which dimension was skipped

### Agent 1: Behavioral Analysis (agents/review-behavioral.md)

- [x] Analyzes git log to produce change-frequency rankings for files in scope
- [x] Combines change frequency with complexity proxy (file size, nesting depth) to rank hotspots
- [x] Detects temporal coupling -- file pairs that consistently co-occur in commits, focusing on cross-directory pairs
- [x] Outputs a ranked hotspot list and a temporal coupling list, each with explanations of why the pattern matters
- [x] Scopes git analysis to the review target (respects author filters, date ranges, folder scope)
- [x] Gracefully skips when git history is sparse or absent, with an explanation

### Agent 2: Code Quality (agents/review-code-quality.md)

- [x] Reviews code against SRP, DRY, YAGNI, meaningful naming, small functions, error handling
- [x] Flags dependency direction violations (inner layers importing outer layers)
- [x] Identifies refactoring opportunities with specific suggestions (file, line, what to do)
- [x] Each finding is categorized as Critical, Suggestion, or Nitpick with an effort tag
- [x] Does its own lightweight file prioritization (e.g., larger files first) since it runs without hotspot data
- [x] References `skills/clean-code/SKILL.md` and `skills/architecture-patterns/SKILL.md`

### Agent 3: Test Quality (agents/review-tests.md)

- [x] Reviews test files for behavior-based vs implementation-coupled testing
- [x] Flags tests that would break on refactor (mocking internals, testing private methods)
- [x] Assesses test naming -- do test names read like requirements?
- [x] Checks test isolation -- tests should not depend on each other's state or execution order
- [x] Assesses coverage gaps -- are critical paths tested? Are edge cases covered?
- [x] Each finding is categorized as Critical, Suggestion, or Nitpick with an effort tag
- [x] When no test files are in scope, produces a finding noting the absence of tests
- [x] References `skills/tdd-practices/SKILL.md`

### Agent 4: Structural Coupling (agents/review-coupling.md)

- [x] Analyzes imports to identify high afferent coupling (many dependents) and high efferent coupling (many dependencies)
- [x] Identifies change amplifiers -- single logical changes that require touching many files
- [x] Flags cross-module dependencies that violate architectural boundaries
- [x] Suggests decoupling opportunities with specific recommendations
- [x] Each finding is categorized as Critical, Suggestion, or Nitpick with an effort tag
- [x] References `skills/code-review/SKILL.md`

### Agent 5: Team Practices (agents/review-team-practices.md)

- [x] Reviews recent commit messages (last ~50 in scope) for quality -- descriptive, explains WHY, not just WHAT
- [x] Produces stats: average message word count, percentage under 5 words, common anti-patterns
- [x] When GitHub remote is available, analyzes PR review quality via `gh` CLI -- ratio of substantive reviews vs rubber stamps
- [x] Gracefully skips PR analysis when `gh` is unavailable or remote is not GitHub
- [x] Frames findings as team health signals with specific improvement suggestions
- [x] References `skills/code-review/SKILL.md`

### Agent 6: Org Standards (agents/review-org-standards.md)

- [x] Reads the target project's CLAUDE.md (if it exists) to discover project-specific conventions and rules
- [x] Checks code in scope against those project-specific conventions
- [x] Flags deviations from stated project patterns (e.g., project says "use camelCase" but code uses snake_case)
- [x] Each finding references the specific CLAUDE.md rule being violated
- [x] When no CLAUDE.md exists in the target project, reports this and skips gracefully

### Agent 7: AI Ergonomics (agents/review-ai-ergonomics.md)

- [x] Assesses context window friendliness -- flags files that are excessively large for LLM consumption
- [x] Checks for explicit types and contracts vs implicit conventions that LLMs struggle with
- [x] Evaluates module boundaries -- are they self-documenting? Can an LLM understand the module's purpose from its structure?
- [x] Assesses test-as-spec quality -- do tests serve as readable specifications an LLM can use for context?
- [x] Reviews CLAUDE.md and docs quality for AI context -- is there enough project context for an LLM to work effectively?
- [x] Evaluates naming -- do names carry enough context to be understood without reading surrounding code?
- [x] Each finding is categorized as Critical, Suggestion, or Nitpick with an effort tag
- [x] References `skills/ai-ergonomics/SKILL.md`

### Unified Output Format

- [x] Final output follows the existing review format: Hotspots, Temporal Coupling, Critical, Suggestions, Nitpicks, Coupling & Enhancement, Team Practices, AI Ergonomics, Improvement Roadmap
- [x] Each finding includes: file:line (when applicable), what is wrong, WHY it matters, effort tag (quick win / moderate / significant)
- [x] Findings from multiple agents on the same file are grouped together when they overlap
- [x] Improvement Roadmap is sorted by impact-to-effort ratio across all agents' findings
- [x] Tone remains coaching-oriented -- lead with what is working well, explain WHY for every finding
- [x] Empty sections are omitted

### Sub-Agent Output Contract

- [x] Each agent produces markdown with findings in a consistent structure: category (Critical/Suggestion/Nitpick), location (file:line), description, WHY, effort tag
- [x] Each agent includes a brief "what is working well" section for positive observations
- [x] Agents do not spawn sub-agents (platform constraint)
- [x] Agents are read-only -- they do not modify any files

## API Shape

Orchestrator passes to each agent:

```
Scope context:
- files: [list of resolved file paths]
- git_range: "6 months ago..HEAD" (or specific commit range)
- author_filter: "Alice" (optional)
- project_root: "/path/to/project"
```

Each agent returns:

```
## [Agent Name] Review

### Working Well
- [positive observation]

### Findings
- **[Critical/Suggestion/Nitpick]** `file:line` — [description]. WHY: [explanation]. Effort: [quick win/moderate/significant]
```

## Out of Scope

- Changing what review dimensions exist (the 7 agents are fixed for this spec)
- Sequential dependencies between agents (all run in parallel, orchestrator enriches after)
- Configurable agent selection (e.g., "run only code quality and tests") -- all 7 always run
- Caching or incremental review (reviewing only what changed since last review)
- Writing or modifying target project code -- strictly read-only

## Technical Context

- **Files to modify**: `commands/review.md` (refactor from monolithic reviewer to orchestrator)
- **Files to create**: 7 agent definitions in `agents/` (`review-behavioral.md`, `review-code-quality.md`, `review-tests.md`, `review-coupling.md`, `review-team-practices.md`, `review-org-standards.md`, `review-ai-ergonomics.md`)
- **Skill file to create**: `skills/ai-ergonomics/SKILL.md` (methodology for the AI Ergonomics agent)
- **Agent definition pattern**: YAML frontmatter with `name`, `description`, `tools`, `model: inherit` -- matches existing agents like `agents/reviewer.md`
- **Tools needed by agents**: Read, Glob, Grep, Bash (for git and gh commands)
- **Existing skills to reference**: `skills/clean-code/SKILL.md`, `skills/architecture-patterns/SKILL.md`, `skills/tdd-practices/SKILL.md`, `skills/code-review/SKILL.md`
- **Platform constraint**: Sub-agents cannot spawn other sub-agents. The orchestrator (command) must spawn all agents directly.
- **Risk level**: LOW

---



[x] Reviewed
