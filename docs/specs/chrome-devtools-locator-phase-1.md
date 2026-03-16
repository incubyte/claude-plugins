# Spec: Chrome DevTools Live Inspection - Phase 1 (Walking Skeleton)

## Overview
Add Chrome DevTools live inspection as a third locator generation strategy in the playwright-locator-generator agent. Phase 1 delivers end-to-end automated locator generation from a running localhost application for ONE element, with graceful degradation to outerHTML when Chrome MCP is unavailable.

This eliminates manual HTML copy-paste during Phase 2 of the playwright-bdd workflow, letting developers generate locators directly from their running app.

## Acceptance Criteria

### Dev Server Detection and Startup
- [ ] At Phase 2 start, detect dev server command from package.json scripts (priority: "dev" > "start" > "serve")
- [ ] Prompt developer with three options: "Start dev server using `npm run dev`?" / "Already running at URL" / "Use different command"
- [ ] If "Start dev server": execute command via Bash tool with run_in_background flag
- [ ] If "Already running": accept developer-provided URL and validate format (http:// or https://)
- [ ] If "Use different command": accept custom command and execute with run_in_background flag
- [ ] Verify server accessibility by attempting HTTP request to base URL
- [ ] Server fails to start or URL unreachable: show error with server logs and stop Phase 2
- [ ] Keep server running after locator generation (do not shut down in Phase 1)

### Chrome MCP Availability Check
- [ ] Before attempting Chrome strategy, call tabs_context_mcp to check Chrome MCP availability
- [ ] Chrome MCP unavailable: silently fall back to outerHTML prompt (no user notification)
- [ ] Chrome MCP available: proceed with live inspection strategy

### Chrome Tab Creation and Navigation
- [ ] Create fresh browser tab via tabs_create_mcp
- [ ] Navigate to dev server URL via navigate tool
- [ ] Wait for page load (check document.readyState via javascript_tool)
- [ ] Navigation fails: prompt "Page failed to load at [URL]. [Retry / Fall back to outerHTML / Stop]"

### Element Finding (Hybrid Approach)
- [ ] Use step description to attempt element finding via find tool first
- [ ] Element found uniquely: proceed to attribute extraction
- [ ] Element not found: generate CSS selector from step description and use javascript_tool with document.querySelector
- [ ] Multiple elements found: prompt "Found N matches for '[description]'. [Show details / Provide more specific description / Fall back to outerHTML]"
- [ ] If "Show details": display element descriptions (tag, visible text, attributes) and re-prompt for selection
- [ ] If "Provide more specific description": accept refined description and retry find tool
- [ ] javascript_tool fallback also returns zero matches: prompt "Element not found. [Retry with different selector / Fall back to outerHTML / Stop]"

### Attribute Extraction
- [ ] Extract all relevant attributes from found element: data-testid, data-test-id, data-test, role, aria-label, aria-labelledby, id, class, name, placeholder
- [ ] Extract visible text content via innerText
- [ ] For form inputs: extract associated label text via DOM traversal
- [ ] Extraction fails or returns empty: log warning and proceed with available attributes

### Locator Generation (Following Existing Priority)
- [ ] Generate locator using existing priority order: data-testid > role+name > label > placeholder > id > text > CSS
- [ ] Return locator in Playwright format: `page.getByRole(...)` or `[data-testid="..."]`
- [ ] Include stability assessment: stable / moderate / unstable
- [ ] For text-based locators: add warning "Locator uses text content - consider adding data-testid for stability"
- [ ] For CSS-based locators: add warning "Locator uses CSS classes - highly fragile, add data-testid"

### Interaction Testing
- [ ] Determine interaction type based on step description and element type
- [ ] For buttons/links: test click via computer tool
- [ ] For text inputs: test fill with dummy text via computer tool
- [ ] For other elements: test visibility via javascript_tool (check element.offsetParent !== null)
- [ ] Interaction test passes: return locator with success indicator
- [ ] Interaction test fails: prompt "Locator interaction test failed for '[locator]'. [Retry / Try different approach / Fall back to outerHTML / Stop]"
- [ ] If "Retry": re-attempt same interaction test once
- [ ] If "Try different approach": return to element finding with adjusted strategy

### Error Handling - Server Failures
- [ ] Dev server command not found in package.json: prompt "No dev server script detected. What command should I use?"
- [ ] Server process exits immediately: show exit code and logs, prompt "Server failed to start. [Check configuration / Provide different command / Fall back to outerHTML]"
- [ ] Server starts but URL returns 404/500: show HTTP status and response, prompt "Server not responding at [URL]. [Wait and retry / Try different URL / Fall back to outerHTML]"

### Error Handling - Chrome MCP Failures
- [ ] tabs_create_mcp fails: silently fall back to outerHTML (Chrome MCP unavailable)
- [ ] navigate fails after tab creation: prompt "Navigation failed: [error]. [Retry / Fall back to outerHTML / Stop]"
- [ ] javascript_tool execution error: log error, fall back to find tool or prompt for manual selector

### Error Handling - Element Ambiguity
- [ ] find tool returns array with 2+ elements: extract descriptions for all matches
- [ ] Show developer: tag name, visible text (first 50 chars), key attributes (id, class, data-testid if present)
- [ ] Developer selects by index: use that element
- [ ] Developer provides more specific description: retry find with refined query

### Error Handling - Validation Failures
- [ ] Locator validation test fails (element not clickable, not fillable): warn developer with specific error
- [ ] Developer chooses "continue anyway": proceed with locator despite validation failure
- [ ] Developer chooses "fall back": switch to outerHTML strategy for this element

### Graceful Degradation
- [ ] Chrome MCP unavailable at Phase 2 start: fall back to outerHTML prompt without notifying developer
- [ ] Chrome strategy fails for any reason: offer fallback to outerHTML with explanation
- [ ] Developer can choose outerHTML at any decision point during Chrome workflow
- [ ] outerHTML fallback uses existing locator-generator logic (no changes to HTML parsing path)

### Scope Limitation (Phase 1 Only)
- [ ] Generate locator for ONE element only (single step from Phase 2)
- [ ] Do not loop through multiple elements (that's Phase 2 of this feature)
- [ ] Do not shut down dev server after locator generation (keep alive for future use)
- [ ] Do not track which strategy was used (reporting comes in Phase 2 of this feature)

## API Shape

### Modified Agent: playwright-locator-generator

**New Input Parameters:**
```typescript
{
  stepDescription: string,        // Existing
  actionType: string,              // Existing
  uiRepoPath?: string,            // Existing
  outerHTML?: string,             // Existing
  devServerUrl?: string,          // NEW - if Chrome strategy enabled
  useChromeStrategy?: boolean     // NEW - flag to enable Chrome live inspection
}
```

**Modified Output:**
```typescript
{
  success: boolean,
  locator?: string,
  strategy?: string,              // e.g., "data-testid (from Chrome live inspection)"
  stability?: "stable" | "moderate" | "unstable",
  warning?: string,
  source?: string,                // e.g., "Chrome DevTools: http://localhost:3000"
  interactionTested?: boolean,    // NEW - true if interaction test passed
  error?: {
    type: string,
    message: string,
    userMessage: string,
    suggestions: string[]
  }
}
```

### Modified Orchestrator: playwright-bdd.md (Phase 2 Step)

**Step 10 Addition - Three-Option Choice:**

At Phase 2 start (before first locator generation), prompt developer:

```
"How should I generate locators?"
[1] Chrome DevTools (inspect running app)
[2] UI repository analysis
[3] outerHTML (manual paste)
```

**If Option 1 selected:**
- Run dev server detection and startup sequence
- Check Chrome MCP availability
- For each element in Phase 2:
  - Call playwright-locator-generator with useChromeStrategy=true and devServerUrl
  - Handle Chrome-specific errors per this spec
  - Fall back to outerHTML on failures per developer choice

**If Option 2 or 3 selected:**
- Use existing workflow unchanged

## Out of Scope

Phase 2-4 features explicitly NOT included in Phase 1:

### Phase 2 Features (Multi-Element + Lifecycle)
- Looping through all elements in Phase 2 (5-15 locators)
- Server shutdown after Phase 2 completes
- Tracking which elements used Chrome vs fallback strategy
- Summary report of Chrome strategy success rate

### Phase 3 Features (Advanced Error Handling)
- Automatic retry with alternative selectors
- Screenshot capture for ambiguous matches
- Fragile locator warnings in POM comments
- Advanced disambiguation UI

### Phase 4 Features (DX Polish)
- Progress indicators ("Inspecting element 3/7...")
- Performance optimization (DOM query caching)
- Better choice prompts with strategy explanations
- Post-Phase 2 summary with statistics

### Not Changed
- Existing locator priority order (data-testid > role > label > placeholder > id > text > CSS)
- Phase 2 POM structure and output format
- UI repo and outerHTML strategies (remain fully functional)
- Any other playwright-bdd phases (1, 3, 4, 5)

## Technical Context

### Files to Modify

**Primary Changes:**
- `/Users/akashincubyte/Documents/incubyte/Repo/claude plugins/claude-plugins/bee/agents/playwright/playwright-locator-generator.md`
  - Add Step 0a: Chrome MCP availability check
  - Add Strategy 3: Chrome DevTools live inspection (after repo analysis, before outerHTML)
  - Add interaction testing step
  - Add Chrome-specific error handling

**Secondary Changes:**
- `/Users/akashincubyte/Documents/incubyte/Repo/claude plugins/claude-plugins/bee/commands/playwright-bdd.md`
  - Modify Step 10 (Phase 2 start): add three-option locator strategy choice
  - Add dev server detection and startup logic
  - Add Chrome MCP availability check at Phase 2 start
  - Add server lifecycle tracking (start, keep alive)

### Integration Points

**Chrome MCP Tools (from browser-verifier pattern):**
- `tabs_context_mcp` - check availability
- `tabs_create_mcp` - create fresh tab
- `navigate` - load dev server URL
- `find` - natural language element search
- `javascript_tool` - DOM queries and interaction testing
- `computer` - click/fill actions for validation
- `read_console_messages` - error detection during testing

**Dev Server Detection (from browser-verifier):**
1. Check CLAUDE.md for documented commands
2. Check chat context for recent mentions
3. Fall back to package.json script analysis

**Error Handling Pattern (from PR #16):**
- Structured error objects with type, message, userMessage, suggestions
- No silent failures - all errors surfaced to developer
- Actionable next steps in every error message
- Differentiated handling by error severity

### Existing Patterns to Follow

**Locator Priority (from playwright-locator-generator.md lines 54-100):**
- Priority 1: data-testid (stable)
- Priority 2: role+name (stable, semantic)
- Priority 3: label (stable, forms)
- Priority 4: placeholder (moderate)
- Priority 5: id (moderate)
- Priority 6: text (unstable, warn)
- Priority 7: CSS (unstable, warn)

**Browser Tool Usage (from browser-verifier.md):**
- Always create fresh tab per session
- Verify page load via document.readyState check
- Handle navigation failures with retry prompts
- Console error checking during interaction

**Agent Error Handling (from PR #16 commit 540a929):**
- File read errors: track and warn
- LLM API failures: retry logic with rate limit detection
- Parse errors: comprehensive reporting with recovery steps
- All catch blocks log and report - no silent failures

## Risk Level

**MODERATE**

**Risk Factors:**
- User-facing prompts and decision points (UX complexity)
- External dependency on Chrome MCP (graceful degradation required)
- Dev server lifecycle management (startup, keep-alive)
- Network interactions (server accessibility, page load)
- Multiple failure modes requiring differentiated handling

**Mitigation:**
- Comprehensive error handling per PR #16 pattern
- Silent fallback when Chrome MCP unavailable (non-blocking)
- Clear prompts with 3-4 options at each decision point
- Graceful degradation preserves existing workflow functionality
- Phase 1 scoped to single element reduces complexity

**Adaptive Depth (MODERATE risk guidelines):**
- 4-6 interview questions covering edge cases
- Standard TDD plan with error scenario coverage
- Review recommends team review before merge

## Success Signal

Phase 1 is successful when:

1. **Developer can generate ONE validated locator from running app without manual HTML copy-paste**
2. **Chrome MCP unavailable → workflow silently falls back to outerHTML (no blockage)**
3. **Dev server fails to start → clear error with logs, prompts for resolution**
4. **Element not found → developer gets clear choices (retry/refine/fallback)**
5. **Interaction test fails → developer gets clear choices (retry/different approach/fallback)**
6. **All error paths have actionable next steps (no dead ends)**
7. **Existing outerHTML and UI repo strategies remain fully functional (no regression)**

Measurable outcome: Developer completes Phase 2 for a feature file with one UI step, choosing Chrome DevTools strategy, and receives a working locator that passes interaction testing, all without leaving the chat interface.
