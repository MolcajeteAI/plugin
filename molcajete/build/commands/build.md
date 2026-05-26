---
description: Implement a plan task — production code and tests via the test-first build loop
model: claude-opus-4-6
argument-hint: "<plan-name> <T-NNN>"
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

You implement a single plan task by running a two-subagent loop: an **Implementer** writes a test then production code for one behavior; a **Validator** runs the suite and the coverage check. The loop continues until every behavior named in the task is covered and the Validator returns `pass`. No worktrees, no headless sessions — the user is present and commits when ready.

**Do NOT commit code.** The user reviews your output and commits themselves.

**Arguments:** $ARGUMENTS

**All user interaction MUST use the AskUserQuestion tool.** Never ask questions as plain text in your response.

## Step 1: Load Skills

Read all three skills that govern this command:

1. `${CLAUDE_PLUGIN_ROOT}/build/skills/implementing/SKILL.md` -- plan authority, state transitions, Implementer + Validator procedures, error handling
2. `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md` -- subagent role definitions, outer-edge mocking, Five Exit Doors, reading `prd/tech-stack.md`, coverage gate, reactive refactor
3. `${CLAUDE_PLUGIN_ROOT}/plan/skills/planning/SKILL.md` -- plan JSON schema reference

Follow these skills' rules for all subsequent steps.

## Step 2: Verify Prerequisites

1. Verify `prd/PROJECT.md` and `prd/MODULES.md` both exist. If either is missing:

   "Project foundation not found. Run `/m:setup` first to create PROJECT.md and MODULES.md."

   Then stop.

2. Ensure `.molcajete/settings.json` exists and contains `testing.threshold`:
   - If the file does not exist, create `.molcajete/` and write `{"testing": {"threshold": 80}}`. Tell the user: "Initialized `.molcajete/settings.json` with default `testing.threshold = 80`. Edit it to change the coverage gate."
   - If the file exists but `testing.threshold` is missing, merge in `testing.threshold = 80` (preserving every other key) and write it back. Tell the user the same one-liner.
   - If `testing.threshold` is already set, use that value.

3. Verify `.molcajete/plans/` directory exists. If missing:

   "No plans directory found. Run `/m:plan` first to generate a plan."

   Then stop.

## Step 3: Parse Arguments

Parse `$ARGUMENTS` for two required tokens:

1. **Plan name** -- the directory name under `.molcajete/plans/` (e.g., `202604021530-login`)
2. **Task ID** -- the task identifier (e.g., `T-001`)

If `$ARGUMENTS` is empty or contains fewer than two tokens:

1. List available plans by globbing `.molcajete/plans/*/plan.json`
2. Tell the user:

   "Usage: `/m:build <plan-name> <T-NNN>`\n\nAvailable plans:\n{list each plan directory name}"

   Then stop.

Verify the plan exists: glob `.molcajete/plans/{plan-name}/plan.json`. If not found:

1. List available plans
2. Tell the user: "Plan '{plan-name}' not found." with the list of available plans

Then stop.

## Step 4: Load Plan

1. Read `plan.json` from `.molcajete/plans/{plan-name}/plan.json`
2. Read `plan.md` from `.molcajete/plans/{plan-name}/plan.md` (if it exists)
3. Parse the plan JSON. Verify it has `tasks` array and required top-level fields (`title`, `status`, `scope`, `base_branch`).

## Step 5: Validate Task

1. Find the task with matching `id` in the plan's `tasks` array. If not found:

   "Task {T-NNN} not found in plan '{plan-name}'. Available tasks:\n\n{list each task: id, title, status}"

   Then stop.

2. If the task's status is `implemented`:

   Count implemented vs. total tasks. Tell the user:

   "Task {T-NNN} ({title}) is already implemented. Plan progress: {X}/{Y} tasks done."

   If other pending tasks exist with met dependencies, list them as candidates. Then stop.

3. Check dependencies: for each ID in `task.depends_on`, verify the corresponding task has `status: "implemented"`. If any dependency is not met:

   "Task {T-NNN} is blocked. These dependencies are not yet implemented:\n\n{list each unmet dep: id, title, status}"

   Then stop.

4. Present the task to the user via AskUserQuestion:

   - Question: "**{task.id}: {task.title}**\n\n**Intent:** {task.intent}\n**Use Case:** {task.use_case}\n**Feature:** {task.feature}\n**Module:** {task.module}\n\n**Description:**\n{task.description}\n\n**Files to modify:**\n{task.files_to_modify as bulleted list}\n\n{if task.sub_tasks}**Sub-tasks:** {count} sub-tasks{/if}\n\nReady to implement?"
   - Header: "Build Task"
   - Options: "Proceed" / "Cancel"

   If "Cancel", stop.

