---
description: "Phase 1: Plan all subtasks for a use case (used by dispatch.sh, not user-facing)"
model: claude-opus-4-6
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(*), Task
argument-hint: <uc-id> <spec-folder-path>
---

# UC Plan (Phase 1)

You are planning all subtasks for a single use case. You gather context, detect WIP from previous attempts, generate plan files for each subtask in dependency order, and commit them. You do NOT write BDD steps, implement code, or run tests.

**Arguments:** $ARGUMENTS

Parse the arguments: first token is the UC ID (e.g., `UC-0KTg-001`), second token is the spec folder path.

## Headless Mode

This command runs in headless mode via `claude -p` with `--dangerously-skip-permissions`. Interactive prompts are not available. You MUST make autonomous decisions at every point and never block on user input.

Decision rules:
- **Ambiguous input:** Use best-match heuristics and log the assumption.
- **Incomplete dependencies:** Proceed anyway and log a warning.
- **Unclear requirements:** Make your best judgment based on available context and document the decision in the plan.

## Step 0: Environment Validation

Before any other work, verify that the Bash tool is functional:
```bash
echo "bash-ok: $(pwd)"
```

If this command fails with an EPERM or sandbox error:
1. Log the exact error message
2. Output:
   ```
   UC_PLAN_STATUS: FAILURE
   ERROR: bash_unavailable
   ```
3. Stop execution immediately.

## Step 0b: Detect Work in Progress

Check if a previous planning attempt left work in this worktree:

```bash
git status --porcelain
```

If there are uncommitted plan files in `prd/specs/{feature}/plans/`:
1. Inventory existing plan files for this UC's subtasks
2. Determine which subtasks already have plans
3. Log: `[UC-PLAN] Resuming from previous attempt. Plans exist for: {list}. Generating only missing plans.`
4. Skip subtasks that already have valid plans

## Step 1: Gather Context

Launch a `general-purpose` sub-agent using the Task tool to build a structured UC brief. The agent should:

- Read `prd/specs/{folder}/spec.md` -- extract sections relevant to this UC
- Read `prd/specs/{folder}/requirements.md` -- extract acceptance criteria for this UC (if exists)
- Read `prd/specs/{folder}/tasks.md` -- extract all subtasks under this UC heading with their dependencies and complexity
- Read `prd/tech-stack.md` -- extract architecture and conventions
- Read `CLAUDE.md` -- extract project conventions
- Read per-task changelog files in `prd/specs/{folder}/plans/changelog-*.md` -- summarize what's already built (if any exist)
- Read the project-management skill at `${CLAUDE_PLUGIN_ROOT}/skills/project-management/SKILL.md`
- Scan `**/README.md` files (excluding `node_modules/`, `prd/`) in directories related to the UC's scope -- summarize existing patterns

The agent must return a structured brief:
```
UC_BRIEF:
- UC ID: {id}
- UC Title: {title}
- Subtask count: {count}
- Subtasks: {list with IDs, titles, complexity, dependencies}

SPEC_EXCERPT:
{Only the sections from spec.md relevant to this UC}

REQUIREMENTS_EXCERPT:
{Functional requirements for this UC, or "No requirements.md found"}

TECH_CONTEXT:
- Stack: {relevant stack}
- Conventions: {key conventions}
- Architecture: {relevant patterns}

EXISTING_PATTERNS:
{Summary of existing code patterns relevant to this UC}

CHANGELOG_SUMMARY:
{What's already built, or "No changelog files found"}

WARNINGS:
{Any issues or "NONE"}
```

## Step 2: Load BDD Scenarios

1. Read `bdd/CLAUDE.md` if it exists. If no `# BDD Configuration` section, note BDD is not configured.
2. Grep `bdd/features/` for files containing `@uc-{UC-ID}`.
3. If matching scenarios exist, read them and include in the planning context so plans account for BDD acceptance criteria.
4. If no matching scenarios exist, note that BDD is not available for this UC.

## Step 3: Generate Plan Files

For each subtask in this UC, in dependency order:

1. Skip subtasks that already have valid plan files (from Step 0b).
2. Get a UTC timestamp by running `date -u +%Y%m%d-%H%M`.
3. The plan filename is: `{timestamp}-task-{subtask-id-with-double-dash}.md`
   - Example: `20260315-1430-task-UC-0KTg-001--1.1.md`
   - Note: double-dash `--` separates UC ID from subtask number.
4. Explore the codebase to understand existing patterns, related code, and where new code should go.
5. Write the plan to `prd/specs/{feature}/plans/{plan-filename}` (create the `plans/` directory if needed). The plan should cover:
   - Files to create or modify
   - Key implementation decisions
   - How this integrates with existing code
   - **Planned interfaces:** function signatures, CSS selectors, API endpoints, component names that step definitions will assert against
   - BDD acceptance criteria (if BDD scenarios exist for this UC)
   - A "Headless Decisions" section documenting any assumptions

## Step 4: Commit Plan Files

Stage and commit all generated plan files:

```bash
git add prd/specs/{feature}/plans/*-task-*.md
git commit -m "plan({uc-id}): generate subtask plans

UC: {uc-id}
Subtasks planned: {count}"
```

## Step 5: Output

Output the final status:

```
UC_PLAN_STATUS: SUCCESS
UC_ID: {uc-id}
PLAN_FILES:
- {path-to-plan-1}
- {path-to-plan-2}
...
SUBTASKS_PLANNED: {count}
SUBTASKS_SKIPPED: {count} (already had plans)
```

If any step fails critically:
```
UC_PLAN_STATUS: FAILURE
UC_ID: {uc-id}
ERROR: {description}
```

## Rules

- Never block on user input. Make autonomous decisions and log reasoning.
- Follow all project conventions from CLAUDE.md.
- Do not use the word "comprehensive" in any document.
- Do NOT write BDD steps, implement code, or run tests.
- Plan the correct solution, not the fastest one.
