# TDD Plan: Browser Verification

## Execution Instructions
Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] -> [x]).
Continue until all items are done.
If stuck after 3 attempts, mark with a warning and move to the next independent step.

## Context
- **Source**: `docs/specs/browser-visual-verification.md`
- **Architecture**: Simple -- markdown-only Claude Code plugin (agents, commands, skills)
- **Risk**: LOW
- **Slices**: 5 slices, ordered by dependency

## What "Testing" Means Here

This is a markdown-only project. There is no runtime code, no test framework, no `npm test`. "Testing" means structural verification -- does each file contain the required sections, frontmatter fields, tool references, and cross-file references specified by the acceptance criteria? The executor verifies each behavior by reading the file and confirming its contents match the spec.

**Verification method**: After writing each file, use Read/Grep to confirm the required content is present. That is the "test".

## Codebase Patterns (templates to follow)

- **Agent frontmatter**: `name`, `description`, `tools`, `model: inherit` (see `bee/agents/verifier.md`)
- **Command frontmatter**: `description` only (see `bee/commands/qc.md`)
- **Skill frontmatter**: `name`, `description` (see `bee/skills/lsp-analysis/SKILL.md`)
- **Agent structure**: Skills section, Inputs section, Mission/Process section, Output Format, Bee-Specific Rules
- **Command structure**: Skills section, orchestration steps, delegation via Task tool, graceful degradation
- **Skill structure**: Reference tables, patterns, graceful degradation, no orchestration logic

---

## Slice 1: Skill File (`bee/skills/browser-testing/SKILL.md`)

Shared reference for Chrome MCP tools, dev server detection patterns, and screenshot conventions. Both the agent (Slice 2) and command (Slice 4) will reference this skill.

### Behavior 1.1: File exists with correct YAML frontmatter

**Given** the skill file does not exist yet
**When** we create `bee/skills/browser-testing/SKILL.md`
**Then** it has YAML frontmatter with `name: browser-testing` and a `description` field

- [x] **RED**: Confirm the file does not exist (Read returns error or empty)
- [x] **GREEN**: Create `bee/skills/browser-testing/SKILL.md` with frontmatter matching the pattern from `bee/skills/lsp-analysis/SKILL.md`
- [x] **VERIFY**: Read the file, confirm `name: browser-testing` and `description:` are present in frontmatter

### Behavior 1.2: Chrome MCP tool reference table

**Given** the skill file exists
**When** we read the Chrome MCP tool section
**Then** it contains a table mapping each tool to its purpose: `tabs_create_mcp`, `navigate`, `read_page`, `find`, `computer`, `javascript_tool`, `read_console_messages`, `get_page_text`, `tabs_context_mcp`

- [x] **RED**: Grep the file for `tabs_create_mcp` -- not found yet
- [x] **GREEN**: Add a Chrome MCP Tools section with a reference table (tool name, what it does, when to use it)
- [x] **VERIFY**: Grep confirms all 9 tool names are present in the file

### Behavior 1.3: Dev server detection patterns

**Given** the skill file exists
**When** we read the dev server detection section
**Then** it describes the detection order: (1) CLAUDE.md / chat context first, (2) ecosystem analysis fallback (package.json scripts, Makefile, common frameworks)

- [x] **RED**: Grep the file for "CLAUDE.md" in a detection context -- not found yet
- [x] **GREEN**: Add a Dev Server Detection section documenting the two-step detection order and common patterns per ecosystem
- [x] **VERIFY**: File contains both detection steps in the correct priority order

### Behavior 1.4: Graceful degradation approach

**Given** the skill file exists
**When** we read the graceful degradation section
**Then** it documents the `tabs_context_mcp` availability check and the two degradation modes (dev mode: skip and pass, test mode: stop with error)

- [x] **RED**: Grep for "tabs_context_mcp" in a degradation context -- not found yet
- [x] **GREEN**: Add a Graceful Degradation section
- [x] **VERIFY**: File describes both degradation modes

### Behavior 1.5: Screenshot capture conventions

**Given** the skill file exists
**When** we read the screenshot section
**Then** it documents screenshot conventions: when to capture, naming pattern, storage path (`tests/executions/{date}/`)

- [x] **RED**: Grep for "screenshot" -- not found yet
- [x] **GREEN**: Add a Screenshot Conventions section
- [x] **VERIFY**: File documents screenshot capture approach and path conventions

- [x] **REFACTOR**: Read the complete file top to bottom. Ensure sections flow logically, no duplication, consistent formatting with other SKILL.md files.

---

## Slice 2: Agent Definition (`bee/agents/browser-verifier.md`)

