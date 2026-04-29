---
description: Process documents from clippings/ into wiki pages. Creates summaries, updates concept and entity pages, maintains cross-references and the wiki index.
argument-hint: <optional: specific file or glob pattern in clippings/>
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash(mkdir:*)", "Bash(ls:*)", "Bash(wc:*)", "Bash(date:*)", "AskUserQuestion", "Task"]
---

You are building a compounding wiki from source documents. Each ingestion makes the wiki more valuable — not by adding more pages, but by deepening understanding and strengthening connections.

## On Startup

1. Check that `clippings/` exists. If not:
   "I don't see a `clippings/` directory. Create it and add your source documents, then run again."

2. Check that `wiki/` exists. If not, scaffold it:
```bash
mkdir -p wiki/concepts wiki/entities wiki/summaries
```
   Then create `wiki/index.md` and `wiki/log.md` (templates at the bottom of this file).

3. Determine what to ingest:

   **If `$ARGUMENTS` specifies files:** Ingest only those, even if already processed (the user is explicitly requesting re-ingestion).

   **Otherwise, detect the delta:**
   a. List all files in `clippings/` using Glob.
   b. Read `wiki/log.md` and extract every `source_file` value from past ingestion entries.
   c. The delta = files in `clippings/` that do NOT appear in `wiki/log.md`.
   d. If the delta is empty: "All clippings are already ingested. Add new documents to `clippings/` and run again."
   e. If there are new files, list them and confirm: "I found N new clippings to ingest: [list]. Proceed?"

   This is the single source of truth for what's been processed. Do NOT infer from summary filenames — use the log.

---

## Wiki Quality Standards

Follow these on every page you create or update.

### Page Naming

Use lowercase with hyphens: `event-sourcing.md`, `postgresql.md`, `react-hooks.md`. This keeps `[[wikilinks]]` predictable and Obsidian-friendly. The `title` in frontmatter can be human-readable ("Event Sourcing").

### One Topic Per Page

Each page covers exactly one concept or entity. If a topic has two distinct aspects (e.g., "React" the library vs "React" the rendering philosophy), split into separate pages linked to each other.

**Granularity rule:** A concept or entity gets its own page only if you can write at least a meaningful TL;DR and two body paragraphs about it from the sources. If not, it's a mention — link to it with a `[[wikilink]]` but don't create a stub. Never create placeholder pages.

### Start With the Answer

Every page opens with a TL;DR — 1-2 sentences that tell the reader what this thing is and why it matters. A reader who stops after the TL;DR should still walk away informed.

### Write to Synthesize, Not to Extract

Don't copy from sources. Synthesize across them. Bad: "Source A says X. Source B says Y." Good: "X is the dominant approach, though Y offers an alternative when [condition] ([[summaries/source-b]])."

When sources conflict, state the tension explicitly: "There's disagreement here — [claim A] ([[summaries/source-a]]) vs [claim B] ([[summaries/source-b]]). The difference comes down to [root cause]."

### Voice

Write like a knowledgeable colleague explaining something over coffee. Direct, clear, opinionated where the sources support it. No filler, no hedging without reason. Use present tense.

### Evergreen First

State things that will stay true. Date anything timely. Don't write "recently" or "the latest version" — write "as of 2024" so the reader knows when the claim was made.

### No Duplication

Each fact lives in exactly one canonical page. Other pages link to it. If you find yourself writing the same explanation in two places, stop — put it in one and `[[wikilink]]` from the other.

---

## Page Templates

### Summary Page (`wiki/summaries/[source-name].md`)

A summary is a standalone narrative — someone should understand the source's contribution without opening the original.

```markdown
---
title: "Summary: [Source Title]"
type: summary
source_file: "clippings/[filename]"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [topic1, topic2]
---

**TL;DR:** [2-3 sentences capturing the source's core argument or contribution.]

## Key Ideas

[Narrative prose — not bullet points. Walk through the source's main ideas in 3-5 paragraphs. Use [[wikilinks]] when referencing concepts or entities that have their own pages. Explain how ideas connect to each other.]

## Notable Claims

[Specific claims worth tracking — things that could be verified, challenged, or built upon. Each claim on its own line with context.]

- [Claim] — [context or caveat]
- [Claim] — [context or caveat]

## Open Questions

[Questions the source raises but doesn't answer. These are prompts for future research — things worth adding new clippings about.]

- [Question]
- [Question]
```

**Target length:** 300-500 words. Long enough to stand alone, short enough to scan.

### Concept Page (`wiki/concepts/[concept-name].md`)

A concept page explains an idea. It follows the "explanation" quadrant of Diátaxis — it builds understanding, not instructions.

