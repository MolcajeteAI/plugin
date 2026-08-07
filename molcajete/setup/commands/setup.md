---
description: Initialize project foundation in one shot — describe the project once, all 7 spec files written from that
model: claude-sonnet-5
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# Set Up Project Foundation

One AskUserQuestion: the user describes the project. From that single answer, write `specs/PROJECT.md`, `specs/TECH-STACK.md`, `specs/ACTORS.md`, `specs/GLOSSARY.md`, `specs/MODULES.md`, `specs/DOMAINS.md`, `specs/FEATURES.md`, and `.molcajete/settings.json`. Detect everything else from the codebase or the description. **Use AskUserQuestion only for the description and the final confirmation** — no multi-stage interview.

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

**Writing style:** every document you write and every message you print uses Simplified Technical English. Every one carries only what its reader needs. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/shared/skills/output-economy/SKILL.md` before writing.

## Step 1: Load Skill

Read `${CLAUDE_PLUGIN_ROOT}/setup/skills/setup/SKILL.md` for templates and rules.

## Step 2: Regeneration Check

If `specs/PROJECT.md` already exists, ask:

- Brief: list the foundation files that already exist and when they were last modified, so the user
  knows what is at stake. State plainly that "Regenerate all" overwrites local edits. Recommend
  "Update".
- Question: "A foundation already exists here. How should I proceed?"
- Header: "Setup mode"
- Options: "Update" / "Regenerate all" / "Cancel"

  - "Update" — keep foundation content; detect what the plugin now produces that the host lacks; report and apply only what you approve.
  - "Regenerate all" — full overwrite. Loses any local edits to foundation files.
  - "Cancel" — stop, no changes.

On **Cancel**, stop. On **Regenerate all**, continue to Step 7 (the existing flow). On **Update (detect drift and patch)**, branch to Steps 3–6. Do not run Steps 7–14 — update mode is its own complete flow.

## Step 3: Detect Drift

Walk the **Drift Catalog** in the skill loaded in Step 1: for each entry, run its **Detection** rule against the host and collect findings.

For each finding, record:

- `check-id` — the catalog entry's ID
- `artifact` — the host path or block name
- `category` — `NEW ARTIFACTS` / `SCHEMA GAPS` / `CONTENT DRIFT` (per the catalog)
- `summary` — one-line description suitable for the report

Findings that need per-module expansion (e.g., `tech-stack-running-tests` checks every module) produce one finding per affected module.

If the collected findings list is empty, tell the user:

> No updates needed. Setup is current with the plugin defaults.

Then stop.

## Step 4: Report and Confirm

Print the categorized report:

```
Drift detected against current plugin defaults:

NEW ARTIFACTS
- {summary for each NEW ARTIFACTS finding}

SCHEMA GAPS
- {summary for each SCHEMA GAPS finding}

CONTENT DRIFT
- {summary for each CONTENT DRIFT finding}
```

Omit any category that has zero findings. That report is the brief for the next question — it
already follows the two-move rule. Add a recommendation and the escape-hatch line, then ask:

- Question: "Apply these updates? Commit local changes first if you want a clean revert."
- Header: "Update"
- Options: "Apply all" / "Apply selected" / "Skip"

  - "Apply all" — apply every finding's fix action.
  - "Apply selected" — pick which fixes to apply per category (Step 5).
  - "Skip" — exit update mode without changes.

On **Skip**, stop. On **Apply all**, mark every finding as `selected` and skip Step 5.

## Step 5: Apply Selected

For each category that has findings, issue a multi-select question:

- Brief: for that category, print a Markdown table of its findings — the `summary`, the file it
  touches, and what the fix action will do. This is what the user selects from; the option labels
  are only handles.
- Question: "Which {category} fixes should I apply?"
- Header: "Artifacts" / "Schema gaps" / "Drift" (12 characters maximum)
- Options: one per finding in that category, labelled with a short handle from its `summary`
- multiSelect: true

When a category has more than 4 findings, list every one in the brief, then chain AskUserQuestion calls (4 options each) until the user has reviewed all of them. Mark only the chosen findings as `selected`.

## Step 6: Apply Updates and Report

For each finding marked `selected`, execute its catalog entry's **Fix** action verbatim, preserving every other line in the touched file. The steps those actions name are this file's Step 7 (stack detection), Step 11 (foundation write), Step 12 (principles file), and Step 13 (CLAUDE.md block).

For each finding, record one of: `Applied`, `Skipped (user declined per-file prompt)`, `Failed: {reason}`.

After all fixes, print the per-finding result:

```
Update complete:

