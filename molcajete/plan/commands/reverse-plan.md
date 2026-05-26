---
description: Generate a coverage-recovery plan that adds tests until the project meets its coverage threshold
model: claude-opus-4-6
argument-hint: "[module-name | path | FEAT-XXXX | UC-XXXX ...]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
---

# Reverse Plan Command

You generate **coverage-recovery plans**: tasks that add tests to existing code until the project meets its coverage threshold. You scan the codebase, identify modules and files whose coverage is below the threshold from `.molcajete/settings.json` `testing.threshold`, and emit behavior tasks whose `description` names the uncovered paths. The output is strictly JSON — `/m:build` runs the same Implementer + Validator loop as greenfield plans; the only difference is the descriptions are phrased as "Cover {file}: add tests for {uncovered behavior}", which the dev session reads to know it should add tests rather than implement new production code.

**Scope argument:** $ARGUMENTS

**Do not ask questions or request confirmations.** Run the entire command uninterrupted from start to finish. The developer will review the output files after generation.

## Step 1: Load Skills

Read both skills that govern this command:

1. `${CLAUDE_PLUGIN_ROOT}/plan/skills/planning/SKILL.md` — plan file format, task decomposition, context budgets, done signals, naming
2. `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md` — testing principles and coverage gate

Follow these skills' rules for all subsequent steps.

## Step 2: Verify Prerequisites

1. Verify `prd/PROJECT.md`, `prd/MODULES.md`, and `prd/TECH-STACK.md` exist. If any is missing:

   "Project foundation not found. Run `/m:setup` first."

   Then stop.

2. Verify `.molcajete/settings.json` exists and contains `testing.threshold`. If missing:

   "Testing threshold not configured. Run `/m:setup` to initialize `testing.threshold` in `.molcajete/settings.json`."

   Then stop.

3. Create `.molcajete/plans/` directory if it doesn't exist:
   ```bash
   mkdir -p .molcajete/plans
   ```

## Step 3: Parse Arguments

Parse `$ARGUMENTS`:

- **No arguments** → scan every module listed in `prd/MODULES.md` and `prd/TECH-STACK.md` for coverage gaps
- **Module name** (matches an ID in `prd/MODULES.md`) → scope to that module's directory
- **Path** (matches an existing directory under the working tree) → scope to that directory
- **FEAT-XXXX / UC-XXXX** → resolve to the implementation files via the feature's `ARCHITECTURE.md#Code Map`; scope to those files

If a token does not resolve to any of the above, report it as unknown and stop.

## Step 4: Load Project Context

Read project-level files:
- `prd/PROJECT.md` — project description (required)
- `prd/TECH-STACK.md` — technology choices, required for derived test/coverage commands per module
- `prd/MODULES.md` — module registry (required)
- `prd/FEATURES.md` — feature registry (helps task descriptions reference the right feature when known)

## Step 5: Run Coverage Per Module

For each in-scope module, locate its `Module` section in `prd/TECH-STACK.md` and derive the coverage command:

