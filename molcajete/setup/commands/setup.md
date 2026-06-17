---
description: Initialize project foundation in one shot — describe the project once, all 7 spec files written from that
model: claude-opus-4-6
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

# Set Up Project Foundation

One AskUserQuestion: the user describes the project. From that single answer, write `specs/PROJECT.md`, `specs/TECH-STACK.md`, `specs/ACTORS.md`, `specs/GLOSSARY.md`, `specs/MODULES.md`, `specs/DOMAINS.md`, `specs/FEATURES.md`, and `.molcajete/settings.json`. Detect everything else from the codebase or the description.

**Use AskUserQuestion only for the description and the final confirmation.** No multi-stage interview.

## Step 1: Load Skill

Read `${CLAUDE_PLUGIN_ROOT}/setup/skills/setup/SKILL.md` for templates and rules.

## Step 2: Regeneration Check

If `specs/PROJECT.md` already exists, ask via AskUserQuestion:
- Question: "Foundation already exists. What would you like to do?"
- Header: "Setup Mode"
- Options:
  - "Cancel" — stop, no changes.
  - "Regenerate all" — full overwrite. Loses any local edits to foundation files.
  - "Update (detect drift and patch)" — keep foundation content; detect what the plugin now produces that the host lacks; report and apply only what you approve.

On **Cancel**, stop. On **Regenerate all**, continue to Step 3 (the existing flow). On **Update (detect drift and patch)**, branch to Steps 2u → 2v → 2w → 2x. Do not run Steps 3–8 — update mode is its own complete flow.

## Step 2u: Detect Drift

Update mode walks the **Drift Catalog** in `${CLAUDE_PLUGIN_ROOT}/setup/skills/setup/SKILL.md` (loaded in Step 1). The catalog enumerates every drift check the plugin knows about; for each entry, run the **Detection** rule against the host and collect findings.

For each finding, record:

- `check-id` — the catalog entry's ID
- `artifact` — the host path or block name
- `category` — `NEW ARTIFACTS` / `SCHEMA GAPS` / `CONTENT DRIFT` (per the catalog)
- `summary` — one-line description suitable for the report

Findings that need per-module expansion (e.g., `tech-stack-running-tests` checks every module) produce one finding per affected module.

If the collected findings list is empty, tell the user:

> No updates needed. Setup is current with the plugin defaults.

Stop. Do not proceed to Step 2v.

## Step 2v: Report and Confirm

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

Omit any category that has zero findings. Then ask via AskUserQuestion:

- Question: "Apply updates? You may want to commit local changes before proceeding."
- Header: "Update"
- Options:
  - "Apply all" — apply every finding's fix action.
  - "Apply selected" — pick which fixes to apply per category (Step 2w).
  - "Skip" — exit update mode without changes.

On **Skip**, stop. On **Apply all**, mark every finding as `selected` and go to Step 2x. On **Apply selected**, go to Step 2w.

## Step 2w: Apply Selected

For each category that has findings, issue a multi-select AskUserQuestion:

- Question: "Pick which {category} fixes to apply:"
- Header: short category name (e.g., "New Artifacts", "Schema Gaps", "Content Drift")
- Options: one per finding in that category, labelled with the `summary` from Step 2u
- `multiSelect: true`

When a category has more than 4 findings, chain AskUserQuestion calls (4 options each) until the user has reviewed every finding in that category. Mark only the chosen findings as `selected`. Then proceed to Step 2x.

## Step 2x: Apply Updates and Report

For each finding marked `selected`, execute the catalog entry's **Fix** action:

- **`principles-host-file`** → Step 7a logic. When the file exists but is stale, follow Step 7a's existing per-file AskUserQuestion ("Keep existing / Regenerate from plugin skill"); update mode does not force overwrite of host content.
- **`principles-claude-md-block`** → Step 7b logic. Always idempotent-replaced; content outside markers untouched.
- **`tech-stack-running-tests` / `tech-stack-coverage`** → For each affected module, re-run the manifest-scan portion of Step 3 to derive the command. When detection finds nothing for a coverage field, write `not available`. Insert the line at the canonical position per the catalog. Preserve every other line in the file.
- **`settings-testing-threshold`** → Read `.molcajete/settings.json` as JSON, merge in `testing.threshold = 80` (preserve every other key and nested value), write back.
- **`dot-claude-rules-dir`** → `mkdir -p .claude/rules`.

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

