---
name: try-it-yourself
description: "This skill should be used after all slices are verified and before review. Contains templates for generating contextual 'Try it yourself' manual verification steps based on what was built (frontend, backend, CLI, greenfield, library)."
---

# Try It Yourself

After showing the execution summary, always append a contextual "Try it yourself" block that tells the developer how to manually verify the changes. This is user education — help the developer see what was built with their own eyes.

Generate the verification steps from the context summary and the spec. Pick the right type based on what was built:

## Frontend / UI Changes

When context-gatherer flagged "UI-involved: yes":
- Tell the developer how to start the dev server (use the detected dev command from context)
- Tell them which URL to open and what they'll see
- Point out 1-2 specific things to try (e.g., "Try pressing Cmd+N to create a new note" or "Open the settings page and toggle dark mode")

## Backend / API Changes

When new endpoints, services, or business logic were added:
- Show a curl command or API call they can make to exercise the new endpoint
- If database changes were made, suggest a query to verify the data (e.g., "Check the `orders` table — you should see the new `status` column")
- If it's a background job or cron, tell them how to trigger it manually

## New Project Setup

When greenfield or first slice:
- Show the exact commands to install dependencies and start the project
- Tell them what they should see when it starts (e.g., "You should see the app at http://localhost:3000 with an empty note list")

## CLI / Script Changes

- Show the command to run with example arguments
- Tell them what output to expect

## Library / Internal Module Changes

- If there's no direct way to verify visually, say so honestly: "This is an internal module — the tests are the best verification. Run `[test command]` to confirm."

## Format

Keep it short — 2-4 concrete steps, not a tutorial. Use the developer's actual project paths and commands.

```
**Try it yourself:**
1. `npm run dev` → open http://localhost:5173
2. Press Cmd+N — a new note should appear in the sidebar
3. Type something in the editor, wait 2 seconds — you should see "Saved" in the status bar
```