1. If `.molcajete/settings.json` `testing.commands.coverage` is set, use it (run from the module's `Directory`).
2. Otherwise, derive a conventional coverage command from `Modules.{name}.Testing` (Vitest → `npx vitest run --coverage`, Jest → `npx jest --coverage`, pytest → `pytest --cov`, go test → `go test -cover ./...`, etc.).

If the runner is unknown and no override is set, skip that module and record the skip — do not guess.

Run each module's coverage command. Parse the report to obtain per-file coverage percentages and a list of uncovered branches / line ranges. Aggregate into a structured map:

```
{
  module-name: {
    directory,
    threshold,
    files: [
      { path, coverage_pct, gaps: [ { kind: "branch" | "line", description, line_range } ] }
    ]
  }
}
```

If a module's coverage command fails to run (no test command, no test files yet), record the failure and continue.

## Step 6: Identify Coverage Gaps

For each module, keep only files whose coverage is below the module's threshold (default: `.molcajete/settings.json` `testing.threshold`, falling back to 80). Group gaps into **behavior clusters** per file — adjacent or thematically related uncovered branches that the build agent can reasonably address as a single task.

If no module has gaps below threshold, tell the user "All in-scope modules already meet the coverage threshold; no coverage-recovery tasks needed." Then stop.

## Step 7: Log Scope Summary

Log the scope summary as plain text:

- **Modules scanned** — list with current coverage percentage and threshold
- **Files needing coverage** — list per module, with coverage percentage and number of uncovered gap clusters
- **Modules skipped** — list with the reason (no runner, command failed, etc.)

Do not ask for confirmation or offer to narrow scope.

## Step 8: Generate Task Breakdown

Read the plan schema:
```
${CLAUDE_PLUGIN_ROOT}/plan/skills/planning/templates/plan-schema.json
```

Build a JSON object matching this schema. For each file with coverage gaps, emit one task (or more, if context-budget splitting is required):

1. **Task shape:**
   - `id`: `T-001`, `T-002`, etc. (flat sequential)
   - `title`: `Cover {file-relative-path}`
   - `use_case`: when the file is mapped to a UC via some feature's `ARCHITECTURE.md#Code Map`, set this; otherwise `null`.
   - `feature`: same — set when the file is mapped via a feature's Code Map, otherwise `null`.
   - `module`: the module ID containing the file
   - `architecture`: path to the feature's `ARCHITECTURE.md` when known, otherwise `null`.
   - `status`: `pending`
   - `estimated_context`: `~{N}K tokens`
   - `depends_on`: `[]` (coverage tasks are typically independent; add dependencies only when one cover task introduces a shared test harness that another reuses)
   - `description`: names the file under test, the current coverage percentage, and the uncovered behaviors or branches to target. Do not enumerate test file paths or assertion lists — the build agent decides those. Example: "Add tests for `src/auth/refresh.ts` (currently 42%). Uncovered behaviors: expired refresh token rejection, replay-protection failure path, network-error retry."
   - `files_to_modify`: the production file(s) under test. Test files are not enumerated; the Implementer chooses placement per the module's existing test conventions.
   - `sub_tasks`: `null` unless context-budget splitting is needed
   - `summary`: `null`
   - `errors`: `[]`

2. **Plan-level fields:**
   - `base_branch`: current git branch (`git branch --show-current`)
   - `title`: `Coverage Recovery — {scope summary}`
   - `scope`: the original argument tokens (or `["full-scan"]` if none)

3. **Order tasks** by module, then by lowest coverage first within each module. Files closest to threshold are not necessarily easiest, but lowest-coverage files generally have the most impactful gaps.

## Step 9: Write Plan File

1. Generate the directory name:
   - Timestamp: current time as `YYYYMMDDHHmm`
   - Slug: `coverage-{module-name}` (single module), `coverage-mixed` (multiple modules), or `coverage-full-scan`
   - Directory: `{YYYYMMDDHHmm}-{slug}`

2. Create the plan directory:
   ```bash
   mkdir -p .molcajete/plans/{YYYYMMDDHHmm}-{slug}
   ```

3. **Write `plan.json` first.** Write the plan JSON to `.molcajete/plans/{YYYYMMDDHHmm}-{slug}/plan.json`. This is the source of truth for `/m:build`.

4. **Write `plan.md` second.** Render `plan.md` per the planning skill's "Companion `plan.md` (reverse / coverage-recovery)" section. Use the skeleton at `${CLAUDE_PLUGIN_ROOT}/plan/skills/planning/templates/reverse-plan-template.md`. Structure: header, modules with current coverage and threshold, behavior tasks per file with gap clusters, coverage gate in Verification.

## Step 10: Report

Tell the user:

- Plan JSON path and `plan.md` path
- Task count and total estimated context budget
- Modules covered with current coverage and threshold
- Any modules skipped and why

Suggest next step: "Review `plan.md`, then run `/m:build {plan-name} <T-NNN>` to start adding tests. The same Implementer + Validator loop runs on `cover` tasks; tasks finish when the file's gaps are closed and the project coverage gate passes."
