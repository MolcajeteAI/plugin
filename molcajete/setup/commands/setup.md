---
description: Initialize project with foundational docs and tooling detection, or re-run to update tooling only
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

You are initializing a project's foundational documents. These documents are required by all other Molcajete commands (/m:plan, /m:spec).

**All user interaction MUST use the AskUserQuestion tool.** Never ask questions as plain text in your response. This keeps you in control of the conversation flow.

## Step 1: Load Skill

Read the setup skill for interview rules, codebase detection patterns, confirmation rules, and template references:

```
Read: ${CLAUDE_PLUGIN_ROOT}/setup/skills/setup/SKILL.md
```

Follow the skill's rules for all subsequent steps.

## Step 2: Check for Existing Documents and Parse Flags

Check if `prd/PROJECT.md` already exists.

If it exists, use AskUserQuestion:
- Question: "Foundational documents already exist (PROJECT.md found). What would you like to do?"
- Header: "Setup Mode"
- Options:
  - "Regenerate all" -- full interview: regenerate PRD documents
  - "No changes" -- stop without changes

If "Regenerate all" → proceed to Step 3.
If "No changes" → stop.

If `prd/PROJECT.md` does not exist, proceed to Step 3.

## Step 3: Interview -- Project Description

Use AskUserQuestion to ask the user to describe their project. Ask:
- "What does this project do, who uses it, and what problem does it solve?"

If the user's answer is too brief (doesn't cover what/who/why), follow up with qualifying questions via AskUserQuestion until you have enough for a 1-2 paragraph description.

After gathering the description, use AskUserQuestion to present it back:
- Question: "Here's the project description I'll use for PROJECT.md:\n\n{extracted description}\n\nDoes this look correct?"
- Header: "Project"
- Options:
  - "Yes, looks good" -- proceed
  - "Edit" -- user provides corrections via Other

## Step 4: Interview -- Tech Stack

### If a codebase exists

Launch an `Explore` sub-agent to scan for tech stack indicators **grouped by module**. The agent should:

1. **Discover modules:** Check for `apps/*/`, `packages/*/`, `services/*/`, `cmd/*/` directory structures. If none found, treat the project root as a single module.
2. **Per module:** Read the module's directory and detect:
   - Directory path (relative to project root)
   - Language and version (from go.mod, package.json engines, tsconfig.json target, etc.)
   - Framework (from dependencies: React, Next.js, Express, gqlgen, etc.)
   - Build tool (Vite, Webpack, esbuild, `go build`, etc.)
   - Key libraries (state management, GraphQL clients, ORMs, validation, i18n, etc.)
   - Styling (Tailwind, CSS modules, styled-components — frontend modules only)
   - Testing tools (Vitest, Jest, Go test, pytest, etc.)
   - Lint/format tools (Biome, ESLint, golangci-lint, etc.)
3. **Shared infrastructure:** Check docker-compose.yml for databases, caches, queues. Check .github/workflows/, vercel.json, netlify.toml for CI/CD and hosting.
4. **External services:** Grep for API keys, SDK imports, or service client instantiations that indicate third-party services (payment processors, LLM providers, notification services, etc.)
5. **Return a structured summary** organized as: one section per module (with directory, language, framework, libraries, tooling), then shared infrastructure, then external services.

After the agent returns, use AskUserQuestion to present the inferred stack:
- Question: "I found the following tech stack in your codebase:\n\n{inferred stack grouped by module, then shared infrastructure, then external services}\n\nIs this correct? Add or correct anything that's missing."
- Header: "Tech Stack"
- Options:
  - "Yes, that's correct" -- proceed
  - "Mostly correct, with changes" -- user provides corrections via Other

### If no codebase exists

Use AskUserQuestion to ask each tech stack question. You may batch related questions into a single AskUserQuestion with multiple questions (up to 4):

