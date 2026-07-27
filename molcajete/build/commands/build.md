---
description: Execute a plan — run the TDD red/green/mutation lifecycle for one or more tasks (slices) inside a plan folder.
model: claude-opus-4-6
argument-hint: "<plan-id> <T-NNN | T-NNN.N> [more ...]"
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

`/m:build` executes a plan produced by `/m:plan`. It walks the tasks the user named, runs the TDD lifecycle for each, updates the plan checkboxes, and flips the corresponding log entries to `implemented`.

The plan's `mode` (`default`, `cover`, or `mixed`) is a summary label. The authoritative per-slice dispatch reads the slice's `objective` field (`implement` or `coverage`):

- **mode: default** — every slice is `objective: implement`. Writes production code and integration tests.
- **mode: cover** — every slice is `objective: coverage`. Writes integration tests only. **No production code.** Tests assert behavior of code that already exists.
- **mode: mixed** — the plan contains both objectives. Per-slice dispatch is unchanged: `implement` slices write production code + tests; `coverage` slices write tests only. Coverage slices execute first (guaranteed by `T-NNN` ordering set at plan time), pinning existing behavior before implement slices modify it.

Molcajete generates **integration tests exclusively** per Principle 1 of the engineering principles. `/m:build` never scaffolds unit tests; if the host team wants unit tests for algorithmic code, they write them outside this lifecycle.

**Do NOT commit code.** The user reviews your output and commits themselves.

**Arguments:** $ARGUMENTS

**All user interaction MUST use the AskUserQuestion tool.** Never plain-text questions.

## Step 1: Parse Arguments

`$ARGUMENTS` must contain:

1. A plan ID as the first token. Format: `YYYYMMDDTHHMMSS-<descriptive-name>` (the folder name under `.molcajete/plans/`).
2. One or more task IDs. Each is `T-NNN` (whole slice) or `T-NNN.N` (one sub-task).

Examples:

- `/m:build 20260616T141530-add-checkout T-001`
- `/m:build 20260616T141530-add-checkout T-001 T-002 T-003`
- `/m:build 20260616T141530-add-checkout T-001.1 T-001.2`

If `$ARGUMENTS` is empty or missing a plan-id, list available plans:

```
ls .molcajete/plans/
```

Then tell the user:

> "Usage: `/m:build <plan-id> <T-NNN | T-NNN.N> [...]`. Available plans: {list of plan folder names}."

Stop.

If the plan-id does not resolve to a folder under `.molcajete/plans/`, refuse with the available list and stop.

## Step 2: Load Skills and Principles

