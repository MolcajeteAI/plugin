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
  - AskUserQuestion
---

# Change Command

`/m:change` records an intentional change to an existing UC: **"we want this use case to behave differently going forward."**

Unlike `/m:fix` (where the spec might already be correct), `/m:change` **always** edits the spec — the change request *is* a spec edit. If the request only describes new behavior without a spec change, the user wanted `/m:fix` or `/m:spec` instead; suggest the right command and stop.

`/m:change` then **produces the change plan itself** — after editing the specs and marking the affected UCs `dirty`, it runs the plan-authoring skill's "Producing a Plan" procedure in the same invocation, so there is no separate `/m:plan` step. It never writes production code or tests. Hand-off to `/m:build` is mandatory. The plan is written to disk and confirmed via AskUserQuestion before finalizing, so a wrong interpretation is caught and editable before any code is built.

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

**Writing style:** every document you write and every message you print uses Simplified Technical English. Every one carries only what its reader needs. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/shared/skills/output-economy/SKILL.md` before writing.

## Step 1: Parse Arguments

`$ARGUMENTS` must begin with one or more `FEAT-XXXX` or `UC-XXXX` IDs followed by the free-form description. Examples:

- `/m:change UC-0KTg "registration now also requires email verification before login"`
- `/m:change UC-0KTg UC-0L2x "session lifetime drops from 30 days to 7 days"`
- `/m:change FEAT-0Fy0 "the entire feature moves from sync HTTP to event-driven processing"`

If `$ARGUMENTS` does **not** start with a valid ID, refuse:

> `/m:change` requires at least one `FEAT-XXXX` or `UC-XXXX` ID as the first argument. To create a brand-new feature or UC, use `/m:spec`.

Stop without writing anything.

## Step 2: Load Skills

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/spec-revision/SKILL.md` — the machinery `/m:change` shares with `/m:fix`: the prerequisite gate, spec loading, module-instance resolution, spec-edit rules, logging and status, plan production, and the report shape.
2. The skills listed in that skill's **Skills to Load** — including the host engineering principles.

## Step 3: Verify Prerequisites

Apply the `spec-revision` skill's **Prerequisites** gate. Refuse and stop if it fails.

## Step 4: Load the Referenced Specs

Follow the `spec-revision` skill's **Loading the Referenced Specs**.

## Step 5: Resolve UC Module-Instances

Before proposing edits, follow the `spec-revision` skill's **Resolving UC Module-Instances**. The fan-out question is:

> "`{UC-XXXX}` exists in {N} modules: {list}. Apply this change to which modules?"

"All ({N})" is the pre-selected option.

## Step 6: Draft the Spec Edit

From the description in `$ARGUMENTS`, draft the spec edit **per module-instance** in each UC's target set. The edit may:

- Change an existing scenario's Steps / Outcomes / Side Effects.
- Add or remove scenarios.
- Add, modify, or retire FRs/NFRs at the feature level (when the change scope justifies it).
- Add a new UC under the feature (when the request implies a workflow that doesn't fit any existing UC). Use the usecase-authoring skill's **Write Files** procedure to create the new UC spec file (`UC-XXXX-{slug}.md`), support folder, and `CHANGELOG.md`. When the new UC applies to multiple modules, follow the shared-ID rule.

Removing a scenario or retiring an FR/NFR **never renumbers what remains**. The surviving IDs stay exactly as they were, gaps and all, and a new scenario always gets a freshly generated ID rather than a retired one. The same holds when "Apply to all" propagates an edit: the peer instance keeps its own IDs. See the `id-generation` skill's **Immutability** section.

For each affected module-instance, present a diff-style review. The diff is the brief, never the question text:

- Brief: name the UC and module, then show the proposed spec change as a fenced diff or before/after
  block. Say what behavior changes as a result, and whether the same edit applies cleanly to the
  peer module-instances.
- Question: "Apply this spec change to `{UC-XXXX}` in `{module}`?"
- Header: "Spec change"
- Options: "Proceed" / "Apply to all" / "Edit" / "Skip this module"

Corrections arrive via the built-in `Other`; `Chat about this` covers the "cancel and talk it through" path.

When the user chooses "Apply to all", propagate the same content edit to every peer instance, but keep module-scoped elements (actor names, module-specific side effects) intact — do not blindly overwrite peer-specific content.

If after review the user determines no spec edit is needed **anywhere**, refuse:

> `/m:change` always edits specs. If no spec change is needed but the code should change, use `/m:fix`. Cancelling.

## Step 7: Apply Spec Edits

For each module-instance the user confirmed, follow the `spec-revision` skill's **Applying Spec Edits** (including its replace-never-annotate rule). ARCHITECTURE.md reach for a change: update that module's `REQUIREMENTS.md` **and** `ARCHITECTURE.md` — Component Inventory / API Surface / Code Map rows for any newly-implied files or endpoints in that module.

## Step 8: Append Log Entries and Update UC Status

Follow the `spec-revision` skill's **Logging and Status**, over **every module-instance affected in Step 7**.

Per-command entry values:

- command: `change`
- modules: every module in the fan-out target set, **even if only one was actually edited** — the token records the scope of the event.
- reason: one paragraph capturing what changed in the spec and why. **Same reason text** for every module-instance in this fan-out (e.g., "added email-verification gate before login per security review 2026-06-15").

## Step 9: Produce the Plan

Follow the `spec-revision` skill's **Producing the Plan** over the entries logged in Step 8.

Direct the plan's **summary and context paragraph to be the consolidated change record**: state plainly what changed, in which UCs/features (naming each), and the approach — this is the single narrative the change produces, spanning every affected UC in one document (the per-UC `CHANGELOG.md` stays as the terse marker log). Because the UC specs already describe the new behavior, the tasks reconcile the code to match: `/m:build` will delete tests/code for retired scenarios and add tests for the new behavior (Principle 1.5).

## Step 10: Report

Report per the `spec-revision` skill's **Reporting**.

End the report with the explicit hand-off:

> Next: review `specs/plans/<plan-id>.md`. When ready, run `/m:build <plan-id>` to execute the change. That runs every unfinished task in the plan. Add task IDs — `/m:build <plan-id> T-001 [more ...]` — to run a subset.