Batch 1:
- "What applications or services make up your project? For each one, what language and framework does it use?" (e.g., "Patient app: React + TypeScript in apps/patient/, Backend: Go + gqlgen in server/")
- "What database, cache, or queue systems?" (e.g., PostgreSQL + Redis)

Batch 2:
- "How is the project hosted and what CI/CD do you use?" (e.g., Hetzner VPS + GitHub Actions)
- "Is this a monorepo or multi-repo? What package manager?" (e.g., monorepo with pnpm)

After gathering answers, use AskUserQuestion to present the composed tech stack for confirmation (one module section per application/service).

## Step 5: Interview -- Actors

### If actors can be inferred

Launch an `Explore` sub-agent to scan for actor evidence in the codebase. The agent should check for:
- Auth middleware with role checks (suggests role-based actors)
- Admin panel routes or components (suggests admin actor)
- API key validation (suggests external system actor)
- Public vs. authenticated routes (suggests guest vs. authenticated actors)
- Webhook handlers (suggests external system actor)
- Multi-tenant patterns (suggests tenant/organization actor)

Also extract potential actors from the project description gathered in Step 3 (user types mentioned, roles described).

After inference, use AskUserQuestion to present suggested actors:
- Question: "Based on your project, I identified these actors:\n\n{actor table with Role, Description, Constraints}\n\nDo these look correct? Are there others?"
- Header: "Actors"
- Options:
  - "Yes, that's correct" -- proceed
  - "Needs changes" -- user provides corrections via Other

### If no actors can be inferred

Use AskUserQuestion:
- Question: "Who interacts with this system? List the roles (human or system) along with any permissions or constraints. For example: 'Admin (human) -- full access; API Consumer (system) -- read-only.'"
- Header: "Actors"

After gathering the answer, use AskUserQuestion to present the structured actor table for confirmation.

## Step 6: Interview -- Modules

Modules are physical application layers -- each distinct app, service, console, API, or package in the project. They determine how specs and features are organized on disk.

### If a codebase exists

Launch an `Explore` sub-agent to infer modules from the project structure:
- Check for `apps/`, `packages/`, `services/`, `cmd/` directories -- each subdirectory is a module
- Check for monorepo workspace configurations (package.json workspaces, pnpm-workspace.yaml)
- A single root application (e.g., one `package.json` + `src/`, one `go.mod` + `main.go`) is one module

After inference, use AskUserQuestion to present the inferred modules:
- Question: "I found these physical modules in your project:\n\n{module table: ID | Module | Description}\n\nModules are physical application layers (apps, services, packages). Each maps to a deployable unit.\n\nDo these look correct?"
- Header: "Modules"
- Options:
  - "Yes, that's correct" -- proceed
  - "Needs changes" -- user provides corrections via Other

### If no codebase exists

Use AskUserQuestion:
- Question: "What are the physical modules in your project? A module is each distinct application, service, or package -- for example: a frontend app, a backend API, a shared library, a CLI tool.\n\nModules are physical application layers, not logical concerns."
- Header: "Modules"

### For single-module projects

If the project appears to be a single application (one framework, one entry point, no monorepo structure), suggest one module using the project name or `app`:
- Question: "This appears to be a single-module project. I'll create one module: **{project-name-slug}** (type: app). You can add more modules later if your project grows. Does this look correct?"
- Header: "Modules"
- Options:
  - "Yes, one module is fine" -- proceed
  - "I have multiple modules" -- user provides corrections via Other

After confirmation, for each confirmed module assign:
- **ID:** Short kebab-case identifier (doubles as Gherkin tag)
- **Module:** Human-readable name
- **Description:** One sentence explaining what this module covers
- **Directory:** `modules/{id}/` (relative path within `prd/`)

Record the module list for document generation.

## Step 7: Interview -- Domain Tags

After modules are confirmed, identify logical business domains that cut across modules. Domain tags are lightweight labels used to organize features by business concern -- they are not tied to a specific module.

### If a codebase exists

