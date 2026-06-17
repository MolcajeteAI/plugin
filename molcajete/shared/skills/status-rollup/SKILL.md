---
name: status-rollup
description: >-
  Status as first-class state on slices, use cases, and features.
  Defines the three-value enum (pending | dirty | implemented), per-level
  semantics, the bottom-up roll-up rule, and which command writes which
  level's status. Status lives on the artifact's frontmatter and is the
  source of truth — the CHANGELOG is for context and markers, not state.
---

# Status Roll-up

Every spec artifact carries a `status` field in its frontmatter. This is the **source of truth** for whether the artifact is implemented. Open any FEAT / UC / SLICE spec file and the frontmatter answers "is this implemented?" without reading any other file.

The three-value enum is the same at every level: `pending`, `dirty`, `implemented`. The semantics are scoped to the level.

## The three values

- **`pending`** — the artifact has never been built. (At the slice level: implementation hasn't run. At the UC and feature level: no descendant slice is `implemented` yet.)
- **`dirty`** — the artifact was previously `implemented` and now has unfinished work. Either a spec edit invalidated it, or new descendant work was introduced.
- **`implemented`** — the artifact is complete. Tests pass, coverage gate passed, every descendant is also `implemented`.

The legacy value `deprecated` is preserved when already present in an artifact's frontmatter; this skill does not manage that transition.

## Per-level semantics

### Slice

- **`pending`** — slice file was written by `/m:plan` but `/m:build` has not implemented it yet.
- **`dirty`** — slice was previously `implemented`, but its UC has been modified (via `/m:change`, `/m:fix`, or `/m:spec`) and the slice's behavior may need to change. Set by `/m:plan` when scheduling new work that supersedes the slice.
- **`implemented`** — `/m:build` ran the TDD loop to completion: test green, coverage gate passed, mutation check passed.

The slice's `status` field is the **only** runtime state on the slice file. The `.molcajete/slices/{id}.json` record is kept as a durable build outcome for diagnostics (mutation logs, retry counts, timestamps) but it is **not** consulted for status decisions — neither for dependency gating in `/m:build` nor for any roll-up.

### Use Case

- **`pending`** — UC has never been built. Every slice is `pending` or `dirty`; no slice is `implemented`.
- **`dirty`** — UC was previously `implemented` and has at least one slice that is now `pending` or `dirty`, OR a spec-phase command (`/m:fix`, `/m:change`, `/m:spec`) has modified the UC since it was implemented (even before any new slice exists yet).
- **`implemented`** — every slice in the UC's support folder has `status: implemented`.

### Feature

- **`pending`** — feature has never been built. Every UC is `pending` or `dirty`; no UC is `implemented`.
- **`dirty`** — feature was previously `implemented` and at least one UC is now `pending` or `dirty`.
- **`implemented`** — every UC under the feature has `status: implemented`.

## The roll-up rule

A single rule, applied at any parent level over its immediate children's `status` values:

```
status({parent}) =
  - "implemented"  if every child has status "implemented"
  - "dirty"        if at least one child is "dirty"
                   OR (at least one child is "pending" AND at least one child is "implemented")
  - "pending"      if every child is "pending" or "dirty" with no "implemented" children
```

In prose: **all implemented → implemented; some implemented + some pending → dirty; nothing implemented → pending**. The `dirty` middle state captures "this thing was working and now part of it isn't" — the partial-completion / mid-iteration state.

Children by level:

- **UC roll-up children** = `SLICE-NNN-*.md` files in the UC's support folder.
- **Feature roll-up children** = `UC-XXXX-*.md` spec files in the feature folder.

The roll-up reads each child's frontmatter `status:` field. It never reads the CHANGELOG. It never reads `.molcajete/slices/{id}.json`.

## Direct-write override at the UC level

The roll-up over slice statuses would say a UC is `implemented` whenever every slice is `implemented`. But when a spec-phase command edits an `implemented` UC, the UC must immediately reflect that change — before `/m:plan` has had a chance to invalidate any slice. So spec-phase commands write UC `status: dirty` **directly** when modifying a previously-`implemented` UC, even though every slice is still `implemented`.

This is a deliberate departure from pure roll-up at the UC level. Order of precedence for UC `status`:

1. If spec-phase commands have flipped it to `dirty` since the last build, keep `dirty` until `/m:build` flips slices back to `implemented` and a fresh roll-up agrees.
2. Otherwise, compute by rolling up slice statuses.

`/m:build` always recomputes UC and Feature status by roll-up after a successful slice build. Spec-phase commands write `dirty` directly when needed.

## Which command writes which level

| Level | Written by | When |
|-------|-----------|------|
| Slice | `/m:plan` | New slice → `status: pending`. Existing implemented slice superseded by new spec → `status: dirty`. |
| Slice | `/m:build` | Slice's TDD loop completes successfully → `status: implemented`. |
| UC | `/m:spec`, `/m:fix`, `/m:change`, `/m:cover` | New UC → `pending`. Editing a previously-`implemented` UC → `dirty` (direct write). |
| UC | `/m:build` | After a slice flips to `implemented` → recompute via roll-up over sibling slices. |
| Feature | `/m:spec`, `/m:fix`, `/m:change`, `/m:cover` | After updating a child UC's status → recompute via roll-up over child UCs. |
| Feature | `/m:build` | After updating a child UC's status → recompute via roll-up over child UCs. |

`/m:plan` does **not** write UC status or Feature status. It only writes slice status and stamps CHANGELOG entries (`pending` → `dirty` with plan-id).

## Where status lives in the spec tree

```
specs/features/{module}/FEAT-XXXX-{slug}/
├── REQUIREMENTS.md            ← Feature status here (frontmatter `status:`)
├── USE-CASES.md
├── ARCHITECTURE.md
├── UC-AAAA-{slug}.md          ← UC status here (frontmatter `status:`)
└── UC-AAAA-{slug}/
    ├── CHANGELOG.md           ← markers + log, NOT status
    ├── SLICE-001-{name}.md    ← Slice status here (frontmatter `status:`)
    └── SLICE-002-{name}.md    ← Slice status here (frontmatter `status:`)
```

## Relationship to the CHANGELOG

The CHANGELOG is **not** the status source of truth. It is a context log and a marker file for "what needs to change and why". Its entry-status transitions (`pending` → `dirty` → `implemented`, TODO → DONE) remain useful for tracking which change requests have been planned and built. But the artifact's frontmatter `status:` is what every consumer reads to answer "is this implemented?"

See the `uc-log` skill for the CHANGELOG file format and entry mechanics.

## At-a-glance reads

Any reader — human or AI agent — can answer status questions by reading exactly one file:

- "Is this feature implemented?" → open `REQUIREMENTS.md`, read frontmatter `status:`.
- "Is this UC implemented?" → open `UC-XXXX-{slug}.md`, read frontmatter `status:`.
- "Is this slice implemented?" → open the slice file, read frontmatter `status:`.

No need to walk the CHANGELOG. No need to read `.molcajete/slices/{id}.json`.
