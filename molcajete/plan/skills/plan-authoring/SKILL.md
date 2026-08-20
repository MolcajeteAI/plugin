---
name: plan-authoring
description: >-
  Owns the plan file format. One prose Markdown plan per /m:plan invocation,
  written as a single file at specs/plans/<timestamp>-<slug>.md. Decomposes a use case
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

## Filing and Plan IDs

`/m:plan` writes exactly one file per invocation — a single Markdown file, not a folder:

```
specs/plans/<YYYYMMDDTHHMMSS>-<slug>.md
```

- **Plan ID = a UTC timestamp to the second**, ISO compact: `20260727T143052`. Second-level
  granularity is the finest the ID carries — do not attempt sub-second precision.
- `-<slug>` is a short kebab-case descriptor (max 40 chars) derived from the pending work's
  reasons (e.g. `add-email-verification`, `fix-409-on-duplicate`). It is for humans; the
  timestamp is the identity.
- The plan lives under `specs/` because a plan is part of the recorded change history of the
  application — not a throwaway build artifact. It is tracked in git.
- The plan ID is the filename without the `.md` extension (`<YYYYMMDDTHHMMSS>-<slug>`); `/m:build` resolves it to `specs/plans/<plan-id>.md`.
- Every `/m:plan` invocation creates a **new** file. Never amend an existing plan file.

## Plan File Structure

A plan has a title, a one- or two-line summary, a `**Specs:**` line, a `**Prerequisites:**`
line, a `**Provenance:**` line, an optional short context paragraph, and then one
`## [ ] T-NNN` section per task.

```markdown
# Plan: {Descriptive Name}

{One or two sentences: the working capability this plan delivers, and why.}

**Specs:** FEAT-XXXX-{slug} · UC-XXXX-{slug} · SC-XXXX, SC-YYYY  ·  **Mode:** implement | cover | mixed
**Prerequisites:** —
**Provenance:** UC-XXXX v{n} ({entry-timestamp}) · UC-YYYY v{n} ({entry-timestamp})

{Optional short paragraph of shared context — what we're building and the slice of the
architecture it touches. Reference the spec files once here (`specs/features/{module}/
FEAT-XXXX-{slug}/…`) so no task has to repeat them.}

## [ ] T-001 — {User-visible behavior, stated as an outcome}

**Kind:** implement
**Covers:** SC-XXXX, SC-YYYY
**Depends on:** —

{Prose — see "Task Prose" below.}

## [ ] T-002 — {Next behavior}

**Kind:** implement
**Covers:** SC-ZZZZ
**Depends on:** T-001

{Prose.}
```

The `**Specs:**` line names every FEAT and UC the plan touches plus the scenarios in scope,
and a `**Mode:**` label summarizing the plan. The label is **derived from the task kinds**, so
it never states anything the tasks do not already say:

| Mode | When |
|------|------|
| `cover` | every task has `**Kind:** cover` |
| `implement` | no task has `**Kind:** cover` |
| `mixed` | at least one task of each |

The label is a human summary. Per-task truth is the task's own `**Kind:**` field — that is what
`/m:build` dispatches on. A plan written before the `**Kind:**` field existed carries
`**Mode:** default`; read `default` as a synonym for `implement`.

The `**Prerequisites:**` line is **mandatory and always present**. It names work that must be
done **outside this plan** before `/m:build` may start, or `—` when there is none. It uses the
same empty value as `Depends on` at the task level, and it has a different scope.

| Field | Points at | How `/m:build` checks it |
|-------|-----------|--------------------------|
| `Depends on` | a task inside this plan | reads the upstream task's checkbox |
| `Prerequisites` | work no task in this plan does | it cannot check. It asks the user, then records that it did not verify. |

**The line has exactly one writer.** The coverage step in **Producing a Plan** writes a value other
than `—`, and only when the user answers "Handle separately" to the test-coverage question. Nothing
else may write it — no other step, no other command, and no finding made while the plan is drafted.

