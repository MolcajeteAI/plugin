---
description: Intentionally change the behavior of an existing FEAT/UC. Always updates specs first, marks the affected UCs dirty, then produces the change plan directly for /m:build.
model: claude-opus-5
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

`/m:change` then **produces the change plan itself** — after editing the specs and marking the affected UCs `dirty`, it runs the plan-authoring skill's "Producing a Plan" procedure in the same invocation, so there is no separate `/m:plan` step. It never writes production code or tests. Hand-off to `/m:build` is mandatory. The plan is written to disk and confirmed via AskUserQuestion before finalizing, so a wrong interpretation is caught and editable before any code is built.

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
5. `${CLAUDE_PLUGIN_ROOT}/shared/skills/uc-log/SKILL.md` — CHANGELOG mechanics only.
6. `${CLAUDE_PLUGIN_ROOT}/shared/skills/status-rollup/SKILL.md` — how to write UC and Feature status directly.
7. `${CLAUDE_PLUGIN_ROOT}/plan/skills/plan-authoring/SKILL.md` — the plan format and the **Producing a Plan** procedure used in Step 9.
8. **Engineering principles.** Read `.claude/rules/principles.md` from the host project (fall back to `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md` with a one-line warning if missing). The architecture pass in Step 9 applies these.

## Step 3: Verify Prerequisites

`specs/PROJECT.md`, `specs/MODULES.md`, and `specs/TECH-STACK.md` must exist. Each ID referenced in `$ARGUMENTS` must resolve to an existing spec file. If any does not, refuse with a clear list of unresolved IDs.

## Step 4: Load the Referenced Specs

For each FEAT/UC ID:

- Resolve the spec path. Read `specs/features/{module}/FEAT-XXXX-{slug}/REQUIREMENTS.md` (and `USE-CASES.md`) for FEAT IDs. Read `specs/features/{module}/FEAT-XXXX-{slug}/UC-XXXX-{slug}.md` for UC IDs.
- Read the feature's `ARCHITECTURE.md`.
- Read the UC's `CHANGELOG.md` (for context on prior changes).

## Step 5: Resolve UC Module-Instances

Multi-module UCs share one `UC-XXXX` ID across every module the capability appears in (see `spec/skills/usecase-authoring/SKILL.md` → Module-Scoped Use Cases). Before proposing edits, resolve each given `UC-XXXX` ID to the full set of module-instances that exist for it.

For each `UC-XXXX` ID:

1. Glob `specs/features/*/FEAT-*/UC-XXXX-*.md`. Every match is a module-instance of that UC. The module is the segment immediately under `specs/features/`.
2. Read every module-instance's spec file, the parent feature's `REQUIREMENTS.md`/`ARCHITECTURE.md` in that module folder, and each module-instance's `CHANGELOG.md`. (Step 4 already loaded the first module-instance encountered; extend the load set to include the peers.)
3. If exactly one module-instance exists, proceed with no fan-out.
4. If 2+ module-instances exist, present the fan-out via AskUserQuestion:
   > "`{UC-XXXX}` exists in {N} modules: {list}. Apply this change to which modules?"
   > Options: "All ({N})" (default) / one option per module ("Only {module}") / "Custom — I'll list them" (via Other, user provides a subset).
5. Record the confirmed target set per UC-XXXX. All subsequent steps iterate over that set.

For FEAT IDs, the same fan-out applies transitively: expand the FEAT to its UCs (per Step 4), then resolve each UC's module-instances.

## Step 6: Draft the Spec Edit

From the description in `$ARGUMENTS`, draft the spec edit **per module-instance** in each UC's target set. The edit may:

