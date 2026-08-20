---
name: testing
description: >-
  Technology-agnostic rules for the test-first build loop. Implementer, Validator,
  and Reviewer role contracts, outer-edge mocking, reading specs/TECH-STACK.md,
  Runner Inference, coverage gate scoped to touched files, reactive refactor.
---

# Testing

Authoritative testing rules for the default build flow.

## Three Subagent Roles

The build loop runs three agents in series per task. The Validator's mechanical signal (green + coverage) and the Reviewer's correctness signal must **both** be positive before a task's checkbox flips.

### Implementer

For one behavior at a time: write the test first (file order is the only enforcement), then write production code in its final form to make it pass.

**Receives:** task description (the plan's `T-NNN` prose), architecture doc, the relevant `Module` section of `specs/TECH-STACK.md`, current code state, list of behaviors already covered, previous Validator/Reviewer feedback if any.

**Returns:** list of files changed, the behavior just covered, a one-line note.

The Implementer cannot mark a task done.

### Validator

Runs the project's test command and the coverage command, independently of the Implementer. This is a **mechanical** check — it proves the tests are green and the coverage floors are met, and (with the mutation step) that the tests are not vacuous. It does **not** judge whether the implementation is correct.

**Receives:** files changed this round; the resolved test + coverage commands; the threshold.

**Returns:** exactly one of `pass`, `tests_failed{failures}`, or `coverage_low{gaps}`.

Does not see the Implementer's reasoning. Maker–checker boundary.

### Reviewer

Judges **correctness** — whether the implementation actually does what the spec says, not merely whether its own tests pass. A separate agent from the Implementer (maker–checker), reading the UC spec independently of the test's assertions.

**Receives:** the owning UC spec body (the `SC-XXXX` scenarios in the task's `Covers`, verbatim); the task's `Covers` list and grading prose; the final integration test file; the final production files the task touched. It does **not** receive the Implementer's reasoning.

**Verifies:**

1. **Meaningful assertions** — each covered `SC-XXXX` has at least one assertion pinning a user-observable exit (response/status, persisted state, an external call/message, an observable side effect), not vacuous line coverage.
2. **Right expectation** — the asserted expected values match what the scenario says must happen. The Reviewer derives the expected behavior from the spec itself and flags any assertion that pins a value the spec does not call for.
3. **Real implementation** — production code genuinely implements every covered scenario; no stub, `TODO`, `FIXME`, `not implemented`, or hard-coded return that only satisfies the fixture.
4. **No missing scenario** — every scenario in `Covers` is addressed in the test, and in the code for every kind except `cover`.

**Returns:** exactly one of `correct`, `defects{list}`, or `spec_defect{list}`.

`defects{list}` — the spec is right and the work does not match it. Each defect names the `SC-XXXX`, the file, and what is wrong. This sends the task back to the Implementer; it is never resolved by placating the Reviewer superficially — the fix must satisfy the spec.

`spec_defect{list}` — **the spec itself is the problem.** Each item names the `SC-XXXX` (or the behavior that has no `SC-XXXX`), and states whether the spec is *wrong* (it specifies behavior that is incorrect or contradicts a sibling scenario) or *silent* (the code must handle a case no scenario covers). Return this only when changing the code or the test cannot resolve the finding, because the spec is what they would have to satisfy.

The distinction matters because the two results go to different places. `defects` loops back to the Implementer. `spec_defect` reaches the orchestrator's adaptation path, where the spec is edited and a task is added — the Reviewer cannot edit a spec and must not try. Without this third value a Reviewer that finds a wrong spec has only `defects`, which sends the Implementer to fix code that was already right.

## Test-First

Test file is created or extended before any production-code edit in the same round. The orchestrator diffs the test-file set between rounds and rejects rounds with no new test path.

Write production code in its final form on the first pass. No throwaway-minimum-then-refactor middle step.

## Integration Tests Only

Integration-tests-only is Principle 1 (`principles` skill) — that section is canonical for what Molcajete does and does not generate, and for how pre-existing host unit tests are treated.

Operationally: the integration test is the contract for the task's scenarios. Where the contract cannot be economically exercised through the driver port, the task's design is wrong — either the seam or the scenario. Escalate; do not fall back to a unit test.

## Outer-Edge Mocking

Principle 2 sets the boundary. Applied to a build round: run for real — handlers, services, domain layer, repositories, validation, serialization. Mock at the outer edge only — network transport you don't own, the database driver (or use testcontainers), third-party APIs, time, randomness.

## Assertions

Assert on the user-observable consequences of the subject — response, state changes, outgoing calls, queued messages, logged errors. Pick what's meaningful per behavior; don't enumerate.

Cross-boundary effects the subject *causes* (welcome email enqueued, downstream event fired) belong on this subject's tests. Assert on the observation, not the producer's internals.

One assertion target per test. Split if a single test would assert on three independent things.

## Reading `specs/TECH-STACK.md`

Resolve the `Module` whose `Directory` contains the file under test. Use its rows:

- `Testing` — runner and assertion library, when set. When blank, fall back to Runner Inference below.
- `Framework`, `Key libraries` — must run for real.
- Project-level `Services` — mock at the driver edge or run via testcontainers.
- Project-level `External Services` — always mock at the network boundary.

If `Framework` or `Key libraries` is missing or templated for the target module, halt and report. The `Testing` row is the only exception — blank is fine and triggers inference.

## Runner Inference

When `Modules.{name}.Testing` is blank, read the module's manifest once and pick a runner.

| Manifest signal | Runner |
|---|---|
| `vitest` in devDependencies, or `vitest.config.*` | Vitest |
| `jest` in devDependencies, or `jest.config.*`, or `package.json` `jest` key | Jest |
| Bun runtime (`bunfig.toml`) and no Vitest/Jest | `bun test` |
| `@playwright/test` and no other runner | Playwright |
| `pytest` in any Python manifest, or `pytest.ini`, or `[tool.pytest.ini_options]` | pytest |
| `go.mod` exists | `go test` |
| `Cargo.toml` exists | `cargo test` |
| `rspec` in Gemfile | RSpec |
| `org.junit.jupiter` in pom.xml / build.gradle | JUnit 5 |
| TS/JS + Vite, no test runner present | Vitest (best fit) |
| TS/JS + React / Next / Express / NestJS, no test runner present | Jest |
| None of the above | Halt and ask the user |

Two or more direct signals (e.g., Jest AND Vitest in devDeps) → ambiguous; ask the user.

When halting to ask, follow `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` — the evidence goes in the brief, not the question:

- Brief: list the runner signals found and where each came from (manifest field, config file, lockfile), so the user can see why it is ambiguous.
- Question: "Which test runner should I use?"
- Header: "Runner"
- Options: one per detected candidate

Cache the resolution on the in-memory loop state for this invocation; do not write back to `specs/TECH-STACK.md` unless asked.

### Scoped command shapes

For touched-files coverage, use the runner's per-file flag:

| Runner | Scoped test | Scoped coverage flag |
|---|---|---|
| Vitest | `npx vitest run {paths}` | `--coverage --coverage.include={src}` (repeat per file) |
| Jest | `npx jest {paths}` | `--coverage --collectCoverageFrom={src}` (repeat per file) |
| pytest | `pytest {paths}` | `--cov={module_or_dir}` (repeat) |
| go test | `go test {pkgs}` | `-cover -coverpkg={pkgs}` |
| cargo | `cargo test {filter}` | `cargo llvm-cov --include-files {src}` if available |

## Coverage Gate

The gate is **four-dimensional**: lines, statements, branches, and funcs. The floor for each comes from `.molcajete/settings.json`:

```json
{
  "testing": {
    "thresholds": {
      "lines": 80,
      "statements": 80,
      "branches": 80,
      "funcs": 80
    }
  }
}
```

**Backwards compatibility.** If `testing.threshold` (singular, a single number) is set and `testing.thresholds` (plural, the object) is not, apply the single number to all four dimensions. If both are present, the plural object wins. `/m:build` upgrades a legacy single-number setting on first read (Step 3) by writing the expanded form back without changing behavior.

Coverage is **scoped to the touched files** — the union of the files the task's prose names (create + modify) and every file the Implementer has changed during the loop. The Validator never judges the whole project.

`pass` requires: scoped test run green AND, for every touched file, every one of the four dimensions at or above its floor. A file with lines at 100% but branches at 66% does NOT pass.

`coverage_low` lists per-touched-file gaps **per dimension**, with concrete locations:

- Uncovered line ranges (for the `lines` / `statements` dimensions).
- Uncovered branches with the conditional location (file:line and the condition text).
- Uncovered functions by name.

### Gap classification (build-time)

For every gap reported by the runner, the Implementer must classify it before resolving:

1. **Reachable behavior** — the gap maps to an `SC-XXXX` in the UC spec that the current test plan does not assert (or asserts only the happy path). **Resolution: add the missing test case.** If the new assertion belongs to a scenario not yet in the task's `Covers` list, add the corresponding `SC-XXXX` to the task's `Covers` in the plan file.
2. **Defensive / unreachable** — the gap is a branch or function that cannot be reached from any specified scenario (typical examples: `if (!input) throw` guards on internal calls, default switch arms, error paths that the type system already forbids). **Resolution: delete the code.** If the code must stay for runtime safety, scope the runner's ignore directive to that branch only with a one-line comment that names the reason and links back to where the guarantee comes from.
3. **Orphaned assertion / dead behavior** — a test case, assertion, comment, or production path that serves an `SC-`/`FR-`/`NFR-` no longer present in the current UC spec (typically because `/m:fix` or `/m:change` retired it). **Resolution: delete it** — the test case, its explanatory comment, and the now-dead production code together. This is proactive cleanup per Principle 1.5, not coverage padding: never keep the code alive by asserting the retired behavior is gone.

**Raising the floor is never a resolution.** The thresholds are a minimum bar; the goal under "every line fulfills a requirement" is to be close to 100% on every dimension. If the model is tempted to lower the floor, the gap is one of the two cases above — pick one.

The Implementer prefers branches whose addition exercises a real path over padding totals — every test added in case 1 must come from a UC scenario, not a contrived input designed to clip a branch.

## Reconciling Changed Behavior

When a task's owning UC changed via `/m:fix`, `/m:change`, or `/m:spec` (the UC is `dirty`), the existing canonical test file (and its production code) may now describe behavior the spec no longer contains. Before adding or adjusting any assertion, reconcile the file against the **current** UC spec:

- Diff the UC's current `SC-`/`FR-`/`NFR-` set against the IDs the existing test file references (in the task's `Covers`, in `// SC-XXXX:` comments, and in the assertions themselves).
- **Retired IDs** — delete their test cases, their explanatory comments, and the production code that existed only to serve them (per Principle 1.5 and the "Orphaned assertion / dead behavior" gap class).
- **Changed IDs** — rewrite the assertion to the new expected values; do not keep the old expectation alongside.
- **New FR / behaviorally-observable NFR** — add a positive test case that asserts the new behavior directly.

Do **not** convert a retired scenario into a test that asserts it now fails or is absent. A removed behavior leaves no test behind — only the changelog records that it once existed.

## Reactive Refactor

Restructure only when:

1. Validator feedback requires it (the fix isn't additive — shape is wrong), or
2. A later task's behavior doesn't fit the shape of earlier-task code; reshape as part of the current task.

Don't reshape just because the code "could be cleaner." Writing in final form on the first pass is the goal.

When the task is a coverage-recovery task (description names uncovered paths in existing code), touch production only when the seam is untestable (e.g., outer-edge client constructed internally with no injection point); reshape the minimum needed.

## Test Naming

`when X then Y`. Describe blocks (or runner equivalent) mirror the behavior hierarchy.

## Where Integration Tests Live

Test files are placed at a canonical path derived from the task's owning UC and `specs/MODULES.md`. The agent does not pick the path — it is computed. See the plan-authoring skill's "Test File Convention" for the formula and the build command's task-validation step for validation.

The canonical layout is a **dedicated tests tree keyed by module**, mirroring the spec tree module → feature → UC test. The `Tests` column of each module's row in `specs/MODULES.md` names this tree (typical values: `server/tests/{module}`, `tests/{module}`, `packages/{module}/tests`). **Integration tests do not live inside module source directories** — that would mix behavior tests with implementation code and break the "grep the tests tree to find every test for a feature" property.

Pre-existing unit tests in the repo are left exactly where they are — Molcajete does not migrate, delete, or reason about them.

## Keeping the File Organized

A UC's canonical test file accumulates tests across every task and fix that ever touches it — it is never rewritten from scratch. When adding to an existing file, do not append new test blocks at the end by default. Find the `describe`/context block for the scenario or behavior area the new tests belong to and insert alongside it; open a new block only when the tests genuinely start a new behavior area the file doesn't yet cover. When a task or fix adds tests for a scenario that already has a block, extend that block in place rather than opening a second one elsewhere in the file.

The goal: the file reads as one coherent map of the UC's behavior, grouped by what it tests, not as a chronological log of when each task ran. Keeping it that way is part of writing the test, not a follow-up cleanup pass.