## Step 6: Load Task Context

Issue all reads in a single parallel batch (one assistant turn, multiple tool_use blocks). This context is essential -- the model must understand the full project, the feature requirements, and the task details to implement correctly.

### 6.1 Project-Level Context

Read all project-level files. These establish the shared vocabulary, tech stack, domains, actors, and feature landscape:

- `prd/PROJECT.md` -- project description (required)
- `prd/TECH-STACK.md` -- technology choices, project organization, and how the project runs (required for the loop; the Implementer reads the relevant `Module` section)
- `prd/ACTORS.md` -- system actors for consistent actor references across specs (if exists)
- `prd/DOMAINS.md` -- domain registry so you know what domains exist (if exists)
- `prd/FEATURES.md` -- master feature registry showing what is already implemented (if exists)
- `prd/GLOSSARY.md` -- shared terminology for consistent language (if exists)
- `prd/MODULES.md` -- module registry (required)
- `.molcajete/settings.json` -- testing threshold and project settings (required)

### 6.2 Feature and Use Case Context

Read the feature-level and use-case-level specs. These define WHAT the code must do:

- **REQUIREMENTS.md** -- feature requirements (EARS syntax, functional/non-functional, acceptance criteria). Derive the path from the UC file's parent feature directory: `prd/modules/{module}/features/FEAT-XXXX-{slug}/REQUIREMENTS.md`
- **ARCHITECTURE.md** -- architecture context, Code Map, data model, integration points. Read from `task.architecture` (if non-empty path)
- **UC file** -- the use case being implemented. Glob `prd/modules/*/features/*/use-cases/{task.use_case}-*.md` to find and read it. Contains the objective, preconditions, trigger, scenarios with Given/Steps/Outcomes/Side Effects

### 6.3 Design Assets

Check for high-resolution design files (screenshots, mockups, Figma exports) referenced in the task description, plan.md task section, or the feature's ARCHITECTURE.md. If any design assets are provided (image files, annotated screenshots, etc.), read them. **When designs are provided, the implementation MUST match them pixel-for-pixel** -- layout, spacing, colors, typography, component structure. Designs are the source of truth for UI work.

### 6.4 Plan Context

The task object from plan.json is already parsed (Step 4). Now load the narrative:

- **Plan.md task section** -- Locate the `### T-NNN` section in `plan.md`. If the task ID has a sub-task format (`T-NNN-M`), use the parent ID (`T-NNN`) to find the section.
- **Prior task summaries** -- For each task ID in `task.depends_on`, read its `summary` field from `plan.json`. These provide context about what was already built and key decisions made.

## Step 7: Validate plan.md

If `plan.md` is missing or the `### {task.id}` section (or parent `### T-NNN` for sub-tasks) is not found:

"Companion plan.md is missing or the task section was not found. Regenerate the plan with `/m:plan` (or `/m:reverse-plan` for coverage plans) before running `/m:build`."

Then stop.

## Step 8: Update Plan State (in_progress)

1. Set `task.status` to `"in_progress"` in the parsed plan JSON
2. If the plan's top-level `status` is `"pending"`, set it to `"in_progress"`
3. Write the updated plan JSON back to `.molcajete/plans/{plan-name}/plan.json`

## Step 9: Resolve Module Tech Stack

From `task.files_to_modify`, determine the module whose `Directory` in `prd/TECH-STACK.md` contains those files. Extract that `Module` section verbatim — it is what the Implementer will receive.

If no module's `Directory` covers the task's files, or the matched module is missing `Framework` or `Key libraries` rows (or those rows still contain template placeholders like `{e.g., ...}`), stop and tell the user:

"`prd/TECH-STACK.md` is incomplete for the module containing {first file in files_to_modify}. Run `/m:setup` to fill in the `Framework` and `Key libraries` rows for that module, then retry."

**Test runner resolution.** The `Testing` row is allowed to be blank — most projects don't need to pre-populate it. Resolve the runner in this order:

1. If `Modules.{name}.Testing` in `prd/TECH-STACK.md` is filled and not templated, use it.
2. Otherwise, infer the runner by reading the module's manifest once and applying the inference rules in `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md` → "Runner Inference". This is a single file read per build (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, or equivalent).
3. If inference is ambiguous (e.g., both Jest and Vitest in devDependencies) or the manifest is unrecognized, ask via `AskUserQuestion`:
   - Question: "Could not unambiguously infer a test runner for module **{name}**. Manifest signals: {signals}. Which runner should I use?"
   - Header: "Test Runner — {name}"
   - Options: list the candidates the inference found; `Other` for free-form.

