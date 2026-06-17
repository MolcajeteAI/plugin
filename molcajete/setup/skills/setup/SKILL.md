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

Read templates from `./templates/` and write each file in a single parallel batch after confirmation. Global files in `specs/`; per-module directories under `specs/modules/{module}/features/` (UCs are direct children of each FEAT folder — no `use-cases/` subfolder).

| Document | Template | Location |
|----------|----------|----------|
| PROJECT.md | [PROJECT-template.md](./templates/PROJECT-template.md) | `specs/PROJECT.md` |
| TECH-STACK.md | [TECH-STACK-template.md](./templates/TECH-STACK-template.md) | `specs/TECH-STACK.md` |
| ACTORS.md | [ACTORS-template.md](./templates/ACTORS-template.md) | `specs/ACTORS.md` |
| GLOSSARY.md | [GLOSSARY-template.md](./templates/GLOSSARY-template.md) | `specs/GLOSSARY.md` |
| MODULES.md | [MODULES-template.md](./templates/MODULES-template.md) | `specs/MODULES.md` |
| DOMAINS.md | [DOMAINS-template.md](./templates/DOMAINS-template.md) | `specs/DOMAINS.md` |
| FEATURES.md | [FEATURES-template.md](./templates/FEATURES-template.md) | `specs/FEATURES.md` |

## Regeneration

When `specs/PROJECT.md` already exists, ask once (regenerate vs cancel). On regenerate, run the full one-shot composition again.

## Template Reference

See `./templates/` for the seven template files.
