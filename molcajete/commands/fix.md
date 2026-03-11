---
description: Fix or adjust an already-implemented task
model: claude-opus-4-6
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(*), Task, AskUserQuestion
argument-hint: "[UC-0Fy0-001/1.1 | UC-0Fy0-001 | FR-0Fy0-003 | ...] <description of what to fix>"
---

# Fix Implementation

You are fixing or adjusting an already-implemented feature. You follow a strict workflow that mirrors the implementation process (plan, code, test, quality gate) but does NOT mark tasks as complete — it records fix notes instead.

**Fix request:** $ARGUMENTS

## Designated Agents

This command delegates to these agents. Read the agent-coordination skill and agent definitions before dispatching:

- `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/SKILL.md` — invocation protocol and handoff patterns
- **Developer** (`${CLAUDE_PLUGIN_ROOT}/agents/developer.md`) — implements the code fix and tests from the approved plan
- **Reviewer** (`${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md`) — reviews the fix for correctness, security, performance
- **Committer** (`${CLAUDE_PLUGIN_ROOT}/agents/committer.md`) — stages files and commits with proper message format

**Chain:** Developer -> Reviewer -> Committer (with fix loops on review issues or hook failures)

**What this command keeps:** Parse fix request, spec-first analysis, plan approval, PRD updates (fix notes), formatter/linter execution.

## Critical Directives

These override every step below. No exceptions.

1. **Right over easy.** Fix the root cause, not the symptom. If the correct fix requires more effort than a workaround, do the correct fix. Never patch around a problem when a proper solution exists.
2. **Fix everything you see.** Pre-existing linter warnings, type errors, test failures, and convention violations must be fixed when detected. You own every issue you encounter, regardless of who introduced it.

## Step 1: Parse Arguments & Identify Context

Parse `$ARGUMENTS` to separate an optional requirement/task ID from the fix description.

### ID Detection

Look for a leading ID token matching one of these patterns:

| Pattern | Type | Example |
|---------|------|---------|
| `UC-{tag}-NNN/N.M` | Sub-task | UC-0Fy0-001/1.1 |
| `UC-{tag}-NNN/N` | Task | UC-0Fy0-001/3 |
| `UC-{tag}-NNN` | Use case | UC-0Fy0-001 |
| `FR-{tag}-NNN` | Functional requirement | FR-0Fy0-003 |
| `NFR-{tag}-NNN` | Non-functional requirement | NFR-0Fy0-001 |
| `US-{tag}-NNN` | User story | US-0Fy0-002 |

Everything after the ID token is the fix description. If no ID token is found, the entire argument is the fix description.

### Context Resolution

**If an ID was found:**

1. Search all `prd/specs/*/tasks.md` files for the ID:
   - Task/sub-task ID (`UC-{tag}-NNN/N` or `UC-{tag}-NNN/N.M`): locate the exact task entry
   - Use case ID (`UC-{tag}-NNN`): locate the UC section
   - Requirement ID (`FR-{tag}-NNN`, `NFR-{tag}-NNN`, `US-{tag}-NNN`): search `prd/specs/*/requirements.md` and `prd/specs/*/spec.md` to find the feature folder, then locate related tasks in that feature's tasks.md
2. Extract the feature folder path (`prd/specs/{folder}/`)
3. Extract the relevant task/UC context and acceptance criteria

**If no ID was found:**

1. Extract keywords from the fix description
2. Search all `prd/specs/*/tasks.md`, `prd/specs/*/requirements.md`, and `prd/specs/*/spec.md` files for those keywords
3. If a single clear match is found, use that feature as the context
4. If multiple matches are found, use AskUserQuestion to ask the user which feature/task this fix applies to — include "Chores (not feature-specific)" as an additional option
5. If no match is found, default to `prd/specs/chores/` without asking — this is a chore

## Step 2: Gather Context

Launch a `general-purpose` sub-agent using the Task tool to build a structured context brief. The prompt must include the feature folder path and the fix description. The agent should:

