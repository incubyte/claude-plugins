# Agent Gaps: Architecture Doc vs Actual Agent Files

Running list of content from the architecture doc that didn't make it into the agent markdown files. Track here so nothing gets lost across slices.

---

## spec-builder.md (Slice 3 — implemented)

### Missing: "WHY SPECS MATTER FOR AI" preamble
The architecture doc's spec-builder prompt opens with:
> "The #1 reason AI code misses the mark is ambiguous requirements. 'Add authentication' forces the AI to guess 100 decisions. A spec with clear acceptance criteria means the AI nails it."

This framing is in the `ai-workflow` SKILL.md, but the agent itself doesn't reference it. The doc's original prompt had this inline to prime the agent's mindset.

**Action:** Either add a brief version to the agent prompt, or add a line like: "Read `.claude/skills/ai-workflow/SKILL.md` for the reasoning behind this approach."

### Simplified: Spec depth matrix
The doc has a detailed visual grid (Small/Feature/Epic × Low/Moderate/High) with specific AC counts per cell. The agent file collapses this into a simpler bulleted list. The nuance lost: SMALL tasks at different risk levels get different treatment (3-5 ACs vs 5-7 ACs + failure modes).

**Action:** Consider expanding the depth guidance to match the matrix, especially the Small × High Risk case.

### Missing: MCP state tools
Doc lists `mcp__bee__*` in tools. Agent has `Read, Write, Glob, Grep`. Not applicable in standalone mode, but track for plugin conversion.

---

## architecture-advisor.md (Slice 3 — implemented)

### Missing: Concrete example of option presentation
The architecture doc includes a full example:
> "This feature has complex scoring rules. Three approaches:
> - MVC (current pattern) — Consistent. Rules live in services. Risk: service files grow as rules get complex.
> - Onion / Hexagonal — Pure domain core. Rules are trivially testable. More structure upfront. (Recommended for complex rules)
> - Keep it simple — Inline logic. Fastest. Refactor when it hurts."

This example teaches the agent *how* to present options with the right level of detail. The current file says "use AskUserQuestion with 2-3 options" but doesn't show what good looks like.

**Action:** Add the example back.

### Missing: AI-specific YAGNI context
The doc adds: "This is especially important with AI — the AI loves to generate interfaces and abstractions. Push back on unnecessary indirection."

The agent file has the YAGNI check but misses this specific callout about AI's tendency to over-abstract.

**Action:** Add one line about AI's abstraction tendency.

### Missing: MCP state recording
Doc says: "Record the decision: Store architecture choice in MCP state so the correct TDD planner is selected downstream." The agent file ends with stating the recommendation but doesn't mention persisting it.

**Action:** Not applicable in standalone mode. Track for plugin conversion.

### Missing: ADR teaching moment
Doc includes: "Teaching moment: 'An ADR captures WHY we chose this, so future-us doesn't have to guess.'"

Not in the current file.

**Action:** Add to ADR section.

---

## quick-fix.md (Slice 1 — implemented)

Checked — content matches the architecture doc well. No significant gaps.

---

## context-gatherer.md (Slice 2 — implemented)

Checked — content matches. No significant gaps.

---

## tidy.md (Slice 2 — implemented)

Checked — content matches. No significant gaps.

---

## Placeholders (not yet implemented — gaps expected)

### tdd-planner-onion.md (Slice 4 — implemented)
Comprehensive agent with full outside-in double-loop flow, port interface design rules, mocking strategy per layer, anti-patterns, and common patterns. Includes "architecture EMERGES from the tests" insight, execution header, and teaching moment.

### tdd-planner-mvc.md (Slice 4 — implemented)
Comprehensive agent with full MVC layer order, "Controller is THIN" emphasis, mocking strategy per layer, anti-patterns, and common patterns. Includes dependency direction rules and failure message progression.

### tdd-planner-simple.md (Slice 4 — implemented)
Tight and minimal as intended. Test-implement-verify per behavior, risk-aware edge cases, execution header, and teaching moment.

### tdd-planner-event-driven.md (implemented)
Contract-first TDD: event schema → producer → consumer → wire. Resilient consumer patterns, idempotency, dead letter handling. Common patterns: CRUD + Events, Event Chain, Saga/Process Manager.

### tdd-planner-serverless.md (implemented)
Handler-first TDD: handler → business logic (pure) → integrations → wire. Serverless-specific concerns: cold start, statelessness, timeouts, payload limits. Common patterns: REST API Endpoint, Webhook Receiver, Scheduled Function.

### tdd-planner-cqrs.md (implemented)
Split TDD: command side (command handler → domain → events) and query side (projection → read model → query handler). Event sourcing patterns. Common patterns: Simple CQRS, Event-Sourced CQRS, Multi-Projection CQRS.

### tdd-planner-api-contract.md (implemented)
Consumer-driven contract TDD: consumer expectations → contract definition → provider compliance → wire. BFF patterns, schema evolution. Common patterns: BFF, Service Mesh, Async API Contract.

### verifier.md (Slice 5 — implemented)
Risk-aware verification: 5-step process (run tests → check plan → validate ACs → check patterns → risk-aware deeper checks). Tiered checks (ALWAYS/MODERATE+/HIGH). Spec checkbox updating. Structured output format with file:line references.

### reviewer.md (Slice 5 — implemented)
Holistic final review: spec coverage, pattern compliance, code quality, test quality, commit story, observability. Risk-aware ship recommendation (merge/team review/feature flag+QA). Conversational tone. Read-only — analyzes and recommends, doesn't change code.
- Observability check makes it in (logs, errors surfaced, metrics for high-risk)
- Conversational tone guidance: "Nice work. The domain logic is clean. Two things I'd change..."
- Risk-aware ship recommendation with specific actions per level

---

## Cross-cutting gaps (not tied to a specific agent)

### Skills are not explicitly referenced by agents
The architecture doc says agents reference skills and Claude Code auto-loads them. But none of the agent files explicitly say "reference the X skill." This may work implicitly (Claude Code loads skills in context), but making it explicit could improve reliability.

**Action:** Consider adding skill references to agent prompts, e.g. "Draw on the `tdd-practices` skill for TDD guidance."

### Hooks (Section 4) — not implemented
Soft guardrail hooks are described but not assigned to a slice. They're TypeScript — deferred to plugin conversion.

### MCP Server (Section 5) — not implemented
State tracking, YAGNI check tool, teaching level — all deferred to plugin conversion. Agents currently can't persist state between invocations.

---

*Last updated: 2026-02-07 — after Slice 5 (verifier + reviewer) implemented and wired into orchestrator*
