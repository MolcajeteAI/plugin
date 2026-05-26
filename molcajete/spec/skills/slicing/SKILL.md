---
name: slicing
description: >-
  Decompose a use case into ordered, independently-executable slices.
  Owns the slice file format — one Markdown file per slice, holding the
  contract surface and the test plan as language-tagged snippets and nested
  bullets. Referenced by spec (forward) and reverse-spec (coverage) to emit
  the per-slice plans the harness consumes.
---

# Slicing

A **slice** is one vertical unit of work — a coherent, end-to-end piece of behavior that can be implemented and tested in isolation. The full slice set for a use case is a DAG: each slice declares the slices it depends on and the named exports it provides downstream.

Spec emits **one Markdown file per slice**, co-located with the parent UC. The harness loads one slice at a time and passes only that slice's file to the CodeWriter — payload stays small, slices stay independently runnable.

## Slice IDs

Slice IDs derive from the parent UC and a 3-digit sequence: **`{UC-id}-NNN`** (e.g., `UC-J10A-001`, `UC-J10A-002`).

- The UC ID itself is timestamp-based (base-62), so cross-UC collisions are impossible.
- Within a UC, NNN is assigned sequentially: `001`, `002`, `003`, …
- Cross-dev collisions only happen when two devs are adding slices to the same UC on parallel branches — git surfaces them at merge time.
- The spec command computes the next NNN by scanning existing files in the UC's `.slices/` folder and taking `max(NNN) + 1`.
- Slice IDs are short enough to type when launching a single slice (`molcajete build UC-J10A-003`) and self-describing — you see the UC the moment you read the ID.

Slice IDs are NOT generated via the base-62 `generate-id.js` script. That script is for entity-level IDs (FEAT, UC, SC, FR, NFR, US, ADR). Slices are an organizational layer below the UC and reuse the UC's ID as their root.

## Slice Objectives

Every slice carries one of two objectives. The objective is declarative — the harness picks the lifecycle from it.

- **`implement`** — Net-new behavior. The materialized scaffold tests must start RED. The CodeWriter writes production code until they turn GREEN. If the scaffold starts GREEN unexpectedly, the harness mutates the targeted files and expects RED — passing means the implementation already satisfies the slice; failing means the scaffold is vacuous.
- **`coverage`** — Test recovery on existing code. The materialized scaffold tests must start GREEN. The CodeWriter adds more assertions. The harness then mutates the targeted files and expects RED — that's the success condition. Used by `/m:reverse-spec` against shipped code.

The lifecycle (scaffold-write → RED/GREEN check → implement → GREEN check → mutation) is owned by the harness, not the slice file. The slice file declares **what** the slice is; the harness decides **how** to run it based on `objective`.

## What Spec Emits Per Use Case

```
prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/
├── UC-XXXX-{slug}.md
└── UC-XXXX-{slug}.slices/
    ├── UC-XXXX-001-{kebab-name}.md
    ├── UC-XXXX-002-{kebab-name}.md
    └── UC-XXXX-003-{kebab-name}.md
```

The DAG is implicit — every slice's `depends_on` field names the prior slice IDs it relies on. No separate index file. The parent feature's `ARCHITECTURE.md` is updated in the same spec pass (see the architecture skill's **Table Filling** rules).

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
files:
  create: [path/to/new-file]      # production files this slice creates
  modify: [path/to/existing-file] # production files this slice changes
depends_on: [UC-XXXX-NNN]         # prior slice IDs this slice relies on
provides: [namedExport]           # exports the slice publishes for downstream slices
test_file: path/to/test-file      # repo-relative path the CodeWriter writes the test scaffold to
covers: [SC-XXXX, FR-XXXX]        # scenarios and requirements this slice closes
last_update: YYYY-MM-DD
---
```

Field semantics:

- `id` — `{parent UC ID}-NNN`. Sequential within the UC.
- `name` — kebab-case label used in logs, branch names, and the filename.
- `objective` — `implement` or `coverage`. Picks the harness lifecycle.
- `files.create` — production files this slice introduces. Must not exist when an `implement` slice runs for the first time.
- `files.modify` — production files this slice changes. Must exist when the slice runs.
- `depends_on` — slice IDs whose `provides` exports this slice relies on. Cycles are illegal. The harness scheduler keeps a slice pending until every dependency reaches `implemented`.
- `provides` — named exports this slice publishes for downstream slices. The harness greps these out of the slice's source files and forwards just the signatures to dependents — never the full source.
- `test_file` — repo-relative path where the CodeWriter writes the actualized scaffold test file (translated from the Tests section).
- `covers` — `SC-XXXX` scenario IDs and `FR-XXXX` requirement IDs this slice closes. Every scenario in the UC must be covered by exactly one slice.

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

A nested-bullet test plan. Each leaf is one assertion. The CodeWriter translates this list into actual test code in the project's runner — top-level bullets become outermost `describe` blocks (or the runner-equivalent), nesting becomes nested `describe` blocks, leaves become `it` blocks with assertions.

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

## Slicing Rules

1. **One coherent behavior per slice.** A slice is "the thing that turns these scenario IDs green together." Don't bundle unrelated scenarios.
2. **Files are owned, not borrowed.** A file appears in at most one slice's `files.modify` or `files.create` per UC. If two slices both need to change the same file, merge them or split the file.
3. **Dependencies cross by exports, not by source.** Downstream slices receive only the `provides` list of upstream slices, never the upstream files' full source.
4. **Every scenario is covered exactly once.** Every `SC-` in the UC must appear in exactly one slice's `covers`. Same for `FR-` IDs.
5. **Order is topological.** A slice's NNN must be greater than every NNN it depends on.
6. **Granularity follows test seam.** A slice's Tests section is what gives it its boundary. If a single test file can validate the behavior end-to-end without cross-slice mocking, the granularity is right.

## Reverse (Coverage) Slicing

When emitted by `/m:reverse-spec` for existing code:

- `objective: coverage`.
- `files.create` is empty — coverage slices never introduce production files.
- `files.modify` lists the existing files whose uncovered behavior the slice tests.
- `provides` lists exports the slice's tests pin (used by the harness's mutation step to know what to perturb).
- The Tests section's leaves pin the current behavior with concrete assertions. The CodeWriter writes runner code matching those bullets; mutation then turns the tests RED to prove the assertions caught the perturbation.

## Template Reference

| Template | Purpose |
|----------|---------|
| [slice-template.md](./templates/slice-template.md) | One-slice file scaffold (frontmatter + Rationale + Contracts + Tests) |
