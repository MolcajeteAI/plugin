---
name: uc-log
description: >-
  Per-UC change log mechanics. Defines the CHANGELOG.md sidecar file path,
  TODO/DONE section layout, entry line format, the append-only invariant that
  forbids any command from removing or rewriting an existing entry, and
  entry-status transitions
  (pending → dirty → implemented). Referenced by /m:spec, /m:fix, /m:change,
  /m:cover, /m:plan, and /m:build. The changelog is a context log + marker
  file; it is NOT the source of truth for artifact status (see status-rollup).
---

# UC Changelog

Every use case carries a sidecar changelog file that records each spec-phase change requested for that UC and tracks it through plan and build. The changelog is the contract between the spec-phase commands (`/m:spec`, `/m:fix`, `/m:change`, `/m:cover`), the architect (`/m:plan`), and the executor (`/m:build`).

The changelog answers two questions: **what changed and why** (for plan) and **what's still outstanding** (for plan and build).

## Append-Only — The Log Never Loses History

The changelog exists to preserve history. **An entry line, once written, is permanent.** No command and no skill may ever remove or rewrite one.

Exactly three mutations are permitted. There are no others:

| # | Mutation | Who |
|---|----------|-----|
| 1 | Insert a **new** entry line at the top of `TODO:`. | `/m:spec`, `/m:fix`, `/m:change`, `/m:cover` |
| 2 | On one existing TODO line, flip `[pending]` → `[dirty]` and replace the `plan:—` field with `plan:<plan-id>`. Nothing else on the line changes. | `/m:plan` |
| 3 | On one existing TODO line, flip `[dirty]` → `[implemented]` and move the line **verbatim** to the top of `DONE:`. Nothing else on the line changes. | `/m:build` |

Everything else is forbidden. Specifically, never:

- Delete an entry line.
- Rewrite an existing entry's `timestamp`, `command`, `modules`, or `reason`.
- Replace an existing entry with a new one, for any reason.
- Merge two entries into one.
- Reorder entries.
- Overwrite the file wholesale. `Write` on a CHANGELOG.md is permitted **only** to create it with empty `TODO:` / `DONE:` sections. An existing CHANGELOG.md is modified with `Edit`, never `Write`.

### Write Mechanic

**Adding an entry (mutation 1).** The edit's anchor is the literal section header line `TODO:`, and the replacement is that header plus the new line beneath it:

```
old_string:  TODO:
new_string:  TODO:
             - <new entry line>
```

Never anchor the edit on an existing entry line. The file's line count must increase by exactly one.

**Status flips (mutations 2 and 3).** The anchor is the single line being flipped. The replacement differs from it only in the bracketed status token — plus, for `/m:plan`, the `plan:` field. Every other character of the line is copied through unchanged.

### Near-Duplicate Entries Are Still New Entries

A new entry whose `reason` reads the same as an existing entry's is **still a new entry**. Re-running a command over the same bug or the same request correctly produces two entries with different timestamps: the log is recording that the command ran twice, which is itself history worth keeping.

Textual similarity to an existing line is never evidence that the line should be replaced, refreshed, or re-timestamped. Do not "update" an entry. Do not treat writing the log as an idempotent operation.

### Self-Check After Every Write

Before moving on, confirm both:

1. The number of entry lines in the file did not decrease.
2. Every timestamp that was in the file before the edit is still in the file.

If either fails, the edit destroyed history: restore the removed lines immediately and re-apply the change as an insertion.

## The changelog is not the status source of truth

Artifact status (UC, feature) lives on each artifact's frontmatter `status:` field; task status is the plan's `## [ ]` / `## [x]` checkbox. The changelog's entries have their own per-entry status field, but that is **not** the canonical state of the UC. This skill defines only the changelog file mechanics. See the `status-rollup` shared skill for how status is owned by spec-phase commands and `/m:build`.

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
- The user may narrow the fan-out (e.g., "only apply this change in the console module"). Only the module-instances the user confirmed receive an entry. When asking for that confirmation, follow `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` — list the module-instances in the brief, keep the question to one sentence.
- Entries in different module-instances **share the same timestamp** and **the same reason text** when the event is one logical spec-phase change.
- Each entry also carries a `modules:` metadata token naming every module-instance that received an entry for this event. This makes fan-outs traceable from any single CHANGELOG.md — a reader looking at one module can see the change was also applied to the other listed modules.
- The `modules:` token is **omitted** when the UC only exists in one module (single-instance / single-module project).
- **When only one module is affected but the UC is multi-module** (e.g., the fix is patient-only): the `modules:` token names just that module. Absence of a peer module in `modules:` signals to any reader that the peer module was intentionally not part of this event.

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
| `plan` | Plan ID (the plan file name without `.md`), or `—` if not yet planned | `plan:20260616T141530-add-checkout` | yes |
| `modules` | Comma-separated list of module IDs this event fanned out to | `modules:patient,console` | Only when the UC exists in 2+ module-instances. Omit for single-module UCs. |
| `reason` | One-line description of what changed and why | free text | yes |

