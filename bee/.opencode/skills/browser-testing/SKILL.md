---
name: browser-testing
description: "This skill should be used when running browser-based verification. Supports two providers: Claude-in-Chrome (primary) and chrome-devtools-mcp (fallback). Contains tool reference, dev server detection, screenshot conventions, and graceful degradation."
---

# Browser Testing

Browser MCP tools give you browser-level verification — navigate pages, read DOM content, check console errors, take screenshots, and interact with UI elements.

This skill applies to any agent or command that performs browser-based verification — the browser-verifier agent (dev and test modes) and the browser-test command (standalone regression testing).

---

## Provider Detection (Do This First)

Bee supports two browser MCP providers. Try them in order — use whichever is available.

### Step 1: Try Claude-in-Chrome (primary)

Call `tabs_context_mcp` (tool: `mcp__claude-in-chrome__tabs_context_mcp`).

- If it succeeds → **use Claude-in-Chrome** for this session. See the Claude-in-Chrome tool table below.
- If it fails or the tool is not found → continue to Step 2.

### Step 2: Try chrome-devtools-mcp (fallback)

Use `tool schema search (not needed on opencode)` with query `"+chrome-devtools-mcp"` to discover chrome-devtools-mcp tools.

- If tools are found, call `list_pages` (tool: `mcp__plugin_chrome-devtools-mcp_chrome-devtools__list_pages`).
  - If it succeeds → **use chrome-devtools-mcp** for this session. See the chrome-devtools-mcp tool table below.
  - If it fails → plugin is installed but browser is not connected. Tell the user: "chrome-devtools-mcp is installed but the browser is not connected. See https://github.com/nicobailon/chrome-devtools-mcp for setup instructions."
- If no tools found → no browser MCP available. Degrade based on mode (see Graceful Degradation).

### Step 3: No provider available

Tell the user:

> "Browser verification requires a browser MCP provider. Install one of these:
> 1. **Claude-in-Chrome** extension — install from Chrome Web Store
> 2. **chrome-devtools-mcp** plugin — install from the Claude Code plugin marketplace: `claude plugins install chrome-devtools-mcp`"

Then degrade based on mode.

**Important:** Decide the provider ONCE at the start of the session. Do not re-check per operation. Use the chosen provider's tools consistently throughout.

---

## Claude-in-Chrome Tools

Tools are prefixed with `mcp__claude-in-chrome__`.

| Tool | What it does | When to use it |
|------|-------------|----------------|
| `tabs_context_mcp` | Get info about current browser tabs | Availability check |
| `tabs_create_mcp` | Create a new empty tab | Opening a fresh tab for testing |
| `navigate` | Navigate to a URL | Loading the app at the target URL |
| `read_page` | Get accessibility tree of page elements | Verifying element presence, structure, interactive states |
| `find` | Find elements by natural language description | Locating specific UI elements ("login button", "search bar") |
| `get_page_text` | Extract raw text content from the page | Verifying text content |
| `computer` | Mouse/keyboard interaction and screenshots | Clicking, typing, scrolling, taking screenshots |
| `javascript_tool` | Execute JavaScript in page context | Checking runtime state, custom assertions |
| `read_console_messages` | Read browser console output | Checking for runtime errors, exceptions, warnings |

### Workflow Pattern (Claude-in-Chrome)

1. `tabs_context_mcp` → check availability
2. `tabs_create_mcp` → open fresh tab
3. `navigate` → load the app URL
4. `read_page` → verify page structure
5. `find` / `computer` → interact with elements
6. `read_page` or `computer` (screenshot) → verify outcome
7. `read_console_messages` → check for errors

### Screenshots (Claude-in-Chrome)

Use `computer` with `action: "screenshot"` to capture the current viewport.

---

## chrome-devtools-mcp Tools

Tools are prefixed with `mcp__plugin_chrome-devtools-mcp_chrome-devtools__`.

