---
description: Reverse-engineer a single feature from existing code (cascades to UCs + inline scenarios)
model: claude-opus-4-6
argument-hint: <freeform description of feature to extract>
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

# Reverse-Engineer Feature from Code

You are extracting a single feature spec from existing code, including all its use cases with their inline scenarios. Instead of interviewing the user for requirements, you scan the codebase to discover what's already built, extract structured specs, and enrich ARCHITECTURE.md with implementation research.

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

Read the following files to understand the project and avoid duplicate features:

1. `prd/PROJECT.md` — project description (required)
2. `prd/TECH-STACK.md` — technology choices (if exists)
3. `prd/ACTORS.md` — system actors (if exists)
4. `prd/MODULES.md` — module registry (required)
5. `prd/DOMAINS.md` — domain tag registry (if exists)
6. `prd/FEATURES.md` — check for duplicates across all modules

Use the project context to inform your code analysis and extraction.

## Step 4: Module Selection

Read `prd/MODULES.md` for the list of registered modules and `prd/DOMAINS.md` for domain tags (if it exists).

- If only one module exists, use it automatically and skip to Step 5
- If multiple modules exist, **defer full resolution until after Step 6** (Discovery Scan) when code evidence is available

After Step 6.2 (Scope Confirmation), when code evidence is available:

- Use AskUserQuestion to ask which module this feature belongs to (from MODULES.md). Single-select.
  - Question: "Based on the discovered code, which module does this feature belong to?\n\n{list modules from MODULES.md}"
  - Header: "Module Selection"
- Use AskUserQuestion to ask which domain this feature belongs to (from DOMAINS.md). Single-select.
  - Question: "Which domain does this feature belong to?\n\n{list domains from DOMAINS.md}"
  - Header: "Domain Selection"

## Step 5: Collect Description

If `$ARGUMENTS` is not empty, use it as the description of the existing code capability to extract.

If `$ARGUMENTS` is empty, use AskUserQuestion:
- Question: "Describe the existing code capability you want to extract into a feature spec. Include any relevant module names, directories, or functionality areas.\n\n**Examples:**\n- \"The authentication system in src/auth/ — handles login, registration, and token refresh\"\n- \"The payment processing pipeline that handles Stripe webhooks and order fulfillment\"\n- \"The notification service that sends emails and push notifications\""
- Header: "Describe Existing Capability"

## Step 6: Discovery Scan

Use Glob, Grep, and Read to find files matching the described capability.

### 6.1 Discovery

Search for relevant files:
- Glob for directory structures, module files, and configuration related to the capability
- Grep for key terms, class names, function names, route definitions, and exports
- Read key files to understand the implementation

### 6.2 Scope Confirmation

Present the discovered files via AskUserQuestion before deep analysis:

- Question: "I found these files related to the described capability:\n\n{list of files grouped by directory, with one-line description of each}\n\nShould I analyze all of these, or would you like to narrow or expand the scope?"
- Header: "Relevant Files"
- Options: "Analyze all" / "Narrow scope" (user specifies via Other) / "Add more files" (user specifies via Other)

If the user narrows or expands, adjust the file list accordingly.

## Step 7: Launch T1 — Research + Spec Extraction

Use the Agent tool to launch a general-purpose subagent for deep analysis and spec extraction.

The subagent prompt must include:

1. **Skills to load:**
   - `${CLAUDE_PLUGIN_ROOT}/spec/skills/reverse-engineering/SKILL.md`
   - `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/SKILL.md`
   - `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md`

2. **Project context files to read:**
   - `prd/PROJECT.md`, `prd/TECH-STACK.md` (if exists), `prd/ACTORS.md` (if exists), `prd/MODULES.md`, `prd/DOMAINS.md` (if exists), `prd/FEATURES.md`

3. **The confirmed file list** from Step 6.2

4. **The selected module and domain** from Step 4

5. **The specific task:**
   - Read and analyze all confirmed files following the reverse-engineering skill's research methodology
   - Create the feature in each selected module with the same FEAT-XXXX ID
   - For each module:
     - Extract the feature: name, non-goals, actors, EARS functional requirements with Fit Criteria, non-functional requirements, acceptance criteria
     - Extract all use cases: name, objective, actor, preconditions, trigger, scenarios (Given/Steps/Outcomes/Side Effects per the usecase-authoring skill)
   - Populate ARCHITECTURE.md with all enrichment sections: Component Inventory, Data Model (with real entities), API Surface, Integration Points, Event Topology, Code Map (linking every UC and SC to implementation files)
   - Compare discovered actors against `prd/ACTORS.md` and add any new ones. Compare discovered technologies against `prd/TECH-STACK.md` and add any new ones. Follow the project-level discovery rules from the reverse-engineering skill.
   - Generate IDs: run `node ${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/scripts/generate-id.js {count}` for all needed IDs (1 FEAT + N UCs + M SCs + P FRs + Q NFRs + R USs + S ADRs)

6. **Files to write (per selected module):**
   - Create directory: `prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/`
   - `prd/modules/{module}/features/FEAT-XXXX-{slug}/REQUIREMENTS.md` using template at `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/templates/REQUIREMENTS-template.md` (with `module:` and `domain:` in frontmatter)
   - `prd/modules/{module}/features/FEAT-XXXX-{slug}/USE-CASES.md` using template at `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/templates/USE-CASES-template.md` (with rows for all extracted UCs)
   - `prd/modules/{module}/features/FEAT-XXXX-{slug}/ARCHITECTURE.md` using template at `${CLAUDE_PLUGIN_ROOT}/spec/skills/architecture/templates/ARCHITECTURE-template.md`
   - `prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}.md` for each use case, using template at `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/templates/UC-template.md` (scenarios inline in the UC file)
   - Append a row to `prd/FEATURES.md` under `## {domain}` section: `| FEAT-XXXX | {name} | {description} | pending |`

   **Common:**
   - Edit `prd/ACTORS.md` — append rows for newly discovered actors (if any)
   - Edit `prd/TECH-STACK.md` — add newly discovered tech stack entries (if any)

7. **Report format:** The subagent must end with a structured report listing:
   - Feature ID, name, and file path (per module)
   - Use case IDs, names, inline scenario counts, and file paths
   - ARCHITECTURE.md enrichment summary (which sections populated, file counts in Component Inventory, entity counts in Data Model, route counts in API Surface, Code Map entry counts)
   - Project-level updates: {count} new actors added to ACTORS.md, {count} new tech stack entries added to TECH-STACK.md (list names)

## Step 8: Report

After the subagent returns, tell the user what was created:

**Specs Created (per module):**
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/REQUIREMENTS.md` — feature requirements (EARS syntax, extracted from code)
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/USE-CASES.md` — use case index
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/ARCHITECTURE.md` — enriched with implementation research
- UC files with inline scenario counts
- Updated `prd/FEATURES.md` with new row

Suggest next step: "Review the extracted specs, then run `/m:reverse-plan` to generate a coverage-recovery plan when the feature needs more test coverage."
