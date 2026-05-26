---
name: planning
description: >-
  Rules for generating implementation plans from PRD specs. Defines plan file
  format, task decomposition rules, context budgets, the coverage-gate done
  signal, task status lifecycle, naming conventions, and slug generation.
  Used by /m:plan (intent: implement) and /m:reverse-plan (intent: cover).
---

# Planning

Rules for generating implementation plan files in `.molcajete/plans/`. Plans are **JSON files** inside directories — never markdown. A plan decomposes specified use cases (or coverage gaps, in the reverse case) into ordered tasks that the build command will execute via the two-subagent loop.

## When to Use

- Generating an implementation plan from specified use cases with `/m:plan`
- Generating a coverage-recovery plan from existing code with `/m:reverse-plan`
- Understanding task decomposition rules and context budgets
- Referencing plan file format and naming conventions

## Plan File Format

Plan files live at `.molcajete/plans/{YYYYMMDDHHmm}-{slug}/plan.json`. Each plan gets its own directory so per-task run logs and validation artifacts can live alongside the plan. The exact JSON structure is defined by [plan-schema.json](./templates/plan-schema.json). Read the schema before generating any plan file. The output must be valid JSON written with `JSON.stringify(data, null, 2)` formatting — do not produce markdown plan files.

### Plan Directory Structure

```
.molcajete/plans/{YYYYMMDDHHmm}-{slug}/
  plan.json
  plan.md
  runs/
    T-001.log
    T-002.log
```

## The Planner Names Behaviors; the Build Agent Decomposes Them

The planner produces one task per behavior or small cluster of related behaviors. It does **not** enumerate the test-and-code work for each behavior. Whether a task contains one behavior or four, the planner writes one task. The build agent decomposes the task's behaviors at build time using the task description, the architecture doc, and the existing code.

This protects the plan from explosion and protects the planner from making decisions it cannot make well — the planner has spec context but not the implementation context needed to know how many behaviors a task really contains. The build agent has both. Sub-tasks are reserved for context-budget splitting only, never for Red/Green/Refactor phases.

## Companion `plan.md` (greenfield)

Every `/m:plan` run writes a human-readable `plan.md` alongside `plan.json` in the same plan directory. The MD is a WYSIWYG preview of what `/m:build` will produce — users review it before executing the plan.

### Generation order

1. Build the plan JSON in memory.
2. Write `plan.json` to disk.
3. Derive `plan.md` from the JSON plus PRD context and write it to the same directory.

JSON is always authoritative. MD is a pure function of JSON + PRD files; it is regenerated on every plan write and is never hand-edited. If the user wants to change the plan, they edit intent and regenerate — never the MD alone.

### Structure

Use the skeleton at [plan-template.md](./templates/plan-template.md). Required sections in order:

1. **Title** — from `plan.title`.
2. **Context** — 1–3 paragraphs sourced from scoped features' REQUIREMENTS.md "why" framing plus the plan's scope intent.
3. **Scope** — bulleted links to each in-scope feature README and UC file, plus `base_branch`.
4. **Non-requirements (plan-level)** — from REQUIREMENTS.md out-of-scope sections.
5. **Tasks** — one `### T-NNN — {title}` section per top-level task, in JSON order. Each task section contains:
   - **References** — feature, use case, architecture links.
   - **What changes** — narrative version of `task.description`.
   - **Important snippets** — small code sketches (≤ ~15 lines each) derived from ARCHITECTURE.md Code Map entries and `files_to_modify`. For new exports, show the shape (signature or type), not the full body.
   - **Files to create/modify** — from `task.files_to_modify`, with short notes. Sub-tasks, when present, appear as nested bullets here — they do not get their own full sections.
   - **Non-requirements (task-level)** — what the task is explicitly NOT doing.
   - **Verification** — three bullets: coverage gate (full test suite passes and coverage meets the project threshold from `.molcajete/settings.json` `testing.threshold`, executed by the Validator subagent during `/m:build`), manual smoke (1–3 steps derived from the UC's scenario Steps and Outcomes), file-level assertions (expected files + key exports/functions).

### Link path convention

Plan directory lives at `.molcajete/plans/{YYYYMMDDHHmm}-{slug}/plan.md` — three directories deep. Relative links to PRD files use `../../../prd/...`. Scenario anchors use `#sc-xxxx` (lowercased SC ID) pointing into the UC file.

### Fields excluded from greenfield MD

Never render: `plan.status`, `task.status`, `task.summary`, `task.errors`, `task.estimated_context`, `task.depends_on`. These are execution state or implementation concerns; the MD is a pre-execution preview.

## Companion `plan.md` (reverse / coverage-recovery)

Every `/m:reverse-plan` run writes a `plan.md` alongside `plan.json`. The MD lists each in-scope module with current coverage and the project threshold, then describes the per-file behavior tasks that the build loop will execute.

### Structure

Use the skeleton at [reverse-plan-template.md](./templates/reverse-plan-template.md). Required sections:

1. **Title** — `{plan.title} — Coverage Recovery`.
2. **Context** — one short paragraph: number of modules scanned, files needing coverage, and the project threshold.
3. **Modules** — one subsection per in-scope module: current coverage percentage, threshold, and a list of files with gaps. Modules that are already at or above threshold are omitted.
4. **Tasks** — one `### T-NNN — Cover {file-relative-path}` section per task. Each task section contains:
   - **File under test** — the production file path.
   - **Current coverage** — percentage.
   - **Uncovered behaviors / branches** — the gap clusters as the planner classified them. These are the behaviors the build agent will write tests for; the build agent decides actual test placement and assertion shape.
   - **Files to modify** — same as `task.files_to_modify`.
   - **Verification** — coverage gate (file moves to at or above threshold AND total project coverage stays at or above threshold; both confirmed by the Validator subagent).

### Fields excluded from reverse MD

Same exclusions as greenfield: `plan.status`, `task.status`, `task.summary`, `task.errors`, `task.estimated_context`, `task.depends_on`.

## Task Decomposition Rules

### Behavior-Cluster Tasks

Each top-level task names one behavior or a small cluster of related behaviors. The planner does not split behaviors into multiple tasks per Red/Green/Refactor — the build loop handles that internally.

**Good decomposition:**
- "Implement patient registration happy path and duplicate-email rejection" — one task, two related behaviors
- "Implement password reset request and confirmation" — one task, two phases of the same flow

**Bad decomposition:**
- "Write test for patient registration" + "Implement patient registration" + "Refactor patient registration" — three tasks for one behavior; the build loop does this internally
- "Set up database models" — layer-based, doesn't name any behavior
- "Create API routes" — infrastructure without behavior framing

### Infrastructure Absorption

Infrastructure work is **not** standalone top-level tasks. The first behavior task absorbs infrastructure cost — split it into sub-tasks when infrastructure + implementation exceeds 200K context:

- **Sub-task 1:** Builds shared infrastructure (test harness, database migrations, shared middleware)
- **Sub-task 2:** Implements the behavior on top of that infrastructure

Sub-tasks inherit `intent` and other fields from the parent. The coverage gate runs only at the parent-task level after all sub-tasks complete.

### Cross-Module Awareness

Read `prd/MODULES.md` as part of project context. When a feature spans modules, the first task for that feature absorbs infrastructure cost. Do not create per-module infrastructure tasks. Tasks slice vertically by behavior — a task's files may span any number of modules' codebases.

### Using ARCHITECTURE.md Enrichment

When ARCHITECTURE.md contains a Code Map section with entries, use it to:
- Map UC scenarios to implementation files for more accurate task decomposition
- Include referenced files in each task's `files_to_modify` list
- Estimate context budgets more precisely
- Identify shared files that appear across multiple scenarios — these may need infrastructure absorption into the first task's sub-tasks

### Task Intent

Each task carries an `intent` field that tells the build loop what kind of work to do:

| Intent | Set by | Meaning |
|--------|--------|---------|
| `implement` | `/m:plan` | Build new code from specs. The Implementer writes a test for each behavior, then production code in its final form. |
| `cover` | `/m:reverse-plan` | Add tests to existing code until the project meets the coverage threshold. The Implementer writes tests for uncovered behaviors; production code is touched only when an untestable seam needs reactive refactor. |

The build loop is the same for both intents — same Implementer + Validator pair, same coverage gate. Only the Implementer's framing differs.

### Task Sizing

Each task must fit within an estimated **200K token context budget**. This budget covers:
- Reading relevant source files
- Reading relevant spec files (UC, REQUIREMENTS, ARCHITECTURE)
- The Implementer + Validator rounds for this task

If a task would exceed the budget, split it into **sub-tasks** within the same task (see Sub-Task Decomposition below). Do not create separate top-level tasks for what is logically one unit of work.

### Sub-Task Decomposition

Sub-tasks break a large task into sequential steps that share a single worktree and branch. Use sub-tasks when a task is too large for one context window but logically belongs together, or when infrastructure must be absorbed.

#### When to Use Sub-Tasks

| Condition | Sub-tasks? |
|-----------|-----------|
| Under 200K estimated context, no shared infra | No |
| Over 200K estimated context | Yes |
| New shared infrastructure that the behavior depends on | Yes |

#### Sub-Task Rules

- **ID format:** `T-NNN-M` — parent task ID + dash + integer (e.g., `T-003-1`, `T-003-2`). Never use decimal IDs.
- **`sub_tasks` field:** `null` when the task has no sub-tasks. An array of sub-task objects when decomposed.
- **Inheritance:** Sub-tasks inherit `use_case`, `feature`, `module`, `architecture`, and `intent` from the parent task. These fields are not repeated in the sub-task object.
- **Dependencies:** `depends_on` in a sub-task references **sibling sub-task IDs only** (e.g., `T-003-1`), never top-level task IDs.
- **Shared worktree:** All sub-tasks run in the parent task's worktree — no separate branches.
- **Validation split:** Sub-tasks get formatting + linting + completeness checks; the coverage gate runs only at the parent-task level after all sub-tasks complete.
- **Sizing:** Each sub-task should fit within 200K tokens. The parent task's `estimated_context` reflects the total across all sub-tasks.

The two-subagent loop runs inside each sub-task scoped to its own `description` and `files_to_modify`. Sub-tasks are not Red/Green/Refactor phases.

#### Sub-Task Object Shape

See the `sub_task_schema` section in [plan-schema.json](./templates/plan-schema.json) for the exact fields. Key differences from top-level tasks:
- No `use_case`, `feature`, `module`, `architecture`, or `intent` (inherited from parent)
- `depends_on` scoped to sibling IDs
- `summary`, `errors` work the same as top-level tasks

### Task Ordering

Order tasks by dependency chain:
1. Data model tasks before API tasks
2. Core logic before edge cases
3. Happy-path behaviors before error-handling behaviors

Express dependencies explicitly with the `depends_on` field.

## Done Signals

A task is done when:
1. All behaviors named in the task description are covered.
2. The full test suite passes.
3. Coverage meets the project threshold from `.molcajete/settings.json` `testing.threshold`.

The build command enforces these via the Implementer + Validator loop. The Validator's `pass` outcome — combined with the orchestrator's bookkeeping that every named behavior has been covered — is the only signal that closes a task.

## Task Status Lifecycle

```
pending → in_progress → implemented
                      → failed
```

| Status | Meaning |
|--------|---------|
| `pending` | Not started, waiting for dependencies |
| `in_progress` | Currently being worked on by `/m:build` |
| `implemented` | Done signals satisfied (suite passes, coverage meets threshold, behaviors covered) |
| `failed` | Iteration cap hit and user paused, or hard fault — needs intervention |

Plan-level status follows the same values:
- `pending` — no tasks started
- `in_progress` — at least one task in progress
- `implemented` — all tasks implemented
- `failed` — any task failed and work stopped

## Research Discovery

When generating an implementation plan, scan for relevant research briefs:

1. List `.molcajete/research/*.md` — filenames sort naturally by timestamp (newest first)
2. Read only the YAML frontmatter of each file (not the body)
3. Compare `description` and `query` against the plan's topic/scope
4. If relevant, read the full document and use it as context
5. Stop after the first relevant match to protect context window
6. Also scan `research/*.md` at project root the same way

The brief's "Existing Codebase Patterns" section helps understand what exists and what needs to change. The "Key Libraries/APIs" section informs task decomposition when new dependencies are involved.

## Plan File Naming

### Timestamp

Format: `{YYYYMMDDHHmm}` — year, month, day, hour (24h), minute. Use the current time when generating the plan.

### Slug Generation

Derive the slug from the scope:

| Scope | Slug | Example |
|-------|------|---------|
| Single feature | Feature name in kebab-case | `user-authentication` |
| Single UC | UC name in kebab-case | `email-login` |
| Multiple features | `mixed` | `mixed` |
| Full scan | `full-scan` | `full-scan` |
| Coverage single module | `coverage-{module}` | `coverage-api` |
| Coverage mixed | `coverage-mixed` | `coverage-mixed` |
| Coverage full scan | `coverage-full-scan` | `coverage-full-scan` |

Full plan directory example: `202603261430-user-authentication/plan.json`

## Scope Field Rules

The `scope` field in the plan JSON records exactly the IDs the user passed to the plan command — no expansion.

- If user passes `FEAT-0A1b`, scope is `["FEAT-0A1b"]` — not the feature plus all its UCs
- If user passes `UC-0A1b UC-0A2c`, scope is `["UC-0A1b", "UC-0A2c"]`
- If no arguments (full scan mode), scope is `["full-scan"]`

The planner still expands internally to discover plannable work (e.g., resolving a feature to its UCs), but the `scope` field only stores the original input.

## Schema

Read the plan schema before generating:

```
${CLAUDE_PLUGIN_ROOT}/plan/skills/planning/templates/plan-schema.json
```