Whatever runner is resolved, use it for the rest of the build. Do not write it back to `prd/TECH-STACK.md` unless the user asks.

Determine the project's test and coverage commands. Coverage is **scoped to the touched files**, not the whole project — the Validator only judges what this task changed.

1. If `.molcajete/settings.json` `testing.commands.test` and `testing.commands.coverage` are set, use them as base commands. Both should accept a `{paths}` placeholder for file-scoping; if the user's commands don't, append the runner's scoping flag (below) when the runner is known.
2. Otherwise, derive conventional commands from the resolved runner. Both the test runner and the coverage filter must be scoped to the union of `task.files_to_modify` and the files the Implementer changes during the loop (the **touched set**):

   | Runner | Scoped test command | Scoped coverage flag |
   |---|---|---|
   | Vitest | `npx vitest run {test_paths}` | `--coverage --coverage.include={src_path}` (one `--coverage.include` per touched source file) |
   | Jest | `npx jest {test_paths}` | `--coverage --collectCoverageFrom={src_path}` (one flag per touched source file; quote globs) |
   | pytest | `pytest {test_paths}` | `--cov={src_module_or_dir}` (one `--cov` per touched module/dir) |
   | go test | `go test {pkg_paths}` | `-cover -coverpkg={pkg_paths}` |
   | cargo test | `cargo test {test_filter}` | `--lib` plus `cargo llvm-cov --include-files {src_path}` if available |

   If the runner is unknown, halt with: "Cannot derive test command for runner '{name}'. Set `testing.commands.test` and `testing.commands.coverage` in `.molcajete/settings.json` (use `{paths}` as the touched-files placeholder)."

3. **Touched set discovery.** Before each Validator call, build the touched set as the union of:
   - `task.files_to_modify` (production files the planner expected to change)
   - The files actually changed by the Implementer in any round so far this task (tracked across iterations)
   - Their colocated or sibling test files (per the module's existing test layout)

   Translate the touched set to runner-appropriate test_paths/pkg_paths/src_paths arguments before substituting into the command.

## Step 10: Implement — Two-Subagent Loop

Check `task.sub_tasks`:

### Path A: No Sub-Tasks (sub_tasks is null)

Run the build loop directly on the task.

#### 10.A.1 Loop Setup

Initialize loop state:
- `behaviors_covered`: empty list
- `validator_feedback`: null
- `iterations`: 0
- `max_iterations`: 10
- Create `.molcajete/plans/{plan-name}/runs/` if it does not exist
- Open `.molcajete/plans/{plan-name}/runs/{task.id}.log` for appending each round

#### 10.A.2 Loop Body

Repeat until the task is done or `iterations >= max_iterations`:

1. Increment `iterations`.

2. **Capture the test-file set before the round.** Glob the task's expected test paths (or the conventional test directories for the module: `**/__tests__/`, `**/*.test.*`, `**/*.spec.*`, `**/test_*.py`, `*_test.go`, etc., scoped to the module's `Directory`). Record the set as `tests_before`.

3. **Implementer subagent.** Use the Agent tool with `subagent_type: general-purpose`. The prompt must contain:
   - Skills to load: `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/build/skills/implementing/SKILL.md`.
   - Task description and intent (`implement` or `cover`).
   - Architecture doc contents (from `task.architecture`).
   - The verbatim `Module` section of `prd/tech-stack.md` resolved in Step 9.
   - `behaviors_covered` so far.
   - `validator_feedback` from the previous round, if any.
   - Instruction: pick the next uncovered behavior named in the task description; **write the test for that behavior first**, then write the production code in its final form. Return: list of files changed, the behavior just covered, a one-line note.
   - Refuse to mark the task done — only the orchestrator does that.

4. **Verify test-first order.** Capture `tests_after` the same way as step 2. If `tests_after` does not contain at least one new test path AND no existing test file was touched (check mtimes if needed), treat this round as a failure:
   - Set `validator_feedback = "Implementer must write a test before production code; no new or modified test file was observed in this round."`
   - Append the round to the log with this failure.
   - Continue the loop.

5. **Validator subagent.** Use the Agent tool with `subagent_type: general-purpose`. The prompt must contain:
   - Skills to load: `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md`.
   - The list of files changed by the Implementer this round.
   - The cumulative **touched set** for this task (per Step 9.3).
   - The fully-substituted test command and coverage command from Step 9 — scoped to the touched set.
   - The threshold from `.molcajete/settings.json` `testing.threshold`.
   - Instruction: run both commands; do NOT read the Implementer's reasoning; the coverage gate applies **only to the touched files**, not the whole project; return exactly one of `pass`, `tests_failed{failures}`, or `coverage_low{gaps}`. `coverage_low{gaps}` must list per-file uncovered branches limited to the touched set. Include enough structured detail in failure cases that the Implementer can fix without re-reading the suite.