**A cross-spec consequence is not a prerequisite.** Work that another spec needs because of this
plan is either a task in this plan, or a sign that the spec is not finished. If a plan cannot run
without work that is not a task in it, the plan is not ready to be written: resolve the work first
under the `resolution-gate` skill — category `C13` — then write the plan.

Write one clause per item. Name the file and the canonical test path it needs:

```markdown
**Prerequisites:** Canonical integration coverage for `src/auth/session.ts` and
`src/auth/token.ts` (`tests/FEAT-0A1b-auth/UC-0KTg-sign-in.test.ts`)
```

### The Provenance line

The `**Provenance:**` line records the spec state the plan was written against. A plan is a
reading of the specs at one moment, and a later `/m:fix`, `/m:change`, or `/m:spec` can move the
specs underneath it. Without this line nothing can tell a current plan from a stale one, so
`/m:build` executes a drifted plan as confidently as a fresh one.

One clause per use case in scope, `·`-separated:

```markdown
**Provenance:** UC-0KTg v4 (20260616T141530) · UC-3Z2L v2 (20260614T090012, 20260614T090012)
```

| Part | Value |
|------|-------|
| `UC-XXXX` | the use case ID, matching the `**Specs:**` line |
| `v{n}` | the `version` in that UC spec's frontmatter, read at plan-write time |
| `({timestamps})` | the timestamps of the `pending` changelog entries this plan consumed for that UC, comma-separated |

For a UC that spans several module-instances, record one clause per instance and name the module:
`UC-3Z2L@auth v2 (…)`. The versions can differ per instance, and a drift check that reads only
one of them misses the other.

The line is written once, by P6, and is never edited afterward. It states what was true when the
plan was written, so amending it would destroy the only evidence drift detection has. A plan
written before this field existed carries no such line; `/m:build` skips the drift check and says
so in its report.

## Task Shape

Every task is a level-2 heading carrying a checkbox, then three fields, then prose:

```markdown
## [ ] T-NNN — {outcome phrased as a user-visible behavior}

**Kind:** implement | change | fix | cover
**Covers:** <comma-separated SC-/FR- IDs>
**Depends on:** <comma-separated T-NNN IDs, or —>

{prose}
```

- **Checkbox** — `## [ ] T-NNN` is pending; `## [x] T-NNN` is done. This checkbox is the
  build's status ledger. There is no status frontmatter anywhere else.
- **T-NNN** — plan-local task ID, `T-001`, `T-002`, … assigned in dependency order. Numbering
  crosses FEAT/UC boundaries — there is one `T-NNN` sequence per plan.
- **Kind** — the work this task does, one of four values. See Task Kind below. This is the field
  `/m:build` dispatches on; it decides whether the first test run must be RED or GREEN, whether
  the task may write production code, and whether it may delete code for a retired scenario.
- **Covers** — a **comma-separated list** of the `SC-XXXX` scenario IDs (and `FR-XXXX`
  requirement IDs) this task closes.
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
   the module's `Driving Ports` column in `specs/MODULES.md`.
4. **How we prove it** — what the integration test drives and what "green" means: the concrete,
   user-observable outcomes that must hold. This is the source the build scaffolds the test from.
5. **Decisions and trade-offs** — key choices, what the task deliberately does *not* do, and the
   limitation each choice carries. Everything in this field is already settled: scope the spec
   does not ask for, and trade-offs the user accepted. The field never holds a decision still to
   be made. An unsettled trade-off is an unresolved item, so put it to the user before you write
   the plan (see the `resolution-gate` skill) and record the answer here. A decided default
   belongs here — write the value, the reason for it, and the fact that the user chose it. An
   open question never enters a plan.

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
4. **Order is dependency order.** A task's NNN is greater than every task it depends on.
5. **Files are owned, not shared.** A production file should be created/modified by at most one
   task in the plan. If two tasks both need to change the same file, either merge them or make one
   depend on the other so the edits are sequenced.
