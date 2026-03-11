---
description: Implement a task from the task plan
model: claude-opus-4-6
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(*), Task, AskUserQuestion
argument-hint: <task ID like "UC-0Fy0-001/1.1" or feature like "Feature 2">
---

# Implement Task

You are implementing a specific task from a feature's tasks.md file. You follow a strict 9-step workflow and execute ONLY the requested task.

**Task identifier:** $ARGUMENTS

## Designated Agents

This command delegates to these agents. Read the agent-coordination skill and agent definitions before dispatching:

- `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/SKILL.md` — invocation protocol and handoff patterns
- **Developer** (`${CLAUDE_PLUGIN_ROOT}/agents/developer.md`) — implements code and tests from the approved plan
- **Reviewer** (`${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md`) — reviews code for correctness, security, performance, conventions, test coverage
- **Committer** (`${CLAUDE_PLUGIN_ROOT}/agents/committer.md`) — stages files and commits with proper message format

**Chain:** Developer -> Reviewer -> Committer (with fix loops on review issues or hook failures)

**What this command keeps:** Context gathering, plan approval, progress tracking, scope control, formatter/linter execution.

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

## Execution Scope

This command executes exactly ONE sub-task (e.g., "UC-0Fy0-001/1.1"). The external coordinator manages iteration across sub-tasks. If `$ARGUMENTS` points to a parent task (e.g., "UC-0Fy0-001/1"), use AskUserQuestion to ask which sub-task to implement.

## Step 3: Plan

> Remember: **Right over easy.** Plan the correct solution, not the fastest one.

1. Get a UTC timestamp by running `date -u +%Y%m%d-%H%M` (e.g., `20260311-1430`).

2. The plan filename is: `{timestamp}-task-UC-{tag}-NNN--N.M.md`

   Note: double-dash `--` separates the UC ID from the task/subtask number.

3. Explore the codebase to understand existing patterns, related code, and where new code should go.

4. Write the plan to `prd/specs/{feature}/plans/{plan-filename}` (create the `plans/` directory if needed). The plan should cover:
   - Files to create or modify
   - Key implementation decisions
   - How this integrates with existing code

5. Present the plan to the user. Output the plan content in your message, then use AskUserQuestion:
   - Question: "Do you accept the plan?"
   - Header: "Plan"
   - Options:
     - "Yes, proceed with implementation" — proceed to Step 4
     - "No, I have feedback" — user provides feedback via the "Other" option
   - multiSelect: false

6. If the user provides feedback, update the plan file, present the updated plan, and ask again. Repeat until accepted.

## Step 3b: Load BDD Acceptance Criteria

1. Read `bdd/CLAUDE.md`. If no `# BDD Configuration` section, skip this step (backward compatible).
2. Grep `bdd/features/` for files containing `@task-{current-task-ID}`.
3. If matching scenarios exist:
   a. Read the matching `.feature` files and extract scenarios tagged with the current task ID.
   b. Update the plan file with a "BDD Acceptance Criteria" section listing each scenario.
   c. These scenarios become the primary acceptance criteria.
4. If no matching scenarios exist, skip (fall back to current behavior).

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
- If BDD scenarios exist for this task (tagged `@task-{ID}`): (1) Locate step definition files in bdd/steps/ with TODO: implement step bodies for matching scenarios. (2) Implement those bodies with real assertions using the detected BDD framework and patterns from bdd/CLAUDE.md. (3) Do NOT create new step definitions or modify scenario structure. (4) After implementing step definitions, write unit tests as normal. If no BDD scenarios exist, write unit tests only.

## Step 6: Run Tests

Run the test suite to verify everything passes:
- Run the specific tests you wrote
- Run the broader test suite for affected areas
- Run BDD tests scoped to the current task's tag: `--tags=@task-{ID}`
- Run formatter on changed files and fix any issues
- Run linter on changed files and fix any issues
- If tests fail, fix the code and re-run until green
- Do NOT skip failing tests or mark them as expected failures

## Step 7: Update Progress

Run this **immediately** after Steps 3–6 pass. Do NOT defer these updates.

