---
description: Intentionally change the behavior of an existing FEAT/UC. Always updates specs first, then logs a pending entry so /m:plan can produce the change plan.
model: claude-opus-4-6
argument-hint: <FEAT-XXXX | UC-XXXX> [more IDs ...] <description>
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
---

# Change Command

`/m:change` records an intentional change to an existing UC: **"we want this use case to behave differently going forward."**

Unlike `/m:fix` (where the spec might already be correct), `/m:change` **always** edits the spec — the change request *is* a spec edit. If the request only describes new behavior without a spec change, the user wanted `/m:fix` or `/m:spec` instead; suggest the right command and stop.

`/m:change` never writes production code, tests, slices, or plans. Hand-off to `/m:plan` is mandatory.

**Use AskUserQuestion for all user interaction.**

## Step 1: Parse Arguments

`$ARGUMENTS` must begin with one or more `FEAT-XXXX` or `UC-XXXX` IDs followed by the free-form description. Examples:

- `/m:change UC-0KTg "registration now also requires email verification before login"`
- `/m:change UC-0KTg UC-0L2x "session lifetime drops from 30 days to 7 days"`
- `/m:change FEAT-0Fy0 "the entire feature moves from sync HTTP to event-driven processing"`

If `$ARGUMENTS` does **not** start with a valid ID, refuse:

> `/m:change` requires at least one `FEAT-XXXX` or `UC-XXXX` ID as the first argument. To create a brand-new feature or UC, use `/m:spec`.

Stop without writing anything.

## Step 2: Load Skills

Read in one batch:

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/SKILL.md`
3. `${CLAUDE_PLUGIN_ROOT}/spec/skills/architecture/SKILL.md`
4. `${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/SKILL.md`
5. `${CLAUDE_PLUGIN_ROOT}/shared/skills/uc-log/SKILL.md`

## Step 3: Verify Prerequisites

`specs/PROJECT.md` and `specs/MODULES.md` must exist. Each ID referenced in `$ARGUMENTS` must resolve to an existing spec file. If any does not, refuse with a clear list of unresolved IDs.

## Step 4: Load the Referenced Specs

For each FEAT/UC ID:

- Resolve the spec path. Read `specs/modules/{module}/features/FEAT-XXXX-{slug}/REQUIREMENTS.md` (and `USE-CASES.md`) for FEAT IDs. Read `specs/modules/{module}/features/FEAT-XXXX-{slug}/UC-XXXX-{slug}/usecase.md` for UC IDs.
- Read the feature's `ARCHITECTURE.md`.
- Read the UC's `.log` (for context on prior changes).

## Step 5: Draft the Spec Edit

From the description in `$ARGUMENTS`, draft the spec edit per UC. The edit may:

- Change an existing scenario's Steps / Outcomes / Side Effects.
- Add or remove scenarios.
- Add, modify, or retire FRs/NFRs at the feature level (when the change scope justifies it).
- Add a new UC under the feature (when the request implies a workflow that doesn't fit any existing UC). Use the usecase-authoring skill's Step 4 (Write Files) to create the new UC folder, `usecase.md`, and `.log`.

Present a diff-style review via a single AskUserQuestion per affected UC:

> "Here is the proposed spec change for {UC ID}: {diff or before/after snippets}. Proceed?"

Options: "Proceed" / "Edit" (user provides corrections via Other) / "Cancel".

If after review the user determines no spec edit is needed, refuse:

> `/m:change` always edits specs. If no spec change is needed but the code should change, use `/m:fix`. Cancelling.

## Step 6: Apply Spec Edits

For each affected UC, edit `usecase.md`. Increment frontmatter `version`. Update the feature's `REQUIREMENTS.md` and `ARCHITECTURE.md` per the architecture skill's additive rules — Component Inventory / API Surface / Code Map rows for any newly-implied files or endpoints.

`/m:change` does **not** produce slices, plans, code, or tests. It does not edit existing slice files (`/m:plan` will decide whether to add, modify, or supersede them in its next run).

## Step 7: Append Log Entries and Update UC Status

For every UC affected, use the `uc-log` shared skill to:

1. Append a new entry to the UC's `.log` (under `TODO:`, prepended) with:
   - timestamp (UTC, `YYYYMMDDTHHMMSS`)
   - status: `pending`
   - command: `change`
   - plan: `—`
   - reason: one paragraph capturing what changed in the spec and why (e.g., "added email-verification gate before login per security review 2026-06-15")
2. Recompute and write the UC's frontmatter `status` per the `uc-log` skill's roll-up rules. A previously-`implemented` UC becomes `dirty`. A `pending` or `dirty` UC stays as it is.

## Step 8: Report

Tell the user:

- The spec edits made per UC (one or two lines each).
- The log entry appended per UC.
- The new UC status per UC.

End the report with the explicit hand-off:

> Next: run `/m:plan <UC-XXXX> [more IDs ...]` to decompose the change into slices and write the plan that `/m:build` will execute.
