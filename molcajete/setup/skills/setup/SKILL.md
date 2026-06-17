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
- **MODULES.md** — physical application layers (one per `apps/*/`, `services/*/`, `packages/*/`, `cmd/*/`, or one root module). Each: ID (kebab-case), Name, Description, Directory, Tests, Driving Ports. The `Tests` column is the per-module root for integration/component test files; see the "Tests Column" rule below for per-language defaults. The `Driving Ports` column lists the kinds of entry points the module exposes; see the "Driving Ports Column" rule below for detection.
- **TECH-STACK.md** — per-module Language, Framework, Build, Key libraries, Styling, Testing, Lint/Format; project-level Runtime, Services, Applications, External Services, Repository Structure, Tooling, Environment, Conventions. Leave `Modules.{name}.Testing` blank when detection finds no clear runner — the build loop's Runner Inference handles it.
- **ACTORS.md** — discovered from auth middleware, admin routes, webhook handlers, API key validation, plus any mentioned in the description.
- **DOMAINS.md** — logical concerns (identity, billing, notifications, etc.) inferred from route prefixes, model names, or the description.
- **GLOSSARY.md** — 5 standard terms (Module, Domain Tag, Feature, Use Case, Actor) + 3–5 project-specific terms.
- **FEATURES.md** — one `## {domain}` section per domain, all tables empty.
- **.molcajete/settings.json** — `{"testing": {"threshold": 80}}`.

## Codebase Detection (when present)

In one parallel batch, glob and read:

- Module roots: `apps/*/`, `packages/*/`, `services/*/`, `cmd/*/`.
- Manifests in each: `package.json`, `pyproject.toml`/`requirements*.txt`, `go.mod`, `Cargo.toml`, `Gemfile`, `pom.xml`, `build.gradle{,.kts}`.
- Project-level: `docker-compose.yml`, `.github/workflows/*.yml`, `vercel.json`, `netlify.toml`, `biome.json`, `tailwind.config.*`, `prisma/schema.prisma`, `drizzle.config.ts`, `.env*`.
- Grep for SDK imports indicating external services.

Per-module testing tool detection follows `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md` → "Runner Inference". Populate the row when the inference is unambiguous; leave blank otherwise.

## Tests Column (MODULES.md)

Every module gets a `Tests` value at setup time. It is the per-module root directory under which integration/component test files live (slice test files are derived from this root plus the slice's feature/UC dirs — see the slicing skill's "Test File Convention").

Always per-module, derived from `{module.Directory}` using a language-aware default. Pick the row that matches the module's primary language:

| Language / framework | `Tests` default | Notes |
|----------------------|-----------------|-------|
| TypeScript / JavaScript | `{module.Directory}/tests` | Works with Vitest, Jest, Mocha; runners discover the directory |
| Python | `{module.Directory}/tests` | pytest convention |
| Java / Maven | `{module.Directory}/src/test/java` | Maven Surefire convention |
| Java / Gradle | `{module.Directory}/src/test/java` | Same — Gradle follows Maven layout by default |
| Ruby / RSpec | `{module.Directory}/spec` | RSpec discovers `spec/**` automatically |
| Rust | `{module.Directory}/tests` | Cargo integration test convention |
| Go | `{module.Directory}` | Co-located convention; `_test.go` suffix discriminates test files |
| Other | `{module.Directory}/tests` | Sensible fallback unless the runner requires otherwise |

The default is a starting point. The user may override per module after setup — for example, monorepos may prefer `packages/{module}/tests`, and projects that vendor a `test/` directory at the repo root may centralize. The slice derivation function always reads `MODULES.md` at slice-load time, so changing a `Tests` value flows through every subsequent build.

## Driving Ports Column (MODULES.md)

Every module gets a `Driving Ports` value at setup time — a comma-separated list of kebab-case identifiers naming the kinds of entry points the module exposes. These identifiers become the per-slice `entry_type` taxonomy: a slice's `entry_type` must be one of the values in its module's `Driving Ports` list, and that value becomes part of the slice's canonical test filename (see the slicing skill's Test File Convention).

Driving port — in the hexagonal sense — is the inbound side of the module: whoever or whatever calls in. Six recognized values plus any project-specific ones:

