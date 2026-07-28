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

`/m:fix` never writes production code, tests, or plans. Hand-off to `/m:plan` is mandatory.

**Use AskUserQuestion for all user interaction.**

## Step 1: Parse Arguments

`$ARGUMENTS` must begin with one or more `FEAT-XXXX` or `UC-XXXX` IDs followed by the free-form description. Examples:

- `/m:fix UC-0KTg "duplicate email should return 409, currently returns 500"`
- `/m:fix UC-0KTg UC-0L2x "session cleanup leaves orphan tokens when refresh fails"`
- `/m:fix FEAT-0Fy0 "rate-limit headers are missing on 429 responses across the feature"`

If `$ARGUMENTS` does **not** start with a valid ID, refuse:

> `/m:fix` requires at least one `FEAT-XXXX` or `UC-XXXX` ID as the first argument. To extract specs from new code, use `/m:cover`. To create a new feature or UC, use `/m:spec`.

Stop without writing anything.

If multiple IDs are given, every affected module-instance must end up with a log entry in Step 8. Features expand to all their UCs (after Step 6 you must list each affected UC explicitly), and each multi-module UC expands to its module-instances in Step 5.

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

## Step 5: Resolve UC Module-Instances

Multi-module UCs share one `UC-XXXX` ID across every module the capability appears in (see `spec/skills/usecase-authoring/SKILL.md` → Module-Scoped Use Cases). Before diagnosing, resolve each given `UC-XXXX` ID to the full set of module-instances that exist for it.

For each `UC-XXXX` ID:

1. Glob `specs/features/*/FEAT-*/UC-XXXX-*.md`. Every match is a module-instance of that UC. The module is the segment immediately under `specs/features/`.
2. Read every module-instance's spec file, its parent feature's `REQUIREMENTS.md`/`ARCHITECTURE.md`, and its `CHANGELOG.md` (Step 4 already loaded the first; extend the load set to include the peers).
3. If exactly one module-instance exists, proceed with no fan-out.
4. If 2+ module-instances exist, present the fan-out via AskUserQuestion:
   > "`{UC-XXXX}` exists in {N} modules: {list}. Which modules does this bug affect?"
   > Options: "All ({N})" / one option per module ("Only {module}") / "Custom — I'll list them" (via Other, user provides a subset).
5. Record the confirmed target set per UC-XXXX. Diagnosis, spec edits, and log entries in the next steps iterate over that set.

For FEAT IDs, expand the FEAT to its UCs (per Step 4), then resolve each UC's module-instances here.

## Step 6: Diagnose

For each module-instance in each target set, compare the description in `$ARGUMENTS` against that module-instance's spec. Pick exactly one diagnosis **per module-instance**:

| Diagnosis | When | Action in Step 7 |
|-----------|------|------------------|
| **Spec correct, code wrong** | The current spec already states the desired behavior; the bug is purely in the implementation. | No spec edit. Log entry only. |
| **Spec silent** | The spec doesn't address the buggy behavior at all (missing scenario, missing FR). | Add the missing scenario or FR to the relevant UC / feature. |
| **Spec wrong** | The spec explicitly states the broken behavior; the spec itself needs to be corrected. | Edit the offending scenario / FR. Increment UC `version`. |

**Diagnosis can differ per module-instance.** A bug may live entirely in one module's code while the peer module is correct; the spec may be right in one module and wrong in another. Do not force a single diagnosis across module-instances.

Surface the diagnosis(es) via AskUserQuestion, one prompt per affected module-instance:

> "Here is my diagnosis for `{UC-XXXX}` in `{module}`: {diagnosis} — {one-sentence justification}. {Proposed spec edit, or 'no spec edit'.} Proceed?"

Options: "Proceed" / "Edit" (user provides corrections via Other) / "Cancel".

## Step 7: Apply Spec Edits (if any)

For each module-instance where the diagnosis was **Spec silent** or **Spec wrong**, edit that module-instance's `UC-XXXX-{slug}.md` (the UC spec file, a sibling of REQUIREMENTS / USE-CASES / ARCHITECTURE for that module's feature folder). Increment frontmatter `version` on each edited file — versions are per-file. Update that module's ARCHITECTURE.md tables only if the edit changed the Component Inventory / API Surface / Code Map surface (per the architecture skill's additive rules).

When editing a **Spec wrong** scenario or FR, **replace** the incorrect text with the correct behavior — do not keep the wrong wording or annotate it with "was X, now Y". The changelog `reason` records the correction.

For module-instances where the diagnosis was **Spec correct, code wrong**, write nothing to disk in this step.

`/m:fix` does **not** produce plans, code, or tests. Task decomposition belongs to `/m:plan`.

## Step 8: Append Log Entries and Update UC Status

For every module-instance in each UC-XXXX target set (regardless of diagnosis — see the note below), use the `uc-log` shared skill to:

1. Append a new entry to that module-instance's `CHANGELOG.md` (under `TODO:`, prepended) with:
   - timestamp (UTC, `YYYYMMDDTHHMMSS`) — **same timestamp** for every module-instance in this fan-out
   - status: `pending`
   - command: `fix`
   - plan: `—`
   - modules: comma-separated list of module IDs in the target set (include whenever the UC has 2+ module-instances). Omit for single-module UCs.
   - reason: one paragraph capturing the bug **as it manifests in this module**. When the diagnosis was Spec correct/Code wrong, the reason names the misbehavior and states the expected behavior **positively** — describe what the code should do, so `/m:plan` writes a regression test that asserts the correct behavior (Principle 1.5), not a test that merely proves the bug is absent. When the diagnosis required a spec edit, the reason summarizes the spec edit too. Reasons may differ per module-instance when the diagnosis differs.
2. **Set that module-instance's frontmatter `status`** directly per the `status-rollup` skill: a previously-`implemented` UC becomes `dirty`; a `pending` or `dirty` UC stays as it is. Status is per-file.
3. **Recompute each affected parent feature's frontmatter `status`** by rolling up over its child UCs' frontmatter `status:` values (per module) — not the changelog. Apply the roll-up rule from the `status-rollup` skill and write the result to each affected `REQUIREMENTS.md`.

Append a log entry **even when the spec was untouched.** The point of the entry is to drive `/m:plan` to produce a regression test, regardless of whether the spec moved. If the user explicitly narrowed the target set in Step 5 to exclude a module-instance, that instance is not logged.

## Step 9: Report

Tell the user:

- The diagnosis per module-instance, grouped by UC-XXXX.
- The spec edits made (if any), per module-instance.
- The log entry appended per module-instance (note the `modules:` token when multi-module).
- The new status per module-instance and per affected feature.

End the report with the explicit hand-off:

> Next: run `/m:plan <UC-XXXX> [more IDs ...]` to produce the regression plan that `/m:build` will execute.
