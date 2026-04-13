# Spec: Browser Verification

## Overview
<!-- -------- bee-comment -------- -->
> **@developer**: what needs to change such that we do not make the goal of the spec narrow to "visual". I also want to make sure that we look into browser console messages etc.
> **@bee**: Renamed spec from "Browser Visual Verification" to "Browser Verification". Broadened the overview to explicitly cover console errors, runtime exceptions, and page behavior — not just what's visible on screen.
> - [x] mark as resolved
<!-- -------- /bee-comment -------- -->
Add browser-based verification to Bee via Chrome MCP tools. The browser verifier checks the running app holistically — visual state, console errors, runtime exceptions, and page behavior — not just what's visible on screen. Two capabilities: (1) a browser-verifier agent that runs after the regular verifier during `bee:build` when UI is involved, and (2) a standalone `bee:browser-test` command for regression testing specs against a running app.

## Capability 1: Browser Verifier Agent (dev mode)

Called by `bee:build` Step 4 as a second Task after the regular verifier passes, only when context-gatherer flagged "UI-involved: yes".

### Dev Server Detection
<!-- -------- bee-comment -------- -->
> **@developer**: first method of detection should be trying to get the information from context like CLAUDE.md or chat history
> **@bee**: Added CLAUDE.md and prior chat context as the primary detection source. Package.json/Makefile analysis is now the fallback, not the first step.
> - [x] mark as resolved
<!-- -------- /bee-comment -------- -->
- [ ] Agent first checks CLAUDE.md and prior chat context for dev server command and URL (developers often document this)
- [ ] If not found in context, agent falls back to ecosystem analysis (package.json scripts, Makefile, etc.)
- [ ] Agent asks the developer: "Should I run {detected-command} and test on {default-uri}, or do you want to provide a different starting point URI?"
- [ ] Developer can confirm the detected defaults or provide a custom command and/or URI
- [ ] If no dev server command is detected, agent asks the developer for the command and URI directly

### Chrome MCP Availability
<!-- -------- bee-comment -------- -->
> **@developer**: is it possible to check this? how
> **@bee**: Yes — the agent calls `tabs_context_mcp`. If the Chrome MCP server isn't connected, the tool call returns an error. That error is the detection signal. Updated the AC to make this concrete.
> - [x] mark as resolved
<!-- -------- /bee-comment -------- -->
- [ ] Agent checks Chrome MCP availability by calling `tabs_context_mcp` — if the call fails or errors, Chrome MCP is not connected
- [ ] If Chrome MCP is unavailable, agent reports "Browser verification skipped -- Chrome MCP not available" and passes without blocking the build
- [ ] The regular verifier result (PASS) is not affected by browser verification being unavailable

### Browser Verification
<!-- -------- bee-comment -------- -->
> **@developer**: how does it fit in with our existing state tracking? In which step will we be doing this? Will it be specifically one agent's responsibility?
> **@bee**: Added explicit "Where in the workflow" and "State tracking" sections. Runs in Step 4 of build cycle, after regular verifier passes. The browser-verifier agent (separate agent, not the regular verifier) owns the entire browser interaction. State file gets a "Browser Verification" field per slice: passed/failed/skipped.
> - [x] mark as resolved
<!-- -------- /bee-comment -------- -->
<!-- -------- bee-comment -------- -->
> **@developer**: does this mean we will have to change some orchestrator somewhere?
> **@bee**: Yes — `bee/commands/build.md` is the orchestrator. In Step 4 (Execute → Verify), after the regular verifier Task returns PASS, we add a conditional: if "UI-involved: yes", spawn a second Task to the browser-verifier agent. This is already listed under "Files to Create/Modify → Update: `bee/commands/build.md`" (lines 124-127 of this spec).
> - [x] mark as resolved
<!-- -------- /bee-comment -------- -->

**Where in the workflow:** Step 4 (Execute → Verify) of `bee:build`. The build orchestrator calls the browser-verifier agent as a separate Task *after* the regular verifier passes. The browser-verifier agent is solely responsible for all browser interaction.

**State tracking:** `.claude/bee-state.local.md` adds a "Browser Verification" field per slice: `passed`, `failed`, or `skipped (no Chrome MCP)`.

- [ ] Agent reads the spec's acceptance criteria for the current slice
- [ ] Agent opens the app in Chrome via MCP tools and navigates to the relevant page(s)
- [ ] Agent uses AI judgment to translate each AC into navigation/interaction/assertion steps (no explicit test scripts)
- [ ] Agent checks the browser console for errors via `read_console_messages`
- [ ] Agent reads page content via `read_page` and `get_page_text` to verify AC outcomes
- [ ] If `.claude/DESIGN.md` exists, agent checks visible UI against design brief constraints (colors, spacing, component usage)

