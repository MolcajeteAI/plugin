---
name: testing
description: >-
  Technology-agnostic rules for the test-first build loop. Defines the
  Implementer and Validator subagent roles, the test-then-code procedure,
  outer-edge mocking, the Five Exit Doors for component assertions, how
  to read prd/tech-stack.md for stack-specific runner and mocking choices,
  the coverage gate, reactive refactor rules, test naming, and the
  Test Subject vs. Observation Surface boundary.
---

# Testing

Authoritative testing rules for the default build flow. Loaded by `/m:build` on every task and referenced by the implementing skill. There is no separate BDD path; tests are written by the Implementer subagent and judged by the Validator subagent.

## When to Use

- Implementing a plan task via `/m:build` (every task loads this skill)
- Adding tests during a coverage-recovery task (`intent: cover`)
- Deciding what to mock and what to run for real
- Choosing what to assert when a component test could observe many things

## Two Subagent Roles

The build loop is owned by two agents in series. They have different responsibilities, different context, and different return shapes. The orchestrator (the `/m:build` command) trusts only the Validator.

### Implementer

**Responsibility:** for one behavior at a time, write the test, then write the production code in its final form to make the test pass.

**Context received:**
- The task description and architecture doc.
- The `Module` section of `prd/tech-stack.md` whose `Directory` contains the file under test.
- The current code state (read fresh; do not rely on a cached view).
- The list of behaviors already covered in this task (initially empty).
- Validator feedback from the previous round, if any.

**Procedure:**
1. Pick the next uncovered behavior named in the task description.
2. Write the test for that behavior first. The test file must be created or extended before any production-code edit in the same round. This file-creation order is the only enforcement of test-first discipline — the orchestrator verifies it by diffing the test-file set between rounds.
3. Write the production code in the form you believe is correct on the first pass. Do not write a hardcoded "minimum" stub and then refactor it; the Red-Green-Refactor middle step exists to give human authors a safety net and is not needed here.
4. Return: list of files changed, the behavior just covered, a brief note on what was done.

**The Implementer cannot finish the task.** It returns control after each behavior. The orchestrator decides whether to call it again.

### Validator

**Responsibility:** independently judge whether the test suite passes and coverage meets the project threshold.

**Context received:**
- The list of files changed by the Implementer in this round.
- The project's test command and coverage command (from `.molcajete/settings.json` `testing` or, when not present, the conventional command for the runner named in `prd/tech-stack.md` `Modules.{name}.Testing`).

The Validator does **not** see the Implementer's reasoning, notes, or self-assessment. The maker-checker boundary is the point of the split — if the Validator had the Implementer's context, it would inherit its blind spots.

**Procedure:**
1. Run the full project test command.
2. Run the project coverage command.
3. Return exactly one of:
   - `pass` — all tests green; coverage at or above the threshold.
   - `tests_failed{failures}` — list of failing tests with assertion messages.
   - `coverage_low{gaps}` — list of files and branches still uncovered, with line ranges where available.

A `pass` result is the only signal that lets the orchestrator move to the next behavior or close the task.

## Test-First Discipline

The test names the behavior before the code exists. That is the discipline TDD preserves. The Implementer enforces it by file order: test file is touched first in each round. If a round produces no new test path, the orchestrator treats it as a failure with the feedback "Implementer must write a test before production code."

Writing the production code in its final form on the first pass is not a relaxation of TDD. The Three Laws still hold: production code exists only to make a failing test pass. What is dropped is the requirement to write a throwaway implementation in between.

## Test Type Selection

| Test type | When to use |
|---|---|
| Unit | Leaf logic with no external collaborators — pure functions, value objects, formatters, parsers. |
| Component | Anything that crosses a boundary — HTTP handlers, GraphQL resolvers, service methods, repositories. The full internal stack runs for real; only the outer edge is replaced. This is the default for everything in an `Applications` row of `prd/tech-stack.md`. |
| Smoke | Optional. At the use-case edge when a full end-to-end probe is the cheapest way to verify wiring. Use sparingly. |

When in doubt, prefer the component test. A unit test that mocks half the system tells you the mocks work, not the system.

## Outer-Edge Mocking

Mock only what is outside the service boundary. Run everything inside it for real.

