# Bee Architecture

**Status:** v1 opencode port implemented (symlink install). See Section 3.5.
**Owner:** bhavesh80
**Last updated:** 2026-04-25

This document is the authoritative reference for Bee's internal architecture after the multi-platform refactor. It exists to prevent architectural drift during the 6-8 week refactor described in [`docs/brainstorms/opencode-advanced-integration-brainstorm.md`](./brainstorms/opencode-advanced-integration-brainstorm.md).

Read this before making changes to `bee/commands/`, `bee/agents/`, `bee/skills/`, or either platform's plugin code.

---

## 1. Design Principles

1. **Single source of truth for knowledge.** Orchestration logic, workflow rules, domain heuristics — all live in skills, which are platform-agnostic markdown files shared between Claude Code and opencode.
2. **Platform-native wiring.** Commands and agent files look native to each host. No runtime regex transformation. No pretending opencode is Claude.
3. **Thin shells, thick skills.** Commands are ~40-60 lines of wiring. Agents are frontmatter + shared prompt. The heavy work lives in skills.
4. **Files on disk, not dynamic registration.** Everything opencode and Claude Code need to discover Bee is on disk in the path they already scan. No plugin tricks for agent registration.
5. **Plugins do one job well.** Plugin code only does what cannot be expressed as a file on disk: register the skills path, inject a one-time bootstrap, provide the `bee_state` custom tool. Nothing else.
6. **Borrow patterns, not code.** omo's ideas (category routing, background agents, init-deep, skill-embedded MCPs) get re-expressed in Bee's idiom. Bee doesn't depend on omo.
7. **DHH-aligned scope.** Duplicating thin platform wrappers is cheaper than maintaining a transformation engine. We accept some duplication at the wiring layer in exchange for simpler mental models.

---

## 2. Three-Layer Architecture

Bee has three kinds of artifacts. Each serves a distinct purpose. Keeping them separate is what makes multi-platform support cheap.

```
┌─────────────────────────────────────────────────────────────┐
│  SKILLS (portable knowledge)                                │
│  bee/skills/<name>/SKILL.md                                 │
│  Shared across all platforms. No platform-specific wiring.  │
│  Loaded on-demand by agents and commands.                   │
└─────────────────────────────────────────────────────────────┘
              ▲
              │ loaded by
              │
┌─────────────────────────────────────────────────────────────┐
│  AGENTS (specialist personas)                               │
│  bee/agents/<name>/prompt.md   ← shared prompt              │
│  .claude-plugin/agents/<name>.md   ← Claude frontmatter     │
│  .opencode/agents/<name>.md         ← opencode frontmatter  │
│  Platform file = frontmatter + {{include: prompt.md}}       │
└─────────────────────────────────────────────────────────────┘
              ▲
              │ delegated to (via Task / @mention)
              │
┌─────────────────────────────────────────────────────────────┐
│  COMMANDS (user-facing entry points)                        │
│  .claude-plugin/commands/<name>.md (Claude, uses Task)      │
│  .opencode/commands/<name>.md       (opencode, uses @mention)│
│  ~40-60 lines each. Load shared skills. Delegate to agents. │
└─────────────────────────────────────────────────────────────┘
```

### Rule of thumb for where content goes

Ask "where is this useful?":

| Content | Goes in |
|---|---|
| "How to write a spec" | skill (portable knowledge) |
| "When running SDD, do A then B then C" | skill (portable knowledge, loaded by sdd command) |
| "The slice-coder agent's system prompt" | `bee/agents/slice-coder/prompt.md` (shared) |
| "slice-coder's Claude frontmatter (model, allowed-tools)" | `.claude-plugin/agents/slice-coder.md` |
| "slice-coder's opencode frontmatter (category, tools)" | `.opencode/agents/slice-coder.md` |
| "User types `/bee:sdd` — what happens?" | `.claude-plugin/commands/sdd.md` (thin, delegates via Task) |
| "User types `/bee-sdd` — what happens?" | `.opencode/commands/sdd.md` (thin, delegates via @mention) |

