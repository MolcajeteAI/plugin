---
description: Implement a task from the task plan
model: claude-opus-4-6
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(*), Task, AskUserQuestion
argument-hint: <task ID like "UC-0Fy0-001/1.1" or feature like "Feature 2">
---

# Implement Task

You are implementing a specific task from a feature's tasks.md file. You follow a strict 8-step workflow and execute ONLY the requested task.

**Task identifier:** $ARGUMENTS

## Critical Directives

These override every step below. No exceptions.

1. **Right over easy.** At every decision point — planning, coding, testing — choose the architecturally correct solution. Never take shortcuts. If the right approach costs more effort, pay it.
2. **Fix everything you see.** Pre-existing linter warnings, type errors, test failures, and convention violations must be fixed when detected. You own every issue you encounter, regardless of who introduced it.

## Step 1: Gather Context

1. Find the tasks.md file. If `$ARGUMENTS` looks like a task ID (e.g., "UC-0Fy0-001/1.1", "UC-0Fy0-002/1"), search all `prd/specs/*/tasks.md` files for that task under the matching UC section. If `$ARGUMENTS` mentions a feature name, find the matching folder. If ambiguous, use AskUserQuestion.

2. Read the tasks.md file and identify the target task. Extract:
   - Task title and acceptance criteria
   - Dependencies (verify they are completed — their checkboxes should be marked)
   - Feature context (which use case this belongs to)
   - The feature folder path (`prd/specs/{folder}/`)

3. If dependencies are NOT completed, warn the user and use AskUserQuestion to ask whether to proceed anyway or stop.

4. Launch a `general-purpose` sub-agent using the Task tool to build a structured task brief. The prompt must include the feature folder path and task details you extracted above. The agent should:
   - Read `prd/specs/{folder}/spec.md` — extract only sections relevant to this task's use case
   - Read `prd/specs/{folder}/requirements.md` — extract acceptance criteria and functional requirements for this use case (if exists)
   - Read `prd/tech-stack.md` — extract architecture and conventions
   - Read `CLAUDE.md` — extract project conventions
   - Read per-task changelog files in `prd/specs/{folder}/plans/changelog-*.md` — summarize what's already built (if any exist)
   - Scan `**/README.md` files (excluding `node_modules/`, `prd/`) in directories related to the task's scope — summarize existing patterns
   - Read the project-management skill at `${CLAUDE_PLUGIN_ROOT}/skills/project-management/SKILL.md`

   The agent must return a structured brief in this format:
   ```
   TASK_BRIEF:
   - Task ID: {id}
   - Task title: {title}
   - Acceptance criteria: {criteria}
   - Complexity: {points}
   - Dependency status: {all met / list unmet}

   SPEC_EXCERPT:
   {Only the sections from spec.md relevant to this task's use case}

   REQUIREMENTS_EXCERPT:
   {Functional requirements and acceptance criteria for this use case, or "No requirements.md found"}

   TECH_CONTEXT:
   - Stack: {relevant stack for this task}
   - Conventions: {key conventions from CLAUDE.md and tech-stack.md}
   - Architecture: {relevant architecture patterns}

   EXISTING_PATTERNS:
   {Summary of existing code patterns from README scans relevant to this task}

   CHANGELOG_SUMMARY:
   {What's already built from per-task changelog files, or "No changelog files found"}

   WARNINGS:
   {Any issues: incomplete deps, missing spec sections, ambiguities — or "NONE"}
   ```

Use the returned brief as your context for all subsequent steps. Do NOT read these files again yourself.

## Step 2: Clarify

If anything about the task is ambiguous after reading the context brief, use AskUserQuestion to clarify with the user. Examples:
- Unclear acceptance criteria
- Multiple valid implementation approaches
- Missing information in the spec

If the task is clear, skip this step.

## Sub-Task Handling

After gathering context, determine whether the target task has sub-tasks in tasks.md:

- **Leaf task** (e.g., "UC-0Fy0-001/8.1" — no children): Proceed through Steps 3–8 once.
- **Parent task** (e.g., "UC-0Fy0-001/8" — has sub-tasks like 8.1, 8.2): Iterate through each **uncompleted** sub-task in order. For EACH sub-task:
  1. Execute Steps 3–8 (Plan → Code → Tests → Run Tests → Update Progress → Quality Gate)
  2. Then proceed to the next uncompleted sub-task