**Run for real:**
- Handler, controller, or resolver code.
- Service and domain layer.
- Repository or data-access layer (the application's own DB layer, not the database server).
- Request parsing, response serialization.
- Authorization, validation, middleware.

**Mock at the outer edge:**
- The network transport (outgoing HTTP to services you do not own).
- The database server (the driver/client calls, not your repository layer). Or use a real instance via testcontainers when the runner supports it.
- External APIs, email providers, payment processors.
- Time and randomness.

The principle is identical across stacks. The names differ; the rule does not.

## Five Exit Doors

For component tests, assert through one or more of these doors. Not every test needs all five — pick the ones that make the behavior observable.

1. **Response** — shape, status code, headers, body fields.
2. **State change** — what the data store now contains that it did not before.
3. **External calls** — outgoing requests made to the outer edge, with their payloads.
4. **Messages enqueued** — events emitted, jobs queued, messages published.
5. **Observability** — errors logged, metrics emitted, traces written.

Five Exit Doors is the inventory. The Implementer chooses which exits the current behavior should be visible through, asserts on those, and stops. Asserting on every door for every test is noise.

## Reading `prd/tech-stack.md`

The testing skill is technology-agnostic. The project's stack lives in `prd/tech-stack.md`. The Implementer reads the relevant `Module` section and uses it to choose runner, assertion library, and mocking tools.

**Procedure:**
1. Resolve the `Module` whose `Directory` contains the file under test. In a monorepo there will be multiple modules; pick the one whose `Directory` is a prefix of the file path.
2. Read the rows of that module:
   - `Testing` — the test runner and assertion library, when set. When blank, fall back to "Runner Inference" below.
   - `Framework` and `Key libraries` — the internal stack that must run for real.
   - `Services` (project-level) — owned infrastructure; mock at the client edge or run via testcontainers.
   - `External Services` (project-level) — third-party APIs; always mocked at the network boundary.
   - `Repository Structure` — when `monorepo`, scope reading to the module section above.
3. If `Framework` or `Key libraries` for the target module is missing or still contains template placeholder syntax (`{e.g., ...}`), **halt and report**. Do not guess these — they decide what must run for real. The fix is to re-run `/m:setup` and fill them in. The `Testing` row is the only exception: blank is fine and triggers inference.

**Mapping:**

| `prd/tech-stack.md` row | Runtime decision |
|---|---|
| `Modules.{name}.Testing` | Pick the test runner and assertion library from this row when filled; otherwise infer (see "Runner Inference" below). |
| `Modules.{name}.Framework`, `Modules.{name}.Key libraries` | Run these for real. Do not mock them. |
| Project-level `Services` | Mock at the driver edge, or run via testcontainers if the runner supports it. Never mock the application's own repository layer. |
| Project-level `External Services` | Always mock at the network boundary using the interceptor for this runner (e.g., `msw`, `nock`, framework-native). |
| Time, randomness | Mock via the testing framework named in `Modules.{name}.Testing`. |

## Runner Inference

When `Modules.{name}.Testing` is blank, infer the runner from one manifest read. This is the build loop's fallback and the default path — most projects don't need to pre-populate the row.

**Procedure:**

1. Resolve the module's `Directory` from `prd/tech-stack.md` and read the manifest:
   - JavaScript/TypeScript → `package.json`
   - Python → `pyproject.toml` (preferred), else `requirements*.txt`
   - Go → `go.mod`
   - Rust → `Cargo.toml`
   - Ruby → `Gemfile`
   - Java/Kotlin → `pom.xml` or `build.gradle{,.kts}`
2. Apply the inference table to the manifest's dependency list:

   | Manifest signals | Runner |
   |---|---|
   | `vitest` in devDependencies, or `vitest.config.{ts,js,mjs}` present | Vitest |
   | `jest` in devDependencies, or `jest.config.{ts,js}` present, or `package.json` `jest` key | Jest |
   | Bun runtime (`bun` engine, `bunfig.toml`) and no Vitest/Jest | `bun test` |
   | `@playwright/test` and no other runner | Playwright (treat as the runner) |
   | `pytest` in any Python manifest, or `pytest.ini`, or `[tool.pytest.ini_options]` | pytest |
   | `go.mod` exists | `go test` |
   | `Cargo.toml` exists | `cargo test` |
   | `rspec` in Gemfile | RSpec |
   | `org.junit.jupiter` in pom.xml/build.gradle | JUnit 5 |
   | TypeScript/JavaScript + Vite in deps and no test runner present | Vitest (best fit for the toolchain) |
   | TypeScript/JavaScript + React/Next/Express/NestJS and no test runner present | Jest (most widely supported) |
   | None of the above | Halt and ask the user via `AskUserQuestion` |

3. Two or more direct signals (e.g., both `jest` and `vitest` in devDependencies) → **ambiguous**. Do not pick; ask the user via `AskUserQuestion` with the candidate runners as options.

4. Cache the resolved runner on the in-memory loop state for this `/m:build` invocation. Do not write it back to `prd/tech-stack.md` unless the user explicitly asks for it.

The inference is cheap (one manifest read, no globbing) and accurate for the vast majority of projects. Pre-populating `Modules.{name}.Testing` only pays off when (a) the manifest is genuinely ambiguous, (b) the project uses a non-conventional wrapper command, or (c) a monorepo has mixed runners per module.

## Coverage Gate

The coverage threshold lives in `.molcajete/settings.json` under `testing.threshold` (default `80`).

**Coverage is scoped to the touched files** — the union of the task's `files_to_modify` and every file the Implementer has changed during the loop so far. The Validator never judges the whole project, only what this task touched. The orchestrator passes the touched set to the Validator on every round; the Validator runs the test and coverage commands with the touched-files scoping flags appropriate to the runner.

The Validator returns `pass` only when:
- The scoped test run is green.
- Per-file coverage on every touched file is at or above the threshold.

`coverage_low` returns the specific touched files and branches still uncovered. The Implementer uses that report to choose the next behavior — preferring branches whose addition exercises a real path rather than padding totals.

When a branch is genuinely unreachable (defensive code for an invariant that the type system already enforces, dead error handlers behind a `process.exit`, etc.), the right move is to delete it, not to add a vacuous test that asserts nothing. If the branch must stay, document why above it in a single short comment and use the runner's ignore directive scoped to that branch only.

The threshold is a floor, not a quality measure. A green coverage run with vacuous assertions is still a failure of intent, even when the Validator returns `pass`.

## Reactive Refactor

Restructuring is never a scheduled phase. Two situations make it appropriate:

1. **Validator feedback.** A `tests_failed` or `coverage_low` result whose fix requires changing the shape of existing code, not just adding lines. The Implementer restructures as part of the fix; the next Validator pass confirms the suite still works.
2. **Accommodating a later task.** While implementing task N, the Implementer finds that code written for task N-1 does not fit the new behavior — the abstraction is wrong, the seam is in the wrong place, or two cases need a shared shape that does not yet exist. Restructuring earlier-task code as part of completing the current task is correct. Do not reopen the earlier task; do not amend the plan.

If neither condition holds, do not restructure. Writing code in its final form on the first pass is the goal; restructuring solely because the code "could be cleaner" is out of scope.

## Test Naming

- Test names follow `when X then Y`. Example: `when the request body is missing email then the handler returns 400`.
- `describe` (or runner equivalent) blocks mirror the behavior hierarchy: subject under test → context → behavior.
- One assertion target per test. If a single test asserts on three of the Five Exit Doors, split it into one test per door so a failure points at the broken door.

## Test Subject vs. Observation Surface

A test has exactly one **subject** — the unit, component, or use case under test. The subject defines what the test "is about."

The **observation surface** — what the test asserts on — is everything the actor observes as a consequence of exercising the subject. The observation surface routinely spans more than the subject's own internals.

Example: a sign-up component test.

- The **subject** is the sign-up handler.
- The **observations** include: the account row is created, the user is redirected, a welcome notification is queued, and a confirmation email is enqueued for the email provider.
- The notification and the email are produced by code outside the sign-up handler — but the user sees them happen as a direct consequence of signing up.

Those cross-boundary observations belong in the sign-up test as `And` assertions on the relevant exit doors (state, messages enqueued, external calls). Omitting them leaves the behavior under-validated.

This is **not** testing the notifications feature or the email feature. Those have their own tests in their own files which exercise their internal behavior (retries, templating, rate limits) in isolation. The sign-up test only asserts on the user-visible consequence — that the email is enqueued, that the notification fires.

**Rules:**
1. One subject per test file.
2. Assert on cross-boundary side effects when they are observable consequences of the subject.
3. Describe the observation, not the implementation: assert "a welcome email is enqueued for `alice@example.com` with template `welcome`" — not "the email service's `sendTransactional` method is called with `template_id=42`."
4. Do not reach into the other feature's internals. The email feature's own tests assert retry and template behavior; the sign-up test only asserts the email was enqueued.
5. Do not duplicate across tests. A cross-boundary assertion belongs on the subject whose behavior produced it.
