---
description: Execute a plan — run the TDD red/green/mutation lifecycle plus a correctness review for one or more tasks in a prose plan.
model: claude-sonnet-5
argument-hint: "<plan-id> [T-NNN ...] [--commit]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
---

# Build Command

`/m:build` executes a plan produced by `/m:plan`. It walks the tasks the user named, runs the TDD lifecycle for each, verifies the implementation is actually correct (not merely green), updates the plan checkboxes, and flips the corresponding log entries to `implemented`.

The plan's `**Mode:**` label (`default`, `cover`, or `mixed`) is a summary. The authoritative per-task dispatch reads whether the task is an **implement** task or a **coverage** task from its prose (see the plan-authoring skill's "Task Objectives"):

- **implement task** — writes production code across the layers the task names, plus an integration test. Test starts RED, ends GREEN.
- **coverage task** — writes an integration test only. **No production code.** The test starts GREEN (it pins behavior that already ships) and the mutation step proves the assertions have teeth.

A `mode: mixed` plan contains both kinds; coverage tasks carry lower `T-NNN` and run first, pinning existing behavior before implement tasks change it.

Molcajete generates **integration tests exclusively** per Principle 1 of the engineering principles. `/m:build` never scaffolds unit tests.

**Committing is opt-in.** Each task is a logical commit boundary. Without `--commit`, `/m:build` writes no git state at all — the user reviews the output and commits it. With `--commit`, each task that passes every gate is committed on the current branch as it passes. A task that fails commits nothing.

**Arguments:** $ARGUMENTS

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