If content could live in a skill, it should. Commands and agent wrappers should be small enough that duplicating them per platform is trivial.

---

## 3. Directory Layout (Target State)

```
incubyte-ai-plugins/
├── .claude-plugin/                       ← marketplace manifest (not bee-specific)
│   └── marketplace.json
│
├── bee/                                  ← the Bee plugin
│   ├── .claude-plugin/plugin.json        ← Bee's Claude Code manifest
│   ├── .claude/hooks/                    ← Claude-specific hooks (existing)
│   │
│   ├── skills/                           ← SHARED knowledge (single source, both platforms read)
│   │   ├── review-orchestration/SKILL.md  ← NEW (from review.md extraction)
│   │   ├── sdd-orchestration/SKILL.md     ← NEW (from sdd.md extraction)
│   │   ├── brainstorming/SKILL.md         ← existing
│   │   ├── spec-writing/SKILL.md          ← existing
│   │   ├── ... (19 existing + a few NEW for borrowed-omo features)
│   │
│   ├── agents/                           ← SOURCE OF TRUTH (Claude agents, editable)
│   │   ├── slice-coder.md                 ← developer edits this
│   │   ├── review-code-quality.md         ← Claude Code reads these directly
│   │   └── ... (35 agents)
│   │
│   ├── commands/                         ← Claude commands (thin, ~40 lines each)
│   │   ├── review.md                      ← NEW thin version
│   │   ├── sdd.md                         ← thin version (Phase 0)
│   │   └── ... (12 commands)
│   │
│   ├── scripts/
│   │   ├── update-bee-state.sh            ← existing
│   │   ├── generate-opencode-agents.py    ← NEW: generator script
│   │   └── generate-opencode-commands.py  ← NEW Phase 1
│   │
│   ├── .opencode/                        ← GENERATED + opencode-native wiring
│   │   ├── agents/                        ← generated from bee/agents/
│   │   │   ├── slice-coder.md
│   │   │   └── ... (35 generated files)
│   │   ├── commands/                      ← generated from bee/commands/
│   │   │   └── ... (12 generated files)
│   │   └── bin/
│   │       ├── install.sh                 ← creates ~/.config/opencode symlinks
│   │       └── uninstall.sh               ← reverses install (safe, bee-only)
│   │
│   ├── routing.json                      ← Claude routing (Phase 2)
│   └── README.md, AGENTS.md, LICENSE
│
└── docs/
    ├── ARCHITECTURE.md                    ← this file
    ├── CONTRIBUTING.md                    ← "adding a new command/agent/skill"
    ├── brainstorms/
    └── specs/
```

**Key files to track mentally:**
- `bee/agents/<name>.md` = source of truth. Developers edit these.
- `bee/.opencode/agents/<name>.md` = generated. Never edit directly.
- `bee/skills/<name>/SKILL.md` = shared. Both platforms read these as-is.
- `bee/commands/<name>.md` = Claude command. Source of truth for command shells.
- `bee/.opencode/commands/<name>.md` = generated (Phase 1) or written natively if opencode wiring differs enough.

### 3.5 Opencode install mechanism (symlinks into the user's config dir)

