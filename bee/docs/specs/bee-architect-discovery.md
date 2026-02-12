# Discovery: /bee:architect Command

## Why

The Bee plugin helps developers build features with specs, TDD plans, and reviews -- but it has no way to assess whether the architecture itself is healthy. Developers can follow all the right processes and still end up with a codebase where the code structure drifts from the domain it represents. A README talks about "Orders" but the code calls them "transactions." Concepts the business treats as separate live tangled in one module. These mismatches accumulate silently and make every future feature harder to build.

The `/bee:architect` command closes this gap by grounding architectural health in the product's own language -- how the product describes itself versus how the code is actually structured.

## Who

- **Developers using Bee on existing codebases**: They want to know where their architecture has drifted from their domain. They get runnable tests that document good boundaries and flag where architecture leaks.
- **Developers starting greenfield projects via /bee:build**: They want architecture tests written before any feature code, defining the intended module boundaries from discovery's milestone map. Architecture-first TDD.
- **Tech leads reviewing architectural health**: They get a concrete, testable picture of boundary violations and domain mismatches -- not a subjective opinion, but tests that pass or fail.

## Success Criteria

- Developers can run `/bee:architect` on any codebase and get a report that maps domain language (from README, docs, API descriptions) against actual code structure
- The command produces runnable test files (not just prose recommendations) that the project's existing test runner can execute
- Some tests pass (documenting good boundaries worth preserving) and some intentionally fail (highlighting where architecture leaks)
- For greenfield projects invoked from `/bee:build`, boundary tests exist before any feature code is written
- The developer interview is light -- 2-3 targeted validation questions, not a full domain modeling session

## Problem Statement

Codebases drift from their domain over time. The product says "Orders" and "Shipments" but the code has a single `processTransaction()` that handles both. A module that should own one concept quietly absorbs three. These mismatches are invisible in day-to-day feature work but compound into architectural debt. Today, the only way to catch them is expensive manual review or tribal knowledge. The `/bee:architect` command makes these mismatches visible and testable -- grounded in how the product actually describes itself, not in abstract "best practices."

## Hypotheses

- H1: README, docs, marketing copy, and API descriptions contain enough domain vocabulary to identify meaningful mismatches with code structure. If not, the interview step needs to carry more weight.
- H2: ArchUnit-style dependency tests are expressive enough to capture both naming mismatches (vocabulary drift) and structural mismatches (tangled concepts). If not, we may need a second test format for naming checks.
- H3: Auto-detecting the test framework from project config (package.json, build files) reliably determines how to generate runnable tests. If not, we fall back to asking the developer.
- H4: Light validation (2-3 questions) is sufficient to confirm domain intent without turning into a full domain modeling session. If developers consistently need more, the interview protocol needs expansion.

## Out of Scope

- Full domain-driven design modeling or event storming facilitation
- Runtime architecture analysis (only static analysis and git history)
- Generating production code to fix the violations found -- the command is read-only plus test generation
- Supporting test frameworks not detectable from project config (the developer can always specify manually)
- Continuous monitoring or CI integration -- this is an on-demand assessment

## Milestone Map

### Phase 1: Domain-grounded assessment with runnable tests (the walking skeleton)

This is the standalone `/bee:architect` command working end-to-end on an existing codebase.

- The command orchestrates context-gatherer, review-coupling, and review-behavioral agents in parallel to analyze the codebase
- A new agent extracts domain language from README, docs, marketing copy, and API descriptions, then compares vocabulary and structure against what the code analysis found
- The command shows the developer a summary of findings and asks 2-3 targeted validation questions ("Is Orders really separate from Shipments in your domain?")
- The command generates runnable ArchUnit-style test files that match the project's detected test framework (Jest, Vitest, Pytest, etc.)
- Passing tests document good boundaries worth preserving; intentionally failing tests highlight where architecture leaks from the domain model
- Tests are saved to a predictable location in the project (e.g., `tests/architecture/` or alongside existing test directories)

### Phase 2: Greenfield integration with /bee:build

Builds on Phase 1 by wiring into the existing build workflow for new projects.

- When `/bee:build` detects a greenfield project and discovery produces a milestone map with module structure, the architect command runs automatically
- Boundary tests are generated from discovery's module map before any feature code is written
- Tests define the intended architecture: which modules exist, what their boundaries are, which dependencies are allowed
- Feature code is then written to pass these architecture tests (architecture-first TDD)

## Open Questions

- Where exactly should generated test files live? A dedicated `tests/architecture/` folder, or co-located with existing tests? This may vary by project convention and should be a question the command asks or infers.
- How do we handle projects with no README or minimal documentation? Fall back entirely to the interview, or also infer domain language from naming patterns in the code itself?
- For the greenfield flow, at what point in the `/bee:build` pipeline does the architect step run -- after discovery but before spec, or after spec but before TDD planning? The answer affects what information is available for test generation.
- Should architecture tests be re-run after each phase ships in a multi-phase epic, to catch drift introduced during development?
- What is the right level of granularity for generated tests -- module-level boundaries only, or also class/function-level naming checks?

## Revised Assessment

Size: FEATURE -- This is a single new command with one new agent (domain language extraction) plus orchestration of existing agents. Phase 2 is a wiring change to an existing command, not a new subsystem. Two phases, but each is well-scoped.

Greenfield: no -- This extends an existing plugin with established patterns (orchestrator-agent, commands/*.md, agents/*.md, skills/*.md).


[x] Reviewed