### Dev Mode Reporting

- [ ] Agent only reports failures -- passing ACs are not listed
- [ ] Console errors are shown in the output
- [ ] When failures are found, agent asks the developer "Should I go ahead and fix this?"
- [ ] If no failures and no console errors, agent reports "Browser verification passed" (one line)

## Capability 2: `bee:browser-test` Command (test mode)

Standalone command for regression testing. Read-only -- does NOT modify any code.

### Invocation

- [ ] Command accepts one or more spec file names: `bee:browser-test user-auth checkout-flow`
- [ ] Spec names resolve to files in `docs/specs/` (with or without `.md` extension)
- [ ] Shows an error when a specified spec file does not exist

### Dev Server Handling

- [ ] Same detection order as Capability 1 (CLAUDE.md/chat context first, then ecosystem analysis)
- [ ] Asks the developer to confirm or override the detected command and URI
- [ ] Starts the dev server if not already running

### Chrome MCP Availability

- [ ] Checks for Chrome MCP tools before starting
- [ ] If Chrome MCP is unavailable, reports the error and stops (unlike dev mode, there is no fallback -- browser testing is the whole point)

### Test Execution

- [ ] For each spec file, reads all acceptance criteria
- [ ] Navigates the app and uses AI judgment to verify each AC
- [ ] Checks browser console for errors
- [ ] Takes screenshots for both passing and failing ACs
- [ ] If `.claude/DESIGN.md` exists, checks UI against design brief constraints

### Test Mode Reporting

- [ ] Produces a full report with each AC marked PASS or FAILED
- [ ] Failed ACs include a description of what was expected vs. what was observed
- [ ] Console errors are listed in the report
- [ ] Screenshot file paths are referenced in the report
- [ ] Report is saved to `tests/executions/{YYYY-MM-DD}/{specname}-results.md`
- [ ] Creates the directory structure if it does not exist
- [ ] When testing multiple specs, produces one report file per spec
- [ ] Prints a summary to the console: "N of M specs passed. Reports saved to tests/executions/{date}/"

## Files to Create/Modify

### New: `bee/agents/browser-verifier.md`

Agent definition with:
- YAML frontmatter: name, description, tools (including Chrome MCP tool names), model: inherit
- Tools must include: Read, Glob, Grep, Bash, tabs_create_mcp, navigate, read_page, find, computer, javascript_tool, read_console_messages, get_page_text

### New: `bee/commands/browser-test.md`

Command definition with:
- YAML frontmatter: description
- Orchestrates: dev server detection, Chrome MCP check, spec file resolution, browser-verifier agent delegation (in test mode), report generation

### New: `bee/skills/browser-testing/SKILL.md`

Shared skill referenced by both the agent and command:
- Dev server detection patterns (package.json scripts, Makefile, common frameworks)
- Chrome MCP tool usage patterns (which tool for what purpose)
- Graceful degradation approach
- Screenshot capture conventions

### Update: `bee/commands/build.md`

- In Step 4 (Execute -> Verify), after the regular verifier passes: if "UI-involved: yes", delegate to browser-verifier agent via Task in dev mode
- Pass: spec path, slice number, context summary (including dev server info)

### Update: `bee/CLAUDE.md`

- Add `bee:browser-test` to the implemented commands list under Project Conventions

### Update: `bee/commands/help.md`

- Add `/bee:browser-test` as a new section in the tour, after `/bee:qc`

## Out of Scope

- No mobile/responsive viewport testing -- desktop browser only
- No visual diff/pixel comparison -- AI judgment only, no image diffing tools
- No parallel browser sessions -- specs tested sequentially
- No test recording/playback -- every run is AI-interpreted fresh
- No modification of production code from `bee:browser-test` (strictly read-only)
- No automatic retry of failed ACs -- report and stop

## Technical Context

- Patterns to follow: agent frontmatter matches existing agents (see `verifier.md`, `quick-fix.md`); command structure matches `qc.md` for standalone orchestration
- Key dependencies: Chrome MCP tools (external), context-gatherer's "UI-involved" flag, existing verifier agent (runs first, browser-verifier runs second)
- The `qc.md` command is the closest template for ecosystem detection and graceful degradation patterns
- Risk level: LOW (internal tooling, no production code changes)

---

<p align="center">[x] Reviewed</p>
