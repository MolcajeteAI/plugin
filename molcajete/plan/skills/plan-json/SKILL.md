---
name: plan-json
description: >-
  The machine plan contract. Defines the change directory under specs/changes/,
  the plan.json schema, the decomposition rules that turn an applied change
  request into tasks, and the four operations that are the only permitted plan
  mutations (complete, insert, revise, append). Loaded only by the CLI's
  planning session and executor — never by an authoring command. No human
  reviews a plan: it optimizes for unambiguous execution, not readability.
---

# plan.json — The Machine Plan

The plan is JSON, written by the CLI's planning session at execution start, mutated by the executor as the run learns, and never reviewed by a human. The human reviews contracts — the change request, the interfaces, the data — and reads the decision record after the run. The plan is not a review surface.

## The Change Directory

One directory per change, under the spec tree:

```
specs/changes/
└── {change-id}/                # e.g. 20260823T104500-order-expiry
    ├── request.md              # written at authoring — what the human reviews
    ├── plan.json               # written by the CLI at execution start
    ├── decisions.md            # what the run decided alone — created on first entry
    ├── validation/             # reviewer findings, one file per cycle
    └── report.md               # written when the run ends
```

- The `{change-id}` is `{timestamp}-{slug}`: an ISO 8601 compact UTC timestamp (`YYYYMMDDTHHMMSS`) from the clock, a hyphen, and a short kebab-case slug of the change. The authoring command creates the directory and the ID when it writes `request.md`.
- The change directory is the only thing that crosses the authoring–execution boundary. Authoring writes `request.md` and stops. The CLI writes everything else.
- The plan ID equals the change ID. One change, one plan, one run branch (`change/{change-id}`).

## Schema

```jsonc
{
  "plan": "20260823T104500-order-expiry",   // = the change ID
  "created": "2026-08-23T10:45:00Z",        // from the clock, never composed
  "specs": ["FEAT-9KC2-order-expiry", "UC-9KC2@orders"],
  "provenance": [                            // the changelog entries this plan consumes
    { "useCase": "UC-9KC2@orders", "version": 3, "entries": ["20260823T103012"] }
  ],
  "budget": {
    "maxTasks": 40,            // 0 = unlimited (resource ceiling)
    "maxSpendUsd": 25.00,      // 0 = unlimited (resource ceiling)
    "maxValidationCycles": 3,  // 0 = no reviewer (action count)
    "maxTaskRetries": 3
  },
  "tasks": [
    {
      "id": "T-001",
      "round": 1,              // 1 = authored; 2+ = appended by a reviewer cycle
      "done": false,
      "outcome": "Open orders older than 30 days expire and release their reserved funds",
      "kind": "code",          // test | code
      "origin": "spec",        // spec | change | fix | cover — the changelog link
      "covers": ["SC-9KC2-01", "SC-9KC2-02", "NFR-9KC2-01"],
      "examples": ["E-001"],   // request examples this task turns into fixtures or assertions
      "retires": [],           // scenario IDs this task may delete tests and code for
      "dependsOn": [],
      "useCase": "UC-9KC2@orders",
      "feature": "FEAT-9KC2-order-expiry",
      "module": "orders",
      "entryType": "event",
      "files": { "create": ["server/orders/expiry.ts"], "modify": ["server/orders/router.ts"] },
      "provides": ["expireOrders"],
      "interface": ["expireOrders"],   // INTERFACE.md rows this task adds or changes
      "rationale": "Expiry runs on the order.expiry.tick event. Trade-off accepted at design time: a scan bounded by an index on placed_at, not a per-order timer.",
      "contracts": "export function expireOrders(asOf: Date): Promise<number>",
      "grading": "Drive order.expiry.tick against seeded orders: one older than 30 days expires and its reservation is released through the accounts interface; a 29-day order is untouched; the count returned equals the rows transitioned in order_events.",
      "audit": []
    }
  ],
  "knownIssues": []
}
```

The template is `templates/plan-template.json` in this skill. Fill it; never compose the shape from memory.

### Field semantics

