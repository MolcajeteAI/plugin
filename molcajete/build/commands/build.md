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

1. `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md` — Implementer rules, outer-edge mocking, runner inference, coverage gate
2. `${CLAUDE_PLUGIN_ROOT}/plan/skills/planning/SKILL.md` — plan JSON schema

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

   - Question: "**{task.id}: {task.title}**\n\n**Use Case:** {task.use_case}\n**Feature:** {task.feature}\n**Module:** {task.module}\n\n**Description:**\n{task.description}\n\n**Files to modify:**\n{task.files_to_modify as bulleted list}\n\n{if task.sub_tasks}**Sub-tasks:** {count} sub-tasks{/if}\n\nReady to implement?"
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

**Test runner resolution.** Resolve per the testing skill's "Runner Inference" section. If ambiguous, ask via `AskUserQuestion` with the candidates as options. Cache the resolution for this invocation.

**Test + coverage commands.** If `.molcajete/settings.json testing.commands.{test,coverage}` is set, use those (with `{paths}` as the touched-files placeholder). Otherwise derive from the resolved runner's conventional scoping flag (see testing skill). If unknown, halt with a setup hint.

**Touched set.** Before each Validator call, build the touched set as the union of:
   - `task.files_to_modify` (production files the planner expected to change)
   - The files actually changed by the Implementer in any round so far this task (tracked across iterations)
   - Their colocated or sibling test files (per the module's existing test layout)

   Translate the touched set to runner-appropriate test_paths/pkg_paths/src_paths arguments before substituting into the command.

## Step 10: Implement — Inline Loop

The orchestrator (you) is the Implementer. You write the test then the production code directly. You also run the test/coverage command via Bash and judge the result. No subagents — spawning one to run `npm test` is wasted Claude calls.

### Loop setup

- `behaviors_covered`: empty list
- `validator_feedback`: null
- `iterations`: 0
- `max_iterations`: 10
- Create `.molcajete/plans/{plan-name}/runs/` if missing; open `.molcajete/plans/{plan-name}/runs/{task.id}.log`.

### Loop body — repeat until done or `iterations >= max_iterations`

For each iteration:

1. **Pick the next uncovered behavior** named in `task.description`. If every named behavior is in `behaviors_covered`, run one final verify (step 4) and exit.

2. **Write the test first.** The test file must be created or extended before any production-code edit in this iteration. Use the resolved runner from Step 9 and the testing skill's conventions.

3. **Write production code in its final form.** No throwaway-minimum-then-refactor. If the task's `description` names uncovered code paths (coverage-recovery flavor), write only tests — touch production code only when a seam is genuinely untestable (reactive refactor).

4. **Run the scoped test + coverage commands via Bash** (the commands resolved in Step 9, substituted with the current touched set). Read the result yourself:
   - All scoped tests green + per-file coverage on every touched file ≥ `testing.threshold` → behavior done. Append to `behaviors_covered`. Clear `validator_feedback`. Loop to step 1.
   - Tests failed → set `validator_feedback` to the failure details. Loop to step 1 (you'll address them on the next iteration as part of the same behavior).
   - Coverage low → set `validator_feedback` to the per-file gaps. Loop to step 1.

5. **Append the round to the log** — iteration number, behavior name, files changed, outcome, failure detail if any.

6. On hard infra failure (connection refused, missing service, etc.), stop. Do not retry; surface to the user.

### Iteration cap

If `iterations >= max_iterations` without success, pause and ask via AskUserQuestion:

- Question: "Task {task.id} did not converge after {max_iterations} iterations.\n\nLast result: {summary}\n\nFull log: `.molcajete/plans/{plan-name}/runs/{task.id}.log`\n\nWhat next?"
- Header: "Loop Paused"
- Options: "Mark task failed (I'll investigate)" / "Continue for another 10 iterations" / "Cancel"

Act on the user's choice.

### Sub-Tasks

When `task.sub_tasks` is non-null, run the loop above per sub-task in dependency order, scoped to each sub-task's `description` and `files_to_modify`. Mark each sub-task `implemented` or `failed` in plan.json as you go. After all sub-tasks pass, run one final scoped test + coverage pass at the parent-task level (same Bash command as the loop) before proceeding to Step 11. If any sub-task fails, mark the parent failed and stop.

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