Read in one batch:

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/slicing/SKILL.md` — slice file schema and Test File Convention.
2. `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md` — runner inference, outer-edge mocking, coverage gate.
3. `${CLAUDE_PLUGIN_ROOT}/shared/skills/uc-log/SKILL.md` — CHANGELOG mechanics only.
4. `${CLAUDE_PLUGIN_ROOT}/shared/skills/status-rollup/SKILL.md` — how to write slice status and roll up UC + Feature.
5. **Engineering principles.** Read `.claude/rules/principles.md` from the host project — this is the operative version of the principles. If the host file is missing, read `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md` instead and emit a one-line warning to the user: "No host principles file found at `.claude/rules/principles.md`. Using plugin defaults. Run `/m:setup` to generate the host file." Every code edit, test scaffold, and refactor in this command must respect these principles — Principle 5 (small functions, clear boundaries, no god files, refactor to reuse) is the day-to-day enforcement surface here.

## Step 3: Verify Prerequisites

1. `specs/PROJECT.md`, `specs/MODULES.md`, and `specs/TECH-STACK.md` must exist AND be read in full now (one parallel batch). If any is missing: "Project foundation not found. Run `/m:setup` first." Stop. Hold their content in working memory through Step 8 — `PROJECT.md` shapes scope decisions, `MODULES.md` is the canonical module → directory map (also used in 8.2), and `TECH-STACK.md` is re-read for the runner section in Step 7.
2. Ensure `.molcajete/settings.json` exists and resolves to four per-dimension coverage floors (`lines`, `statements`, `branches`, `funcs`):
   - If the file does not exist, create `.molcajete/` and write:
     ```json
     {"testing": {"thresholds": {"lines": 80, "statements": 80, "branches": 80, "funcs": 80}}}
     ```
     Tell the user: "Initialized `.molcajete/settings.json` with default `testing.thresholds = 80` on every dimension. Edit it to change the coverage gate."
   - If the file has `testing.thresholds` (plural, object), use those four values directly. Any missing dimension defaults to 80.
   - If the file has the legacy `testing.threshold` (singular, number) and no `testing.thresholds`, **upgrade in place**: expand the single number to all four dimensions, write back, and tell the user: "Upgraded `.molcajete/settings.json` `testing.threshold = N` to per-dimension `testing.thresholds` (lines/statements/branches/funcs all = N). Edit individual dimensions to tighten the gate."
   - If the file has neither, merge in the default object and write it back.

The resolved object `{lines, statements, branches, funcs}` is the operative gate for every per-file coverage check in Step 8. The legacy single-number form is no longer used during the run.

## Step 4: Load the Plan

1. Read `.molcajete/plans/<plan-id>/plan.md`.
2. Parse:
   - **Mode line** (`mode: default`, `mode: cover`, or `mode: mixed`) at the top.
   - **FEAT / UC sections** (h2 / h3 headings).
   - **Task list** under each UC: `T-NNN` lines with optional `T-NNN.N` sub-tasks. Each task references a slice filename (e.g., `UC-0KTg-001-validate-email.md`).
3. Build an in-memory task index: `T-NNN → { feat, uc, slice_file_path, sub_tasks }`. The slice file path is the UC folder plus the referenced filename.
4. For each task ID in `$ARGUMENTS`:
   - `T-NNN` (whole slice) → mark every sub-task under it for execution.
   - `T-NNN.N` (single sub-task) → mark only that sub-task.
   - Unknown task ID → refuse with: "Task `{id}` is not in plan `{plan-id}`. Available tasks: {list}." Stop.

## Step 5: Load Upstream Context

From the parsed plan you now know which `FEAT-XXXX` and `UC-XXXX` are touched by `$ARGUMENTS`. Read upstream context for ALL of them in one parallel batch BEFORE Step 8.

For every touched FEAT (derived from each touched slice's file path — the feature folder is the slice file's grandparent):

- `<feature-folder>/REQUIREMENTS.md`
- `<feature-folder>/ARCHITECTURE.md`
- `<feature-folder>/USE-CASES.md`

For every touched UC:

- `<feature-folder>/UC-XXXX-{slug}/UC-XXXX-{slug}.md` (the UC spec body, not just the support folder)

**Cross-check against the plan's `## Context` block.** If `plan.md` has a `## Context` section listing upstream files, compare its paths to the derived set:

- Paths in the list that do not exist on disk → halt with the missing-file message below.
- Paths in the list that exist but are NOT in the derived set → emit a one-line warning ("`plan.md` Context list contains `<path>` but no touched task references its FEAT/UC — plan may be stale") and continue.
- Paths in the derived set that are NOT in the list → also emit a warning ("plan Context list is missing `<path>` — was this UC added after `/m:plan` ran?"). The derived set still gets loaded.

**Missing upstream file (hard halt).** If any derived path is missing on disk, halt with:

> Upstream context missing for {FEAT-XXXX | UC-XXXX}: `<path>`. Run `/m:spec` (for spec files) or `/m:setup` (for project foundation) before re-running `/m:build`.

This is a hard gate — these documents are the behavioral source of truth. Every test scenario assertion in Step 8.4, every production-code decision in Step 8.6, and every escalation message must be consistent with the loaded UC spec scenarios (`SC-XXXX`) and the feature's `ARCHITECTURE.md` component boundaries.

## Step 6: Present the Build Plan

Show the user via AskUserQuestion: "Executing plan `{plan-id}` in `mode: {mode}`. {N} task(s): {list of tasks with slice file references}. Proceed?"

In `mode: mixed`, split the count line so the user sees the shape before confirming: "Executing plan `{plan-id}` in `mode: mixed`. {C} coverage task(s), {I} implement task(s) — coverage runs first. Proceed?" Follow with the task list grouped by objective.

