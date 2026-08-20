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

**The plan can change while it runs.** A plan is written before the code is read, so it misses things: a file nothing asserts, shipped code that is broken, a spec that says the wrong thing. Each of those used to end the run and send the user to another command. Now each one is a **trigger** in the `plan-adaptation` skill: the build drafts the correction, asks once, and either amends the plan and continues, records a known issue and continues, or halts. The user answers one question and the run keeps going.

The plan's `**Mode:**` label is a summary derived from the tasks. **The authoritative per-task dispatch is the task's own `**Kind:**` field** (see the plan-authoring skill's "Task Kind"). Nothing about the kind is inferred from prose.

| Kind | Production code | Phase 1 expects | Reconciles retired scenarios |
|---|---|---|---|
| `implement` | writes new code | RED | no |
| `change` | modifies existing code | RED | yes |
| `fix` | corrects existing code | RED | no |
| `cover` | **none** | GREEN | no |

Throughout Step 8, **a code-writing kind** means `implement`, `change`, or `fix` — the three that write production code and start RED. `cover` writes an integration test only; its test starts GREEN because it pins behavior that already ships, and the mutation step proves the assertions have teeth.

**A plan mixes kinds.** One plan may open with `cover` tasks that pin the code it is about to touch, continue with a `fix` task, and close with `change` tasks. The plan-authoring ordering rule already places `cover` before `fix` before `change`/`implement` wherever they touch the same behavior, so this command executes them in the order it reads them.

**A missing `**Kind:**` line** means the plan predates the field. Read it as `cover` when the plan's `**Mode:**` is `cover`, and as `implement` otherwise. `**Mode:** default` is the old name for `implement`.

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
2. `${CLAUDE_PLUGIN_ROOT}/build/skills/plan-adaptation/SKILL.md` — the trigger catalog, the slot-and-run task ID scheme, the amendment gate, and the budget. Every STOP in Step 8 routes through this skill before it halts.
3. `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md` — Implementer / Validator / Reviewer roles, runner inference, outer-edge mocking, coverage gate.
4. `${CLAUDE_PLUGIN_ROOT}/shared/skills/uc-log/SKILL.md` — CHANGELOG mechanics only.
5. `${CLAUDE_PLUGIN_ROOT}/shared/skills/status-rollup/SKILL.md` — how to write UC status and roll up Feature.
6. `${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/SKILL.md` — **Immutability** section. This command writes `SC-XXXX` IDs into task `Covers` lists and into test-file comments. It copies existing IDs verbatim and never generates, renumbers, or alters one. Task tags (`T-NNN`) are not spec IDs and are re-tagged by the `plan-adaptation` skill under its own rules.
7. **Only when `--commit` is set** — `${CLAUDE_PLUGIN_ROOT}/shared/skills/git-committing/SKILL.md` — message format, style detection, the spec-references block, and the no-attribution rule. A run without the modifier does not read it.
8. **Only when an amendment needs a spec edit** — `${CLAUDE_PLUGIN_ROOT}/spec/skills/spec-revision/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/shared/skills/resolution-gate/SKILL.md`. Load them at the moment the `plan-adaptation` skill's step 3 runs, not up front — most runs never edit a spec.
9. **Engineering principles.** Read `.claude/rules/principles.md` from the host project — this is the operative version of the principles. If the host file is missing, read `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md` instead and emit a one-line warning to the user: "No host principles file found at `.claude/rules/principles.md`. Using plugin defaults. Run `/m:setup` to generate the host file." Every code edit, test scaffold, correctness review, and refactor in this command must respect these principles.

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
3. Resolve the adaptation budget from the same `.molcajete/settings.json`. Read the `adaptation` object and default every missing key: `maxAmendments: 3`, `maxTasksPerAmendment: 2`, `allowSpecEdits: true`. A file with no `adaptation` block resolves to those defaults — **do not write the block back**, because a file that never mentions adaptation is a file the user has not decided about, and unlike the coverage floors nothing here is enforced by a gate that needs a stored value. Carry the resolved values to Step 8.

## Step 4: Load the Plan

1. Read `specs/plans/<plan-id>.md`.
2. Parse:
   - **The `**Specs:**` line** — the FEAT and UC IDs the plan touches, the scenarios in scope, and the `**Mode:**` label.
   - **The `**Prerequisites:**` line** — work that must be done outside this plan before any task runs. `—` means none. A plan written before this field existed carries no such line; treat a missing line as `—`. Carry the parsed value to Step 6. Do not act on it here.
   - **The `**Provenance:**` line** — per UC, the spec `version` and the changelog entry timestamps this plan was written against. A plan written before this field existed carries no such line; record that fact and carry it to 5.2. Do not act on it here.
   - **Each task** — every `## [ ] T-NNN — {outcome}` (or `## [x] T-NNN`) heading, where the tag is `T-NNN` or `T-NNN.M`, its `**Kind:**` value, its `**Covers:**` list, its `**Depends on:**` list, and the task prose beneath it up to the next `## ` heading. A task with no `**Kind:**` line predates the field; apply the missing-field rule from the header.
3. Build an in-memory task index: `tag → { outcome, kind, covers, depends_on, done (checkbox state), prose }`, keeping file order. A `## Known Issues` heading is not a task — a prior run recorded it, and this command never executes it. Ignore any `## ` heading that carries no checkbox.
4. Select the tasks to execute:
   - **`$ARGUMENTS` carries no task ID** → mark every task whose checkbox is `[ ]`, in `T-NNN` ascending order. A task already `[x]` is skipped, so a re-run resumes the plan where the last run stopped. If no task is `[ ]`, tell the user "Plan `{plan-id}` has no unfinished tasks — nothing to do." and stop.
   - **`$ARGUMENTS` carries one or more task IDs** → for each one:
     - `T-NNN` or `T-NNN.M` matching a task heading → mark it for execution.
     - `T-NNN` where the plan holds no such heading but does hold a run `T-NNN.1 … T-NNN.M` → mark **every** task in that run. A prior run amended this slot, and the bare tag names the whole run (see the `plan-adaptation` skill).
     - Unknown task ID → refuse with: "Task `{id}` is not in plan `{plan-id}`. Available tasks: {list}." Stop.

## Step 5: Load Upstream Context

### 5.1 Load the specs

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

### 5.2 Check the plan against its provenance

A plan is a reading of the specs at one moment. A `/m:fix`, `/m:change`, or `/m:spec` run after the plan was written moves the specs underneath it, and the plan then describes behavior the spec no longer states. This sub-step is the only place that can catch it, because every later sub-step trusts the plan.

Skip this check when the plan carries no `**Provenance:**` line, and say so in the Step 11 report: "Plan `{plan-id}` predates the provenance field — this build did not check it for drift."

Otherwise compare each UC in the provenance line against what 5.1 loaded, and collect three signals:

1. **The spec version moved.** The UC's frontmatter `version` is higher than the provenance value. Something edited this use case after the plan was written. Report the two versions.
2. **An unowned entry is open.** The UC's `CHANGELOG.md` `TODO:` section holds a `[pending]` or `[dirty]` entry whose timestamp is newer than the plan ID and whose `plan:` field is not this plan. Another command recorded work this plan does not carry. Report the entry line verbatim.
3. **A covered scenario is gone.** An `SC-XXXX` named in some task's `**Covers:**` no longer appears in the UC spec. The task would test a scenario that no longer exists. Report the scenario and the task.

Signal 1 alone can be benign — a version moves for an edit to any part of the UC, including one no task touches. Signals 2 and 3 always mean the plan and the spec disagree.

**Report every signal in the Step 11 report under "Plan drift".** Then act on it.

**Signal 1 alone** — carry it to the Step 6 gate brief and continue. A version can move for an edit to any part of the UC, including one no task touches, so this on its own is context, not a defect.

**Signal 2 or signal 3** — the plan and the spec disagree about work this plan does. That is **trigger A6**: run the `plan-adaptation` procedure, which drafts a *revise* of each affected task against the current spec. It runs here, before Step 6, so the user reviews the corrected task list at the build gate rather than one this step is about to change.

Revise only the tasks the signals name. A drifted plan is not a wrong plan, and rewriting tasks nothing flagged would discard the reasoning `/m:plan` already did.

On "Stop here", a spent budget, or a headless run, halt with an escalation under `.molcajete/escalations/{plan-id}-drift.md` listing every signal and the drafted revisions. Do not run a plan the specs contradict.

## Step 6: Present the Build Plan

This is the single start-or-stop gate. It carries the prerequisite and the `--commit` disclosure
too — never add a second question for either.

The task list is the brief, never the question text:

- Brief: name the plan and mode, then print the tasks as a Markdown table — `T-NNN`, kind, outcome,
  and the scenarios each covers. When the plan holds more than one kind, add a count per kind under
  the table and state the order the kinds run in, so the user sees that existing behavior is pinned
  before anything changes it. Recommend "Proceed".
- Question: "Execute plan `{plan-id}`?"
- Header: "Build plan"
- Options: "Proceed" / "Cancel"

If "Cancel", stop without writing.

**When 5.2 found drift**, the brief opens with a **Plan drift** section, above everything else. List each signal on its own line: the UC, which of the three signals fired, and the two values that disagree. State plainly that the plan describes the specs as they were and the specs have moved since. Recommend "Cancel", because a build over a drifted plan writes code against a spec nobody re-read. The options do not change — this stays one gate.

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

For each task marked in Step 4, run it through the lifecycle. **Process tasks in file order**, which the `plan-adaptation` skill's slot-and-run rules keep identical to tag order — `T-002`, `T-003.1`, `T-003.2`, `T-003.3`, `T-004`. For each task:

**Re-read the task list after every amendment.** An amendment inserts tasks and re-tags others, so the in-memory index from Step 4 is stale the moment one applies. Re-parse the plan file, then continue from the first `[ ]` task in file order.

**A discovery in the trigger catalog is not a failure.** Before any STOP below halts the run, run the `plan-adaptation` procedure for its trigger. The escalation those sub-steps describe is what happens on "Stop here", when the budget is spent, or in a headless run — it is no longer the only outcome.

**Everything else halts the rest of the run.** When a task halts — on an unmet dependency (8.2), on a discovery outside the catalog, or on any escalation the sub-steps below define — stop dispatching the remaining tasks and go to Step 9. Never skip past a failed task to the next one. The completed tasks keep their `[x]`, the rest stay `[ ]`, and Step 9 still runs — so the user fixes the escalation and re-runs `/m:build {plan-id}` to resume.

### 8.1 Resolve the task

From the task index (Step 4) and prose:

1. **Kind** — read the `**Kind:**` field verbatim. Apply the missing-field rule from the header when the plan predates the field. Never infer the kind from prose.
2. **Target files** — the `create` / `modify` production files named in the prose. A code-writing kind may create and modify; `cover` modifies none (it adds tests only).
3. **Entry point** — the driving-port kind named in the prose (`http`, `graphql`, `event`, …). Must appear in the module's `Driving Ports` list in `specs/MODULES.md`.
4. **Grading** — the "how we prove it" description of what the test drives and what green means.

### 8.2 Validate the task

1. **Check dependencies.** For each ID in `Depends on`, read its checkbox state in the plan file. The dependency is met when its heading reads `## [x] T-NNN`. A bare `T-NNN` naming an amended slot is met only when **every** task in that run reads `[x]`. If any dependency is still `[ ]`, halt: "Task `{T-NNN}` is blocked. Unmet deps: {list with each dep's checkbox state}." Stop.
2. **Check file invariants:**
   - code-writing kind — every file the prose says it **creates** must NOT exist; every file it **modifies** must exist. A `change` or `fix` task normally creates nothing, because both act on code that already ships.
   - `cover` — it creates and modifies no production files; every file whose behavior it pins must exist.

   A file the task says it **creates** that already exists is **trigger A7**: the code moved since the plan was written, so the task's prose describes work that is partly done. Run the `plan-adaptation` procedure, which drafts a *revise* of this task against what is actually on disk. A file the task says it **modifies** that does not exist still halts — a task pointed at a file that is not there is a broken plan, not an adaptable one.
3. **Check canonical coverage of the files this task modifies.** Skip for a `cover` task, whose whole purpose is to close this gap. For each production file in the `modify` set, resolve its module in `specs/MODULES.md` by `Directory` prefix, then grep the file's exported symbols against that module's `Tests` tree, exactly as the plan-authoring skill's coverage probe does. Judge against `{module.Tests}` only — a `src/foo.test.ts` beside `src/foo.ts` is not coverage.

   A file with no canonical coverage is **trigger A2**: this task is about to change code that nothing asserts, with no safety net under it. Run the `plan-adaptation` procedure, which drafts a `cover` task to pin the file before this task touches it. The plan's own probe missed it because the file was added, moved, or renamed after the plan was written.

   **Skip a file the plan's `**Prerequisites:**` line already names.** The user answered that exact question at the plan's coverage gate and affirmed it again at the Step 6 gate, so asking a third time is asking the same question until the answer changes. Report those files in the Step 11 report under "Unverified prerequisites", where they already belong.
4. **Derive the test file path** per the plan-authoring skill's Test File Convention from the task's owning UC + `specs/MODULES.md`:
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

- code-writing kind: `it` bodies are empty (or a single `expect.fail("not implemented")` placeholder when the runner requires it). Initial run must be RED.
- `cover`: `it` bodies contain the full assertions implied by the grading prose, following rule 1.3 (precise values). Initial run must be GREEN.

Add imports the assertions need.

**Consult referenced non-canonical tests.** If the task prose names an existing test to consult (recorded by `/m:plan` for a plan holding `cover` tasks, e.g. "consult `src/legacy/foo.test.ts` (reference)"):

- `Read` the referenced file **before** you write the canonical test. Lift fixtures, setup, seed data, and assertion patterns into the new integration test as first-class content — not verbatim copies.
- The referenced tests are **not** substitutes for integration coverage. Every SC in the task's `Covers` needs an integration assertion at the driver port.
- A reference marked `migrate` is held for deletion after 8.10 succeeds (see 8.11). Do not delete it here.

Write the test file. Create parent directories as needed. If the canonical file already has tests from a prior task or fix, insert the new blocks next to the existing ones for the same scenario/behavior area rather than appending at the end — see the testing skill's "Keeping the File Organized" rule.

### 8.5 Phase 1 check — initial test run

Run the scoped test command against the derived test file only.

- code-writing kind — expect RED.
  - GREEN → run the mutation check (8.8). If mutation turns it RED, the implementation already satisfies the task; skip Phase 2 and proceed to 8.9.
  - **STOP:** If GREEN after mutation, halt with an escalation under `.molcajete/escalations/{plan-id}-{T-NNN}.md`.
  - RED → proceed to 8.6.
- `cover` — expect GREEN.
  - GREEN → proceed to 8.6 (add assertions) and then the mutation check.
  - RED → **trigger A3.** The scaffold asserts what the code does today and the code does not do it, so either the shipped implementation is broken or the scaffold targets the wrong files. Rule the second one out first: re-read the task prose and confirm the test drives the entry point and files it names. When the scaffold is right, the code is broken — run the `plan-adaptation` procedure, which diagnoses it and drafts a `fix` task to run before this one. That is the whole point of pinning behavior before changing it, so finding a defect here is a success, not a failure.
  - **STOP:** On "Stop here", a spent budget, or a headless run, halt with an escalation under `.molcajete/escalations/{plan-id}-{T-NNN}.md`: "Coverage task {T-NNN} scaffold is RED before tests are added — existing implementation appears broken or the scaffold targets the wrong files. Investigate via `/m:fix`."

### 8.6 Phase 2 — Implement or assert

- code-writing kind: write production code in its final form across the layers the task names, to satisfy the behavior and turn the scaffold GREEN. Fill empty `it` bodies with concrete assertions as you implement (per Principle 1.3 — precise values). Honour dependency signatures verbatim. An `implement` task adds code that did not exist; a `fix` task corrects code that does; a `change` task rewrites it to the behavior the spec now states.
- `cover`: add more assertions to the scaffold to close coverage on the files it pins. **Do not write production code.**

**Apply Principle 5** (loaded in Step 2) — universal software craft while writing code (reuse an existing helper before adding one, small functions, clear boundaries, no duplication) and the Code Comments rules 5.1–5.4 (spec traceability, function headers, inline comments, comment density matched to hidden intent).

**Reconcile first on a `change` task.** Before writing any new code or assertion, reconcile the existing canonical test file and the touched production files against the current UC spec (re-read in Step 5) per the testing skill's "Reconciling Changed Behavior". Deleting the tests and code of a scenario the UC retired is part of the `change` kind's contract, and it is the only kind that may do it. A `fix`, `implement`, or `cover` task never deletes a scenario's tests or code — a task that finds it needs to is mis-kinded, so halt with an escalation naming the scenario.

Run the scoped test + coverage commands.

- RED → retry up to 3 more times. Each retry: the only context is the failing test output plus the task prose.
- On the 3rd RED, decide **why** it will not go green before you escalate. When the failure traces to code this task does not own — a dependency the task calls returns something the spec says it should not — that is **trigger A5**: run the `plan-adaptation` procedure, which diagnoses the dependency and drafts a `fix` task for it. When the failure is in this task's own code, it is not a trigger. Three failed attempts at the task's own work is a failure, and inventing an amendment to escape it would hide the real problem.
- **STOP:** On the 3rd RED with no A5 diagnosis, or on "Stop here", a spent budget, or a headless run, halt with an escalation under `.molcajete/escalations/{plan-id}-{T-NNN}.md` with the last test output.
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
   Re-read the UC scenarios for every gap you classify. A gap you cannot map to any current `SC-XXXX`, cannot justify as defensive, and cannot tie to a retired scenario is a **spec gap — trigger A1**. The code does something no scenario describes, so no test can be written for it without first deciding what it is supposed to do. Run the `plan-adaptation` procedure: its diagnosis adds the missing scenario to the UC (or corrects a wrong one) and drafts the task that closes it. Never invent an assertion for behavior the spec does not describe — a test written against a guess pins the guess.
3. **Resolve each gap** — Reachable → add the missing test case (and add the `SC-XXXX` to the task's `Covers` if absent). Defensive → delete the code, or keep with a per-branch ignore directive and a one-line reason (bare "hard to test" is not valid). Orphaned → delete the code, its comments, and any test referencing the retired scenario.

   **Raising any threshold is forbidden.** Never edit `.molcajete/settings.json` to make the gate pass.
4. **Re-run scoped tests + coverage.** All OK → 8.8. Gaps remain → next iteration.
   - **STOP:** On the 3rd iteration with gaps still present, or on "Stop here", a spent budget, or a headless run, halt with an escalation under `.molcajete/escalations/{plan-id}-{T-NNN}.md` listing every remaining gap, its classification, and file:line.

### 8.8 Mutation check

Identify the exported functions/bindings the task's tests exercise — the entry-point handlers and domain functions in the files the task created or modified (code-writing kind) or pins (`cover`). Rewrite each to throw `new Error('MUTANT')` (or language-equivalent). Save originals first. Run the scoped test command. Restore originals in a `finally`.

- code-writing kind: mutation is only run when the scaffold started GREEN unexpectedly (Phase 1 check). Success = RED.
- `cover`: mutation is mandatory after Phase 2. Success = RED. GREEN after mutation means the added assertions are vacuous; retry up to 3 more times passing only the mutation report plus the task prose.
- **STOP:** If mutation is still GREEN after 3 retries (coverage) or after the initial check (implement), halt with an escalation under `.molcajete/escalations/{plan-id}-{T-NNN}.md` containing the mutation report.

**Never leave a file mutated on exit.** Verify restoration by re-reading and comparing to the saved original.

### 8.9 Mechanical verification block (blocking)

Before the correctness review, emit the evidence for this task. If any item cannot be stated honestly, halt with an escalation under `.molcajete/escalations/{plan-id}-{T-NNN}.md`; do NOT proceed to 8.10 or 8.11.

- Test file path, and the initial run color against the expected one, with runner output.
- Phase 2 final run: GREEN, with runner output.
- One row per touched file: `<file>: lines <a>%, statements <b>%, branches <c>%, funcs <d>% (floors: <L>/<S>/<B>/<F>)` — every dimension at or above its floor.
- Each 8.7 gap and its disposition (scenario test added with its SC-XXXX, or defensive/orphaned code deleted with reason).
- Mutation: RED for every mutated export, or `N/A — RED-first proved non-vacuity` for a code-writing kind that started RED (mutation runs for a `cover` task always, a code-writing kind only when the scaffold started GREEN at 8.5).
- Mutated files restored, verified by re-read against the saved originals — `N/A` when mutation was not run.

### 8.10 Correctness review (blocking, maker-checker)

8.9 proves the tests are green, covered, and non-vacuous — not that the implementation is *correct*. A test that pins a wrong expected value passes 8.9 happily. This step is a **maker-checker** boundary: dispatch a **Reviewer sub-agent** (via the Agent tool) that did **not** write this task's code, per the testing skill's **Reviewer** role contract — give it exactly what that contract's **Receives** list names and nothing else, and it applies that contract's four checks and returns `correct`, `defects{list}`, or `spec_defect{list}`.

- `correct` → proceed to 8.11.
- `defects{...}` → loop back to 8.6: fix the production code and/or the test to satisfy the spec (not to satisfy the Reviewer superficially), then re-run 8.5→8.10. Cap at 3 correctness iterations.
- `spec_defect{...}` → **trigger A4.** The Reviewer read the spec independently and concluded the spec is what is wrong, so looping back to 8.6 would send the Implementer to change code that already matches it. Run the `plan-adaptation` procedure, whose diagnosis edits the spec and drafts the task that reconciles the code to it. A `spec_defect` does **not** consume a correctness iteration — the count exists to stop an Implementer looping on the same defect, and nothing was sent back to the Implementer.
- **STOP:** On the 3rd `defects` result, or on "Stop here", a spent budget, or a headless run, halt with an escalation under `.molcajete/escalations/{plan-id}-{T-NNN}.md` listing every outstanding defect. Do NOT flip the checkbox.

### 8.11 Record task completion

Only reached when 8.9's evidence was emitted complete AND 8.10 returned `correct`.

1. **Flip the checkbox in the plan file.** Change this task's heading from `## [ ] {tag} — {outcome}` to `## [x] {tag} — {outcome}`, where `{tag}` is the task's tag exactly as written — `T-003` or `T-003.2`. Preserve the rest of the file verbatim, including any `**Added:**`, `**Retagged:**`, or `**Revised:**` audit lines. This is the task-level source of truth and is read for dependency gating (8.2) by later tasks in this same run. Once flipped, this task's tag is permanent: the `plan-adaptation` skill never re-tags a completed task.
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

This is the shape. Every section below the task table is conditional — print it only when it has content, and never print an empty one.

````markdown
## Build complete — plan `20260820T1430-otp-expiry`

`mode: mixed` · 2 of 3 tasks complete · 1 failed

| Task | Kind | Outcome | Test file | Commit |
|---|---|---|---|---|
| T-001 | cover | Pins the current OTP send path | `tests/auth/FEAT-3Z2K-email-otp/UC-3Z2L.test.ts` | `a1b2c3d` |
| T-002 | implement | Rejects an unregistered address | `tests/auth/FEAT-3Z2K-email-otp/UC-3Z2L.test.ts` | `b2c3d4e` |
| T-003 | change | Expires the OTP after 10 minutes | — | failed |

**Status changes**

| Artifact | Before | After |
|---|---|---|
| `UC-3Z2L` | dirty | implemented |
| `FEAT-3Z2K` | dirty | dirty |

**Escalations**

- `T-003` — `.molcajete/escalations/20260820T1430-otp-expiry-T-003.md`

**Unverified prerequisites**

`/m:build` did not verify these. You confirmed them at the Step 6 gate.

- A Postmark sandbox token exists in the test environment.

**Amendments** — 2 of 3 allowed

| When | Trigger | Change |
|---|---|---|
| during T-003 | A2 | inserted `T-003.1` (cover) — pins `src/auth/session.ts`; `T-003` re-tagged `T-003.2` |
| during T-003.2 | A3 | inserted `T-003.2` (fix) — OTP accepted after expiry; `T-003.2` re-tagged `T-003.3`; added `SC-3Z2T` to `UC-3Z2L` |

**Known issues**

- `T-004` · A2 — `src/auth/token.ts` has no canonical integration coverage. Logged on `UC-3Z2L` as `pending`.

**Plan drift**

- `UC-3Z2L` — spec is `v3`, plan was written against `v2`.
- `UC-3Z2L` — open entry this plan does not own: `- 20260821T0910 [pending] command:fix plan:— — OTP accepted after expiry`

**Completeness gaps**

- `SC-3Z2Q` has no covering assertion in `UC-3Z2L.test.ts`.

Plan `20260820T1430-otp-expiry` — 2 of 3 tasks complete.

> Next: `/m:build 20260820T1430-otp-expiry` to run the remaining 1 task.
````

### Section rules

**The heading and the metadata line always print.** The `mode`, the completed count, and the failed count go on one line under the heading.

**The task table always prints**, one row per task attempted, with a `Kind` column carrying each task's `**Kind:**` value. Rows stay in execution order — never regroup them by kind, because the order tasks ran in is what the reader needs. A failed task shows `—` for its test file and `failed` in the last column. The `Commit` column appears only under `--commit`; omit the column entirely otherwise rather than filling it with dashes.

**Unverified prerequisites** prints when the plan carried a `**Prerequisites:**` line other than `—`. List every prerequisite verbatim under that fixed sentence. **Never write that a prerequisite was checked, met, or satisfied** — this command has no way to establish any of those.

**Amendments** prints when any amendment applied. One row per amendment, in the order they happened: the task that was running, the trigger ID, and what changed — tasks inserted or revised, tags re-assigned, and any spec edit. The heading carries the count against `maxAmendments`, so the user sees how close the run came to the budget. **This section is exempt from the output budget** — the plan the user approved at Step 6 is not the plan that ran, and every difference belongs here.

**Known issues** prints when the user answered "Note and continue" at any gate. One line per issue: the task that hit it, the trigger ID, the reason, and the UC the `pending` changelog entry landed on. Close the section by naming the command that picks them up: `/m:plan <UC-XXXX>`. Also exempt from the output budget.

**Plan drift** from 5.2 lists every signal the provenance check found, one line each. **This section is exempt from the output budget** — a drift the report truncates is a drift the user never acts on. When the plan carried no `**Provenance:**` line, replace the list with the single sentence 5.2 defines. Omit the section only when the check ran and found nothing.

**Completeness gaps** from 9.3 lists every uncovered scenario, missing assertion, and stray marker. **This section is exempt from the output budget.** List all of them, or omit the section when there are none.

**Commits** gets its own line under the table only when a commit failed in 8.11 — name the task and state that its work is on disk but uncommitted. A successful commit is already in the `Commit` column.

**Coverage numbers, the 8.7 loop's resolutions, and 8.11's migration dispositions print only when one of them fell below the floor, stayed unresolved, or was deferred.** A number that passed its gate is not news; the gate already enforced it. When the host project's coverage collector was unavailable per Step 7 and you estimated against the floor, say so in one line.

**The closing line** states plan progress. When every task is complete, write "Plan `{plan-id}` is fully executed." and print no `Next:` line. Otherwise print the `Next:` hand-off naming the remaining count.
