---
name: plan-authoring
description: >-
  Owns the plan file format. One prose Markdown plan per /m:plan invocation,
  written under specs/plans/<timestamp>-<slug>/plan.md. Decomposes a use case
  into ordered, vertical, working-software tasks (never implementation layers),
  each a checkbox the build consumes. Referenced by /m:plan to emit the plan and
  by /m:build to execute it.
---

# Plan Authoring

A **plan** is a single Markdown document that describes, in prose, how a set of spec
changes will be delivered. It is the bridge between the spec layer (what the software must
do) and the build layer (working code + tests). `/m:plan` writes it; `/m:build` reads it.

The unit of work is a **task** — one *vertical, working-software increment*. A task moves
through whatever layers it needs (UI → API → domain → data) to make one named behavior real
and testable end to end. A task is **never a layer** ("the backend", "the database"): every
task must leave the software working. Tasks are ordered by dependency, and that order is the
order the build runs them and the order the human commits them.

Plans replace the old per-slice files. There is no `SLICE-NNN-*.md`, no per-task frontmatter,
and no slice DAG index — the plan document is the whole artifact.

## Filing and Plan IDs

`/m:plan` writes exactly one file per invocation:

```
specs/plans/<YYYYMMDDTHHMMSS>-<slug>/plan.md
```

- **Plan ID = a UTC timestamp to the second**, ISO compact: `20260727T143052`. Second-level
  granularity is the finest the ID carries — do not attempt sub-second precision.
- `-<slug>` is a short kebab-case descriptor (max 40 chars) derived from the pending work's
  reasons (e.g. `add-email-verification`, `fix-409-on-duplicate`). It is for humans; the
  timestamp is the identity.
- The plan lives under `specs/` because a plan is part of the recorded change history of the
  application — not a throwaway build artifact. It is tracked in git.
- Every `/m:plan` invocation creates a **new** folder. Never amend an existing plan folder.

## Plan File Structure

A plan has a title, a one- or two-line summary, a single `**Specs:**` line, an optional
short context paragraph, and then one `## [ ] T-NNN` section per task.

```markdown
# Plan: {Descriptive Name}

{One or two sentences: the working capability this plan delivers, and why.}

**Specs:** FEAT-XXXX-{slug} · UC-XXXX-{slug} · SC-XXXX, SC-YYYY  ·  **Mode:** default | cover | mixed

{Optional short paragraph of shared context — what we're building and the slice of the
architecture it touches. Reference the spec files once here (`specs/features/{module}/
FEAT-XXXX-{slug}/…`) so no task has to repeat them.}

## [ ] T-001 — {User-visible behavior, stated as an outcome}

**Covers:** SC-XXXX, SC-YYYY
**Depends on:** —

{Prose — see "Task Prose" below.}

## [ ] T-002 — {Next behavior}

**Covers:** SC-ZZZZ
**Depends on:** T-001

{Prose.}
```

The `**Specs:**` line names every FEAT and UC the plan touches plus the scenarios in scope,
and a `**Mode:**` label (`default`, `cover`, or `mixed`) summarizing the plan: `default` when
every task builds new/changed behavior, `cover` when every task pins existing behavior, `mixed`
when both. The label is a human summary; per-task truth is carried by each task's own prose
(implement vs coverage — see Task Objectives).

## Task Shape

Every task is a level-2 heading carrying a checkbox, then two fields, then prose:

```markdown
## [ ] T-NNN — {outcome phrased as a user-visible behavior}

**Covers:** <comma-separated SC-/FR- IDs>
**Depends on:** <comma-separated T-NNN IDs, or —>

{prose}
```

- **Checkbox** — `## [ ] T-NNN` is pending; `## [x] T-NNN` is done. This checkbox is the
  build's status ledger. There is no status frontmatter anywhere else.
- **T-NNN** — plan-local task ID, `T-001`, `T-002`, … assigned in dependency order. Numbering
  crosses FEAT/UC boundaries — there is one `T-NNN` sequence per plan.
- **Covers** — a **comma-separated list** of the `SC-XXXX` scenario IDs (and `FR-XXXX`
  requirement IDs) this task closes. Every scenario in every UC in scope must appear in exactly
  one task's `Covers`.
