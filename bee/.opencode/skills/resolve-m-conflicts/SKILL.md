---
name: resolve-m-conflicts
description: "This skill should be used when resolving git merge conflicts. Parses conflict markers, shows clean side-by-side diffs, explains why each conflict occurred using git history, and presents resolution options via AskUserQuestion with reasoning for the recommended choice. Use this skill whenever the user mentions merge conflicts, says 'resolve conflicts', 'fix conflicts', or when git status shows unmerged paths."
---

# Resolve Merge Conflicts

Guide the developer through merge conflicts one at a time, with full context and clear choices. The goal is not just to resolve conflicts — it's to help the developer make an informed decision about each one.

---

## Step 1: Discover Conflicts

Run `git diff --name-only --diff-filter=U` to find all files with unmerged paths. If no conflicts exist, tell the developer and stop.

Present a summary:

> Found **N conflicts** across **M files**: `file1.ts`, `file2.ts`, ...

Then work through them one file at a time, one conflict hunk at a time.

---

## Step 2: Parse Each Conflict

For each conflict hunk (bounded by `<<<<<<<`, `=======`, `>>>>>>>`), extract:

- **Ours** (HEAD / current branch) — the code above `=======`
- **Theirs** (incoming branch) — the code below `=======`
- **Surrounding context** — 5-10 lines above and below the conflict markers to show where in the file this sits

---

## Step 3: Build Context — Why Did This Conflict Happen?

This is what makes the resolution informed rather than a coin flip. For each conflict:

1. **Git blame both sides.** Run `git log --merge -p -- <file>` or use `git log` on each branch to find the commits that touched the conflicting lines. Extract:
   - Who changed each side and when
   - The commit message (the *intent* behind the change)

2. **Summarize the story.** Write a short narrative:
   > **Ours** (branch `feature-x`, commit `abc1234` by Alice, 2 days ago): Renamed `getUserName` to `getDisplayName` as part of the naming convention cleanup.
   > **Theirs** (branch `main`, commit `def5678` by Bob, 1 day ago): Added a `fallback` parameter to `getUserName` for graceful degradation when user data is missing.

   This tells the developer *why* both changes exist, not just *what* they are.

3. **Identify the conflict type.** Categorize it to guide the resolution:
   - **Parallel edits** — both sides changed the same lines for different reasons
   - **Rename vs. modify** — one side renamed/moved, the other modified
   - **Delete vs. modify** — one side deleted code the other changed
   - **Adjacent changes** — changes are near each other and git couldn't auto-merge
   - **Structural refactor** — one side restructured (extracted function, changed signature) while the other modified the old structure

---

## Step 4: Present Resolution Options via question

Use `question` with markdown previews to show the conflict clearly and offer resolution options. The developer should be able to see the code for each option before choosing.

Structure the question like this:

- **Question**: A concise summary — e.g., "How should we resolve the conflict in `src/user.ts` (lines 42-58)?"
- **Header**: Short label like "Conflict 1/3"
- **Options** (2-4, depending on the conflict):

### Option patterns by conflict type:

**Parallel edits (most common):**
1. **Keep ours (Recommended)** — with markdown preview showing the resulting code. Description explains: "Alice's rename is part of a broader cleanup tracked in JIRA-123. Bob's fallback logic can be re-applied on top."
2. **Keep theirs** — with preview. "Bob's fallback prevents a production crash. The rename can be done in a follow-up."
3. **Merge both** — with preview showing hand-merged code that incorporates both changes. "Applies the rename AND adds the fallback parameter. Both intents preserved."

**Delete vs. modify:**
1. **Keep the deletion** — "This code was removed intentionally in commit X because [reason]."
2. **Keep the modification** — "This modification adds [feature]. The deletion may not have accounted for this new use case."

**Structural refactor:**
1. **Keep the refactored version and port changes** — "The refactor is the larger structural change. We can port the smaller modification into the new structure."
2. **Keep the old structure with modifications** — "If the refactor isn't ready, keep the working modification and revisit the refactor."

### How to decide the recommended option

The recommendation is NOT arbitrary. Explain the reasoning transparently. Consider these factors in order:

1. **Scope of change** — Larger, structural changes (refactors, renames across many files) are harder to redo. Smaller, targeted changes (add a parameter, fix a value) are easier to re-apply. Favor keeping the larger change and re-applying the smaller one.

2. **Recency and intent** — More recent changes on actively developed branches often represent the latest product decisions. Check if one side's commit message references a ticket, spec, or discussion that signals deliberate intent.

3. **Safety** — If one side adds error handling, null checks, or fallbacks, lean toward keeping the safer code, especially in production-critical paths.

4. **Test coverage** — If one side's change has accompanying tests and the other doesn't, the tested version is more trustworthy.

5. **Reversibility** — Favor the option that's easier to undo if wrong. Keeping a deletion is hard to reverse if you realize later the code was needed. Keeping extra code is easier to clean up.

Always state the reasoning explicitly in the option description, e.g.:
> "(Recommended) The rename spans 12 files and is part of a tracked cleanup. Bob's one-line fallback is simpler to re-apply after."

---

## Step 5: Apply and Continue

After the developer picks an option:

1. Apply the resolution by editing the file — remove the conflict markers and insert the chosen code.
2. Move to the next conflict hunk in the same file, or the next file.
3. After all conflicts in a file are resolved, run a quick syntax/lint check if tooling is available.

---

## Step 6: Final Verification

Once all conflicts are resolved:

1. Run `git diff --check` to confirm no conflict markers remain.
2. Summarize what was resolved:
   > Resolved **N conflicts** across **M files**:
   > - `src/user.ts`: Kept refactored names + ported fallback logic (3 conflicts)
   > - `src/api.ts`: Kept incoming error handling (1 conflict)
3. Ask the developer if they want to stage the resolved files and continue the merge/rebase.

---

## Tone

Be a collaborator, not a resolver. The developer is making the call — you're providing the context and analysis to make that call well-informed. When you recommend an option, explain why honestly and acknowledge the trade-off of not picking the other option.

---

## Applies To

Any workflow where git conflicts arise — during merges, rebases, cherry-picks, or stash pops. Can be triggered from any Bee agent that encounters merge conflicts, or directly by the developer.
