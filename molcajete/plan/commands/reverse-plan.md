---
description: Generate a plan for wiring BDD to existing code (reverse path)
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
  - AskUserQuestion
---

# Reverse Plan Command

You generate plans for wiring BDD step definitions to existing code. You scan for use cases that need BDD coverage, verify Gherkin exists, and produce a **JSON** plan file in `.molcajete/plans/` with a task breakdown that `molcajete build` will execute. The output format is strictly JSON — never markdown. Every task uses `wire-bdd` intent — the application already works, tasks create step definitions that exercise it.

**Scope argument:** $ARGUMENTS

**All user interaction MUST use the AskUserQuestion tool.** Never ask questions as plain text in your response. This keeps you in control of the conversation flow.

## Step 1: Load Skills

Read both skills that govern this command:

1. `${CLAUDE_PLUGIN_ROOT}/plan/skills/planning/SKILL.md` — plan file format, task decomposition, context budgets, done signals, naming
2. `${CLAUDE_PLUGIN_ROOT}/shared/skills/gherkin/SKILL.md` — BDD scaffold context, tagging rules

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
4. Also include features with status `implemented` that have UCs ready.
5. For each in-scope feature, read `REQUIREMENTS.md` and `ARCHITECTURE.md` (if exists).
6. Build the full picture of all pending work.

If nothing plannable is found: tell the user "No use cases need BDD wiring. Use `/m:reverse-feature`, `/m:reverse-usecase`, or `/m:reverse-spec` to extract specs from code first." Then stop.

## Step 6: Verify Gherkin

For each plannable UC:

1. Grep `bdd/features/` for `@UC-XXXX` tag to find the `.feature` file.
2. Verify the `.feature` file exists and contains at least one `Scenario:` or `Scenario Outline:`.
3. Read the feature file to count scenarios and extract step patterns.

Report gaps:
- If Gherkin missing for a UC: "UC-XXXX ({name}) has no Gherkin. Run `/m:scenario UC-XXXX` first."

If **all** UCs are missing Gherkin, stop with the gap report.

If **some** UCs have gaps, report the gaps and ask via AskUserQuestion:
- Question: "{gap report}\n\nWould you like to proceed with a plan covering only the UCs that have Gherkin, or fix the gaps first?"
- Header: "Gherkin Gaps"
- Options: "Proceed with available UCs" / "Cancel — I'll fix the gaps first"

If "Cancel", stop. Otherwise, continue with only the verified UCs.

## Step 7: Collect TEST-ISSUES

For each in-scope UC, check for a sibling testability-concerns file and fold surviving recommendations into the plan. See the planning skill's "Companion `plan.md` (reverse)" section for the full rules.

1. **Discover** — for each UC at `prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}.md`, look for a sibling named `UC-XXXX-{slug}-TEST-ISSUES.md` (same basename + `-TEST-ISSUES.md`). Skip UCs that have no such file.

2. **Parse** — read each TEST-ISSUES file. The format follows `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/templates/UC-TEST-ISSUES-template.md`. Extract each REC's Scenario, Area, Why it might matter, and Category fields.

3. **Filter by Testing Decisions** — for each REC, read the owning feature's `ARCHITECTURE.md`. If it has a `## Testing Decisions` section containing a decision that covers the same area/category, **skip** that REC — the concern is already resolved.

4. **Classify** — for each surviving REC:
   - **Scenario-local** if the REC's `Scenario:` field names a single in-scope `SC-XXXX`.
   - **Global** if the REC lacks a `Scenario:` field, OR the same REC text/area appears in TEST-ISSUES files across ≥2 scoped UCs.

5. **Remember the set** — keep the surviving classified RECs available for Step 9 (JSON fold-in) and Step 11 (MD write decision). If zero RECs survive, note that `plan.md` will not be written in Step 11.


## Step 8: Present Scope Summary

Use AskUserQuestion to show what will be planned:

- Question: Format as a structured summary:
  - **Features in scope** — list with UC counts
  - **Use cases to plan** — list with scenario counts and status
  - **Total scenarios** — aggregate count
  - **Missing Gherkin** (if any were excluded) — list of excluded UCs

- Header: "Plan Scope"
- Options: "Proceed" / "Narrow scope" / "Cancel"

If "Narrow scope": use AskUserQuestion to ask which IDs to exclude, remove them, and re-present. If "Cancel": stop.

## Step 9: Generate Task Breakdown

Read all in-scope materials:
- UC files with their scenarios
- Feature REQUIREMENTS.md and ARCHITECTURE.md files
- Gherkin .feature files for the in-scope UCs
- `bdd/steps/INDEX.md` (if exists) for existing step definitions

If any ARCHITECTURE.md contains a Code Map section with entries, use it to identify the existing implementation files that step definitions need to exercise. Include the ARCHITECTURE.md path in each task's Architecture field so build tasks can load it for context.

Read the plan schema — it defines the exact JSON structure you must produce:
```
${CLAUDE_PLUGIN_ROOT}/plan/skills/planning/templates/plan-schema.json
```

Build a JSON object matching this schema. The top-level object has `title`, `generated`, `status`, `scope`, `base_branch`, `bdd_command`, and `tasks` (array). Decompose into tasks following the planning skill rules:

