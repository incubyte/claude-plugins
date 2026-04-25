# Opencode Advanced Integration — Brainstorm

Date: 2026-04-24
Context: Deciding how Bee should properly support opencode, after the initial `feature/opencode-support` runtime-transformation approach broke in practice (subagents not registering, skills not auto-discovered, context pollution).

## Problem

Bee was architected for Claude Code (Task tool, `AskUserQuestion`, `TodoWrite`, frontmatter skill auto-load, `.claude/` state). The current `.opencode/plugins/bee.js` tries to bridge the gap with runtime regex replacement plus dynamic command registration. In practice:

- `bee/agents/*.md` never get registered anywhere opencode can discover them → `Task` tool has nothing to delegate to
- `bee/skills/*` aren't in opencode's discovery paths and aren't named `SKILL.md` → skill tool can't find them
- Frontmatter `skills: [foo]` on agents doesn't auto-load in opencode (requires explicit `skill()` calls)
- 600-line commands pollute context on every turn
- Simple string replacement can't bridge the architectural gap between Claude's command-orchestrated model and opencode's agent-driven model

## Options Explored

1. **Runtime regex transformation** (current `bee.js`) — Effort: medium. Risk: high. Partially broken; hits undocumented APIs; fights platform.
2. **Full dual-tree port (manual)** — Effort: high. Risk: medium. Two parallel copies of commands + agents. High maintenance, drift risk.
3. **Skills-only + bootstrap (superpowers pattern)** — Effort: low. Risk: low. Ship skills, inject a one-time bootstrap with tool-mapping hints. Trust the LLM to translate. Loses orchestrated `/bee:*` commands on opencode.
4. **Depend on oh-my-opencode** — Effort: near-zero. Risk: medium. Inherits omo's opinions (multi-model, telemetry, ralph loops) which clash with Bee's "navigator not enforcer" tone.
5. **Bee-scoped claude-loader** — Effort: high. Risk: high. Reinvents what omo maintains.
6. **Skills/agents/commands three-layer split + thin platform wrappers + borrow omo patterns natively** — Effort: high (6-8 weeks). Risk: low. Single source of truth for knowledge and agent prompts; thin platform-native wiring; omo's best ideas (category routing, background agents, init-deep, skill-embedded MCPs) implemented in Bee's idiom.

## Chosen Direction

**Option 6 — Full advanced port with omo patterns borrowed.** User wants properly-done feature-parity on opencode plus the workflow power features omo pioneered.

Core architecture:

- **Skills** = portable knowledge (shared across platforms, canonical `SKILL.md` filename).
- **Agents** = shared system prompts in `agents/<name>/prompt.md`; platform-specific wrappers = frontmatter + `{{include: ...}}`.
- **Commands** = thin wiring (~40-60 lines), one file per platform, load the relevant shared skill and delegate using platform idioms (`Task` on Claude, `@mention` on opencode).
- **Platform plugins** = minimal: register skills path, inject bootstrap, provide `bee_state` tool. No runtime regex. No command registration.

Phasing:

- **Phase 0 (week 1)** — Claude-only internal refactor: extract orchestration from commands into skills, extract agent prompts to shared files. Claude Bee keeps working.
- **Phase 1 (weeks 2-3)** — Opencode shells: write thin commands + agent wrappers, shrink plugin to ~100 lines, smoke-test matrix.
- **Phase 2 (weeks 3-4)** — Category-based model routing (borrowed from omo): agents declare category, platform config maps category → model.
- **Phase 3 (weeks 4-5)** — Background/parallel agents: independent slices fire in parallel.
- **Phase 4 (week 5)** — `/bee:init-deep`: hierarchical AGENTS.md / CLAUDE.md generation.
- **Phase 5 (week 6)** — Skill-embedded MCPs: skill frontmatter declares required MCPs.
- **Phase 6 (week 7)** — IntentGate skill + todo enforcer + comment-quality skill.
- **Phase 7 (week 8)** — Hardening: `bee doctor` command, docs, CI, opt-in telemetry.

## Key Insights

- **Superpowers ships ZERO commands on opencode** — they migrated AWAY from symlinks, settled on skills-only + bootstrap injection. They let the LLM mentally translate tool names. Elegant and low-maintenance.
- **oh-my-opencode already has a `claude-code-command-loader`** in its `src/features/` — building that again for Bee is wasted effort if we go the "adopt omo" route, but makes sense if Bee stays native-to-both-platforms.
- **The cost of duplicating Claude and opencode command/agent wrappers is lower than the cost of maintaining a transformation engine** — especially once orchestration logic is extracted into shared skills (the heavy files become the shared ones).
- **omo's model-routing category pattern is orthogonal to Bee's navigation** — it can be added without changing Bee's tone or philosophy. Same for init-deep, background agents, skill-embedded MCPs.
- **Hash-anchored edits and tmux subagents are host-level concerns** — they belong in opencode itself, not in a plugin. Not porting.
- **DHH-aligned scope honesty**: 12 commands × 2 platforms × thin wrappers = ~1K lines of mostly-identical wiring. That's cheaper to maintain than a 250-line runtime transformer with edge cases.

## Cross-Domain Simplifications Discovered

- Moving orchestration logic from commands into skills **also helps Claude users** — it makes commands smaller and clearer. Phase 0 is a win even if opencode didn't exist.
- The `{{include: ...}}` mechanism for shared prompts could apply to a 3rd platform later (Codex, Cursor) with linear effort, not quadratic.
- `bee_state` is platform-agnostic and can remain a first-class custom tool — no need to translate, both platforms support custom tools.

## Borrowed from omo (explicit list)

Adopted:
- Category-based subagent routing → Bee's routing.json
- Background/parallel agents → Bee parallel-execution skill + `bee_background` tool
- `/init-deep` → `/bee:init` hierarchical context generation
- Skill-embedded MCPs → Bee skill frontmatter `mcps:` field
- IntentGate → Bee intent-classification skill
- Todo enforcer → Bee state-watchdog hook
- Comment quality → Bee comment-quality skill (codifies CLAUDE.md rules)

Rejected:
- Hash-anchored edits (host-level concern, belongs in opencode/Claude Code)
- Tmux subagents (omo-specific runtime)
- Ralph loop (Bee's verification gates already serve this purpose)
- Bundled proprietary MCPs (user's global CLAUDE.md already mandates context7)

## Open Questions

- Include mechanism: hand-roll a `{{include: ...}}` resolver in scripts, or use an existing templating tool? (Leaning hand-roll — ~30 lines, zero deps.)
- Should skill `SKILL.md` rename break Claude compatibility? No — Claude Code reads any `.md` in a skill dir; we just rename to `SKILL.md` and Claude still finds them. No regressions.
- Category-routing config: per-project override in `opencode.json` / `.claude-plugin/routing.json`, or global only? (Probably both, with project overriding global.)
- How do we handle users currently on `feature/opencode-support` branch with the old bee.js? Migration note + branch abandoned. The architecture is different enough that there's nothing to migrate from.
- Does Bee need its own opt-in telemetry, or rely on host-level telemetry? (Deferred to Phase 7.)
- `/bee:init-deep` skill output path: `AGENTS.md` (opencode native) or both `CLAUDE.md` + `AGENTS.md`? (Both; opencode also reads CLAUDE.md.)

## Next Step

Write `docs/ARCHITECTURE.md` as the authoritative design doc before any code moves. This gets pressure-tested once, then becomes the implementation guide. Prevents architectural drift mid-refactor.
