# Discovery: Chrome DevTools Live Inspection for Locator Generation

## Why
Manual copy-paste of outerHTML is tedious and error-prone. Developers often work with running applications during test creation, but the current workflow requires switching to DevTools, inspecting elements, copying HTML, and pasting into the chat. When UI repositories aren't available or accessible, this manual process becomes the only option. We need a way to inspect live applications directly during Phase 2 locator generation, eliminating the copy-paste friction while maintaining the automated workflow developers expect.

## Who
QA developers and automation engineers using the `/bee:playwright` workflow to generate BDD tests. These users are comfortable with localhost dev servers and want to minimize context-switching between browser DevTools and the Claude interface.

## Success Criteria
- Developer generates locators from a running localhost application without manual HTML copy-paste
- Plugin auto-detects and starts dev server using package.json scripts
- Element finding succeeds for standard UI elements (buttons, inputs, links) with 90%+ accuracy on first attempt
- Locators are validated through interaction testing before POM generation completes
- Graceful degradation: if Chrome DevTools unavailable or fails, workflow falls back to outerHTML/repo strategies without blocking progress

## Problem Statement
Developers creating Playwright tests often have their application running locally, but the current locator generation workflow can't leverage this. They must either provide access to UI component repositories (not always available) or manually copy outerHTML from Chrome DevTools (tedious and breaks flow). This manual process is especially painful when generating locators for multiple elements across several feature files. We need a third strategy that connects directly to the running application, finds elements using step descriptions, extracts attributes, validates locators through interaction, and integrates seamlessly with the existing Phase 2 workflow.

## Hypotheses

### H1: Hybrid Element Finding (Decision 1)
**Hypothesis**: Using Chrome MCP's `find` tool for initial element search, then falling back to `javascript_tool` with generated DOM queries when `find` fails or returns ambiguous results, will balance speed (fast natural language search) with precision (deterministic DOM queries).

**Validates**: Most standard UI elements (buttons with clear labels, named inputs) can be found via natural language, while complex or unlabeled elements require DOM query fallback.

**Rejects if**: `find` tool has <70% success rate on standard elements, making the "fast path" rarely useful.

### H2: Selective Fallback with Developer Prompts (Decision 2)
**Hypothesis**: Silently falling back when Chrome MCP is unavailable, but prompting the developer for server/element issues ("Start server?", "Element not found - retry or fall back?"), strikes the right balance between automation and control.

**Validates**: Developers prefer transparency for actionable errors (server down, element missing) but don't want to be bothered by infrastructure issues (Chrome MCP not installed).

**Rejects if**: Developers report frustration with too many prompts, or confusion about why Chrome strategy was skipped.

### H3: Universal Interaction Testing (Decision 3)
**Hypothesis**: Testing every generated locator through interaction (click/fill/visibility check) before returning it will catch unstable or incorrect locators early, reducing downstream test failures.

**Validates**: Interaction testing catches meaningful issues (wrong element selected, element not interactive, locator too fragile) that would otherwise surface during test execution.

**Rejects if**: Interaction testing adds >10 seconds per element with minimal value (false positives, or issues rarely caught).

### H4: Single Server Instance per Phase 2 (Decision 4)
**Hypothesis**: Starting the dev server once at Phase 2 beginning, keeping it alive for all locator generation tasks, then shutting it down after Phase 2 completes, minimizes startup overhead while managing resources efficiently.

**Validates**: Phase 2 typically generates 5-15 locators, making one-time startup cost negligible compared to per-element startup.

**Rejects if**: Long-running servers cause resource issues (port conflicts, memory leaks) or developers prefer manual server management.

### H5: Balanced Error Handling (Decision 5)
**Hypothesis**: Different error types warrant different responses:
- Dev server fails to start → error and stop (environment issue, must fix)
- Multiple elements found → ask developer to disambiguate
- Interaction test fails → warn and let developer choose next action
- Fragile locator (text/CSS only) → accept but add warning comment

This approach keeps the workflow moving while surfacing issues that require developer input.

**Validates**: Developers can resolve errors efficiently without the plugin making risky assumptions or blocking on non-critical warnings.

**Rejects if**: Any error handling pattern causes confusion, workflow blockage, or silent failures that frustrate developers.

## Out of Scope

### Not Building
- **Manual DevTools interaction mode**: Developer won't manually click elements in Chrome to select them (fully automated only)
- **Remote URL support**: Only localhost URLs supported (no staging/production environments)
- **Cross-browser live inspection**: Chrome only (no Firefox/Safari DevTools integration)
- **Visual regression during validation**: Interaction testing verifies functionality, not appearance
- **Server configuration management**: Plugin uses package.json scripts as-is (no custom server setup, port configuration, or environment variables)
- **Multi-page workflows**: Each element inspected independently (no navigation flows or multi-step element finding)

### Explicitly NOT Changed
- **Existing locator priority**: data-testid > role+name > label > placeholder > id > text > CSS (Chrome strategy extracts attributes, follows same priority)
- **Phase 2 POM structure**: Chrome DevTools is a locator generation input, doesn't change POM output format
- **UI repo and outerHTML strategies**: These remain available as alternatives or fallbacks

