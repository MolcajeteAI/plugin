---
description: Record a bug ("spec says X, code does Y") against one or more existing FEAT/UC IDs. Updates specs only when the spec was wrong; always logs a pending entry so /m:plan can produce a regression plan.
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

# Fix Command

`/m:fix` records a bug against an existing UC: **"the use case is supposed to do X, but the code does Y."** The bug may or may not require a spec edit.

- If the spec already says the right thing and only the code is wrong, `/m:fix` writes nothing to the spec — it just appends a `pending` log entry so `/m:plan` can produce a one-task regression plan.
- If the spec was wrong or silent on the case, `/m:fix` updates the spec (and may add a new scenario or UC) before logging the entry.

`/m:fix` never writes production code, tests, slices, or plans. Hand-off to `/m:plan` is mandatory.

**Use AskUserQuestion for all user interaction.**

## Step 1: Parse Arguments

`$ARGUMENTS` must begin with one or more `FEAT-XXXX` or `UC-XXXX` IDs followed by the free-form description. Examples:

- `/m:fix UC-0KTg "duplicate email should return 409, currently returns 500"`
- `/m:fix UC-0KTg UC-0L2x "session cleanup leaves orphan tokens when refresh fails"`
- `/m:fix FEAT-0Fy0 "rate-limit headers are missing on 429 responses across the feature"`

If `$ARGUMENTS` does **not** start with a valid ID, refuse:

> `/m:fix` requires at least one `FEAT-XXXX` or `UC-XXXX` ID as the first argument. To extract specs from new code, use `/m:cover`. To create a new feature or UC, use `/m:spec`.

Stop without writing anything.

If multiple IDs are given, every UC must end up with a log entry in Step 7. Features expand to all their UCs (after Step 5 you must list each affected UC explicitly).

## Step 2: Load Skills

Read in one batch:

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/SKILL.md`
3. `${CLAUDE_PLUGIN_ROOT}/spec/skills/architecture/SKILL.md`
4. `${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/SKILL.md`
5. `${CLAUDE_PLUGIN_ROOT}/shared/skills/uc-log/SKILL.md` — CHANGELOG mechanics only.
6. `${CLAUDE_PLUGIN_ROOT}/shared/skills/status-rollup/SKILL.md` — how to write UC and Feature status directly.

## Step 3: Verify Prerequisites

`specs/PROJECT.md` and `specs/MODULES.md` must exist. Each ID referenced in `$ARGUMENTS` must resolve to an existing spec file. If any does not, refuse with a clear list of unresolved IDs.

## Step 4: Load the Referenced Specs

For each FEAT/UC ID:

- Resolve the spec path. Read `specs/features/{module}/FEAT-XXXX-{slug}/REQUIREMENTS.md` (and `USE-CASES.md`) for FEAT IDs. Read `specs/features/{module}/FEAT-XXXX-{slug}/UC-XXXX-{slug}.md` for UC IDs.
- Read the feature's `ARCHITECTURE.md`.
- Read the UC's `CHANGELOG.md` (for context on prior changes).

## Step 5: Diagnose

Compare the description in `$ARGUMENTS` against the loaded spec(s). Pick exactly one diagnosis per affected UC:

| Diagnosis | When | Action in Step 6 |
|-----------|------|------------------|
| **Spec correct, code wrong** | The current spec already states the desired behavior; the bug is purely in the implementation. | No spec edit. Log entry only. |
| **Spec silent** | The spec doesn't address the buggy behavior at all (missing scenario, missing FR). | Add the missing scenario or FR to the relevant UC / feature. |
| **Spec wrong** | The spec explicitly states the broken behavior; the spec itself needs to be corrected. | Edit the offending scenario / FR. Increment UC `version`. |

Surface the diagnosis(es) via a single AskUserQuestion before writing anything:

> "Here is my diagnosis for {ID}: {diagnosis} — {one-sentence justification}. {Proposed spec edit, or 'no spec edit'.} Proceed?"

Options: "Proceed" / "Edit" (user provides corrections via Other) / "Cancel".

## Step 6: Apply Spec Edits (if any)

For each UC where the diagnosis was **Spec silent** or **Spec wrong**, edit `UC-XXXX-{slug}.md` (the UC spec file, a sibling of REQUIREMENTS / USE-CASES / ARCHITECTURE) accordingly. Increment frontmatter `version`. Update the feature's ARCHITECTURE.md tables only if the edit changed the Component Inventory / API Surface / Code Map surface (per the architecture skill's additive rules).

For UCs where the diagnosis was **Spec correct, code wrong**, write nothing to disk in this step.

`/m:fix` does **not** produce slices, plans, code, or tests. It does not edit existing slice files.

## Step 7: Append Log Entries and Update UC Status

For every UC named in `$ARGUMENTS` (expanded from any FEAT IDs), use the `uc-log` shared skill to:

1. Append a new entry to the UC's `CHANGELOG.md` (under `TODO:`, prepended) with:
   - timestamp (UTC, `YYYYMMDDTHHMMSS`)
   - status: `pending`
   - command: `fix`
   - plan: `—`
   - reason: one paragraph capturing what the bug is. When the diagnosis was Spec correct/Code wrong, the reason names the misbehavior and the expected behavior (so `/m:plan` can write a regression test). When the diagnosis required a spec edit, the reason summarizes the spec edit too.
2. **Set the UC's frontmatter `status`** directly per the `status-rollup` skill: a previously-`implemented` UC becomes `dirty`; a `pending` or `dirty` UC stays as it is.
3. **Recompute the parent feature's frontmatter `status`** by rolling up over its child UCs' frontmatter `status:` values (not the changelog). Apply the roll-up rule from the `status-rollup` skill and write the result to REQUIREMENTS.md.

Append a log entry **even when the spec was untouched.** The point of the entry is to drive `/m:plan` to produce a regression test, regardless of whether the spec moved.

## Step 8: Report

Tell the user:

- The diagnosis for each UC.
- The spec edits made (if any).
- The log entry appended per UC.
- The new UC status per UC.

End the report with the explicit hand-off:

> Next: run `/m:plan <UC-XXXX> [more IDs ...]` to produce the regression plan that `/m:build` will execute.
