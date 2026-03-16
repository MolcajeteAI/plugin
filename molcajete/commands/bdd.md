---
description: Configure BDD environment for this project
model: claude-opus-4-6
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(*), Task, AskUserQuestion
---

# BDD Setup

You are configuring the BDD environment for this project. You detect the tech stack, confirm settings interactively, write an extended `bdd/CLAUDE.md` config, and run the gherkin scaffold.

## Designated Agents

- `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/SKILL.md` -- invocation protocol
- **BDD Setup** (`${CLAUDE_PLUGIN_ROOT}/agents/bdd-setup.md`) -- detects tech stack

## Step 1: Check Existing Config

Read `bdd/CLAUDE.md`. If it exists and contains a `# BDD Configuration` section with an `## Extended Configuration` subsection:

Use AskUserQuestion:
- Question: "BDD configuration already exists. What would you like to do?"
- Options:
  - "Reconfigure from scratch" -- proceed to Step 2
  - "Keep current config" -- skip to Step 5

If no extended config exists, proceed to Step 2.

## Step 2: Detect Tech Stack

Launch the BDD Setup agent using the Task tool:
- Read the agent definition at `${CLAUDE_PLUGIN_ROOT}/agents/bdd-setup.md`
- Follow the invocation template from `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/references/invocation-template.md`
- The agent scans project files and returns detected values

Use the agent's output for Step 3.

## Step 3: Interactive Confirmation

Present detected values and ask the user to confirm or override each setting. Use AskUserQuestion for each batch:

**Batch 1 -- Language and BDD Framework:**
- Question: "Detected language: **{LANGUAGE}**, BDD framework: **{FRAMEWORK}**. Confirm or change?"
- Options: "{LANGUAGE} + {FRAMEWORK}" (auto-detected), "Python + behave", "Go + godog", "TypeScript + cucumber-js", "Other (specify)"

**Batch 2 -- E2E Framework:**
- Question: "E2E framework: **{E2E_FRAMEWORK}**. Confirm or change?"
- Options: "{E2E_FRAMEWORK}" (if detected), "Playwright", "Cypress", "None"
- Skip this batch if E2E_FRAMEWORK is "None" and no E2E indicators found

**Batch 3 -- Database:**
- Question: "Database driver: **{DB_DRIVER}**. DB state strategy for tests?"
- Options: "transaction-rollback (fast, requires DB connection)", "testcontainers (isolated, slower)", "truncation (simple, requires cleanup)", "none (no DB in tests)"
- Skip this batch if DB_DRIVER is "None"

**Batch 4 -- Page Object Model:**
- Only ask if E2E framework is not "None"
- Question: "Use Page Object Model pattern for E2E tests?"
- Options: "Yes", "No"

## Step 4: Write Config

Write the extended `bdd/CLAUDE.md` config. If the file exists and has a `# BDD Configuration` section, replace it entirely. If it has other content outside that section, preserve it.

Write this structure:

```markdown
# BDD Configuration

- **Format:** Standard Gherkin
- **Language:** {confirmed language}
- **Framework:** {confirmed framework}
- **Directory style:** domain-organized
- **Organization:** one feature per UC
- **Domain mapping:** (populated during scaffold)

## Extended Configuration

- **E2E framework:** {confirmed E2E framework}
- **Database driver:** {confirmed DB driver}
- **Database state strategy:** {confirmed strategy}
- **Page Object Model:** {yes | no}
```

## Step 5: Run Scaffold

Read the gherkin skill at `${CLAUDE_PLUGIN_ROOT}/skills/gherkin/SKILL.md` and execute the scaffold procedure from `${CLAUDE_PLUGIN_ROOT}/skills/gherkin/references/scaffold.md`. This creates the `bdd/` directory structure, INDEX files, and world module.

After scaffold completes, update the `# BDD Configuration` section's **Domain mapping** field with the detected domains from the scaffold procedure.

## Step 6: Report

Tell the user:
- What was configured (language, framework, E2E, DB strategy)
- What files were created
- Suggest next steps: "Use `/m:stories` to generate BDD scenarios from your requirements."

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- Follow all project conventions from CLAUDE.md.
- Do not use the word "comprehensive" in any document.