- **Depends on** — a **comma-separated list** of the prior `T-NNN` tasks this task builds on,
  or `—` when it has no prerequisite. Dependencies must point backward (lower NNN). A downstream
  task reads the code an upstream task already wrote to disk; the dependency is satisfied when
  the upstream task's checkbox is `[x]`.

### Task Prose

The prose is the task's contract. Because there is no frontmatter, the prose MUST make the
following unambiguous — written as flowing explanation, not as labeled lists:

1. **What the increment makes real, end to end** — the behavior a user or caller observes.
2. **The files it creates and modifies**, named inline as you explain the work ("the rule lands
   in `server/profile/setName.ts`, wired through `server/profile/router.ts`, and the `NameStep`
   in `web/onboarding/` calls it"). Build derives its edit set and its mutation targets from
   these.
3. **The entry point / driving port** the behavior is reached through (e.g. an HTTP route, a
   GraphQL field, an event handler, a service call). The driving-port kind must be one listed in
   the module's `Driving Ports` column in `specs/MODULES.md`. Build derives the canonical test
   path from it.
4. **How we prove it** — what the integration test drives and what "green" means: the concrete,
   user-observable outcomes that must hold. This is the source the build scaffolds the test from.
5. **Decisions and trade-offs** — key choices, what the task deliberately does *not* do, and the
   limitation each choice carries.

Use a fenced code snippet only where an exact shape matters (a function signature, a payload
schema) — not to enumerate steps. Keep it readable: a plan should read like a well-written
plan-mode plan, not a filled-in form.

## Vertical-Increment Rules

1. **One coherent behavior per task.** A task is "the thing that makes these scenarios real
   together." Don't bundle unrelated scenarios.
2. **Work across the layers, never within one.** Slice the work by *behavior* (name, then phone),
   not by *layer* (all the UI, then all the API). Every task leaves working software.
3. **Every scenario is covered exactly once.** Every `SC-` (and every requirement `FR-` a task
   claims) appears in exactly one task's `Covers`.
4. **Order is dependency order.** A task's NNN is greater than every task it depends on. That
   order is the execution order and the commit order.
5. **Files are owned, not shared.** A production file should be created/modified by at most one
   task in the plan. If two tasks both need to change the same file, either merge them or make one
   depend on the other so the edits are sequenced.
6. **Granularity follows the test seam.** If one integration test can validate the behavior end to
   end, the task is the right size. Split a task only at a genuine logical boundary — or when it
   would not fit a single ~200k-token build context. Splitting to isolate a layer is never valid.

## Task Objectives — implement vs coverage

Most tasks are **implement** tasks: net-new or changed behavior. Their integration test starts
RED and the build writes production code until it is GREEN.

A task may instead be a **coverage** task: it pins the behavior of code that already ships,
adding assertions with no new production code. Its test starts GREEN, and the build's mutation
step proves the assertions have teeth. State plainly in the prose which kind a task is (e.g.
"This pins existing behavior — no production code changes"). The build reads the prose to decide
the RED-vs-GREEN expectation; there is no `objective` field to set.

When a plan mixes coverage and implement tasks for the same UC, order all coverage tasks (lower
NNN) before the implement tasks that change that behavior, so existing behavior is pinned before
it is modified.

## Test File Convention

Integration test files are placed at a **canonical path derived from the task and
`specs/MODULES.md`** — never declared in the plan, never chosen ad hoc. The layout mirrors the
spec tree **module → feature → use case → task test** so any reader can grep the tree by feature
or UC and find every integration test that pins its behavior:

```
{module.Tests}/{feature-dir-name}/{uc-dir-name}/{NNN}-{entry-type}-{task-slug}.{test-ext}
```

| Token | Resolution |
|-------|-----------|
| `{module.Tests}` | The `Tests` column of the module's row in `specs/MODULES.md` (set by `/m:setup`). Integration tests live in a dedicated tests tree, not inside module source dirs. |
| `{feature-dir-name}` | The task's parent feature dir under `specs/features/{module}/`, e.g. `FEAT-0Fy0-onboarding` |
| `{uc-dir-name}` | The parent UC support dir, e.g. `UC-0KTg-collect-identity` |
| `{NNN}` | The task's zero-padded sequence number, from `T-NNN` (e.g. `001` for `T-001`) |
| `{entry-type}` | The driving-port kind named in the task prose (`http`, `graphql`, `event`, `cron`, `queue`, `service`, …). Must appear in the module's `Driving Ports` list in `specs/MODULES.md`. |
| `{task-slug}` | A short kebab-case name for the task's behavior, from the `T-NNN` heading |
| `{test-ext}` | Per-runner extension from `specs/TECH-STACK.md` Testing row or runner inference: `test.ts` (Vitest/Jest), `_test.py` (pytest), `_integration_test.go` (Go, with `//go:build integration`), `_spec.rb` (RSpec), etc. |

The UC ID is deliberately omitted from the filename — the parent directory already encodes it.
The `{entry-type}` segment makes the driving-port kind grep-discoverable across the test tree.

Molcajete generates **integration tests only** — tests driven through an entry point, covering a
task's behavior end to end. Host-project unit tests already in the repo are left where they are
and are not subject to this layout.

Build-time validation (owned by `/m:build`): refuse to dispatch a task if its `{entry-type}` is
missing from the module's `Driving Ports` list, if the module row in MODULES.md has no `Tests`
value, or if two tasks in the same UC resolve to the same canonical path.

## Status

The plan checkboxes are the task-level ledger. There is no slice status. `/m:build` flips
`## [ ] T-NNN` to `## [x] T-NNN` when a task passes verification, then writes UC status directly
from task completion and rolls Feature status up from its UCs. See the `status-rollup` skill.

## Worked Example

```markdown
# Plan: Onboarding — Identity & Contact (Phase 1)

Stand up the first phase of patient onboarding end to end: capturing a name, then a verified
phone number, so a new patient can complete step 1 and move on. Each task is a full-stack slice
of one behavior, not a layer.

**Specs:** FEAT-0Fy0-onboarding · UC-0KTg-collect-identity · SC-0KTg-01, SC-0KTg-02, SC-0KTg-03  ·  **Mode:** default

We're building against the `patient` module (`specs/features/patient/FEAT-0Fy0-onboarding/`).
The onboarding flow is a client wizard backed by an HTTP profile service; persistence is the
existing `profiles` store. Everything here rides the module's `http` driving port.

## [ ] T-001 — A patient submits their name and advances to step 2

**Covers:** SC-0KTg-01
**Depends on:** —

This closes SC-0KTg-01 of UC-0KTg. The heart of it is a new `setName` on the profile service in
`server/profile/setName.ts` — it trims and validates first and last name, rejects an empty last
name, and persists to the `profiles` store. Its shape:

​```ts
export function setName(profileId: string, first: string, last: string): Promise<Profile>
​```

We expose it as `POST /onboarding/name`, wired into `server/profile/router.ts`, and the
`NameStep` form in `web/onboarding/NameStep.tsx` posts there and advances the wizard in
`web/onboarding/flow.ts` on a 200. The integration test drives `POST /onboarding/name` and goes
green when a valid name persists and the response advances the flow, and when an empty last name
comes back `422`. We are deliberately not deduping names or handling mid-name edits yet — nothing
in the UC asks for it.

## [ ] T-002 — A patient adds a phone number and receives a verification code

**Covers:** SC-0KTg-02, SC-0KTg-03
**Depends on:** T-001

This closes SC-0KTg-02 (submit) and SC-0KTg-03 (verify), completing onboarding phase 1. Building
on T-001's profile, we add `startPhoneVerification` and `confirmPhoneCode` in
`server/profile/phone.ts`; the first stores a normalized E.164 number and dispatches a code
through the existing `SmsPort`, the second checks the code and marks the phone verified. Both
surface through `server/profile/router.ts` as `POST /onboarding/phone` and
`POST /onboarding/phone/verify`, and the `PhoneStep` in `web/onboarding/PhoneStep.tsx` walks the
patient through entry → code → confirmation.

The integration test drives both endpoints against a stubbed `SmsPort`: green when a submitted
number triggers exactly one send and stores the pending number, a correct code marks it verified
and finishes the flow, and a wrong code returns `401`. Trade-off: we cap verification at a fixed
attempt count rather than building rate-limiting infrastructure — the UC only calls for "reject a
wrong code."
```
