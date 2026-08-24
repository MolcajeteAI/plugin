---
name: uc-log
description: >-
  Per-UC change log mechanics. Defines the CHANGELOG.md sidecar file path,
  TODO/DONE section layout, entry line format, the append-only invariant that
  forbids any command from removing or rewriting an existing entry, and
  entry-status transitions (pending → implemented). Entries are written by
  /m:cover at extraction time and by the CLI's apply step when it lands a
  change request on the run branch. The changelog is a context log + marker
  file; it is NOT the source of truth for artifact status (see status-rollup).
---

# UC Changelog

Every use case carries a sidecar changelog file that records each spec change requested for that UC and tracks it through execution. The changelog is the contract between the authoring commands (`/m:spec`, `/m:fix`, `/m:change`, `/m:cover`) and the executor (the `molcajete` CLI).

The changelog answers two questions: **what changed and why** (for the planning session) and **what's still outstanding** (for the next run).

Under the request model, `/m:spec`, `/m:fix`, and `/m:change` never touch the spec tree — they write `request.md`. Their changelog entries are therefore written by the CLI's **apply step**, which lands the request's diffs on the run branch and inserts one entry per affected module-instance, carrying the originating command's token. `/m:cover` is the one command that writes the spec tree directly, so it also writes its own entries directly.

## Append-Only — The Log Never Loses History

The changelog exists to preserve history. **An entry line, once written, is permanent.** No command and no skill may ever remove or rewrite one.

Exactly three mutations are permitted. There are no others:

| # | Mutation | Who |
|---|----------|-----|
| 1 | Insert a **new** entry line at the top of `TODO:`. | The CLI's apply step (for `spec`, `fix`, `change` requests), `/m:cover` at extraction time, the CLI mid-run when a decision or known issue produces spec work |
| 2 | On one existing TODO line, replace the `plan:—` field with `plan:<plan-id>`. Nothing else on the line changes. | The CLI's planning session, when its plan consumes a `pending` entry a previous run left behind |
| 3 | On one existing TODO line, flip `[pending]` → `[implemented]` and move the line **verbatim** to the top of `DONE:`. Nothing else on the line changes. | The CLI, when every task covering the entry completes |

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

**Plan stamp and status flip (mutations 2 and 3).** The anchor is the single line being changed. The replacement differs from it only in the `plan:` field (mutation 2) or the bracketed status token (mutation 3). Every other character of the line is copied through unchanged.

### Near-Duplicate Entries Are Still New Entries

A new entry whose `reason` reads the same as an existing entry's is **still a new entry**. Re-running a command over the same bug or the same request correctly produces two entries with different timestamps: the log is recording that the command ran twice, which is itself history worth keeping.

Textual similarity to an existing line is never evidence that the line should be replaced, refreshed, or re-timestamped. Do not "update" an entry. Do not treat writing the log as an idempotent operation.

### Self-Check After Every Write

Before moving on, confirm both:

1. The number of entry lines in the file did not decrease.
2. Every timestamp that was in the file before the edit is still in the file.

If either fails, the edit destroyed history: restore the removed lines immediately and re-apply the change as an insertion.

## The changelog is not the status source of truth

Artifact status (UC, feature) lives on each artifact's frontmatter `status:` field; task status is the `done` field on each task in the change's `plan.json`. The changelog's entries have their own per-entry status field, but that is **not** the canonical state of the UC. This skill defines only the changelog file mechanics. See the `status-rollup` shared skill for how status is owned.

## File Path

The log lives inside the UC's support folder:

```
specs/features/{module}/FEAT-XXXX-{slug}/UC-XXXX-{slug}/CHANGELOG.md
```

- One log per **module-instance** of a UC. When a UC exists in 2+ modules (same UC-XXXX ID, different module-scoped files — see `spec/skills/usecase-authoring/SKILL.md` → Module-Scoped Use Cases), each module has its own CHANGELOG.md alongside its own UC file. Do not share a single log across module-instances.
- The filename is always literal `CHANGELOG.md` — it does not encode the UC ID (the parent directory already does).
- Created lazily by the first write that touches that module-instance of the UC.

## Multi-Module UC Logging

When a UC-XXXX ID resolves to multiple module-instances (the same UC exists in 2+ modules), a single spec change fans out to **every module-instance's CHANGELOG.md that the change applies to**. Each module-instance keeps its own log; the fan-out just means the writer adds one entry per affected module-instance.

**Fan-out rules:**

