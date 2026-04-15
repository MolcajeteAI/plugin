---
description: Generate Gherkin feature files from a use case
model: claude-opus-4-6
argument-hint: <UC-XXXX>
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

# Generate Gherkin Scenarios

You are generating Gherkin feature files from an existing use case. You will read the UC file and construct `.feature` content using the Gherkin Mapping table.

**Use case argument:** $ARGUMENTS

**All user interaction MUST use the AskUserQuestion tool.** Never ask questions as plain text in your response.

## Step 1: Load Skills

Read both skills that govern this command:

1. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/gherkin/SKILL.md` — generation rules, tagging, step writing, scaffold, detection, index maintenance
2. Read `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md` — Gherkin Mapping table only (the table that maps UC elements to Gherkin output)

Follow these skills' rules for all subsequent steps.

## Step 2: Verify Prerequisites

1. Parse `$ARGUMENTS` for a `UC-XXXX` token. If missing or does not match the pattern `UC-` followed by an alphanumeric code, tell the user:

   "Usage: `/m:scenario UC-XXXX`. Provide a valid use case ID."

   Then stop.

2. Glob `prd/modules/*/features/*/use-cases/UC-XXXX-*.md` (substituting the actual ID) to find the UC file. If not found, tell the user:

   "Use case {UC-XXXX} not found. Check the ID and try again."

   Then stop.

3. Extract the parent `FEAT-XXXX` from the path (the directory name under `features/`) and the module from the path (the directory name under `prd/modules/`).

4. Verify `prd/FEATURES.md` exists. If missing, tell the user:

   "Run `/m:setup` first — DOMAINS.md and FEATURES.md are required."

   Then stop.

5. Verify FEAT-XXXX exists in `prd/FEATURES.md`. If not found, tell the user:

   "Feature {FEAT-XXXX} not found in FEATURES.md. Check the ID and try again."

   Then stop.

## Step 3: Load Project Context

Read these files to understand the project, feature, and use case:

- `prd/PROJECT.md` — what this project is
- `prd/TECH-STACK.md` — technology context (if exists)
- `prd/ACTORS.md` — known actors (if exists)
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/REQUIREMENTS.md` — feature requirements
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/ARCHITECTURE.md` — architecture context (if exists)
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}.md` — the target use case

## Step 4: Parse Use Case

Extract from the UC file:

**YAML frontmatter:**
- `id` — the UC-XXXX ID
- `name` — the use case name
- `feature` — parent FEAT-XXXX
- `actor` — primary actor
- `tag` — the @UC-XXXX tag

**Gherkin Tags line (Feature-level):** `@FEAT-XXXX @UC-XXXX @{domain} @{module} @{priority-tag}` — the `.feature` file represents this UC.

**Preconditions:** These become Gherkin `Background: Given` clauses.

**Trigger:** Context for constructing `When` clauses.

**Scenarios:** Each `### SC-XXXX:` block:
- **Given** → `Given`/`And` clauses (after Background)
- **Steps** → `When`/`And` clauses (decompose compound steps into one action per clause)
- **Outcomes** → `Then` clauses (must use exact assertion values)
- **Side Effects** (positive) → `And` clauses
- **Side Effects** ("No ...") → `And no ...` clauses

If no scenarios are found in the UC file, tell the user:

"{UC-XXXX} has no scenarios. Run `/m:usecase` to add scenarios first."

Then stop.

## Step 5: Scaffold Setup

Run the scaffold procedure from `${CLAUDE_PLUGIN_ROOT}/shared/skills/gherkin/references/scaffold.md` (steps 2a–2h):

- Check for existing scaffold, create if missing
- Detect modules, language, format
- Create INDEX.md files and world module
- Persist BDD settings to `.molcajete/settings.json`
- Validate existing indexes, rebuild if drift detected

## Step 6: Module/Domain and Tag Selection

### 6.1 Module and Domain Resolution

Read the parent feature's REQUIREMENTS.md frontmatter:
- `module:` → `{module}` directory segment.
- `domain:` → `{domain}` directory segment. Every feature has exactly one domain — this is the BDD path segment.

**One feature → one domain → one BDD directory.** The test *subject* is this one UC; the *observation surface* is everything the user experiences as a consequence. Scenarios must assert on every user-observable side effect, even when it crosses into other features/domains (emails, notifications, analytics, downstream writes) — these are observations of this UC, not tests of those other features. See `gherkin/SKILL.md` → **Test Subject vs. Observation Surface**.

The target `.feature` file path is `bdd/features/{module}/{domain}/{UC-XXXX}-{uc-slug}.feature`.

