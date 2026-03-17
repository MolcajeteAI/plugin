---
description: Create a technical specification for a feature
model: claude-opus-4-6
allowed-tools: Read, Write, Edit, Glob, Grep, Task, AskUserQuestion
argument-hint: <feature folder name>
---

# Create Technical Specification

You are producing a technical specification document for a feature. Output goes to the feature's folder inside `prd/specs/`.

**Feature folder:** $ARGUMENTS

## Critical Directives

These override every step below. No exceptions.

1. **Right over easy.** Design data models, APIs, and architecture for correctness, not convenience. Do not simplify the design to make the spec easier to write. If the correct architecture is more complex, specify the more complex architecture.
2. **Fix everything you see.** If you encounter inconsistencies, gaps, or errors in existing PRD files or requirements while working, fix them.

## Step 1: Verify Product Context

Check that `prd/mission.md` and `prd/tech-stack.md` exist. If they don't, tell the user to run `/m:init` first and stop.

## Step 2: Identify Feature Folder

If `$ARGUMENTS` is provided, look for a matching folder in `prd/specs/`. Match by folder name (exact or partial). If multiple matches or no match, use AskUserQuestion to clarify.

If `$ARGUMENTS` is not provided, list available feature folders in `prd/specs/` and use AskUserQuestion to ask which one.

## Step 3: Load Context via Sub-Agents

Launch 3 parallel `Explore` sub-agents using the Task tool in a single message:

**Agent 1 — Skills and Templates** (subagent_type: `Explore`, thoroughness: "very thorough"):
- Prompt: Read the following files and return their full content:
  - `${CLAUDE_PLUGIN_ROOT}/skills/project-management/SKILL.md`
  - `${CLAUDE_PLUGIN_ROOT}/skills/project-management/references/spec-template.md`
  Return:
  ```
  SKILL_RULES:
  {Key rules and conventions from SKILL.md — formatting, ID schemes, diagram conventions}

  TEMPLATE:
  {Full content of spec-template.md}
  ```

**Agent 2 — PRD Context** (subagent_type: `Explore`, thoroughness: "very thorough"):
- Prompt: Read the following files and return a structured summary:
  - `prd/mission.md` — vision, users
  - `prd/tech-stack.md` — architecture, stack choices, conventions
  - `prd/roadmap.md` — priorities (if exists)
  - Per-task changelog files in `prd/specs/*/plans/changelog-*.md` — what's already built (scan all feature folders)
  - `prd/specs/{folder}/requirements.md` — feature requirements (if exists)
  - `CLAUDE.md` — project conventions
  Return:
  ```
  PRD_CONTEXT:
  - Mission: {one-line summary}
  - Target users: {user types}
  - Stack: {architecture and stack}
  - Conventions: {key CLAUDE.md rules for spec writing — resolver patterns, component architecture, i18n, GraphQL multi-schema}
  - Roadmap priorities: {relevant items, or "No roadmap found"}
  - Already built: {summary from per-task changelog files, or "No changelog files found"}

  REQUIREMENTS:
  {Full content of requirements.md if it exists, or "No requirements.md found — brief requirements gathering needed"}
  ```

**Agent 3 — Architecture Scan** (subagent_type: `Explore`, thoroughness: "very thorough"):
- Prompt: Scan the codebase to understand the current architecture:
  - Find `**/README.md` files (excluding `node_modules/`, `prd/`) and read those in directories related to the feature's technical scope. Extract module purposes, component diagrams, and data flow information.
  - List existing database migrations in `server/migrations/` (file names only)
  - List existing models in `server/internal/models/` (file names only)
  - List existing repositories in `server/internal/repository/` (file names only)
  - List GraphQL schema files in `server/internal/*/graph/*.graphqls` (file names only)
  Return:
  ```
  ARCHITECTURE:
  - Modules: {list of relevant modules with their purposes from READMEs}
  - Data models: {existing models from server/internal/models/}
  - Repositories: {existing repos from server/internal/repository/}
  - GraphQL schemas: {existing .graphqls files per app}
  - Migrations: {recent migration file names}
  - Diagrams: {any relevant Mermaid diagrams found in READMEs}
  ```

Use the returned context for all subsequent steps. Do NOT read these files again yourself.

## Step 4: Requirements Check

If `requirements.md` exists in the feature folder (returned by Agent 2), use it as the primary input. Reference all UC/US/FR/NFR IDs from it.

If `requirements.md` does NOT exist, conduct a brief requirements gathering via AskUserQuestion:
- What does this feature do?
- What are the main use cases?
- What are the key technical constraints?

Then proceed to spec generation. Note that a full requirements pass was skipped.

## Step 5: Generate Specification

> Remember: **Right over easy.** Design data models, APIs, and architecture for correctness. Do not simplify the design to reduce spec complexity. If the right architecture requires more tables, more resolvers, or more components — specify them.

Write `spec.md` in the feature folder following the spec template. The spec must include:

1. **Overview** — Feature description, strategic alignment, user value, success criteria
2. **Requirements Summary** — FR/NFR tables referencing IDs from requirements.md
3. **Data Models** — SQL CREATE TABLE statements with column description tables. Include indexes and ER diagram in Mermaid.
4. **API Contracts** — GraphQL schema definitions, mutation/query details with request/response examples, error codes. Include sequence diagrams in Mermaid.
5. **User Interface** — Component table (type, location, purpose), user flow diagrams in Mermaid, state management interfaces, form validation tables, error messages, accessibility requirements.
6. **Integration Points** — External systems, internal dependencies, configuration.
7. **Acceptance Criteria** — Per use case with checkboxes, edge cases table, performance and security criteria.
8. **Verification** — Unit, integration, and E2E test tables.
9. **Implementation Checklist** — Grouped by subsystem (server, frontend per app), all checkboxes.

All diagrams must use Mermaid syntax: sequence diagrams for API flows, ER diagrams for data models, flowcharts for user flows.

## Step 6: Update Roadmap

If `prd/roadmap.md` exists, update the feature's status/links to include the new spec link.

## Step 7: Inform User

After generating the document, tell the user:
- What file was created and where
- Summary of data models, API operations, and components defined
- Suggest next steps: "Use `/m:tasks {folder-name}` to break this spec into implementation tasks."

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- Follow all formatting rules from the project-management skill: no emojis, text checkboxes only, Mermaid-only diagrams, tables for structured data, consistent ID scheme.
- Reference requirement IDs (`UC-{tag}-NNN`, `US-{tag}-NNN`, `FR-{tag}-NNN`, `NFR-{tag}-NNN`) from requirements.md throughout the spec.
- Do not use the word "comprehensive" in any document.
- Write SQL for PostgreSQL specifically.
- Write GraphQL schema matching the project's multi-schema pattern (patient/doctor/console).
