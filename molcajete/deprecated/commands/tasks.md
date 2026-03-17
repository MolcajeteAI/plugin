---
description: Break a specification into implementation tasks
model: claude-opus-4-6
allowed-tools: Read, Write, Edit, Glob, Grep, Task, AskUserQuestion
argument-hint: <feature folder name>
---

# Create Implementation Tasks

You are breaking a technical specification into actionable implementation tasks organized as vertical feature slices. Output goes to the feature's folder inside `prd/specs/`.

**Feature folder:** $ARGUMENTS

## Critical Directives

These override every step below. No exceptions.

1. **Right over easy.** When breaking the spec into tasks, do not simplify tasks by choosing easier implementation approaches. Each task must deliver the architecturally correct solution from the spec. If a task is complex, size it accordingly — do not reduce scope to lower the estimate.
2. **Fix everything you see.** If you encounter inconsistencies, gaps, or errors in existing PRD files, specs, or requirements while working, fix them.

## Step 1: Identify Feature Folder

If `$ARGUMENTS` is provided, look for a matching folder in `prd/specs/`. Match by folder name (exact or partial). If multiple matches or no match, use AskUserQuestion to clarify.

If `$ARGUMENTS` is not provided, list available feature folders and use AskUserQuestion to ask which one.

## Step 2: Verify Spec Exists

Check that `spec.md` exists in the feature folder. If it doesn't, tell the user to run `/m:spec {folder}` first and stop.

## Step 3: Load Context via Sub-Agents

Launch 2 parallel sub-agents using the Task tool in a single message:

**Agent 1 — Skills and Templates** (subagent_type: `Explore`, thoroughness: "very thorough"):
- Prompt: Read the following files and return their full content:
  - `${CLAUDE_PLUGIN_ROOT}/skills/project-management/SKILL.md`
  - `${CLAUDE_PLUGIN_ROOT}/skills/project-management/references/tasks-template.md`
  Return:
  ```
  SKILL_RULES:
  {Key rules and conventions from SKILL.md — task formatting, estimation, vertical slicing, single-checklist rule}

  TEMPLATE:
  {Full content of tasks-template.md}
  ```

**Agent 2 — Spec and Codebase Context** (subagent_type: `general-purpose`):
- Prompt: Read the following files and return a structured summary:
  - `prd/specs/{folder}/spec.md` — the full specification (summarize each section: data models, API contracts, UI components, acceptance criteria, implementation checklist)
  - `prd/specs/{folder}/requirements.md` — requirements with UC/FR/NFR IDs (if exists)
  - `prd/mission.md` — vision, users
  - `prd/tech-stack.md` — architecture, stack choices
  - Per-task changelog files in `prd/specs/*/plans/changelog-*.md` — what's already built (scan all feature folders)
  - `CLAUDE.md` — project conventions
  Also scan `**/README.md` files (excluding `node_modules/`, `prd/`) in directories that will likely be touched by implementation. Read those READMEs to understand existing file organization, patterns, and dependencies.
  Return:
  ```
  SPEC_SUMMARY:
  - Feature: {name and description}
  - Use cases: {list of UC IDs with titles}
  - Data models: {tables to create/modify}
  - API operations: {queries and mutations per app schema}
  - UI components: {component list with types}
  - Acceptance criteria: {summary per UC}
  - Implementation checklist: {grouped by subsystem}

  REQUIREMENTS_SUMMARY:
  {UC/FR/NFR ID list with titles, or "No requirements.md found"}

  PROJECT_CONTEXT:
  - Stack: {relevant stack}
  - Conventions: {key conventions for task breakdown}
  - Already built: {from per-task changelog files, or "No changelog files found"}

  CODEBASE_PATTERNS:
  {Existing file organization and patterns from README scans — migration naming, resolver structure, component placement, test file locations}
  ```

Use the returned context for all subsequent steps. Do NOT read these files again yourself.

## Step 4: Break Into Vertical Slices

> Remember: **Right over easy.** Do not simplify tasks by choosing easier implementation approaches. Each task must deliver the architecturally correct solution from the spec. If a task is complex, size it accurately — do not reduce scope to lower the estimate.

Analyze the spec and create tasks following these principles:

### Organize by Use Case

