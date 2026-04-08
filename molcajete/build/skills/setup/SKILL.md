---
name: setup
description: >-
  Rules and templates for the /m:setup command. Defines the interview flow
  for generating PROJECT.md, TECH-STACK.md, ACTORS.md, GLOSSARY.md,
  MODULES.md, DOMAINS.md, and master FEATURES.md. Covers codebase inference
  for tech stack, actors, modules, and domain tags.
---

# Project Setup

Rules for initializing a project's foundational documents. The /m:setup command references this skill to interview the user and generate the global documents (PROJECT.md, TECH-STACK.md, ACTORS.md, GLOSSARY.md, MODULES.md, DOMAINS.md) and master FEATURES.md that all other commands depend on.

## When to Use

- Setting up a new project with /m:setup
- Re-generating foundational documents for an existing project
- Understanding what foundational documents are required before running /m:plan

## Interview Flow

The setup interview has five stages. Each stage gathers information, presents what was understood, and asks the user to confirm or correct before proceeding.

**All user interaction MUST use the AskUserQuestion tool.** Never ask questions as plain text in the response. This keeps the agent in control of the flow -- the user answers via the tool, and the agent proceeds to the next question without losing control. Even open-ended questions (like "describe your project") must go through AskUserQuestion so the agent remains the driver of the conversation.

### Stage 1: Project Description

Use AskUserQuestion to ask the user to describe the project. Follow up with qualifying questions as needed, each via AskUserQuestion:

1. "What does this project do?" -- the core functionality
2. "Who uses it?" -- the primary users or audience
3. "What problem does it solve?" -- the motivation

If the user's initial description answers all three, skip the follow-ups. Extract a 1-2 paragraph description for PROJECT.md.

### Stage 2: Tech Stack

The tech stack is organized by **module** -- each application, service, or package gets its own section with the directory path, language, framework, key libraries, and tooling. Shared infrastructure (databases, hosting, CI/CD) and external services go in separate sections.

**If a codebase exists**, scan for tech stack indicators and group findings by module:
1. Identify top-level modules: check `apps/`, `packages/`, `services/`, `cmd/`, or other directory structures that separate distinct applications or services.
2. For each module, detect: directory path, language, framework, build tool, key libraries, styling (if frontend), testing tools, lint/format tools.
3. Detect shared infrastructure: databases, caches, queues, hosting, CI/CD, monitoring, containerization.
4. Detect external services: third-party APIs, LLM providers, payment processors, notification services.
5. Detect runtime environment: Docker Compose vs host-native, start/stop commands, compose file location.
6. Detect services: from `docker-compose.yml` or other manifests, extract service names, types, ports, and health check commands.
7. Detect applications: runnable apps with their ports, run commands, and types (frontend/backend).
8. Detect BDD framework: check for `behave`, `@cucumber/cucumber`, `godog`, etc. in dependency manifests. Identify the step definition language and feature file location.
9. Detect per-domain tooling: formatter and linter for each module/domain.
10. Detect environment config: `.env` / `.env.example` files, key variables, seed data commands.
11. Use AskUserQuestion to present the inferred stack organized by section: "I found the following tech stack in your codebase:\n\n{inferred stack: modules, runtime, services, applications, external services, repository structure, BDD, tooling, environment}\n\nIs this correct?"

**If no codebase exists**, use AskUserQuestion for each question:
1. "What applications or services make up your project? For each one, what language and framework does it use?" (e.g., "Patient app: React + TypeScript, Backend API: Go + gqlgen")
2. "What database, cache, or queue systems?"
3. "How is the project hosted and what CI/CD do you use?"
4. "Is this a monorepo or multi-repo? What package manager?"
5. "What BDD framework will you use? (e.g., Behave, Cucumber.js, godog)"
6. "What formatter and linter do you use per module?"

Fill in the TECH-STACK.md template with the confirmed answers, populating all applicable sections (Modules, Runtime, Services, Applications, External Services, Repository Structure, BDD, Tooling, Environment, Conventions).

### Stage 3: Actors

**If actors can be inferred** from the project description or codebase (e.g., user roles in auth middleware, admin panels, API consumers), use AskUserQuestion to suggest them: "Based on your project, I identified these actors: ... Do these look correct? Are there others?"

**If actors cannot be inferred**, use AskUserQuestion to ask: "Who interacts with this system? List the roles (human or system) that use it, along with any constraints or permissions."

