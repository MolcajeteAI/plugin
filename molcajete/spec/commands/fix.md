---
description: Record a bug ("spec says X, code does Y") against one or more existing FEAT/UC IDs. Updates specs only when the spec was wrong, then produces the regression plan directly for /m:build.
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

# Fix Command

`/m:fix` records a bug against an existing UC: **"the use case is supposed to do X, but the code does Y."** The bug may or may not require a spec edit — the Step 6 diagnosis decides.

`/m:fix` then **produces the regression plan itself** — it logs the entry and runs the plan-authoring skill's "Producing a Plan" procedure in the same invocation, so there is no separate `/m:plan` step. It never writes production code or tests. Hand-off to `/m:build` is mandatory. The plan is written to disk and confirmed via AskUserQuestion before finalizing, so a wrong diagnosis is caught and editable before any code is built.

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

**Writing style:** every document you write and every message you print uses Simplified Technical English. Every one carries only what its reader needs. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/shared/skills/output-economy/SKILL.md` before writing.

## Step 1: Parse Arguments

`$ARGUMENTS` must begin with one or more `FEAT-XXXX` or `UC-XXXX` IDs followed by the free-form description. Examples:

- `/m:fix UC-0KTg "duplicate email should return 409, currently returns 500"`
- `/m:fix UC-0KTg UC-0L2x "session cleanup leaves orphan tokens when refresh fails"`
- `/m:fix FEAT-0Fy0 "rate-limit headers are missing on 429 responses across the feature"`

If `$ARGUMENTS` does **not** start with a valid ID, refuse:

> `/m:fix` requires at least one `FEAT-XXXX` or `UC-XXXX` ID as the first argument. To extract specs from new code, use `/m:cover`. To create a new feature or UC, use `/m:spec`.

Stop without writing anything.

Every affected module-instance must end up with a log entry in Step 8: features expand to all their UCs (after Step 6 you must list each affected UC explicitly), and each multi-module UC expands to its module-instances in Step 5.

## Step 2: Load Skills

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/spec-revision/SKILL.md` — the machinery `/m:fix` shares with `/m:change`: the prerequisite gate, spec loading, module-instance resolution, spec-edit rules, logging and status, plan production, and the report shape.
2. The skills listed in that skill's **Skills to Load** — including the host engineering principles.

## Step 3: Verify Prerequisites

Apply the `spec-revision` skill's **Prerequisites** gate. Refuse and stop if it fails.

## Step 4: Load the Referenced Specs

Follow the `spec-revision` skill's **Loading the Referenced Specs**.

## Step 5: Resolve UC Module-Instances

Before diagnosing, follow the `spec-revision` skill's **Resolving UC Module-Instances**. The fan-out question is:

> "`{UC-XXXX}` exists in {N} modules: {list}. Which modules does this bug affect?"

Diagnosis, spec edits, and log entries in the next steps iterate over the confirmed target set.

## Step 6: Diagnose

For each module-instance in each target set, compare the description in `$ARGUMENTS` against that module-instance's spec. Pick exactly one diagnosis **per module-instance**:

| Diagnosis | When | Action in Step 7 |
|-----------|------|------------------|
| **Spec correct, code wrong** | The current spec already states the desired behavior; the bug is purely in the implementation. | No spec edit. Log entry only. |
| **Spec silent** | The spec doesn't address the buggy behavior at all (missing scenario, missing FR). | Add the missing scenario or FR to the relevant UC / feature. |
| **Spec wrong** | The spec explicitly states the broken behavior; the spec itself needs to be corrected. | Edit the offending scenario / FR. Increment UC `version`. |

**Diagnosis can differ per module-instance.** A bug may live entirely in one module's code while the peer module is correct. Do not force a single diagnosis across module-instances.

Surface the diagnosis(es) one prompt per affected module-instance. The diagnosis is the brief:

- Brief: name the UC and module, state the diagnosis with a one-sentence justification, and show
  the proposed spec edit as a fenced diff — or say plainly that no spec edit is needed and why.
- Question: "Is this diagnosis for `{UC-XXXX}` in `{module}` right?"
- Header: "Diagnosis"
- Options: "Proceed" / "Edit" / "Cancel"

## Step 7: Apply Spec Edits (if any)

Only module-instances diagnosed **Spec silent** or **Spec wrong** are edited; a **Spec correct, code wrong** instance gets no spec edit at all. For the ones that are edited, follow the `spec-revision` skill's **Applying Spec Edits** (including its replace-never-annotate rule). ARCHITECTURE.md reach for a fix: update that module's tables **only if** the edit changed the Component Inventory / API Surface / Code Map surface.

## Step 8: Append Log Entries and Update UC Status

Follow the `spec-revision` skill's **Logging and Status**, over **every module-instance in each UC-XXXX target set** — not just the edited ones.

Per-command entry values:

- command: `fix`
- reason: one paragraph capturing the bug **as it manifests in this module**. When the diagnosis was Spec correct/Code wrong, the reason names the misbehavior and states the expected behavior **positively** — describe what the code should do, so the plan writes a regression test that asserts the correct behavior (Principle 1.5), not a test that merely proves the bug is absent. When the diagnosis required a spec edit, the reason summarizes the spec edit too. Reasons may differ per module-instance when the diagnosis differs.

Append a log entry **even when the spec was untouched** — the entry drives the regression plan regardless of whether the spec moved. Module-instances the user excluded in Step 5 are not logged.

## Step 9: Produce the Plan

Follow the `spec-revision` skill's **Producing the Plan** over the entries logged in Step 8. A fix's tasks are a regression test that starts RED, then the code change that turns it GREEN.

For a purely local, single-scenario regression the plan is typically one task; do not manufacture extra tasks.

## Step 10: Report

Report per the `spec-revision` skill's **Reporting**, with one addition: lead with **the diagnosis per module-instance, grouped by UC-XXXX**.

End the report with the explicit hand-off:

> Next: review `specs/plans/<plan-id>.md`. When ready, run `/m:build <plan-id>` to execute the regression fix. That runs every unfinished task in the plan. Add task IDs — `/m:build <plan-id> T-001 [more ...]` — to run a subset.
