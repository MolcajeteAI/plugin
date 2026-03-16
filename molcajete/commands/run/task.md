---
description: "Phase 3: Implement a single task (used by dispatch.sh, not user-facing)"
model: claude-opus-4-6
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(*), Task
argument-hint: <task-id> <spec-folder-path>
---

# Implement Task (Phase 3)

You are implementing a single task from a pre-existing plan. The plan was generated in Phase 1 (run--plan) and BDD step definitions were written in Phase 2 (run--bdd). You do NOT generate plans or write BDD step definitions. You implement production code, run unit tests, review, update progress, and commit.

**Arguments:** $ARGUMENTS

Parse the arguments: first token is the task ID (e.g., `UC-0KTg-001/1.1`), second token is the spec folder path.

## Designated Agents

This command delegates to these agents. Read the agent-coordination skill and agent definitions before dispatching:

- `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/SKILL.md` -- invocation protocol and handoff patterns
- **Developer** (`${CLAUDE_PLUGIN_ROOT}/agents/developer.md`) -- implements production code and unit tests per plan (green phase)
- **Reviewer** (`${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md`) -- reviews code for correctness, security, performance, conventions, test coverage
- **Committer** (`${CLAUDE_PLUGIN_ROOT}/agents/committer.md`) -- stages files and commits with proper message format

**Chain:** Developer(green) -> UNIT TEST GATE -> REGRESSION GATE -> Reviewer -> Progress Update -> Committer

## Critical Directives

These override every step below. No exceptions.

1. **Right over easy.** At every decision point choose the architecturally correct solution. Never take shortcuts.
2. **Fix everything you see.** Pre-existing linter warnings, type errors, test failures, and convention violations must be fixed when detected.

## Headless Mode

This command runs in headless mode via `claude -p` with `--dangerously-skip-permissions`. Interactive prompts are not available. You MUST make autonomous decisions at every point and never block on user input.

Decision rules:
- **Ambiguous input:** Use best-match heuristics and log the assumption.
- **Incomplete dependencies:** Proceed anyway and log a warning.
- **Unclear requirements:** Make your best judgment and document the decision.
- **Review escalation:** If issues persist after max retries, fail with structured output.
- **Commit hook failure:** If hooks fail after max retries, fail with structured output.

## Step 0: Environment Validation

```bash
echo "bash-ok: $(pwd)"
```

If this command fails with an EPERM or sandbox error:
1. Output: `{"HEADLESS_FAILURE": true, "reason": "bash_unavailable", "error": "<exact error message>"}`
2. Stop execution immediately.

## Step 0b: Detect Work in Progress

Check if a previous attempt left work in this worktree:

```bash
git status --porcelain
git log --oneline HEAD..$(git branch --show-current) 2>/dev/null || true
```

If there are uncommitted changes or commits on the current branch:

1. Inventory what exists: modified/untracked files, production code, unit tests
2. Determine what phase the previous attempt reached:
   - Production code written -> previous attempt got past Step 3
   - Progress files updated -> previous attempt got past Step 7
   - Only missing a commit -> skip directly to Step 8
3. Log: `[SUBTASK-RUN] Resuming from previous attempt. WIP detected at phase: {phase}. Skipping to Step {N}.`
4. Skip directly to the appropriate step.

## Step 1: Gather Context

1. Parse the subtask ID to extract the UC ID (e.g., `UC-0KTg-001` from `UC-0KTg-001/1.1`).
2. Find the spec folder. Read `prd/specs/{folder}/tasks.md` to extract the subtask's title, acceptance criteria, dependencies, and complexity.
3. If dependencies are NOT completed, log `[SUBTASK-RUN] WARNING: Proceeding despite incomplete dependencies: {list}` and continue.

4. Launch a `general-purpose` sub-agent using the Task tool to build a context brief:
   - Read `prd/specs/{folder}/spec.md` -- extract sections relevant to this subtask's UC
   - Read `prd/specs/{folder}/requirements.md` -- extract acceptance criteria (if exists)
   - Read `prd/tech-stack.md` -- extract architecture and conventions
   - Read `CLAUDE.md` -- extract project conventions
   - Read per-task changelog files in `prd/specs/{folder}/plans/changelog-*.md` -- summarize what's already built
   - Scan `**/README.md` files (excluding `node_modules/`, `prd/`) in related directories

## Step 2: Read Pre-existing Plan

1. Find the plan file for this subtask at `prd/specs/{feature}/plans/*-task-{subtask-id-with-double-dash}.md`.
   - The subtask ID `UC-0KTg-001/1.1` becomes `UC-0KTg-001--1.1` in the filename.
2. Read the plan file. This is your implementation blueprint. Do NOT generate a new plan.
3. If no plan file exists, log a warning and create a minimal plan based on the task brief (fallback only).

## Step 2b: Read BDD Step Definitions

1. Read `bdd/CLAUDE.md` if it exists.
2. Grep `bdd/steps/` for files related to this UC's scenarios.
3. Read the step definitions for awareness -- your production code must satisfy these assertions.
4. If no BDD steps exist, note that and proceed with unit tests only.

## Step 3: GREEN PHASE (Developer Agent)

> Remember: **Right over easy.** **Fix everything you see.**

