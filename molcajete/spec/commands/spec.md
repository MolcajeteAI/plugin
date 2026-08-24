---
description: Create or update features and use cases (with inline scenarios) from free-form natural language
model: claude-opus-5
argument-hint: <freeform spec description>
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
  - WebSearch
  - WebFetch
---

# Spec Command

The single spec-authoring entry point. Takes free-form natural language and proposes new or updated features, use cases, and inline scenarios — across any number of entities in one invocation.

**`/m:spec` writes one artifact: `request.md`** — the change request under `specs/changes/{change-id}/`, per the change-request skill. It never edits the spec tree — the base branch's specs stay exactly as they are until execution applies the request on the run branch. No plans, no code, no tests, no task IDs. After spec completes, the lifecycle continues with `molcajete build {change-id}`.

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

**Writing style:** every document you write and every message you print uses Simplified Technical English. Every one carries only what its reader needs. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/shared/skills/output-economy/SKILL.md` before writing.

## Step 1: Load Skills

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md`
3. `${CLAUDE_PLUGIN_ROOT}/spec/skills/architecture/SKILL.md`
4. `${CLAUDE_PLUGIN_ROOT}/spec/skills/module-authoring/SKILL.md` — the charters, INTERFACE.md, DATA.md, and the two authoring questions.
5. `${CLAUDE_PLUGIN_ROOT}/spec/skills/change-request/SKILL.md` — the request.md format Step 9 writes.
6. `${CLAUDE_PLUGIN_ROOT}/shared/skills/resolution-gate/SKILL.md` — the analysis sweep and the batched ask that run before Step 9 writes anything.
7. `${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/SKILL.md`

## Step 2: Verify Prerequisites

`specs/PROJECT.md` and `specs/MODULES.md` must exist. If missing: "Project foundation not found. Run `/m:setup` first." Stop.

## Step 3: Load Spec Context

- Project-level: `specs/PROJECT.md`, `specs/TECH-STACK.md`, `specs/ACTORS.md`, `specs/MODULES.md` (including the charters), `specs/DOMAINS.md`, `specs/FEATURES.md` (skip missing optional files)
- Per-module: `specs/modules/{module}/INTERFACE.md` and `DATA.md` for every module the input plausibly touches.
- Per-feature: For every feature in FEATURES.md, read `specs/features/{module}/FEAT-XXXX-{slug}/REQUIREMENTS.md` and `USE-CASES.md`. On very large projects launch one Explore subagent per domain.

## Step 4: Research (optional)

If `$ARGUMENTS` references `research/*.md`, load `${CLAUDE_PLUGIN_ROOT}/research/skills/headless-research/SKILL.md` and pass it the reference. Otherwise use the freeform input as the research query if the topic is new and non-obvious. Skip research for small edits.

## Step 5: Collect Input

If `$ARGUMENTS` is empty, ask via AskUserQuestion: "Describe what to spec out — new features, new use cases for existing features, edits to existing features or UCs, or any combination."

`/m:spec` is for creating or extending specs. For bug fixes ("spec says X, code does Y"), use `/m:fix`. For intentional behavior changes to a built UC, use `/m:change`. For extracting specs from existing code, use `/m:cover`.

## Step 6: Classify and Plan

