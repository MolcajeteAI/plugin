# Single-Task Mode

You are implementing a specific sub-task from a feature's tasks.md file. The task identifier must be a sub-task ID (N.M format, e.g., "UC-0Fy0-001/1.1"). If a parent task ID is given (e.g., "UC-0Fy0-001/1"), use AskUserQuestion to ask which sub-task to work on. Follow this strict 7-step workflow and execute ONLY the requested sub-task.

## Designated Agents

This workflow delegates to these agents (read agent definitions before dispatching):

- **Developer** (`${CLAUDE_PLUGIN_ROOT}/agents/developer.md`) — implements code and tests from the approved plan
- **Reviewer** (`${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md`) — reviews code for correctness, security, performance

See `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/SKILL.md` for invocation protocol and handoff patterns.

## Step 1: Gather Context

1. Find the tasks.md file. If the task identifier looks like a task ID (e.g., "UC-001/1.1", "UC-002/1"), search all `prd/specs/*/tasks.md` files for that task under the matching UC section. If it mentions a feature name, find the matching folder. If ambiguous, use AskUserQuestion.

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
   - Read `prd/changelog.md` — summarize what's already built (if exists)
   - Scan `**/README.md` files (excluding `node_modules/`, `prd/`) in directories related to the task's scope — summarize existing patterns
   - Read the project-management skill at `.claude/skills/project-management/SKILL.md`

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
   {What's already built in related domains, or "No changelog found"}

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

## Step 3: Plan

Enter plan mode using EnterPlanMode. In plan mode:

1. Explore the codebase to understand existing patterns, related code, and where new code should go.
2. Design a mini implementation plan covering:
   - Files to create or modify
   - Key implementation decisions
   - How this integrates with existing code
3. Write the plan to `prd/specs/{feature}/plans/{task-slug}.md` (create the `plans/` directory if needed).
4. Exit plan mode with ExitPlanMode to get user approval.

## Step 3b: Load BDD Acceptance Criteria

1. Read `bdd/CLAUDE.md`. If no `# BDD Configuration` section, skip this step (backward compatible).
2. Grep `bdd/features/` for files containing `@task-{current-task-ID}`.
3. If matching scenarios exist:
   a. Read the matching `.feature` files and extract scenarios tagged with the current task ID.
   b. Update the plan file with a "BDD Acceptance Criteria" section listing each scenario.
   c. These scenarios become the primary acceptance criteria.
4. If no matching scenarios exist, skip (fall back to current behavior).

## Step 4: Write Code

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
- If tests fail, fix the code and re-run until green
- Do NOT skip failing tests or mark them as expected failures

## Step 7: Quality Gate

Launch 3 parallel sub-agents using the Task tool in a single message:

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

**Agent 3 — Reviewer** (invoke the Reviewer agent):
- Read the Reviewer agent definition at `${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md`
- Follow the invocation template from `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/references/invocation-template.md`
- Provide the list of all files created or modified during this task
- The Reviewer discovers stack-specific coding skills at runtime for convention checking
- Return the Reviewer's standard output format (REVIEW_STATUS, VERDICT, FINDINGS)

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

After all agents return:
1. If formatting issues -> run the formatter to fix them
2. If lint issues -> fix the lint errors
3. If Reviewer found CRITICAL or WARNING issues -> fix them
4. Write README content from Agent 4 (CREATE new files, UPDATE existing ones)
5. If any code was changed in steps 1-3 -> re-run tests (Step 6). README-only changes do NOT trigger re-testing.

## After All Steps Pass

1. **Update tasks.md**: Mark the task checkbox as complete. Add completion notes:
   ```
   - [x] N.M {Task title}
     - Complexity: {points}
     - Dependencies: {deps}
     - Acceptance: {criterion}
     - Completed: {YYYY-MM-DD}
     - Notes: {brief description of approach, key decisions, files created/modified}
   ```

2. **Update changelog.md**: Append to or update the relevant domain section in `prd/changelog.md` describing what now exists, mapped to requirement IDs.

3. **Stop**: Do NOT continue to the next task. Report what was completed and suggest the next task to implement.

## Scope Control

This is critical: execute ONLY the requested task. Do not:
- Implement adjacent tasks "while you're at it"
- Refactor unrelated code
- Add features not in the task's acceptance criteria
- Modify files outside the task's scope unless required by the task

When done, tell the user what was completed and suggest: "Next task: `/m:dev {UC-XXX/next-task-id}`"

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- Follow all project conventions from CLAUDE.md.
- Never stage files or create commits — the user manages git.
- Do not use the word "comprehensive" in any document.
