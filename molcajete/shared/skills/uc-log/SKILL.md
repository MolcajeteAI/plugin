---
name: uc-log
description: >-
  Per-UC change log mechanics. Defines the CHANGELOG.md sidecar file path,
  TODO/DONE section layout, entry line format, and entry-status transitions
  (pending → dirty → implemented). Referenced by /m:spec, /m:fix, /m:change,
  /m:cover, /m:plan, and /m:build. The changelog is a context log + marker
  file; it is NOT the source of truth for artifact status (see status-rollup).
---

# UC Changelog

Every use case carries a sidecar changelog file that records each spec-phase change requested for that UC and tracks it through plan and build. The changelog is the contract between the spec-phase commands (`/m:spec`, `/m:fix`, `/m:change`, `/m:cover`), the architect (`/m:plan`), and the executor (`/m:build`).

The changelog answers two questions: **what changed and why** (for plan) and **what's still outstanding** (for plan and build).

## The changelog is not the status source of truth

Artifact status (UC, feature) lives on each artifact's frontmatter `status:` field; task status is the plan's `## [ ]` / `## [x]` checkbox. The changelog's entries have their own per-entry status field, but that is **not** the canonical state of the UC. See the `status-rollup` shared skill for how status is owned by spec-phase commands and `/m:build`.

This skill defines only the changelog file mechanics. Commands write `status` directly to the relevant frontmatter; the changelog mechanics described below do not affect that.

## File Path

The log lives inside the UC's support folder:

```
specs/features/{module}/FEAT-XXXX-{slug}/UC-XXXX-{slug}/CHANGELOG.md
```

- One log per **module-instance** of a UC. When a UC exists in 2+ modules (same UC-XXXX ID, different module-scoped files — see `spec/skills/usecase-authoring/SKILL.md` → Module-Scoped Use Cases), each module has its own CHANGELOG.md alongside its own UC file. Do not share a single log across module-instances.
- The filename is always literal `CHANGELOG.md` — it does not encode the UC ID (the parent directory already does).
- Created lazily by the first spec-phase command that touches that module-instance of the UC.

## Multi-Module UC Logging

When a UC-XXXX ID resolves to multiple module-instances (the same UC exists in 2+ modules), a single spec-phase event fans out to **every module-instance's CHANGELOG.md that the event applies to**. Each module-instance keeps its own log; the fan-out just means the calling command writes one entry per affected module-instance.

**Fan-out rules:**

- The calling command (`/m:spec`, `/m:change`, `/m:fix`, `/m:cover`) resolves the UC-XXXX ID to its set of module-instances (glob `specs/features/*/FEAT-*/UC-XXXX-*.md`).
- The user may narrow the fan-out (e.g., "only apply this change in the console module"). Only the module-instances the user confirmed receive an entry.
- Entries in different module-instances **share the same timestamp** and **the same reason text** when the event is one logical spec-phase change.
- Each entry also carries a `modules:` metadata token naming every module-instance that received an entry for this event. This makes fan-outs traceable from any single CHANGELOG.md — a reader looking at one module can see the change was also applied to the other listed modules.
- The `modules:` token is **omitted** when the UC only exists in one module (single-instance / single-module project).

**Example — same event across two modules (`patient` and `console`):**

```
TODO:
- 20260616T141530 [pending] command:change plan:— modules:patient,console — email-verification gate added per security review
```

(This exact line appears in both `specs/features/patient/FEAT-.../UC-XXXX-.../CHANGELOG.md` and `specs/features/console/FEAT-.../UC-XXXX-.../CHANGELOG.md`.)

**When only one module is affected but the UC is multi-module** (e.g., the fix is patient-only): the `modules:` token names just that module. Absence of a peer module in `modules:` signals to any reader that the peer module was intentionally not part of this event.

`/m:plan` treats each module-instance's log independently for status transitions (each entry flips `pending` → `dirty` → `implemented` on its own module-instance's file). Roll-up across module-instances still happens through the parent feature's status per the `status-rollup` skill.

## File Shape

Plain Markdown with two top-level sections, `TODO:` and `DONE:`, separated by a blank line.

```markdown
TODO:
- <timestamp> [dirty]   command:change  plan:20260616T141530-add-checkout  — reason text
- <timestamp> [pending] command:fix     plan:—                              — reason text

DONE:
- <timestamp> [implemented] command:spec  plan:20260601T093000-bootstrap  — reason text
- <timestamp> [implemented] command:cover plan:20260530T120045-import-1   — reason text
```