- The writer resolves the UC-XXXX ID to its set of module-instances (glob `specs/features/*/FEAT-*/UC-XXXX-*.md`). For a request-driven change, the request's per-module sections already name the affected module-instances.
- The user may narrow the fan-out at authoring time (e.g., "only apply this change in the console module"). Only the module-instances the request names receive an entry. When asking for that confirmation, follow `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` — list the module-instances in the brief, keep the question to one sentence.
- Entries in different module-instances **share the same timestamp** and **the same reason text** when the event is one logical spec change.
- Each entry also carries a `modules:` metadata token naming every module-instance that received an entry for this event. This makes fan-outs traceable from any single CHANGELOG.md — a reader looking at one module can see the change was also applied to the other listed modules.
- The `modules:` token is **omitted** when the UC only exists in one module (single-instance / single-module project).
- **When only one module is affected but the UC is multi-module** (e.g., the fix is patient-only): the `modules:` token names just that module. Absence of a peer module in `modules:` signals to any reader that the peer module was intentionally not part of this event.

The CLI treats each module-instance's log independently for status transitions. Roll-up across module-instances still happens through the parent feature's status per the `status-rollup` skill.

## File Shape

Plain Markdown with two top-level sections, `TODO:` and `DONE:`, separated by a blank line.

```markdown
TODO:
- <timestamp> [pending] command:change  plan:20260823T104500-order-expiry  — reason text
- <timestamp> [pending] command:cover   plan:—                             — reason text

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
| `status` | One of `pending`, `implemented` | `[pending]` | yes |
| `command` | `spec` \| `fix` \| `change` \| `cover` | `command:change` | yes |
| `plan` | The change ID (the directory name under `specs/changes/`), or `—` if no run has consumed the entry | `plan:20260823T104500-order-expiry` | yes |
| `modules` | Comma-separated list of module IDs this event fanned out to | `modules:patient,console` | Only when the UC exists in 2+ module-instances. Omit for single-module UCs. |
| `reason` | One-line description of what changed and why | free text | yes |

The em dash (`—`) separates the metadata from the reason. Do not use the em dash inside the reason — pick another punctuation. When present, `modules:` sits between `plan:` and the em dash, separated from `plan:` by a single space.

An entry the apply step writes is born already stamped — it carries the running change's `plan:<plan-id>`, because the apply and the plan happen in the same phase of the same run. Only entries written outside a run (`/m:cover` at extraction, a known issue left for a later run) start with `plan:—`.

## Entry Ordering

Within each section, **newest entries go at the top** (prepended, not appended). Each section reads top-to-bottom = newest-to-oldest. Never reorder existing entries.

The commands say "append the changelog entry." That always means **insert a new line at the top of `TODO:`**, per mutation 1 above — never overwrite whatever is currently at the top.

## Status Transitions

```
pending ──covering tasks complete──► implemented
```

- `pending` — the change is recorded but its covering tasks have not all completed. Lives under `TODO:`.
- `implemented` — the CLI finished every task covering the entry; tests pass. Lives under `DONE:`.

No other transitions. Statuses never roll back. A superseded change gets a **new** entry; the entry it supersedes stays in the file untouched, per **Append-Only**.

The `dirty` status is gone. It marked a spec that ran ahead of its implementation, and that state can no longer occur: every commit during execution carries the updated specs, the code, and the tests together, on the run's own branch.

## How Each Writer Touches the Log

Every row below applies **per module-instance**, per the fan-out rules above. Every action is one of the three permitted mutations from **Append-Only**; no writer has any other write access to the file.

| Writer | Action | Mutation |
|--------|--------|----------|
| The CLI's apply step | For each UC the request touches: insert a new `pending` entry at the top of TODO, with the `command:` token of the request's originating command (`spec`, `fix`, or `change`) and `plan:<change-id>` already stamped. | 1 |
| `/m:cover` | Insert a new `pending` entry at the top of TODO. `command:cover`. `plan:—`. Once per module-instance at extraction time. | 1 |
| The CLI's planning session | For each pre-existing `pending` entry the plan consumes (a `cover` entry, a known issue from an earlier run): set `plan:<change-id>`. The entry stays in TODO. | 2 |
| The CLI mid-run | When a decision produces spec work, or a known issue is recorded for a later run: insert a new `pending` entry at the top of TODO with the `command:` token of the work it describes. A known-issue entry keeps `plan:—` so a later run picks it up. | 1 |
| The CLI | For each entry whose covering tasks all completed: flip status to `implemented`, move the line from TODO to DONE (prepended at top of DONE). | 3 |

**A TODO section may mix commands.** A use case whose log holds a `command:cover` entry beside a `command:fix` entry is normal, and one run's planning session consumes both: each task's `origin` field in `plan.json` keeps the entry's `command:` token linkable. No writer refuses a mixed set.