After ALL sub-tasks are complete, mark the parent task checkbox as complete in tasks.md (see Step 7).

This per-sub-task update ensures progress is saved even if context limits are reached mid-execution.

## Step 3: Plan

> Remember: **Right over easy.** Plan the correct solution, not the fastest one.

1. Determine the plan scope and filename from the target work:
   - Full feature → `task-feature.md`
   - Use case → `task-UC-{tag}-NNN.md`
   - Task → `task-UC-{tag}-NNN--N.md`
   - Sub-task → `task-UC-{tag}-NNN--N.M.md`

   Note: double-dash `--` separates the UC ID from the task/subtask number.

2. Explore the codebase to understand existing patterns, related code, and where new code should go.

3. Write the plan to `prd/specs/{feature}/plans/{plan-filename}` (create the `plans/` directory if needed). The plan should cover:
   - Files to create or modify
   - Key implementation decisions
   - How this integrates with existing code

4. Present the plan to the user. Output the plan content in your message, then use AskUserQuestion:
   - Question: "Do you accept the plan?"
   - Header: "Plan"
   - Options:
     - "Yes, proceed with implementation" — proceed to Step 4
     - "No, I have feedback" — user provides feedback via the "Other" option
   - multiSelect: false

5. If the user provides feedback, update the plan file, present the updated plan, and ask again. Repeat until accepted.

## Step 4: Write Code

> Remember: **Right over easy.** Implement the correct solution from the plan. **Fix everything you see** — if you open a file and find pre-existing issues, fix them.

Implement the task following the approved plan. Key rules:
- Follow all conventions from CLAUDE.md (resolver rules, component architecture, i18n, etc.)
- Follow patterns from the relevant coding skills (Go, TypeScript, React, etc.)
- Write clean, production-quality code — not prototypes
- Stay within the scope of THIS task only

## Step 5: Write Tests

Write tests for the code you created or modified:
- Place test files in `__tests__/` sibling directories (frontend) or alongside the code (Go)
- Follow existing test patterns in the codebase
- Cover the acceptance criteria from the task
- Include edge cases and error scenarios

## Step 6: Run Tests

Run the test suite to verify everything passes:
- Run the specific tests you wrote
- Run the broader test suite for affected areas
- If tests fail, fix the code and re-run until green
- Do NOT skip failing tests or mark them as expected failures

## Step 7: Update Progress

Run this **immediately** after Steps 3–6 pass for each sub-task (or for a leaf task). Do NOT defer these updates.

1. **Update tasks.md**: Mark the sub-task (or leaf task) checkbox as complete. Add completion notes:
   ```
   - [x] N.M {Task title}
     - Complexity: {points}
     - Dependencies: {deps}
     - Acceptance: {criterion}
     - Completed: {YYYY-MM-DD}
     - Notes: {brief description of approach, key decisions, files created/modified}
   ```

2. **Write per-task changelog file**: Create `prd/specs/{feature}/plans/changelog-UC-{tag}-NNN--N.M.md` with:
   - What was implemented
   - Key decisions made
   - Files created/modified
   - Requirement IDs delivered

3. **Update main changelog**: Append to `prd/changelog.md` in chronological format:
   - Add entry under today's date heading (create heading if not exists)
   - Get the current UTC time by running `date -u +%H:%M` and use it as the timestamp (HH:MM)
   - Include the timestamp, change title, brief description
   - Link to the plan file and changelog file(s)

   Example:
   ```markdown
   ## 2026-02-14

   - [22:00] Implement console admin sign-in
     Adds JWT-based authentication for console admin users.
     - Plan: [task-UC-0Fcy-001--1.md](specs/20260212-1456-console_authentication/plans/task-UC-0Fcy-001--1.md)
     - Changelog: [changelog-UC-0Fcy-001--1.1.md](specs/20260212-1456-console_authentication/plans/changelog-UC-0Fcy-001--1.1.md)
   ```