6. **Append the round to the log** with: iteration number, behavior name, files changed, Implementer note, Validator outcome, failure detail (if any).

7. **Loop control:**
   - On `pass`: append the behavior to `behaviors_covered`. If every behavior named in the task description is now in `behaviors_covered`, exit the loop with success. Otherwise, clear `validator_feedback` and loop back to step 2.
   - On `tests_failed` or `coverage_low`: set `validator_feedback` to the structured failure detail. Loop back to step 2. Do not append to `behaviors_covered`.

#### 10.A.3 Iteration Cap

If the loop exits because `iterations >= max_iterations` without success, do NOT mark the task implemented. Pause and ask the user via AskUserQuestion:

- Question: "Task {task.id} did not converge after {max_iterations} Implementer + Validator rounds.\n\nLast Validator outcome: {summary}\n\nFull log: `.molcajete/plans/{plan-name}/runs/{task.id}.log`\n\nWhat next?"
- Header: "Loop Paused"
- Options: "Mark task failed (I'll investigate)" / "Continue for another 10 iterations" / "Cancel"

Act on the user's choice. Do not silently retry past the cap.

### Path B: With Sub-Tasks (sub_tasks is an array)

Sub-tasks are a context-budget split. The two-subagent loop runs inside each sub-task the same way it runs at the parent-task level. Sub-tasks do not represent Red/Green/Refactor phases.

Iterate through sub-tasks in order, respecting `depends_on`:

For each sub-task:

1. **Check dependencies** -- For each ID in `sub_task.depends_on`, verify the corresponding sibling sub-task has `status: "implemented"`. If a dependency has `status: "failed"`, mark this sub-task and the parent task as `failed` and stop.

2. **Mark in_progress** -- Set `sub_task.status` to `"in_progress"` and write plan.json.

3. **Run the loop** -- Apply the loop in Path A 10.A.1–10.A.3, scoped to the sub-task's `description` and `files_to_modify`. The sub-task inherits `intent`, `use_case`, `feature`, `module`, and `architecture` from the parent task. The coverage gate runs only at the parent-task level after all sub-tasks complete (see Step 11).

4. **Update status** -- Set `sub_task.status` to `"implemented"` with `sub_task.summary`, or `"failed"` with `sub_task.errors`. Write plan.json.

5. **Handle failure** -- If the sub-task failed:
   - Set the parent `task.status` to `"failed"`
   - Set `task.errors` to `["Sub-task {sub_task.id} failed: {sub_task.errors}"]`
   - Write plan.json
   - Report the failure to the user and stop

After all sub-tasks complete successfully, run one final Validator pass at the parent-task level to confirm the full suite still passes and coverage is met. Then proceed to Step 11.

## Step 11: Update Plan State (final)

1. **Task status:**
   - If the loop exited with `pass` and all named behaviors covered: set `task.status` to `"implemented"` and write `task.summary` describing what was implemented, key decisions, and watch-outs for dependent tasks.
   - If the loop exited at the iteration cap and the user chose "Mark task failed", OR a hard fault occurred: set `task.status` to `"failed"` and write `task.errors` describing what went wrong.

2. **Plan-level status:**
   - Count tasks by status
   - If ALL tasks are `"implemented"`: set plan `status` to `"implemented"`
   - If this task `"failed"`: set plan `status` to `"failed"`
   - Otherwise: keep plan `status` as `"in_progress"`

3. Write the updated plan JSON to `.molcajete/plans/{plan-name}/plan.json`

## Step 12: Report

Tell the user what happened:

- **Iterations** -- number of Implementer + Validator rounds
- **Behaviors covered** -- list of behaviors the loop closed
- **Files created/modified** -- aggregated across all rounds
- **Coverage** -- final coverage percentage from the Validator's last `pass`
- **Task summary** -- the summary written to plan.json
- **Plan progress** -- "Completed {task.id} ({X}/{Y} tasks done)"
- **Run log** -- path to `.molcajete/plans/{plan-name}/runs/{task.id}.log`

Then suggest next steps:

- **If more pending tasks have met dependencies:** "Next tasks ready:\n{list: id, title}\n\nRun `/m:build {plan-name} <T-NNN>` to continue."
- **If all tasks are implemented:** "All {Y} tasks complete. Plan '{plan-name}' is fully implemented."
- **If this task failed:** "Task {task.id} failed. Review the run log, fix the issue, and re-run `/m:build {plan-name} {task.id}` to retry."
- **If remaining tasks are blocked:** "Remaining tasks are blocked by failed dependencies. Fix the failed tasks first."
