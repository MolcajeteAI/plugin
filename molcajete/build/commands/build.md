---
description: Implement a single slice — TDD red/green/mutation lifecycle in two phases
model: claude-opus-4-6
argument-hint: "<UC-XXXX-NNN>"
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

# Build Command

You implement a single **slice** by running its two-phase TDD lifecycle. The slice's Markdown file — its frontmatter, Rationale, Contracts (Types / API Surface / Behavior), and Tests (nested bullets) — plus the dependency-slice `provides` signatures and the current contents of any `files.modify` are the only context. There is no plan.json, no UC re-read, no architecture file re-read at build time. Spec already did that work; build consumes its output.

**Do NOT commit code.** The user reviews your output and commits themselves.

**Arguments:** $ARGUMENTS

**All user interaction MUST use the AskUserQuestion tool.** Never ask questions as plain text in your response.

## Step 1: Load Skills

Read in one batch:

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/slicing/SKILL.md` — slice file schema and the contract this command consumes
2. `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md` — runner inference, outer-edge mocking, coverage gate

## Step 2: Verify Prerequisites

1. `prd/PROJECT.md` and `prd/MODULES.md` must exist. If either is missing:

   "Project foundation not found. Run `/m:setup` first."

   Then stop.

2. Ensure `.molcajete/settings.json` exists and contains `testing.threshold`:
   - If the file does not exist, create `.molcajete/` and write `{"testing": {"threshold": 80}}`. Tell the user: "Initialized `.molcajete/settings.json` with default `testing.threshold = 80`. Edit it to change the coverage gate."
   - If the file exists but `testing.threshold` is missing, merge in `testing.threshold = 80` (preserving every other key) and write it back.
   - If `testing.threshold` is already set, use that value.

## Step 3: Parse Arguments

Parse `$ARGUMENTS` for one required token: the slice ID in the format `UC-XXXX-NNN` (e.g., `UC-J10A-003`).

If `$ARGUMENTS` is empty:

1. List available slices by globbing `prd/modules/*/features/*/use-cases/*.slices/*.md` and sorting by ID.
2. Tell the user:

   "Usage: `/m:build <UC-XXXX-NNN>`\n\nAvailable slices:\n{list each slice: id, name, objective, status}"

   Then stop.

Resolve the slice file by globbing `prd/modules/*/features/*/use-cases/*.slices/{UC-XXXX-NNN}-*.md`. If not found:

1. List available slices as above.
2. Tell the user: "Slice '{UC-XXXX-NNN}' not found." with the list.

Then stop.

## Step 4: Load Slice File

1. Read the resolved slice file.
2. Parse the frontmatter (`id`, `name`, `use_case`, `feature`, `objective`, `files.create`, `files.modify`, `depends_on`, `provides`, `entry_type`, `covers`, `last_update`). The slice **must not** declare `test_file` — that field is derived (see Step 5).
3. Capture the body sections: `## Rationale`, `## Contracts` (with `### Types`, `### API Surface`, `### Behavior` subsections), `## Tests` (the nested bullet plan).

## Step 5: Validate Slice

1. **Check dependencies.** For each ID in `depends_on`, glob `prd/modules/*/features/*/use-cases/*.slices/{dep-id}-*.md` to confirm the dependency slice file exists, then check `.molcajete/slices/{dep-id}.json` for `status: "implemented"`. If any dependency is unmet:

   "Slice {id} is blocked. These dependencies are not yet implemented:\n\n{list each unmet dep: id, status}"

   Then stop.

2. **Check file invariants:**
   - For `objective: implement` slices: every path in `files.create` must NOT yet exist; every path in `files.modify` must exist.
   - For `objective: coverage` slices: `files.create` must be empty; every path in `files.modify` must exist.

   On violation, tell the user precisely which invariant failed and stop.

3. **Derive the test file path.** Apply the slicing skill's **Test File Convention** to compute `test_file` from frontmatter + `prd/MODULES.md`:

   ```
   {module.Tests}/features/{feature-dir-name}/use-cases/{uc-dir-name}/{NNN}-{entry-type}-{slice-name}.{test-ext}
   ```

   Where:
   - `{module.Tests}` is the `Tests` column of the slice's module in `prd/MODULES.md`. If the module row has no `Tests` value, halt with: "Module '{module}' has no `Tests` value in `prd/MODULES.md`. Add it (see the setup skill's per-language defaults) and re-run."
   - `{feature-dir-name}` is the slice's parent feature directory name under `prd/modules/{module}/features/` (resolved from the slice file's path on disk).
   - `{uc-dir-name}` is the slice's parent UC directory name under `.../use-cases/` (without the `.slices` suffix).
   - `{NNN}` is the zero-padded sequence number from the slice's `id` (e.g., `001` for `UC-0KTg-001`).
   - `{entry-type}` is the slice's `entry_type` frontmatter value.
   - `{slice-name}` is the slice's frontmatter `name`.
   - `{test-ext}` is the per-runner extension resolved from `prd/TECH-STACK.md` Testing row or runner inference (e.g., `test.ts`, `_test.py`, `_test.go`).

   Validate:
   - The slice's `feature` frontmatter must match the FEAT prefix in `{feature-dir-name}`. If not, halt: "Slice {id} frontmatter `feature: {value}` does not match parent feature directory `{feature-dir-name}`. Fix one or the other and re-run."
   - The slice's `use_case` frontmatter must match the UC prefix in `{uc-dir-name}`. If not, halt with the analogous message.
   - The slice file must not declare `test_file:` in its frontmatter. If it does, halt: "Slice {id} declares `test_file` in frontmatter — this field is derived. Remove it from the frontmatter."
   - The slice must declare `entry_type:` in its frontmatter. If missing, halt: "Slice {id} is missing `entry_type` in frontmatter. Set it to one of the module's `Driving Ports` values from `prd/MODULES.md` (e.g., `http`, `event`, `cron`) and re-run."
   - The slice's `entry_type` value must appear in the module's `Driving Ports` list in `prd/MODULES.md`. If not, halt: "Slice {id} `entry_type: {value}` is not declared in `prd/MODULES.md` for module '{module}'. Add it under the module's `Driving Ports` column (re-running `/m:setup` will detect new driving ports automatically) or change the slice's `entry_type` to a value already listed."
   - The derived path must not collide with any other slice in the same UC. Scan sibling slice files under the same `.slices/` directory and apply the same derivation to each; if two slices resolve to the same canonical path, halt: "Slice {id} and slice {other-id} resolve to the same `test_file`. Rename one of them."

   Cache the derived `test_file` on the in-memory slice for the rest of the build. (The harness's `slice-data.ts` performs the same derivation; this step keeps the interactive command symmetric.)

4. **Present the slice** via AskUserQuestion:

   - Question: "**{id}: {name}**\n\n**Use Case:** {use_case}\n**Objective:** {objective}\n**Entry type (driving port):** {entry_type}\n**Covers:** {covers}\n\n**Files (create):** {files.create}\n**Files (modify):** {files.modify}\n**Depends on:** {depends_on}\n**Test file (derived, materialized at build):** {derived_test_file}\n\nReady to build this slice?"
   - Header: "Build Slice"
   - Options: "Proceed" / "Cancel"

   If "Cancel", stop.

## Step 6: Load Build Payload

Issue all reads in a single parallel batch. The payload is intentionally narrow — slice file content + dependency exports + existing modify files + tech stack — and nothing else. Do NOT re-read REQUIREMENTS.md, ARCHITECTURE.md, the UC file, or any other slice file.

### 6.1 Dependency Exports

For each slice ID in `depends_on`:

1. Read the dependency's slice file to find its `provides` list and `files.create` / `files.modify` paths.
2. For each name in `provides`, `grep` the dependency's source files for the exported identifier and capture the signature (function declaration, type alias, class, or constant declaration). Capture only the export signature line(s), not the full body.

Build a `dependency_exports` view in memory: one entry per dependency slice, listing `{ slice_id, name, signature }` rows. This is what the slice sees of its dependencies — never the full source.

### 6.2 Existing Modify Files

For each path in `files.modify`, read the current contents.

### 6.3 Tech Stack

Determine the module by matching the first file in `files.modify` (or `files.create`) against the `Directory` rows in `prd/TECH-STACK.md`. Read that module's section verbatim — it carries the framework, key libraries, and testing runner.

If no module matches, or the matched module is missing `Framework` / `Key libraries` rows, stop with:

"`prd/TECH-STACK.md` is incomplete for the module containing {first file}. Run `/m:setup` to fill in `Framework` and `Key libraries` for that module."

Resolve the test runner per the testing skill's "Runner Inference". Cache it for this invocation. Resolve test + coverage commands from `.molcajete/settings.json testing.commands.{test,coverage}` when set, otherwise derive from the runner's conventional scoping flag. The touched-files placeholder is `files.create ∪ files.modify ∪ {test_file}`.

## Step 7: Phase 1 — Scaffold

The scaffold phase translates the slice's `## Tests` nested-bullet plan into actual test code in the project's runner. The output goes to the **derived `test_file` path computed in Step 5.3** — never a path declared in the slice frontmatter. **Do not write production code in this phase.**

1. Read the `## Tests` section of the slice file.
2. Map the bullet structure to runner-equivalent grouping:
   - Top-level bullets (typically `- **SC-XXXX:** ...` or `- **FR-XXXX:** ...`) become outermost `describe` blocks. Block names follow the pattern `SC-XXXX: {scenario name}` so the harness can map results back to scenarios.
   - Nested context bullets (`- Given ...`, `- When ...`) become nested `describe` blocks.
   - Leaf bullets (`- Then ...`, `- And ...`) become `it` blocks.
3. For `objective: implement` slices: `it` bodies are intentionally empty (or contain only a single `expect.fail("not implemented")` placeholder when the runner requires it). The initial run must be deterministically RED.
4. For `objective: coverage` slices: `it` bodies contain the full assertions implied by the bullet text against the existing implementation. The initial run must be deterministically GREEN.
5. Add the imports the assertions will need — for `implement` slices these may not yet resolve (the modules don't exist), and that's part of the expected RED state.
6. Write the file at the **derived** `test_file` path. Create parent directories as needed.

## Step 8: Phase 1 Check — Initial Test Run

Run the scoped test command against `slice.test_file` only.

- `objective: implement` — expect RED.
  - GREEN → run the **mutation check** (Step 10). If mutation turns the scaffold RED, the implementation already satisfies the slice; record the outcome and skip Phase 2. If mutation leaves the scaffold GREEN, halt and write to `.molcajete/escalations/{id}.md`: "Scaffold for {id} starts GREEN and survives mutation — the test does not actually test the contract. Re-run `/m:spec` to re-author the Tests section."
  - RED → proceed to Phase 2.
- `objective: coverage` — expect GREEN.
  - GREEN → proceed to Phase 2.
  - RED → halt; write to `.molcajete/escalations/{id}.md`: "Coverage slice {id} scaffold is RED before tests are added — existing implementation appears broken or the scaffold targets the wrong files."

## Step 9: Phase 2 — Implement

The implement phase writes production code (and, for `implement` slices, fills in the test assertion bodies the scaffold left empty).

1. **For `implement` slices:** write production code in its final form to satisfy the slice's Contracts (Types / API Surface / Behavior) and turn the scaffold GREEN. Fill each empty `it` body with concrete assertions as you implement the behavior it covers. Honour `dependency_exports` signatures verbatim.
2. **For `coverage` slices:** add more assertions to the scaffold to close coverage on `files.modify`. Do NOT edit production code unless a seam is genuinely untestable (the testing skill's reactive refactor rule).
3. Run the scoped test + coverage commands.
   - All green + per-file coverage on every touched file ≥ `testing.threshold` → proceed to Step 10.
   - RED → retry up to 3 more times. On retry, the only context you operate with is the **failing test output** plus the slice frontmatter. Do NOT re-read the slice file, dependency exports, or modify files.
   - On the 3rd RED, halt; write to `.molcajete/escalations/{id}.md` with the last test output.

## Step 10: Mutation Check (harness-owned semantics)

The mutation check is a deterministic perturbation: for each file in `files.modify` (and `files.create` if it exists), rewrite every exported function/binding named in `slice.provides` to throw `new Error('MUTANT')` (TS/JS) or the language-appropriate equivalent (`raise NotImplementedError('MUTANT')` for Python, `panic("MUTANT")` for Go, etc.). Save the originals first. Run the scoped test command. Restore originals in a `finally`. Report RED/GREEN.

When the harness runs this command non-interactively, the mutation step is performed by the harness itself (see `molcajete/src/commands/build/mutation.ts`). When you run this command interactively:

- For `implement` slices, run mutation only when the scaffold starts GREEN unexpectedly (Step 8).
- For `coverage` slices, run mutation after Phase 2 — success criterion is **mutation RED**. If mutation leaves the scaffold GREEN, the added tests are vacuous; retry up to 3 more times passing only the mutation report plus the slice frontmatter.

Perform the perturbation via `Edit`/`Write`, run the test command via `Bash`, and restore via `Edit`/`Write`. Wrap in explicit save → mutate → run → restore order, and verify restoration by re-reading the file and comparing to the saved original. **Never leave a file mutated on exit.**

## Step 11: Record Outcome

Write `.molcajete/slices/{id}.json` with:

```json
{
  "id": "{id}",
  "use_case": "{use_case}",
  "feature": "{feature}",
  "objective": "{objective}",
  "status": "implemented",
  "completed_at": "{ISO timestamp}",
  "files_touched": [...],
  "covers": [...],
  "summary": "{one paragraph: what got built / what got covered, key decisions, anything downstream slices should know}"
}
```

This file is the durable per-slice record. The harness aggregates these for UC and feature completion.

## Step 12: Report

Tell the user:

- **Slice** — `{id}: {name}` ({objective})
- **Scenarios covered** — `covers`
- **Files created / modified** — aggregated from `files.create` + `files.modify` (plus the materialized `test_file`)
- **Coverage** — final coverage percentage from the last passing test run
- **Summary** — what got built or covered
- **Slice record** — path to `.molcajete/slices/{id}.json`

Then list the next slices whose `depends_on` is now satisfied by completed slices in the same UC: "Next slices ready:\n{list: id, name}\n\nRun `/m:build {next-id}` to continue."

If every slice in the UC is now implemented, suggest: "All slices for {use_case} complete. The use case is fully built."
