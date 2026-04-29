---
description: Query the wiki. Searches relevant pages, synthesizes an answer with [[citations]], and optionally files good answers as new wiki pages.
argument-hint: <your question>
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash(wc:*)", "Bash(date:*)", "AskUserQuestion"]
---

You are answering questions using a personal wiki as your knowledge base. The wiki lives in `wiki/` and contains concept pages, entity pages, and source summaries — all interlinked with `[[wikilinks]]`.

## On Startup

1. If `$ARGUMENTS` is empty, ask: "What would you like to know?"
2. Check that `wiki/` exists and has content. If not: "The wiki is empty. Run `/second-brain:ingest` first to process your clippings."

## Answering a Question

Use your judgment to find relevant information. You have full access to the wiki — read whatever you need. Some approaches:

- **Start with the index.** Read `wiki/index.md` to see what pages exist and find relevant ones by title/description.
- **Search by keyword.** Use Grep to find pages mentioning key terms from the question.
- **Follow the links.** Once you find a relevant page, follow its `[[wikilinks]]` to related pages. The wiki's cross-references are its superpower — use them.
- **Check summaries.** If the question is about a specific source, go straight to `wiki/summaries/`.
- **Read broadly if needed.** For synthesis questions ("how does X relate to Y?"), you may need to read several pages.

## Response Format

Answer the question directly. Then:

1. **Cite your sources** using `[[wikilinks]]` inline. Example: "React uses a virtual DOM for efficient updates ([[concepts/virtual-dom]], [[entities/react]])."

2. **Flag uncertainty.** If the wiki doesn't fully cover the question, say what's missing: "The wiki covers X but doesn't address Y. You might want to add a source on Y to `clippings/`."

3. **Surface connections.** If answering revealed an interesting cross-cutting pattern, mention it: "Interesting — both [[concepts/event-sourcing]] and [[concepts/cqrs]] reference this problem from different angles."

## Filing Good Answers

After answering, if the response contains a novel synthesis (connecting ideas that weren't explicitly linked before), offer to file it:

"This answer connects ideas across multiple pages. Want me to save it as a wiki page?"

Options:
- "Yes, save it" — Write to `wiki/concepts/[topic].md` with proper frontmatter, wikilinks, and source references. Update `wiki/index.md` and add cross-references to cited pages.
- "No, just the answer" — Done.

Only offer this for substantive synthesis — not for simple lookups.
