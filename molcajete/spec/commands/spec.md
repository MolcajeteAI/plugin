---
description: Create or update features and use cases (with inline scenarios) from free-form natural language
model: claude-opus-4-6
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

The single spec-authoring entry point. Takes free-form natural language and creates or updates features, use cases, and inline scenarios — across any number of entities in one invocation.

**`/m:spec` writes spec prose only.** It does not produce slices, plans, or code. After spec completes, the lifecycle continues with `/m:plan` → `/m:build`.

**Use AskUserQuestion for all user interaction.** Never plain-text questions.

## Step 1: Load Skills

Read in one batch:

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md`
3. `${CLAUDE_PLUGIN_ROOT}/spec/skills/architecture/SKILL.md`
4. `${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/SKILL.md`
5. `${CLAUDE_PLUGIN_ROOT}/shared/skills/uc-log/SKILL.md` — CHANGELOG mechanics only.
6. `${CLAUDE_PLUGIN_ROOT}/shared/skills/status-rollup/SKILL.md` — how to write UC and Feature status directly.

## Step 2: Verify Prerequisites

`specs/PROJECT.md` and `specs/MODULES.md` must exist. If missing: "Project foundation not found. Run `/m:setup` first." Stop.

## Step 3: Load Spec Context

Read in parallel:

- Project-level: `specs/PROJECT.md`, `specs/TECH-STACK.md`, `specs/ACTORS.md`, `specs/MODULES.md`, `specs/DOMAINS.md`, `specs/FEATURES.md` (skip missing optional files)
- Per-feature: For every feature in FEATURES.md, read `specs/features/{module}/FEAT-XXXX-{slug}/REQUIREMENTS.md` and `USE-CASES.md`. Parallelize aggressively; on very large projects launch one Explore subagent per domain.

## Step 4: Research (optional)

If `$ARGUMENTS` references `research/*.md`, load `${CLAUDE_PLUGIN_ROOT}/research/skills/headless-research/SKILL.md` and pass it the reference. Otherwise use the freeform input as the research query if the topic is new and non-obvious. Skip research for small edits.

## Step 5: Collect Input

If `$ARGUMENTS` is empty, ask via AskUserQuestion: "Describe what to spec out — new features, new use cases for existing features, edits to existing features or UCs, or any combination."

`/m:spec` is for creating or extending specs. For bug fixes ("spec says X, code does Y"), use `/m:fix`. For intentional behavior changes to a built UC, use `/m:change`. For extracting specs from existing code, use `/m:cover`.

## Step 6: Classify and Plan

Parse the free-form text against the loaded context. Classify each entity into:

| Category | Trigger | Action |
|----------|---------|--------|
| **New Feature** | Capability not in any existing feature | Resolve module + domain; create feature dir + REQUIREMENTS.md + USE-CASES.md + ARCHITECTURE.md; add FEATURES.md row |
| **New Use Case** | Workflow belonging to an existing feature | Create UC spec file (`UC-XXXX-{slug}.md`) + support folder with `CHANGELOG.md`; add USE-CASES.md row |
| **Modified Feature** | Adds/changes requirements | Update REQUIREMENTS.md (new FRs, NFRs, acceptance criteria) |
| **Modified Use Case** | Adds/changes scenarios | Update `UC-XXXX-{slug}.md`; increment version. UC `status` is updated by the `uc-log` skill in Step 10. |

For new features, resolve module + domain per the feature-authoring skill's Module and Domain Resolution.

Present the full plan via a single AskUserQuestion (New Features, New UCs, Modified Features, Modified UCs — only sections that have entries). Options: "Proceed" / "Edit" (Other) / "Cancel".

## Step 7: Streamlined Reviews

For each entity, present a consolidated review via AskUserQuestion. Show all sections at once (not one at a time — the user already gave substantial context). For new entities, present full content for confirmation; for modifications, present a diff-style view with version-bump notice.

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

`/m:spec` does **not** generate slice IDs. Slices are produced by `/m:plan`.

## Step 9: Write Spec Documents

Write in dependency order: parents before children.

**New Features** (per selected module):
1. `mkdir -p specs/features/{module}/FEAT-XXXX-{slug}` — UCs are direct children of this folder.
2. Write REQUIREMENTS.md (from template, with module + domain frontmatter; follow feature-authoring section order).
3. Write empty USE-CASES.md.
4. Write ARCHITECTURE.md scaffold from `${CLAUDE_PLUGIN_ROOT}/spec/skills/architecture/templates/ARCHITECTURE-template.md`. Populate every applicable table per the architecture skill's **Table Filling** rules — Component Inventory, API Surface, Code Map, and Event Topology / Integration Points where the feature has rows for them. Leave a table empty only when the feature genuinely has no rows. An ARCHITECTURE.md with empty mandatory tables blocks Step 9.
5. Append FEATURES.md row.

**Modified Features:** Edit REQUIREMENTS.md. Refresh ARCHITECTURE.md tables affected by the new/changed requirements per the architecture skill's additive Population Rules.

**New Use Cases** — for every new UC, iterate over every module the UC applies to (one iteration for single-module UCs, multiple iterations for shared-ID multi-module UCs per the usecase-authoring skill):

1. Compute the module-scoped slug from the module-scoped UC name confirmed for this module.
2. `mkdir -p specs/features/{module}/FEAT-XXXX-{slug-for-module}/UC-XXXX-{slug-for-module}` — the UC's support folder. Slice files (when `/m:plan` produces them later) and `CHANGELOG.md` live inside this folder.
3. Write the UC spec file `specs/features/{module}/FEAT-XXXX-{slug-for-module}/UC-XXXX-{slug-for-module}.md` (sibling of REQUIREMENTS.md / USE-CASES.md / ARCHITECTURE.md) with frontmatter (id, name, feature, status: pending, version: 1, actor) + title + objective + preconditions + trigger + inline scenarios with `---` separators. **Every module-instance shares the same `UC-XXXX` ID but carries its own module-scoped `name:`, actor, trigger, scenarios, and side effects.**
4. Initialize the change log file `specs/features/{module}/FEAT-XXXX-{slug-for-module}/UC-XXXX-{slug-for-module}/CHANGELOG.md` per the `uc-log` shared skill (empty TODO/DONE sections). Step 10 appends the first entry (fanned out across module-instances when multi-module).
5. Append USE-CASES.md row to that module's feature folder (file link points to the module-scoped `UC-XXXX-{slug-for-module}.md`, a direct sibling). Update that module's feature ARCHITECTURE.md per the architecture skill: every file that this module-instance's scenarios imply must have a Component Inventory row; every `SC-` and the module-instance's UC itself must have a Code Map row; new endpoints must appear in API Surface. Update the `use_cases` and `scenarios` frontmatter arrays and `last_update`.

**Modified Use Cases:** Resolve the UC-XXXX to its module-instances (glob `specs/features/*/FEAT-*/UC-XXXX-*.md`). Apply the edit to each affected module-instance's `UC-XXXX-{slug}.md`; increment frontmatter `version` per file; never change the UC-XXXX ID. Update each affected module's ARCHITECTURE.md rows for newly touched files. Do **not** edit, add, or delete slice files — slice authorship belongs to `/m:plan`.

**No slice files. No code files. No tests.** `/m:spec` is spec prose only.

## Step 10: Append Changelog Entry and Update Statuses

For every UC-XXXX touched in Step 9 (new or modified), iterate over every module-instance and use the `uc-log` shared skill to append the changelog entry, then apply the direct-write status rules from the `status-rollup` shared skill.

1. **Append a changelog entry** to each module-instance's `CHANGELOG.md` (under `TODO:`, prepended) with:
   - timestamp (UTC, `YYYYMMDDTHHMMSS`) — **same timestamp** across every module-instance of the same UC-XXXX in this run
   - status: `pending`
   - command: `spec`
   - plan: `—`
   - modules: comma-separated list of module IDs the UC-XXXX exists in. Include this token whenever the UC has 2+ module-instances. Omit for single-module UCs.
   - reason: one-line description of what was created or changed (e.g., "added UC for password reset", "added FR-0Pq2 to require email verification"). Reasons may differ per module-instance when the change is module-scoped.
2. **Set each module-instance's frontmatter `status`** directly:
   - **Brand-new UC instance** → `status: pending`.
   - **Modifying a previously-`implemented` UC instance** → `status: dirty`.
   - **Modifying a `pending` or `dirty` UC instance** → status unchanged.
3. **Recompute each affected parent feature's frontmatter `status`** by rolling up over its child UCs. Read each UC's `status:` from that module's `UC-XXXX-{slug}.md` frontmatter (not the changelog). Apply the roll-up rule from the `status-rollup` skill:
   - All UCs `implemented` → feature `implemented`.
   - At least one UC `dirty`, OR mixed `pending` + `implemented` → feature `dirty`.
   - All UCs `pending` or `dirty` with no `implemented` → feature `pending`.
   Write the result to each affected module's `REQUIREMENTS.md` frontmatter `status`.

The changelog is **not** the status source of truth. Status is written directly per the `status-rollup` skill.

## Step 11: Report

Tell the user what was created and updated, grouped by UC. For each:

- The new or modified files (`UC-XXXX-{slug}.md`, `CHANGELOG.md`, REQUIREMENTS.md edits, FEATURES.md row, etc.).
- The new UC status (`pending` or `dirty`) and the new Feature status if it changed.
- The changelog entry that was appended.

If testability signals were detected in any new scenario (external APIs without sandbox, time/randomness, env-flag branches), surface them inline in the report as a brief **Testability Notes** list with category. They are advisory output, not a recorded table.

End the report with the explicit hand-off:

> Next: run `/m:plan <FEAT-XXXX | UC-XXXX> [more IDs ...]` to decompose the changes into slices and write the plan that `/m:build` will execute.