- Change an existing scenario's Steps / Outcomes / Side Effects.
- Add or remove scenarios.
- Add, modify, or retire FRs/NFRs at the feature level (when the change scope justifies it).
- Add a new UC under the feature (when the request implies a workflow that doesn't fit any existing UC). Use the usecase-authoring skill's **Write Files** procedure to create the new UC spec file (`UC-XXXX-{slug}.md`), support folder, and `CHANGELOG.md`. When the new UC applies to multiple modules, follow the shared-ID rule.

For each affected module-instance, present a diff-style review via AskUserQuestion:

> "Here is the proposed spec change for `{UC-XXXX}` in `{module}`: {diff or before/after snippets}. Proceed?"

Options: "Proceed" / "Apply this same edit to every module-instance" / "Edit" (user provides corrections via Other) / "Skip this module" / "Cancel".

When the user chooses "Apply this same edit to every module-instance", propagate the same content edit to every peer instance, but keep module-scoped elements (actor names, module-specific side effects) intact — do not blindly overwrite peer-specific content.

If after review the user determines no spec edit is needed **anywhere**, refuse:

> `/m:change` always edits specs. If no spec change is needed but the code should change, use `/m:fix`. Cancelling.

## Step 7: Apply Spec Edits

For each module-instance the user confirmed, edit its `UC-XXXX-{slug}.md` (the UC spec file, a sibling of REQUIREMENTS / USE-CASES / ARCHITECTURE for that module's feature folder). Increment frontmatter `version` on each edited file — versions are per-file. Update that module's `REQUIREMENTS.md` and `ARCHITECTURE.md` per the architecture skill's additive rules — Component Inventory / API Surface / Code Map rows for any newly-implied files or endpoints in that module.

The spec edit **replaces** the old text — it describes only the new behavior. Do not retain the previous wording or annotate the spec with "previously X" / "changed from Y". The changelog entry's `reason` (Step 8) is the only record of what changed and why.

Module-instances the user skipped are left untouched.

`/m:change` never writes production code or tests. It does, however, produce the change plan itself in Step 9.

## Step 8: Append Log Entries and Update UC Status

For every module-instance affected in Step 7, use the `uc-log` shared skill to:

1. Append a new entry to that module-instance's `CHANGELOG.md` (under `TODO:`, prepended) with:
   - timestamp (UTC, `YYYYMMDDTHHMMSS`) — **same timestamp** for every module-instance in this fan-out
   - status: `pending`
   - command: `change`
   - plan: `—`
   - modules: comma-separated list of module IDs the fan-out targeted (include this token whenever the UC has 2+ module-instances, even if only one was actually edited — the token records the scope of the event). Omit for single-module UCs.
   - reason: one paragraph capturing what changed in the spec and why. **Same reason text** for every module-instance in this fan-out. (e.g., "added email-verification gate before login per security review 2026-06-15")
2. **Set that module-instance's frontmatter `status`** directly per the `status-rollup` skill: a previously-`implemented` UC becomes `dirty`; a `pending` or `dirty` UC stays as it is. Status is written per module-instance file — a peer instance not edited in this run keeps its prior status.
3. **Recompute each affected parent feature's frontmatter `status`** by rolling up over its child UCs' frontmatter `status:` values (per module) — not the changelog. Apply the roll-up rule from the `status-rollup` skill and write the result to each affected `REQUIREMENTS.md`.

## Step 9: Produce the Plan

Run the **Producing a Plan** procedure from the `plan-authoring` skill (loaded in Step 2) over the entries just logged in Step 8. A change is always **`mode: default`** (implement tasks).

Direct the plan's **summary and context paragraph to be the consolidated change record**: state plainly what changed, in which UCs/features (naming each), and the approach — this is the single narrative the change produces, spanning every affected UC in one document (the per-UC `CHANGELOG.md` stays as the terse marker log). Because the UC specs already describe the new behavior, the tasks reconcile the code to match: `/m:build` will delete tests/code for retired scenarios and add tests for the new behavior (Principle 1.5).

The procedure runs the architecture pass, presents the task breakdown via AskUserQuestion (the review gate — a wrong interpretation is caught here before any code is built), writes `specs/plans/<plan-id>.md`, and flips the Step 8 entries from `pending` to `dirty` with the plan-id stamped. The context it needs is already in memory (loaded skills, the referenced specs and `ARCHITECTURE.md`, the pending entries).

## Step 10: Report

Tell the user:

- The spec edits made per module-instance (one or two lines each), grouped by UC-XXXX.
- The log entry appended per module-instance (note the `modules:` token when multi-module).
- The new status per module-instance and per affected feature.
- Any module-instances that were resolved but skipped by the user.
- The plan written: `specs/plans/<plan-id>.md`, and its tasks.

End the report with the explicit hand-off:

> Next: review `specs/plans/<plan-id>.md`. When ready, run `/m:build <plan-id> T-001 [more task IDs ...]` to execute the change.
