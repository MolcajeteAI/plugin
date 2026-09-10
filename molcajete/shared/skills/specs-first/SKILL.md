---
name: specs-first
description: >-
  The read order every entry point runs before it changes anything — the
  feature index, then the use cases, then the architecture document, then the
  requirements, then the code, with a web search at any point. Owns the
  frontmatter-first scan, the two entry modes (by ID, by description), the
  configuration inventory, and the exit checklist: what is built, how it works,
  what conflicts, what else reads it, what configuration governs it. Loaded by
  /m:build, /m:explore, /m:spec, /m:change, and /m:fix.
---

# Specs First

A spec tree states what is built and where it lives. Read it before the code. The code shows what exists. The spec shows what was meant. The two disagree more often than either is wrong, and a change proposed from the code alone overrides a feature, duplicates a use case, or breaks a scenario nobody re-read. This skill fixes the order. The caller decides what to do with what it finds.

## Why This Order

1. **Features first.** A feature row in `specs/FEATURES.md` is one sentence per capability. It is the highest signal per byte in the tree, so it is the cheapest way to find what already exists.
2. **Use cases second.** A use case is the unit that changes. Its scenarios are the assertions the change must keep or replace.
3. **Architecture third.** `ARCHITECTURE.md` says how the feature works today. It names the code, the events, the entities, and the settings, so it is the map into the code.
4. **Requirements fourth.** `REQUIREMENTS.md` holds the Non-Goals and the NFRs. That is where a conflict hides.
5. **Code last.** By then you know which files to open and what each one is supposed to do.

## Read the Frontmatter First

Every spec file opens with a YAML block between the first `---` and the second. Read that block before you read a body. It is enough to decide whether the file is a candidate.

| File | Frontmatter carries |
|------|---------------------|
| `REQUIREMENTS.md` | `id`, `name`, `module`, `domain`, `status`, `refs` |
| `UC-*.md` | `id`, `name`, `feature`, `status`, `actor` |
| `ARCHITECTURE.md` | `id`, `name`, `use_cases`, `scenarios`, `last_update` |

`specs/FEATURES.md` and every `USE-CASES.md` carry no frontmatter. They are index tables, and their one-line descriptions are the scan.

Read a body in full only for a candidate. Read the index layer yourself. Never send a subagent to read it: the `spec-lookup` skill explains that a subagent returns a summary, and the summary drops the module instance the query needed.

## Two Entry Modes

**By ID.** The caller gives one or more `FEAT-XXXX` or `UC-XXXX` IDs (`/m:change`, `/m:fix`). Start from them. Then add every feature named in a candidate's `refs`, and every feature whose Code Map names a file the candidate's Code Map also names. A shared file is a shared feature.

**By description.** The caller gives words and no IDs (`/m:build`, `/m:explore`, `/m:spec`). Run the `spec-lookup` skill's **Resolve by Keyword**, Pass 0 to Pass 4, to rank the candidates. Take every feature and use case in the main tier, plus every module instance the module-completeness rule adds. When nothing scores, the request is an addition: the candidates are then the features in the same domain as the request, read for conflicts only.

**Both modes.** When the arguments name a document under `.molcajete/explorations/`, read it in full before anything else. It already holds the candidate features, the prerequisites, and the decisions the user aligned on. Read any `research/*.md` or `.molcajete/research/*.md` the arguments name in the same way.

## The Order

Run the six steps in order. The labels are `S1` to `S6` so they never collide with a calling command's step numbers.

### S1 — Features

Read every row of `specs/FEATURES.md`. Then read the frontmatter of each candidate feature's `REQUIREMENTS.md` under `specs/features/{module}/FEAT-XXXX-{slug}/`. Output: the candidate list, with each feature's `status` and `refs`.

### S2 — Use cases

For each candidate feature, read `USE-CASES.md`, then the frontmatter of every sibling `UC-*.md`. Then read the full body — every `### SC-XXXX:` block — of each use case the work changes or appends to, plus that use case's `CHANGELOG.md` under its support folder.

A use case you will not edit is still a candidate when one of its scenarios asserts the behavior you are about to change. Read it in full. It is the one that breaks.

### S3 — Architecture

Read each candidate feature's `ARCHITECTURE.md` in full: the Component Inventory, the API Surface, the Event Topology, the Data Model, the Code Map, the Architecture Decisions, and the Testing Decisions. An ADR is a decision a future agent must not reverse in silence. Read every one before you propose a shape.

### S4 — Requirements

Read each candidate feature's `REQUIREMENTS.md` body: the Non-Goals, the UI section, the FRs, and the NFRs. A Non-Goal that names what you are about to build is a conflict. Record it. Never build around it in silence.

### S5 — Code

Open every file the Code Map names for the use cases in scope. Then read beyond the Code Map, because the specs are not full coverage and a Code Map row is a starting point, not a boundary:

- grep the exported symbols of each file for their callers,
- grep every event name, entity name, and setting name the architecture tables mention,
- read the canonical integration test for each use case in scope, at the `plan-authoring` skill's Test File Convention path, when it exists.

Code that does what no scenario states is a finding. Record it as a candidate `cover` item or as a sibling-spec item for the `resolution-gate` skill's category C13. It is never a reason to stop reading.

### S6 — Configuration

Before you propose any setting, find the sets that exist. Read:

- `specs/TECH-STACK.md`,
- `.molcajete/settings.json`,
- the host `CLAUDE.md` and every file under `.claude/rules/`,
- every file the Component Inventory marks as configuration, settings, environment, or feature flags,
- every setting the S5 files read.

Write one row per set: the set, its location, and the settings the touched code reads.

**Extend the set that already governs the nearest behavior.** Create a new set only when no existing set has the same reader, and record that as a decision with its reason. A second setting with the same reader and a near-identical name is the defect this step exists to stop.

### Web search, at any point

When a library, a protocol, or an external API's behavior is uncertain, use `WebSearch` or `WebFetch` at that moment. Cite what you used. Do not defer the search to a research step that may never run.

## Exit Checklist

Do not leave this skill until you can state each of these in one sentence, with a file path or an ID:

1. **What is built.** Which features and use cases exist for this capability, and their `status`.
2. **How it works.** The files, the driving port, the events, the entities, and the settings that serve it.
3. **What conflicts.** Every Non-Goal, sibling scenario, ADR, or NFR the change contradicts.
4. **What else reads it.** Every caller, consumer, and setting reader outside the candidate features.
5. **What configuration governs it.** The set, its location, and the settings it holds.

A blank line is a reason to read more. It is never a reason to guess.

## What the Caller Does Next

| Caller | Where the checklist goes |
|--------|--------------------------|
| `/m:build` | Step 4's interview asks only what the checklist left open. Item 5 fills the `**Configuration changes:**` block |
| `/m:explore` | The open interview, then the exploration document |
| `/m:spec` | The classification of each entity, and the C13 sibling sweep |
| `/m:change` | The draft spec edit, with the callers and settings it reaches |
| `/m:fix` | The diagnosis, with the `file:line` that is wrong or silent |