The browser verification specialist agent. Called by build.md (Slice 3) and by the browser-test command (Slice 4).

### Behavior 2.1: File exists with correct YAML frontmatter

**Given** the agent file does not exist yet
**When** we create `bee/agents/browser-verifier.md`
**Then** it has YAML frontmatter with `name: browser-verifier`, `description`, `model: inherit`, and `tools` listing all required tools

- [x] **RED**: Confirm the file does not exist
- [x] **GREEN**: Create `bee/agents/browser-verifier.md` with frontmatter. Tools must include: `Read, Glob, Grep, Bash, tabs_create_mcp, navigate, read_page, find, computer, javascript_tool, read_console_messages, get_page_text`
- [x] **VERIFY**: Read the file, confirm all frontmatter fields are present. Grep for each of the 12 tools in the tools list.

### Behavior 2.2: Skills reference

**Given** the agent file exists with frontmatter
**When** we read the Skills section
**Then** it references `skills/browser-testing/SKILL.md` (the file from Slice 1)

- [x] **RED**: Grep for `skills/browser-testing/SKILL.md` -- not found yet
- [x] **GREEN**: Add Skills section referencing the browser-testing skill
- [x] **VERIFY**: Reference is present

### Behavior 2.3: Inputs section defines what the agent receives

**Given** the agent file exists
**When** we read the Inputs section
**Then** it lists: spec path, slice number, context summary (including dev server info), mode (dev or test), and DESIGN.md path (optional)

- [x] **RED**: Grep for "Inputs" section -- not found or incomplete
- [x] **GREEN**: Add Inputs section listing all inputs the agent expects
- [x] **VERIFY**: All 5 input items are documented

### Behavior 2.4: Chrome MCP availability check

**Given** the agent file exists
**When** we read the process section
**Then** it describes calling `tabs_context_mcp` to check availability, and the skip-with-message behavior when unavailable

- [x] **RED**: Grep for "tabs_context_mcp" in process context -- not found yet
- [x] **GREEN**: Add the availability check as Step 0 or Step 1 of the agent's process
- [x] **VERIFY**: The check and the skip message ("Browser verification skipped -- Chrome MCP not available") are both present

### Behavior 2.5: Dev server detection and developer confirmation

**Given** the agent file exists
**When** we read the dev server section
**Then** it describes: check CLAUDE.md/chat context first, fall back to ecosystem analysis, ask developer to confirm or override

- [x] **RED**: Grep for dev server detection steps -- not found yet
- [x] **GREEN**: Add dev server detection following the spec's detection order
- [x] **VERIFY**: All three steps (context check, ecosystem fallback, developer confirmation) are present

### Behavior 2.6: Browser verification process (AC checking)

**Given** the agent file exists
**When** we read the verification process
**Then** it describes: reading ACs from spec, navigating the app, using AI judgment for each AC, checking console via `read_console_messages`, reading page content via `read_page`/`get_page_text`, checking against DESIGN.md if present

- [x] **RED**: Grep for "acceptance criteria" or "read_console_messages" in verification context -- not found yet
- [x] **GREEN**: Add the core verification loop
- [x] **VERIFY**: All 6 verification steps from the spec are represented

### Behavior 2.7: Dev mode reporting (failures only)

**Given** the agent file exists
**When** we read the output format for dev mode
**Then** it specifies: only report failures, show console errors, ask "Should I go ahead and fix this?" on failure, one-line pass message

- [x] **RED**: Grep for "Should I go ahead and fix this" -- not found yet
- [x] **GREEN**: Add dev mode output format section
- [x] **VERIFY**: All 4 reporting rules from the spec are present

### Behavior 2.8: Test mode reporting (full report)

**Given** the agent file exists
**When** we read the output format for test mode
**Then** it specifies: full report with PASS/FAILED per AC, expected vs observed for failures, console errors, screenshot references, report saved to `tests/executions/{date}/{specname}-results.md`

- [x] **RED**: Grep for "tests/executions" -- not found yet
- [x] **GREEN**: Add test mode output format section
- [x] **VERIFY**: All 7 reporting requirements from the spec are present

### Behavior 2.9: State tracking

**Given** the agent file exists
**When** we read the state tracking section
**Then** it documents updating `.claude/bee-state.local.md` with "Browser Verification" field per slice: `passed`, `failed`, or `skipped (no Chrome MCP)`

- [x] **RED**: Grep for "bee-state" in browser verification context -- not found yet
- [x] **GREEN**: Add state tracking instructions
- [x] **VERIFY**: All three state values are documented

- [x] **REFACTOR**: Read the complete agent file. Compare structure against `bee/agents/verifier.md` for consistency. Ensure tone matches ("You are Bee..."), sections are in logical order, no duplication.