| Value | What it covers |
|-------|----------------|
| `http` | REST routes, public HTTP endpoints |
| `graphql` | GraphQL schemas and resolvers |
| `event` | Async event/message consumers (Kafka, RabbitMQ, NATS, SNS, etc.) |
| `cron` | Scheduled jobs, time-triggered tasks |
| `queue` | Queue/job consumers (BullMQ, SQS workers, Sidekiq) |
| `service` | Public service methods called from other modules in the same process |

Projects can extend with their own values (`grpc`, `websocket`, `tcp`, `signal`) — they are kebab-case identifiers, no other constraint.

### Detection (codebase scan)

In the codebase scan, detect driving ports per module by these signals. Populate the `Driving Ports` value with every detected kind for the module; if the scan finds nothing for a module, ask the user.

| Driving port | Detection signals |
|--------------|-------------------|
| `http` | Express/Fastify/Koa route registrations; FastAPI/Flask `@app.route`; NestJS `@Controller`; Rails `config/routes.rb` entries; Go `http.HandleFunc` / Gin/Echo/Fiber handlers; ASP.NET `[Route]`; Spring `@RequestMapping`/`@RestController` |
| `graphql` | `type Query` / `type Mutation` in `*.graphql` / `*.gql`; `@Resolver`/`@Query`/`@Mutation` decorators; `gql\`…\`` tagged templates; `buildSchema` / `makeExecutableSchema` |
| `event` | Kafka consumer SDK (`KafkaJS.consumer`, `confluent-kafka-go`); NATS subscribers; RabbitMQ `channel.consume`; SNS/SQS topic subscriptions; Pub/Sub subscribers |
| `cron` | `node-cron`, `node-schedule`, `apscheduler`, `robfig/cron`; cron-format strings in config; `Scheduled` decorators (Spring); `crontab` files |
| `queue` | BullMQ `Worker`/`Queue.process`; SQS `pollFor*`; Sidekiq workers; Resque jobs; Bull `processJob` |
| `service` | Public class methods exposed via a DI container, RPC registry, or explicit public-API export when there is no transport boundary |

If detection finds multiple signals (e.g., a module has both HTTP routes and event consumers), list all of them: `http, event`. Order is alphabetical; comma-and-space separated.

### Re-running setup on an existing project

When `specs/PROJECT.md` already exists and the user opts to regenerate (or runs setup on a project whose MODULES.md predates this column), the re-run must:

1. Re-detect driving ports for every module from the current codebase.
2. Add the `Driving Ports` column if it is missing.
3. Populate missing values for each module from detection; preserve any human-edited values already present.
4. Surface a "Driving ports added" diff in the confirmation step so the user sees what changed.

## Confirmation Rule

Present the composite foundation in **one** AskUserQuestion. Options: write all files / edit one section / cancel. Do not interview section-by-section.

## Document Generation

Read templates from `./templates/` and write each file in a single parallel batch after confirmation. Global files in `specs/`; per-module directories under `specs/features/{module}/`. Each FEAT folder holds REQUIREMENTS.md, USE-CASES.md, ARCHITECTURE.md, plus the UC spec files (`UC-XXXX-{slug}.md`) and UC support folders (`UC-XXXX-{slug}/`) as siblings.

| Document | Template | Location |
|----------|----------|----------|
| PROJECT.md | [PROJECT-template.md](./templates/PROJECT-template.md) | `specs/PROJECT.md` |
| TECH-STACK.md | [TECH-STACK-template.md](./templates/TECH-STACK-template.md) | `specs/TECH-STACK.md` |
| ACTORS.md | [ACTORS-template.md](./templates/ACTORS-template.md) | `specs/ACTORS.md` |
| GLOSSARY.md | [GLOSSARY-template.md](./templates/GLOSSARY-template.md) | `specs/GLOSSARY.md` |
| MODULES.md | [MODULES-template.md](./templates/MODULES-template.md) | `specs/MODULES.md` |
| DOMAINS.md | [DOMAINS-template.md](./templates/DOMAINS-template.md) | `specs/DOMAINS.md` |
| FEATURES.md | [FEATURES-template.md](./templates/FEATURES-template.md) | `specs/FEATURES.md` |
| principles.md | `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md` (body only, frontmatter stripped) | `.claude/rules/principles.md` |
| CLAUDE.md block | inlined in `setup.md` Step 7b | `<host-root>/CLAUDE.md` (fenced section between sentinel markers) |

## Engineering Principles

`/m:setup` writes a host-project copy of the engineering principles at `.claude/rules/principles.md` and injects a short summary into the host `CLAUDE.md` so any AI agent working in the project sees them.

