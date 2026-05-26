---
description: Create or update features, use cases, and scenarios from free-form natural language
model: claude-opus-4-6
argument-hint: <freeform spec description>
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
  - WebSearch
  - WebFetch
---

# Spec Command

You are the broadest spec-authoring command. Unlike the granular commands (`feature`, `usecase`) which operate on a single entity, you take free-form natural language and orchestrate creation or update of features and use cases — potentially spanning multiple entities in a single invocation. Scenarios live inline inside each use case.

**All user interaction MUST use the AskUserQuestion tool.** Never ask questions as plain text in your response. This keeps you in control of the conversation flow.

## Step 1: Load Skills

Read all three authoring skills since this command can touch any layer:

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/SKILL.md` — EARS syntax, Fit Criteria, feature interview
2. `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md` — flat inline scenario structure, UC interview, E2E Testing Philosophy
3. `${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/SKILL.md` — ID generation rules

Follow these skills' rules for all subsequent steps. In particular, follow the E2E Testing Philosophy from the usecase-authoring skill: all scenarios assume E2E execution against real infrastructure, no mocked databases or stubbed services. Write specs as if everything is testable end-to-end.

## Step 2: Verify Prerequisites

Check that `prd/PROJECT.md` and `prd/MODULES.md` both exist.

If either is missing, tell the user:

"Project foundation not found. Run `/m:setup` first to create PROJECT.md and MODULES.md."

Then stop. Do not proceed.

## Step 3: Load Full Project Context

Read all project-level files, the domain registry, and every existing feature's specs. This is the key difference from granular commands — spec needs the full PRD picture.

**Project-level files:**
- `prd/PROJECT.md` — project description (required)
- `prd/TECH-STACK.md` — technology choices (if exists)
- `prd/ACTORS.md` — system actors (if exists)
- `prd/MODULES.md` — module registry (required)
- `prd/DOMAINS.md` — domain tag registry (if exists)

**Per-domain files:**
- `prd/FEATURES.md` — features across all domains

**Per-feature files:** For every feature listed in each domain's FEATURES.md, read:
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/REQUIREMENTS.md`
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/USE-CASES.md`

For large projects with many features, use Agent sub-agents to parallelize reading.

## Step 4: Research Context

Read the headless-research skill:

```
Read: ${CLAUDE_PLUGIN_ROOT}/research/skills/headless-research/SKILL.md
```

Check if `$ARGUMENTS` references a research document (a path matching `research/*.md`).
If so, pass it to the headless-research skill as a user-provided reference.

Otherwise, use the freeform description from `$ARGUMENTS` as the research query.

Follow the skill's workflow (check user reference → scan existing → run agents if needed).

Use the resulting context brief to inform subsequent extraction, classification, and interview steps (better requirement suggestions, awareness of existing patterns, up-to-date approaches).

## Step 5: Collect Input

If `$ARGUMENTS` is not empty, use it as the free-form input.

If `$ARGUMENTS` is empty, use AskUserQuestion:
- Question: "Describe what you want to spec out. You can mention new features, new use cases for existing features, changes to existing features, or any combination.\n\n**Examples:**\n- \"Add user authentication with email/password login and OAuth support\"\n- \"Add a password reset flow to FEAT-0S9A and create a new audit logging feature\"\n- \"Update the checkout feature to support gift cards and add a returns workflow\""
- Header: "Spec Input"

## Step 6: Analyze and Classify

Parse the free-form text against the loaded PRD context. Classify each entity the user described into one of these categories:

| Category | Trigger | Action |
|----------|---------|--------|
| **New Feature** | Describes capability not covered by any existing feature | Run Domain Resolution (feature-authoring skill) to assign target domain, then create feature dir + REQUIREMENTS.md + USE-CASES.md + ARCHITECTURE.md, add FEATURES.md row |
| **New Use Case** | Describes a workflow belonging to an existing feature | Create UC file in existing feature, add row to USE-CASES.md |
| **Modified Feature** | Adds or changes requirements of an existing feature | Update REQUIREMENTS.md (new FRs, NFRs, acceptance criteria) |
| **Modified Use Case** | Adds or changes scenarios in an existing UC | Update UC file (new/changed scenarios), increment version, set status to dirty |

For each entity, extract as much structured content as possible:

**New Features:** name, non-goals, actors, functional requirements (EARS syntax), non-functional requirements, acceptance criteria, potential use cases.

**New Use Cases:** name, objective, primary actor, preconditions, trigger, scenarios (Given/Steps/Outcomes/Side Effects).

**Modified Features:** which FEAT-XXXX, what changes to REQUIREMENTS.md.

**Modified Use Cases:** which UC-XXXX, new or changed scenarios.

## Step 7: Present Spec Plan

Use a single AskUserQuestion to show the full picture before any changes:

- Question: Format as a structured plan showing:
  - **New Features** — list with name, target domain, and one-line description each
  - **New Use Cases** — list with parent feature, name, and one-line description each
  - **Modified Features** — list with FEAT-XXXX and summary of changes
  - **Modified Use Cases** — list with UC-XXXX and summary of changes

  Only include sections that have entries.

- Header: "Spec Plan"
- Options: "Yes, proceed" / "Edit plan" / "Cancel"

If the user selects "Edit plan", use AskUserQuestion to collect corrections and re-present the plan.

If the user selects "Cancel", stop.

## Step 8: Streamlined Interviews

For each entity in the spec plan, present a consolidated review. Unlike the granular commands which go section-by-section, spec presents all sections at once since the user already provided substantial context.

### 7.1 Module and Domain Resolution for New Features

For each new feature in the spec plan, run the feature-authoring skill's Module and Domain Resolution before proceeding to interviews:

1. Read `prd/MODULES.md` for modules, read `prd/DOMAINS.md` for domains
2. If one module, use automatically; if multiple, ask via AskUserQuestion: "Which modules does this feature apply to?" (multi-select)
3. Ask which domain this feature belongs to (from DOMAINS.md). Single-select.
4. Check FEATURES.md for existing features this new feature depends on
5. Include the resolved module and domain in the Step 7 spec plan presentation so the user sees where each feature will be created

### 8.1 New Features

For each new feature, present all sections in one view via AskUserQuestion:

- Question: "**New Feature: {name}**\n\n**Non-Goals:**\n{non_goals or 'None identified'}\n\n**Actors:**\n{actors}\n\n**Functional Requirements (EARS):**\n{requirements}\n\n**Non-Functional Requirements:**\n{nfrs or 'None identified'}\n\n**Acceptance Criteria:**\n{acceptance}\n\nDoes this look correct?"
- Header: "Feature: {name}"
- Options: "Looks good" / "Edit" (user specifies which section to change via Other)

If the user selects "Edit", ask which section to change, collect the correction, and re-present the full view.

### 8.2 New Use Cases

For each new use case, present all sections in one view via AskUserQuestion:

> **Multi-module scoping:** If the parent feature exists in 2+ modules, the UC must narrate from the selected module's perspective -- actor, trigger, preconditions, and scenarios scoped to that module's boundary. See the Module-Scoped Use Cases section in the usecase-authoring skill.

- Question: "**New Use Case: {name}**\nParent feature: {FEAT-XXXX}\n\n**Objective:** {objective}\n\n**Actor:** {actor}\n\n**Preconditions:**\n{preconditions}\n\n**Trigger:** {trigger}\n\n**Scenarios:**\n{for each scenario:\n  **Scenario: {name}**\n  Given: {given}\n  Steps: {steps}\n  Outcomes: {outcomes}\n  Side Effects: {side_effects}\n}\n\nDoes this look correct?"
- Header: "Use Case: {name}"
- Options: "Looks good" / "Edit" (user specifies what to change via Other)

If the user selects "Edit", collect the correction and re-present. After confirmation, ask:

- Question: "Would you like to add another scenario to this use case?"
- Header: "More Scenarios?"
- Options: "Yes, I'll describe one" (user provides via Other) / "No, that's all"

### 8.3 Modified Features

For each modified feature, present a diff-style view via AskUserQuestion:

- Question: "**Updating: {FEAT-XXXX} — {feature name}**\n\n**Changes to REQUIREMENTS.md:**\n{diff-style showing additions/changes}\n\nDoes this look correct?"
- Header: "Update: {FEAT-XXXX}"
- Options: "Looks good" / "Edit" (user specifies what to change via Other)

### 8.4 Modified Use Cases

For each modified use case, present a diff-style view via AskUserQuestion:

- Question: "**Updating: {UC-XXXX} — {use case name}**\n\n**Changes:**\n{new/changed scenarios shown diff-style}\n\nVersion will increment from {N} to {N+1}. Status will be set to dirty.\n\nDoes this look correct?"
- Header: "Update: {UC-XXXX}"
- Options: "Looks good" / "Edit" (user specifies what to change via Other)

## Step 9: Generate IDs

After all interviews are confirmed, count the total number of new IDs needed (features + use cases + scenarios) and batch-generate them:

```bash
node ${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/scripts/generate-id.js {total_count}
```

Assign prefixes from the output lines in order:
- `FEAT-` for new features
- `UC-` for new use cases
- `SC-` for new scenarios
- `FR-` for functional requirements
- `NFR-` for non-functional requirements
- `US-` for user stories
- `ADR-` for architecture decisions

## Step 10: Write PRD Documents

Write in dependency order so that parent structures exist before children.

### 11.1 New Features

For each new feature:

For each selected module, create the feature directory:

> **Multi-module scoping:** If this feature spans 2+ modules, each module's REQUIREMENTS.md must be scoped to that module's actors, FRs, Non-Goals, NFRs, and Acceptance. Do not copy identical content across modules. See the Module-Scoped Content section in the feature-authoring skill.

1. Create the directory structure:
   ```bash
   mkdir -p prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases
   ```

2. Read `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/templates/REQUIREMENTS-template.md`
   Write `prd/modules/{module}/features/FEAT-XXXX-{slug}/REQUIREMENTS.md` filled with confirmed content. Follow section order from the skill: name + objective, Non-Goals, Actors, UI (only if provided), Functional Requirements (EARS + Fit Criteria), Non-Functional Requirements, Acceptance.

3. Read `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/templates/USE-CASES-template.md`
   Write `prd/modules/{module}/features/FEAT-XXXX-{slug}/USE-CASES.md` with an empty use case table.

4. Read `${CLAUDE_PLUGIN_ROOT}/spec/skills/architecture/templates/ARCHITECTURE-template.md`
   Write `prd/modules/{module}/features/FEAT-XXXX-{slug}/ARCHITECTURE.md` scaffold.

5. Edit `prd/FEATURES.md` — add a new row:
   ```
   | FEAT-XXXX | {Feature Name} | {One-sentence description} | pending | @FEAT-XXXX | [features/FEAT-XXXX-{slug}/](features/FEAT-XXXX-{slug}/) |
   ```

### 11.2 Modified Features

For each modified feature:
- Edit `prd/modules/{module}/features/FEAT-XXXX-{slug}/REQUIREMENTS.md` with the confirmed changes (new FRs, NFRs, acceptance criteria).

### 11.3 New Use Cases

For each new use case:

> **Multi-module scoping:** If the parent feature exists in 2+ modules, scope the UC to the selected module's perspective -- actor, trigger, scenarios, and side effects narrate from that module's boundary. See the Module-Scoped Use Cases section in the usecase-authoring skill.

1. Read `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/templates/UC-template.md`

2. Write `prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}.md` with:
   - YAML frontmatter: id (UC-XXXX), name, feature (FEAT-XXXX), status (pending), version (1), actor
   - Title: `# UC-XXXX: {Use Case Name}`
   - Objective blockquote
   - Preconditions section
   - Trigger section
   - All confirmed scenarios in flat structure — each scenario preceded and followed by a `---` horizontal rule (including after the last scenario), each with SC-XXXX ID, Given/Steps/Outcomes/Side Effects

3. Add a new row to `prd/modules/{module}/features/FEAT-XXXX-{slug}/USE-CASES.md`:
   ```
   | UC-XXXX | {Use Case Name} | pending | {One-sentence description} | [UC-XXXX-{slug}.md](use-cases/UC-XXXX-{slug}.md) |
   ```

### 11.4 Modified Use Cases

For each modified use case:
- Edit the UC file with new/changed scenarios.
- Increment `version` in YAML frontmatter.

## Step 11: Report

Tell the user a structured summary of everything created and updated:

**Created:**
- New features (FEAT-XXXX) with file paths
- New use cases (UC-XXXX) with file paths and inline scenario counts

**Updated:**
- Modified features (FEAT-XXXX) with change summary
- Modified use cases (UC-XXXX) with change summary
- Updated FEATURES.md rows
- Updated USE-CASES.md rows

Suggest next steps based on what was created:
- If new features without UCs: "Use `/m:usecase FEAT-XXXX` or `/m:spec` to add use cases."
- If everything is specified: "Use `/m:plan UC-XXXX` to generate an implementation plan."