---

## Slice 3: Build.md Integration

Update Step 4 of `bee/commands/build.md` to conditionally call the browser-verifier agent when UI is involved.

### Behavior 3.1: Conditional browser verification after regular verifier

**Given** `bee/commands/build.md` exists with Step 4 (Execute -> Verify)
**When** we read the post-verification section of Step 4
**Then** after the regular verifier passes, there is a conditional: if "UI-involved: yes", spawn a Task to the browser-verifier agent in dev mode

- [x] **RED**: Grep `build.md` for "browser-verifier" -- not found yet
- [x] **GREEN**: Add the conditional browser-verifier delegation in Step 4, after the regular verifier PASS block. Pass: spec path, slice number, context summary (including dev server info), mode: "dev"
- [x] **VERIFY**: Grep confirms "browser-verifier" is present in Step 4, conditional on "UI-involved"

### Behavior 3.2: Browser verification does not block on unavailability

**Given** build.md has the browser-verifier conditional
**When** we read the browser-verifier delegation
**Then** it states that if browser-verifier reports "skipped", the slice still passes (regular verifier PASS is not affected)

- [x] **RED**: Grep for "skipped" in browser verification context -- not explicit yet
- [x] **GREEN**: Add clarification that browser verification skip does not block the build
- [x] **VERIFY**: The non-blocking behavior is documented

### Behavior 3.3: State tracking update

**Given** build.md has the browser-verifier conditional
**When** we read the state update after browser verification
**Then** `.claude/bee-state.local.md` is updated with the Browser Verification result for the current slice

- [x] **RED**: Grep for "Browser Verification" state update -- not found yet
- [x] **GREEN**: Add state tracking update instruction in the browser-verifier delegation block
- [x] **VERIFY**: State update instruction is present

- [x] **REFACTOR**: Read the full Step 4 section. Ensure the browser-verifier addition flows naturally after the existing verifier logic. No disruption to the existing PASS/NEEDS FIXES flow.

---

## Slice 4: Standalone Command (`bee/commands/browser-test.md`)

The `bee:browser-test` orchestrator command for regression testing.

### Behavior 4.1: File exists with correct YAML frontmatter

**Given** the command file does not exist yet
**When** we create `bee/commands/browser-test.md`
**Then** it has YAML frontmatter with `description` (matching pattern from `bee/commands/qc.md`)

- [x] **RED**: Confirm the file does not exist
- [x] **GREEN**: Create `bee/commands/browser-test.md` with frontmatter
- [x] **VERIFY**: Read the file, confirm `description:` is present in frontmatter

### Behavior 4.2: Skills reference

**Given** the command file exists
**When** we read the Skills section
**Then** it references `skills/browser-testing/SKILL.md`

- [x] **RED**: Grep for `skills/browser-testing/SKILL.md` -- not found yet
- [x] **GREEN**: Add Skills section
- [x] **VERIFY**: Reference is present

### Behavior 4.3: Spec file resolution

**Given** the command file exists
**When** we read the invocation section
**Then** it describes: accepting one or more spec names as arguments, resolving to `docs/specs/` with or without `.md`, erroring when a spec file does not exist

- [x] **RED**: Grep for "docs/specs/" in resolution context -- not found yet
- [x] **GREEN**: Add spec resolution step
- [x] **VERIFY**: All 3 invocation ACs are covered (multiple specs, .md extension handling, missing file error)

### Behavior 4.4: Chrome MCP check (hard fail in test mode)

**Given** the command file exists
**When** we read the Chrome MCP check section
**Then** it checks availability via `tabs_context_mcp` and STOPS with an error if unavailable (unlike dev mode which skips gracefully)

- [x] **RED**: Grep for hard-fail behavior -- not found yet
- [x] **GREEN**: Add Chrome MCP availability check that stops on failure
- [x] **VERIFY**: The stop-on-failure behavior is explicit, distinct from dev mode's skip behavior

### Behavior 4.5: Dev server handling

**Given** the command file exists
**When** we read the dev server section
**Then** it uses the same detection order as Capability 1, asks developer to confirm/override, starts the dev server if not running

- [x] **RED**: Grep for dev server handling -- not found yet
- [x] **GREEN**: Add dev server handling section
- [x] **VERIFY**: Detection order, confirmation, and server start are all documented

### Behavior 4.6: Per-spec delegation to browser-verifier agent

**Given** the command file exists
**When** we read the test execution section
**Then** for each spec, it delegates to the browser-verifier agent via Task in test mode, passing all ACs

