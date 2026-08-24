---
name: spec-revision
description: >-
  Shared machinery for the revising spec commands (/m:fix, /m:change). Owns the
  skill load list, the prerequisite gate, loading the referenced specs, resolving a
  UC-XXXX to its module-instances with the multi-module fan-out, the defect
  diagnosis, the diff-drafting rules, and the report shape. Both commands revise
  an existing FEAT/UC by composing a change request — they never edit the spec
  tree, and the CLI applies the request on the run branch.
---

# Spec Revision

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

The revising family — `/m:fix` and `/m:change` — both start from one or more existing `FEAT-XXXX` /
`UC-XXXX` IDs, resolve each UC to the module-instances that actually exist for it, draft the spec revision
(always for `/m:change`, conditionally for `/m:fix`), and **compose a change request** — `request.md`
under `specs/changes/{change-id}/`, per the change-request skill. This skill owns that machinery. Neither
command edits the spec tree, writes a plan, or writes production code or tests; the base branch's specs
stay untouched until `molcajete build {change-id}` applies the request on the run branch.

The calling command supplies what is genuinely its own: its argument examples and refusal string, its
decision step, its `command` token, and its hand-off line.

## Skills to Load

Load these after this skill:

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/SKILL.md`
3. `${CLAUDE_PLUGIN_ROOT}/spec/skills/architecture/SKILL.md`
4. `${CLAUDE_PLUGIN_ROOT}/spec/skills/module-authoring/SKILL.md` — the charters and the two authoring questions; the INTERFACE.md and DATA.md formats the request's sections 3 and 4 use.
5. `${CLAUDE_PLUGIN_ROOT}/spec/skills/change-request/SKILL.md` — the request.md format and its apply rules.
6. `${CLAUDE_PLUGIN_ROOT}/shared/skills/resolution-gate/SKILL.md` — the analysis sweep and the batched ask that run before the request is written.
7. `${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/SKILL.md`
8. **Engineering principles.** Read `.claude/rules/principles.md` from the host project (fall back to `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md` with a one-line warning if missing).

## Prerequisites

`specs/PROJECT.md`, `specs/MODULES.md`, and `specs/TECH-STACK.md` must exist. Each ID referenced in
`$ARGUMENTS` must resolve to an existing spec file. If any does not, refuse with a clear list of
unresolved IDs.

## Loading the Referenced Specs

For each FEAT/UC ID:

- Resolve the spec path. Read `specs/features/{module}/FEAT-XXXX-{slug}/REQUIREMENTS.md` (and `USE-CASES.md`) for FEAT IDs. Read `specs/features/{module}/FEAT-XXXX-{slug}/UC-XXXX-{slug}.md` for UC IDs.
- Read the feature's `ARCHITECTURE.md`.
- Read the UC's `CHANGELOG.md` (for context on prior changes).
- Read the owning module's `specs/modules/{module}/INTERFACE.md` and `DATA.md` — the request's interface and data sections revise them.

## Resolving UC Module-Instances

Before the command drafts anything, resolve each given `UC-XXXX` ID to the full set of module-instances
that exist for it (see `spec/skills/usecase-authoring/SKILL.md` → Module-Scoped Use Cases).

For each `UC-XXXX` ID:

1. Glob `specs/features/*/FEAT-*/UC-XXXX-*.md`. Every match is a module-instance of that UC. The module is the segment immediately under `specs/features/`.
2. Read every module-instance's spec file, its parent feature's `REQUIREMENTS.md` / `ARCHITECTURE.md` in that module folder, and that instance's `CHANGELOG.md`.
3. If exactly one module-instance exists, proceed with no fan-out.
4. If 2+ module-instances exist, present the fan-out. The calling command supplies the question sentence and says which option is pre-selected.
   - Brief: list the module-instances as a Markdown table (module, file path, current status) so the
     user can see what each one holds before choosing a fan-out.
   - Header: "Modules"
   - Options: "All ({N})" / one option per module ("Only {module}")

   Do not add a "Custom — I'll list them" option; the built-in `Other` already collects a subset.
5. Record the confirmed target set per UC-XXXX. All subsequent steps iterate over that set. The request's per-module sections are built from it.

For FEAT IDs the same fan-out applies transitively: expand the FEAT to its UCs (per **Loading the
Referenced Specs**), then resolve each UC's module-instances here.

## Diagnosing a Defect

Every defect resolves to exactly one of three diagnoses, and the diagnosis decides both whether the
request carries a spec diff and which `command` token the request records. Run this before any drafting.

| Diagnosis | When | Spec diff in the request | Request command |
|-----------|------|--------------------------|-----------------|
| **Spec correct, code wrong** | The current spec already states the desired behavior; the defect is purely in the implementation. | none | `fix` |
| **Spec silent** | The spec does not address the behavior at all — a missing scenario or a missing FR. | Add the missing scenario or FR, shown whole and marked new. | `fix` |
| **Spec wrong** | The spec explicitly states the incorrect behavior; the spec itself needs correcting. | The offending scenario / FR as before and after, with the `version` increment noted. | `change` |

**The diagnosis can differ per module-instance.** A defect may live entirely in one module's code while the
peer module is correct. Never force a single diagnosis across module-instances.

**Spec silent produces a `fix`, not new-behavior work.** The behavior already ships; writing the scenario down
records what was always intended, and the run then makes the code match it.

This table has three callers. `/m:fix` runs it against the user's bug description. `/m:change` does not run
it — a change request is a spec edit by definition, so its diagnosis is always **Spec wrong**. The CLI runs
it mid-execution against a defect the run discovered, routing the outcome through its decide-and-record rule.

## Drafting the Diffs

For each module-instance the command confirmed, draft the revision as the request's before-and-after
diffs — the spec file itself is never touched. Two rules from the in-place era survive as diff rules:

**The After text replaces, never annotates.** Write the behavior that should hold now — do not keep the
old wording inside the After, and do not annotate it with "was X, now Y" / "previously X". The request's
diff already shows the Before, and the changelog entry the apply step writes is the record of what changed.

**Replace the text, never the ID.** Every `FEAT-`, `UC-`, `SC-`, `FR-`, `NFR-`, `US-`, and `ADR-` ID in the
Before survives into the After character-for-character, anchors included. Rewriting a scenario's Steps does
not change its `SC-XXXX`; retiring one scenario does not renumber the others; propagating an edit to a peer
module-instance never carries a peer's IDs across. Only a genuinely new entity gets a generated ID. See the
`id-generation` skill's **Immutability** section.

A revision that changes the module's public surface or its stores also drafts the matching INTERFACE.md and
DATA.md diffs (the request's sections 3 and 4). When the revision needs a relationship not in the module's
`Depends on`, or a responsibility no charter holds, ask the module-authoring skill's two questions — the
charter amendment goes into the request's section 6.

## Composing the Request

Compose `request.md` per the change-request skill: create the change directory
(`date -u +%Y%m%dT%H%M%S` for the timestamp, short kebab-case slug), fill the template's six sections
from the confirmed diffs, close every change entry with its `### Additional Notes` and `### Examples`
subsections, and seed examples the user's description already pins (exact values) as `E-NNN` entries.

`/m:change` marks every retired scenario **retired** in section 2 — stating what it used to assert — so
the planning session can populate the `retires` list of the tasks that delete its tests and code.

Run the `resolution-gate` procedure before writing. The request file is the only file the command writes.

## Reporting

This is the shape. The heading states the outcome, one table covers every module-instance touched, and the
hand-off follows.

````markdown
## Change request ready — {change-id}

| Module | What changes | Diagnosis |
|---|---|---|
| `auth` | The above-ceiling outcome (SC-3Z2P) now allows a score above 100 | spec wrong |
| `console` | The display-range scenario (SC-3Z2T) widens | spec wrong |

Review `specs/changes/{change-id}/request.md`. Edit the **Additional Notes** and **Examples**
subsections freely — the run reads them at trigger time.
````

**One table row per module-instance.** The `What changes` cell holds one clause, not a paragraph. Write
`no spec diff — code-only fix` in that cell when the diagnosis was **Spec correct, code wrong** — that is
a result, not an omission.

**A skipped instance still gets a row**, with `skipped` in `What changes`. Print no section for skipped
instances when the user skipped none.

When the run touched several `UC-XXXX` IDs, print one heading and one table per UC.

End the report with the command's explicit hand-off line, which always names the change directory and the
`molcajete build {change-id}` invocation, and states that deleting the change directory abandons the
request with the spec tree untouched.