Opencode does **not** auto-discover agents/commands/skills bundled inside a plugin directory. Confirmed against [opencode source](https://github.com/anomalyco/opencode) on 2026-04-25:

- `ConfigPaths.directories()` (`packages/opencode/src/config/paths.ts`) returns exactly four kinds of location: the global config dir (`~/.config/opencode/`), walked-up `.opencode/` dirs from cwd, `~/.opencode/`, and `$OPENCODE_CONFIG_DIR`. Plugin install paths are not in that list.
- `ConfigAgent.load(dir)` and `ConfigCommand.load(dir)` are only called over those four sources (`packages/opencode/src/config/config.ts`).
- The plugin hook interface (`packages/plugin/src/index.ts`) exposes `tool`, `auth`, `provider`, `chat.*`, `permission.ask`, `tool.execute.*`, `experimental.*` — but **no agent or command registration hook**. The `config(cfg)` hook returns `Promise<void>` and is called after the agent service has already read `cfg.agent`, so mutating it is too late.
- The official docs (`packages/web/src/content/docs/agents.mdx`) explicitly list only `~/.config/opencode/agents/` and `.opencode/agents/` as markdown-agent locations.

The only viable install path is (C): materialize bee's content inside the user's opencode config dir. We do this with **symlinks**, so plugin updates flow through without re-copying:

```
~/.config/opencode/
├── agents/
│   ├── bee-slice-coder.md      -> <plugin>/bee/.opencode/agents/slice-coder.md
│   └── ... (35 per-file symlinks)
├── commands/
│   ├── bee-sdd.md              -> <plugin>/bee/.opencode/commands/sdd.md
│   └── ... (12 per-file symlinks)
├── skills/
│   └── bee                     -> <plugin>/bee/skills/                (directory symlink)
└── bee/
    └── scripts                 -> <plugin>/bee/scripts/               (directory symlink)
```

**Per-file for agents and commands** — not a directory symlink — because opencode's `configEntryNameFromPath` derives the entity name by stripping the first `/agent(s)/` or `/command(s)/` path segment and keeping the rest. A directory symlink like `agents/bee -> ...` would yield names like `bee/slice-coder`, which is ugly in `@` mentions and cross-references. Per-file links with `bee-` prefix give us clean flat names (`bee-slice-coder`, `/bee-sdd`).

**Directory symlink for skills** — because opencode reads skill name from the SKILL.md frontmatter, not from the path, so directory nesting is irrelevant. Opencode's skill scanner uses the recursive pattern `{skill,skills}/**/SKILL.md`.

**Directory symlink for scripts** — `bee/scripts/update-bee-state.sh` is invoked from command bodies via the fixed path `$HOME/.config/opencode/bee/scripts/update-bee-state.sh`. The generator rewrites `${CLAUDE_PLUGIN_ROOT}/scripts/...` references in command bodies to that location.

The install script (`bee/.opencode/bin/install.sh`) is idempotent and refuses to overwrite non-bee files; the uninstaller (`bee/.opencode/bin/uninstall.sh`) only removes symlinks that point back into the plugin directory.

### What got renamed / moved

| Old | New | Why |
|---|---|---|
| `bee/commands/*.md` (600+ line heavy commands) | `.claude-plugin/commands/*.md` (thin) + `bee/skills/<name>-orchestration/SKILL.md` | Split wiring from knowledge |
| `bee/agents/<name>.md` (single file) | `bee/agents/<name>/prompt.md` (shared) + `.claude-plugin/agents/<name>.md` (frontmatter wrapper) | Shared prompt, per-platform frontmatter |
| `bee/skills/<name>/<name>.md` (if named that way) | `bee/skills/<name>/SKILL.md` | Opencode convention; Claude still finds it |
| `.opencode/plugins/bee.js` (11KB, does too much) | `.opencode/plugin/bee.js` (~100 lines) | Shrinks to genuine platform-specific work |
| `bee/.claude/`, `bee/.cursor/` (unused legacy dirs) | deleted | Clean up |

---

## 4. The Generator (Write Once, Generate the Twin)

Platform hosts (Claude Code, opencode) do not expose a hook for resolving custom include directives at file-read time. An earlier version of this doc proposed a `{{include: ...}}` mechanism resolved at load time; pilot testing in April 2026 confirmed that directive would appear as literal text in the agent's system prompt, breaking the agent. See [`docs/brainstorms/pilot-phase-0-findings.md`](./brainstorms/pilot-phase-0-findings.md) for the full investigation.

Instead, we use a **build-step generator**: one file per agent is the editable source of truth (the Claude agent file); a script transforms it into the opencode twin. Both files are committed. CI enforces that the generated files are up-to-date.

### Source of truth

The Claude agent file at `bee/agents/<name>.md` is the **only** file a developer edits. It contains full frontmatter, full prompt body, and any Claude-specific conventions (`skills:` auto-load, `<example>` blocks, `color:`, etc.).

### Generator

`bee/scripts/generate-opencode-agents.py` — Python script (~130 lines). For each `bee/agents/<name>.md`:

1. Parse the Claude frontmatter (tolerant of `<example>` blocks and other Claude-specific embellishments).
2. Transform to opencode's frontmatter schema: `name`, `description`, `mode: subagent`, `category` (inferred by name prefix — `review-*` → `reviewing`, `tdd-planner-*` → `planning`, etc.).
3. Drop Claude-only fields (`color`, `skills`, `allowed-tools`, `<example>` blocks).
4. Prepend to the body: *"Before starting, load these skills using the skill tool: ..."* — since opencode does not auto-load skills from frontmatter.
5. Write to `bee/.opencode/agents/<name>.md`.

Usage:

```bash
# Regenerate all agents
python3 bee/scripts/generate-opencode-agents.py

# Regenerate one
python3 bee/scripts/generate-opencode-agents.py review-code-quality
```

### Category inference

The category determines which model an agent uses (see Section 7: Category-Based Model Routing). Current heuristic by name prefix:

| Prefix / name | Category |
|---|---|
| `review-*`, `reviewer`, `sdd-verifier`, `verifier` | `reviewing` |
| `tdd-planner-*`, `spec-builder`, `discovery`, `architecture-*`, `context-gatherer`, `domain-language-extractor`, `qc-planner` | `planning` |
| `slice-*`, `tdd-coder`, `tdd-ping-pong`, `tdd-test-writer`, `programmer` | `deep-work` |
| `design-agent`, `browser-verifier` | `visual` |
| `onboard`, `recap` | `teaching` |
| `quick-fix`, `tidy` | `quick-work` |

New agents that don't match a prefix default to `deep-work` and should be given an explicit prefix mapping in the generator.

### Why a generator instead of a runtime transform?

- **Debuggable.** Generated files are committed and visible. If an opencode user reports a broken agent, you can inspect the file they have.
- **Zero runtime cost.** No regex on every message, no plugin hook latency.
- **Platform-agnostic.** Works even if a host's plugin API is limited (opencode's `experimental.chat.messages.transform` is experimental and per-message).
- **CI-friendly.** `git diff` after running the generator should be empty on main. A CI check runs `generate-opencode-agents.py` then verifies no files changed — fails the build if a developer forgot to regenerate.