Confirm with the user:
- Question: "Place this UC's .feature file at:\n\n`bdd/features/{module}/{domain}/{UC-XXXX}-{uc-slug}.feature`\n\nExisting UC files in this tree: {list of existing `bdd/features/{module}/{domain}/*.feature`}"
- Header: "Module/Domain"
- Options: "Confirm" / "Override" (user provides via Other)

### 6.2 Classification Tags

Propose tags for each scenario based on its nature:
- First scenario / happy-path → `@smoke`
- Error / edge case → `@regression`
- Security / data integrity → `@critical`

Also propose a feature-level priority tag.

Use AskUserQuestion:
- Question: "Proposed tags:\n\n**Feature-level:** `@FEAT-XXXX @UC-XXXX @{domain} @{module} @{priority-tag}`\n\n{for each scenario: `@SC-XXXX @{classification-tag}` — {scenario name}}\n\nDo these look correct?"
- Header: "Tags"
- Options: "Yes, looks good" / "Edit" (user corrects via Other)

## Step 6b: E2E Step Quality Check

Before generating Gherkin, scan the parsed UC steps for mock-dependent anti-patterns per the gherkin skill's E2E-First Step Writing rules:

- Check Given/Steps/Outcomes/Side Effects for references to mocks, stubs, fakes, spies, or test doubles
- If mock-dependent language is found, automatically rewrite to E2E patterns:
  - "Given the user service returns a verified user" -> "Given user alice exists with verified email"
  - "When we call the mocked payment endpoint" -> "When alice submits a payment of $25"
  - "Then the mock was called once" -> "Then the payments table has exactly 1 row for alice"
- This is a Gherkin quality rule applied silently -- no AskUserQuestion needed

## Step 7: Generate Gherkin

### 7.1 Construct Feature File Content

Using the Gherkin Mapping table from the usecase-authoring skill:

- **Feature-level tags:** `@FEAT-XXXX @UC-XXXX @{domain} @{module} @{priority-tag}`
- **Feature line:** `Feature: {UC Name}` with description from UC objective
- **Background:** from UC Preconditions (each precondition becomes a `Given` / `And` clause)
- **Each scenario:**
  - Tags: `@SC-XXXX @{classification-tag}`. Never add a second domain tag — one feature, one domain.
  - `Scenario: {Scenario Name}`
  - `Given` / `And` from scenario Given field
  - `When` / `And` from scenario Steps field (one action per clause)
  - `Then` from scenario Outcomes field (exact assertion values)
  - `And` from positive Side Effects — assert on every user-observable side effect, even when it crosses into other features/domains (emails, notifications, analytics, downstream writes). These are observations of this UC, not tests of those other features. See `gherkin/SKILL.md` → **Test Subject vs. Observation Surface**
  - `And no ...` from "No ..." Side Effects

Follow the step writing rules from the gherkin skill (declarative Given, exact Then, parameterized patterns). Use `Scenario Outline` + `Examples` when multiple scenarios test the same flow with different inputs.

### 7.2 Preview

Use AskUserQuestion to show the full generated Gherkin for review:
- Question: "Here's the generated Gherkin:\n\n```gherkin\n{full feature file content}\n```\n\nDoes this look correct?"
- Header: "Preview"
- Options: "Yes, looks good" / "Edit" (user corrects via Other)

### 7.3 Check for Existing UC File

Grep `bdd/features/` for `@UC-XXXX` — the tag is unique to this UC, so the match (if any) resolves to a single `.feature` file. If found, follow the dedup procedure from `${CLAUDE_PLUGIN_ROOT}/shared/skills/gherkin/references/generation.md` step 3-pre:
- Skip exact duplicate scenarios inside that UC's file.
- Warn on near-duplicates.
- Append only new scenarios to the existing UC file — never merge scenarios across UCs.

If multiple files match, report the inconsistent state and stop: the UC should own exactly one `.feature` file.

### 7.4 Write Feature File

Write the `.feature` file to `bdd/features/{module}/{domain}/{UC-XXXX}-{uc-slug}.feature`. Create `bdd/features/{module}/{domain}/` if missing. If appending to this UC's existing file, use the Edit tool to append new scenarios at the end; do not create a second file for the same UC.

## Step 8: Update Indexes

Follow `${CLAUDE_PLUGIN_ROOT}/shared/skills/gherkin/references/generation.md` step 3d — update `bdd/features/INDEX.md`.

## Step 9: Splitting Check

Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/gherkin/references/splitting.md`. If the scenario count in the target feature file exceeds 15, run the splitting procedure.

## Step 10: Report

Tell the user what was created:

- Feature file path + scenario count
- Updated INDEX.md files

Suggest next step: "Use `/m:plan UC-XXXX` to generate an implementation plan, or `/m:scenario UC-YYYY` for another use case."
