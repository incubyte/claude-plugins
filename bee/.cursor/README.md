# Using Bee in Cursor

Bee is a spec-driven TDD workflow navigator. In Claude Code it runs as a plugin; Cursor doesn't support plugins, so this integration makes Bee available in Cursor using a **symlink** and a **Cursor rule**. After setup, you can use the same Bee workflows (build, discover, review) from any project.

**Prerequisites:** You have the Bee repo cloned somewhere on your machine (e.g. this repo).

**What this setup does:** Nothing is written to any database. You create a symlink so Cursor can find Bee at a fixed path, and you add a rule (either via Cursor’s UI or by adding a rule file to your project) so the agent knows to run Bee when you say "bee-build", "bee discover", or "bee review".

---

## One-time setup (per machine)

### Step 1: Symlink Bee into Cursor’s config

This makes Bee available at a fixed path the rule will use from any workspace.

```bash
ln -snf /absolute/path/to/bee/repo ~/.config/Cursor/bee
```

Replace `/absolute/path/to/bee/repo` with the real path to this Bee repo (e.g. `~/projects/bee` or `$HOME/Documents/Incubyte/git-repos/bee`).

Verify:

```bash
ls -la ~/.config/Cursor/bee
```

You should see `bee -> /absolute/path/to/bee/repo`.

### Step 2: Add the Bee rule in Cursor

You need a rule that tells the agent to run Bee when you say "bee-build", "bee discover", or "bee review". Use **one** of the two options below.

---

#### Option A: Rule in every project (good for teams)

Add the rule to each project that will use Bee. The rule lives in the repo, so your team gets it via git.

1. In your **project** (the repo where you write code), create the rules directory if it doesn’t exist:
   ```bash
   mkdir -p .cursor/rules
   ```
2. Copy the Bee rule into it:
   ```bash
   cp /path/to/bee/cursor-integration/bee-workflow.mdc .cursor/rules/
   ```
3. Commit `.cursor/rules/bee-workflow.mdc`. Everyone who clones the repo and has done Step 1 (symlink) on their machine will have Bee in that project.

**Requirement:** Each developer still needs to do **Step 1** (symlink) on their own machine so `~/.config/Cursor/bee` points to their Bee repo.

---

#### Option B: Rule for all your Cursor projects (per developer)

Add a rule in Cursor that applies to every project on your machine (no copy per repo).

1. Open **Cursor**.
2. Go to **Settings** (gear icon or File → Preferences) → **Cursor Settings**.
3. In the left sidebar, open **Rules, Skills, Subagents**.
4. In the **Rules** section, click **"+ New"**.
5. Create a new rule:
   - **Name/description:** e.g. "Bee workflow".
   - **Content:** Open `cursor-integration/bee-workflow.mdc` in this Bee repo. Paste the **rule body only** — everything from the first `# Bee workflow` heading to the end of the file (i.e. skip the YAML frontmatter at the top between the `---` lines).
   - If the UI asks for **scope** or **where to save:** choose **User** (or equivalent) so the rule applies in every workspace, not only the current project.
   - If there is an **Always apply** (or similar) option, turn it **on** so the rule is active in every chat.
6. Save.

After that, in any Cursor project you can say "bee-build", "bee discover", or "bee review" in chat and the agent will run Bee. You only need the symlink from Step 1.

---

## Usage

In a Cursor project where the Bee rule is active, open the chat and say:

| You say | What runs |
|--------|-----------|
| **bee-build** or **bee build** or **start bee workflow** | Full Bee build workflow: triage → spec → plan → execute → review. |
| **bee-build** *&lt;task&gt;* (e.g. **bee-build add user authentication**) | Same workflow, with your task as the starting description. |
| **bee-discover** or **bee discover** | Discovery session: PM-style interview, outputs a PRD. |
| **bee-playwright** *&lt;path&gt;* (e.g. **bee-playwright /path/to/feature.feature**) | Generate Playwright-BDD tests from Gherkin: step definitions → POMs → services → utilities → scenario outlines. |
| **bee-review** or **bee review** | Standalone code review: hotspots, tech debt, coaching. |

State and artifacts (e.g. `docs/specs/.bee-state.md`, specs, plans) are stored in the **current project**, so you can close and reopen the project and resume later.

---

## How paths work

- **Bee’s own files** (commands, agents, skills) are read from `~/.config/Cursor/bee/` — i.e. the symlink you created.
- **Project artifacts** (specs, state, ADRs, TDD plans) are read and written in the **workspace root** — the project you have open in Cursor.

Bee’s logic stays in one place; your specs and state stay in each repo.

---

## If you move or clone the Bee repo

Update the symlink to the new path:

```bash
ln -snf /new/path/to/bee ~/.config/Cursor/bee
```

You don’t need to change the rule; it always uses `~/.config/Cursor/bee`.