- {finding.summary} — Applied
- {finding.summary} — Skipped (user declined per-file prompt)
- {finding.summary} — Failed: {reason}
```

End with the standard hand-off:

> Next: review the changes, commit when satisfied. If `/m:plan` or `/m:build` were planning runs, re-run them so they pick up any new principles or schema additions.

## Step 7: Detect Existing Stack (parallel)

Run the skill's **Codebase Detection** scan in a single parallel batch. On top of what that section covers, detect for each module the **test command** and **coverage command** from the manifest's scripts (e.g., `package.json scripts.test` / `scripts.coverage`, `pyproject.toml [tool.pytest.ini_options]`, `Makefile` targets, `go test ./...` conventional for Go).

If no codebase exists, skip this step — the project description from Step 8 is the only source.

## Step 8: One Description

This one collects free-form input, so the brief is short — it exists to tell the user what a good
answer contains:

- Brief: say what you already detected from the codebase scan, so the user does not repeat it. Then
  ask for what the scan cannot know, with examples: "we'll use AWS SES for email", "patient data is
  PHI". Note that the answer is typed into `Other`.
- Question: "Describe the project in 2-4 sentences: what it does, who uses it, and what problem it solves."
- Header: "Project"

Optionally include scoped follow-ups in the same AskUserQuestion call (up to 4) only if the project type genuinely needs disambiguation — for example, in a multi-app monorepo: "Which module is the primary user-facing one?" Do NOT ask about actors, domains, modules, or test runners — infer those.

## Step 9: Compose

Combine the description (Step 8) and the codebase findings (Step 7) into a single mental model, and resolve every document per the skill's **Composition** section. Two TECH-STACK fields come only from Step 7's detection:

- **`Running tests`** — the exact command to run the tests for the module. Required when the module ships testable code.
- **`Coverage`** — the exact coverage command + where to read stats. If the module does not expose coverage stats, write `not available` — `/m:build` will estimate against the 80% floor.

## Step 10: Present Composite for Confirmation

Present the composed foundation as a brief, then ask:

- Brief: print the full composed foundation as Markdown — a one-sentence project summary, a table
  of modules (directory, language, framework, runner, running-tests, coverage), then lists of
  services with types, external services, actors with roles, and domains. Name the 8 files that
  will be written. Recommend "Write all files". Close with the escape-hatch line.
- Question: "Write the foundation files now?"
- Header: "Foundation"
- Options: "Write all files" / "Edit one section" / "Cancel"

If "Edit one section", apply the user's edit and re-present.

## Step 11: Write Foundation Files

In a single parallel batch:

```bash
mkdir -p specs .molcajete .claude/rules
```

Per module: `mkdir -p specs/features/{module}`. Every project — single- or multi-module — gets a per-module folder under `specs/features/`.

Write each foundation file from its template per the skill's **Document Generation** table. For TECH-STACK.md specifically: populate **Running tests** and **Coverage** for every module that ships testable code, using the commands detected in Step 7 (or marked `not available` when the project does not provide a coverage collector).

Write `.molcajete/settings.json` as `{"testing": {"threshold": 80}}` if it doesn't exist; preserve existing keys when it does.

## Step 12: Write Engineering Principles File

The host project receives a local copy of the engineering principles at `.claude/rules/principles.md`. This is the operative version that `/m:plan` and `/m:build` read; the team can edit it to adapt principles to their context.

Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md` and strip its YAML frontmatter (everything between the leading `---` and the closing `---`, plus the closing line itself), keeping the body verbatim from the `# Engineering Principles` heading on.

**If `.claude/rules/principles.md` does not exist**, write the stripped body there. **If it already exists**, ask via AskUserQuestion:

- Brief: name the existing file and say it may carry team edits. State that regenerating replaces it
  wholesale with the plugin's current version. Recommend "Keep existing".
- Question: "Engineering principles already exist. Keep them or regenerate?"
- Header: "Principles"
- Options: "Keep existing" / "Regenerate"

On "Keep existing", do nothing. On "Regenerate", overwrite with the stripped body.

## Step 13: Inject CLAUDE.md Fenced Block

The host project's `CLAUDE.md` carries a short, always-loaded summary of the engineering principles plus a pointer to the full file, fenced by sentinel markers so re-runs are idempotent. The block:

```
<!-- molcajete:principles:start -->
## Engineering Principles (Molcajete)

Trust comes from tests, not code shape. Code can change; behavior is the contract.

- Integration tests are the only test type Molcajete generates. Every UC and feature is backed by integration tests, no exceptions. Unit tests, if the team wants them for algorithmic code, live outside Molcajete's lifecycle and are not counted toward the coverage floor.
- Hexagonal architecture: drive tests through driver ports with the real internal stack; mock only the outer-edge driven ports.
- Dependency injection makes the outer edge swappable at test time.
- 80% coverage floor on touched files (configurable via `.molcajete/settings.json testing.threshold`).
- Small functions, clear module boundaries, no god files. Refactor to reuse; never duplicate.
- Principles are technology-agnostic. The stack is recorded in `specs/TECH-STACK.md`.
- Write every spec, plan, comment, and report in Simplified Technical English (ASD-STE100): one meaning per word, active voice, simple tenses, one instruction per sentence.
- Carry what the reader needs for their next action, then stop. Never drop a fact to meet a budget — move it or split it instead.

See `.claude/rules/principles.md` for full text and rationale. Re-read it before any architecture decision, test-scope decision, or refactor.
<!-- molcajete:principles:end -->
```

Inject:

1. **If `CLAUDE.md` does not exist at the host root**, create it with just the block as its contents.
2. **If `CLAUDE.md` exists and contains both sentinel markers**, replace everything between them (inclusive of the markers themselves) with the new block. Do not touch any content outside the markers.
3. **If `CLAUDE.md` exists and does not contain the markers**, append the block to the end of the file, preceded by a blank line.

The injection is silent — no user prompt; the block is plugin-owned metadata that always reflects current defaults.

## Step 14: Report

Tell the user what was written and what to do next:

> Created `specs/PROJECT.md`, `specs/TECH-STACK.md`, `specs/ACTORS.md`, `specs/GLOSSARY.md`, `specs/MODULES.md`, `specs/DOMAINS.md`, `specs/FEATURES.md`, `.molcajete/settings.json`, `.claude/rules/principles.md`, and updated `CLAUDE.md` with the Molcajete principles block. The **Running tests** and **Coverage** rows in TECH-STACK.md were filled where I could detect them; verify them before running `/m:build`. The Testing framework field was filled where detectable; the build loop infers the rest from manifests at run time. Engineering principles are operative immediately — `/m:plan` and `/m:build` will read `.claude/rules/principles.md`; edit it to adapt principles to your project.
>
> Next: `/m:spec "describe a feature"` to add your first feature, then `/m:plan <UC-XXXX>` followed by `/m:build <plan-id>` to execute.