**Writing style:** every document you write and every message you print uses Simplified Technical English. Every one carries only what its reader needs. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/shared/skills/output-economy/SKILL.md` before writing.

## Step 1: Parse Arguments

`$ARGUMENTS` carries:

1. A plan ID as the first token. Required. Format: `YYYYMMDDTHHMMSS-<slug>` (the plan file's name under `specs/plans/`, without the `.md` extension — the plan is `specs/plans/<plan-id>.md`).
2. Zero or more task IDs, each `T-NNN`. When no task ID is given, the run covers **every unfinished task in the plan**.
3. An optional `--commit` modifier, in any position among the tokens. Strip it before you read the plan ID and the task IDs. It makes each task that passes every gate its own commit (8.11).

Examples:

- `/m:build 20260616T141530-add-checkout` — every unfinished task, in `T-NNN` order
- `/m:build 20260616T141530-add-checkout T-001` — one task
- `/m:build 20260616T141530-add-checkout T-001 T-002 T-003` — a named subset
- `/m:build 20260616T141530-add-checkout --commit` — every unfinished task, each one committed

If `$ARGUMENTS` is empty or missing a plan-id, list available plans:

```
ls specs/plans/
```

Then tell the user:

> "Usage: `/m:build <plan-id> [T-NNN ...]`. Available plans: {list of plan file names, without `.md`}."

Stop.

If the plan-id does not resolve to a file `specs/plans/<plan-id>.md`, refuse with the available list and stop.

When `--commit` is set, check the repository before anything else runs — a commit that cannot happen must fail here, not halfway through the plan:

```
git rev-parse --git-dir
git rev-parse --abbrev-ref HEAD
```

If the first command fails, stop with: "`--commit` needs a git repository. This directory is not one." Carry the branch name to the Step 6 gate. Do not act on it here — this command never creates a branch and never pushes.

## Step 2: Load Skills and Principles

Read:

1. `${CLAUDE_PLUGIN_ROOT}/plan/skills/plan-authoring/SKILL.md` — plan file format, task shape, and Test File Convention.
2. `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md` — Implementer / Validator / Reviewer roles, runner inference, outer-edge mocking, coverage gate.
3. `${CLAUDE_PLUGIN_ROOT}/shared/skills/uc-log/SKILL.md` — CHANGELOG mechanics only.
4. `${CLAUDE_PLUGIN_ROOT}/shared/skills/status-rollup/SKILL.md` — how to write UC status and roll up Feature.
5. `${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/SKILL.md` — **Immutability** section. This command writes `SC-XXXX` IDs into task `Covers` lists and into test-file comments. It copies existing IDs verbatim and never generates, renumbers, or alters one.
6. **Only when `--commit` is set** — `${CLAUDE_PLUGIN_ROOT}/shared/skills/git-committing/SKILL.md` — message format, style detection, the spec-references block, and the no-attribution rule. A run without the modifier does not read it.
7. **Engineering principles.** Read `.claude/rules/principles.md` from the host project — this is the operative version of the principles. If the host file is missing, read `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md` instead and emit a one-line warning to the user: "No host principles file found at `.claude/rules/principles.md`. Using plugin defaults. Run `/m:setup` to generate the host file." Every code edit, test scaffold, correctness review, and refactor in this command must respect these principles.

## Step 3: Verify Prerequisites

1. `specs/PROJECT.md`, `specs/MODULES.md`, and `specs/TECH-STACK.md` must exist AND be read in full now. If any is missing: "Project foundation not found. Run `/m:setup` first." Stop.
2. Ensure `.molcajete/settings.json` exists and resolves to four per-dimension coverage floors (`lines`, `statements`, `branches`, `funcs`):
   - If the file does not exist, create `.molcajete/` and write:
     ```json
     {"testing": {"thresholds": {"lines": 80, "statements": 80, "branches": 80, "funcs": 80}}}
     ```
     Tell the user: "Initialized `.molcajete/settings.json` with default `testing.thresholds = 80` on every dimension. Edit it to change the coverage gate."
   - If the file has `testing.thresholds` (plural, object), use those four values directly. Any missing dimension defaults to 80.
   - If the file has the legacy `testing.threshold` (singular, number) and no `testing.thresholds`, **upgrade in place**: expand the single number to all four dimensions, write back, and tell the user: "Upgraded `.molcajete/settings.json` `testing.threshold = N` to per-dimension `testing.thresholds` (lines/statements/branches/funcs all = N). Edit individual dimensions to tighten the gate."
   - If the file has neither, merge in the default object and write it back.

## Step 4: Load the Plan

1. Read `specs/plans/<plan-id>.md`.
2. Parse:
   - **The `**Specs:**` line** — the FEAT and UC IDs the plan touches, the scenarios in scope, and the `**Mode:**` label.
   - **The `**Prerequisites:**` line** — work that must be done outside this plan before any task runs. `—` means none. A plan written before this field existed carries no such line; treat a missing line as `—`. Carry the parsed value to Step 6. Do not act on it here.
   - **Each task** — every `## [ ] T-NNN — {outcome}` (or `## [x] T-NNN`) heading, its `**Covers:**` list, its `**Depends on:**` list, and the task prose beneath it up to the next `## ` heading.
3. Build an in-memory task index: `T-NNN → { outcome, covers, depends_on, done (checkbox state), prose }`.
4. Select the tasks to execute:
   - **`$ARGUMENTS` carries no task ID** → mark every task whose checkbox is `[ ]`, in `T-NNN` ascending order. A task already `[x]` is skipped, so a re-run resumes the plan where the last run stopped. If no task is `[ ]`, tell the user "Plan `{plan-id}` has no unfinished tasks — nothing to do." and stop.
   - **`$ARGUMENTS` carries one or more task IDs** → for each one:
     - `T-NNN` → mark it for execution.
     - Unknown task ID → refuse with: "Task `{id}` is not in plan `{plan-id}`. Available tasks: {list}." Stop.

## Step 5: Load Upstream Context

For every task marked for execution, resolve the **owning UC** of its `Covers` scenarios: glob `specs/features/*/FEAT-*/UC-*.md` (the UC spec is a sibling of `REQUIREMENTS.md`, not inside the `UC-*/` support folder) and find the UC spec whose scenarios include the task's `SC-XXXX` IDs (cross-check against the `**Specs:**` line). The feature folder is the UC spec's parent feature dir. Read upstream context for ALL touched FEATs and UCs before Step 8:

For every touched FEAT:

- `<feature-folder>/REQUIREMENTS.md`
- `<feature-folder>/ARCHITECTURE.md`
- `<feature-folder>/USE-CASES.md`

For every touched UC:

- `<feature-folder>/UC-XXXX-{slug}.md` (the UC spec body, a sibling of `REQUIREMENTS.md` — the scenarios are the behavioral source of truth).

**Missing upstream file (hard halt).** If any derived path is missing on disk, halt with:

> Upstream context missing for {FEAT-XXXX | UC-XXXX}: `<path>`. Run `/m:spec` (for spec files) or `/m:setup` (for project foundation) before re-running `/m:build`.

This is a hard gate — the loaded UC scenarios (`SC-XXXX`) and the feature's `ARCHITECTURE.md` component boundaries govern every test assertion, production-code decision, and correctness judgment in Step 8.

## Step 6: Present the Build Plan

This is the single start-or-stop gate. It carries the prerequisite and the `--commit` disclosure
too — never add a second question for either.

The task list is the brief, never the question text:

- Brief: name the plan and mode, then print the tasks as a Markdown table — `T-NNN`, outcome, and
  the scenarios each covers. In `mode: mixed`, group the table by kind and note that coverage tasks
  run first, with the per-kind counts. Recommend "Proceed".
- Question: "Execute plan `{plan-id}`?"
- Header: "Build plan"
- Options: "Proceed" / "Cancel"

If "Cancel", stop without writing.

**When `--commit` is set**, the brief closes with one line, above the question: each task that
passes every gate is committed on branch `{branch}` as it passes, a failed task commits nothing, and
nothing is pushed. Do not add a second question — proceeding at this gate is the consent to commit.

**When the `**Prerequisites:**` line parsed in Step 4 is not `—`**, the same gate carries the
prerequisite and the proceed label changes, so the user affirms it instead of clicking past it:

- Brief: open with a **Prerequisites** section, before the task table. List each prerequisite on
  its own line, verbatim from the plan. State plainly that `/m:build` cannot check any of them —
  it has no way to know the work was done — and that the proceed option is the user's own
  assertion that it is. State that `/m:plan` wrote this line because the user chose "Handle
  separately" at the test-coverage gate, so the files these tasks change may still have no
  integration coverage and no safety net. Then the task table as above. Recommend "Cancel",
  because a build over unverified prerequisites is the one failure this command cannot detect.
  Close with the escape-hatch line.
- Question: "Execute plan `{plan-id}`?"
- Header: "Build plan"
- Options: "Prerequisites done, proceed" / "Cancel"

On "Cancel", stop without writing. On "Prerequisites done, proceed", hold the affirmation and
every prerequisite line for the Step 11 report — the build must never later imply it verified
them.

## Step 7: Tech Stack and Runner Resolution

Read `specs/TECH-STACK.md`. Locate the **Running tests** and **Coverage** sections:

- **Running tests** — the project's exact test command(s). Use the per-module entry matching the task's module (the module is the segment under `specs/features/` in the owning UC's path).
- **Coverage** — the project's exact coverage command and how to read stats (collector, report path).

If the **Running tests** section is missing for the matching module, halt: "`specs/TECH-STACK.md` is missing the **Running tests** entry for module `{module}`. Run `/m:setup` to populate it."

If the **Coverage** section is missing or marked "not available", proceed anyway — the coverage gate falls back to a best-effort estimate against the four-dimension floors from Step 3. Note this in the final report; when only an estimate is available, the gap-resolution loop (8.7) cannot run and the build halts with an escalation asking the user to install a coverage collector.

Resolve the test runner per the testing skill's **Runner Inference**. Cache test + coverage commands for this invocation.

## Step 8: Execute Each Task

For each task marked in Step 4, run it through the lifecycle. Process tasks in plan order (`T-NNN` ascending). For each task:

**Failure halts the rest of the run.** When a task halts — on an unmet dependency (8.2) or on any of the escalations the sub-steps below define — stop dispatching the remaining tasks and go to Step 9. Never skip past a failed task to the next one. The completed tasks keep their `[x]`, the rest stay `[ ]`, and Step 9 still runs — so the user fixes the escalation and re-runs `/m:build {plan-id}` to resume.

### 8.1 Resolve the task

From the task index (Step 4) and prose:

1. **Kind** — implement or coverage (read from the prose; coverage tasks state they pin existing behavior with no new production code).
2. **Target files** — the `create` / `modify` production files named in the prose. Implement tasks may create and modify; coverage tasks modify none (they add tests only).
3. **Entry point** — the driving-port kind named in the prose (`http`, `graphql`, `event`, …). Must appear in the module's `Driving Ports` list in `specs/MODULES.md`.
4. **Grading** — the "how we prove it" description of what the test drives and what green means.

### 8.2 Validate the task

1. **Check dependencies.** For each ID in `Depends on`, read its checkbox state in the plan file. The dependency is met when its heading reads `## [x] T-NNN`. If any dependency is still `[ ]`, halt: "Task `{T-NNN}` is blocked. Unmet deps: {list with each dep's checkbox state}." Stop.
2. **Check file invariants:**
   - implement task — every file the prose says it **creates** must NOT exist; every file it **modifies** must exist.
   - coverage task — it creates and modifies no production files; every file whose behavior it pins must exist.
3. **Derive the test file path** per the plan-authoring skill's Test File Convention from the task's owning UC + `specs/MODULES.md`:
   ```
   {module.Tests}/{feature-dir-name}/{uc-dir-name}.{test-ext}
   ```
   Refuse to dispatch if `{entry-type}` is not in the module's `Driving Ports`, or the module row has no `Tests` value. When another task in this plan (or a prior plan) already targets this UC's test file, append to it rather than creating a new one.

### 8.3 Load build payload

Read:

- **Dependency outputs.** For each `Depends on` task, read the production files it created/modified (named in its prose) so this task can call their exports. Capture signature lines you need — you do not need full bodies.
- **Existing modify files.** Read the current contents of every file this task modifies.
- The TECH-STACK module section from Step 7.

### 8.4 Phase 1 — Scaffold the test file

Translate the task's "how we prove it" grading prose into runner-equivalent integration test code at the derived test path, driving the named entry point. Group tests by the scenarios in `Covers`.

**Apply Principle 1's Test Writing Rules** (loaded in Step 2) — descriptive names with no spec ID in them (1.1), IDs in leading-line comments (1.2), precise realistic values (1.3), comments that document intent (1.4).

Lifecycle:

- implement task: `it` bodies are empty (or a single `expect.fail("not implemented")` placeholder when the runner requires it). Initial run must be RED.
- coverage task: `it` bodies contain the full assertions implied by the grading prose, following rule 1.3 (precise values). Initial run must be GREEN.

Add imports the assertions need.

**Consult referenced non-canonical tests.** If the task prose names an existing test to consult (recorded by `/m:plan` in cover/mixed mode, e.g. "consult `src/legacy/foo.test.ts` (reference)"):

- `Read` the referenced file **before** you write the canonical test. Lift fixtures, setup, seed data, and assertion patterns into the new integration test as first-class content — not verbatim copies.
- The referenced tests are **not** substitutes for integration coverage. Every SC in the task's `Covers` needs an integration assertion at the driver port.
- A reference marked `migrate` is held for deletion after 8.10 succeeds (see 8.11). Do not delete it here.

Write the test file. Create parent directories as needed. If the canonical file already has tests from a prior task or fix, insert the new blocks next to the existing ones for the same scenario/behavior area rather than appending at the end — see the testing skill's "Keeping the File Organized" rule.

### 8.5 Phase 1 check — initial test run

Run the scoped test command against the derived test file only.

- implement task — expect RED.
  - GREEN → run the mutation check (8.8). If mutation turns it RED, the implementation already satisfies the task; skip Phase 2 and proceed to 8.9.
  - **STOP:** If GREEN after mutation, halt with an escalation under `.molcajete/escalations/{plan-id}-{T-NNN}.md`.
  - RED → proceed to 8.6.
- coverage task — expect GREEN.
  - GREEN → proceed to 8.6 (add assertions) and then the mutation check.
  - **STOP:** RED → halt with an escalation under `.molcajete/escalations/{plan-id}-{T-NNN}.md`: "Coverage task {T-NNN} scaffold is RED before tests are added — existing implementation appears broken or the scaffold targets the wrong files. Investigate via `/m:fix`."

### 8.6 Phase 2 — Implement or assert

- implement task: write production code in its final form across the layers the task names, to satisfy the behavior and turn the scaffold GREEN. Fill empty `it` bodies with concrete assertions as you implement (per Principle 1.3 — precise values). Honour dependency signatures verbatim.
- coverage task: add more assertions to the scaffold to close coverage on the files it pins. **Do not write production code.**

**Apply Principle 5** (loaded in Step 2) — universal software craft while writing code (reuse an existing helper before adding one, small functions, clear boundaries, no duplication) and the Code Comments rules 5.1–5.4 (spec traceability, function headers, inline comments, comment density matched to hidden intent).

**Reconcile first when the UC is `dirty`.** If the owning UC changed via `/m:fix`, `/m:change`, or `/m:spec` (its `Covers` scenarios were touched), reconcile the existing canonical test file and touched production files against the current UC spec (re-read in Step 5) per the testing skill's "Reconciling Changed Behavior" before writing any new code or assertion.

Run the scoped test + coverage commands.

- RED → retry up to 3 more times. Each retry: the only context is the failing test output plus the task prose.
- **STOP:** On the 3rd RED, halt with an escalation under `.molcajete/escalations/{plan-id}-{T-NNN}.md` with the last test output.
- GREEN → proceed to **8.7 Coverage gap resolution**.

### 8.7 Coverage gap resolution (blocking)

Parse the per-file coverage output into the four-dimension table per touched file (every file the task creates or modifies). Compare each dimension against its floor from Step 3's resolved `testing.thresholds`:

| Dimension  | Floor | Actual | Status |
|------------|-------|--------|--------|
| lines      | `<n>` | `<n>`  | OK / GAP |
| statements | `<n>` | `<n>`  | OK / GAP |
| branches   | `<n>` | `<n>`  | OK / GAP |
| funcs      | `<n>` | `<n>`  | OK / GAP |

If every dimension is OK for every touched file → proceed to 8.8.

If any dimension is GAP, run the **gap-resolution loop** (max 3 iterations per task):

1. **Collect the gap report** — every uncovered line range, branch (with side), and function by name and file.
2. **Classify each gap** per the testing skill's "Gap classification":
   - **Reachable behavior** — maps to an `SC-XXXX` the current test plan does not assert.
   - **Defensive / unreachable** — a branch or function no specified scenario can reach.
   - **Orphaned / dead** — serves an `SC-`/`FR-`/`NFR-` the UC no longer contains.
   Re-read the UC scenarios for every gap you classify. A gap you cannot map to any current `SC-XXXX`, cannot justify as defensive, and cannot tie to a retired scenario is a spec gap; halt with an escalation suggesting `/m:fix` or `/m:change`.
3. **Resolve each gap** — Reachable → add the missing test case (and add the `SC-XXXX` to the task's `Covers` if absent). Defensive → delete the code, or keep with a per-branch ignore directive and a one-line reason (bare "hard to test" is not valid). Orphaned → delete the code, its comments, and any test referencing the retired scenario.

   **Raising any threshold is forbidden.** Never edit `.molcajete/settings.json` to make the gate pass.
4. **Re-run scoped tests + coverage.** All OK → 8.8. Gaps remain → next iteration.
   - **STOP:** On the 3rd iteration with gaps still present, halt with an escalation under `.molcajete/escalations/{plan-id}-{T-NNN}.md` listing every remaining gap, its classification, and file:line.

### 8.8 Mutation check

Identify the exported functions/bindings the task's tests exercise — the entry-point handlers and domain functions in the files the task created or modified (implement task) or pins (coverage task). Rewrite each to throw `new Error('MUTANT')` (or language-equivalent). Save originals first. Run the scoped test command. Restore originals in a `finally`.

- implement task: mutation is only run when the scaffold started GREEN unexpectedly (Phase 1 check). Success = RED.
- coverage task: mutation is mandatory after Phase 2. Success = RED. GREEN after mutation means the added assertions are vacuous; retry up to 3 more times passing only the mutation report plus the task prose.
- **STOP:** If mutation is still GREEN after 3 retries (coverage) or after the initial check (implement), halt with an escalation under `.molcajete/escalations/{plan-id}-{T-NNN}.md` containing the mutation report.

**Never leave a file mutated on exit.** Verify restoration by re-reading and comparing to the saved original.

### 8.9 Mechanical verification block (blocking)

Before the correctness review, emit the evidence for this task. If any item cannot be stated honestly, halt with an escalation under `.molcajete/escalations/{plan-id}-{T-NNN}.md`; do NOT proceed to 8.10 or 8.11.

- Test file path, and the initial run color against the expected one, with runner output.
- Phase 2 final run: GREEN, with runner output.
- One row per touched file: `<file>: lines <a>%, statements <b>%, branches <c>%, funcs <d>% (floors: <L>/<S>/<B>/<F>)` — every dimension at or above its floor.
- Each 8.7 gap and its disposition (scenario test added with its SC-XXXX, or defensive/orphaned code deleted with reason).
- Mutation: RED for every mutated export, or `N/A — RED-first proved non-vacuity` for an implement task that started RED (mutation runs for coverage tasks always, implement tasks only when the scaffold started GREEN at 8.5).
- Mutated files restored, verified by re-read against the saved originals — `N/A` when mutation was not run.

### 8.10 Correctness review (blocking, maker-checker)

8.9 proves the tests are green, covered, and non-vacuous — not that the implementation is *correct*. A test that pins a wrong expected value passes 8.9 happily. This step is a **maker-checker** boundary: dispatch a **Reviewer sub-agent** (via the Agent tool) that did **not** write this task's code, per the testing skill's **Reviewer** role contract — give it exactly what that contract's **Receives** list names and nothing else, and it applies that contract's four checks and returns `correct` or `defects{list}`.

- `correct` → proceed to 8.11.
- `defects{...}` → loop back to 8.6: fix the production code and/or the test to satisfy the spec (not to satisfy the Reviewer superficially), then re-run 8.5→8.10. Cap at 3 correctness iterations.
- **STOP:** On the 3rd `defects` result, halt with an escalation under `.molcajete/escalations/{plan-id}-{T-NNN}.md` listing every outstanding defect. Do NOT flip the checkbox.

### 8.11 Record task completion

Only reached when 8.9's evidence was emitted complete AND 8.10 returned `correct`.

1. **Flip the checkbox in the plan file.** Change this task's heading from `## [ ] T-NNN — {outcome}` to `## [x] T-NNN — {outcome}`. Preserve the rest of the file verbatim. This is the task-level source of truth and is read for dependency gating (8.2) by later tasks in this same run.
2. **Handle `migrate` references.** For every referenced test the task prose marked `migrate`, ask whether to delete the original. This is a trivial confirmation with a one-sentence consequence, so no brief is needed — name both paths in the question: "Delete `{path}` now that it is migrated into `{derived-test-path}`?" Header: "Migrated". Options: **"Delete"** / **"Keep"** (note the deferral in the Step 11 report). Never delete a `reference`-marked file.
3. **Roll up this task's spec artifacts.** Only when `--commit` is set. Apply the rules Step 9 already owns, scoped to the UCs this task covers instead of the whole plan, so the commit in item 4 carries them:
   - Per the 9.2 rule — recompute this UC's `status:` from the checkboxes of every task in the plan that covers its scenarios (all `[x]` → `implemented`; some `[x]` and some `[ ]` → `dirty`) and write it. Roll the owning Feature up from its UCs and write `REQUIREMENTS.md`.
   - Per the 9.1 rule — when every task in the plan covering this UC now reads `[x]`, use the `uc-log` skill to flip that UC's changelog entry for this `plan:<plan-id>` from `dirty` to `implemented` and move the line to the top of `DONE:`.
4. **Commit the task.** Only when `--commit` is set. Stage an explicit list of paths — never `git add .` and never `git add -A`, so unrelated work already in the tree stays out. Stage exactly:
   - the production files this task created or modified,
   - its test file,
   - any file deleted by a `migrate` disposition in item 2,
   - `specs/plans/<plan-id>.md`, carrying this task's `[x]`,
   - the spec files written in item 3.

   Then commit per the `git-committing` skill read in Step 2: the subject states the task outcome, the body bullets state what the task did, and the spec-references block carries the task's owning `FEAT-XXXX`, its `UC-XXXX`, and every `SC-XXXX` in the task's `Covers`. Record the short hash for the Step 11 report.

   If the commit fails — a pre-commit hook rejects it, nothing was staged, any other error — do not retry it and do not undo item 1, 2, or 3. The work stands on disk. Report the failure and halt the run per the Step 8 failure policy.

The order within this sub-step is fixed: checkbox, then migrate disposition, then spec roll-up, then stage, then commit. Everything the task changed lands in one commit.

The plan checkbox is the durable ledger. Diagnostics (mutation logs, retry counts) live only in the conversation and any escalation files.

## Step 9: Update Changelogs and Statuses

Step 9 runs at the end of every `/m:build` invocation regardless of individual task outcomes. Task checkboxes were already flipped per-task in 8.11 (success-gated). This step handles the changelog entries, the UC/Feature status roll-up, and the end-of-plan completeness sweep.

**Under `--commit`**, 8.11 already applied 9.1 and 9.2 to each completed task's own UCs and committed them. Run 9.1 and 9.2 anyway — they read current on-disk state, so they recompute the same values and normally write nothing. Anything they do write stays uncommitted: report it in Step 10 and leave it for the user. Never create a commit that carries only spec files.

### 9.1 Changelog entries (success-gated)

For each touched UC, if **every** task in the plan that covers that UC's scenarios now reads `## [x]` in the plan file, use the `uc-log` shared skill to flip that UC's changelog entry for this `plan:<plan-id>` from `dirty` to `implemented` and move the line from `TODO:` to the top of `DONE:`. A UC with any still-`[ ]` covering task keeps its entry `dirty` in `TODO:`.

### 9.2 Status roll-up (unconditional)

Per the `status-rollup` skill, with slices gone the **UC is the leaf** — its status is written directly from task completion, and the Feature rolls up from its UCs. Walk the entire plan's scope (every UC and FEAT on the `**Specs:**` line) and rewrite frontmatter from current on-disk state:

**Per-UC (direct write).** For each UC in scope, look at the plan tasks whose `Covers` scenarios belong to it:

- Every such task `[x]` → UC `status: implemented`.
- Some `[x]`, some `[ ]` → UC `status: dirty`.
- None `[x]` → UC `status: pending`.

Write the value to the UC's `UC-XXXX-{slug}.md` frontmatter `status:` — overwrite regardless of prior value; if unchanged, still record `After = unchanged` in Step 10.

**Per-Feature (roll-up).** For each Feature in scope, list every `UC-XXXX-*.md` spec file in the feature folder (siblings of `REQUIREMENTS.md`; ignore `USE-CASES.md` / `ARCHITECTURE.md` / `REQUIREMENTS.md`), read each UC's `status:`, and apply the roll-up rule: all `implemented` → `implemented`; any `dirty` or a mix of `implemented` and `pending` → `dirty`; none `implemented` → `pending`. Write the result to `REQUIREMENTS.md` frontmatter `status:`.

The CHANGELOG is for context only; status decisions read from artifact frontmatter and the plan checkboxes.

### 9.3 End-of-plan completeness sweep

After the tasks selected in Step 4 are done, run one final review across every UC the plan touches (not only the tasks in this run). Confirm:

- Every `SC-XXXX` in each touched UC appears in some task's `Covers` in the plan file, and — for tasks already `[x]` — is addressed by an assertion in that task's canonical test file.
- No `TODO`/`FIXME`/stub markers remain in the production files this plan touched.
- No scenario in a touched UC is left uncovered by any task.

This sweep **reports**; it does not silently pass. List any uncovered scenario, missing assertion, or stray marker in the Step 11 report as a "Completeness gaps" section. If there are none, say so explicitly.

## Step 10: Status Mutation Report (blocking)

Before Step 11, account for every artifact in the plan's scope — every task checkbox that could have flipped, every UC in the plan, every Feature in the plan, every CHANGELOG entry that could have flipped. The accounting is exhaustive; the table is not.

Emit a row for every artifact whose state **changed**, and for every artifact that **should have changed and did not**.

- **If a task failed (escalation written), its checkbox stays `[ ]` and its UC/changelog stay in their prior state.** Emit those rows with the reason `task failed — see escalation`.
- **A UC or Feature roll-up that did not move** (per 9.2) earns a row only when a task in its scope completed this run. Close the table with one line naming how many artifacts were unchanged as expected.

| Artifact path              | Field                | Before  | After                    | Reason (if unchanged)                       |
|----------------------------|----------------------|---------|--------------------------|---------------------------------------------|
| `<plan file>`              | checkbox `T-NNN`     | `[ ]`   | `[x]` / unchanged        | e.g. `task failed 8.10`                     |
| `<UC path>`                | status               | `<prev>`| `<new>` / unchanged      | e.g. `1 of 3 covering tasks still pending`  |
| `<FEAT REQUIREMENTS.md>`   | status               | `<prev>`| `<new>` / unchanged      | e.g. `all UCs already implemented`          |
| `<UC CHANGELOG.md>`        | entry `{plan-id}`    | dirty   | implemented / unchanged  | e.g. `entry unchanged — task failed`        |

## Step 11: Report

Lead with the outcome in one sentence: the plan ID, the mode, and how many tasks completed against how many failed.

Then report what the user must act on:

- **Unverified prerequisites** — when the plan carried a `**Prerequisites:**` line other than `—`, list every prerequisite verbatim and state in one line: "`/m:build` did not verify these. You confirmed them at the Step 6 gate." Never write that a prerequisite was checked, met, or satisfied — this command has no way to establish any of those. Omit this section when the line was `—` or absent.
- **Per completed task** — one line: `T-NNN`, outcome, and its materialized test file path. Under `--commit`, add the short commit hash. In `mode: mixed`, group into "Coverage (pinned existing behavior)" and "Implement (new behavior)".
- **Commits** — only under `--commit`: one line naming the branch and how many commits this run created. When a commit failed in 8.11, name the task and state that its work is on disk but uncommitted.
- **Per escalation** — `T-NNN` and the escalation file path.
- **Completeness gaps** from 9.3 — every uncovered scenario, missing assertion, and stray marker. **This section is exempt from the budget.** List all of them, or state that there are none.
- **Status** for each UC and Feature whose status changed this run.
- Plan checklist progress, one line (e.g., "3 of 5 tasks complete in plan `{plan-id}`").

Report per-touched-file coverage numbers, the 8.7 loop's resolutions, and 8.11's migration dispositions **only when one of them fell below the floor, stayed unresolved, or was deferred**. A number that passed its gate is not news; the gate already enforced it.

If the host project's coverage collector wasn't available (per Step 7) and you estimated against the floor, say so in one line.

If every task in the plan is now complete, suggest: "Plan `{plan-id}` is fully executed."

If unfinished tasks remain, suggest: "Next: `/m:build {plan-id}` to run the remaining {N} tasks."
