# Discovery: Bee Coach

## Why

Developers using Bee and Claude Code have no feedback loop on how effectively they're using AI-assisted development. They can't tell whether their prompts are improving, whether they're adopting the spec-driven workflow, or where they're leaving value on the table. Team leads have no visibility into patterns across their team's sessions. The coaching command closes this loop by analyzing session transcripts and surfacing actionable insights -- turning every session into a learning opportunity.

## Who

- **Individual developers** using Bee who want to self-improve: better prompts, better workflow adoption, faster sessions.
- **Team leads** who want to understand team-wide patterns: where onboarding gaps exist, which practices are being adopted, and where coaching would help most.

## Success Criteria

- A developer can run `/bee:coach` after a session and get 2-3 specific, actionable insights about what they did well and what they could improve
- The Stop hook runs silently after every session and logs enough data that `/bee:coach` can show trends over time (e.g., "your spec adoption rate went from 30% to 80% over the last 20 sessions")
- The coaching insights feel useful, not nagging -- developers want to check them, not dismiss them

## Problem Statement

Bee guides developers through a structured workflow (triage, spec, TDD, verify, review), but today there is no way to measure how well that workflow is being adopted or whether it's producing better outcomes. A developer who skips specs, writes vague prompts, or doesn't use TDD has no signal telling them what they're missing. We need a lightweight coaching system that passively collects session metrics (via a Stop hook) and actively surfaces insights on demand (via a `/bee:coach` command), so developers can see their patterns and improve over time.

## Hypotheses

- H1: The most valuable coaching signal is workflow adoption -- did the developer use specs, TDD plans, and verification, or did they skip straight to coding? This is easy to detect from transcript structure (presence of agent delegations, spec file writes, test-first patterns).
- H2: Session-level metrics logged by the Stop hook can be computed cheaply from the JSONL transcript without parsing every message in detail -- counting message types, tool uses, and file patterns is sufficient for trend tracking.
- H3: Individual developer coaching (self-improvement) is independently valuable without team aggregation features. Team features can be layered on later without changing the data model.
- H4: Developers will find "compared to your last N sessions" framing more useful than absolute scores or grades. Relative improvement is more motivating than judgment.
- H5: The coaching heuristics can be expressed as prompt instructions to Claude (analyzing the transcript as context) rather than requiring executable code or a separate analysis engine.
- H6: A JSONL log at `.claude/bee-insights/session-log.jsonl` is sufficient for trend storage -- no database needed. Each line is one session's metrics.

## Out of Scope

- Team aggregation dashboard or cross-developer comparison (Phase 1 is individual only)
- Automated coaching that interrupts sessions mid-flow ("you should write a spec") -- coaching is retrospective, on-demand
- Integration with external tools (Slack, dashboards, CI)
- Modifying the existing Bee workflow to enforce practices based on coaching scores
- Historical backfill of sessions that happened before the hook was installed

## Key Design Decisions

### 1. Transcript Parsing Strategy

The `/bee:coach` command receives a session transcript (JSONL file). It needs to extract meaningful signals from it. Two approaches:

**Recommended: Feed transcript to Claude with coaching prompt.** The coach command is a markdown agent (like all Bee agents). It reads the JSONL transcript, and the prompt instructs Claude what to look for. Claude's language understanding handles the messy reality of varied message types, tool uses, and conversation flows. This is consistent with how the entire Bee system works -- prompt engineering, not executable code.

**Alternative: Pre-parse into structured summary, then analyze.** The Stop hook could do heavy extraction and the coach command analyzes the pre-parsed summary. Downside: the hook runs after every session and should be fast. Heavy parsing in the hook adds latency.

**Decision:** The Stop hook logs lightweight, cheap-to-compute metrics (counts and flags). The coach command does the deep analysis by reading the actual transcript with Claude. This splits the work: hook = fast metrics for trends, command = deep analysis for insights.

### 2. Coaching Heuristics

What patterns does the coach look for? Organized by category:

**Workflow adoption:**
- Did the session use the Bee workflow? (presence of triage, spec, TDD plan, verification)
- Which phases were used vs skipped?
- Was a spec confirmed before coding started?

**Prompt quality:**
- Are user messages clear and specific, or vague and requiring multiple clarification rounds?
- Ratio of user messages to assistant messages (high ratio might mean too many short, unclear prompts)
- Does the developer provide context upfront or make Claude guess?

**Session efficiency:**
- Total tokens used (from `message.usage`)
- Number of tool errors or retries
- Time from first message to task completion
- Ratio of "productive" tool uses (file writes, test runs) to "exploratory" ones (repeated reads, greps)

**Code quality signals:**
- Were tests written before production code? (file write order)
- Were verification/review steps completed?
- Number of test failures before passing (healthy TDD has failures)

### 3. Hook Metrics Schema

The Stop hook logs one JSON line per session. These must be cheap to compute (counts, not deep analysis).

**Recommended schema:**

```json
{
  "session_id": "string",
  "timestamp": "ISO-8601",
  "duration_seconds": 0,
  "cwd": "/path/to/project",
  "git_branch": "string",
  "message_counts": {
    "user": 0,
    "assistant": 0,
    "tool_use": 0,
    "tool_result": 0
  },
  "token_usage": {
    "input_tokens": 0,
    "output_tokens": 0
  },
  "tools_used": {
    "Read": 0,
    "Write": 0,
    "Glob": 0,
    "Grep": 0,
    "Bash": 0,
    "Task": 0
  },
  "bee_workflow": {
    "spec_written": false,
    "tdd_plan_written": false,
    "verification_run": false,
    "review_run": false
  },
  "files_modified": 0,
  "test_files_modified": 0,
  "errors_observed": 0,
  "transcript_path": "string"
}
```

The `bee_workflow` flags can be detected by scanning for spec file writes (`docs/specs/*.md`), TDD plan patterns, and agent delegation (Task tool calls to known agent names). The `transcript_path` allows the coach command to go back and do deep analysis when requested.

## Milestone Map

### Phase 1: Individual Session Coaching

A developer can run `/bee:coach` after any session and get actionable coaching insights. The Stop hook silently logs metrics after every session.

- Stop hook that parses the session transcript JSONL and appends lightweight metrics to `.claude/bee-insights/session-log.jsonl`
- `/bee:coach` command (markdown agent) that reads the last session's transcript and produces 2-4 coaching insights organized by category (workflow, prompts, efficiency)
- Trend summary from the session log: "Over your last N sessions, here's what's changing" (spec adoption rate, average tokens, workflow completeness)
- Option flags: last session (default), last N sessions, all sessions

### Phase 2: Deeper Patterns and Team Visibility

Builds on Phase 1 data to surface cross-session patterns and enable team-level insights.

- Cross-session pattern detection: recurring skipped steps, improving/degrading metrics, habit formation signals
- Comparative framing: "This session vs your average" with specific deltas
- Team summary mode: aggregate metrics across multiple developers' session logs (requires shared/accessible log location)
- Suggested next actions: based on patterns, recommend specific Bee features the developer isn't using

## Revised Assessment

Size: FEATURE -- Phase 1 is a well-scoped feature (one command, one hook, one log file). Phase 2 is a natural follow-up but not required for Phase 1 to be independently useful. If we tried to build both phases at once, this would be an EPIC, but slicing it keeps each phase at FEATURE size.

Greenfield: Partially. The coach command and hook are new additions, but they live within the established Bee plugin structure (markdown commands, agents, settings.json hooks). The patterns and conventions are well-established.

[x] Reviewed