### Developer workflow

```bash
# Edit an agent
$EDITOR bee/agents/slice-coder.md

# Regenerate the opencode twin
python3 bee/scripts/generate-opencode-agents.py slice-coder

# Commit both files together
git add bee/agents/slice-coder.md bee/.opencode/agents/slice-coder.md
git commit
```

A pre-commit hook (`bee/.claude/hooks/` on the Claude side or a Git hook) can automate step 2 so developers can't forget.

---

## 5. Platform Wrappers — Concrete Examples

### Example: `review-code-quality` agent

**Source** (`bee/agents/review-code-quality.md`) — the file developers edit:

```markdown
---
name: review-code-quality
description: Use this agent to review code against clean code principles — SRP, DRY, YAGNI, naming, ...

<example>
Context: /bee:review spawns this specialist
user: "Review the orders module"
...
</example>

model: inherit
color: magenta
tools: ["Read", "Glob", "Grep", "mcp__lsp__hover", "mcp__lsp__document-symbols"]
skills:
  - clean-code
  - architecture-patterns
  - lsp-analysis
---

You are a specialist review agent focused on code quality — the craftsmanship principles that make code maintainable, readable, and correct.

... (~75 lines of prompt body)
```

**Generated** (`bee/.opencode/agents/review-code-quality.md`) — produced by `generate-opencode-agents.py`, also committed:

```markdown
---
name: review-code-quality
description: Use this agent to review code against clean code principles — SRP, DRY, YAGNI, naming, ...
mode: subagent
category: reviewing
---

Before starting, load these skills using the skill tool: `clean-code`, `architecture-patterns`, `lsp-analysis`.

You are a specialist review agent focused on code quality — the craftsmanship principles that make code maintainable, readable, and correct.

... (same ~75 lines of prompt body, byte-identical to source)
```

What changed between source and generated:

- `color: magenta` dropped (Claude-only)
- `tools:` array dropped (opencode uses its own tool permissioning; agents don't need to declare here)
- `skills:` frontmatter dropped, replaced by an explicit skill-load instruction prepended to body (opencode does not auto-load from frontmatter)
- `<example>` block dropped (Claude-specific documentation aid)
- `mode: subagent` added (opencode requires it)
- `category: reviewing` added (inferred from `review-*` prefix)
- Body preserved byte-for-byte

### Example: `/bee:review` command

**Claude command** (`bee/commands/review.md`) — thin, ~40 lines:

```markdown
---
description: Standalone code review with hotspot analysis, ...
allowed-tools: ["Read", "Grep", "Glob", "Bash(gh:*)", ..., "AskUserQuestion", "Skill", "Task"]
---

You are Bee running a standalone code review.

## Load skills

Before doing any work, load these skills:

- `review-orchestration` — how to run the review (scope, parallel spawn, merging, roadmap)
- `code-review` — Critical/Suggestions/Nitpicks framework
- `clean-code`, `tdd-practices`, `ai-ergonomics`

## Delegation

Spawn 7 specialists in parallel using the Task tool with `subagent_type: bee:<agent-name>`:
- `bee:review-behavioral`, `bee:review-code-quality`, ...

Follow the skill's merging, hotspot-enrichment, and roadmap rules.

## Argument

What to review: $ARGUMENTS
```

**Opencode command** (`bee/.opencode/commands/review.md`) — same structure, different delegation syntax. Generated by a sibling generator script (Phase 1 deliverable): reads the Claude command, transforms `Task` tool references to opencode's subagent invocation, adjusts `allowed-tools` to opencode's schema.

The 170 lines of review orchestration logic live **once** in `bee/skills/review-orchestration/SKILL.md`, loaded by both platforms' commands.

### Example: `/bee:sdd` command

**Claude command** (`.claude-plugin/commands/sdd.md`):

```markdown
---
description: Spec-driven development workflow
argument-hint: <spec-path or task description>
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, AskUserQuestion, Skill, Task]
---

Load the `sdd-orchestration` skill using the Skill tool. Follow it.

When the skill says "delegate to the <agent>", use the Task tool to
invoke `.claude-plugin/agents/<agent>.md`.

When the skill says "ask the developer", use AskUserQuestion.

State tracking: use `bee/scripts/update-bee-state.sh`.

Argument: $ARGUMENTS
```

**Opencode command** (`.opencode/commands/sdd.md`):

```markdown
---
description: Spec-driven development workflow
argument-hint: <spec-path or task description>
---

Load the `sdd-orchestration` skill using the skill tool. Follow it.

When the skill says "delegate to the <agent>", use the Task tool to
invoke the `<agent>` subagent (registered via .opencode/agents/).

When the skill says "ask the developer", use the question tool.

State tracking: use the bee_state custom tool.

Argument: $ARGUMENTS
```

The 600 lines of workflow logic live in `bee/skills/sdd-orchestration/SKILL.md`. Both commands are ~20 lines. Both platforms invoke Task (opencode's Task tool exists for primary→subagent delegation).

---

## 6. Plugin Surfaces — What Each Plugin Does

### Claude Code plugin (`.claude-plugin/plugin.json`)

Claude Code reads `.claude-plugin/` natively. Manifest declares commands, agents, hooks. No custom code needed beyond what exists today.

### Opencode (markdown install, no JS plugin in v1)

Opencode v1 ships **no JavaScript plugin**. Bee's content (agents, commands, skills, state script) is picked up by opencode's standard scanners once the install script has dropped symlinks into `~/.config/opencode/`. See Section 3.5 for the layout.

Claude-parity features the user actually cares about are native to opencode and require no bridging code:

- **Parallel subagent dispatch** — opencode's `task` tool accepts `subagent_type: <name>` identical to Claude's `Task`. Calling it multiple times in one turn runs subagents in parallel, same as Claude Code.
- **Native tool calling** — `read`, `write`, `edit`, `bash`, `grep`, `glob`, `question`, `todowrite`, `skill`, `websearch`, `webfetch` cover everything bee commands reference (generator does the PascalCase → lowercase rewrites).
- **Skill loading** — opencode's `skill` tool reads Bee's SKILL.md files from `~/.config/opencode/skills/bee/` the same way Claude Code reads them from the plugin skills dir.
- **State script** — the `update-bee-state.sh` shell script works unchanged; command bodies call it via `$HOME/.config/opencode/bee/scripts/update-bee-state.sh` (install symlink).

A future v2 plugin (`.opencode/plugin/bee.js`) could add: auto-install on first session, a `bee_state` custom tool to replace the shell script, and prompt injection via `experimental.chat.system.transform`. None of that is required for Claude parity and it is intentionally deferred.

What the install does NOT do:

- ❌ Transform tool names at runtime — rewrites happen once, in the generator
- ❌ Register commands or agents dynamically — opencode does not expose that hook
- ❌ Rewrite frontmatter at load time — the generated opencode files already match opencode's schema
- ❌ Intercept subagent invocations — native `task` tool is enough

---

## 7. Category Metadata + Opt-In Routing (Phase 2)

**Default: Bee never pins a model on any agent.** The user picks their model at the opencode TUI / Claude Code session level, and every Bee agent runs with whatever they chose. Pinning a model in agent frontmatter would override the user's choice, which we don't do.

**The `category:` field is metadata, not a mandate.** Every generated opencode agent gets a `category` (e.g., `reviewing`, `planning`, `deep-work`) based on what kind of work the agent does. On its own, the category does nothing — it's just a tag.

**Optional routing via `routing.json`.** Users who *want* multi-model orchestration (à la omo's Sisyphus pattern) can opt in by adding a `routing.json` that maps category → model. When present, the platform wrapper resolves the mapping at agent-spawn time. When absent (the default), categories are ignored and the user's chosen model runs every agent.

### Categories

| Category | Intended model class | Bee agents |
|---|---|---|
| `planning` | Strong reasoning (Opus / Kimi K2.6) | spec-builder, discovery, tdd-planner-* |
| `deep-work` | Long-context, high-capability | slice-coder, slice-tester, programmer |
| `quick-work` | Fast, cheap | quick-fix, tidy |
| `visual` | Visual-capable | design-agent, browser-verifier |
| `reviewing` | Thorough, careful | reviewer, review-* |
| `teaching` | Explanatory | onboard, coach, help |

### `routing.json` (user-authored, optional)

Bee does **not** ship a default `routing.json`. Users who want category-based model routing create one themselves, e.g.:

```json
{
  "planning": "anthropic/claude-opus-4-7",
  "deep-work": "anthropic/claude-sonnet-4-6",
  "quick-work": "anthropic/claude-haiku-4-5",
  "visual": "anthropic/claude-sonnet-4-6",
  "reviewing": "anthropic/claude-opus-4-7",
  "teaching": "anthropic/claude-sonnet-4-6"
}
```

Opencode users can use opencode-flavored provider prefixes (`opencode-go/...`, `kimi-for-coding/...`). Claude users use Claude Code's own model IDs.

### Resolution

When an agent is invoked:
- If `routing.json` exists AND has an entry for the agent's category → use that model.
- Otherwise → use the model the user already has selected (their TUI choice). **This is the default path, and the one we design for.**

No routing config = Bee stays out of model-picking entirely.

---

## 8. Borrowed omo Patterns — How They Map

### Adopted

| omo pattern | Bee expression | Phase |
|---|---|---|
| Discipline agents / category routing | `routing.json` + category frontmatter | 2 |
| Background agents (parallel fire) | `bee_background` tool + `parallel-execution` skill | 3 |
| `/init-deep` hierarchical context | `/bee:init` + `context-generation` skill | 4 |
| Skill-embedded MCPs | `mcps:` field in skill frontmatter; plugin spins up on load | 5 |
| IntentGate | `intent-classification` skill; loaded by every top-level command | 6 |
| Todo enforcer | `bee-state` watchdog hook; nudges if phase stalls | 6 |
| Comment checker | `comment-quality` skill; invoked by review commands | 6 |

### Rejected

| omo feature | Why not |
|---|---|
| Hash-anchored edits (Hashline) | Host-level edit-tool concern; belongs in opencode/Claude Code upstream |
| Tmux subagents | Opencode runtime feature; not a plugin concern |
| Ralph loop (self-reference until done) | Bee's existing verification gates (sdd-verifier, reviewer) serve the same purpose |
| Bundled proprietary MCPs (Exa, Context7, Grep.app) | User's global CLAUDE.md already mandates context7; don't bundle specific providers |
| Multi-model orchestration inside a single agent | Bee agents are single-purpose; multi-model logic lives at the category-routing layer, not inside agent prompts |

---

## 9. Migration Path (from current `feature/opencode-support`)

The current `feature/opencode-support` branch went the wrong direction. Plan:

1. **Create new branch** `feature/multi-platform-refactor` from `main`. Don't try to salvage the current branch's `bee.js`.
2. **Phase 0 on new branch** (Claude-only refactor): extract orchestration into skills, extract agent prompts, add include resolver. Claude Bee passes all existing tests at end.
3. **Delete old branch** after Phase 1 ships (opencode native shells).
4. **Users on the old branch**: INSTALL.md directs them to the new branch. Old `bee.js` is abandoned; no migration needed because nothing was stably working.

### File-by-file migration checklist (Phase 0)

For each command in `bee/commands/`:
- [ ] Identify the "knowledge" content (when to do what, why, rules)
- [ ] Move knowledge to `bee/skills/<command-name>-orchestration/SKILL.md`
- [ ] Leave thin command body that loads the skill + wires Task/AskUserQuestion
- [ ] Verify Claude Bee still runs the command identically

For each agent in `bee/agents/`:
- [ ] Move `bee/agents/<name>.md` body content to `bee/agents/<name>/prompt.md`
- [ ] Create `.claude-plugin/agents/<name>.md` with Claude frontmatter + include
- [ ] Delete old `bee/agents/<name>.md`

For each skill in `bee/skills/`:
- [ ] Rename the main `.md` file to `SKILL.md`
- [ ] Verify frontmatter has `name:` and `description:` fields
- [ ] Verify Claude Bee still loads the skill

---

## 10. Testing Strategy

### Smoke test harness (Phase 1)

`bee/tests/smoke/` — for each command, a scripted fixture that:

1. Invokes the command on a controlled test project (`bee/tests/fixtures/sample-project/`)
2. Asserts expected tool calls / subagent invocations occur in the expected order
3. Asserts the final state file matches expectations

Runs against both Claude Code and opencode (via their respective headless modes).

### Include linter

`bee/scripts/lint-includes.sh` — walks every `.md` file in `.claude-plugin/` and `.opencode/`, resolves all `{{include: ...}}` directives, reports any that fail. Runs in CI.

### Platform parity test

For every command: resolve both the Claude and opencode versions. Assert that the "knowledge" section (the skill being loaded) is identical. Only frontmatter and delegation syntax should differ.

### What we don't test

- End-to-end user workflows with real LLM calls (too slow, non-deterministic, expensive)
- Specific LLM responses to agent prompts (that's what smoke-test scenarios cover)

---

## 11. Adding New Content (Contributor Guide)

### Adding a new skill

1. Create `bee/skills/<name>/SKILL.md` with `name`, `description` frontmatter.
2. Write the skill body (knowledge, rules, workflow).
3. Run `bee/scripts/lint-includes.sh` to verify no broken references.
4. Both Claude and opencode pick it up automatically — no platform-specific wiring needed.

### Adding a new agent

1. Create `bee/agents/<name>.md` with Claude-style frontmatter and the full prompt body. This is the source of truth.
2. If the agent introduces a new category pattern, add a prefix mapping in `bee/scripts/generate-opencode-agents.py` (`CATEGORY_BY_PREFIX` list).
3. Run `python3 bee/scripts/generate-opencode-agents.py <name>` to produce `bee/.opencode/agents/<name>.md`.
4. Commit both files together.

Never edit `bee/.opencode/agents/*.md` directly — your changes will be overwritten the next time the generator runs.

### Adding a new command

1. Identify the orchestration logic — does it belong in a new skill, or an existing one?
2. Create/update the skill for the orchestration knowledge.
3. Create `bee/commands/<name>.md` (thin: load skill, delegate via Task, wire Claude tools).
4. Run the opencode command generator (Phase 1) or hand-write `bee/.opencode/commands/<name>.md` if the opencode command differs enough that a generator can't handle it cleanly.
5. Add to `bee/README.md` command list.

### Adding a new borrowed-from-omo pattern

Before writing code, update this ARCHITECTURE.md with:
- Where the pattern fits in the layer model (skill? plugin tool? command?)
- Which `routing.json` category (if any) it affects
- Which phase it lands in

---

## 12. Phasing (Summary Reference)

Full detail in the brainstorm summary. Summary here:

| Phase | Deliverable | Effort |
|---|---|---|
| 0 | Internal refactor (Claude only): extract skills, extract prompts, include resolver | Week 1 |
| 1 | Opencode shells: thin commands + agent wrappers + minimal plugin | Weeks 2-3 |
| 2 | Category-based model routing | Weeks 3-4 |
| 3 | Background/parallel agents | Weeks 4-5 |
| 4 | `/bee:init-deep` hierarchical context | Week 5 |
| 5 | Skill-embedded MCPs | Week 6 |
| 6 | IntentGate + todo enforcer + comment quality | Week 7 |
| 7 | Hardening, `bee doctor`, docs, CI, optional telemetry | Week 8 |

Each phase ships standalone value. If work pauses after any phase, Bee is in a coherent state.

---

## 13. Open Questions

Decisions deferred until closer to the affected phase:

- **Skill-embedded MCPs on Claude:** Claude Code's MCP lifecycle is per-session, not per-skill. How do we document this limitation? (Probably: skills declare MCPs, opencode honors them, Claude docs tell users to install once via CLAUDE.md.)
- **Category naming:** is `deep-work` vs `quick-work` the right axis, or should it be more semantic (`generation` vs `synthesis` vs `verification`)? Revisit after Phase 1 use.
- **`bee doctor` scope:** verify installation only, or also lint user's own Bee-customizations? Scope to Phase 7.

### Resolved

- **Routing config format:** JSON. Enables schema tooling + native support in both platforms without YAML parser dependencies.

---

## 14. References

- [Opencode Advanced Integration Brainstorm](./brainstorms/opencode-advanced-integration-brainstorm.md) — why we're doing this
- [Superpowers opencode plugin](https://github.com/obra/superpowers/blob/main/.opencode/plugins/superpowers.js) — the minimal plugin pattern we're adopting
- [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) — patterns we're borrowing from (category routing, init-deep, skill-embedded MCPs, etc.)
- [Opencode agents docs](https://opencode.ai/docs/agents/) — how subagents are registered on opencode
- [Opencode skills docs](https://opencode.ai/docs/skills/) — how the skill tool discovers and loads skills
- [The Harness Problem](https://blog.can.ac/2026/02/12/the-harness-problem/) — background reading on why edit tools matter (we don't fix this at plugin level, but it informs our decisions)
