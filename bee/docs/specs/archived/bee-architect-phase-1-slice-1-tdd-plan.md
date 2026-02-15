# TDD Plan: Bee Architect Phase 1 -- Slice 1: Domain Language Extractor Agent

## Execution Instructions
Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] -> [x]).
Continue until all items are done.
If stuck after 3 attempts, mark with a warning and move to the next independent step.

## Context
- **Source**: `docs/specs/bee-architect-phase-1.md`
- **Slice**: Domain Language Extractor Agent (`agents/domain-language-extractor.md`)
- **Risk**: LOW
- **File to create**: `agents/domain-language-extractor.md`
- **Acceptance Criteria**:
  1. Reads README, docs/, API description files (OpenAPI specs, route definitions) to extract domain vocabulary
  2. Uses WebFetch to visit the company's website and extract marketing language
  3. If no website found or WebFetch fails, asks developer for URL or key domain terms
  4. Falls back to inferring domain vocabulary from code naming patterns (module names, class names, function names, directory structure)
  5. Produces structured domain vocabulary: list of domain concepts with sources
  6. Compares domain vocabulary against code structure and flags vocabulary drift and boundary violations
  7. Read-only -- does not modify any files

## Codebase Analysis

### File Structure
- Implementation: `agents/domain-language-extractor.md` (new file)
- Pattern reference: `agents/context-gatherer.md`, `agents/review-coupling.md`
- Skills to reference: `skills/architecture-patterns/SKILL.md`, `skills/clean-code/SKILL.md`

### Agent Pattern
All agents follow the same structure:
1. YAML frontmatter: `name`, `description`, `tools`, `model: inherit`
2. One-line persona statement
3. Skills section (read skill files for reference)
4. Inputs section (what the agent receives)
5. Process section (numbered steps)
6. Output Format section (markdown template)
7. Rules section (constraints)

### Verification Method
Since this is a markdown agent definition (no compiled code, no test framework), each step is verified by reading the file back and confirming:
- Section exists with expected content
- Follows the established pattern from reference agents
- Covers the relevant acceptance criteria

---

## Behavior 1: YAML frontmatter and persona

**Given** the established agent pattern (frontmatter + persona line)
**When** the domain-language-extractor agent file is created
**Then** it has valid YAML frontmatter with name, description, tools (Read, Glob, Grep, WebFetch), model: inherit, and a one-line persona

- [x] **DEFINE**: Frontmatter needs:
  - `name: domain-language-extractor`
  - `description`: one sentence about extracting domain vocabulary from docs, website, and code
  - `tools: Read, Glob, Grep, WebFetch`
  - `model: inherit`
  - Persona line: something like "You are a domain language analyst..."

- [x] **APPLY**: Create `agents/domain-language-extractor.md` with frontmatter and persona line only.

- [x] **VERIFY**: Read the file. Confirm frontmatter has all four fields. Confirm `tools` includes WebFetch (unique to this agent vs review-coupling). Confirm persona line exists after the closing `---`.

---

## Behavior 2: Skills section

**Given** the agent needs domain boundary and clean code knowledge
**When** the skills section is written
**Then** it references architecture-patterns and clean-code skill files

- [x] **DEFINE**: A Skills section that instructs the agent to read:
  - `skills/architecture-patterns/SKILL.md` -- for domain boundary knowledge
  - `skills/clean-code/SKILL.md` -- for naming pattern analysis

- [x] **APPLY**: Add the Skills section after the persona line.

- [x] **VERIFY**: Read the file. Confirm both skill paths are listed. Confirm the section follows the pattern from `review-coupling.md`.

---

## Behavior 3: Inputs section

**Given** the agent will be spawned by the orchestrator command
**When** the inputs section is written
**Then** it documents what the agent receives (project_root, and optionally context-gatherer output)

- [x] **DEFINE**: The agent receives:
  - `project_root`: path to the project being analyzed
  - Optionally: context-gatherer output (for existing docs, README location, etc.)

- [x] **APPLY**: Add the Inputs section.

- [x] **VERIFY**: Read the file. Confirm inputs are documented. Confirm it matches the style of review-coupling's Inputs section.

---

## Behavior 4: Process step -- extract vocabulary from docs

**Given** AC1: reads README, docs/, API description files to extract domain vocabulary
**When** the first process step is written
**Then** it instructs the agent to scan README, docs/ folder, and API description files (OpenAPI, route definitions) for domain terms

- [x] **DEFINE**: Process step 1 should instruct the agent to:
  - Read README.md (or README) at project root
  - Glob for files in docs/ directory
  - Grep for OpenAPI/Swagger files, route definition files
  - Extract nouns, verbs, and concepts that describe the business domain

- [x] **APPLY**: Add Process section with step 1.

- [x] **VERIFY**: Read the process step. Confirm it mentions README, docs/, and API files. Confirm it uses Read, Glob, Grep tools.

---

## Behavior 5: Process step -- extract vocabulary from website

**Given** AC2 and AC3: use WebFetch for website, fallback to asking developer
**When** the website extraction step is written
**Then** it instructs the agent to find and fetch the company website, with fallback behavior

