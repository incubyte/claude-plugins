# Pilot Phase 0 Findings

Date: 2026-04-24
Branch: `feature/multi-platform-refactor`

## What worked

1. **Command thinning: validated.** `/bee:review` shrank from 177 lines → 38 lines by extracting orchestration into a skill. The 170-line `review-orchestration` skill holds the agent catalog, scope rules, dedup/hotspot/roadmap logic, output format, tone, and rules. Command is now pure wiring: load skills, delegate, interpret arguments. Pattern holds.

2. **Skill extraction: validated.** Nothing architecturally new — Bee already uses skills heavily. Adding `review-orchestration` as a new skill is a clean fit. Follows the same convention as existing skills (`SKILL.md` with name/description frontmatter).

3. **Include resolver script: works in isolation.** `bee/scripts/resolve-includes.sh` correctly resolves `{{include: path}}` directives recursively, handles missing includes with clear errors, and produces output byte-equivalent to the original. Cycle detection logic in place (not exercised).

## What broke

**The agent-wrapper + shared-prompt + `{{include}}` pattern does not work at runtime.**

The design doc assumed the platform host (Claude Code or opencode) would resolve `{{include: ...}}` when reading agent files. Verified empirically: **Claude Code's plugin loader has no hook for this.** Claude reads `bee/agents/<name>.md` as raw markdown — the literal string `{{include: review-code-quality/prompt.md}}` would be sent to the model as part of the system prompt.

Opencode is similar: its plugin API has `experimental.chat.messages.transform` which fires on message-send, not on agent-file-load. Resolving includes there is possible in theory but awkward and non-standard.

**Consequence:** the "single source of truth for agent prompts via include" is not achievable with the architecture as designed. The resolver script works, but no host reads through it.

## Root cause

I designed the include mechanism around "host reads through resolver" without verifying the hosts actually provide that hook. They don't. This is a classic assumption-not-verified error — exactly the kind of risk the pilot was supposed to catch.

## What this means for the overall architecture

The design doc's core philosophy (**three-layer split + platform-native wrappers**) is still valid. But the mechanism for sharing agent prompts across platforms needs to change. Three honest options:

### Option A — Build-step generation (recommended)

- Keep `bee/agents/<name>.md` as the canonical Claude agent file (source of truth, committed, edited directly).
- Add `bee/scripts/generate-opencode-agents.sh` — reads `bee/agents/*.md`, transforms frontmatter to opencode schema, writes to `.opencode/agents/*.md`. Runs pre-commit and in CI.
- No include mechanism needed. The resolver script can be deleted.
- Trade-off: both files committed; if someone edits the opencode file directly, the generator overwrites on next run. CI check enforces "opencode agents are always generated from Claude agents."

### Option B — Honest duplication with lint

- Two independent files: `bee/agents/<name>.md` (Claude) and `.opencode/agents/<name>.md` (opencode). Body content duplicated.
- CI lint: assert that the body content (after frontmatter) is byte-identical between the two. Fail the build if they drift.
- Simpler than Option A (no build step, no generator logic), but developers must remember to edit both.
- Claude Code's `skills: [...]` frontmatter and opencode's explicit skill-load are the only real body-level differences — the lint can ignore these specific deltas.

### Option C — Drop multi-platform agents entirely (superpowers pattern)

- Skills work on both platforms (validated — they already use `SKILL.md`).
- Commands get duplicated per platform (12 files × 2 platforms = 24 files, small).
- Agents stay Claude-only. Opencode users get commands + skills but no `/bee:review`'s specialist-agent orchestration on opencode.
- Matches superpowers' proven pattern. Lowest effort, biggest feature loss.
- `/bee:review` specifically would become single-agent (just "you are Bee, run a review") on opencode, losing the 7-agent parallel dimension.

## What also worked (unexpected wins)

- **Extracting orchestration into a skill is genuinely clearer on Claude alone.** The new `bee/commands/review.md` (38 lines) is much easier to understand than the 177-line original. Even without opencode, this is a Claude-side improvement. Worth keeping regardless of which option wins.
- **`bee/skills/review-orchestration/SKILL.md`** is well-factored and reusable — any future command that wants review-style orchestration can load it.

## Current branch state

- `feature/multi-platform-refactor` branched from `main`.
- Added: `bee/scripts/resolve-includes.sh` (works, but may get deleted if we pick Option A/B)
- Added: `bee/skills/review-orchestration/SKILL.md` (keep regardless of option)
- Changed: `bee/commands/review.md` (thin version, 38 lines — keep regardless)
- `bee/agents/review-code-quality.md` — restored to main. No changes.
- `bee/agents/review-code-quality/` directory — deleted.
- `docs/ARCHITECTURE.md` and `docs/brainstorms/` — preserved from the `feature/opencode-support` branch move.

Nothing is committed yet. Clean rollback available.

## Recommended next step

**Pick Option A (build-step generation).** Rationale:

- Honest about the constraint (hosts don't resolve includes).
- Single source of truth preserved (one file per agent, edited directly; generator outputs the opencode twin).
- CI check makes drift impossible.
- Avoids the duplication-maintenance burden of Option B.
- Doesn't sacrifice opencode feature parity like Option C.
- Build step is ~50 lines of bash (frontmatter transformation is simple).

Cost: update the ARCHITECTURE.md to replace the include mechanism with a build-step section, delete resolve-includes.sh, write generate-opencode-agents.sh.

If you agree, next action is a focused ARCHITECTURE.md revision (10-20 min) before we proceed to writing the generator and redoing the pilot on a fresh agent.
