---
name: ai-workflow
description: "This skill should be used when explaining why Bee follows spec-first TDD workflows, or when teaching mode is on. Contains the reasoning behind spec → plan → test → code ordering."
---

# AI-Assisted Development Workflow

## Why Specs Matter for AI

The #1 reason AI-generated code misses the mark is ambiguous requirements. "Add authentication" forces the AI to guess 100 decisions — session vs JWT, cookie vs header, redirect vs 401, password rules, lockout policy. Each guess compounds.

A spec with clear acceptance criteria eliminates guessing. The AI gets unambiguous targets and nails them on the first pass.

**The tradeoff:** 10 minutes writing a spec saves hours of rework. Without a spec, you'll spend that time anyway — just spread across debugging, re-prompting, and rewriting.

## Why Tests Define "Done" for AI

AI doesn't know when it's finished. It will keep generating code until you stop it. Tests give it a concrete finish line.

A failing test is the clearest possible prompt: "Make this pass." The AI doesn't need to interpret requirements — the test IS the requirement in executable form.

**Red-green-refactor with AI:**
- RED: Write a failing test. The AI now has a precise target.
- GREEN: Ask the AI to make it pass. It focuses on exactly what's needed.
- REFACTOR: Clean up with confidence — the tests catch regressions.

## Why Vertical Slicing Improves AI Focus

AI works best with focused, bounded tasks. A vertical slice (UI + backend + data for one capability) gives the AI everything it needs to deliver something complete and testable.

Horizontal slicing (all database tables, then all APIs, then all UI) forces the AI to build things it can't test in isolation. Each layer depends on layers that don't exist yet.

**Vertical slice benefits:**
- Each slice is independently testable
- The AI can verify its own work end-to-end
- Progress is visible — each slice ships real value
- If something goes wrong, you lose one slice, not the whole feature

## Why Risk Assessment Changes Everything

Low-risk code (internal tool, easy to revert) doesn't need the same rigor as high-risk code (payment flow, auth, data migration). Applying the same process to both wastes time on low-risk tasks and under-serves high-risk ones.

Risk-aware workflow means:
- Low risk: lighter spec, simpler plan, ship when tests pass
- High risk: thorough spec (failure modes, edge cases), defensive TDD plan, feature flag + team review

## When to Skip Process

Not every task needs a spec. Not every change needs TDD. The workflow should match the task:

- **Typo fix:** Just fix it. Run tests. Done.
- **Config change:** Fix it. Verify. Done.
- **Simple bug:** Understand it. Fix it. Test it. Done.
- **Feature:** Spec it. Plan it. Build it. Verify it. Review it.
- **Epic:** Break it down. Spec each slice. Build incrementally.

The right amount of process is the minimum needed to produce correct, maintainable code. More process than needed is waste. Less process than needed is risk.
