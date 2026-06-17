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
- Question: "Foundation already exists. Regenerate from scratch (loses any edits)?"
- Header: "Setup Mode"
- Options: "Cancel" / "Regenerate all"

On "Cancel", stop. On "Regenerate all", continue.

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

## Step 7: Write Files

In a single parallel batch:

```bash
mkdir -p specs .molcajete
```

Per module: `mkdir -p specs/modules/{module}/features`.

Read templates from `${CLAUDE_PLUGIN_ROOT}/setup/skills/setup/templates/` (PROJECT, TECH-STACK, ACTORS, GLOSSARY, MODULES, DOMAINS, FEATURES) and write each file under `specs/`. For TECH-STACK.md specifically: populate **Running tests** and **Coverage** for every module that ships testable code, using the commands detected in Step 3 (or marked `not available` when the project does not provide a coverage collector).

Write `.molcajete/settings.json` as `{"testing": {"threshold": 80}}` if it doesn't exist; preserve existing keys when it does.

## Step 8: Report

Tell the user what was written and what to do next:

> Created `specs/PROJECT.md`, `specs/TECH-STACK.md`, `specs/ACTORS.md`, `specs/GLOSSARY.md`, `specs/MODULES.md`, `specs/DOMAINS.md`, `specs/FEATURES.md`, `.molcajete/settings.json`. The **Running tests** and **Coverage** rows in TECH-STACK.md were filled where I could detect them; verify them before running `/m:build`. The Testing framework field was filled where detectable; the build loop infers the rest from manifests at run time.
>
> Next: `/m:spec "describe a feature"` to add your first feature, then `/m:plan <UC-XXXX>` followed by `/m:build <plan-id> T-001` to execute.
