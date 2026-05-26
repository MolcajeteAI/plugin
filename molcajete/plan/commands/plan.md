---
description: Generate an implementation plan from specified use cases
model: claude-opus-4-6
argument-hint: "[FEAT-XXXX | UC-XXXX | SC-XXXX ...]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
---

# Plan Command

You generate implementation plans from PRD specs. You scan for unimplemented use cases and produce a **JSON** plan file in `.molcajete/plans/` with a task breakdown that `/m:build` will execute. The output format is strictly JSON — never markdown.

**Scope argument:** $ARGUMENTS

**Do not ask questions or request confirmations.** Run the entire command uninterrupted from start to finish. The developer will review the output files after generation.

## Step 1: Load Skills

Read both skills that govern this command:

1. `${CLAUDE_PLUGIN_ROOT}/plan/skills/planning/SKILL.md` — plan file format, task decomposition, context budgets, done signals, naming
2. `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md` — testing principles and coverage gate that the plan's Verification sections must align with

Follow these skills' rules for all subsequent steps.

## Step 2: Verify Prerequisites

1. Verify `prd/PROJECT.md` and `prd/MODULES.md` both exist. If either is missing:

   "Project foundation not found. Run `/m:setup` first to create PROJECT.md and MODULES.md."

   Then stop.

2. Create `.molcajete/plans/` directory if it doesn't exist:
   ```bash
   mkdir -p .molcajete/plans
   ```

## Step 3: Parse Arguments

Parse `$ARGUMENTS` for entity IDs:

- **No arguments** → full PRD scan mode
- **With arguments** → parse tokens matching `FEAT-XXXX`, `UC-XXXX`, or `SC-XXXX` patterns; scope the plan to those entities

If arguments are provided, validate every ID exists in the PRD:
- `FEAT-XXXX` → must appear in `prd/FEATURES.md`
- `UC-XXXX` → must exist as `prd/modules/*/features/*/use-cases/UC-XXXX-*.md`
- `SC-XXXX` → must exist as a scenario heading in some UC file (grep `prd/modules/*/features/*/use-cases/*.md` for `### SC-XXXX`)

If any ID is not found, report which ones are invalid and stop.

## Step 4: Load Project Context

Read project-level files:
- `prd/PROJECT.md` — project description (required)
- `prd/TECH-STACK.md` — technology choices (if exists)
- `prd/ACTORS.md` — system actors (if exists)
- `prd/MODULES.md` — module registry (required)
- `prd/DOMAINS.md` — domain tag registry (if exists)
- `prd/FEATURES.md` — master feature registry

Per-feature files will be loaded in the next step based on scope.

## Step 5: Scan for Plannable Work

### Mode A: With Arguments (explicit scope)

Plan work for exactly the provided IDs — **no status filtering**. The user is explicitly telling you what to work on.