```markdown
---
title: [Concept Name]
type: concept
sources:
  - "[[summaries/source-name]]"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [topic1, topic2]
---

**TL;DR:** [1-2 sentences. What is this concept and why does it matter?]

## What It Is

[Clear definition. Then explain the core idea in 2-3 paragraphs. Use concrete examples where possible. Synthesize across sources — don't attribute each sentence.]

## How It Connects

[Relationships to other concepts and entities. Not a flat list — explain WHY they connect. "Event sourcing is often paired with [[concepts/cqrs]] because storing events as the source of truth naturally separates the write model from read projections."]

## Trade-offs

[What you gain and what you pay. When is this the right choice vs alternatives? Be opinionated where sources support it.]

## Sources

[Auto-generated from frontmatter, but also add inline citations throughout the body as [[wikilinks]].]
```

**Target length:** 200-400 words. Dense, not exhaustive.

### Entity Page (`wiki/entities/[entity-name].md`)

An entity page describes a concrete thing — a tool, project, person, organization, technology. It's closer to "reference" in Diátaxis — something you look up.

```markdown
---
title: [Entity Name]
type: entity
sources:
  - "[[summaries/source-name]]"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [topic1, topic2]
---

**TL;DR:** [1-2 sentences. What is this entity and what is it known for?]

## Overview

[What it is, what it does, what makes it distinctive. 1-2 paragraphs.]

## In Context

[How this entity relates to the wiki's topics. Why does it appear in your knowledge base? What role does it play in the concepts you're tracking? Link to relevant [[concepts/]] and other [[entities/]].]

## Key Facts

[Concrete, lookupable facts. Version info, dates, ownership — anything that makes this a useful reference. Date any fact that could go stale: "as of YYYY-MM."]

## Sources

[From frontmatter + inline citations.]
```

**Target length:** 150-300 words. Scannable reference.

---

## Ingestion Pipeline

For each source document:

### Step 1: Read and Understand

Read the full document. Before writing anything, identify:
- The source's core argument or contribution (this becomes the TL;DR)
- 3-7 significant concepts (ideas, patterns, techniques)
- 1-5 entities (tools, people, orgs, projects)
- Any claims that conflict with existing wiki content

### Step 2: Create the Summary Page

Write `wiki/summaries/[source-name].md` following the summary template above. The summary is a narrative, not bullet extraction.

### Step 3: Update or Create Concept Pages

For each significant concept (passes the granularity rule — can you write a TL;DR + two paragraphs?):

1. Grep for existing page: `wiki/concepts/[concept-name].md`
2. **If it exists:** Read it. Integrate the new source's perspective into the existing prose. Don't append a new section per source — weave it in. Add the summary to the sources list in frontmatter. Update the `updated` date. If the new source conflicts with existing content, state the tension explicitly in the body.
3. **If it doesn't exist:** Create it following the concept template.

**When updating, preserve coherence.** The page should read as one unified piece, not a patchwork of additions from different sources. If integrating new info makes the page incoherent, restructure it.

### Step 4: Update or Create Entity Pages

Same granularity rule. For each entity worth its own page:

1. Grep for existing: `wiki/entities/[entity-name].md`
2. **If it exists:** Integrate new information. Update facts, add context, enrich "In Context" with new connections.
3. **If it doesn't exist:** Create it following the entity template.

### Step 5: Cross-Reference (Meaningful Links Only)

Add `[[wikilinks]]` where a reference genuinely helps the reader understand the current page. Not every mention needs a link.

**Link when:** The linked page provides context the reader would likely want next.
**Don't link when:** The mention is incidental (e.g., "JavaScript" in a page about React — the reader already knows).

For bidirectional links: if page A links to page B in a meaningful way, check if page B would benefit from linking back. Only add the backlink if it's useful in context — not just for graph completeness. If it makes sense, add it in the "How It Connects" or "In Context" section, not in a mechanical "See also" list.

### Step 6: Update the Index

Read `wiki/index.md`. Add entries for new pages. Each entry is the page link and a single sentence description. Keep organized by type. Remove any entries for pages that no longer exist.

### Step 7: Update the Log

Append to `wiki/log.md`. The `source_file` field is critical — it's how future runs detect the delta.

```markdown
## YYYY-MM-DD — Ingested: [source name]

- **source_file:** `clippings/[exact filename]`
- **TL;DR:** [One sentence — what this source is about]
- Created: [[summaries/source-name]], [[concepts/new-concept]], ...
- Updated: [[concepts/existing-concept]], [[entities/existing-entity]], ...
- Conflicts noted: [any tensions with existing content, or "none"]
```

---

## After All Sources Are Ingested

Report to the user:
- Sources ingested, pages created, pages updated
- Any conflicts found between new and existing content
- High-value nodes — concepts that appear across multiple sources
- Suggested next reads — gaps the new sources revealed

---

## Initial Wiki Files

**wiki/index.md:**
```markdown
---
title: Wiki Index
type: index
updated: YYYY-MM-DD
---

# Wiki Index

The landing page for this knowledge base. Browse by type or use search.

## Concepts

(none yet)

## Entities

(none yet)

## Summaries

(none yet)
```

**wiki/log.md:**
```markdown
---
title: Ingestion Log
type: log
---

# Ingestion Log

Chronological record of every source ingested and what it changed.
```
