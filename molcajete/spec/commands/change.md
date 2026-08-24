---
description: Intentionally change the behavior of an existing FEAT/UC. Composes a change request with before/after spec diffs and retired-scenario marks; the CLI applies and executes it.
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

Unlike `/m:fix` (where the spec might already be correct), `/m:change` **always** proposes a spec diff — the change request *is* a spec change. If the request only describes new behavior without a spec change, the user wanted `/m:fix` or `/m:spec` instead; suggest the right command and stop.

`/m:change` writes one artifact: `request.md` under `specs/changes/{change-id}/`, per the change-request skill. It never edits the spec tree, never writes a plan, and never writes production code or tests. It marks every retired scenario in the request so the CLI's planning session can populate `retires`. Hand-off to `molcajete build {change-id}` is mandatory.

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

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/spec-revision/SKILL.md` — the machinery `/m:change` shares with `/m:fix`: the prerequisite gate, spec loading, module-instance resolution, diff-drafting rules, request composition, and the report shape.
2. The skills listed in that skill's **Skills to Load** — including the host engineering principles.

## Step 3: Verify Prerequisites

Apply the `spec-revision` skill's **Prerequisites** gate. Refuse and stop if it fails.

## Step 4: Load the Referenced Specs

Follow the `spec-revision` skill's **Loading the Referenced Specs**.

## Step 5: Resolve UC Module-Instances

Before drafting anything, follow the `spec-revision` skill's **Resolving UC Module-Instances**. The fan-out question is:

> "`{UC-XXXX}` exists in {N} modules: {list}. Apply this change to which modules?"

"All ({N})" is the pre-selected option.

## Step 6: Draft the Revision

From the description in `$ARGUMENTS`, draft the revision **per module-instance** in each UC's target set, as before-and-after diffs per the `spec-revision` skill's **Drafting the Diffs**. The revision may:

- Change an existing scenario's Steps / Outcomes / Side Effects.
- Add new scenarios, or retire existing ones. A retired scenario is marked **retired** in the request, with what it used to assert.
- Add, modify, or retire FRs/NFRs at the feature level (when the change scope justifies it).
- Add a new UC under the feature (when the request implies a workflow that doesn't fit any existing UC), shown whole and marked new per the usecase-authoring skill. When the new UC applies to multiple modules, follow the shared-ID rule.
- Revise the module's interface elements or stores — those become INTERFACE.md and DATA.md diffs in the request's sections 3 and 4.

Retiring a scenario or an FR/NFR **never renumbers what remains**. The surviving IDs stay exactly as they were, gaps and all, and a new scenario always gets a freshly generated ID rather than a retired one. The same holds when "Apply to all" propagates a diff: the peer instance keeps its own IDs. See the `id-generation` skill's **Immutability** section.

For each affected module-instance, present a diff-style review. The diff is the brief, never the question text:

- Brief: name the UC and module, then show the proposed diff as a fenced diff or before/after
  block. Say what behavior changes as a result, and whether the same diff applies cleanly to the
  peer module-instances.
- Question: "Include this spec change for `{UC-XXXX}` in `{module}`?"
- Header: "Spec change"
- Options: "Proceed" / "Apply to all" / "Edit" / "Skip this module"

Corrections arrive via the built-in `Other`; `Chat about this` covers the "cancel and talk it through" path.

When the user chooses "Apply to all", propagate the same content diff to every peer instance, but keep module-scoped elements (actor names, module-specific side effects) intact — do not blindly overwrite peer-specific content.

If after review the user determines no spec change is needed **anywhere**, refuse:

> `/m:change` always changes specs. If no spec change is needed but the code should change, use `/m:fix`. Cancelling.

## Step 7: Compose the Request

Follow the `spec-revision` skill's **Composing the Request** over the confirmed diffs. Entry values the request records: `command: change`, and one shared reason paragraph capturing what changes and why — the apply step writes it into every affected module-instance's changelog.

## Step 8: Report

Report per the `spec-revision` skill's **Reporting**.

End the report with the explicit hand-off:

> Next: review `specs/changes/{change-id}/request.md` — the retired scenarios are marked, and the run deletes their tests and code. When ready, run `molcajete build {change-id}`. To abandon the change, delete the change directory; the spec tree never changed.
