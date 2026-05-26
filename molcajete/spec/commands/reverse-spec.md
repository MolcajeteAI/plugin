---
description: Reverse-engineer specs from existing code (broadest scope, multi-feature)
model: claude-opus-4-6
argument-hint: <freeform description of capabilities to extract>
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

# Reverse-Engineer Spec from Code

You are extracting product specs from an existing codebase — discovering features, use cases, and inline scenarios from code rather than authoring them from scratch. This is the broadest reverse command: it can discover and extract multiple features in a single invocation.

**All user interaction MUST use the AskUserQuestion tool.** Never ask questions as plain text in your response.

## Step 1: Load Skills

Read all skills that govern this command:

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/reverse-engineering/SKILL.md` — research methodology, extraction patterns, ARCHITECTURE.md enrichment, dispatcher integration
2. `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/SKILL.md` — EARS syntax, Fit Criteria, feature structure, templates
3. `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md` — flat inline scenario structure, Side Effects conventions, UC template

Follow these skills' rules for all subsequent steps.

## Step 2: Verify Prerequisites

Check that `prd/PROJECT.md` and `prd/MODULES.md` both exist.

If either is missing, tell the user:

"Project foundation not found. Run `/m:setup` first to create PROJECT.md and MODULES.md."

Then stop. Do not proceed.

## Step 3: Load Project Context

Read the following files to understand the project:

1. `prd/PROJECT.md` — project description (required)
2. `prd/TECH-STACK.md` — technology choices (if exists)
3. `prd/ACTORS.md` — system actors (if exists)
4. `prd/MODULES.md` — module registry (required)
5. `prd/DOMAINS.md` — domain tag registry (if exists)
6. `prd/FEATURES.md` — check for duplicates across all domains

## Step 4: Collect Description

If `$ARGUMENTS` is not empty, use it as the description of capabilities to extract.

If `$ARGUMENTS` is empty, use AskUserQuestion:
- Question: "Describe the existing code capabilities you want to extract into specs. You can mention multiple areas — each will become a separate feature.\n\n**Examples:**\n- \"Authentication with Privy, social login, and EOA wallet support\"\n- \"The payment processing pipeline and the notification service\"\n- \"Everything in src/api/ — user management, billing, and admin tools\""
- Header: "Describe Capabilities"

## Step 5: Discovery Scan

Use Glob, Grep, and Read to find files matching the described capabilities.

### 5.1 Broad Discovery

Search for relevant files:
- Glob for directory structures, module files, and configuration related to the described areas
- Grep for key terms, class names, function names, route definitions, and exports
- Read key entry points (route files, index files, main modules) to understand the structure

Group discovered files by likely feature boundary (shared domain, directory structure, actor set).

### 5.2 Scope Confirmation

Present the discovered files via AskUserQuestion:

- Question: "I found these files organized by likely feature boundaries:\n\n{for each proposed feature group:\n  **Feature: {proposed name}**\n  {list of files with one-line descriptions}\n}\n\nShould I analyze all of these, or would you like to adjust the grouping?"
- Header: "Discovered Scope"
- Options: "Analyze all" / "Adjust grouping" (user specifies via Other) / "Narrow scope" (user specifies via Other)

If the user adjusts, update the grouping accordingly.

## Step 6: Launch T1 — Research + Spec Extraction

Use the Agent tool to launch a general-purpose subagent for each feature group. If there are multiple feature groups, launch them sequentially (not in parallel) to avoid overwhelming the system.

For each feature group, the subagent prompt must include:

1. **Skills to load:**
   - `${CLAUDE_PLUGIN_ROOT}/spec/skills/reverse-engineering/SKILL.md`
   - `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/SKILL.md`
   - `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md`

2. **Project context files to read:**
   - `prd/PROJECT.md`, `prd/TECH-STACK.md` (if exists), `prd/ACTORS.md` (if exists), `prd/DOMAINS.md`, `prd/FEATURES.md`

3. **The specific task:**
   - Read `prd/MODULES.md` and `prd/DOMAINS.md` to determine which module and domain each extracted feature belongs to
   - Determine module from code location (which application/service directory), determine domain from business concern
   - Read and analyze the confirmed files for this feature group
   - Extract: name, non-goals, actors, EARS functional requirements with Fit Criteria, non-functional requirements, acceptance criteria
   - Extract use cases: name, objective, actor, preconditions, trigger, scenarios (Given/Steps/Outcomes/Side Effects)
   - Populate ARCHITECTURE.md: Component Inventory, Data Model, API Surface, Integration Points, Event Topology, Code Map
   - Compare discovered actors against `prd/ACTORS.md` and add any new ones. Compare discovered technologies against `prd/TECH-STACK.md` and add any new ones. Follow the project-level discovery rules from the reverse-engineering skill.
   - Generate IDs: run `node ${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/scripts/generate-id.js {count}` for all needed IDs (FEAT-, UC-, SC-, FR-, NFR-, US-, ADR-)
4. **Files to write:**

   For each feature, in each selected module:
   - `prd/modules/{module}/features/FEAT-XXXX-{slug}/REQUIREMENTS.md` using template at `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/templates/REQUIREMENTS-template.md` — with `module: {module}` and `domain: {domain}` in frontmatter
   - `prd/modules/{module}/features/FEAT-XXXX-{slug}/USE-CASES.md` using template at `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/templates/USE-CASES-template.md`
   - `prd/modules/{module}/features/FEAT-XXXX-{slug}/ARCHITECTURE.md` using template at `${CLAUDE_PLUGIN_ROOT}/spec/skills/architecture/templates/ARCHITECTURE-template.md`
   - `prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}.md` for each use case, using template at `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/templates/UC-template.md` (scenarios inline in the UC file)
   - Append row to `prd/FEATURES.md` under the `## {domain}` section: `| FEAT-XXXX | {name} | {description} | pending |`

   **Common to both:**
   - Edit `prd/ACTORS.md` — append rows for newly discovered actors (if any)
   - Edit `prd/TECH-STACK.md` — add newly discovered tech stack entries (if any)

5. **Report format:** The subagent must end with a structured report listing:
   - Feature ID, name, and file path
   - Use case IDs, names, inline scenario counts, and file paths
   - ARCHITECTURE.md enrichment summary (which sections populated)
   - Project-level updates: {count} new actors added to ACTORS.md, {count} new tech stack entries added to TECH-STACK.md (list names)

## Step 7: Report

After each subagent returns, compile the results into a summary and tell the user what was created across all features:

**Specs Created:**
- Features (FEAT-XXXX) with file paths
- Use cases (UC-XXXX) with inline scenario counts
- ARCHITECTURE.md files enriched with implementation research

Suggest next step: "Review the extracted specs, then run `/m:reverse-plan` to generate a coverage-recovery plan when modules need more test coverage."