Both sections always exist, even when empty. Section headings are literal: `TODO:` and `DONE:` followed by a colon, no markdown heading prefix.

## Entry Line Format

One Markdown list item per entry:

```
- <timestamp> [<status>] command:<command> plan:<plan-id-or-—> [modules:<a,b,...>] — <reason>
```

Fields:

| Field | Format | Example | Required |
|-------|--------|---------|----------|
| `timestamp` | ISO 8601 compact: `YYYYMMDDTHHMMSS` (UTC) | `20260616T141530` | yes |
| `status` | One of `pending`, `dirty`, `implemented` | `[pending]` | yes |
| `command` | `spec` \| `fix` \| `change` \| `cover` | `command:change` | yes |
| `plan` | Plan folder ID, or `—` if not yet planned | `plan:20260616T141530-add-checkout` | yes |
| `modules` | Comma-separated list of module IDs this event fanned out to | `modules:patient,console` | Only when the UC exists in 2+ module-instances. Omit for single-module UCs. |
| `reason` | One-line description of what changed and why | free text | yes |

The em dash (`—`) separates the metadata from the reason. Do not use the em dash inside the reason — pick another punctuation. When present, `modules:` sits between `plan:` and the em dash, separated from `plan:` by a single space.

## Entry Ordering

Within each section, **newest entries go at the top** (prepended, not appended). Each section reads top-to-bottom = newest-to-oldest. Never reorder existing entries.

## Status Transitions

```
pending ──/m:plan──► dirty ──/m:build──► implemented
```

- `pending` — written by a spec-phase command. No plan has consumed it yet. Lives under `TODO:`.
- `dirty` — `/m:plan` has consumed the entry, stamped its plan-id, and produced a plan that addresses it. Build has not finished yet. Lives under `TODO:`.
- `implemented` — `/m:build` finished the corresponding tasks; tests pass. Lives under `DONE:`.

No other transitions. A `pending` entry never becomes `implemented` without first becoming `dirty` — plan is mandatory. Statuses never roll back; superseded changes get a new entry, not edits to old ones.

## How Each Command Touches the Log

| Command | Action |
|---------|--------|
| `/m:spec` | Append `pending` entry to TODO. `command:spec`. `plan:—`. For multi-module UCs, fan out — append to every module-instance's CHANGELOG.md and include the `modules:` token. |
| `/m:fix` | Append `pending` entry to TODO. `command:fix`. `plan:—`. Always — even when no spec edit was needed. For multi-module UCs, fan out to every affected module-instance and include `modules:`. |
| `/m:change` | Append `pending` entry to TODO. `command:change`. `plan:—`. For multi-module UCs, fan out to every affected module-instance and include `modules:`. |
| `/m:cover` | Append `pending` entry to TODO. `command:cover`. `plan:—`. Once per module-instance at extraction time. For multi-module UCs, fan out and include `modules:`. |
| `/m:plan` | For each `pending` entry it consumes: flip status to `dirty`, set `plan:<plan-id>`. Entries stay in TODO. For multi-module UCs, `/m:plan` transitions the entries in every module-instance's CHANGELOG.md that the plan covers. |
| `/m:build` | For each `dirty` entry whose tasks completed: flip status to `implemented`, move the line from TODO to DONE (prepended at top of DONE). Per module-instance. |

`/m:plan` refuses to operate if any of the referenced UCs' TODO sections mix `command:cover` entries with other commands. Mixed-mode pending entries must be split across separate plan runs.

## Two "dirty" Meanings

The word `dirty` appears at two levels with intentionally different meanings. Do not conflate them:

- **Entry-level `dirty`** (managed here) — "in flight." The changelog entry has been planned but the build hasn't completed.
- **Artifact-level `dirty`** (managed by `status-rollup`) — "was complete, now has new unfinished work." Lives on the UC / feature frontmatter.

## Idempotency

Every operation on the log is idempotent at the entry level:

- Re-running `/m:spec`, `/m:fix`, `/m:change`, or `/m:cover` with the same description appends a new entry; it does not edit prior entries. Duplicate descriptions are the author's responsibility to avoid.
- Re-running `/m:plan` against the same pending entries always creates a new plan folder (per the lifecycle rule) but updates each consumed entry in place (status and plan-id).
- Re-running `/m:build` against an already-completed task is a no-op on the log.
