---
name: slicing
description: >-
  Decompose a use case into ordered, independently-executable slices.
  Owns the slice file format — one Markdown file per slice, holding the
  contract surface and the test plan as language-tagged snippets and nested
  bullets. Referenced by /m:plan (default and cover modes) to emit the
  per-slice files the build consumes.
---

# Slicing

A **slice** is one vertical unit of work — a coherent, end-to-end piece of behavior that can be implemented and tested in isolation. The full slice set for a use case is a DAG: each slice declares the slices it depends on and the named exports it provides downstream.

`/m:plan` emits **one Markdown file per slice**, co-located with the parent UC. The build loop loads one slice at a time and passes only that slice's file to the CodeWriter — payload stays small, slices stay independently runnable.

## Slice IDs

Slice IDs derive from the parent UC and a 3-digit sequence: **`{UC-id}-NNN`** (e.g., `UC-J10A-001`, `UC-J10A-002`).

- The UC ID itself is timestamp-based (base-62), so cross-UC collisions are impossible.
- Within a UC, NNN is assigned sequentially: `001`, `002`, `003`, …
- Cross-dev collisions only happen when two devs are adding slices to the same UC on parallel branches — git surfaces them at merge time.
- `/m:plan` computes the next NNN by scanning existing `SLICE-NNN-*.md` files in the UC's support folder and taking `max(NNN) + 1`.
- Slice IDs are short enough to type when launching a single slice and self-describing — you see the UC the moment you read the ID.

Slice IDs are NOT generated via the base-62 `generate-id.js` script. That script is for entity-level IDs (FEAT, UC, SC, FR, NFR, US, ADR). Slices are an organizational layer below the UC and reuse the UC's ID as their root.

## Slice Objectives

Every slice carries one of two objectives. The objective is declarative — the harness picks the lifecycle from it.

- **`implement`** — Net-new behavior. The materialized scaffold tests must start RED. The CodeWriter writes production code until they turn GREEN. If the scaffold starts GREEN unexpectedly, the harness mutates the targeted files and expects RED — passing means the implementation already satisfies the slice; failing means the scaffold is vacuous.
- **`coverage`** — Test recovery on existing code. The materialized scaffold tests must start GREEN. The CodeWriter adds more assertions. The harness then mutates the targeted files and expects RED — that's the success condition. Used by `/m:plan` in `mode: cover` against shipped code.

The lifecycle (scaffold-write → RED/GREEN check → implement → GREEN check → mutation) is owned by the harness, not the slice file. The slice file declares **what** the slice is; the harness decides **how** to run it based on `objective`.

A single plan may carry slices of both objectives when it is emitted in `mode: mixed` (a UC has pending changelog entries from both `/m:cover` and `/m:spec` / `/m:fix` / `/m:change`). The harness still dispatches per slice on `objective` — no new lifecycle. The plan's `T-NNN` ordering guarantees coverage slices run before implement slices so existing behavior is pinned before it is changed.

## What Plan Emits Per Use Case

Each UC has two artifacts at the feature level: the UC spec file `UC-XXXX-{slug}.md` (sibling of REQUIREMENTS / USE-CASES / ARCHITECTURE) and a support folder `UC-XXXX-{slug}/` (sibling of the spec file). The folder contains `CHANGELOG.md` and the slice files. Slice filenames are `SLICE-NNN-{kebab-name}.md`.

```
specs/features/{module}/FEAT-XXXX-{slug}/
├── REQUIREMENTS.md
├── USE-CASES.md
├── ARCHITECTURE.md
├── UC-XXXX-{slug}.md
└── UC-XXXX-{slug}/
    ├── CHANGELOG.md
    ├── SLICE-001-{kebab-name}.md
    ├── SLICE-002-{kebab-name}.md
    └── SLICE-003-{kebab-name}.md
```