- **If the folder is `chores`**: skip `spec.md`, `requirements.md`, and `tasks.md` (they don't exist in chores). Set those brief sections to "N/A — chores fix".
- **Otherwise**:
  - Read `prd/specs/{folder}/spec.md` — extract sections relevant to the identified requirement/use case
  - Read `prd/specs/{folder}/requirements.md` — extract acceptance criteria and functional requirements (if exists)
  - Read `prd/specs/{folder}/tasks.md` — extract the relevant task details and current status
- Read `prd/tech-stack.md` — extract architecture and conventions
- Read `CLAUDE.md` — extract project conventions
- Read per-task changelog files in `prd/specs/{folder}/plans/changelog-*.md` — summarize what's already built in the relevant domain
- Scan `**/README.md` files (excluding `node_modules/`, `prd/`) in directories related to the fix scope — summarize existing patterns
- Read the project-management skill at `${CLAUDE_PLUGIN_ROOT}/skills/project-management/SKILL.md`

The agent must return a structured brief in this format:
```
FIX_CONTEXT:
- Feature: {feature folder name}
- Requirement/Task: {ID and title}
- Current status: {completed/in-progress/pending}
- Fix description: {user's fix description}

SPEC_EXCERPT:
{Only the sections from spec.md relevant to this fix}

REQUIREMENTS_EXCERPT:
{Functional requirements and acceptance criteria for the related use case, or "No requirements.md found"}

TASK_EXCERPT:
{The relevant task entry from tasks.md, including acceptance criteria and completion notes if any}

TECH_CONTEXT:
- Stack: {relevant stack for this fix}
- Conventions: {key conventions from CLAUDE.md and tech-stack.md}
- Architecture: {relevant architecture patterns}

EXISTING_PATTERNS:
{Summary of existing code patterns from README scans relevant to this fix}

CHANGELOG_SUMMARY:
{What's already built from per-task changelog files, or "No changelog files found"}

WARNINGS:
{Any issues: missing spec sections, ambiguities — or "NONE"}
```

Use the returned brief as your context for all subsequent steps. Do NOT read these files again yourself.

## Step 3: Clarify

If anything about the fix is ambiguous after reading the context brief, use AskUserQuestion to clarify with the user. Examples:
- The fix description is vague and could mean multiple things
- The root cause isn't clear from the description
- Multiple valid fix approaches exist

If the fix is clear, skip this step.

## Step 3b: Root Cause Classification

Classify the defect's root cause:

| Classification | Indicator | Action |
|---------------|-----------|--------|
| Requirements gap | Acceptance criteria missing/incorrect | Update requirements.md |
| Spec error | Data model/API/flow incorrect | Update spec.md |
| Task definition gap | Task criteria incomplete/wrong | Update tasks.md |
| BDD scenario error | Steps don't match intended behavior | Update .feature files |
| Code-only bug | Spec is correct, implementation diverged | Skip to Step 4 |

1. Read `bdd/CLAUDE.md`. If not configured, classify as "Code-only bug" (backward compatible).
2. Check `bdd/features/` for scenarios related to affected task/UC.
3. Evaluate fix description against spec artifacts. Determine classification.
4. If NOT "Code-only bug": update spec artifacts, present to user via AskUserQuestion, iterate until approved, then proceed to Step 4.
5. If "Code-only bug": proceed to Step 4 directly.

## Step 4: Plan

> Remember: **Right over easy.** Fix the root cause, not the symptom. If the proper fix is harder than a workaround, do the proper fix.

1. Get a UTC timestamp by running `date -u +%Y%m%d-%H%M` (e.g., `20260311-1430`).

2. Determine the plan filename:
   - Sub-task scope → `{timestamp}-fix-UC-{tag}-NNN--N.M.md`
   - General fix or chores fix (no specific task) → `{timestamp}-fix-{slug}.md` (short slug from the fix description)

   Note: double-dash `--` separates the UC ID from the task/subtask number.

3. Explore the codebase to understand the current implementation, the bug or issue, and what needs to change.

4. Write the plan to `prd/specs/{feature}/plans/{plan-filename}` (create the `plans/` directory if needed). The plan should cover:
   - Root cause analysis (what's wrong and why)
   - Files to modify
   - The fix approach
   - How to verify the fix works

5. Present the plan to the user. Output the plan content in your message, then use AskUserQuestion:
   - Question: "Do you accept the fix plan?"
   - Header: "Plan"
   - Options:
     - "Yes, proceed with the fix" — proceed to Step 5
     - "No, I have feedback" — user provides feedback via the "Other" option
   - multiSelect: false

6. If the user provides feedback, update the plan file, present the updated plan, and ask again. Repeat until accepted.

## Step 5: Write Code

> Remember: **Right over easy.** Implement the correct fix from the plan. **Fix everything you see** — if you open a file and find pre-existing issues, fix them.

Implement the fix following the approved plan. Key rules:
- Follow all conventions from CLAUDE.md (resolver rules, component architecture, i18n, etc.)
- Follow patterns from the relevant coding skills (Go, TypeScript, React, etc.)
- Stay within the scope of THIS fix only — do not refactor adjacent code
- Make the minimum changes needed to resolve the issue

## Step 6: Write Tests

Write or update tests for the code you modified:
- Add test cases that reproduce the original issue and verify the fix
- Update existing tests if the fix changes expected behavior
- Follow existing test patterns in the codebase
- Place test files in `__tests__/` sibling directories (frontend) or alongside the code (Go)

## Step 7: Run Tests

Run the test suite to verify everything passes:
- Run the specific tests you wrote or modified
- Run the broader test suite for affected areas
- If `bdd/CLAUDE.md` is configured, run BDD tests for the affected task/UC tags: `--tags=@task-{ID}` or `--tags=@uc-{UC-ID}`
- If tests fail, fix the code and re-run until green
- Do NOT skip failing tests or mark them as expected failures

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
- Prompt: Read the code-documentation skill at `${CLAUDE_PLUGIN_ROOT}/skills/code-documentation/SKILL.md` and the README template at `${CLAUDE_PLUGIN_ROOT}/skills/code-documentation/references/readme-template.md`. Identify all directories where files were **created** or **deleted** during this fix (provide the list). For each such directory (skip `node_modules/`, `dist/`, `build/`, `coverage/`, `vendor/`, `.git/`, `__tests__/`, `prd/`, asset-only directories):
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
   a. Send FINDINGS to the Developer agent to fix (same invocation as Step 5, with FINDINGS as additional input)
   b. After Developer fixes, re-run tests (Step 7 logic)
   c. Re-run Reviewer on updated files (standalone, no README updater)
   d. Max 3 fix cycles. If the review still has CRITICAL issues after 3 cycles, escalate to user via AskUserQuestion.

## Step 9: Update PRD Files (No Status Change)

**Do NOT mark any task checkboxes as complete.** This is a fix, not initial implementation.

1. **Update tasks.md** (skip if the fix folder is `chores` — chores has no tasks.md): Under the relevant task or sub-task entry, append a fix note:
   ```
   - Fix ({YYYY-MM-DD}): {brief description of what was fixed and why}
   ```

   Example — if the fix targets UC-{tag}-NNN/1.1:
   ```
   - [x] 1.1 Create `server/internal/database/executor.go`
     - Complexity: 1
     - Dependencies: None
     - Acceptance: ...
     - Completed: 2026-02-10
     - Notes: Created DBExecutor interface...
     - Fix (2026-02-12): Fixed interface to include CopyFrom method that was missing from DBExecutor, causing compilation failures in bulk insert operations
   ```

2. **Write per-fix changelog file**: Get a UTC timestamp by running `date -u +%Y%m%d-%H%M`. Create `prd/specs/{feature}/plans/{timestamp}-changelog-fix-{slug}.md` (or `{timestamp}-changelog-fix-UC-{tag}-NNN--N.M.md` for sub-task scoped fixes) with:
   - What was fixed and why (root cause)
   - Files modified
   - Requirement IDs affected

3. **Update main changelog**: Append to `prd/changelog.md` in chronological format:
   - Add entry under today's date heading (create heading if not exists)
   - Get the current UTC time by running `date -u +%H:%M` and use it as the timestamp (HH:MM)
   - Include the timestamp, fix title, brief description
   - Link to the fix plan file and changelog file

   Example:
   ```markdown
   ## 2026-02-14

   - [22:00] Fix CopyFrom missing from DBExecutor interface
     Adds CopyFrom method to DBExecutor, resolving compilation failures in bulk inserts.
     - Plan: [20260214-2200-fix-UC-0FyC-001--1.1.md](specs/20260212-1512-db_executor_transactions/plans/20260214-2200-fix-UC-0FyC-001--1.1.md)
     - Changelog: [20260214-2200-changelog-fix-UC-0FyC-001--1.1.md](specs/20260212-1512-db_executor_transactions/plans/20260214-2200-changelog-fix-UC-0FyC-001--1.1.md)
   ```

## Scope Control

This is critical: fix ONLY the described issue. Do not:
- Implement adjacent tasks "while you're at it"
- Refactor unrelated code
- Add features not related to the fix
- Modify files outside the fix's scope unless required

When done, tell the user what was fixed (include commit hash) and where the fix notes were recorded.

## Step 10: Commit

Launch the Committer agent using the Task tool:
- Read the Committer agent definition at `${CLAUDE_PLUGIN_ROOT}/agents/committer.md`
- Follow the invocation template from `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/references/invocation-template.md`
- Provide: fix context (task ID or slug, feature name, UC ID if applicable), accumulated FILES_CREATED + FILES_MODIFIED (from Developer, README updater, and any fix-cycle changes)

After the Committer returns:
1. If COMMIT_STATUS is SUCCESS -> report commit hash and message to user
2. If COMMIT_STATUS is HOOK_FAILURE:
   a. Send HOOK_OUTPUT to the Developer agent to fix the issues
   b. After Developer fixes, re-run Review Gate (Step 8) then Committer (Step 10)
   c. Max 3 hook-failure cycles. If commit still fails after 3 cycles, escalate to user via AskUserQuestion.
3. If COMMIT_STATUS is ERROR -> report error to user and stop

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- Follow all project conventions from CLAUDE.md.
- Do not use the word "comprehensive" in any document.
- Never mark task checkboxes — fixes do not change completion status.
