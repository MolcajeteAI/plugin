---
name: status-rollup
description: >-
  Status as first-class state on use cases and features. Defines the two-value
  enum (pending | implemented), per-level semantics, the Feature roll-up rule
  over its UCs, and which writer owns which level. Task-level state lives in
  the done field of each task in plan.json; UC and Feature status live on the
  artifact frontmatter and are the source of truth — the CHANGELOG is for
  context and markers, not state.
---

# Status Roll-up

Every spec artifact carries a `status` field in its frontmatter. This is the **source of truth** for whether the artifact is implemented. Open any FEAT or UC spec file and the frontmatter answers "is this implemented?" without reading any other file.

The two-value enum is the same at every level: `pending`, `implemented`. The semantics are scoped to the level.

**The `dirty` status is removed.** It marked a spec that ran ahead of its implementation, and that state can no longer occur: spec edits land on the run branch together with the code and the tests that satisfy them, in the same commits, and the base branch receives them only when the finished run merges. The base branch's spec tree always describes shipped code.

**The UC is the leaf.** The finest-grained unit of build work is a **task** — an entry in the change's `plan.json` under `specs/changes/<change-id>/`. Task state is the task's `done` field (`false` pending, `true` done), not a frontmatter `status`. The CLI reads task state to write UC status directly, and Feature status rolls up from its UCs.

## The two values

- **`pending`** — the artifact is specced but not fully built. (At the UC level: not every covering task is `done` yet. At the feature level: not every UC is `implemented` yet.)
- **`implemented`** — the artifact is complete. Tests pass, the verify hook's gates passed, the final verification passed, and every descendant is also `implemented`.

The legacy values `deprecated` and `dirty` are preserved when already present in an artifact's frontmatter on the base branch; this skill does not manage those transitions. The first run that rebuilds such an artifact rewrites its status from the enum above.

## Per-level semantics

### Task (plan.json)

- **`done: false`** — the task was written by the planning session (or appended by a verification cycle) but has not passed validation.
- **`done: true`** — the task ran its lifecycle to completion: test green, verify hook passed, mutation check passed, and the task's worktree merged into the run branch.

Tasks have no other state, and a `done` task is never revised, re-tagged, or removed. Only the CLI writes `plan.json`.

### Use Case

- **`pending`** — not every task covering the UC's scenarios is `done`. A freshly applied or freshly extracted UC starts here.
- **`implemented`** — every task in the change's plan whose `covers` scenarios belong to this UC is `done`, and the final verification passed.

### Feature

- **`pending`** — at least one UC under the feature is `pending`.
- **`implemented`** — every UC under the feature has `status: implemented`.

## The roll-up rule

A single rule, applied at the Feature level over its immediate children's (UCs') `status` values:

```
status(Feature) =
  - "implemented"  if every child UC has status "implemented"
  - "pending"      otherwise
```

**Feature roll-up children** = `UC-XXXX-*.md` spec files in the feature folder. The roll-up reads each UC's frontmatter `status:`. It never reads the CHANGELOG.

## UC status — written directly from task completion

The UC is a leaf, so there is no UC-level roll-up; its status is **written directly** by the writer that last touched it:

- **The CLI's apply step** — a new UC the request creates is written with `status: pending`. A previously `implemented` UC the request modifies is rewritten to `pending` on the run branch, in the same commit as the spec edit. On the base branch nothing changes until the run merges.
- **`/m:cover`** — a UC extracted from existing code is written with `status: pending`. It stays `pending` until a run builds its tests.
- **The CLI, after tasks run** — computes UC status from the plan's tasks: every task covering the UC's scenarios `done` → `implemented`; otherwise → `pending`. Overwrites the UC frontmatter regardless of prior value.

## Which writer owns which level

| Level | Written by | When |
|-------|-----------|------|
| Task `done` | The CLI's planning session | New task → `done: false`. |
| Task `done` | The CLI | Task passes validation and merges → `done: true`, via the `complete` operation. |
| UC | The CLI's apply step, `/m:cover` | New UC → `pending`. Modified previously-`implemented` UC → `pending`, on the run branch. |
| UC | The CLI | After tasks run → write UC status directly from covering-task state. |
| Feature | The CLI's apply step, `/m:cover` | After updating a child UC's status → recompute via roll-up over child UCs. |
| Feature | The CLI | After updating child UC statuses → recompute via roll-up over child UCs. |

The authoring commands `/m:spec`, `/m:fix`, and `/m:change` write no status at all — they write `request.md` and never touch the spec tree.

## Where status lives in the spec tree

```
specs/features/{module}/FEAT-XXXX-{slug}/
├── REQUIREMENTS.md            ← Feature status here (frontmatter `status:`)
├── USE-CASES.md
├── ARCHITECTURE.md
├── UC-AAAA-{slug}.md          ← UC status here (frontmatter `status:`)
└── UC-AAAA-{slug}/
    └── CHANGELOG.md           ← markers + log, NOT status

specs/changes/
└── <change-id>/
    └── plan.json              ← Task status here (`done` field per task)
```

## Relationship to the CHANGELOG

The CHANGELOG is a context log and a marker file for "what needs to change and why", **not** the status source of truth. Its entry-status transitions (`pending` → `implemented`, TODO → DONE) track which change requests have been built; the artifact frontmatter `status:` (UC, Feature) and the plan's `done` fields (task) are what every consumer reads to answer "is this implemented?"

See the `uc-log` skill for the CHANGELOG file format and entry mechanics.