- [x] **DEFINE**: Process step 2 should:
  - Look for website URL in README, package.json homepage field, or docs
  - Use WebFetch to visit and extract marketing language / product descriptions
  - If no URL found or WebFetch fails: ask the developer for the URL or key domain terms using AskUserQuestion (not open-ended -- offer concrete options like "Enter URL" / "Describe key domain terms" / "Skip website analysis")

- [x] **APPLY**: Add step 2 to the Process section.

- [x] **VERIFY**: Read step 2. Confirm it covers the happy path (WebFetch succeeds), failure path (WebFetch fails), and missing path (no URL found). Confirm it uses AskUserQuestion for fallback, not open-ended prompts.

---

## Behavior 6: Process step -- infer vocabulary from code

**Given** AC4: fallback to code naming patterns
**When** the code inference step is written
**Then** it instructs the agent to extract domain terms from module names, class names, function names, directory structure

- [x] **DEFINE**: Process step 3 should:
  - Glob for top-level directories and key source folders
  - Grep for class/module/function declarations
  - Extract recurring nouns from naming patterns
  - This serves as both supplementary source and fallback when docs/website are sparse

- [x] **APPLY**: Add step 3 to the Process section.

- [x] **VERIFY**: Read step 3. Confirm it covers directory structure, class names, module names, function names. Confirm it positions code as both supplement and fallback.

---

## Behavior 7: Process step -- compare vocabulary against code structure

**Given** AC6: flags vocabulary drift and boundary violations
**When** the comparison step is written
**Then** it instructs the agent to cross-reference domain vocabulary with actual code and flag mismatches

- [x] **DEFINE**: Process step 4 should:
  - Compare extracted domain concepts against module/directory names
  - Flag vocabulary drift: domain term differs from code term (e.g., domain says "Order", code says "transaction")
  - Flag boundary violations: concepts the domain treats as separate but code tangles in one module
  - For each mismatch, note the domain source and the code location

- [x] **APPLY**: Add step 4 to the Process section.

- [x] **VERIFY**: Read step 4. Confirm it defines both mismatch types with examples. Confirm it instructs the agent to record source and location for each finding.

---

## Behavior 8: Output format

**Given** AC5: structured domain vocabulary with sources
**When** the output format is written
**Then** it provides a markdown template matching the assessment report shape from the spec

- [x] **DEFINE**: Output format should include:
  - Domain Vocabulary table: Concept | Source | Code Match
  - Boundary Map: which modules own which concepts
  - Vocabulary Drift items (if any)
  - Boundary Violation items (if any)
  - The format should align with the "Assessment Report Shape" in the spec so the orchestrator can merge it directly

- [x] **APPLY**: Add the Output Format section with the markdown template.

- [x] **VERIFY**: Read the output format. Confirm it has the vocabulary table, boundary map, drift items, and violation items. Confirm it aligns with the spec's assessment report shape (lines 60-89 of the spec).

---

## Behavior 9: Rules section

**Given** AC7: read-only, no file modifications, plus agent constraints
**When** the rules section is written
**Then** it lists all constraints: read-only, no sub-agents, tool boundaries

- [x] **DEFINE**: Rules should include:
  - Read-only -- do not modify any files
  - Do not spawn sub-agents
  - Use AskUserQuestion only when docs and website are unavailable (not for every run)
  - If all sources are sparse, still produce output from whatever was found -- do not return empty results

- [x] **APPLY**: Add the Rules section.

- [x] **VERIFY**: Read the rules. Confirm read-only constraint is present. Confirm no-sub-agents constraint is present. Confirm graceful degradation is covered.

---

## Edge Cases (LOW risk -- minimal)

- [x] **VERIFY**: The tools list in frontmatter does NOT include Bash or Write (agent is read-only, and cannot run arbitrary commands).

- [x] **VERIFY**: The output format uses the same table structure as the spec's assessment report shape, so the orchestrator can merge without reformatting.

- [x] **VERIFY**: The file follows valid markdown structure -- frontmatter fences (`---`), consistent heading levels, no broken formatting.

---

## Final Check

- [x] Read `agents/domain-language-extractor.md` top to bottom. Confirm:
  - YAML frontmatter has name, description, tools (Read, Glob, Grep, WebFetch), model: inherit
  - Persona line sets the agent's role clearly
  - Skills section references architecture-patterns and clean-code
  - Inputs section documents what the agent receives
  - Process has 4 steps: docs extraction, website extraction, code inference, vocabulary-vs-code comparison
  - Output format matches the spec's assessment report shape
  - Rules enforce read-only, no sub-agents, graceful degradation
  - File reads naturally from top to bottom -- no awkward transitions

## Summary
| Step | Description | Status |
|------|------------|--------|
| Behavior 1 | YAML frontmatter and persona | done |
| Behavior 2 | Skills section | done |
| Behavior 3 | Inputs section | done |
| Behavior 4 | Process -- extract from docs | done |
| Behavior 5 | Process -- extract from website | done |
| Behavior 6 | Process -- infer from code | done |
| Behavior 7 | Process -- compare and flag mismatches | done |
| Behavior 8 | Output format | done |
| Behavior 9 | Rules section | done |
| Edge cases | Tools, format alignment, valid markdown | done |
| Final check | Full file review | done |

---

[x] Reviewed