- **Source of truth (default):** `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md`. The plugin ships these.
- **Host-project copy:** `.claude/rules/principles.md`. Team-editable. Operative version that `/m:plan` and `/m:build` read at run time.
- **Always-on summary:** `CLAUDE.md` fenced section delimited by `<!-- molcajete:principles:start -->` and `<!-- molcajete:principles:end -->`.

**Re-run behavior:**

- `.claude/rules/principles.md` — written when absent. When present, `/m:setup` asks whether to keep (default, preserves team edits) or regenerate from the plugin skill.
- `CLAUDE.md` fenced section — replaced in place when the markers are present; appended when the file exists but the markers are absent; the file is created with only the block when it doesn't exist. Content outside the markers is never touched. The block always reflects current plugin defaults.

## Regeneration

When `specs/PROJECT.md` already exists, `/m:setup` offers three paths: **Cancel**, **Regenerate all** (full one-shot composition; loses local edits), or **Update** (drift detection + selective patch). The principles file follows its own regeneration prompt in Step 7a — not part of the foundation regeneration.

## Drift Catalog

When `/m:setup` runs in **Update mode**, it walks this catalog. Each entry is a discrete drift check: an artifact, a detection rule, and a fix action. New plugin features that produce host-facing artifacts add new entries; `/m:setup` propagates them to existing projects without overwriting user content.

The catalog is the **single source of truth** for what update mode can repair. Categories:

- **NEW ARTIFACTS** — files/blocks the plugin produces that the host lacks entirely.
- **SCHEMA GAPS** — host files missing sections or fields the current template requires; existing content preserved.
- **CONTENT DRIFT** — host files whose plugin-owned content differs from current defaults; team-owned content is preserved unless the user opts to overwrite.

### `principles-host-file`

- **Artifact:** `.claude/rules/principles.md`
- **Category:** NEW ARTIFACT (when missing) or CONTENT DRIFT (when stale)
- **Detection:** File does not exist, **OR** file exists but its content does not start with `# Engineering Principles` and contain headings matching the current plugin skill (`# Engineering Principles`, `## The Meta-Principle...`, `## 1. Integration Tests...`, `## 2. Hexagonal Architecture...`, `## 3. Dependency Injection...`, `## 4. 80% Coverage Floor...`, `## 5. Universal Software Craft`, `## 6. Principles Are Technology-Agnostic`, `## How Molcajete Enforces These`, `## Override`).
- **Fix:** Run Step 7a logic. When the file exists but is stale, the existing per-file AskUserQuestion in Step 7a ("Keep existing / Regenerate from plugin skill") applies — update mode does not force overwrite.
- **Source of truth:** `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md` (body only, frontmatter stripped).

### `principles-claude-md-block`

- **Artifact:** Host `CLAUDE.md` fenced block between `<!-- molcajete:principles:start -->` and `<!-- molcajete:principles:end -->`.
- **Category:** NEW ARTIFACT (when missing) or CONTENT DRIFT (when stale)
- **Detection:** Host `CLAUDE.md` does not exist, **OR** sentinel markers are absent, **OR** content between markers does not byte-match the current default block (inlined in `setup.md` Step 7b).
- **Fix:** Run Step 7b logic. The fenced block is always idempotent-replaced — never asks before overwriting, because the block is metadata the plugin fully owns. Content outside the markers is never touched.
- **Source of truth:** `setup.md` Step 7b (inlined block).

### `tech-stack-running-tests`

