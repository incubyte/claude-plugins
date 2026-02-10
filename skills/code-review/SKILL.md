---
name: code-review
description: Review methodology combining software craftsmanship principles with Adam Tornhill's "code as a crime scene" hotspot analysis. Categorization framework, effort sizing, and coupling detection.
---

# Code Review Methodology

## Philosophy

Not all tech debt is equal. Code that changes often and is hard to understand costs you every sprint. Code that's ugly but stable and rarely touched costs you nothing. **Focus where it hurts.**

This methodology combines two lenses:
1. **Software craftsmanship** — is the code clean, testable, well-structured? (See `skills/clean-code/SKILL.md`, `skills/architecture-patterns/SKILL.md`, `skills/tdd-practices/SKILL.md`)
2. **Behavioral analysis** — what does the git history tell us about where problems cluster, what changes together, and where complexity is growing? (Adam Tornhill's "Code as a Crime Scene" / "Software Design X-Rays")

## Hotspot Analysis

A hotspot is a file that is both **frequently changed** AND **complex**. Frequent changes alone don't mean trouble (a config file that gets updated often is fine). Complexity alone doesn't mean trouble (a complex algorithm that never changes is stable). The intersection is where bugs breed.

### Change Frequency

Use `git log --format=format: --name-only` over a meaningful time window (3-6 months is typical) to count how often each file appears in commits. Rank by frequency. The top 10-20% are your high-churn files.

For scoped reviews (a folder, a module), run the analysis on the scoped path but also check whether the scoped files appear in the repo-wide top 20%.

### Complexity Proxy

Full cyclomatic complexity analysis requires language-specific tooling. As a practical proxy, use:
- **File size** (lines of code) — larger files tend to be more complex
- **Indentation depth** — deeply nested code is harder to reason about
- **Function count and size** — many large functions in one file signals SRP violations

### Hotspot Ranking

Combine change frequency and complexity into a simple risk score:
- **High risk**: top 20% churn AND above-average complexity — these are active problem areas
- **Medium risk**: top 20% churn OR above-average complexity (but not both) — watch these
- **Low risk**: everything else — leave these alone unless something else flags them

### What Hotspots Tell You

- A hotspot in core business logic means the domain model may need restructuring
- A hotspot in a test file means tests are brittle and coupled to implementation
- A hotspot in a configuration file is usually fine — config changes often by nature
- A hotspot in a "god class" means SRP violations are costing you in every change

## Temporal Coupling

Files that consistently appear in the same commits — especially files in different modules — reveal hidden dependencies. The code doesn't import each other, but a change in one requires a change in the other.

### Detection

Analyze commit history for file co-occurrence:
1. For each commit, record which files changed together
2. Build a co-occurrence matrix: how often does file A change in the same commit as file B?
3. Filter to pairs where co-occurrence is significantly above random chance
4. Flag pairs that live in different modules/directories — these are the interesting ones

Same-directory co-occurrence is expected (related files change together). Cross-directory co-occurrence often reveals:
- **Shotgun surgery** — one logical change scattered across many files
- **Hidden shared concepts** — two modules depend on the same unstated assumption
- **Missing abstractions** — behavior that should be in one place is duplicated

### What to Recommend

- If two files always change together and share a concept: suggest extracting the shared concept
- If a change in module A always requires a change in module B: suggest an interface or event between them
- If a config change requires code changes in multiple places: suggest centralizing the configuration

## Coupling Analysis

Beyond temporal coupling (behavioral), analyze structural coupling:

### Afferent Coupling (Who depends on me?)
Files/modules with many dependents are high-impact change targets. A change here ripples outward. These should be stable and well-tested.

### Efferent Coupling (Who do I depend on?)
Files/modules that depend on many others are fragile — any dependency changing can break them. These are candidates for simplification.

### Change Amplifiers
A single logical change (e.g., "add a new user role") that requires touching 5+ files is a design smell. The concept of "user role" is scattered instead of centralized. Look for:
- The same enum/constant repeated in multiple files
- The same conditional check (`if role === 'admin'`) in multiple places
- The same data transformation done in multiple handlers

## Categorization Framework

### Critical
Issues that should be fixed before the next release. Evidence of active harm.
- Security vulnerabilities (injection, auth bypass, data exposure)
- Bugs (logic errors, race conditions, unhandled edge cases that crash)
- Broken architectural patterns (dependency direction violations in critical paths)
- Data integrity risks (missing validation on write paths, silent data corruption)

### Suggestions
Issues worth addressing in the next few sprints. They slow the team down or make the codebase harder to work with.
- SRP violations in hotspot files (these are actively expensive)
- Missing or brittle tests on frequently-changing code
- Coupling that amplifies change cost
- Naming that obscures intent in complex logic
- Duplication of business rules (DRY violations where the knowledge is the same)

### Nitpicks
Issues that would make the code nicer but aren't causing active problems. Address opportunistically.
- Style inconsistencies (naming convention deviations, formatting)
- Minor naming improvements in stable code
- Dead code that isn't hurting anything but adds noise
- Comment quality (misleading or stale comments)

### What NOT to Flag
- Tech debt in stable, rarely-changed code — it's not costing you anything
- Style preferences that aren't project conventions — the reviewer's taste is not a standard
- "I would have done it differently" — unless the current approach has measurable costs

## Effort Sizing

Every finding gets an effort tag so the team can plan:

- **Quick win** (< 1 hour, low risk): rename a function, extract a method, delete dead code, add a missing test for an edge case. Can be done in a spare moment.
- **Moderate** (half-day to a day, some risk): extract a class, restructure a module, refactor a complex function, add integration tests. Needs a focused session.
- **Significant** (multi-day, needs planning): redesign a subsystem, introduce an architectural boundary, migrate a data model, decouple tightly-bound modules. Needs its own story/ticket.

## Team Practice Quality

### Commit Messages
Good commit messages are a form of documentation. They explain WHY a change was made, not just WHAT changed. A codebase with good commit messages is easier to debug (`git bisect`), easier to review (`git log`), and easier to onboard into.

Red flags:
- Single-word messages: "fix", "update", "wip", "stuff"
- What-only messages: "changed button color" (why?)
- Ticket-only messages: "JIRA-1234" (no context without opening the ticket)
- Mega-commits: one message covering 20 unrelated changes

Good patterns:
- Conventional commits: `feat(auth): add rate limiting to login endpoint`
- Why-first: "Prevent brute-force attacks on login — add rate limiting after 5 failed attempts"
- Small, focused commits with messages that tell a story when read in sequence

### PR Review Quality
Code review is how teams learn from each other. Rubber-stamp reviews ("LGTM", approval with no comments) provide zero value — they're a process checkbox, not a learning opportunity.

Red flags:
- High ratio of approvals with no comments
- Comments that are only "LGTM", "looks good", "+1", or emoji-only
- Reviews completed in under 2 minutes on non-trivial PRs
- Same reviewer always approving the same author (buddy system, not real review)

What good reviews look like:
- At least one specific observation per review (even on clean code: "Nice extraction of the discount logic — much clearer now")
- Questions that probe understanding: "What happens if the user submits twice?"
- Knowledge sharing: "FYI, we have a utility for this in src/utils/dates.ts"

## Improvement Roadmap

The review should end with an actionable roadmap, ordered by impact-to-effort ratio:

1. **Quick wins with high impact** — do these first. They're cheap and make the codebase meaningfully better. Examples: rename a confusing function in a hotspot file, add a missing test for a critical path, extract duplicated business logic.

2. **Moderate efforts with high impact** — schedule these. They need focused time but pay for themselves quickly. Examples: refactor a god class that's a change-frequency hotspot, add integration tests for an untested critical flow.

3. **Significant investments** — plan these as stories. They're expensive but address structural problems. Examples: decouple temporally-coupled modules, introduce an architectural boundary, redesign a subsystem that's a persistent hotspot.

4. **Skip these (for now)** — tech debt that's not actively hurting. Mention it for awareness but explicitly recommend NOT prioritizing it. The team's time is better spent on items 1-3.