- `FEAT-XXXX` → include all UCs under that feature. Glob `prd/modules/*/features/FEAT-XXXX-*/` to find it, then read `USE-CASES.md` and all UC files in `use-cases/`.
- `UC-XXXX` → include that specific UC. Glob `prd/modules/*/features/*/use-cases/UC-XXXX-*.md` to find it.
- `SC-XXXX` → include the parent UC. Grep `prd/modules/*/features/*/use-cases/*.md` for `### SC-XXXX` to find the UC file, then include the whole UC (scenarios aren't planned individually).

For each in-scope feature, extract the module from the path and also read:
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/REQUIREMENTS.md`
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/ARCHITECTURE.md` (if exists)

### Mode B: No Arguments (full scan)

Find everything that needs implementation:

1. Read `prd/FEATURES.md` for all features across all domains.
2. For each feature, read `prd/modules/{module}/features/FEAT-XXXX-{slug}/USE-CASES.md`.
3. Collect UCs with status `pending` or `dirty` in the USE-CASES.md table.
4. Also scan `prd/FEATURES.md` for features with status `dirty`. For each dirty feature, include **all** its UCs from USE-CASES.md — even those with `implemented` status — since a dirty feature means requirements changed and all UCs may need re-planning.
5. Also include features with status `pending` that have UCs ready.
6. For each in-scope feature, read `REQUIREMENTS.md` and `ARCHITECTURE.md` (if exists).
7. Build the full picture of all pending work.

If nothing plannable is found: tell the user "No unimplemented specs found. All use cases are either already implemented or not yet specified. Use `/m:feature`, `/m:usecase`, or `/m:spec` to author new specs." Then stop.

## Step 6: Log Scope Summary

Log the scope summary as plain text for the user to see, then continue immediately:

- **Features in scope** — list with UC counts
- **Use cases to plan** — list with scenario counts and status
- **Total scenarios** — aggregate count

Do not ask for confirmation or offer to narrow scope.

## Step 7: Generate Task Breakdown

Read all in-scope materials:
- UC files with their inline scenarios
- Feature REQUIREMENTS.md and ARCHITECTURE.md files

If any ARCHITECTURE.md contains a Code Map section with entries, use it to map UC scenarios to implementation files. Include the ARCHITECTURE.md path in each task's Architecture field so build tasks can load it for context.

Read the plan schema — it defines the exact JSON structure you must produce:
```
${CLAUDE_PLUGIN_ROOT}/plan/skills/planning/templates/plan-schema.json
```

Build a JSON object matching this schema. The top-level object has `title`, `generated`, `status`, `scope`, `base_branch`, and `tasks` (array). Decompose into tasks following the planning skill rules:

1. **Behavior-cluster tasks** — each task names one behavior or a small cluster of related behaviors. Do not split into Red/Green/Refactor sub-tasks; task decomposition into test-and-code units is the build agent's responsibility, not the planner's.

2. **Infrastructure tasks** — only when necessary as prerequisites (database setup, test harness, shared middleware). Per the planning skill's Infrastructure Absorption rule, prefer absorbing infrastructure into the first scenario task's sub-tasks rather than emitting it as a standalone top-level task.

3. **Context budget** — estimate each task at ≤ 200K tokens. Consider: source files to read + spec files + implementation work. Split into sub-tasks if over budget (for context only, never for phases).

4. **Task fields** — for each task include all fields from the plan schema:
   - `id`: `T-001`, `T-002`, etc. (flat sequential)
   - `title`: verb-noun describing what gets built
   - `use_case`: the UC-XXXX this task advances
   - `feature`: parent feature ID (FEAT-XXXX)
   - `module`: the module the feature belongs to
   - `architecture`: path to the feature's ARCHITECTURE.md (at `prd/modules/{module}/features/FEAT-XXXX-{slug}/ARCHITECTURE.md`)
   - `intent`: `implement` (this command only emits `implement`)
   - `status`: `pending`
   - `estimated_context`: `~{N}K tokens`
   - `depends_on`: `["T-NNN"]` or `[]`
   - `description`: names the behavior or behaviors to deliver, why, and any constraints. Do NOT include test file paths or assertion lists — the build agent decides those.
   - `files_to_modify`: expected production file paths
   - `sub_tasks`: `null` unless context-budget splitting is needed
   - `summary`: `null`
   - `errors`: `[]`

5. **Plan-level fields** — also populate:
   - `base_branch`: current git branch (run `git branch --show-current`)

   Do **not** add a `bdd_command` field or any test-runner command. The Validator subagent reads project test/coverage commands at build time from `.molcajete/settings.json` `testing` or by convention.

6. **Order by dependency chain** — infrastructure first, data models before APIs, core logic before edge cases, happy-path before error-handling.

## Step 8: Write Plan File

1. Generate the directory name:
   - Timestamp: current time as `YYYYMMDDHHmm`
   - Slug: derived from scope per the planning skill rules (feature name kebab-case, UC name kebab-case, `mixed`, or `full-scan`)
   - Directory: `{YYYYMMDDHHmm}-{slug}`

2. Create the plan directory:
   ```bash
   mkdir -p .molcajete/plans/{YYYYMMDDHHmm}-{slug}
   ```

3. **Write `plan.json` first.** Write the plan JSON to `.molcajete/plans/{YYYYMMDDHHmm}-{slug}/plan.json`. This is the source of truth for `/m:build`.

4. **Derive and write `plan.md` second.** Using the JSON you just wrote plus the PRD context loaded in Steps 4–7 (REQUIREMENTS.md, ARCHITECTURE.md, UC files), render `plan.md` per the planning skill's "Companion `plan.md` (greenfield)" section. Use the skeleton at `${CLAUDE_PLUGIN_ROOT}/plan/skills/planning/templates/plan-template.md`. Write the result to `.molcajete/plans/{YYYYMMDDHHmm}-{slug}/plan.md`. Do not include execution-state fields (`status`, `summary`, `errors`, `estimated_context`, `depends_on`).

## Step 9: Report

Tell the user:

- Plan JSON path and `plan.md` path
- Task count and total estimated context budget
- Features and UCs covered

Suggest next step: "Review `plan.md` for a WYSIWYG preview, then run `/m:build {plan-name} <T-NNN>` to start the test-first build loop."