Fill in the ACTORS.md template with the confirmed actors.

### Stage 4: Modules

Modules are physical application layers -- each distinct app, service, console, API, or package in the project. Module types are open vocabulary; suggested defaults include `app`, `service`, `package`, `console`, `api`, `cli`, `worker`, `library`, but any descriptive type is valid.

**If a codebase exists**, infer modules from the project structure:
- Check for `apps/`, `packages/`, `services/`, `cmd/` directories -- each subdirectory is a module
- Check for monorepo workspace configurations (package.json workspaces, pnpm-workspace.yaml)
- A single root application (e.g., one `package.json` + `src/`, one `go.mod` + `main.go`) is one module
- Use AskUserQuestion to present the inferred modules: "I found these modules in your project:\n\n{module table}\n\nModules are the physical application layers in your project -- each app, service, or package. They determine how specs and features are organized.\n\nDo these look correct?"

**If no codebase exists**, use AskUserQuestion to ask about project structure:
- "What are the physical modules in your project? A module is each distinct application, service, or package -- for example: a frontend app, a backend API, a shared library, a CLI tool.\n\nModules are physical application layers, not logical concerns."

**For single-module projects**, use the project name or `app` as the sole module:
- "This appears to be a single-module project. I'll create one module: **{project-name-slug}** (type: app). You can add more modules later if your project grows. Does this look correct?"

For each confirmed module, assign:
- **ID:** Short kebab-case identifier (doubles as Gherkin tag)
- **Module:** Human-readable name
- **Description:** One sentence explaining what this module covers
- **Directory:** `modules/{id}/` (relative path within `prd/`)

### Stage 5: Domain Tags

After modules are confirmed, identify logical business domains that cut across modules. Domain tags are lightweight labels used to organize features by business concern.

**If a codebase exists**, infer domain tags from code patterns:
- Auth middleware, login routes, role checks suggest an `identity` domain
- Payment routes, billing models, subscription logic suggest a `billing` domain
- Notification handlers, email templates suggest a `notifications` domain
- Dashboard routes, analytics endpoints suggest an `analytics` domain
- Use AskUserQuestion to present the inferred domain tags: "Based on the codebase, I identified these business domains:\n\n{domain tag table}\n\nDomain tags are logical business concerns used to organize features across modules (e.g., identity, billing, analytics). They are not tied to a specific module.\n\nDo these look correct? Are there others?"

**If no codebase exists**, use AskUserQuestion to ask about business domains:
- "What are the logical business domains in your project? Domain tags represent business concerns that may span multiple modules -- for example: identity, billing, onboarding, analytics.\n\nThese are used to organize features by topic, not by physical layer."

Write DOMAINS.md as a lightweight tag registry with the confirmed domain tags.

## Codebase Detection

### Module Discovery

When a codebase exists, first identify the project's modules -- each application, service, or package that has its own tech stack:

| Structure Pattern | Module Source |
|------------------|--------------|
| `apps/*/` | Each subdirectory is a module (monorepo apps) |
| `packages/*/` | Each subdirectory is a module (monorepo packages) |
| `services/*/` | Each subdirectory is a module (microservices) |
| `cmd/*/` | Each subdirectory is a module (Go services) |
| Single root `package.json` + `src/` | One module at root |
| Single root `go.mod` + `main.go` | One module at root |

For each identified module, run the tech stack indicators below scoped to that module's directory. Also run them at the project root for shared config.

### Tech Stack Indicators

| Indicator File | Infers |
|---------------|--------|
| `package.json` | Node.js; check `dependencies` for framework (next, express, fastify, etc.) |
| `tsconfig.json` | TypeScript |
| `go.mod` | Go; check module path for framework indicators |
| `Cargo.toml` | Rust |
| `Gemfile` | Ruby; check for `rails` |
| `requirements.txt` or `pyproject.toml` | Python; check for `django`, `fastapi`, `flask` |
| `pom.xml` or `build.gradle` | Java/Kotlin |
| `docker-compose.yml` | Infrastructure services (databases, caches, queues) |
| `prisma/schema.prisma` | Prisma ORM + database type from `provider` |
| `drizzle.config.ts` | Drizzle ORM |
| `.github/workflows/*.yml` | GitHub Actions CI/CD |
| `vercel.json` or `netlify.toml` | Hosting platform |
| `tailwind.config.*` | Tailwind CSS |
| `biome.json` | Biome formatter/linter |

