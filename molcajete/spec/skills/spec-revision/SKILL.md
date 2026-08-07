---
name: spec-revision
description: >-
  Shared machinery for the revising spec commands (/m:fix, /m:change). Owns the
  skill load list, the prerequisite gate, loading the referenced specs, resolving a
  UC-XXXX to its module-instances with the multi-module fan-out, the spec-edit
  application rules, changelog and status writing, plan production, and the report
  shape. Both commands revise an existing FEAT/UC and hand a plan straight to
  /m:build.
---

# Spec Revision

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

The revising family — `/m:fix` and `/m:change` — both start from one or more existing `FEAT-XXXX` /
`UC-XXXX` IDs, resolve each UC to the module-instances that actually exist for it, edit the specs (always
for `/m:change`, conditionally for `/m:fix`), log the event, and **produce the plan themselves** in the
same invocation — there is no separate `/m:plan` step. This skill owns that machinery. Neither command
ever writes production code or tests; hand-off to `/m:build` is mandatory.

The calling command supplies what is genuinely its own: its argument examples and refusal string, its
decision step, its `command` token and `reason` policy, and its hand-off line.

## Skills to Load

Load these after this skill:

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/SKILL.md`
3. `${CLAUDE_PLUGIN_ROOT}/spec/skills/architecture/SKILL.md`
4. `${CLAUDE_PLUGIN_ROOT}/shared/skills/resolution-gate/SKILL.md` — the analysis sweep and the batched ask that run before any spec edit is applied.
5. `${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/SKILL.md`
6. `${CLAUDE_PLUGIN_ROOT}/shared/skills/uc-log/SKILL.md` — CHANGELOG mechanics only.
7. `${CLAUDE_PLUGIN_ROOT}/shared/skills/status-rollup/SKILL.md` — how to write UC and Feature status directly.
8. `${CLAUDE_PLUGIN_ROOT}/plan/skills/plan-authoring/SKILL.md` — the plan format and the **Producing a Plan** procedure used by **Producing the Plan** below.
9. **Engineering principles.** Read `.claude/rules/principles.md` from the host project (fall back to `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md` with a one-line warning if missing). The architecture pass in **Producing the Plan** applies these.

## Prerequisites

`specs/PROJECT.md`, `specs/MODULES.md`, and `specs/TECH-STACK.md` must exist. Each ID referenced in
`$ARGUMENTS` must resolve to an existing spec file. If any does not, refuse with a clear list of
unresolved IDs.

## Loading the Referenced Specs

For each FEAT/UC ID:

- Resolve the spec path. Read `specs/features/{module}/FEAT-XXXX-{slug}/REQUIREMENTS.md` (and `USE-CASES.md`) for FEAT IDs. Read `specs/features/{module}/FEAT-XXXX-{slug}/UC-XXXX-{slug}.md` for UC IDs.
- Read the feature's `ARCHITECTURE.md`.
- Read the UC's `CHANGELOG.md` (for context on prior changes).

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
5. Record the confirmed target set per UC-XXXX. All subsequent steps iterate over that set.

For FEAT IDs the same fan-out applies transitively: expand the FEAT to its UCs (per **Loading the
Referenced Specs**), then resolve each UC's module-instances here.

## Applying Spec Edits

For each module-instance the command confirmed, edit its `UC-XXXX-{slug}.md` (the UC spec file, a sibling
of REQUIREMENTS / USE-CASES / ARCHITECTURE for that module's feature folder). Increment frontmatter
`version` on each edited file — versions are per-file. Update that module's `ARCHITECTURE.md` per the
architecture skill's additive rules; the calling command states how far that update reaches.

**Edits replace, never annotate.** Replace the incorrect or superseded text with the behavior that should
hold now — do not keep the old wording or annotate it with "was X, now Y" / "previously X". The changelog
entry's `reason` is the only record of what changed and why.

This replace-never-annotate rule governs the **spec files only**. It never reaches the CHANGELOG, which is
append-only — see below.

**Replace the text, never the ID.** Every `FEAT-`, `UC-`, `SC-`, `FR-`, `NFR-`, `US-`, and `ADR-` ID already in
the file survives the edit character-for-character. Rewriting a scenario's Steps does not change its `SC-XXXX`;
retiring one scenario does not renumber the others; propagating an edit to a peer module-instance never carries
a peer's IDs across. Only a genuinely new entity gets a generated ID. See the `id-generation` skill's
**Immutability** section, including its post-edit self-check.

## Logging and Status

For each module-instance in the set the calling command names, append the changelog entry per the `uc-log`
skill, then write that instance's and its parent feature's status per the `status-rollup` skill. A peer
instance not touched in this run keeps its prior status.

"Append" here means the `uc-log` skill's mutation 1: **insert a new line at the top of `TODO:`**. The
CHANGELOG is append-only. Never edit, replace, re-timestamp, or delete an existing entry — not even when
this run's `reason` reads much like an entry already in the file. A repeated run is two entries, and that
repetition is history the log is meant to keep.

Entry values shared by both commands:

- plan: `—`
- timestamp: the **same** UTC timestamp for every module-instance in this fan-out

The calling command supplies the `command` token, the `reason` policy, the `modules` token rule, and which
module-instances get an entry.

## Producing the Plan

Run the **Producing a Plan** procedure from the `plan-authoring` skill over the entries just logged. Both
commands always produce **`mode: default`** (implement tasks).

The procedure runs the architecture pass, presents the task breakdown via AskUserQuestion (the review gate
— a wrong reading of the request is caught here before any code is built), writes
`specs/plans/<plan-id>.md`, and flips the logged entries from `pending` to `dirty` with the plan-id
stamped.

## Reporting

Tell the user:

- The spec edits made per module-instance (one or two lines each), grouped by UC-XXXX — or that none were needed.
- The log entry appended per module-instance (note the `modules:` token when multi-module).
- The new status per module-instance and per affected feature.
- Any module-instances that were resolved but skipped by the user, when there were any.
- The plan written: `specs/plans/<plan-id>.md`, and its task(s).

End the report with the command's explicit hand-off line, which always names the plan file and the
`/m:build <plan-id>` invocation — which runs every unfinished task in the plan — plus the
`/m:build <plan-id> T-001 [more ...]` form for a subset.
