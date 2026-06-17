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
5. `${CLAUDE_PLUGIN_ROOT}/shared/skills/uc-log/SKILL.md`

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

Count total new entity IDs needed (features + use cases + scenarios + FRs + NFRs + USs). One batch call:

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

**New Use Cases** — for every new UC:

1. `mkdir -p specs/features/{module}/FEAT-XXXX-{slug}/UC-XXXX-{slug}` — the UC's support folder. Slice files (when `/m:plan` produces them later) and `CHANGELOG.md` live inside this folder.
2. Write the UC spec file `specs/features/{module}/FEAT-XXXX-{slug}/UC-XXXX-{slug}.md` (sibling of REQUIREMENTS.md / USE-CASES.md / ARCHITECTURE.md) with frontmatter (id, name, feature, status: pending, version: 1, actor) + title + objective + preconditions + trigger + inline scenarios with `---` separators.
3. Initialize the change log file `specs/features/{module}/FEAT-XXXX-{slug}/UC-XXXX-{slug}/CHANGELOG.md` per the `uc-log` shared skill (empty TODO/DONE sections). Step 10 appends the first entry.
4. Append USE-CASES.md row (file link points to `UC-XXXX-{slug}.md`, a direct sibling). Update the parent feature's ARCHITECTURE.md per the architecture skill: every file that the UC's scenarios imply must have a Component Inventory row; every `SC-` and the UC itself must have a Code Map row; new endpoints must appear in API Surface. Update the `use_cases` and `scenarios` frontmatter arrays and `last_update`.

**Modified Use Cases:** Edit `UC-XXXX-{slug}.md`; increment frontmatter `version`; never change ID. Update ARCHITECTURE.md rows for any newly touched files. Do **not** edit, add, or delete slice files — slice authorship belongs to `/m:plan`.

**No slice files. No code files. No tests.** `/m:spec` is spec prose only.

## Step 10: Append Log Entry and Set UC Status

For every UC touched in Step 9 (new or modified), use the `uc-log` shared skill to:

1. Append a new entry to the UC's `CHANGELOG.md` (under `TODO:`, prepended) with:
   - timestamp (UTC, `YYYYMMDDTHHMMSS`)
   - status: `pending`
   - command: `spec`
   - plan: `—`
   - reason: one-line description of what was created or changed (e.g., "added UC for password reset", "added FR-0Pq2 to require email verification")
2. Recompute and write the UC's frontmatter `status` per the roll-up rules in the `uc-log` skill. For brand-new UCs the status is `pending`. For previously-`implemented` UCs that were just modified, the status becomes `dirty`.

## Step 11: Report

Tell the user what was created and updated, grouped by UC. For each:

- The new or modified files (`UC-XXXX-{slug}.md`, `CHANGELOG.md`, REQUIREMENTS.md edits, FEATURES.md row, etc.).
- The new UC status (`pending` or `dirty`).
- The log entry that was appended.

If testability signals were detected in any new scenario (external APIs without sandbox, time/randomness, env-flag branches), surface them inline in the report as a brief **Testability Notes** list with category. They are advisory output, not a recorded table.

End the report with the explicit hand-off:

> Next: run `/m:plan <FEAT-XXXX | UC-XXXX> [more IDs ...]` to decompose the changes into slices and write the plan that `/m:build` will execute.