6. **Granularity follows the test seam.** If one integration test can validate the behavior end to
   end, the task is the right size. Split a task only at a genuine logical boundary — or when it
   would not fit a single ~200k-token build context. Splitting to isolate a layer is never valid.

## Task Kind

`**Kind:**` carries the work a task does. It takes one of four values, and the values match the
four spec commands, so a task's origin stays legible in the plan.

| Kind | Written when | First test run | Production code | Retires scenarios |
|------|--------------|----------------|-----------------|-------------------|
| `implement` | The spec asks for behavior the code does not have. | RED | writes new code | no |
| `change` | The spec now states different behavior for code that already ships. | RED | modifies existing code | yes — deletes the tests and code of every `SC-` the UC retired |
| `fix` | The spec is already right and the code does not match it. | RED | corrects existing code | no |
| `cover` | The code already ships and nothing asserts it. | GREEN | none | no |

`/m:build` reads this field directly. Nothing about the kind is inferred from prose.

**One plan holds tasks of different kinds.** This is the point of the field. A plan that changes
a use case may open with a `cover` task that pins the code it is about to touch, follow with a
`fix` task for a defect that surfaced while pinning it, and close with the `change` tasks that
were the original objective. The plan's `**Mode:**` label summarizes whatever mix results.

**Ordering across kinds.** When tasks of different kinds touch the same behavior, order them
`cover`, then `fix`, then `change` or `implement` — pin what ships, correct what is broken, then
change it. Give the earlier kinds the lower `T-NNN`.

**Distinguishing `fix` from `change`.** Both act on shipped code, and the spec decides which.
When the spec already states the behavior you want, the task is a `fix`. When the spec had to be
edited to state it, the task is a `change`. This is the same three-way diagnosis `/m:fix` runs,
and the `spec-revision` skill owns it.

**Writing a `cover` task.** Word it as a characterization test: it records what the code does
now, not what it should do, so a surprising current behavior is pinned rather than corrected. The
build's mutation step then proves the assertions have teeth. When the code has no seam the
integration test can drive, say so in the prose and include the mechanical seam work in the task
— a `cover` task may move a dependency behind a port, and it still adds no new behavior.

## Test File Convention

Integration test files are placed at a **canonical path derived from the task's owning UC and
`specs/MODULES.md`** — never declared in the plan, never chosen ad hoc. The layout mirrors the
spec tree **module → feature → use case test** so any reader can grep the tree by feature or UC
and find the integration test that pins its behavior:

```
{module.Tests}/{feature-dir-name}/{uc-dir-name}.{test-ext}
```

| Token | Resolution |
|-------|-----------|
| `{module.Tests}` | The `Tests` column of the module's row in `specs/MODULES.md` (set by `/m:setup`). Integration tests live in a dedicated tests tree, not inside module source dirs. |
| `{feature-dir-name}` | The task's parent feature dir under `specs/features/{module}/`, e.g. `FEAT-0Fy0-onboarding` |
| `{uc-dir-name}` | The parent UC's ID and slug, e.g. `UC-0KTg-collect-identity` — this is the test file's own name, not a subdirectory |
| `{test-ext}` | Per-runner extension from `specs/TECH-STACK.md` Testing row or runner inference: `test.ts` (Vitest/Jest), `_test.py` (pytest), `_integration_test.go` (Go, with `//go:build integration`), `_spec.rb` (RSpec), etc. |

One test file per UC: every task that closes scenarios in that UC — whether from the UC's
original plan or a later `/m:fix`/`/m:change` plan — targets this same file, appending to it
rather than producing a new one.

Molcajete generates **integration tests only** — tests driven through an entry point, covering a
task's behavior end to end. Host-project unit tests already in the repo are left where they are
and are not subject to this layout.