Options: "Proceed" / "Cancel".

If "Cancel", stop without writing.

## Step 7: Tech Stack and Runner Resolution

Read `specs/TECH-STACK.md`. Locate the **Running tests** and **Coverage** sections (per the host project's `/m:setup`-generated TECH-STACK):

- **Running tests** — the project's exact test command(s). Use the per-module entry that matches the slice's module (the module is encoded in the slice file path).
- **Coverage** — the project's exact coverage command and how to read stats (collector, report path).

If the **Running tests** section is missing for the matching module, halt: "`specs/TECH-STACK.md` is missing the **Running tests** entry for module `{module}`. Run `/m:setup` to populate it."

If the **Coverage** section is missing or marked "not available", proceed anyway — the coverage gate falls back to a best-effort estimate against the four-dimension floors resolved in Step 3 (`testing.thresholds.{lines, statements, branches, funcs}`). Note this in the final report; when only an estimate is available, the gap-resolution loop (8.7) cannot run and the build halts with an escalation asking the user to install a coverage collector.

Resolve the test runner per the testing skill's **Runner Inference**. Cache test + coverage commands for this invocation.

## Step 8: Execute Each Slice

For each slice marked in Step 4, run the slice through the TDD lifecycle. Process slices in plan order (`T-NNN` ascending). For each slice:

### 8.0 Phase gate (mandatory)

Before doing any work on this slice, emit this exact block in the conversation:

> SLICE {id} GATE: I will run Phase 1 (scaffold test at `<derived test path>`), Phase 1-check (initial run — expect {RED|GREEN}), Phase 2 ({implement|assert}), Phase 2-check (green + per-file coverage ≥ {testing.threshold}%), Mutation (expect RED). I will not flip status in Step 9 until 8.9 emits a fully-ticked verification block.

Substitute the expected initial color from the slice's `objective` (`implement` → RED, `coverage` → GREEN). If you cannot honestly emit this block — e.g. you do not have the test path resolved or you do not intend to run the tests — stop and ask the user.

### 8.1 Load the slice

1. Read the slice file at the resolved path.
2. Parse frontmatter (`id`, `name`, `use_case`, `feature`, `objective`, `files.create`, `files.modify`, `depends_on`, `provides`, `entry_type`, `covers`, `last_update`). Reject the slice if it declares `test_file` in frontmatter.
3. Capture body sections (`## Rationale`, `## Contracts` subsections, `## Tests`).

### 8.2 Validate slice

1. **Check dependencies.** For each ID in `depends_on`, locate the dependency slice file in the same UC folder and read its **frontmatter `status:`**. The dependency is met when `status: implemented`. If any unmet, halt: "Slice `{id}` is blocked. Unmet deps: {list with each dep's current status}." Stop. The `.molcajete/slices/{dep-id}.json` file is no longer consulted for dependency gating — it remains as a durable build outcome record for diagnostics only.
2. **Check file invariants:**
   - `objective: implement` (mode: default) — every path in `files.create` must NOT exist; every path in `files.modify` must exist.
   - `objective: coverage` (mode: cover) — `files.create` must be empty; every path in `files.modify` must exist.
3. **Derive test file path.** Apply the slicing skill's Test File Convention from frontmatter + `specs/MODULES.md`:
   ```
   {module.Tests}/{feature-dir-name}/{uc-dir-name}/{NNN}-{entry-type}-{slice-name}.{test-ext}
   ```
   Apply the validation rules in the slicing skill's "Build-time validation" list verbatim.

### 8.3 Load build payload

Parallel batch:

- **Dependency exports.** For each `depends_on` slice, read its file and `grep` its sources for each name in `provides`. Capture signature lines only (no full bodies).
- **Existing modify files.** Read the current contents of every path in `files.modify`.
- The TECH-STACK module section from Step 7.

### 8.4 Phase 1 — Scaffold the test file

Translate the slice's `## Tests` nested-bullet plan into runner-equivalent test code at the derived test path. Top-level bullets → outermost `describe` (or runner-equivalent). Nested bullets → nested `describe`. Leaves → `it`.

**Apply Principle 1's Test Writing Rules** (loaded in Step 2):

- **1.1 Descriptive names** — every `describe` block and `it` test gets a behavior-describing name. **Never put a spec ID (SC-XXXX, FR-XXXX, UC-XXXX) in a block or test name.**
- **1.2 IDs in leading-line comments** — at the very top of the test file, write `// UC-XXXX: {name}` and `// SLICE-NNN: {name}`. Immediately above each `describe` group derived from a top-level bullet, write `// SC-XXXX: {short description}` (or `// FR-XXXX: ...`). Above each `it` test, write the relevant `// SC-XXXX: ...` comment for the scenario it covers.
- **1.3 Precise, realistic values** — assertions pin exact values. Compute expected values explicitly when they derive from inputs.
- **1.4 Verbose explanatory comments** — every test (or every scenario block of tests) gets a multi-line comment with what's being tested, why it matters, and a concrete example.

Lifecycle:

- `objective: implement` (mode: default): `it` bodies are empty (or contain a single `expect.fail("not implemented")` placeholder when the runner requires it). Initial run must be RED.
- `objective: coverage` (mode: cover): `it` bodies contain the full assertions implied by the bullet text, following rule 1.3 (precise values). Initial run must be GREEN.

Add imports the assertions need.

**Consult referenced non-canonical tests.** If the slice frontmatter has a `references:` list (populated by `/m:plan` in cover mode when the developer accepted entries from `/m:cover`'s "Non-canonical Test Paths"):

- For every entry, `Read` the referenced file **before** you write the canonical test. Lift fixtures, setup blocks, seed data, and assertion patterns into the new integration test as first-class content — not verbatim copies. The reference is input; the canonical test is what Molcajete owns.
- The referenced tests are **not** substitutes for integration coverage. Do not weaken the scenario coverage because a referenced unit test "already covers it" — every SC in the slice's `covers` needs an integration assertion at the driver port.
- Referenced files with `mode: migrate` are held for deletion after 8.9 succeeds (see 8.10.a). Do not delete them here.

Write the test file. Create parent directories as needed.

### 8.5 Phase 1 check — initial test run

Run the scoped test command against the derived test file only.

- **mode: default** / `objective: implement` — expect RED.
  - GREEN → run the mutation check (8.8). If mutation turns it RED, the implementation already satisfies the slice; skip Phase 2 and record outcome.
  - **STOP:** If GREEN after mutation, halt with an escalation under `.molcajete/escalations/{id}.md`.
  - RED → proceed to 8.6 (Phase 2 implement).
- **mode: cover** / `objective: coverage` — expect GREEN.
  - GREEN → proceed to 8.6 (Phase 2 add assertions) and then mutation check.
  - **STOP:** RED → halt with an escalation under `.molcajete/escalations/{id}.md`: "Coverage slice {id} scaffold is RED before tests are added — existing implementation appears broken or the scaffold targets the wrong files. Investigate via `/m:fix`."

### 8.6 Phase 2 — Implement or assert

- **mode: default** / `implement` slice: write production code in its final form to satisfy the slice's Contracts (Types / API Surface / Behavior) and turn the scaffold GREEN. Fill empty `it` bodies with concrete assertions as you implement (per Principle 1.3 — precise values). Honour `dependency_exports` signatures verbatim.
- **mode: cover** / `coverage` slice: add more assertions to the scaffold to close coverage on `files.modify`. **Do not write production code.** The only exception is the testing skill's reactive refactor rule for genuinely untestable seams — in cover mode this is rare and surfaces as a `/m:fix` escalation, not a code change here.

**Apply Principle 5 (universal software craft) while writing code.** Before adding a new helper, grep for an existing one and call it. Keep functions small (split when they outgrow one screen). Keep boundaries clear (no leaking internals across modules). If you find yourself extending a file past its responsibility, split the file. Never duplicate code that already exists.

**Apply Principle 5's Code Comments rules** (loaded in Step 2):

- **5.1 Spec traceability** — at the top of every production file the build creates, write `// FEAT-XXXX: {feature name}`, `// UC-XXXX: {use case name}`, `// SLICE-NNN: {slice name}`. Above every function that satisfies specific scenarios, write `// SC-XXXX, SC-YYYY: {short description}`.
- **5.2 Function header comments** — every non-trivial function gets a What / Why / Non-obvious comment block above its declaration. Trivial accessors can skip.
- **5.3 Inline comments** — every group of lines that accomplishes a discrete step gets a comment explaining what the step does and why. If a function has three blocks of work, it has at least three inline comments.
- **5.4 Be generous, especially in complicated code** — comment generously in control flow, external-system interactions, domain-heavy logic, and performance-sensitive sections. When in doubt, comment.

**Reconcile first when the slice is `dirty`.** If this slice carries `status: dirty` (its UC changed via `/m:fix`, `/m:change`, or `/m:spec`), before writing any new code or assertion, reconcile the existing canonical test file and touched production files against the current UC spec (re-read in Step 5) per the testing skill's "Reconciling a Dirty Slice":

- Delete test cases, assertions, comments, and production code that serve an `SC-`/`FR-`/`NFR-` the UC no longer contains (Principle 1.5 and 5.5).
- Rewrite changed scenarios' assertions to the new expected values — do not keep the old expectation alongside.
- Add positive test cases for every new FR and every new behaviorally-observable NFR (authz, validation, error handling, idempotency — anything reachable through the driver port).
- Never write a test that asserts a retired behavior now fails or is absent, and never leave a comment narrating what the code used to do.

Run the scoped test + coverage commands.

- RED → retry up to 3 more times. Each retry: the only context is the failing test output plus the slice frontmatter. Do NOT re-read the slice body, dependency exports, or modify files.
- **STOP:** On the 3rd RED, halt with an escalation under `.molcajete/escalations/{id}.md` with the last test output.
- GREEN → proceed to **8.7 Coverage gap resolution** (do NOT skip to mutation when any dimension is below its floor).

### 8.7 Coverage gap resolution (blocking)

Parse the per-file coverage output into the four-dimension table per touched file. For every touched file (every path in `files.modify` and `files.create`), compare each dimension against its floor from Step 3's resolved `testing.thresholds`:

| Dimension  | Floor | Actual | Status |
|------------|-------|--------|--------|
| lines      | `<n>` | `<n>`  | OK / GAP |
| statements | `<n>` | `<n>`  | OK / GAP |
| branches   | `<n>` | `<n>`  | OK / GAP |
| funcs      | `<n>` | `<n>`  | OK / GAP |

If every dimension is OK for every touched file → proceed to 8.8 (mutation check).

If any dimension is GAP for any touched file, run the **gap-resolution loop** (max 3 iterations per slice):

**1. Collect the gap report.** From the runner's coverage output, list every uncovered location concretely:

- Uncovered line ranges (e.g., `src/LPVault.sol:48-52`).
- Uncovered branches with the conditional location and the side (e.g., `src/LPVault.sol:74 (else of `if (amount == 0)`)`).
- Uncovered functions by name and file.

**2. Classify each gap** per the testing skill's "Gap classification" rules:

- **Reachable behavior** — gap maps to an `SC-XXXX` in the UC spec that the current test plan does not assert (or asserts only the happy path).
- **Defensive / unreachable** — gap is a branch or function that cannot be reached from any specified scenario.
- **Orphaned assertion / dead behavior** — the uncovered code serves an `SC-`/`FR-`/`NFR-` the UC spec no longer contains (see the testing skill's gap classification).

Re-read the UC spec body (loaded in Step 5) for every gap you classify — the SC list is the only valid grounding. A gap you cannot map to any current `SC-XXXX`, cannot justify as defensive, and cannot tie to a retired scenario (orphaned) is a spec gap; halt with an escalation suggesting `/m:fix` or `/m:change`.

**3. Resolve each gap.**

- **Reachable** → add the missing test case to the test file. If the new assertion belongs to a scenario not yet listed in the slice's `## Tests` body, update the slice. If the `SC-XXXX` is not yet in the slice's `covers` frontmatter, add it.
- **Defensive / unreachable** → delete the code. If it must stay for runtime safety (rare, e.g., reentrancy guard on a path the type system can't prove safe), apply the runner's per-branch ignore directive with a one-line comment naming the reason. Bare "this is hard to test" is not a valid reason.
- **Orphaned assertion / dead behavior** → delete the code, its comments, and any test case that still references the retired scenario (Principle 1.5). Do not keep it alive with a test asserting the behavior is gone.

**Raising any threshold is forbidden.** Do not edit `.molcajete/settings.json` to make the gate pass. If the floor feels wrong, surface that to the user via AskUserQuestion as a separate decision — never as a workaround.

**4. Re-run scoped tests + coverage.** Loop back to the table at the top of 8.7. If all dimensions OK → 8.8. If gaps remain → next iteration.

- **STOP:** On the 3rd iteration with gaps still present, halt with an escalation under `.molcajete/escalations/{id}.md`. The escalation lists every remaining gap, its classification (or "unclassifiable"), and the file:line. Do NOT proceed to mutation; do NOT flip status in Step 9.

### 8.8 Mutation check

For each file in `files.modify` (and `files.create` if present), rewrite every exported function/binding named in `slice.provides` to throw `new Error('MUTANT')` (or language-equivalent). Save originals first. Run the scoped test command. Restore originals in a `finally`.

- `implement` slice: mutation is only run when the scaffold started GREEN unexpectedly (Phase 1 check). Success = RED.
- `coverage` slice: mutation is mandatory after Phase 2. Success = RED. GREEN after mutation means added assertions are vacuous; retry up to 3 more times passing only the mutation report plus the slice frontmatter.
- **STOP:** If mutation is still GREEN after 3 retries (coverage) or after the initial check (implement), halt with an escalation under `.molcajete/escalations/{id}.md` containing the mutation report.

**Never leave a file mutated on exit.** Verify restoration by re-reading and comparing to the saved original.

### 8.9 Verification block (blocking)

Before 8.10 (Record outcome), emit this exact checklist with each box ticked. If any box cannot be honestly ticked, halt with an escalation under `.molcajete/escalations/{id}.md`; do NOT proceed to 8.10 or Step 9.

- [ ] Test file written at: `<path>`
- [ ] Initial run was: `<RED|GREEN>` (expected: `<RED|GREEN>`) — runner output captured below
- [ ] Phase 2 final run: GREEN — runner output captured below
- [ ] Per-file coverage on every touched file meets ALL FOUR floors (lines / statements / branches / funcs). For each touched file, paste a row: `<file>: lines <a>%, statements <b>%, branches <c>%, funcs <d>% (floors: <L>/<S>/<B>/<F>)`. Every dimension on every file must be ≥ its floor.
- [ ] 8.7 gap-resolution: every reported gap was either resolved by added scenario test (with SC-XXXX referenced) or deleted as defensive code (with reason). List each resolved gap and its disposition.
- [ ] Mutation check: RED for every mutated export in `provides`
- [ ] Mutated files restored (verified by re-read diff against saved originals)

### 8.10 Record per-slice outcome

Two writes — one to the slice frontmatter (the source of truth for status), one to the JSON record (durable diagnostics).

**Slice frontmatter** — set `status: implemented` on the slice's `SLICE-NNN-{name}.md` file. This is the source of truth that downstream `/m:build` runs read for dependency gating and that UC + Feature roll-up consume.

**Durable record** — write `.molcajete/slices/{id}.json` for diagnostics (mutation logs, retry counts, timestamps):

```json
{
  "id": "{id}",
  "use_case": "{use_case}",
  "feature": "{feature}",
  "objective": "{objective}",
  "status": "implemented",
  "plan_id": "<plan-id>",
  "completed_at": "{ISO timestamp}",
  "files_touched": [...],
  "covers": [...],
  "summary": "{one paragraph: what got built / what got covered, key decisions, anything downstream slices should know}"
}
```

The JSON file is kept for diagnostic context only. Status decisions read from the slice frontmatter; the JSON is no longer consulted as a state authority.

**Handle `references` with `mode: migrate`.** For every entry in the slice frontmatter's `references:` list whose `mode` is `migrate`:

1. Emit an AskUserQuestion: "The referenced test `{path}` was migrated into the canonical integration test at `{derived-test-path}`. Delete the original file now?"
2. Options: **"Delete"** (removes the original file), **"Keep"** (leaves the original in place — note in Step 11 report that the migration is deferred).
3. On "Delete", remove the file. Record the deletion (or the deferral) in the Step 11 report for this task.

Never delete a referenced file when its `mode` is `reference` — those stay in place by definition.

## Step 9: Update Plan, Changelogs, and Statuses

Step 9 runs at the end of every `/m:build` invocation regardless of individual task outcomes. It has two parts:

- **9.A — Success-gated writes** (plan checkboxes, CHANGELOG entries): only applied for tasks whose 8.9 verification block emitted every box ticked. Failed tasks are skipped here.
- **9.B — Idempotent status rollup** (UC and Feature frontmatter): applied **unconditionally** over the entire plan's scope. The rollup is a pure function of the slice frontmatter currently on disk; a failed slice stays `pending`/`dirty`, which is exactly what the rollup should read. Running it every time — even when nothing changed — keeps UC and Feature status honest against on-disk reality.

### 9.A Success-gated writes

For every task in this run whose 8.9 verification block was fully ticked:

1. **Update `plan.md`.** Flip each completed task/sub-task checkbox from `[ ]` to `[x]`. Preserve the rest of the file verbatim.
2. **Update the UC's CHANGELOG.md.** Use the `uc-log` shared skill to:
   - Locate the changelog entry whose `plan:<plan-id>` matches and whose corresponding slices are now all `implemented`.
   - Flip its status from `dirty` to `implemented` and move the line from `TODO:` to `DONE:` (prepended at the top of `DONE:`).

Tasks that failed 8.9 skip 9.A entirely — their plan checkbox stays `[ ]`, their CHANGELOG entry stays `dirty` in `TODO:`.

### 9.B Idempotent status rollup (unconditional)

Regardless of which tasks passed or failed 8.9, walk the entire plan's scope and rewrite UC and Feature frontmatter from current on-disk state.

**Scope resolution.** From `plan.md` (parsed in Step 4), enumerate:

- Every `UC-XXXX` heading in the plan.
- Every `FEAT-XXXX` heading in the plan.

This set is fixed by the plan, not by which slices completed this run. A plan that references three UCs across two features rolls up all three UCs and both features on every `/m:build` invocation.

**Per-UC rollup.** For each UC in scope, resolve its support folder (`specs/features/{module}/FEAT-XXXX-{slug}/UC-XXXX-{slug}/`) and:

1. List every `SLICE-NNN-*.md` file in the folder.
2. Read each slice file's frontmatter `status:` value.
3. Apply the `status-rollup` skill's roll-up rule to the collected values:
   - all children `implemented` → parent `implemented`
   - at least one child `dirty`, OR mix of `implemented` and `pending`/`dirty` → parent `dirty`
   - every child `pending` or `dirty` with none `implemented` → parent `pending`
4. Write the resulting value to the UC's `UC-XXXX-{slug}.md` frontmatter `status:` field — **overwrite regardless of prior value**. If the value did not change, still record the read/write in the Step 10 mutation report (`After = unchanged`).
5. If a UC has zero slice files, leave its frontmatter untouched and record `After = unchanged` with reason `no slices on disk yet`.

**Per-Feature rollup.** For each Feature in scope, resolve its folder (`specs/features/{module}/FEAT-XXXX-{slug}/`) and:

1. List every `UC-XXXX-*.md` file in the folder (siblings of `REQUIREMENTS.md`; ignore `USE-CASES.md` / `ARCHITECTURE.md` / `REQUIREMENTS.md` themselves).
2. Read each UC file's frontmatter `status:` value.
3. Apply the same roll-up rule.
4. Write the resulting value to `REQUIREMENTS.md`'s frontmatter `status:` — **overwrite regardless of prior value**. Record the read/write in the Step 10 mutation report.
5. If a Feature folder has zero UC spec files, leave `REQUIREMENTS.md` untouched and record `After = unchanged` with reason `no UCs on disk yet`.

The CHANGELOG is for context only. Status decisions read from the artifact frontmatter, not from the changelog. The rollup never reads or modifies CHANGELOG.md entries — that is 9.A's concern.

## Step 10: Status Mutation Report (blocking)

Before Step 11, emit this exact table. It must contain **one row for every artifact in the plan's scope** — every touched slice, every UC in the plan, every Feature in the plan, every CHANGELOG entry that could have flipped, every plan.md checkbox that could have flipped. Every row records what happened to that artifact this run, including rows for artifacts that were intentionally left unchanged. Silent under-firing is not permitted.

- **If a slice failed (escalation written), do NOT flip its changelog entry or its slice's frontmatter `status` — leave them in the `dirty` state.** The user resolves the escalation and re-runs `/m:build` for that task. List the skipped artifacts as `unchanged` rows in the table below with the reason `slice failed — see escalation`.
- **UC and Feature rollup rows always appear** (per Step 9.B's unconditional rollup), whether or not the value moved. If the value did not change (still `pending`, still `dirty`, still `implemented`), the `After` column reads `unchanged` and a footnote-linked reason column names why (e.g., `3 of 5 sibling slices still pending`, `all UCs already implemented — no change`, `no slices on disk yet`).

| Artifact path                          | Field                | Before  | After                    | Reason (if unchanged)                            |
|----------------------------------------|----------------------|---------|--------------------------|--------------------------------------------------|
| `<slice path>`                         | status               | `<prev>`| implemented / unchanged  | e.g. `slice failed — see escalation`             |
| `<UC path>`                            | status               | `<prev>`| `<new>` / unchanged      | e.g. `2 of 4 sibling slices still pending`       |
| `<FEAT REQUIREMENTS.md>`               | status               | `<prev>`| `<new>` / unchanged      | e.g. `all UCs already implemented — no change`   |
| `<UC CHANGELOG.md>`                    | entry `{plan-id}`    | dirty   | implemented / unchanged  | e.g. `entry unchanged — slice failed`            |
| `<plan.md>`                            | checkbox `T-NNN[.N]` | `[ ]`   | `[x]` / unchanged        | e.g. `task failed 8.9`                           |

Row expectations:

- Every slice touched by `$ARGUMENTS` gets exactly one row.
- Every UC named in the plan's `## FEAT-XXXX / ### UC-XXXX` headings gets exactly one row.
- Every Feature named in the plan's `## FEAT-XXXX` headings gets exactly one row.
- Every plan.md checkbox for the requested tasks gets exactly one row.
- Every UC's CHANGELOG entry matching this `plan-id` gets exactly one row.

If the table contains no `UC-` or `FEAT-` rollup rows, Step 9.B did not run — halt and re-execute Step 9.B before continuing.

## Step 11: Report

Tell the user:

- The plan ID and mode.
- For each completed task: slice ID, name, objective, files touched, materialized test file path, and per-touched-file final coverage on all four dimensions (lines / statements / branches / funcs). In `mode: mixed`, group the completed-task list under two sub-headings — "Coverage (pinned existing behavior)" and "Implement (new behavior)" — so the reader can tell which slices pinned current behavior versus which built new code.
- Any gaps that the 8.7 loop resolved by adding scenario tests or deleting defensive code — one line per resolution naming the location and the disposition.
- For each escalation (if any): slice ID and escalation file path.
- Any migration deletions or deferrals from Step 8.10's `references` handling — one line per referenced file.
- **Final status for every UC and Feature in the plan's scope.** One line per artifact regardless of whether it changed this run. Format: `FEAT-XXXX-{slug}: <status>` and `UC-XXXX-{slug}: <status>`. This is a snapshot of on-disk truth after Step 9.B's rollup — the user should be able to read this section and know the current state of every feature the plan touches without opening any files.
- Plan checklist progress (e.g., "3 of 5 tasks complete in plan `{plan-id}`").

If the host project's coverage collector wasn't available (per Step 7) and you estimated against the floor, note that explicitly: "Coverage was estimated; `specs/TECH-STACK.md` does not declare a coverage collector for module `{module}`."

If every task in the plan is now complete, suggest: "Plan `{plan-id}` is fully executed."

If unfinished tasks remain, suggest: "Next: `/m:build {plan-id} {next-T-NNN}` to continue."