The DAG is implicit — every slice's `depends_on` field names the prior slice IDs it relies on. No separate index file. The parent feature's `ARCHITECTURE.md` is updated in the same plan pass (see the architecture skill's **Table Filling** rules).

## Slice File Schema

A slice file has YAML frontmatter, a level-1 heading, and four sections: Rationale, Contracts, Tests, plus the trailing dependency check (which the harness uses, not the human reader).

### Frontmatter

```yaml
---
id: UC-XXXX-NNN
name: kebab-case-name
use_case: UC-XXXX
feature: FEAT-XXXX
objective: implement              # implement | coverage
status: pending                   # pending | dirty | implemented — first-class state per the status-rollup skill
files:
  create: [path/to/new-file]      # production files this slice creates
  modify: [path/to/existing-file] # production files this slice changes
depends_on: [UC-XXXX-NNN]         # prior slice IDs this slice relies on
provides: [namedExport]           # exports the slice publishes for downstream slices
entry_type: http                  # driving-port kind this slice tests (must be in MODULES.md Driving Ports for the module)
covers: [SC-XXXX, FR-XXXX]        # scenarios and requirements this slice closes
references:                       # optional — existing non-canonical tests to consult when scaffolding the canonical integration test
  - path: src/legacy/foo.test.ts
    mode: reference               # reference | migrate
last_update: YYYY-MM-DD
---
```

Field semantics:

- `id` — `{parent UC ID}-NNN`. Sequential within the UC.
- `name` — kebab-case label used in logs, branch names, and the slice filename (`SLICE-NNN-{name}.md`).
- `objective` — `implement` or `coverage`. Picks the harness lifecycle.
- `status` — `pending` | `dirty` | `implemented`. The slice's runtime state, written by `/m:plan` (initial value) and `/m:build` (on successful completion). This is the **only** runtime state on the slice file — `.molcajete/slices/{id}.json` is kept as a durable build outcome record for diagnostics but is not consulted for status decisions. See the `status-rollup` shared skill for the full semantics and roll-up rule.
- `files.create` — production files this slice introduces. Must not exist when an `implement` slice runs for the first time.
- `files.modify` — production files this slice changes. Must exist when the slice runs.
- `depends_on` — slice IDs whose `provides` exports this slice relies on. Cycles are illegal. The harness scheduler keeps a slice pending until every dependency reaches `status: implemented` in its frontmatter.
- `provides` — named exports this slice publishes for downstream slices. The harness greps these out of the slice's source files and forwards just the signatures to dependents — never the full source.
- `entry_type` — the driving-port kind this slice's tests drive (e.g., `http`, `graphql`, `event`, `cron`, `queue`, `service`, or any project-specific kebab-case value). The value MUST appear in the `Driving Ports` list of the slice's module row in `specs/MODULES.md`. The build halts if the value is unknown to the module.
- `covers` — `SC-XXXX` scenario IDs and `FR-XXXX` requirement IDs this slice closes. Every scenario in the UC must be covered by exactly one slice.
- `references` (optional) — list of existing non-canonical test files that `/m:build` should consult when scaffolding this slice's canonical integration test. Only appears when `/m:plan` runs in `mode: cover` and the developer accepted an entry from the `/m:cover`-produced "Non-canonical Test Paths" list. Each entry has:
  - `path` — the source path of the existing test file (relative to the repo root).
  - `mode` — one of `reference` (default: `/m:build` reads the file, lifts fixtures/setup/assertions patterns into the new canonical test, leaves the original in place) or `migrate` (after 8.9 verification succeeds, `/m:build` prompts to delete the original file since its content now lives at the canonical path).

The slice's test file path is **not** declared here — it is derived from frontmatter and `specs/MODULES.md`. See the "Test File Convention" section below.

### Body Structure

```markdown
# {ID}: {Slice Name}

## Rationale

One paragraph: what this slice does, why it exists, which scenarios it closes. Plain prose, no implementation detail.

## Contracts

The locked surface for this slice. Three flavors — use whichever apply, skip the rest. Pinned at spec time so independent slice runs stay consistent. The CodeWriter implements against them; it does not design them.

### Types

Data shape declarations in the project's contract language. Types only — no implementation, no runtime values.

```{contract-lang}
{type declarations: TypeScript interfaces, Python TypedDict/Protocol, Go interfaces, JSON schemas, etc.}
```

### API Surface

Functions, endpoints, or message handlers this slice exposes. One row per public entry point.

For function-shaped APIs:

| Name | Signature | Auth | Notes |
|------|-----------|------|-------|
| `registerUser` | `(input: RegisterInput) => Promise<RegisterResponse>` | none | duplicate email returns 409 |

For HTTP routes:

| Method | Path | Request | Response | Status codes |
|--------|------|---------|----------|--------------|
| POST | `/auth/register` | `RegisterInput` | `RegisterResponse` | 201, 409, 422 |

For event handlers / messages, use a column set that fits the project's transport.

### Behavior

Pre/postconditions and invariants — bullets, not code. The CodeWriter treats these as inviolable.

- **Preconditions:** what must hold before any `provides` export is called
- **Postconditions:** what holds after a successful call
- **Invariants:** what must always hold while this slice's code runs
- **Error modes:** named failure cases downstream slices can rely on

## Tests

A nested-bullet test plan. Each leaf is one assertion. The CodeWriter translates this list into actual test code in the project's runner — top-level bullets group tests by scenario (rendered as outermost `describe` blocks or the runner-equivalent), nesting becomes nested `describe` blocks, leaves become `it` blocks with assertions.

**Names are descriptive; IDs live in comments.** Use a behavior-describing name for every `describe` block and `it` test (never the spec ID). Place the spec ID and a short description in a **leading-line comment** above each block per Principle 1.2 in `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md`. The slice's `covers:` frontmatter array is the canonical machine-readable mapping from slice to scenarios; the comments are for humans.

- **SC-XXXX: {scenario name}**
  - Given {context setup}
    - When {action}
      - Then {expected outcome / assertion}
      - And {additional assertion}
  - Given {different context}
    - When {action}
      - Then {expected outcome}
- **FR-XXXX: {requirement label}**
  - {top-level assertion that ties to the requirement}
```

The structure is BDD-flavored without invoking any BDD tooling. There is no `.feature` file, no Gherkin parser — the bullets are just Markdown that the CodeWriter turns into runner code.

## Test File Convention

Integration/component test files are placed at a **canonical path derived from slice frontmatter and `specs/MODULES.md`** — never declared in the slice file, never chosen by the agent at slice authoring time. The path is a pure function of existing fields. The layout mirrors the spec tree **module → feature → use case → slice test** so any reader can grep the tree by feature or UC and find every integration test that pins its behavior:

```
{module.Tests}/{feature-dir-name}/{uc-dir-name}/{NNN}-{entry-type}-{slice-name}.{test-ext}
```

| Token | Resolution |
|-------|-----------|
| `{module.Tests}` | The `Tests` column of the module's row in `specs/MODULES.md`. Set per-module by `/m:setup`. Typical values are a dedicated tests tree keyed by module (e.g. `server/tests/{module}`, `tests/{module}`, `packages/{module}/tests`) — **integration tests live in a dedicated tests tree, not inside module source directories**. |
| `{feature-dir-name}` | The slice's parent feature dir under `specs/features/{module}/`, e.g. `FEAT-0Fy0-user-onboarding` |
| `{uc-dir-name}` | The slice's parent UC support dir (a sibling of the UC spec file inside the feature dir), e.g. `UC-0KTg-register` |
| `{NNN}` | The zero-padded sequence number portion of the slice's `id` (e.g., `001` for `UC-0KTg-001`) |
| `{entry-type}` | The slice's `entry_type` frontmatter value — the driving-port kind whose surface this slice's tests drive (e.g., `http`, `graphql`, `event`, `cron`, `queue`, `service`). Must appear in the module's `Driving Ports` list in `specs/MODULES.md`. |
| `{slice-name}` | The slice's frontmatter `name` (kebab-case) |
| `{test-ext}` | Per-runner extension from `specs/TECH-STACK.md` Testing row or runner inference: `test.ts` (Vitest/Jest), `_test.py` (pytest), `_integration_test.go` (Go, with `//go:build integration` build tag), `_spec.rb` (RSpec), etc. |

The UC ID is **deliberately omitted** from the filename because the parent directory already encodes it. The full slice ID is always reconstructable as `{parent-uc-id}-{NNN}`.

The `{entry-type}-` segment makes the driving-port kind grep-discoverable across the test tree without fragmenting features into separate directories. To find every integration test driven by GraphQL: `find {module.Tests} -name '*-graphql-*.test.*'`. To find every event-handler test: `find {module.Tests} -name '*-event-*.test.*'`. To find every test for a feature: walk to `{module.Tests}/{FEAT}/`.

Worked examples:

| Project | Path |
|---------|------|
| TS/Vitest HTTP route slice | `tests/auth/FEAT-0Fy0-user-onboarding/UC-0KTg-register/001-http-validate-email.test.ts` |
| TS/Vitest event-handler slice | `tests/auth/FEAT-0Fy0-user-onboarding/UC-0KTg-register/003-event-fanout-welcome.test.ts` |
| Python/pytest cron slice (monorepo) | `packages/auth/tests/FEAT-0Fy0-user-onboarding/UC-0KTg-register/004-cron-cleanup-unverified_test.py` |
| Go service-driven slice (dedicated tests tree) | `server/tests/orderbook/FEAT-TSEG-in-memory-clob/UC-TSEH-place-limit-order/001-service-limit-order-matching_integration_test.go` (uses `//go:build integration` tag and black-box `{module}_test` package) |

Molcajete only generates **integration tests** (tests driven through an entry point, covering a slice's contract end-to-end). The canonical layout applies to every test file Molcajete writes. Any host-project unit tests already in the repo are left where they are and are not subject to this layout.

Build-time validation: the build command computes the derived path and refuses to dispatch if (a) frontmatter contains a stray `test_file:` line that disagrees with the derived path, (b) the slice's `feature` or `use_case` frontmatter doesn't match its parent feature/UC directory, (c) two slices in the same UC resolve to the same canonical path, (d) `entry_type` is missing or not present in the module's `Driving Ports` list in `specs/MODULES.md`, or (e) the module row in MODULES.md has no `Tests` value.

## Slicing Rules

1. **One coherent behavior per slice.** A slice is "the thing that turns these scenario IDs green together." Don't bundle unrelated scenarios.
2. **Files are owned, not borrowed.** A file appears in at most one slice's `files.modify` or `files.create` per UC. If two slices both need to change the same file, merge them or split the file.
3. **Dependencies cross by exports, not by source.** Downstream slices receive only the `provides` list of upstream slices, never the upstream files' full source.
4. **Every scenario is covered exactly once.** Every `SC-` in the UC must appear in exactly one slice's `covers`. Same for `FR-` IDs.
5. **Order is topological.** A slice's NNN must be greater than every NNN it depends on.
6. **Granularity follows test seam.** A slice's Tests section is what gives it its boundary. If a single test file can validate the behavior end-to-end without cross-slice mocking, the granularity is right.
7. **Coverage before implement in mixed plans.** In a `mode: mixed` plan, coverage slices added by the plan are assigned lower `NNN` than implement slices added by the plan within the same UC. The plan's `T-NNN` list follows the same order so the build's ascending walk pins existing behavior before writing new behavior. The rule applies only to slices this plan writes; slices already on disk keep their existing NNN.

## Reverse (Coverage) Slicing

When emitted by `/m:plan` in `mode: cover` for existing code:

- `objective: coverage`.
- `files.create` is empty — coverage slices never introduce production files.
- `files.modify` lists the existing files whose uncovered behavior the slice tests.
- `provides` lists exports the slice's tests pin (used by the harness's mutation step to know what to perturb).
- The Tests section's leaves pin the current behavior with concrete assertions. The CodeWriter writes runner code matching those bullets; mutation then turns the tests RED to prove the assertions caught the perturbation.

## Template Reference

| Template | Purpose |
|----------|---------|
| [slice-template.md](./templates/slice-template.md) | One-slice file scaffold (frontmatter + Rationale + Contracts + Tests) |