Build-time validation (owned by `/m:build`): refuse to dispatch a task if its `{entry-type}` is
missing from the module's `Driving Ports` list, or if the module row in MODULES.md has no `Tests`
value.

## Status

`/m:build` flips `## [ ] T-NNN` to `## [x] T-NNN` when a task passes verification, then writes UC
status directly from task completion and rolls Feature status up from its UCs. See the
`status-rollup` skill.

## Producing a Plan

This is the shared procedure for turning a set of in-scope `pending` changelog entries into a
written plan. `/m:plan` runs it over the pending entries it reads; `/m:fix` and `/m:change` run it
over the entries they just wrote. The caller has already: resolved the UC module-instances in
scope, read their `UC-XXXX-{slug}.md` specs, each feature's `REQUIREMENTS.md` and
`ARCHITECTURE.md`, and written the `pending` entries. The caller must have loaded the `architecture`, `principles`, and `uc-log`
skills (and, only when cover-mode entries are possible, `reverse-engineering`).

**P1 — Assign a kind to each in-scope entry.** Every pending entry names the command that wrote
it, and that command sets the kind of the tasks the entry produces:

| Entry | Task kind |
|-------|-----------|
| `command:cover` | `cover` |
| `command:change` | `change` |
| `command:fix` | `fix` |
| `command:spec` | `implement` |

A single plan may consume entries of every command at once, and the resulting plan carries tasks
of every kind. Nothing here refuses a mixed set.

The mode is **derived**, not chosen: read it off the task kinds per the table in Plan File
Structure. Because P4 can add `cover` tasks, derive the mode at the end of P4 and write that
value — any value computed earlier is provisional.