The em dash (`—`) separates the metadata from the reason. Do not use the em dash inside the reason — pick another punctuation. When present, `modules:` sits between `plan:` and the em dash, separated from `plan:` by a single space.

## Entry Ordering

Within each section, **newest entries go at the top** (prepended, not appended). Each section reads top-to-bottom = newest-to-oldest. Never reorder existing entries.

The commands say "append the changelog entry." That always means **insert a new line at the top of `TODO:`**, per mutation 1 above — never overwrite whatever is currently at the top.

## Status Transitions

```
pending ──plan──► dirty ──/m:build──► implemented
```

- `pending` — written by a spec-phase command, or by `/m:build` recording a known issue. No plan has consumed it yet. Lives under `TODO:`.
- `dirty` — a plan has consumed the entry, stamped its plan-id, and addresses it. The stamp comes from whichever command ran **Producing a Plan** — `/m:plan`, `/m:fix`, `/m:change`, or `/m:build` amending the plan it is running. Build has not finished yet. Lives under `TODO:`.
- `implemented` — `/m:build` finished the corresponding tasks; tests pass. Lives under `DONE:`.

No other transitions. A `pending` entry never becomes `implemented` without first becoming `dirty` — plan is mandatory. Statuses never roll back. A superseded change gets a **new** entry; the entry it supersedes stays in the file untouched, per **Append-Only**.

## How Each Command Touches the Log

Every row below applies **per module-instance**, per the fan-out rules above. Every action is one of the three permitted mutations from **Append-Only**; no command has any other write access to the file.

| Command | Action | Mutation |
|---------|--------|----------|
| `/m:spec` | Insert a new `pending` entry at the top of TODO. `command:spec`. `plan:—`. | 1 |
| `/m:fix` | Insert a new `pending` entry at the top of TODO. `command:fix`. `plan:—`. Always — even when no spec edit was needed, and even when an existing entry says something similar. | 1 |
| `/m:change` | Insert a new `pending` entry at the top of TODO. `command:change`. `plan:—`. | 1 |
| `/m:cover` | Insert a new `pending` entry at the top of TODO. `command:cover`. `plan:—`. Once per module-instance at extraction time. | 1 |
| `/m:plan`, `/m:fix`, `/m:change` | For each `pending` entry the plan consumes: flip status to `dirty`, set `plan:<plan-id>`. Entries stay in TODO. Every command that runs the `plan-authoring` skill's **Producing a Plan** procedure performs this, because P7 of that procedure is where it happens. | 2 |
| `/m:build` | For each `dirty` entry whose tasks completed: flip status to `implemented`, move the line from TODO to DONE (prepended at top of DONE). | 3 |
| `/m:build` | When a mid-build amendment records a known issue, or precedes an inline spec edit: insert a new `pending` entry at the top of TODO, with the `command:` token of the work it describes (`fix`, `change`, or `cover`). | 1 |
| `/m:build` | When that inline spec edit produces a task in the running plan: flip the entry it just wrote to `dirty` and set `plan:<running-plan-id>`. A known-issue entry is **not** stamped — it stays `pending` with `plan:—` so the next `/m:plan` picks it up. | 2 |

**A TODO section may mix commands.** A use case whose log holds a `command:cover` entry beside a `command:fix` entry is normal, and `/m:plan` consumes both in one run: the `plan-authoring` skill assigns each entry its own task `**Kind:**`, so one plan carries `cover` tasks and `fix` tasks together. No command refuses a mixed set.

## Two "dirty" Meanings

The word `dirty` appears at two levels with intentionally different meanings. Do not conflate them:

- **Entry-level `dirty`** (managed here) — "in flight." The changelog entry has been planned but the build hasn't completed.
- **Artifact-level `dirty`** (managed by `status-rollup`) — "was complete, now has new unfinished work." Lives on the UC / feature frontmatter.
