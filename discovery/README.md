# Discovery

Discovery is a Claude Code plugin that runs an end-to-end product discovery flow — taking a raw product idea through ten guided phases and producing a fully-structured PRD as the deliverable.

**Why this exists.** Most product discovery happens informally — a few conversations, a deck, a half-written spec. The result is PRDs that look polished but skip the structural work: vague success metrics, untested assumptions, no kill criteria, scope unreconciled with timeline. Discovery encodes the discipline of a senior PM into a plugin: it asks the right questions in the right order, pushes back on imprecision, and refuses to write PRDs for ideas that should die.

**What makes it different.** Discovery is *process-disciplined*, not just template-filling. It validates every success metric against four dimensions before accepting it (measurable, baselined, time-bound, falsifiable). It forces an assumptions inventory and tags each assumption as risky, assumed, or validated. It runs an explicit kill gate at the end of competitive research and is willing to recommend not pursuing the idea. It maps every feature to a journey step — features that don't trace are scope creep.

**What you get.** A single command (`/discovery:start`) that runs ten phases as a guided interview, produces a fully-structured PRD, and supports a revision mode for post-delivery edits. Ten phases of friction, not template-filling.

> A PRD that doesn't show its working is not trustworthy.

Discovery doesn't ship PRDs. It ships *trustworthy* PRDs.

## The Workflow

```
"Start product discovery for [your idea]"
         |
         v
   [ PHASE 0 ]       Context: who's asking, who reads the output
         |
         v
   [ PHASE 1 ]       Scope: business goals, user goals (precise format),
         |            non-goals (categorized), assumptions inventory,
         |            locked problem statement
         v
   [ PHASE 2 ]       Competition: landscape, positioning gap,
         |            ── KILL GATE ── recommend pursue or kill
         v
   [ PHASE 3 ]       User journeys: happy + abandonment + error +
         |            retry + power-user paths, error-state inventory
         v
   [ PHASE 4 ]       Wireframes: structural sketches per screen
         |
         v
   [ PHASE 5 ]       Mockups: rich annotations, content notes,
         |            state variations
         v
   [ PHASE 6 ]       Epics & features: hierarchy mapped to journey steps
         |
         v
   [ PHASE 7 ]       Technical overview: one paragraph + arch diagram
         |
         v
   [ PHASE 8 ]       Metrics framework: north-star + primaries +
         |            secondaries with rationale
         v
   [ PHASE 9 ]       GTM: ICP, buyer persona, positioning, pricing,
         |            channels, marketing & sales plan
         v
   [ PHASE 10 ]      PRD assembly + optional paths-not-taken +
         |            timeline reconciliation + optional TAM/SAM/SOM
         v
   [ PRD.md ]        Single deliverable. Ready to share.
```

Each phase ends with a checkpoint where the user confirms before moving on.

### Resumability

Discovery is deliberately long — typically 1-3 hours of focused work for a real product. Stop mid-flow, come back next session, pick up where you left off. State persists in `discovery-state.md` in the project root.

### Kill Gate

After competitive research, Discovery explicitly evaluates whether to continue. The recommendation (PROCEED, PROCEED WITH CAVEATS, RECONSIDER, KILL) is the skill's, not the user's — and it's willing to recommend KILL. If KILL, the user can produce a kill memo instead of a PRD, continue with risks elevated, or loop back to re-scope.

### Push Back on Vague Metrics

"Users will love it" is not a success metric. Discovery rejects metrics that fail any of: measurable, baselined, time-bound, falsifiable — and rewrites them with the user. The PRD's metrics framework is structured as a hierarchy: north-star + 3-5 primary + 3-5 secondary, each with rationale.

### Revision Mode

After the PRD is delivered, the user can revise sections by saying *"revise the [section]"*. Discovery edits both `PRD.md` and `discovery-state.md` together, logs the revision, and surfaces cascading changes (e.g., metrics changed → TL;DR may need update).

## Install

On Claude Code, run this and you're good to go:

```bash
# Add the Incubyte marketplace
/plugin marketplace add incubyte/ai-plugins

# Install Discovery
/plugin install discovery@incubyte-plugins
```

> Restart your tool after installing the plugin.

## Use

```
/discovery:start
```

…or just say one of:

- *"start product discovery for [your idea]"*
- *"build me a PRD from scratch for [your idea]"*
- *"PM this for me — [your idea]"*
- *"validate this idea: [your idea]"*

Discovery triggers automatically on those phrases. The slash command is provided for discoverability and to match the convention used by other Incubyte plugins.

## Anatomy

```
discovery/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   └── start.md                              # /discovery:start
└── skills/
    └── product-discovery/
        ├── SKILL.md                          # the methodology (10 phases)
        └── references/
            ├── frameworks/                   # 15 framework references read internally
            └── templates/
                └── PRD.md.template           # canonical PRD structure
```

The framework references are read by the orchestrating skill at specific phases — they're not user-invocable. See `ATTRIBUTION.md` for upstream provenance of forked content.

## License

This plugin is licensed under **Apache-2.0**, distinct from the Proprietary license used by other Incubyte plugins. The choice is required by the upstream open-source licenses of the framework reference files (Apache-2.0 and MIT) — these cannot legally be relicensed as Proprietary. See [`ATTRIBUTION.md`](./ATTRIBUTION.md) for full provenance.
