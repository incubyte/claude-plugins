# Spec: /bee:review Command

## Overview

A standalone code review command that applies software craftsmanship principles and Adam Tornhill's "code as a crime scene" analysis to any scope the user describes. Unlike the existing `reviewer.md` agent (which runs post-build inside the Bee workflow), this command works independently -- no spec, no triage, no prior workflow needed. The dual goal is: (1) **strategic tech debt reduction** — find the highest-leverage improvements, size them by effort, and build a roadmap to get the codebase to a better place over time; and (2) **developer coaching** — teach better practices through review, not just gatekeep.

## Acceptance Criteria

### Scope Interpretation

- [x] User can describe what to review in natural language (e.g., "review the auth module", "review recent commits by Alice", "review everything in src/payments/")
- [x] Command reviews specific files when the user names them
- [x] Command reviews a folder recursively when the user names a directory
- [x] Command reviews recent commits when the user asks for commit-based review (uses git log + git diff)
- [x] Command reviews the entire codebase when the user asks for a full review
- [x] When the scope is ambiguous, the command states its interpretation before proceeding (e.g., "I'm interpreting this as: all files under src/orders/. Proceeding.")

### Hotspot Analysis (Tornhill-style)

- [x] Command analyzes git log to identify change-frequency hotspots (files that change most often)
- [x] Command detects temporal coupling -- files that consistently change together across commits but live in different modules
- [x] Command combines change frequency with file complexity (size, indentation depth as proxy) to rank hotspots by risk
- [x] Hotspot analysis is scoped to the review target, not always the entire repo
- [x] When reviewing a single file or small set of files, hotspot analysis shows where those files sit in the broader hotspot landscape (high-churn or stable?)

### Code Quality Review

- [x] Reviews code against clean code principles: SRP, DRY, YAGNI, naming, small functions, error handling (sourced from `skills/clean-code/SKILL.md`)
- [x] Reviews dependency direction -- flags inner layers importing from outer layers (sourced from `skills/architecture-patterns/SKILL.md`)
- [x] Reviews test quality when test files are in scope -- test isolation, behavior vs implementation testing, naming (sourced from `skills/tdd-practices/SKILL.md`)
- [x] Identifies refactoring opportunities with specific suggestions (not just "this could be better")
- [x] Distinguishes between tech debt that's actively hurting (in hotspots, on critical paths) vs. tech debt that's dormant (in stable, rarely-touched code) — not all debt is equal

### Coupling and Enhancement Opportunities

- [x] Flags modules with high afferent/efferent coupling based on import analysis
- [x] Identifies "change amplifiers" -- single logical changes that require touching many files
- [x] Suggests decoupling opportunities where coupling is unjustified (same domain concept split across unrelated modules, or unrelated concepts tangled together)
- [x] For each coupling/enhancement finding, notes whether it's a quick win or needs deeper work — enabling incremental improvement

### Team Practice Quality

- [x] Reviews recent commit messages (last ~50 in scope) for quality: are they descriptive, do they explain WHY not just WHAT? Flags patterns like single-word messages ("fix", "update", "wip"), missing context, or inconsistent formatting.
- [x] When a GitHub remote is available, reviews PR comments on recent PRs (via `gh` CLI) for substance: flags patterns of low-effort reviews ("LGTM", "looks good", thumbs-up-only approvals with no comments). Notes the ratio of substantive reviews vs. rubber stamps.
- [x] Frames this as a team health signal — low-quality commit messages and rubber-stamp reviews indicate the team isn't learning from each other's code. Suggests specific improvements (e.g., "commit messages in this repo average 3 words — consider adopting conventional commits" or "80% of PR approvals have no comments — consider requiring at least one specific observation per review").

### Output Format

- [x] Output is categorized into three tiers: Critical (bugs, security issues, broken patterns), Suggestions (refactoring opportunities, design improvements), Nitpicks (style, naming, minor readability)
- [x] Each review item explains WHY it matters, not just WHAT is wrong -- coaching tone
- [x] Each review item is tagged with effort: **quick win** (< 1 hour, low risk), **moderate** (half-day to a day, some risk), or **significant** (multi-day, needs planning) — so the team knows what's a low-hanging fruit vs. a bigger undertaking
- [x] Hotspot analysis appears as its own section with a ranked list
- [x] Temporal coupling appears as its own section showing file pairs/groups that change together
- [x] Review ends with an **Improvement Roadmap** section: prioritized list of what to tackle first, ordered by impact-to-effort ratio. Quick wins that meaningfully improve the codebase go first. Complex items get a one-line explanation of why they're worth the investment.
- [x] When nothing significant is found in a category, that category is omitted (no empty sections)

### Edge Cases

- [x] When reviewing a repo with no git history (or very little), hotspot analysis is skipped gracefully with an explanation
- [x] When the user-described scope matches no files, the command reports this clearly instead of producing an empty review
- [x] Large scope reviews (entire codebase) focus on systemic patterns and hotspots rather than line-by-line review of every file

## Out of Scope

- Writing or modifying code -- this is read-only analysis
- Integration with the Bee workflow (no state tracking, no spec dependency)
- Writing to GitHub (creating issues, commenting on PRs) -- read-only via `gh` CLI for PR comment analysis
- Automated fix suggestions that can be applied (just human-readable recommendations)
- Configurable review rulesets or severity thresholds

## Technical Context

- **Files to create**: `commands/review.md` (the slash command), `skills/code-review/SKILL.md` (review methodology and Tornhill analysis techniques, referenced by the command)
- **Command format**: YAML frontmatter with `description` only, followed by the prompt body (matches `commands/bee.md` pattern)
- **Skill format**: YAML frontmatter with `name`, `description`, followed by methodology content
- **Skills to reference from the command**: `skills/clean-code/SKILL.md`, `skills/architecture-patterns/SKILL.md`, `skills/tdd-practices/SKILL.md`, `skills/code-review/SKILL.md`
- **Tools needed**: Read, Glob, Grep, Bash (for git log, git diff, git shortlog, gh pr list, gh pr view)
- **No agent needed**: This is a command, not an agent -- it runs directly when the user invokes `/bee:review`
- **Existing analog**: `agents/reviewer.md` is the post-build reviewer. This command is standalone and broader in scope (Tornhill analysis, coaching tone, flexible scope)
- **Risk level**: LOW

---



[x] Reviewed

