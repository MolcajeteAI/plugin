---
description: Reverse-engineer a single feature from existing code (cascades to UCs + scenarios)
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

You are extracting a single feature spec from existing code, including all its use cases and scenarios. Instead of interviewing the user for requirements, you scan the codebase to discover what's already built, extract structured specs, enrich ARCHITECTURE.md with implementation research, and generate Gherkin artifacts.

This command runs as a two-task dispatcher to protect the 200K context limit. T1 researches the code and extracts PRD specs. T2 generates Gherkin artifacts. A user review checkpoint separates them.

**All user interaction MUST use the AskUserQuestion tool.** Never ask questions as plain text in your response.

## Step 1: Load Skills

Read all skills that govern this command:

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/reverse-engineering/SKILL.md` — research methodology, extraction patterns, ARCHITECTURE.md enrichment, dispatcher integration
2. `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/SKILL.md` — EARS syntax, Fit Criteria, feature structure, templates
3. `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md` — flat scenario structure, Side Effects conventions, UC template
4. `${CLAUDE_PLUGIN_ROOT}/shared/skills/gherkin/SKILL.md` — Gherkin generation, tagging, scaffold, step stubs

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
   - **Testability analysis:** For each extracted UC, run the testability analysis per the reverse-engineering skill's Testability Analysis section. Check the feature's ARCHITECTURE.md `## Testing Decisions` first -- skip concerns that already have a recorded decision. If unresolved concerns are found, generate a recommendations file alongside the UC file using the template at `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/templates/UC-TEST-ISSUES-template.md`. Do not use AskUserQuestion for testability concerns.

6. **Files to write (per selected module):**
   - Create directory: `prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/`
   - `prd/modules/{module}/features/FEAT-XXXX-{slug}/REQUIREMENTS.md` using template at `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/templates/REQUIREMENTS-template.md` (with `module:` and `domain:` in frontmatter)
   - `prd/modules/{module}/features/FEAT-XXXX-{slug}/USE-CASES.md` using template at `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/templates/USE-CASES-template.md` (with rows for all extracted UCs)
   - `prd/modules/{module}/features/FEAT-XXXX-{slug}/ARCHITECTURE.md` using template at `${CLAUDE_PLUGIN_ROOT}/spec/skills/architecture/templates/ARCHITECTURE-template.md`
   - `prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}.md` for each use case, using template at `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/templates/UC-template.md`
   - Append a row to `prd/FEATURES.md` under `## {domain}` section: `| FEAT-XXXX | {name} | {description} | pending |`

   **Common:**
   - Edit `prd/ACTORS.md` — append rows for newly discovered actors (if any)
   - Edit `prd/TECH-STACK.md` — add newly discovered tech stack entries (if any)
   - `UC-XXXX-TEST-ISSUES.md` — testability recommendations (conditional, only when concerns are found)

7. **Report format:** The subagent must end with a structured report listing:
   - Feature ID, name, and file path (per module)
   - Use case IDs, names, scenario counts, and file paths
   - ARCHITECTURE.md enrichment summary (which sections populated, file counts in Component Inventory, entity counts in Data Model, route counts in API Surface, Code Map entry counts)
   - Project-level updates: {count} new actors added to ACTORS.md, {count} new tech stack entries added to TECH-STACK.md (list names)
   - Testability: {count} recommendations files generated (list paths)

## Step 8: Report T1 Results

After the subagent returns, present the results via AskUserQuestion.

Report per module:

- Question: "**Research + Spec Extraction Complete**\n\n{for each module:\n**{module}: {FEAT-XXXX}: {name}**\n- REQUIREMENTS.md: {FR count} functional, {NFR count} non-functional requirements\n- ARCHITECTURE.md: enriched with {sections list}\n- Use Cases:\n  {for each UC: UC-XXXX: {name} ({scenario count} scenarios)}\n}\n\nPlease review the generated specs in `prd/modules/{module}/features/FEAT-XXXX-{slug}/`. Edit any specs that need adjustment, then continue to generate Gherkin.\n\nReady to proceed with Gherkin generation?"
- Header: "Specs Ready for Review"
- Options: "Proceed with Gherkin generation" / "I need to review and edit first — I'll re-run when ready"

If the user chooses to review first, stop. They will re-run or continue manually.

## Step 9: Launch T2 — Gherkin Generation

Use the Agent tool to launch a general-purpose subagent for Gherkin generation.

The subagent prompt must include:

1. **Skills to load:**
   - `${CLAUDE_PLUGIN_ROOT}/shared/skills/gherkin/SKILL.md`
   - `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md` (Gherkin Mapping table)

2. **Files to read (per module):**
   - `prd/modules/{module}/features/FEAT-XXXX-{slug}/REQUIREMENTS.md`
   - `prd/modules/{module}/features/FEAT-XXXX-{slug}/ARCHITECTURE.md`
   - All UC files in `prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/`
   - `prd/TECH-STACK.md` (if exists) for language/framework detection

3. **The specific task:**
   - Run scaffold setup from `${CLAUDE_PLUGIN_ROOT}/shared/skills/gherkin/references/scaffold.md`
   - Read `module:` and `domain:` from REQUIREMENTS.md frontmatter — every feature has exactly one domain. **One feature → one domain → one BDD directory.** Scenarios must assert on every user-observable side effect, even when it crosses into other features/domains (emails, notifications, analytics, downstream writes) — these are observations of the UC, not tests of those other features. See `gherkin/SKILL.md` → **Test Subject vs. Observation Surface**
   - For each UC in this feature, emit a dedicated `.feature` file at `bdd/features/{module}/{domain}/{UC-XXXX}-{uc-slug}.feature` — **one file per use case**; never merge scenarios across UCs
   - Feature-level tags (on each UC file): `@FEAT-XXXX @UC-XXXX @{domain} @{module} @{priority-tag}`. Scenario-level tags: `@SC-XXXX @{classification-tag}`. Never add a second domain tag on a scenario
   - Dedup per UC: grep `bdd/features/` for `@UC-XXXX` — if a match exists, append only new scenarios to that UC's file. If multiple files match a single `@UC-XXXX`, report inconsistent state and stop
   - Update `bdd/features/INDEX.md` (Module → Domain → UC grouping)
   - Run splitting check on any UC file exceeding 15 scenarios

4. **Report format:** The subagent must end with a structured report listing:
   - Feature files created (paths, scenario counts)
   - Any splitting performed

## Step 10: Report

Tell the user what was created:

**Specs Created (per module):**
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/REQUIREMENTS.md` — feature requirements (EARS syntax, extracted from code)
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/USE-CASES.md` — use case index
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/ARCHITECTURE.md` — enriched with implementation research
- UC files with scenario counts
- Updated `prd/FEATURES.md` with new row

**Gherkin Created:**
- Feature file paths with scenario counts
- Updated BDD indexes

Suggest next step: "Review the specs and Gherkin, then run `/m:reverse-plan FEAT-XXXX` to plan BDD wiring."
