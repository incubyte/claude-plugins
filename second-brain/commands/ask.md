---
description: Query the wiki. Searches relevant pages, synthesizes an answer with [[citations]] and Obsidian deep links to sources.
argument-hint: <your question>
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash(basename:*)", "Bash(wc:*)", "Bash(date:*)", "Bash(pwd:*)", "AskUserQuestion"]
---

You are answering questions using a personal wiki as your knowledge base. The wiki lives in `wiki/` and contains concept pages, entity pages, and source summaries — all interlinked with `[[wikilinks]]`.

## On Startup

1. If `$ARGUMENTS` is empty, ask: "What would you like to know?"
2. Check that `wiki/` exists and has content. If not: "The wiki is empty. Run `/second-brain:ingest` first to process your clippings."
3. Determine the Obsidian vault name — it's the name of the parent directory that contains `wiki/`. Use Bash: `basename "$(pwd)"`. Store this for building deep links.

## Answering a Question

Use your judgment to find relevant information. You have full access to the wiki — read whatever you need. Some approaches:

- **Start with the index.** Read `wiki/index.md` to see what pages exist and find relevant ones by title/description.
- **Search by keyword.** Use Grep to find pages mentioning key terms from the question.
- **Follow the links.** Once you find a relevant page, follow its `[[wikilinks]]` to related pages. The wiki's cross-references are its superpower — use them.
- **Check summaries.** If the question is about a specific source, go straight to `wiki/summaries/`.
- **Read broadly if needed.** For synthesis questions ("how does X relate to Y?"), you may need to read several pages.

**Track every page you read and use in your answer.** You need this for the sources section.

## Response Format

### Answer

Answer the question directly in prose. Cite inline with `[[wikilinks]]` where relevant.

Flag uncertainty: if the wiki doesn't cover something, say what's missing and suggest what to add to `clippings/`.

Surface connections: if answering revealed a cross-cutting pattern, call it out.

### Sources

After the answer, print a **Sources** section. For every wiki page that contributed to the answer, list it with an Obsidian deep link.

**Obsidian deep link format:**
```
obsidian://open?vault={vault_name}&file={path}
```

Where:
- `{vault_name}` is the parent directory name (from startup step 3)
- `{path}` is the file path relative to the vault root, URL-encoded (spaces become `%20`, slashes become `%2F`), WITHOUT the `.md` extension

**Example sources section:**

```markdown
---

### Sources

| Page | Link |
|------|------|
| [[concepts/event-sourcing]] | [Open in Obsidian](obsidian://open?vault=kb&file=wiki%2Fconcepts%2Fevent-sourcing) |
| [[entities/postgresql]] | [Open in Obsidian](obsidian://open?vault=kb&file=wiki%2Fentities%2Fpostgresql) |
| [[summaries/distributed-systems-article]] | [Open in Obsidian](obsidian://open?vault=kb&file=wiki%2Fsummaries%2Fdistributed-systems-article) |
```

If the answer also traces back to original clippings (via summary page frontmatter `source_file`), include those too:

```markdown
| Source: Distributed Systems Article | [Open in Obsidian](obsidian://open?vault=kb&file=clippings%2Fdistributed-systems-article) |
```

**URL encoding rules:** Replace spaces with `%20`, slashes with `%2F`. Drop the `.md` extension. Keep hyphens, lowercase letters, and numbers as-is.

## Filing Good Answers

After answering, if the response contains a novel synthesis (connecting ideas that weren't explicitly linked before), offer to file it:

"This answer connects ideas across multiple pages. Want me to save it as a wiki page?"

Options:
- "Yes, save it" — Write to `wiki/concepts/[topic].md` with proper frontmatter, wikilinks, and source references. Update `wiki/index.md` and add cross-references to cited pages.
- "No, just the answer" — Done.

Only offer this for substantive synthesis — not for simple lookups.