- **Artifact:** `specs/TECH-STACK.md` per-module `Running tests:` field.
- **Category:** SCHEMA GAP
- **Detection:** For each `### {module-name}` section under `## Modules`, check whether a `- **Running tests:**` line is present. List every module missing the field.
- **Fix:** For each affected module, re-run the Step 3 detection logic to derive the command (scan the module's manifest for `scripts.test` / `pyproject.toml` `[tool.pytest.ini_options]` / `Makefile` / Go conventional `go test ./...`). If detection finds nothing, prompt the user via AskUserQuestion per module with the discovered candidates or "skip module". Insert the line at the canonical position (after `Testing:` if present, otherwise before `Coverage:`).
- **Source of truth:** `${CLAUDE_PLUGIN_ROOT}/setup/skills/setup/templates/TECH-STACK-template.md` field order.

### `tech-stack-coverage`

- **Artifact:** `specs/TECH-STACK.md` per-module `Coverage:` field.
- **Category:** SCHEMA GAP
- **Detection:** Same shape as `tech-stack-running-tests`; check for `- **Coverage:**` line in each module section.
- **Fix:** For each affected module, re-run the Step 3 detection logic to derive the coverage command. If the project does not expose a coverage collector, write `not available` (`/m:build` estimates against the 80% floor in that case).
- **Source of truth:** Same as `tech-stack-running-tests`.

### `settings-testing-threshold`

- **Artifact:** `.molcajete/settings.json` `testing.threshold` key.
- **Category:** CONTENT DRIFT
- **Detection:** Read the file as JSON. Verify `testing.threshold` is present and is a number. List as drift when missing or non-numeric.
- **Fix:** Read existing file (preserving all other keys and nested structure), merge in `testing.threshold = 80`, write back.
- **Source of truth:** `setup.md` Step 7 (inlined default `{"testing": {"threshold": 80}}`).

### `dot-claude-rules-dir`

- **Artifact:** `.claude/rules/` directory.
- **Category:** NEW ARTIFACT (when missing)
- **Detection:** Directory does not exist.
- **Fix:** `mkdir -p .claude/rules`. Usually paired with `principles-host-file` — the principles fix creates the directory if absent, so this entry only fires when the user has `.claude/rules/principles.md` in mind but the directory was deleted separately (rare).
- **Source of truth:** `setup.md` Step 7 (foundation mkdir).

### `legacy-spec-layout-migration`

- **Artifact:** entire `specs/` tree.
- **Category:** SCHEMA GAPS (structural migration; no plugin-owned content is overwritten, but files are moved and renamed).
- **Detection:** Any of:
  - `specs/modules/` directory exists.
  - Any `specs/features/**/UC-*/usecase.md` file exists (old UC-as-folder-with-usecase.md layout).
  - Any `specs/features/**/UC-*/UC-*-NNN-*.md` slice files exist (old slice naming).
  - Any `specs/features/**/UC-*/UC-*.log` files exist (old log naming).
- **Fix:** Walk every legacy feature folder under `specs/modules/{module}/features/` and migrate per these rules. The target path always includes `{module}/`. Use **AskUserQuestion** with the full list of planned moves (grouped by feature) before applying — the user confirms once for the whole migration.
  1. Move `specs/modules/{module}/features/FEAT-*` → `specs/features/{module}/FEAT-*` (preserve REQUIREMENTS.md, USE-CASES.md, ARCHITECTURE.md, assets/, all child UC files and folders).
  2. For each UC folder `FEAT-*/UC-AAAA-{slug}/` that contains a legacy `usecase.md`:
     - Move `UC-AAAA-{slug}/usecase.md` up one level to `FEAT-*/UC-AAAA-{slug}.md` (the UC spec becomes a sibling of REQUIREMENTS / USE-CASES / ARCHITECTURE).
     - Rename `UC-AAAA-{slug}/UC-AAAA-{slug}.log` → `UC-AAAA-{slug}/CHANGELOG.md`.
     - Rename each slice `UC-AAAA-{slug}/UC-AAAA-NNN-{name}.md` → `UC-AAAA-{slug}/SLICE-NNN-{name}.md`.
  3. Update USE-CASES.md file links inside each FEAT folder: replace `UC-AAAA-{slug}/usecase.md` with `UC-AAAA-{slug}.md`.
  4. Remove the now-empty `specs/modules/` directory tree (only after every feature has migrated successfully).
- **Source of truth:** This catalog entry and the updated path conventions in the slicing / feature-authoring / usecase-authoring skills.
- **Safety:** If any planned target path already exists (collision), abort that feature's migration and surface the conflict in the report. Never overwrite. Leave the source files in place when conflicts block a feature so the user can resolve manually before re-running.

## Extending the Drift Catalog

When a plugin update adds a new host-facing artifact or extends an existing template, add a new entry to this catalog with the same five fields. The update flow in `setup.md` reads this section verbatim — there is no separate registry to keep in sync.

Two rules for new entries:

1. **Detection must be content-only.** No timestamps, no version numbers, no host metadata. The check should be deterministic given the host file and the current plugin defaults.
2. **Fix must never delete or overwrite user-authored content silently.** When the artifact contains both plugin-owned and team-owned content, the fix either patches in place (inserting missing fields without touching existing ones) or asks via AskUserQuestion.

## Template Reference

See `./templates/` for the seven template files.