Read `package.json` dependencies to detect frontend frameworks (React, Next.js, Vue, Svelte) and state management libraries (Zustand, Redux, urql, Apollo).

### Actor Indicators

Scan the codebase for actor evidence:

| Pattern | Suggests Actor |
|---------|---------------|
| Auth middleware with role checks | Role-based actors (admin, user, guest) |
| Admin panel routes or components | Admin actor |
| API key validation | External system / API consumer actor |
| Public vs. authenticated routes | Guest vs. authenticated user actors |
| Webhook handlers | External system actor |
| Multi-tenant patterns | Tenant/organization actor |

These are suggestions only -- always confirm with the user.

## Confirmation Rules

1. Never write documents without user confirmation
2. Use AskUserQuestion for every confirmation -- never ask as plain text
3. Present inferred values section-by-section, not all at once
4. For each section: show what was extracted, use AskUserQuestion to ask "Does this look correct?"
5. If the user corrects a value, update it and move to the next section
6. After all sections are confirmed, generate all documents at once

## Document Generation

After the interview, generate these documents in order. **All global files go directly in `prd/`.** Per-module files go in `prd/modules/{module}/`.

| Order | Document | Template | Location |
|-------|----------|----------|----------|
| 1 | PROJECT.md | [PROJECT-template.md](./templates/PROJECT-template.md) | `prd/PROJECT.md` |
| 2 | TECH-STACK.md | [TECH-STACK-template.md](./templates/TECH-STACK-template.md) | `prd/TECH-STACK.md` |
| 3 | ACTORS.md | [ACTORS-template.md](./templates/ACTORS-template.md) | `prd/ACTORS.md` |
| 4 | GLOSSARY.md | [GLOSSARY-template.md](./templates/GLOSSARY-template.md) | `prd/GLOSSARY.md` |
| 5 | MODULES.md | [MODULES-template.md](./templates/MODULES-template.md) | `prd/MODULES.md` |
| 6 | DOMAINS.md | [DOMAINS-template.md](./templates/DOMAINS-template.md) | `prd/DOMAINS.md` |
| 7 | FEATURES.md | [FEATURES-template.md](./templates/FEATURES-template.md) | `prd/FEATURES.md` |

After generating all documents, create `prd/modules/{module}/features/` for each module.

### GLOSSARY.md Starter Terms

When generating GLOSSARY.md, include these starter terms (adapted to the project's domain):

- **Command** -- the project's primary interaction unit (if applicable)
- **Module** -- a physical application layer (app, console, API, service)
- **Domain Tag** -- a logical business concern used for cross-cutting queries
- **Feature** -- a permanent, named capability of the system
- **Use Case** -- a specific interaction between an actor and the system
- **Actor** -- a role (human or system) that participates in use cases

Add 3-5 additional terms extracted from the project description and tech stack (e.g., the database name, the primary framework, domain-specific terms the user mentioned).

### FEATURES.md Initial State

Generate one master FEATURES.md at `prd/FEATURES.md` with one `## {domain}` section per domain from DOMAINS.md. All tables start empty. No features are populated at setup time -- they are added by /m:feature or /m:spec.

## Regeneration

If `prd/PROJECT.md` already exists when /m:setup is run:
1. Ask the user what they want to do. Options:
   - **"Regenerate all"** -- full interview, regenerate PRD documents
   - **"No changes"** -- stop without changes
2. If "Regenerate all", proceed with the full interview (Stages 1-5)
3. If "No changes", stop

## Template Reference

| Template | Purpose |
|----------|---------|
| [PROJECT-template.md](./templates/PROJECT-template.md) | PROJECT.md structure |
| [TECH-STACK-template.md](./templates/TECH-STACK-template.md) | TECH-STACK.md structure |
| [ACTORS-template.md](./templates/ACTORS-template.md) | ACTORS.md structure |
| [GLOSSARY-template.md](./templates/GLOSSARY-template.md) | GLOSSARY.md structure |
| [MODULES-template.md](./templates/MODULES-template.md) | MODULES.md structure |
| [DOMAINS-template.md](./templates/DOMAINS-template.md) | DOMAINS.md domain tag registry |
| [FEATURES-template.md](./templates/FEATURES-template.md) | Master FEATURES.md structure (sectioned by domain) |