If this is a **leaf task** (no parent), proceed to Step 8 (Quality Gate), then you are done.
If this is a **sub-task of a parent**, proceed to Step 8, then move to the next uncompleted sub-task (back to Step 3). Once all sub-tasks are done, mark the parent task checkbox as complete in tasks.md and stop.

## Step 8: Quality Gate

> Remember: **Fix everything you see.** All issues found here must be fixed — including pre-existing ones. Zero warnings, zero errors, zero failing tests.

Launch 4 parallel sub-agents using the Task tool in a single message:

**Agent 1 — Formatter** (subagent_type: `Bash`):
- Prompt: Detect which files were changed (Go files in `server/`, frontend files elsewhere). Run `gofmt -l` on changed `.go` files and `pnpm run format --check` (or equivalent Biome check command) on changed frontend files. Return:
  ```
  FORMAT_STATUS: PASS | FAIL
  FILES_WITH_ISSUES:
  {list of files needing formatting, or "NONE"}
  ```

**Agent 2 — Linter** (subagent_type: `Bash`):
- Prompt: Detect which files were changed (Go files in `server/`, frontend files elsewhere). Run `golangci-lint run` on changed Go packages and `pnpm run lint` on changed frontend files. Return:
  ```
  LINT_STATUS: PASS | FAIL
  LINT_OUTPUT:
  {linter output, or "NONE"}
  ```

**Agent 3 — Self-review** (subagent_type: `general-purpose`):
- Prompt: Read all files created or modified during this task (provide the file list). Also read the relevant coding skills (`${CLAUDE_PLUGIN_ROOT}/skills/go-writing-code/SKILL.md`, `${CLAUDE_PLUGIN_ROOT}/skills/typescript-writing-code/SKILL.md`, `${CLAUDE_PLUGIN_ROOT}/skills/react-writing-code/SKILL.md`, `${CLAUDE_PLUGIN_ROOT}/skills/software-principles/SKILL.md`) based on the stack. Review the changes for: security issues, missing error handling, convention violations from CLAUDE.md, performance concerns, and code quality. Return:
  ```
  REVIEW_STATUS: PASS | ISSUES_FOUND
  FINDINGS:
  - Severity: CRITICAL | WARNING | SUGGESTION
    File: {path:line}
    Issue: {description}
    Fix: {suggested fix}
  ```

**Agent 4 — README updater** (subagent_type: `general-purpose`):
- Prompt: Read the code-documentation skill at `${CLAUDE_PLUGIN_ROOT}/skills/code-documentation/SKILL.md` and the README template at `${CLAUDE_PLUGIN_ROOT}/skills/code-documentation/references/readme-template.md`. Identify all directories where files were **created** or **deleted** during this task (provide the list). For each such directory (skip `node_modules/`, `dist/`, `build/`, `coverage/`, `vendor/`, `.git/`, `__tests__/`, `prd/`, asset-only directories):
  - If `README.md` exists: read it + the directory's files, determine what updates are needed (file listing, diagrams, last-updated date)
  - If `README.md` does not exist: read all files in the directory, prepare full README content following the template
  Return:
  ```
  README_ACTIONS:
  - Action: UPDATE | CREATE | NONE
    Directory: {path}
    Content: {full README content if CREATE, or specific updates if UPDATE}
  ```

After all 4 agents return:
1. If formatting issues → run the formatter to fix them
2. If lint issues → fix the lint errors
3. If self-review found CRITICAL or WARNING issues → fix them
4. Write README content from Agent 4 (CREATE new files, UPDATE existing ones)
5. If any code was changed in steps 1-3 → re-run tests (Step 6). README-only changes do NOT trigger re-testing.

## Scope Control

This is critical: execute ONLY the requested task (or its sub-tasks). Do not:
- Implement adjacent tasks "while you're at it"
- Refactor unrelated code
- Add features not in the task's acceptance criteria
- Modify files outside the task's scope unless required by the task

When done, tell the user what was completed and suggest: "Next task: `/m:dev {UC-{tag}-NNN/next-task-id}`"

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- Follow all project conventions from CLAUDE.md.
- Never stage files or create commits — the user manages git.
- Do not use the word "comprehensive" in any document.