| Tool | What it does | When to use it |
|------|-------------|----------------|
| `list_pages` | List available browser pages/tabs | Availability check |
| `new_page` | Open a new browser page | Opening a fresh page for testing |
| `navigate_page` | Navigate to a URL | Loading the app at the target URL |
| `take_snapshot` | Get page structure with element `uid`s (text-based, fast) | Verifying element presence; getting `uid`s for interaction |
| `take_screenshot` | Capture visual screenshot | Visual verification, audit trail |
| `click` | Click an element by `uid` | Buttons, links, checkboxes |
| `fill` | Fill an input field by `uid` | Text inputs, textareas |
| `fill_form` | Fill multiple form fields at once | Forms with multiple inputs |
| `type_text` | Type text (keyboard-level) | Typing into focused elements |
| `press_key` | Press a specific key | Enter, Escape, Tab, arrow keys |
| `hover` | Hover over an element by `uid` | Hover states, tooltips |
| `select_page` | Switch to a different page/tab | Multi-page workflows |
| `evaluate_script` | Execute JavaScript in page context | Runtime state, custom assertions |
| `list_console_messages` | List browser console messages | Runtime errors, exceptions, warnings |
| `get_console_message` | Get details of a specific console message | Inspecting a particular error |
| `list_network_requests` | List network requests | Checking API calls, failed requests |
| `get_network_request` | Get details of a specific request | Inspecting request/response payloads |
| `wait_for` | Wait for a condition (element, text, network idle) | Ensuring page is loaded before interacting |
| `resize_page` | Resize the browser viewport | Testing responsive layouts |
| `close_page` | Close a browser page | Cleanup after testing |
| `lighthouse_audit` | Run a Lighthouse audit | Performance and accessibility checks |

### Workflow Pattern (chrome-devtools-mcp)

1. `list_pages` → check availability
2. `new_page` → open fresh page
3. `navigate_page` → load the app URL
4. `wait_for` → ensure content is loaded
5. `take_snapshot` → get element `uid`s
6. `click` / `fill` / `press_key` → interact using `uid`s from snapshot
7. `take_snapshot` or `take_screenshot` → verify outcome
8. `list_console_messages` → check for errors

### Screenshots (chrome-devtools-mcp)

Use `take_screenshot`. For large pages, use the `filePath` parameter to save directly to disk.

---

## Dev Server Detection

Detection follows a priority order. Stop at the first successful detection.

### Step 1: Context sources (primary)

Check these first — developers often document their dev commands:
- **AGENTS.md** in the target project — look for dev server commands, URLs, or run instructions
- **Prior chat context** — the developer may have mentioned the command or URL earlier in the conversation

### Step 2: Ecosystem analysis (fallback)

If context sources don't have the info, analyze the project:

| Ecosystem | Files to check | Common dev commands | Default URL |
|-----------|---------------|-------------------|-------------|
| Node.js / npm | `package.json` scripts | `npm run dev`, `npm start`, `next dev`, `vite` | `http://localhost:3000` |
| Python | `manage.py`, `pyproject.toml` | `python manage.py runserver`, `flask run`, `uvicorn` | `http://localhost:8000` |
| Ruby | `Gemfile`, `Procfile` | `rails server`, `bundle exec rails s` | `http://localhost:3000` |
| Go | `go.mod`, `Makefile` | `go run .`, `make dev` | `http://localhost:8080` |
| Rust | `Cargo.toml` | `cargo run`, `trunk serve` | `http://localhost:8080` |
| Java | `pom.xml`, `build.gradle` | `./mvnw spring-boot:run`, `./gradlew bootRun` | `http://localhost:8080` |
| Elixir | `mix.exs` | `mix phx.server` | `http://localhost:4000` |

### Step 3: Ask the developer

After detection (or if nothing found), always confirm:
"Should I run `{detected-command}` and test on `{default-uri}`, or do you want to provide a different starting point URI?"

If nothing was detected, ask directly: "What command starts the dev server, and what URL should I test on?"

---

## Graceful Degradation

### Dev mode (called from `bee-sdd`)

- Report: "Browser verification skipped — no browser MCP provider available"
- **Do not block the build.** The regular verifier result (PASS) stands.
- The slice still passes. Browser verification is additive, not required.

### Test mode (called from `bee-browser-test`)

- Report the specific issue (no provider found, or browser not connected) with the install instructions from Provider Detection Step 3.
- **Stop.** There is no fallback — browser testing is the entire purpose of this command.

---

## Screenshot Conventions

### When to capture

- **Dev mode**: Only on failure — screenshot the failing state for developer review
- **Test mode**: Both pass and fail — full audit trail for regression reports

### Storage path

Screenshots are stored alongside test reports:
```
tests/executions/{YYYY-MM-DD}/{specname}-screenshot-{ac-number}.png
```

Create the directory structure if it doesn't exist.

### Referencing in reports

In the test mode report, reference screenshots by relative path:
```markdown
- [x] PASS: User can log in with email/password
  Screenshot: `user-auth-screenshot-1.png`
- [ ] FAILED: Dashboard shows recent activity
  Screenshot: `user-auth-screenshot-2.png`
  Expected: Recent activity section visible with at least one entry
  Observed: Section not rendered, console error: "TypeError: Cannot read property 'map' of undefined"
```