- [x] **RED**: Grep for browser-verifier delegation -- not found yet
- [x] **GREEN**: Add the per-spec loop that delegates to the browser-verifier agent with mode: "test"
- [x] **VERIFY**: The delegation passes spec path and mode: "test"

### Behavior 4.7: Report generation and summary

**Given** the command file exists
**When** we read the reporting section
**Then** it describes: one report per spec at `tests/executions/{date}/{specname}-results.md`, directory creation, and console summary ("N of M specs passed")

- [x] **RED**: Grep for "tests/executions" -- not found yet
- [x] **GREEN**: Add report generation and summary output sections
- [x] **VERIFY**: Report path pattern, directory creation, and summary format are all present

### Behavior 4.8: Read-only enforcement

**Given** the command file exists
**When** we read the rules section
**Then** it explicitly states the command does NOT modify any code (read-only)

- [x] **RED**: Grep for "read-only" or "does NOT modify" -- not found yet
- [x] **GREEN**: Add explicit read-only rule
- [x] **VERIFY**: Read-only constraint is stated

- [x] **REFACTOR**: Read the complete command file. Compare structure against `bee/commands/qc.md` for consistency (orchestrator pattern, graceful degradation, tone). Ensure no duplication with the agent definition.

---

## Slice 5: Documentation Updates (CLAUDE.md and help.md)

### Behavior 5.1: CLAUDE.md lists the new command

**Given** `bee/CLAUDE.md` has a "What's Implemented" or "Project Conventions" section listing commands
**When** we read the implemented commands list
**Then** `bee:browser-test` is listed with a brief description

- [x] **RED**: Grep `bee/CLAUDE.md` for "browser-test" -- not found yet
- [x] **GREEN**: Add `bee:browser-test` to the commands list in the appropriate section
- [x] **VERIFY**: Grep confirms "browser-test" is present in CLAUDE.md

### Behavior 5.2: help.md includes browser-test section

**Given** `bee/commands/help.md` has a numbered tour of commands
**When** we read the tour
**Then** there is a new section for `/bee:browser-test` positioned after `/bee:qc`, explaining what it does and how to invoke it

- [x] **RED**: Grep `bee/commands/help.md` for "browser-test" -- not found yet
- [x] **GREEN**: Add a `/bee:browser-test` section to the tour, after the `/bee:qc` section. Include: what it does (regression testing against running app), invocation example (`/bee:browser-test user-auth checkout-flow`), artifacts produced (report files), read-only nature
- [x] **VERIFY**: The section is present, positioned after qc, and includes invocation example

### Behavior 5.3: help.md wrap-up summary includes browser-test

**Given** help.md has a wrap-up summary listing all commands
**When** we read the summary
**Then** `bee:browser-test` is listed alongside the other commands

- [x] **RED**: Grep the wrap-up section for "browser-test" -- not found yet
- [x] **GREEN**: Add `bee:browser-test` to the wrap-up summary and the "Skip to specific command" options
- [x] **VERIFY**: Present in both locations

- [x] **REFACTOR**: Read both files. Ensure the browser-test description is consistent between CLAUDE.md and help.md. Ensure numbering in help.md is correct after the insertion.

---

## Final Check

- [x] **Cross-reference**: Grep all new files for references to each other -- skill references agent, agent references skill, command references agent, build.md references agent
- [x] **Tool list consistency**: The tools listed in the agent frontmatter match the tools documented in the skill file
- [x] **Detection order consistency**: Dev server detection order is identical in skill, agent, and command
- [x] **Degradation mode consistency**: Dev mode (skip) vs test mode (stop) is correctly described in skill, agent, command, and build.md
- [x] **State tracking consistency**: The "Browser Verification" field format is consistent between the agent and build.md
- [x] **Read all 5 new/modified files** end-to-end for tone, formatting, and structural consistency with existing bee files

## File Summary
| Slice | File | Action |
|-------|------|--------|
| 1 | `bee/skills/browser-testing/SKILL.md` | Create |
| 2 | `bee/agents/browser-verifier.md` | Create |
| 3 | `bee/commands/build.md` | Update Step 4 |
| 4 | `bee/commands/browser-test.md` | Create |
| 5 | `bee/CLAUDE.md` | Update commands list |
| 5 | `bee/commands/help.md` | Update tour + summary |

## Behavior Summary
| Slice | Behaviors | Status |
|-------|-----------|--------|
| 1 - Skill file | 5 | |
| 2 - Agent definition | 9 | |
| 3 - Build.md integration | 3 | |
| 4 - Standalone command | 8 | |
| 5 - Documentation updates | 3 | |
| **Total** | **28** | |

---

<p align="center">[x] Reviewed</p>