1. **BDD-aligned tasks** — each task advances at least one Gherkin scenario. Map scenarios to tasks by examining what step definitions need to be written for those assertions to pass.

2. **Infrastructure tasks** — only when necessary as prerequisites (test harness setup, shared step helpers). These tasks have null `scenario` (BDD skipped).

3. **Context budget** — estimate each task at ≤ 200K tokens. Consider: source files to read + spec files + Gherkin + step definition work. Split if over budget.

4. **Task fields** — for each task include all fields from the plan schema:
   - `id`: `T-001`, `T-002`, etc. (flat sequential)
   - `title`: verb-noun describing what step definitions get written
   - `use_case`: the UC-XXXX this task advances
   - `feature`: parent feature ID (FEAT-XXXX)
   - `module`: the module the feature belongs to
   - `architecture`: path to the feature's ARCHITECTURE.md
   - `intent`: `wire-bdd` (reverse plan always uses wire-bdd)
   - `status`: `pending`
   - `estimated_context`: `~{N}K tokens`
   - `scenario`: `"SC-XXXX"` for filtered BDD gate; null for chores (BDD skipped)
   - `depends_on`: `["T-NNN"]` or `[]`
   - `description`: what step definitions to create from scratch, which existing implementation files they exercise, include path to relevant `.feature` file(s), constraints
   - `files_to_modify`: step definition file paths (not application code)
   - `summary`: `null`
   - `errors`: `[]`

   When ARCHITECTURE.md has a Code Map, reference the existing implementation files in each task's description so the build agent knows what code the step definitions should exercise.

5. **Plan-level fields** — also populate:
   - `base_branch`: current git branch (run `git branch --show-current`)
   - `bdd_command`: detect per dispatch skill's BDD Command Detection rules, `null` if not detectable yet

6. **Order by dependency chain** — infrastructure first, shared step helpers before scenario-specific steps, happy-path before error-handling.

7. **Fold TEST-ISSUES into the JSON** — using the classified RECs from Step 7:
   - **Global RECs** → add one sub-task under T-001 per global REC, describing the infrastructure change needed for `molcajete build` to run the scenarios. Sub-task IDs follow `T-001-M`. Absorb infrastructure per the planning skill's "Infrastructure Absorption" rule — no standalone top-level infrastructure task. Append the prerequisite file paths to T-001's `files_to_modify`.
   - **Scenario-local RECs** → append a `Prerequisites:` paragraph to the owning scenario's task `description`. The paragraph lists each REC by ID with its source TEST-ISSUES file path and the required change. Add the prerequisite file paths to the owning task's `files_to_modify`. Only split into a sub-task when the combined work exceeds the 200K context budget.

   This keeps the JSON self-sufficient — `molcajete build` never reads `plan.md`.

## Step 10: Plan Preview

Render the JSON for approval. Also render `plan.md` **only if** at least one REC survived Step 7; otherwise show the JSON only and note that `plan.md` will be skipped.

Use AskUserQuestion:

- Question:
  - Always: show the complete plan JSON in a code block with 2-space indent.
  - Conditionally: if any classified RECs exist from Step 7, also show the rendered `plan.md` content (derived per the planning skill's "Companion `plan.md` (reverse)" section) in a separate fenced markdown block.
  - If no RECs survived, state: "No blocking testability prerequisites detected — `plan.md` will be skipped."
- Header: "Plan Preview"
- Options: "Looks good" / "Edit" / "Cancel"

If "Edit": use AskUserQuestion to collect corrections, regenerate affected tasks (and the derived MD if applicable), and re-preview.
If "Cancel": stop.

## Step 11: Write Plan File

1. Generate the directory name:
   - Timestamp: current time as `YYYYMMDDHHmm`
   - Slug: derived from scope per the planning skill rules (feature name kebab-case, UC name kebab-case, `mixed`, or `full-scan`)
   - Directory: `{YYYYMMDDHHmm}-{slug}`

2. Create the plan directory:
   ```bash
   mkdir -p .molcajete/plans/{YYYYMMDDHHmm}-{slug}
   ```

3. **Write `plan.json` first.** Write the plan JSON to `.molcajete/plans/{YYYYMMDDHHmm}-{slug}/plan.json`. This is the source of truth for `molcajete build`.

4. **Conditionally write `plan.md`.** If any classified RECs survived Step 7, render `plan.md` per the planning skill's "Companion `plan.md` (reverse)" section using the skeleton at `${CLAUDE_PLUGIN_ROOT}/plan/skills/planning/templates/reverse-plan-template.md`, and write it to `.molcajete/plans/{YYYYMMDDHHmm}-{slug}/plan.md`. The MD lists scenarios by ID + short description (never full Gherkin bodies) and details each prerequisite with its source TEST-ISSUES link, category, why it blocks tests, required changes, and the task it maps to. If no RECs survived, **do not** create `plan.md`.

## Step 12: Report

Tell the user:

- Plan JSON path
- `plan.md` path when written; otherwise state "no blocking testability prerequisites detected — `plan.md` skipped"
- Task count and total estimated context budget
- Features and UCs covered
- Any UCs excluded due to missing Gherkin
- TEST-ISSUES summary: count of RECs folded into the plan (global + scenario-local) and count filtered out by Testing Decisions

Suggest next step: "Review the plan file, then run `molcajete build {plan-name}` to start implementation."
