---
name: setup
description: >-
  Rules and templates for the /m:setup command. One-shot foundation setup
  from a single project description plus codebase detection. Generates
  PROJECT.md, TECH-STACK.md, ACTORS.md, GLOSSARY.md, MODULES.md,
  DOMAINS.md, FEATURES.md, and .molcajete/settings.json.
---

# Project Setup

`/m:setup` is one-shot: one user description + (when present) a codebase scan, and the model writes the full foundation. No section-by-section interview.

## Composition

From the user's description and the codebase scan, compose:

- **PROJECT.md** — 1–2 paragraph project description.
- **MODULES.md** — physical application layers (one per `apps/*/`, `services/*/`, `packages/*/`, `cmd/*/`, or one root module). Each: ID (kebab-case), Name, Description, Directory.
- **TECH-STACK.md** — per-module Language, Framework, Build, Key libraries, Styling, Testing, Lint/Format; project-level Runtime, Services, Applications, External Services, Repository Structure, Tooling, Environment, Conventions. Leave `Modules.{name}.Testing` blank when detection finds no clear runner — the build loop's Runner Inference handles it.
- **ACTORS.md** — discovered from auth middleware, admin routes, webhook handlers, API key validation, plus any mentioned in the description.
- **DOMAINS.md** — logical concerns (identity, billing, notifications, etc.) inferred from route prefixes, model names, or the description.
- **GLOSSARY.md** — 5 standard terms (Module, Domain Tag, Feature, Use Case, Actor) + 3–5 project-specific terms.
- **FEATURES.md** — one `## {domain}` section per domain, all tables empty.
- **.molcajete/settings.json** — `{"testing": {"threshold": 80}}`. Strip any legacy `bdd` key.

## Codebase Detection (when present)

In one parallel batch, glob and read:

- Module roots: `apps/*/`, `packages/*/`, `services/*/`, `cmd/*/`.
- Manifests in each: `package.json`, `pyproject.toml`/`requirements*.txt`, `go.mod`, `Cargo.toml`, `Gemfile`, `pom.xml`, `build.gradle{,.kts}`.
- Project-level: `docker-compose.yml`, `.github/workflows/*.yml`, `vercel.json`, `netlify.toml`, `biome.json`, `tailwind.config.*`, `prisma/schema.prisma`, `drizzle.config.ts`, `.env*`.
- Grep for SDK imports indicating external services.

Per-module testing tool detection follows `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md` → "Runner Inference". Populate the row when the inference is unambiguous; leave blank otherwise.

## Confirmation Rule

Present the composite foundation in **one** AskUserQuestion. Options: write all files / edit one section / cancel. Do not interview section-by-section.

## Document Generation

Read templates from `./templates/` and write each file in a single parallel batch after confirmation. Global files in `prd/`; per-module directories under `prd/modules/{module}/features/`.

| Document | Template | Location |
|----------|----------|----------|
| PROJECT.md | [PROJECT-template.md](./templates/PROJECT-template.md) | `prd/PROJECT.md` |
| TECH-STACK.md | [TECH-STACK-template.md](./templates/TECH-STACK-template.md) | `prd/TECH-STACK.md` |
| ACTORS.md | [ACTORS-template.md](./templates/ACTORS-template.md) | `prd/ACTORS.md` |
| GLOSSARY.md | [GLOSSARY-template.md](./templates/GLOSSARY-template.md) | `prd/GLOSSARY.md` |
| MODULES.md | [MODULES-template.md](./templates/MODULES-template.md) | `prd/MODULES.md` |
| DOMAINS.md | [DOMAINS-template.md](./templates/DOMAINS-template.md) | `prd/DOMAINS.md` |
| FEATURES.md | [FEATURES-template.md](./templates/FEATURES-template.md) | `prd/FEATURES.md` |

## Regeneration

When `prd/PROJECT.md` already exists, ask once (regenerate vs cancel). On regenerate, run the full one-shot composition again.

## Template Reference

See `./templates/` for the seven template files.