## Milestone Map

### Phase 1: Core Chrome DevTools Integration (Walking Skeleton)
**Delivers**: End-to-end automated locator generation from live Chrome inspection for one element

**Capabilities**:
- At Phase 2 start, detect dev server script from package.json
- Prompt developer: "Start dev server using `npm run dev`? [Yes / Already running at URL / Use different command]"
- Start server, verify accessibility via Chrome MCP `tabs_create_mcp` + `navigate`
- For one UI element:
  - Try `find` tool with step description ("search button")
  - If not found or ambiguous, generate CSS selector and use `javascript_tool`
  - Extract attributes (data-testid, role, aria-label, etc.)
  - Generate locator following existing priority
  - Test interaction (click for button/link, fill for input, visibility for others)
  - If test passes → return locator
  - If test fails → prompt: "Locator interaction test failed. [Retry / Fall back to outerHTML / Stop]"
- Keep server alive (don't shut down yet)
- Graceful degradation: if Chrome MCP unavailable, fall back to outerHTML prompt

**Success Metric**: Developer generates one validated locator from running app without manual HTML copy-paste.

### Phase 2: Multi-Element Support and Server Lifecycle
**Builds on Phase 1**: Handle 5-15 elements in one Phase 2 run, manage server lifecycle

**Capabilities**:
- Extend to all elements in Phase 2 (loop through each UI element in approved POM)
- Server lifecycle: start once, keep alive across all elements, shut down after Phase 2 completes
- Error handling for dev server failures: if startup fails, error and stop workflow ("Dev server failed to start. Check logs and try again.")
- Track which elements used Chrome strategy vs. fallback (for debugging/reporting)

**Success Metric**: Phase 2 completes with 5+ locators generated via Chrome DevTools, server cleanly shut down.

### Phase 3: Advanced Error Handling and Edge Cases
**Builds on Phase 2**: Robust handling of ambiguous searches and validation failures

**Capabilities**:
- Multiple elements found: prompt developer with descriptions/screenshots ("Found 3 matches for 'submit button'. Which one? [Show details / Provide more specific description / Fall back to outerHTML]")
- Interaction test failures: warn but continue ("Warning: Locator interaction test failed. Locator: `page.getByRole('button', { name: 'Submit' })`. Continue anyway? [Yes / Try different approach / Fall back to outerHTML]")
- Fragile locator warnings: when only text/CSS available, add comment in POM ("// Warning: Text-based locator (no data-testid found). Consider adding semantic attributes.")
- Retry logic: if `find` fails, automatically retry `javascript_tool` with alternative selectors (by text, by position, by parent context)

**Success Metric**: Developer can resolve ambiguous/failed searches without workflow blockage, gets clear warnings for fragile locators.

### Phase 4: Developer Experience Polish
**Builds on Phase 3**: Improve feedback, performance, and discoverability

**Capabilities**:
- Progress indicators: "Inspecting element 3/7 in Chrome..."
- Performance optimization: cache DOM queries, reuse page context across elements
- Better prompts at Phase 2 start: "Generate locators via: [1. Chrome DevTools (inspect running app) / 2. UI repository analysis / 3. outerHTML (manual paste)]"
- Post-Phase 2 summary: "Generated 7 locators via Chrome DevTools (5 validated, 2 warnings). Server shut down."
- Documentation: update CLAUDE.md with Chrome DevTools strategy, troubleshooting guide for common errors

**Success Metric**: Developers understand when/why to choose Chrome strategy, get clear feedback throughout workflow.

## Module Structure
Not applicable (integrating into existing `playwright-locator-generator` agent).

## Open Questions

### Technical Discovery Needed
1. **Chrome MCP availability check**: What's the most reliable way to detect if Chrome MCP is running? (Try `tabs_context_mcp` and catch error, or query MCP server list?)
2. **Element disambiguation UI**: When `find` returns multiple matches, how do we present options to developer? (Text descriptions, screenshots via `computer` tool, or DOM paths?)
3. **Server shutdown timing**: Should we shut down immediately after Phase 2, or ask developer ("Keep server running for manual testing? [Yes / Shut down]")?
4. **Port conflict handling**: If default dev server port (3000, 5173, etc.) is occupied, retry with different port or error immediately?

### Validation Assumptions
5. **Interaction test scope**: For complex components (dropdowns, modals, custom widgets), is click/fill sufficient, or do we need component-specific validation?
6. **Performance baseline**: What's acceptable latency per element? (Target: <5s for find + extract + validate)
7. **Success rate target**: What % of elements should Chrome strategy successfully find/validate without fallback? (Hypothesis: 80%+ for standard UI, lower for custom components)

## Revised Assessment
- **Size**: FEATURE (multi-agent change: Phase 2 orchestration + playwright-locator-generator + error handling)
- **Greenfield**: Partially (new Chrome integration path, but reuses existing browser-verifier patterns and Chrome MCP tools)
- **Risk**: MODERATE (additive feature with graceful degradation, but complex error handling and developer-facing prompts require careful UX design)

---

## Collaboration Loop

**Status**: Awaiting review

[X] **Reviewed**: Does this capture what you're trying to build? (Check box if yes, or share adjustments needed)