Each top-level section corresponds to a use case from requirements.md. The section heading MUST include the UC ID:

```
## [ ] UC-{tag}-001. {Use case title}

- [ ] 1. {Task title}
  - [ ] 1.1 {Subtask title}
  - [ ] 1.2 {Subtask title}

## [ ] UC-{tag}-002. {Use case title}

- [ ] 1. {Task title}
  - [ ] 1.1 {Subtask title}
```

Task numbering restarts at 1 within each use case section. Subtasks use `N.M` format within their parent task.

### Vertical Slicing

Each use case section should deliver a complete, testable slice through all layers:
- Database migration (if needed)
- Repository/data access functions
- API schema and resolvers
- Frontend components and state
- Tests for the slice

Do NOT organize tasks as horizontal layers ("all migrations first", "all schemas second").

### Task Sizing

Estimate each task with story points (1/2/3/5/8). If a task exceeds 8 points, split it. Include complexity rationale in the acceptance criteria.

### Dependencies

Identify dependencies between tasks. Earlier tasks should unblock later ones. Within a feature, order tasks by their natural implementation sequence.

### Parallel Opportunities

Identify tasks that can be developed in parallel (no shared dependencies). Call these out in the execution strategy.

## Step 5: Generate Tasks

Write `tasks.md` in the feature folder following the tasks template. Include:

1. **Overview** — Feature description, strategic alignment, success criteria, estimated total effort, key risks
2. **Use case sections** — One `## [ ] UC-{tag}-NNN. {title}` section per use case, with tasks using `- [ ] N. {title}` and subtasks using `- [ ] N.M {title}`
3. **Task details** — Each task/subtask has: Complexity (points), Dependencies, Acceptance (one-line criterion)
4. **Execution Strategy** — Recommended approach, critical path diagram (Mermaid), parallel opportunities

### Single-Checklist Rule

The feature-level and task-level checkboxes ARE the progress tracking. Do not add separate progress tables, status columns, or completion percentage sections. When a task is completed during `/m:dev`, its checkbox gets marked and completion notes are added inline.

## Step 6: Validate Dependencies

After generating tasks.md, review the dependency graph across all use cases. For each UC section, trace its tasks' dependencies and verify:

1. **No UC depends on a later UC to start.** Every UC section should be executable top-to-bottom without waiting for tasks in other UC sections, OR its dependencies should point to earlier UC sections only.
2. **No circular dependencies between UCs.** UC-001 depending on UC-003 while UC-003 depends on UC-001 is a deadlock.
3. **The first UC can start with zero prerequisites.** If even UC-001 requires something from UC-004, the plan is broken.

### If dependencies are clean

Skip ahead to Step 7.

### If cross-UC dependency conflicts exist

Any shared infrastructure needed to complete a use case should be built as subtasks of that use case, even if other use cases also benefit from it. The UC that needs the infrastructure first owns it.

**Resolution rules:**
- Infrastructure tasks (command skeleton, argument router, shared migrations, base types) become subtasks of the UC that needs them
- If multiple UCs need the same infrastructure, it belongs to whichever UC comes first — later UCs simply depend on that earlier UC
- Reorder UC sections if needed so the UC containing the shared work comes first
- If a UC grows large because it includes infrastructure, that's correct — size it accordingly with story points

After reordering, re-validate the dependency graph to confirm all conflicts are resolved. Update the Execution Strategy and critical path diagram to reflect the new structure.

## Step 7: Update Roadmap

If `prd/roadmap.md` exists, update the feature's entry to include a link to the tasks file.

## Step 8: Inform User

After generating the document, tell the user:
- What file was created and where
- Total story points and number of tasks
- Critical path summary
- Suggest next steps: "Use `/m:dev {UC-{tag}-NNN/task-id}` to start implementing a task (e.g., `/m:dev UC-0Fy0-001/1.1`)."

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- Follow all formatting rules from the project-management skill: no emojis, text checkboxes only, Mermaid-only diagrams, points not time, vertical slices not horizontal layers, single-checklist rule.
- Map each feature section to a UC from requirements.md.
- Do not use the word "comprehensive" in any document.
- Include tests as tasks within each feature slice, not as a separate "testing" feature.