Parse the free-form text against the loaded context and classify each entity as a **new feature** (a capability not in any existing feature — resolve module + domain per the feature-authoring skill's Module and Domain Resolution), a **new use case** (a workflow belonging to an existing feature), a **modified feature** (adds or changes requirements), or a **modified use case** (adds or changes scenarios). Step 9 has the write mechanics for each.

Then look sideways. Run the `resolution-gate` skill's `C13` category across every sibling spec loaded in Step 3: find each already-written FEAT or UC that the entities above contradict, rename, or retire. A UC whose scenario asserts a behavior this run redefines is contradicted, even when the user asked for no change to it. Add every contradicted UC to the **Modified UCs** list, with one line that names what contradicts it. Those UCs then flow through Step 9's **Modified Use Cases** mechanics, unchanged. Never carry the contradiction forward as a note for a later command.

Then check the charters, per the module-authoring skill's two questions. When the new behavior fits no module's charter, ask which module absorbs it or whether it justifies a new module — the charter amendment goes into the request. When the change needs a relationship not in the caller's `Depends on`, ask whether the relationship should exist — the charter addition, with its why, goes into the request. Never resolve either silently.

Present the full plan as a brief, then gate on it:

- Brief: print the plan as Markdown under whichever of these headings have entries — New Features,
  New UCs, Modified Features, Modified UCs. Under each, list the entity with a one-line description
  of what will be written or changed. Recommend "Proceed".
- Question: "Proceed with this spec plan?"
- Header: "Spec plan"
- Options: "Proceed" / "Edit" / "Cancel"

## Step 7: Streamlined Reviews

For each entity, present a consolidated review. The content is the brief — show all sections at once (not one at a time — the user already gave substantial context):

- Brief: for a new entity, print its full content as Markdown, section by section. For a
  modification, print a fenced diff plus the version-bump notice. Either way this is the whole
  payload, so it never belongs in `question` or an option `preview`.
- Question: "Is `{entity}` correct?"
- Header: the entity ID (12 characters maximum)
- Options: "Yes, looks good" / "Edit"

Follow the multi-module rules from the authoring skills when a feature spans 2+ modules.

For each new UC, after confirming the UC, ask once: "Add another scenario?" — loop until no.

## Step 8: Generate IDs

Count total new entity IDs needed (features + use cases + scenarios + FRs + NFRs + USs). Count each **logical** entity **once**, regardless of how many modules it will exist in:

- A single feature that spans 2+ modules counts as **one** FEAT-XXXX ID (reused across module folders).
- A single use case that spans 2+ modules counts as **one** UC-XXXX ID (reused across module-scoped UC files — see `spec/skills/usecase-authoring/SKILL.md` → Module-Scoped Use Cases).
- Scenarios (`SC-`), functional requirements (`FR-`), non-functional requirements (`NFR-`), and user stories (`US-`) are counted per module-instance when their content is module-scoped, because each module-instance's file gets its own set of scenarios/requirements.

One batch call:

```bash
node ${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/scripts/generate-id.js {total_count}
```

Assign prefixes in order.

## Step 9: Write the Change Request

Before you write, run the `resolution-gate` skill's **The Procedure** once over every entity in scope. Testability concerns noticed while drafting enter that gate. Nothing is written while an item is open.

**This step edits no spec file.** It composes every proposed edit into one `request.md`, per the change-request skill and its template. The apply step executes these diffs verbatim at execution time, so write each diff exactly as it must land.

1. Create the change directory: run `date -u +%Y%m%dT%H%M%S` for the timestamp, pick a short kebab-case slug, then `mkdir -p specs/changes/{timestamp}-{slug}`.
2. Compose the spec diffs, in dependency order — parents before children:
   - **New Features** (per selected module): the full REQUIREMENTS.md content the apply step will write (from the feature-authoring template, module + domain frontmatter, section order per the skill), the FEATURES.md row, and the ARCHITECTURE.md scaffold note. Shown whole, marked new.
   - **Modified Features:** each REQUIREMENTS.md item as before and after.
   - **New Use Cases** — per module-instance, per the usecase-authoring skill's multi-module rules: the full UC file content (frontmatter with `status: pending, version: 1`, objective, preconditions, trigger, inline scenarios with their `<a id>` anchors), the USE-CASES.md row, and the ARCHITECTURE.md rows the scenarios imply. Every module-instance shares the same `UC-XXXX` ID but carries its own module-scoped name, actor, trigger, scenarios, and side effects.
   - **Modified Use Cases:** resolve the UC-XXXX to its module-instances (glob `specs/features/*/FEAT-*/UC-XXXX-*.md`); show each affected item as before and after; note the per-file `version` increment. Never change the UC-XXXX ID.
3. Compose the interface section per touched module: the INTERFACE.md element and type diffs, and the class diagram of the surface as it will be.
4. Compose the data section per touched module: the entity-relationship diagram with every field's responsibility, touched tables marked, read-only tables kept for context.
5. Compose the flows: one sequence diagram per changed flow.
6. Compose the module-relationships section, including any charter amendment Step 6's questions produced.
7. Stage the assets. When the input describes a graphical interface, the spec diffs carry ASCII mockups per the change-request skill's **The UI Is Contract Content**. When the user provided image files, copy each one to `specs/changes/{change-id}/assets/` with a descriptive name (feature-authoring skill, Asset Management) and reference it from the diff — the apply step lands it in the feature's `assets/` folder.
8. Close every change entry with its `### Additional Notes` and `### Examples` subsections — present even when empty. Seed examples the user already gave (exact values from Step 5's input) as `E-NNN` entries.
9. Write `specs/changes/{change-id}/request.md`. Besides the staged assets, this is the only thing this command writes.

## Step 10: Report

Present the request for review. The report is the request's own summary, not a rewrite of it:

````markdown
## Change request ready — {change-id}

| Feature | Module | What changes |
|---|---|---|
| Send email OTP ([FEAT-3Z2K](../features/auth/FEAT-3Z2K-email-otp/REQUIREMENTS.md#FEAT-3Z2K)) | `auth` | New UC, 2 scenarios, 1 new interface element |

Review `specs/changes/{change-id}/request.md`. Edit the **Additional Notes** and **Examples** subsections freely — the run reads them at trigger time. Notes flow into task rationale; every example becomes a test fixture or assertion.
````

**Testing decisions prints only when the Step 9 gate resolved a concern** — an external API without a
sandbox, a dependency on time or randomness, an env-flag branch. Omit the whole section otherwise.

End the report with the explicit hand-off:

> Next: review the request, then run `molcajete build {change-id}` to apply it and execute. To abandon it, delete the change directory — the spec tree never changed.
