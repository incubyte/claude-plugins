---
name: bee-state
description: "This skill should be used when updating workflow state in bee-state.local.md. Contains the full command reference for update-bee-state.sh including init, set, get, clear, all flags, and multi-line field syntax."
---

# Bee State Script Reference

The state script manages `.claude/bee-state.local.md` — the source of truth for workflow progress across sessions.

**CRITICAL:** Never use Write or Edit tools on `bee-state.local.md` — that triggers permission prompts. Always use this script via Bash. It is pre-approved in allowed-tools.

## Script Path

`${CLAUDE_PLUGIN_ROOT}/scripts/update-bee-state.sh`

## Commands

**Initialize** (after triage):
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/update-bee-state.sh" init --feature "User auth" --size FEATURE --risk MODERATE
```

**Update fields** (incremental — only pass what changed):
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/update-bee-state.sh" set --current-phase "single-phase" --phase-spec "docs/specs/user-auth.md — confirmed"
```

**Read state** (on startup):
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/update-bee-state.sh" get
```

**Read single field**:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/update-bee-state.sh" get --field feature
```

**Clear** (when done):
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/update-bee-state.sh" clear
```

## Available Flags

`--feature`, `--size`, `--risk`, `--discovery`, `--design-brief`, `--boundaries`, `--current-phase`, `--phase-spec`, `--architecture`, `--tdd-plan`, `--current-slice`, `--phase-progress`, `--slice-progress`

## Multi-line Fields

For phase-progress and slice-progress, use `|` as line separator:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/update-bee-state.sh" set --phase-progress "Phase 1: done — Cart|Phase 2: executing|Phase 3: not started"
```