Launch an `Explore` sub-agent to infer domain tags from code patterns:
- Auth middleware, login routes, role checks suggest an `identity` domain
- Payment routes, billing models, subscription logic suggest a `billing` domain
- Notification handlers, email templates suggest a `notifications` domain
- Dashboard routes, analytics endpoints suggest an `analytics` domain
- Onboarding flows, setup wizards suggest an `onboarding` domain

After inference, use AskUserQuestion to present the suggested domain tags:
- Question: "What logical business domains does your project have?\n\n{suggested domains}\n\nDomains are logical concerns (identity, billing, analytics) used as tags to filter features and tests across modules."
- Header: "Domain Tags"
- Options:
  - "Yes, that's correct" -- proceed
  - "Needs changes" -- user provides corrections via Other

### If no codebase exists

Use AskUserQuestion:
- Question: "What logical business domains does your project have?\n\nDomains are logical concerns (identity, billing, analytics) used as tags to filter features and tests across modules."
- Header: "Domain Tags"

After confirmation, record the domain tag list. DOMAINS.md will be written as a lightweight tag registry (ID, Domain, Description -- no types or directories).

## Step 8: Generate Documents

**Global project files go directly in `prd/`.** Per-module files go in `prd/modules/{module}/`.

First, create the prd directory and module directories:

```bash
mkdir -p prd
```

Then for each confirmed module:
```bash
mkdir -p prd/modules/{module}/features
```

Read all templates from the setup skill and generate the documents:

1. Read `${CLAUDE_PLUGIN_ROOT}/setup/skills/setup/templates/PROJECT-template.md`
   Write `prd/PROJECT.md` filled with the confirmed project description.

2. Read `${CLAUDE_PLUGIN_ROOT}/setup/skills/setup/templates/TECH-STACK-template.md`
   Write `prd/TECH-STACK.md` filled with the confirmed tech stack.

3. Read `${CLAUDE_PLUGIN_ROOT}/setup/skills/setup/templates/ACTORS-template.md`
   Write `prd/ACTORS.md` filled with the confirmed actors.

4. Read `${CLAUDE_PLUGIN_ROOT}/setup/skills/setup/templates/GLOSSARY-template.md`
   Write `prd/GLOSSARY.md` with starter terms:
   - 5 standard terms: Domain, Feature, Use Case, Actor, Side Effect (adapted to this project's domain)
   - 3-5 additional terms extracted from the project description and tech stack (e.g., the database name, the primary framework, domain-specific terms)

5. Read `${CLAUDE_PLUGIN_ROOT}/setup/skills/setup/templates/MODULES-template.md`
   Write `prd/MODULES.md` filled with the confirmed modules table.

6. Read `${CLAUDE_PLUGIN_ROOT}/setup/skills/setup/templates/DOMAINS-template.md`
   Write `prd/DOMAINS.md` filled with the confirmed domain tags as a lightweight tag registry.

7. Read `${CLAUDE_PLUGIN_ROOT}/setup/skills/setup/templates/FEATURES-template.md`
   Write `prd/FEATURES.md` with the status key, then one `## {domain}` section per domain from DOMAINS.md. All tables start empty. No features are populated at setup time.

## Step 9: Report

Tell the user what was created or updated.

**Created files (Steps 3-8):**
- `prd/PROJECT.md` -- project description
- `prd/TECH-STACK.md` -- technology choices
- `prd/ACTORS.md` -- system actors
- `prd/GLOSSARY.md` -- domain vocabulary with starter terms
- `prd/MODULES.md` -- module registry (physical application layers)
- `prd/DOMAINS.md` -- domain tag registry (logical business concerns)
- `prd/FEATURES.md` -- master feature inventory (sectioned by domain)
- For each module:
  - `prd/modules/{module}/features/` -- directory for feature specs

Explain the structure: "Your specs are organized by module. Features are registered in `prd/FEATURES.md` under their domain section. Use `/m:feature` to create your first feature."
