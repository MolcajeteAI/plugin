---
description: Record a bug ("spec says X, code does Y") against one or more existing FEAT/UC IDs. Composes a change request whose spec diffs exist only when the spec was silent or wrong; the CLI applies and executes it.
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

`/m:fix` records a bug against an existing UC: **"the use case is supposed to do X, but the code does Y."** The bug may or may not require a spec diff — the Step 6 diagnosis decides.

`/m:fix` writes one artifact: `request.md` under `specs/changes/{change-id}/`, per the change-request skill. It never edits the spec tree, never writes a plan, and never writes production code or tests. Hand-off to `molcajete build {change-id}` is mandatory. A **Spec correct, code wrong** diagnosis still produces a request — one whose spec section records the expected behavior with no diff, so the run writes the regression test and the code change.

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

Every affected module-instance must end up in the request: features expand to all their UCs (after Step 6 you must list each affected UC explicitly), and each multi-module UC expands to its module-instances in Step 5.

## Step 2: Load Skills

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/spec-revision/SKILL.md` — the machinery `/m:fix` shares with `/m:change`: the prerequisite gate, spec loading, module-instance resolution, the diagnosis, diff-drafting rules, request composition, and the report shape.
2. The skills listed in that skill's **Skills to Load** — including the host engineering principles.

## Step 3: Verify Prerequisites

Apply the `spec-revision` skill's **Prerequisites** gate. Refuse and stop if it fails.

## Step 4: Load the Referenced Specs

Follow the `spec-revision` skill's **Loading the Referenced Specs**.

## Step 5: Resolve UC Module-Instances

Before diagnosing, follow the `spec-revision` skill's **Resolving UC Module-Instances**. The fan-out question is:

> "`{UC-XXXX}` exists in {N} modules: {list}. Which modules does this bug affect?"

Diagnosis and drafting in the next steps iterate over the confirmed target set.

## Step 6: Diagnose

For each module-instance in each target set, compare the description in `$ARGUMENTS` against that module-instance's spec. Pick exactly one diagnosis **per module-instance**, per the `spec-revision` skill's **Diagnosing a Defect** table — it defines the three diagnoses, the spec diff each one puts in the request, the request `command` token each one records, and the rule that the diagnosis may differ per module-instance.

Surface the diagnosis(es) one prompt per affected module-instance. The diagnosis is the brief:

- Brief: name the UC and module, state the diagnosis with a one-sentence justification, and show
  the proposed spec diff as a fenced diff — or say plainly that no spec diff is needed and why.
- Question: "Is this diagnosis for `{UC-XXXX}` in `{module}` right?"
- Header: "Diagnosis"
- Options: "Proceed" / "Edit" / "Cancel"

## Step 7: Compose the Request

Follow the `spec-revision` skill's **Composing the Request** over the confirmed diagnoses.

Only module-instances diagnosed **Spec silent** or **Spec wrong** carry a spec diff, drafted per **Drafting the Diffs**. A **Spec correct, code wrong** instance carries no diff — its request entry states the expected behavior **positively**: describe what the code should do, so the run writes a regression test that asserts the correct behavior (Principle 1.5), not a test that merely proves the bug is absent. Put the observed misbehavior and any exact reproduction values into the entry's `### Examples` as `E-NNN` items — a reproduction is test material.

Entry values the request records: `command: fix`, and one reason paragraph per module-instance capturing the bug **as it manifests in that module**. Reasons may differ per module-instance when the diagnosis differs. Module-instances the user excluded in Step 5 do not appear.

## Step 8: Report

Report per the `spec-revision` skill's **Reporting**, with one addition: lead with **the diagnosis per module-instance, grouped by UC-XXXX**.

End the report with the explicit hand-off:

> Next: review `specs/changes/{change-id}/request.md`. When ready, run `molcajete build {change-id}` to execute the regression fix. To abandon it, delete the change directory; the spec tree never changed.
