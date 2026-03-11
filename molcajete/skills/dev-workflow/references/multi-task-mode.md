# Multi-Task Mode

You are implementing multiple tasks from a feature's tasks.md file. Follow this orchestration workflow to plan all tasks upfront and execute them in dependency-ordered waves with parallel subagents.

## Designated Agents

Each subagent in a wave delegates to these agents internally (read agent definitions before dispatching):

- **Developer** (`${CLAUDE_PLUGIN_ROOT}/agents/developer.md`) — implements code and tests from the plan
- **Reviewer** (`${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md`) — reviews code for correctness, security, performance

See `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/SKILL.md` for invocation protocol and handoff patterns.

## Step M1: Gather Context

Launch a `general-purpose` sub-agent using the Task tool to build a combined brief covering ALL selected tasks. The prompt must include the feature folder path(s) and all task details you extracted. The agent should:

- Read `prd/specs/{folder}/spec.md` — extract sections relevant to all selected tasks' use cases
- Read `prd/specs/{folder}/requirements.md` — extract acceptance criteria and functional requirements for all selected use cases (if exists)
- Read `prd/tech-stack.md` — extract architecture and conventions
- Read `CLAUDE.md` — extract project conventions
- Read `prd/changelog.md` — summarize what's already built (if exists)
- Scan `**/README.md` files (excluding `node_modules/`, `prd/`) in directories related to the tasks' scope — summarize existing patterns
- Read the project-management skill at `.claude/skills/project-management/SKILL.md`

The agent must return a structured brief in this format:
```
TASKS_BRIEF:
- Task {id}: {title}
  - Acceptance criteria: {criteria}
  - Complexity: {points}
  - Dependencies: {list, with status: complete/pending/in-selection}

DEPENDENCY_GRAPH:
  {task_id} -> {depends_on_task_id} [status: complete | in-selection]
  ...

EXECUTION_WAVES:
  Wave 1: [{task_ids}] — {rationale}
  Wave 2: [{task_ids}] — {rationale}
  ...

SPEC_EXCERPT:
{Sections from spec.md relevant to all selected tasks}

REQUIREMENTS_EXCERPT:
{Functional requirements and acceptance criteria for all selected use cases, or "No requirements.md found"}

TECH_CONTEXT:
- Stack: {relevant stack for these tasks}
- Conventions: {key conventions from CLAUDE.md and tech-stack.md}
- Architecture: {relevant architecture patterns}

EXISTING_PATTERNS:
{Summary of existing code patterns from README scans relevant to these tasks}

CHANGELOG_SUMMARY:
{What's already built in related domains, or "No changelog found"}

WARNINGS:
{Any issues: incomplete deps, missing spec sections, ambiguities — or "NONE"}
```

Use the returned brief as your context for all subsequent steps. Do NOT read these source files again yourself.

## Step M2: Clarify

Batch all ambiguities across all selected tasks into a single AskUserQuestion call. Examples:
- Unclear acceptance criteria on any task
- Multiple valid implementation approaches
- Missing information in the spec
- Conflicting requirements between tasks

If all tasks are clear, skip this step.

## Step M3: Plan All Tasks

Enter plan mode using EnterPlanMode. In plan mode:

1. Explore the codebase to understand existing patterns, related code, and where new code should go for ALL selected tasks.
2. Design a combined implementation plan. Write it to `prd/specs/{feature}/plans/{scope-slug}.md` (create the `plans/` directory if needed).

The plan must follow this structure:

```markdown
# Implementation Plan: {scope description}

## Overview
{Brief summary of what will be implemented across all tasks}

## Shared Decisions
{Architectural decisions, shared types, common patterns that apply across tasks}

## Execution Waves

- **Wave 1:** [{task_ids}] — {rationale for grouping}
- **Wave 2:** [{task_ids}] — {rationale, dependencies on wave 1}
- **Wave 3:** [{task_ids}] — {rationale, dependencies on wave 2}

## Task {id}: {title}
- **Files to create/modify:** {list}
- **Approach:** {implementation approach}
- **Integration notes:** {how this connects to other tasks}
- **Acceptance criteria:** {from tasks.md}

## Task {id}: {title}
...
```

3. Exit plan mode with ExitPlanMode to get user approval of the entire plan.

## Step M4: Execute Waves

Initialize session state:

```
SESSION_STATE:
  Completed: []
  Files created: []
  Files modified: []
  Key decisions: []
```

For each wave, execute the following sub-steps:

### M4a. Report Wave Start

Tell the user: "**Wave {W}/{total}:** Implementing {task list} (in parallel)"

### M4b. Launch Subagents in Parallel

For each task in the wave, launch a `general-purpose` Task subagent. **All subagents for a wave must be launched in a single message with multiple Task tool calls.**

Each subagent receives this prompt structure:

```
You are implementing task {task_id}: {title}

## Plan Excerpt
{The plan section for this specific task from Step M3}

## Session State
{Current session state — completed tasks, files created/modified, key decisions}

## Acceptance Criteria
{From tasks.md}

## Project Conventions (Condensed)
- Resolver delegation pattern: all resolver methods must be single-line delegations to helper functions
- Atomic design: atoms, molecules, organisms, templates, pages
- Mobile-first responsive design
- Lingui.js i18n: write UI text in Spanish (es-MX), translate to English
- Test files in __tests__/ sibling directories (frontend) or alongside code (Go)
- Tailwind CSS only, no hardcoded CSS
- Never add Biome ignore comments
- Never stage files or create commits
- Do not use the word "comprehensive" in any document
{Add stack-specific conventions based on the task}

## Workflow

Execute these steps in order:

### 1. Write Code
Implement the task following the plan excerpt. Follow all project conventions.
- Write clean, production-quality code
- Stay within the scope of THIS task only

### 2. Write Tests
Write tests for the code you created or modified:
- Place test files in __tests__/ sibling directories (frontend) or alongside the code (Go)
- Follow existing test patterns in the codebase
- Cover the acceptance criteria
- Include edge cases and error scenarios

### 3. Run Tests
Run the test suite:
- Run the specific tests you wrote
- Run the broader test suite for affected areas
- If tests fail, fix the code and re-run until green
- Do NOT skip failing tests

### 4. Quality Gate
Run these checks sequentially:

**Format check:** Run `gofmt -l` on changed `.go` files and/or `pnpm run format --check` on changed frontend files. Fix any issues.

**Lint check:** Run `golangci-lint run` on changed Go packages and/or `pnpm run lint` on changed frontend files. Fix any issues.

**Self-review (Reviewer agent):** Read the Reviewer agent definition at `${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md`. Review your own changes for: security issues, missing error handling, convention violations, performance concerns. Fix any CRITICAL or WARNING issues found.

**README updates:** For directories where files were created or deleted (skip node_modules/, dist/, build/, coverage/, vendor/, .git/, __tests__/, prd/, asset-only directories):
- If README.md exists: update file listing, diagrams, last-updated date as needed
- If README.md does not exist: create one following project conventions
- Read `.claude/skills/code-documentation/SKILL.md` and `.claude/skills/code-documentation/references/readme-template.md` for the template.

If code was changed during quality gate fixes, re-run tests.

## Return Format

Return EXACTLY this format:
```
RESULT: SUCCESS | FAILURE
TASK_ID: {id}
SUMMARY: {one-line description of what was implemented}
FILES_CREATED: [{list of file paths}]
FILES_MODIFIED: [{list of file paths}]
KEY_DECISIONS: [{list of notable decisions made, or "NONE"}]
ISSUES: {description of any problems encountered, or "NONE"}
```
```

### M4c. Collect Results

After all subagents in the wave return, process results:

**SUCCESS tasks:**
1. Update tasks.md — mark the task checkbox as complete with notes:
   ```
   - [x] N.M {Task title}
     - Complexity: {points}
     - Dependencies: {deps}
     - Acceptance: {criterion}
     - Completed: {YYYY-MM-DD}
     - Notes: {brief description from subagent summary}
   ```
2. Update changelog.md — append to the relevant domain section
3. Append to session state:
   - Add task to Completed list
   - Add files to Files created/modified lists
   - Add key decisions if any

**FAILURE tasks:**
Use AskUserQuestion for each failed task with these options:
- **Retry** — relaunch the subagent with the error context appended
- **Skip** — mark as skipped, block dependent tasks in later waves
- **Stop** — end the entire session

### M4d. Advance to Next Wave

Only advance after all tasks in the current wave succeed or are resolved (skipped/stopped). If a task was skipped, remove any tasks in later waves that depend on it (report these as blocked).

## Step M5: Report

After all waves complete, provide a summary:

```
## Session Complete

### Completed
- {task_id}: {title} — {one-line summary}
- ...

### Skipped
- {task_id}: {title} — {reason}
- ...

### Blocked (due to skipped dependencies)
- {task_id}: {title} — blocked by {dep_id}
- ...

### Files Created
- {list}

### Files Modified
- {list}

### Suggested Next Work
{What to implement next based on remaining tasks}
```

## Wave Construction Rules

Given the selected tasks and their dependencies:

1. **Wave 1**: All tasks with no unmet dependencies (all deps already complete or not in the selected set)
2. **Wave 2**: Tasks whose dependencies are all in Wave 1
3. **Wave N**: Tasks whose dependencies are all in Waves 1..N-1
4. **Max 3 parallel subagents per wave** — if a wave would have >3 tasks, split into sub-waves of 3
5. Tasks with unmet dependencies outside the selected set should be flagged in Step M2

Example with parallelism:
```
/m:dev UC-001/4 UC-001/5
  4.1 deps: None
  4.2 deps: 3.3 (complete), 4.1 (in selection)
  4.3 deps: 4.2 (in selection), 1.3 (complete)
  5.1 deps: None
  5.2 deps: 5.1 (in selection)
  5.3 deps: 5.2 (in selection)

  Wave 1: [4.1, 5.1]       (both independent — parallel)
  Wave 2: [4.2, 5.2]       (4.2 depends on 4.1, 5.2 depends on 5.1 — parallel)
  Wave 3: [4.3, 5.3]       (4.3 depends on 4.2, 5.3 depends on 5.2 — parallel)
```

## Session State Management

Keep the session state concise (~50 lines max). After each wave, append:
- One-line summary per task
- Files created/modified (paths only)
- Key decisions (if any)

If state exceeds 20 entries, compress earlier entries into a "Prior work" summary paragraph.

## Scope Control

Execute ONLY the selected tasks. Do not:
- Implement tasks outside the selection "while you're at it"
- Refactor unrelated code
- Add features not in any task's acceptance criteria
- Modify files outside the tasks' scope unless required

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- Follow all project conventions from CLAUDE.md.
- Never stage files or create commits — the user manages git.
- Do not use the word "comprehensive" in any document.
- Launch all subagents for a wave in a SINGLE message with multiple Task tool calls.
