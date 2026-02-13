# Spec: Bee Coach — Phase 1: Individual Session Coaching

## Overview

A lightweight coaching system that passively logs session metrics via a Stop hook and actively surfaces actionable insights on demand via `/bee:coach`. Helps developers improve their prompts, workflow adoption, and session efficiency over time.

Discovery document: `docs/specs/bee-coach-discovery.md`

## Acceptance Criteria

### Stop Hook (`.claude/hooks/stop-session.sh`)

- [x] Shell script at `.claude/hooks/stop-session.sh` reads JSON from stdin (provides `session_id`, `transcript_path`, `cwd`)
- [x] Script reads the JSONL transcript file and computes lightweight metrics: message counts by type, token usage totals, tool use counts, bee workflow flags, file counts, and error count
- [x] Script detects bee workflow usage by scanning for spec file writes (`docs/specs/*.md`), TDD plan writes, verification agent calls, and review agent calls
- [x] Script resolves the current git branch from `cwd`
- [x] Script computes session duration from first and last message timestamps
- [x] Script appends one JSON line per session to `.claude/bee-insights/session-log.jsonl`, creating the directory and file if they don't exist
- [x] Logged JSON follows the schema defined in the discovery document (session_id, timestamp, duration_seconds, cwd, git_branch, message_counts, token_usage, tools_used, bee_workflow, files_modified, test_files_modified, errors_observed, transcript_path)
- [x] Script exits silently on success — no output to the developer's terminal
- [x] Script exits gracefully if the transcript file is missing or unreadable (no crash, no error output)
- [x] Hook is registered in `.claude/settings.json` under `hooks.Stop`

### `/bee:coach` Command (`commands/coach.md`)

- [ ] Command file exists at `commands/coach.md` with YAML frontmatter matching existing command conventions
- [ ] Default behavior (no flags): reads the last session's transcript for deep analysis and shows a trend summary from the last 5 sessions
- [ ] `--last N` flag: shows trend summary across the last N sessions from the session log
- [ ] `--all` flag: shows trend summary across all sessions in the session log
- [ ] Command reads the transcript JSONL and instructs Claude to analyze it across four categories: workflow adoption, prompt quality, session efficiency, and code quality signals
- [ ] Produces 2-4 specific, actionable coaching insights (not generic advice)
- [ ] Each insight names a concrete thing the developer did well or a specific improvement to try next session
- [ ] Coaching tone is encouraging and non-judgmental — highlights growth, not failures

### Coaching Report Output

- [ ] Insights are printed directly to the terminal as conversational output
- [ ] Insights are also saved to `.claude/bee-insights/coaching-report-YYYY-MM-DD.md` (using the current date)
- [ ] If multiple coaching runs happen on the same day, the file is overwritten with the latest report
- [ ] Report file includes the session date, the 2-4 insights, and the trend summary

### Trend Summary

- [ ] Trend summary reads from `.claude/bee-insights/session-log.jsonl`
- [ ] Shows directional changes across sessions: spec adoption rate, average token usage, workflow phase completeness, message counts
- [ ] Uses relative framing ("your spec adoption went from 2/5 to 4/5 sessions") rather than absolute scores
- [ ] Shows a helpful message when fewer than 2 sessions exist ("not enough sessions for trends yet")

## API Shape

Stop hook stdin:
```json
{ "session_id": "abc-123", "transcript_path": "/path/to/transcript.jsonl", "cwd": "/path/to/project" }
```

Session log line (appended by hook):
```json
{
  "session_id": "string",
  "timestamp": "ISO-8601",
  "duration_seconds": 0,
  "cwd": "/path/to/project",
  "git_branch": "string",
  "message_counts": { "user": 0, "assistant": 0, "tool_use": 0, "tool_result": 0 },
  "token_usage": { "input_tokens": 0, "output_tokens": 0 },
  "tools_used": { "Read": 0, "Write": 0, "Glob": 0, "Grep": 0, "Bash": 0, "Task": 0 },
  "bee_workflow": { "spec_written": false, "tdd_plan_written": false, "verification_run": false, "review_run": false },
  "files_modified": 0,
  "test_files_modified": 0,
  "errors_observed": 0,
  "transcript_path": "string"
}
```

Command invocation:
```
/bee:coach           → deep analysis of last session + trend from last 5
/bee:coach --last 10 → trend summary across last 10 sessions
/bee:coach --all     → trend summary across all sessions
```

## Out of Scope

- Team aggregation or cross-developer comparison (Phase 2)
- Cross-session pattern detection beyond simple trend lines (Phase 2)
- Mid-session coaching interruptions — coaching is retrospective only
- Historical backfill of sessions before the hook was installed
- Modifying existing Bee workflow based on coaching scores
- Integration with external tools (Slack, dashboards, CI)

## Technical Context

- Patterns to follow: commands use markdown with YAML frontmatter (`commands/bee.md` is the reference). Agents follow the same pattern (`agents/quick-fix.md`).
- Files to create: `.claude/hooks/stop-session.sh`, `commands/coach.md`
- Files to modify: `.claude/settings.json` (add Stop hook registration)
- Directories to create (by hook, at runtime): `.claude/bee-insights/`
- The coach command is a markdown agent — Claude analyzes the transcript in-context via prompt instructions, no separate analysis engine
- Risk level: LOW



- [x] Reviewed


