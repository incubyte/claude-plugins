---
name: browser-testing
description: How to use Chrome MCP tools for browser-based verification. Tool reference, dev server detection, graceful degradation, and screenshot conventions.
---

# Browser Testing

Chrome MCP tools give you browser-level verification — navigate pages, read DOM content, check console errors, take screenshots, and interact with UI elements. When Chrome MCP is available, use it for holistic verification. When it's not, degrade gracefully based on mode.

This skill applies to any agent or command that performs browser-based verification — the browser-verifier agent (dev and test modes) and the browser-test command (standalone regression testing).

---

## Chrome MCP Tools

| Tool | What it does | When to use it |
|------|-------------|----------------|
| `tabs_context_mcp` | Get info about current browser tabs; checks if Chrome MCP is connected | Availability check (call first — if it errors, MCP is not connected) |
| `tabs_create_mcp` | Create a new empty tab in the MCP tab group | Opening a fresh tab for testing (don't reuse existing tabs) |
| `navigate` | Navigate to a URL or go forward/back in history | Loading the app at the target URL |
| `read_page` | Get accessibility tree representation of page elements | Verifying element presence, structure, and interactive states |
| `find` | Find elements by natural language description | Locating specific UI elements ("login button", "search bar") |
| `get_page_text` | Extract raw text content from the page | Verifying text content, reading article/page body |
| `computer` | Mouse/keyboard interaction and screenshots | Clicking buttons, typing in fields, scrolling, taking screenshots |
| `javascript_tool` | Execute JavaScript in the page context | Checking runtime state, reading JS variables, custom assertions |
| `read_console_messages` | Read browser console output (log, error, warn) | Checking for runtime errors, exceptions, and warnings |

---

## Dev Server Detection

Detection follows a priority order. Stop at the first successful detection.

### Step 1: Context sources (primary)

Check these first — developers often document their dev commands:
- **CLAUDE.md** in the target project — look for dev server commands, URLs, or run instructions
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

Check Chrome MCP availability once at the start, not per-operation.

1. Call `tabs_context_mcp`.
2. If it succeeds: Chrome MCP is available. Proceed with browser verification.
3. If it fails or errors: Chrome MCP is not connected. Degrade based on mode.

### Dev mode (called from `bee:build`)

- Report: "Browser verification skipped — Chrome MCP not available"
- **Do not block the build.** The regular verifier result (PASS) stands.
- The slice still passes. Browser verification is additive, not required.

### Test mode (called from `bee:browser-test`)

- Report: "Cannot run browser tests — Chrome MCP is not connected. Install the Claude in Chrome extension and ensure it's connected."
- **Stop.** There is no fallback — browser testing is the entire purpose of this command.

---

## Screenshot Conventions

### When to capture

- **Dev mode**: Only on failure — screenshot the failing state for developer review
- **Test mode**: Both pass and fail — full audit trail for regression reports

### How to capture

Use the `computer` tool with `action: "screenshot"`. This captures the current viewport.

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