**P2 — Architecture pass.** Apply the engineering principles: Principle 2 (hexagonal default),
Principle 3 (DI), Principle 1 (every task's tests are integration tests — never scaffold unit tests).

Run the pass over the kinds present, not over the mode label:

- **For `implement`, `change`, and `fix` work** — design or revise the architecture for the
  affected UCs: identify driving/driven ports (driver ports come from `specs/MODULES.md`'s
  `Driving Ports`), adapters, domain boundaries, and cross-cutting work (migrations, shared
  adapters, config); wire through DI. Reflect the design into each feature's `ARCHITECTURE.md`
  per the architecture skill's Table Filling rules.
- **For `cover` work** — skip design; reconstruct the shipped structure with the
  reverse-engineering skill and ensure each `ARCHITECTURE.md` reflects what actually ships.
- **When both are present** — run the cover pass first, so the current design is the baseline,
  then design the new behavior on top. Reflect both into `ARCHITECTURE.md`.

This step designs; it does not ask. The review gate that presents the architecture, the
decomposition, and the test-coverage disposition together runs in **P4**, after the tasks exist
and after the coverage decision is made. Hold the architecture direction until then.

**P3 — Decompose into tasks.** Per the Vertical-Increment Rules above, produce the minimal ordered
list of vertical, working-software tasks that closes every in-scope scenario exactly once, ordered
by dependency (that order is the `T-NNN` sequence). Write each task per the Task Shape (heading +
`Kind` + `Covers` + `Depends on` + prose), giving each task the kind P1 assigned to the entry it
serves, and apply the Task Kind ordering rule wherever two kinds touch the same behavior.

**P4 — Probe test coverage, then run the plan gate.** The P3 task list names the files, so the
probe runs here and never earlier. The probe is **static**: `/m:plan` runs no commands and never
runs a test suite. Read and grep only.

1. **Collect the file set.** Every production file the P3 tasks name as created or modified.
2. **Drop every file the plan creates.** A file that does not exist yet cannot have coverage.
3. **Resolve the module.** For each remaining file, find the module in `specs/MODULES.md` whose
   `Directory` prefixes the path, then read that module's `Tests` column. A file under no module
   row is **unmapped** — report it in the gate brief, do not ask about it, and do not count it as
   uncovered.
4. **Derive the canonical test path** per the Test File Convention above, using the owning UC of
   the task that touches the file.
5. **Grep the tests tree.** Read the file, list its exported symbols, and grep those symbols
   against the module's `Tests` tree. This is the pattern the `change-review` skill uses to map a
   changed file to what asserts it.
6. **Classify each file.** A file is **covered** when a file under the module's `Tests` tree
   asserts at least one of its exported symbols, and you can name that test file and that symbol.
   Otherwise it is **uncovered**.

**Judge against `{module.Tests}` only, and be strict.** Principle 1 is explicit: pre-existing
host-project unit tests are ignored, and the floor is met by integration tests only. A
`src/foo.test.ts` beside `src/foo.ts` is not coverage. A test outside `{module.Tests}` is not
coverage. When you cannot name the asserting file and the asserted symbol, the file is uncovered.

**When the uncovered set is empty**, write `**Prerequisites:** —` and go to the plan gate below.

**When the uncovered set is not empty, ask once — once per plan, never once per file.** A
per-file loop turns a five-file plan into five interrogations.

- Brief: name the plan and recap what P3 decomposed, because the user has not been holding this
  context. Table the uncovered files: file, module, owning UC, and the canonical test path each
  one would get. Under "Add coverage to this plan": one coverage task per uncovered file, or per
  cohesive group of files under one UC, placed at the lowest `T-NNN`; those tasks write tests
  only and no production code; the mode becomes `mixed`; the plan gets longer. Under "Handle
  separately": the plan is written as decomposed, and a `**Prerequisites:**` line names the
  coverage work; `/m:build` cannot verify that work, so it asks the user to confirm it before any
  task runs and records that it could not check. Recommend "Add coverage to this plan". Close
  with the escape-hatch line.
- Question: "Some files this plan changes have no integration test coverage. How should I handle it?"
- Header: "Coverage"
- Options: "Add coverage to this plan" / "Handle separately"

Two options. Never add a third. A third option is how a build stops halfway.

**On "Add coverage to this plan".** Emit one task per uncovered file, or per cohesive group of
files under one UC, each carrying `**Kind:** cover`. Give them the lowest `T-NNN` values and
renumber the P3 tasks upward; the Task Kind ordering rule already requires `cover` tasks before
the tasks that change the same behavior. Write each one per Task Kind's rule for a `cover` task.
Write `**Prerequisites:** —`. Re-derive the mode from the final task kinds.

**On "Handle separately".** Write no coverage tasks and keep the P3 numbering. Write the
`**Prerequisites:**` line naming the canonical coverage each uncovered file needs, with its
canonical test path. The mode does not change.

**Then run the plan gate.** Present the architecture and the decomposition **before writing the
plan** — this is the review gate that catches a wrong interpretation before any code is built. It
runs here, after the tasks exist and after the coverage decision, so the user reviews the final
task list instead of one this step is about to change. Per the asking-questions skill, the
direction is the brief and the gate is a one-sentence ask:

- Brief: write the full direction as Markdown, in sections — the test-coverage classification
  from the probe (covered, uncovered, unmapped) and the disposition the user chose; the numbered
  architecture decisions, one line of rationale each; the `ARCHITECTURE.md` table changes; the
  canonical test path; the plan's `**Prerequisites:**` line; and a table of tasks with the
  scenarios and requirements each covers plus the files it touches, coverage tasks included.
  Recommend "Proceed". Close with the escape-hatch line.
- Question: "Proceed to write the plan?"
- Header: "Plan gate"
- Options: "Proceed" / "Edit" / "Cancel"

The direction goes in the brief, never in `question` and never in an option `preview` — a preview
pane truncates, and the direction is identical under every option, so it is shared context. On
"Edit", the user's correction arrives via the built-in `Other`. On "Cancel", write nothing.

**P5 — Consult non-canonical tests.** Skip when no task in the plan has `**Kind:** cover`. For each UC with a
`command:cover` pending entry, read its `CHANGELOG.md`, find the most recent `command: cover` entry,
and collect the **non-canonical test file paths** it recorded (existing tests touching the UC's
production code that live outside the canonical tests tree). For each, prompt once:

- Brief: name the test file and the UC it overlaps, say what it currently covers, and spell out
  what each of the three dispositions means for `/m:build`. Recommend "Reference-only".
- Question: "What should /m:build do with `{path}`?"
- Header: "Test file"
- Options: "Reference-only" / "Migrate" / "Ignore"

**"Reference-only"** (default — build reads it, lifts fixtures/setup/assertions, leaves it in
place) / **"Migrate"** (same, plus build prompts to delete the original after the canonical test
verifies) / **"Ignore"** (build never opens it). For each non-ignored decision, name the file in the
prose of the task whose behavior overlaps it, with the mode inline — e.g. "consult
`src/legacy/foo.test.ts` (reference)" or "(migrate — delete after the canonical test is green)".
This step never moves or deletes files.

**P6 — Write the plan.** Pick a kebab-case slug (max 40 chars) from the entries' reasons. Write a
**new** single file `specs/plans/<YYYYMMDDTHHMMSS>-<slug>.md` (UTC timestamp to the second) per the
Plan File Structure above — summary, `**Specs:**` line (with the mode), `**Prerequisites:**` line,
`**Provenance:**` line, optional context paragraph, and one `## [ ] T-NNN` section per task.

Build the `**Provenance:**` line here, per The Provenance line above. For every UC in scope, read
the `version` from the frontmatter of the `UC-XXXX-{slug}.md` the caller already loaded, and list
the timestamps of the entries P7 is about to stamp. Read the version from the spec file — never
carry a value forward from an earlier step, because P2 may have edited `ARCHITECTURE.md` and
another command may have written the UC since the caller read it.

**P7 — Stamp the changelog.** For every consumed entry, use the `uc-log` skill to flip its status
`pending → dirty` and set `plan:<plan-id>` (the folder name). The entry stays under `TODO:`; the
`modules:` token, if present, is preserved. Multi-module UCs have one CHANGELOG per module-instance,
each updated independently.

The procedure does **not** touch UC or Feature frontmatter `status` — that is owned by the
spec-phase command (which writes `dirty` when it edits a previously-`implemented` UC) and by
`/m:build` (which writes it from task completion).

## Worked Example

```markdown
# Plan: Onboarding — Identity & Contact (Phase 1)

Stand up the first phase of patient onboarding end to end: capturing a name, then a verified
phone number, so a new patient can complete step 1 and move on. Each task is a full-stack slice
of one behavior, not a layer.

**Specs:** FEAT-0Fy0-onboarding · UC-0KTg-collect-identity · SC-0KTg-01, SC-0KTg-02, SC-0KTg-03  ·  **Mode:** implement
**Prerequisites:** —
**Provenance:** UC-0KTg v1 (20260727T142140)

We're building against the `patient` module (`specs/features/patient/FEAT-0Fy0-onboarding/`).
The onboarding flow is a client wizard backed by an HTTP profile service; persistence is the
existing `profiles` store. Everything here rides the module's `http` driving port.

## [ ] T-001 — A patient submits their name and advances to step 2

**Kind:** implement
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
comes back `422`. This task does not dedupe names and does not handle mid-name edits. UC-0KTg
specifies neither behavior, so both stay out of scope for this plan.

## [ ] T-002 — A patient adds a phone number and receives a verification code

**Kind:** implement
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
and finishes the flow, and a wrong code returns `401`. Trade-off, accepted by the user:
verification stops after 5 attempts on one number, instead of full rate-limiting infrastructure,
because UC-0KTg asks only for "reject a wrong code". The limit is a constant in
`server/profile/phone.ts`.
```
