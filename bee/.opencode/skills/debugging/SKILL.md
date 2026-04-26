---
name: debugging
description: "This skill should be used when diagnosing failures, fixing bugs, or investigating why tests don't pass. Contains systematic debugging: reproduce first, read before you change, assume nothing, find root cause."
---

# Debugging

Read and analyze first, change code last. Most debugging failures come from jumping to fixes before understanding the problem.

---

## Reproduce First

Confirm the failure before touching anything. Run the failing test, hit the failing endpoint, trigger the broken flow. If you can't reproduce it, you don't understand it yet.

---

## Read Everything

Before theorizing, read:

- **The full error** — the entire stack trace, not just the first line. The root cause is often buried deeper.
- **The logs** — application logs, server output, build output. They often tell you exactly what went wrong.
- **The browser console** — for frontend: console errors, network failures, failed requests, and CORS issues tell you more than the UI does. Check the Network tab for status codes and response bodies.
- **The code** — trace the actual execution path from entry point to failure. Don't guess what the code does — read it.

---

## Assume Nothing

Verify every assumption before acting:

- Is the file you're editing the one actually being executed?
- Is the environment variable set? Is it the right value?
- Are you on the correct branch? Is the code deployed/built?
- Is the service running? Is the database reachable?
- Is the test running against the code you think it is?

The bug is often in the gap between what you assume and what's actually true.

---

## One Change at a Time

Make one change. Observe the result. Then decide the next step.

Never make five changes hoping one of them works — you won't know which one fixed it, and the others may introduce new problems.

---

## Add Instrumentation

When existing logs aren't enough, add targeted logging to narrow the cause:

- Log inputs and outputs at the boundary where behavior diverges from expectation.
- Log the actual values, not just "reached here".
- Analyze the output before making the next move.
- Remove the instrumentation after diagnosing.

---

## Narrow Systematically

Use binary search to shrink the problem space:

- Comment out half the logic — does it still fail?
- Hardcode an intermediate value — does the downstream code work?
- Use the simplest possible input — does the base case work?

Each step should cut the search space in half.

---

## Use Available Tools

Don't debug blind when you have integrations:

- **MCP servers** — if LSP tools are available, use them to trace references, find callers, and check types. If database tools are available, query the actual data.
- **Browser automation** — if Chrome MCP is connected, check the console, inspect network requests, read the actual DOM state. Don't guess what the user sees — look at it.
- **Shell tools** — check running processes, port bindings, environment variables, file permissions. The answer is often one command away.

Use what's available before adding workarounds.

---

## Find the Root Cause

Symptoms and root causes are different things. A null pointer exception is a symptom — the root cause is why the value is null.

- Trace backwards from the failure to the origin of the bad state.
- Ask "why?" at each layer — don't stop at the first explanation.
- A fix that addresses the symptom will break again. A fix that addresses the root cause won't.

---

## Explain Before Fixing

Articulate the root cause before writing the fix. If you can't explain why the bug happens, you haven't found it yet.

Bad: "I'll try changing this parameter and see if it works."
Good: "The query returns null because the join uses the wrong foreign key — column X references table A but should reference table B."

---

## Verify After Fixing

The fix isn't done until you've confirmed it works:

- Re-run the failing test — does it pass now?
- Run the full related test suite — did the fix break anything else?
- If it's a frontend fix, check the browser — does the UI behave correctly?
- If it's a data fix, query the actual data — is the state correct?

Never declare "fixed" based on the code looking right. Prove it.

---

## Trial and Error is Last Resort

Exhaust these steps first:

1. Read the error, logs, console, and code
2. Verify your assumptions
3. Add instrumentation and analyze
4. Narrow systematically

Only resort to try-and-see when you've genuinely run out of analytical approaches. If you find yourself guessing, stop and go back to reading.

---

## Don't Brute Force

If the same approach failed twice, stop and rethink. Retrying the same thing is not debugging — it's hoping. Step back, re-read, and try a different angle.

---

## Applies To

All agents that encounter failures during execution: verifier, quick-fix, browser-verifier, and any agent running tests or diagnosing issues.