Invoke the Developer agent:
- Read the Developer agent definition at `${CLAUDE_PLUGIN_ROOT}/agents/developer.md`
- Follow the invocation template from `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/references/invocation-template.md`
- Input: task brief, pre-existing plan, BDD step definitions (if available)
- Goal: implement production code + unit tests per the plan
- Scope: production code + unit tests. Do NOT modify `bdd/features/` files. Do NOT implement BDD step definitions.
- The Developer discovers stack-specific coding and testing skills at runtime

## Step 4: UNIT TEST GATE

Run unit tests for affected areas:
```bash
# Use the test command from the project's configuration
```

- All must pass. If any fail, send failures to the Developer agent for fixes. Max 3 cycles.

## Step 5: REGRESSION GATE

Run sequentially:

1. **Unit tests** for affected areas
2. **Formatter** on changed files -- fix any issues
3. **Linter** on changed files -- fix any issues

All must pass. If any fail, send failures to the Developer agent for fixes. Max 3 cycles, then stop and report failure.

Note: Do NOT run BDD tests here. BDD validation happens in Phase 4 (uc-validate).

## Step 6: Review Gate

> Remember: **Fix everything you see.** Zero warnings, zero errors, zero failing tests.

Launch 2 parallel sub-agents using the Task tool in a single message:

**Agent 1 -- Reviewer** (invoke the Reviewer agent):
- Read the Reviewer agent definition at `${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md`
- Follow the invocation template from `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/references/invocation-template.md`
- Provide all FILES_CREATED and FILES_MODIFIED from Developer output
- Return REVIEW_STATUS, VERDICT, FINDINGS

**Agent 2 -- README updater** (subagent_type: `general-purpose`):
- Read the code-documentation skill at `${CLAUDE_PLUGIN_ROOT}/skills/code-documentation/SKILL.md` and the README template at `${CLAUDE_PLUGIN_ROOT}/skills/code-documentation/references/readme-template.md`
- Identify directories where files were created or deleted
- For each directory (skip `node_modules/`, `dist/`, `build/`, `coverage/`, `vendor/`, `.git/`, `__tests__/`, `prd/`, asset-only directories):
  - If `README.md` exists: determine updates needed
  - If `README.md` does not exist: prepare full README content
- Return README_ACTIONS list

After both agents return:
1. Write README content from Agent 2
2. If Reviewer VERDICT is APPROVE -> proceed to Step 7
3. If Reviewer found CRITICAL or WARNING issues:
   a. Send FINDINGS to Developer agent to fix
   b. After fixes, re-run tests (Step 5 logic)
   c. Re-run Reviewer on updated files
   d. Max 3 fix cycles. If still CRITICAL after 3 cycles:
      ```json
      {"HEADLESS_FAILURE": true, "reason": "review_escalation", "findings": "<CRITICAL findings summary>"}
      ```

## Step 7: Update Progress

Run this only after ALL gates have passed.

1. **Update tasks.md**: Mark the subtask checkbox as complete with notes:
   ```
   - [x] N.M {Task title}
     - Complexity: {points}
     - Dependencies: {deps}
     - Acceptance: {criterion}
     - Completed: {YYYY-MM-DD}
     - Notes: {brief description of approach, key decisions, files created/modified}
   ```

2. **Write per-task changelog**: Get a UTC timestamp. Create `prd/specs/{feature}/plans/{timestamp}-changelog-{subtask-id-with-double-dash}.md` with what was implemented, key decisions, files created/modified.

3. **Update main changelog**: Append to `prd/changelog.md` in chronological format under today's date heading.

## Step 8: Commit

Launch the Committer agent using the Task tool:
- Read the Committer agent definition at `${CLAUDE_PLUGIN_ROOT}/agents/committer.md`
- Follow the invocation template from `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/references/invocation-template.md`
- Provide: subtask ID, task title, feature name, UC ID, accumulated FILES_CREATED + FILES_MODIFIED

After the Committer returns:
1. If COMMIT_STATUS is SUCCESS -> report commit hash and message
2. If COMMIT_STATUS is HOOK_FAILURE:
   a. Send HOOK_OUTPUT to Developer to fix
   b. Re-run Review Gate then Committer
   c. Max 3 hook-failure cycles, then:
      ```json
      {"HEADLESS_FAILURE": true, "reason": "commit_hook_failure", "hook_output": "<last hook output>"}
      ```
3. If COMMIT_STATUS is ERROR, attempt inline commit as fallback:
   - Stage specific files: `git add <file1> <file2> ...`
   - Commit with: `git commit -m "feat(<scope>): <task title>\n\nTask: <subtask-id>\nFeature: <feature-name>\nUC: <uc-id>"`
   - If inline commit also fails:
     ```json
     {"HEADLESS_FAILURE": true, "reason": "commit_failure", "error": "<error from both attempts>"}
     ```

## Scope Control

Execute ONLY the requested subtask. Do not:
- Implement adjacent subtasks
- Refactor unrelated code
- Add features not in the subtask's acceptance criteria
- Modify files outside the subtask's scope unless required

When done, output what was completed (include commit hash).

## Rules

- Never block on user input. Make autonomous decisions and log reasoning.
- Follow all project conventions from CLAUDE.md.
- Do not use the word "comprehensive" in any document.
- Do NOT generate new plans. Use the pre-existing plan from Phase 1.
- Do NOT write BDD step definitions. Those were written in Phase 2.
- Do NOT run BDD tests. BDD validation happens in Phase 4.
