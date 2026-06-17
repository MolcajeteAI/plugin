---
name: uc-log
description: >-
  Per-UC change log + UC status frontmatter mechanics. Defines the CHANGELOG.md
  sidecar file path, TODO/DONE section layout, entry line format, status
  transitions (pending → dirty → implemented), and how the UC status field
  rolls up from its log entries. Referenced by /m:spec, /m:fix, /m:change,
  /m:cover, /m:plan, and /m:build.
---

# UC Log

Every use case carries a sidecar log file that records each spec-phase change requested for that UC and tracks it through plan and build. The log is the contract between the spec-phase commands (`/m:spec`, `/m:fix`, `/m:change`, `/m:cover`), the architect (`/m:plan`), and the executor (`/m:build`).

The log answers two questions: **what changed and why** (for plan) and **what's still outstanding** (for plan and build).

## File Path

The log lives inside the UC's support folder:

```
specs/features/{module}/FEAT-XXXX-{slug}/UC-XXXX-{slug}/CHANGELOG.md
```

- One log per UC. Never share a log across UCs.
- The filename is always literal `CHANGELOG.md` — it does not encode the UC ID (the parent directory already does).
- Created lazily by the first spec-phase command that touches the UC.

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
- <timestamp> [<status>] command:<command> plan:<plan-id-or-—> — <reason>
```

Fields:

| Field | Format | Example |
|-------|--------|---------|
| `timestamp` | ISO 8601 compact: `YYYYMMDDTHHMMSS` (UTC) | `20260616T141530` |
| `status` | One of `pending`, `dirty`, `implemented` | `[pending]` |
| `command` | `spec` \| `fix` \| `change` \| `cover` | `command:change` |
| `plan` | Plan folder ID, or `—` if not yet planned | `plan:20260616T141530-add-checkout` |
| `reason` | One-line description of what changed and why | free text |

The em dash (`—`) separates the metadata from the reason. Do not use the em dash inside the reason — pick another punctuation.

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
| `/m:spec` | Append `pending` entry to TODO. `command:spec`. `plan:—`. |
| `/m:fix` | Append `pending` entry to TODO. `command:fix`. `plan:—`. Always — even when no spec edit was needed. |
| `/m:change` | Append `pending` entry to TODO. `command:change`. `plan:—`. |
| `/m:cover` | Append `pending` entry to TODO. `command:cover`. `plan:—`. Once per UC at extraction time. |
| `/m:plan` | For each `pending` entry it consumes: flip status to `dirty`, set `plan:<plan-id>`. Entries stay in TODO. |
| `/m:build` | For each `dirty` entry whose tasks completed: flip status to `implemented`, move the line from TODO to DONE (prepended at top of DONE). |

`/m:plan` refuses to operate if any of the referenced UCs' TODO sections mix `command:cover` entries with other commands. Mixed-mode pending entries must be split across separate plan runs.

## UC Status Frontmatter

Every `UC-XXXX-{slug}.md` (the UC spec file) carries a `status` field in its frontmatter. The field is a roll-up of the UC's log state:

```yaml
---
id: UC-XXXX
name: ...
feature: FEAT-XXXX
status: pending | dirty | implemented
version: 1
actor: ...
---
```

- **`pending`** — UC has never been built. Every log entry is `pending` or `dirty`; there is no `implemented` entry yet.
- **`dirty`** — UC was previously built (at least one log entry is `implemented`) and now has at least one new `pending` or `dirty` entry.
- **`implemented`** — Every log entry is `implemented`. No outstanding changes.

`/m:spec`, `/m:fix`, `/m:change`, and `/m:cover` recompute and write this field after appending a log entry. `/m:build` recomputes and writes this field after flipping the last outstanding entry to `implemented`.

The legacy value `deprecated` is preserved when already present; this skill does not manage that transition.

## Two "dirty" Meanings

The word `dirty` appears at two levels with intentionally different meanings. Do not conflate them:

- **Entry-level `dirty`** — "in flight." The entry has been planned but the build hasn't completed.
- **UC-level `dirty`** — "was complete, now has new unfinished work." The UC has both `implemented` history *and* outstanding pending/dirty entries.

## Idempotency

Every operation on the log is idempotent at the entry level:

- Re-running `/m:spec`, `/m:fix`, `/m:change`, or `/m:cover` with the same description appends a new entry; it does not edit prior entries. Duplicate descriptions are the author's responsibility to avoid.
- Re-running `/m:plan` against the same pending entries always creates a new plan folder (per the lifecycle rule) but updates each consumed entry in place (status and plan-id).
- Re-running `/m:build` against an already-completed task is a no-op on the log.