1. **Update tasks.md**: Mark the sub-task checkbox as complete. Add completion notes:
   ```
   - [x] N.M {Task title}
     - Complexity: {points}
     - Dependencies: {deps}
     - Acceptance: {criterion}
     - Completed: {YYYY-MM-DD}
     - Notes: {brief description of approach, key decisions, files created/modified}
   ```

2. **Write per-task changelog file**: Get a UTC timestamp by running `date -u +%Y%m%d-%H%M`. Create `prd/specs/{feature}/plans/{timestamp}-changelog-UC-{tag}-NNN--N.M.md` with:
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
     - Plan: [20260214-2200-task-UC-0Fcy-001--1.1.md](specs/20260212-1456-console_authentication/plans/20260214-2200-task-UC-0Fcy-001--1.1.md)
     - Changelog: [20260214-2200-changelog-UC-0Fcy-001--1.1.md](specs/20260212-1456-console_authentication/plans/20260214-2200-changelog-UC-0Fcy-001--1.1.md)
   ```

After updating progress, proceed to Step 8 (Quality Gate), then stop.

## Step 8: Review Gate

> Remember: **Fix everything you see.** All issues found here must be fixed — including pre-existing ones. Zero warnings, zero errors, zero failing tests.

Launch 2 parallel sub-agents using the Task tool in a single message:

**Agent 1 — Reviewer** (invoke the Reviewer agent):
- Read the Reviewer agent definition at `${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md`
- Follow the invocation template from `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/references/invocation-template.md`
- Provide all FILES_CREATED and FILES_MODIFIED from Developer output
- The Reviewer discovers stack-specific coding skills at runtime for convention checking
- Return the Reviewer's standard output format (REVIEW_STATUS, VERDICT, FINDINGS)

**Agent 2 — README updater** (subagent_type: `general-purpose`):
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

After both agents return:
1. Write README content from Agent 2 (CREATE new files, UPDATE existing ones)
2. If Reviewer VERDICT is APPROVE (no CRITICAL/WARNING findings) -> proceed to Step 9
3. If Reviewer found CRITICAL or WARNING issues:
   a. Send FINDINGS to the Developer agent to fix (same invocation as Step 4, with FINDINGS as additional input)
   b. After Developer fixes, re-run tests (Step 6 logic)
   c. Re-run Reviewer on updated files (standalone, no README updater)
   d. Max 3 fix cycles. If the review still has CRITICAL issues after 3 cycles, escalate to user via AskUserQuestion.
4. Run the full feature BDD suite: `--tags=@uc-{UC-ID}`. If tests fail, fix and re-run.

## Step 9: Commit

Launch the Committer agent using the Task tool:
- Read the Committer agent definition at `${CLAUDE_PLUGIN_ROOT}/agents/committer.md`
- Follow the invocation template from `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/references/invocation-template.md`
- Provide: task ID, task title, feature name, UC ID, accumulated FILES_CREATED + FILES_MODIFIED (from Developer, README updater, and any fix-cycle changes)

After the Committer returns:
1. If COMMIT_STATUS is SUCCESS -> report commit hash and message to user
2. If COMMIT_STATUS is HOOK_FAILURE:
   a. Send HOOK_OUTPUT to the Developer agent to fix the issues
   b. After Developer fixes, re-run Review Gate (Step 8) then Committer (Step 9)
   c. Max 3 hook-failure cycles. If commit still fails after 3 cycles, escalate to user via AskUserQuestion.
3. If COMMIT_STATUS is ERROR -> report error to user and stop

## Scope Control

This is critical: execute ONLY the requested task (or its sub-tasks). Do not:
- Implement adjacent tasks "while you're at it"
- Refactor unrelated code
- Add features not in the task's acceptance criteria
- Modify files outside the task's scope unless required by the task

When done, tell the user what was completed (include commit hash) and suggest: "Next task: `/m:dev {UC-{tag}-NNN/next-task-id}`"

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- Follow all project conventions from CLAUDE.md.
- Do not use the word "comprehensive" in any document.