| Field | Meaning |
|---|---|
| `id` | `T-NNN`, sequential in authoring order. Never reused, never renumbered. |
| `round` | The main-loop cycle that authored the task. The planning session writes round 1. A reviewer cycle appends round N+1. |
| `done` | The one status field. `true` only after the task passed validation and merged. A `done` task is frozen — never revised, re-tagged, or removed. |
| `outcome` | The user-visible behavior the task makes real, stated as an outcome. |
| `kind` | Dispatch enum. `code`: write the integration test at the entry point, then write production code until it passes, in one session. `test`: write assertions that pin what ships, and touch no production code. |
| `origin` | The changelog link: the `command:` token of the entry this task serves. `spec` and `change` and `fix` produce `code` tasks; `cover` produces `test` tasks. |
| `covers` | Scenario and requirement IDs this task closes. Machine-readable — bare IDs, no links. |
| `examples` | `E-NNN` tags from the request. The builder turns each one into a fixture or an assertion carrying the example's exact values. An example no test asserts is a verification finding. |
| `retires` | The explicit, checkable list of scenario IDs whose tests and code this task may delete. Empty for every task that retires nothing. Deletion permission lives here and nowhere else. |
| `dependsOn` | Task IDs that must be `done` before this task runs. |
| `useCase` | `UC-XXXX@{module}` — the module-instance the task belongs to. |
| `entryType` | The interface element kind the test drives: the module's entry point for this behavior. |
| `files` | The task's full write footprint — production files and the UC's canonical test file, `create` plus `modify`. The scheduler runs two tasks concurrently only when their footprints are disjoint, so an incomplete footprint causes merge conflicts. |
| `provides` | Exported symbols the task introduces. The mutation check replaces each one with a throw and expects the impacted tests to fail. |
| `interface` | The INTERFACE.md element rows this task adds or changes. Updating those rows is part of the task. |
| `rationale` | Prose: the why, the trade-offs accepted at design time. Notes from the request flow here. |
| `contracts` | Prose: the exact signatures the task exposes. |
| `grading` | Prose: how the verification judges the task done — observable behavior, exact values, never implementation detail. |
| `audit` | Append-only history of `insert` and `revise` operations that touched this task. |

## Decomposition Rules

The planning session holds the applied specs, the request, and the touched modules' INTERFACE.md and DATA.md when it decomposes. The rules:

1. **One coherent behavior per task.** A task is "the thing that makes these scenarios real together." Do not bundle unrelated scenarios.
2. **Work across the layers, never within one.** Slice by behavior, not by layer. Every task leaves working software.
3. **Every scenario is covered exactly once.** Every `SC-` (and every requirement a task claims) appears in exactly one task's `covers`.
4. **Every example is assigned.** Every `E-NNN` tag in the request appears in at least one task's `examples`. An example is never wasted.
5. **Order is dependency order.** A task's NNN is greater than every task it depends on.
6. **Footprints are minimized, not merely declared.** Two tasks that write the same file never run concurrently, so shared files serialize the plan. Prefer decompositions where footprints are disjoint. When two tasks must touch one file, sequence them with `dependsOn`.
7. **Granularity follows the test seam.** If one integration test can validate the behavior end to end, the task is the right size. Split only at a genuine logical boundary. Splitting to isolate a layer is never valid.
8. **Retirement is explicit.** A task may delete tests or code only for the scenario IDs in its `retires` list. The request marks retired scenarios; the planner populates the list; the executor checks it.
9. **Notes flow into rationale.** Every note in the request reaches the `rationale` of the tasks that implement its change. A note is an instruction to the run, not decoration.
10. **The budget is honored at authoring.** More tasks than `maxTasks` (when nonzero) is a planning failure, not a runtime surprise — decompose coarser or report the change as too large.

## The Four Operations

The executor never rewrites the plan freehand. Four operations, nothing else:

| Operation | When | Effect |
|---|---|---|
| `complete` | A task passes validation | `done: true` on one task |
| `insert` | A discovery needs work before an incomplete task | New tasks in the same round, `audit` entry on the affected task, decision recorded |
| `revise` | An incomplete task is wrong | Rewrite its fields, append to its `audit`, decision recorded |
| `append` | A reviewer cycle produces work | New tasks at the end, next `round` number |

Invariants:

- A `done` task is never revised, re-tagged, or removed.
- `audit` is append-only.
- Only the CLI process writes `plan.json`. Task sessions report results; the orchestrator applies them.
- Every `insert` and `revise` pairs with a `decisions.md` entry. The plan says what changed; the decision record says why.

## Serialization

The plan is serialized deterministically: fixed key order (the order in the schema above), two-space indent, one field per line. A `done` flip is then a one-line git diff, and the plan's history reads in `git log -p` like a ledger.

## Who Loads This Skill

The CLI's planning session and executor only. No authoring command loads it — authoring thinks in contracts, and only the executor thinks in tasks. `/m:spec`, `/m:change`, `/m:fix`, and `/m:cover` emit no plan and know nothing of this schema.