## Step 3: Detect Existing Stack (parallel)

In a single parallel batch:

- Glob common module roots (`apps/*/`, `packages/*/`, `services/*/`, `cmd/*/`) and read manifests (`package.json`, `pyproject.toml`/`requirements*.txt`, `go.mod`, `Cargo.toml`, `Gemfile`, `pom.xml`, `build.gradle{,.kts}`) when found.
- Read `docker-compose.yml`, `.github/workflows/*.yml`, `vercel.json`, `netlify.toml`, `biome.json`, `.eslintrc*`, `tailwind.config.*`, `prisma/schema.prisma`, `drizzle.config.ts` if present.
- Grep for SDK imports indicating external services (Stripe, OpenRouter, Twilio, AWS SDK, etc.).
- For each module, attempt to detect the **test command** and **coverage command** from the manifest's scripts (e.g., `package.json scripts.test` / `scripts.coverage`, `pyproject.toml [tool.pytest.ini_options]`, `Makefile` targets, `go test ./...` conventional for Go).

From these, infer: modules (with directory + language + framework + key libraries + test runner via the testing skill's Runner Inference + lint/format tools + running-tests command + coverage command), services (databases, caches, queues, hosting, CI/CD), external services, runtime (Docker Compose vs host-native), repository structure (mono vs multi), env file location, and starter actors (from auth middleware, admin routes, webhook handlers, etc.).

If no codebase exists, skip this step — the project description from Step 4 is the only source.

## Step 4: One Description

Use AskUserQuestion:
- Question: "Describe the project in 2–4 sentences: what it does, who uses it, what problem it solves, and any tech-stack details the codebase scan wouldn't reveal (e.g., 'we'll use AWS SES for email', 'patient data is PHI'). I'll write the foundation documents from this."
- Header: "Project Description"

Optionally include scoped follow-ups in the same AskUserQuestion call (up to 4) only if the project type genuinely needs disambiguation — for example, in a multi-app monorepo: "Which module is the primary user-facing one?" Do NOT ask about actors, domains, modules, or test runners — infer those.

## Step 5: Compose

Combine the description (Step 4) and the codebase findings (Step 3) into a single mental model. Resolve:

- **Project description** — 1–2 paragraphs (PROJECT.md).
- **Modules** — from directory structure, or single-module if root-level project. Each gets ID, name, description, directory.
- **Tech stack per module** — from manifests; populate `Modules.{name}` rows including:
  - `Testing` (framework — when detection found a clear runner; otherwise leave blank for Runner Inference at build time).
  - **`Running tests`** — the exact command to run the tests for the module. Required when the module ships testable code.
  - **`Coverage`** — the exact coverage command + where to read stats. If the module does not expose coverage stats, write `not available` — `/m:build` will estimate against the 80% floor.
  - Plus Services, Applications, External Services, Repository Structure, Tooling, Environment, Conventions sections from findings.
- **Actors** — from auth middleware, admin routes, API key handlers, webhook receivers in the code, plus any mentioned in the description. Each row: Actor / Role / Description / Constraints.
- **Domains** — logical business concerns (identity, billing, notifications, etc.) inferred from route prefixes, directory names, model names, or the description.
- **Glossary** — 5 standard terms (Module, Domain Tag, Feature, Use Case, Actor) + 3–5 project-specific terms (the database name, the primary framework, domain language from the description).

## Step 6: Present Composite for Confirmation

Use one AskUserQuestion with the full composed foundation as the question text:

- Question: "Here's the composed foundation I'll write:\n\n**Project:** {1-sentence summary}\n**Modules:** {list with directories}\n**Tech stack:** {one line per module: language + framework + runner + running-tests + coverage}\n**Services:** {names + types}\n**External Services:** {names}\n**Actors:** {list with roles}\n**Domains:** {list}\n\nWrite all 7 spec files + `.molcajete/settings.json` now?"
- Header: "Foundation Ready"
- Options: "Write all files" / "Edit one section" (user specifies via Other) / "Cancel"

If "Edit one section", apply the user's edit and re-present.

## Step 7: Write Foundation Files

In a single parallel batch:

```bash
mkdir -p specs .molcajete .claude/rules
```

Per module: `mkdir -p specs/modules/{module}/features`.

Read templates from `${CLAUDE_PLUGIN_ROOT}/setup/skills/setup/templates/` (PROJECT, TECH-STACK, ACTORS, GLOSSARY, MODULES, DOMAINS, FEATURES) and write each file under `specs/`. For TECH-STACK.md specifically: populate **Running tests** and **Coverage** for every module that ships testable code, using the commands detected in Step 3 (or marked `not available` when the project does not provide a coverage collector).

Write `.molcajete/settings.json` as `{"testing": {"threshold": 80}}` if it doesn't exist; preserve existing keys when it does.

## Step 7a: Write Engineering Principles File

The host project receives a local copy of the engineering principles at `.claude/rules/principles.md`. This is the operative version that `/m:plan` and `/m:build` read; the team can edit it to adapt principles to their context.

1. Read the plugin skill: `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md`.
2. Strip the YAML frontmatter (everything between the leading `---` and the closing `---`, plus the closing line itself). Keep the body verbatim, starting at the `# Engineering Principles` heading.
3. **If `.claude/rules/principles.md` does not exist**, write the stripped body there.
4. **If `.claude/rules/principles.md` already exists**, ask via AskUserQuestion:
   - Question: "Engineering principles already exist at `.claude/rules/principles.md`. Keep existing (preserves team edits) or regenerate from the plugin skill?"
   - Header: "Principles"
   - Options: "Keep existing" (default) / "Regenerate from plugin skill"
   - On "Keep existing", do nothing.
   - On "Regenerate from plugin skill", overwrite with the stripped body.

## Step 7b: Inject CLAUDE.md Fenced Block

The host project's `CLAUDE.md` carries a short, always-loaded summary of the engineering principles plus a pointer to the full file. The block uses sentinel markers so re-runs are idempotent.

Compute the block:

```
<!-- molcajete:principles:start -->
## Engineering Principles (Molcajete)

Trust comes from tests, not code shape. Code can change; behavior is the contract.

- Integration tests are the trust contract. Unit tests only for heavy algorithmic logic.
- Hexagonal architecture: drive tests through driver ports with the real internal stack; mock only the outer-edge driven ports.
- Dependency injection makes the outer edge swappable at test time.
- 80% coverage floor on touched files (configurable via `.molcajete/settings.json testing.threshold`).
- Small functions, clear module boundaries, no god files. Refactor to reuse; never duplicate.
- Principles are technology-agnostic. The stack is recorded in `specs/TECH-STACK.md`.

See `.claude/rules/principles.md` for full text and rationale. Re-read it before any architecture decision, test-scope decision, or refactor.
<!-- molcajete:principles:end -->
```

Inject:

1. **If `CLAUDE.md` does not exist at the host root**, create it with just the block as its contents.
2. **If `CLAUDE.md` exists and contains both sentinel markers**, replace everything between them (inclusive of the markers themselves) with the new block. Do not touch any content outside the markers.
3. **If `CLAUDE.md` exists and does not contain the markers**, append the block to the end of the file, preceded by a blank line.

The injection is silent — no user prompt. The block is metadata that should always reflect the current plugin defaults.

## Step 8: Report

Tell the user what was written and what to do next:

> Created `specs/PROJECT.md`, `specs/TECH-STACK.md`, `specs/ACTORS.md`, `specs/GLOSSARY.md`, `specs/MODULES.md`, `specs/DOMAINS.md`, `specs/FEATURES.md`, `.molcajete/settings.json`, `.claude/rules/principles.md`, and updated `CLAUDE.md` with the Molcajete principles block. The **Running tests** and **Coverage** rows in TECH-STACK.md were filled where I could detect them; verify them before running `/m:build`. The Testing framework field was filled where detectable; the build loop infers the rest from manifests at run time. Engineering principles are operative immediately — `/m:plan` and `/m:build` will read `.claude/rules/principles.md`; edit it to adapt principles to your project.
>
> Next: `/m:spec "describe a feature"` to add your first feature, then `/m:plan <UC-XXXX>` followed by `/m:build <plan-id> T-001` to execute.
