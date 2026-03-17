---
description: Initialize product documentation (mission, tech-stack, roadmap, changelog)
model: claude-opus-4-6
allowed-tools: Read, Write, Edit, Glob, Grep, Task, AskUserQuestion
---

# Initialize Product Documentation

You are setting up the product documentation foundation for this project. Your output goes to the `prd/` directory at the project root.

## Step 1: Check Existing State

Check if `prd/` already exists. If it does, use AskUserQuestion to ask whether the user wants to:
- **Update existing documents** — read current files and refine them
- **Start fresh** — overwrite with new documents

If `prd/` does not exist, proceed to Step 2.

## Step 2: Load Context via Sub-Agents

Launch 2 parallel `Explore` sub-agents using the Task tool in a single message:

**Agent 1 — Skills and Templates** (subagent_type: `Explore`, thoroughness: "very thorough"):
- Prompt: Read the following files and return their full content:
  - `${CLAUDE_PLUGIN_ROOT}/skills/project-management/SKILL.md`
  - `${CLAUDE_PLUGIN_ROOT}/skills/project-management/references/readme-template.md`
  - `${CLAUDE_PLUGIN_ROOT}/skills/project-management/references/mission-template.md`
  - `${CLAUDE_PLUGIN_ROOT}/skills/project-management/references/tech-stack-template.md`
  - `${CLAUDE_PLUGIN_ROOT}/skills/project-management/references/roadmap-template.md`
  - `${CLAUDE_PLUGIN_ROOT}/skills/project-management/references/changelog-template.md`
  Return:
  ```
  SKILL_RULES:
  {Key rules and conventions from SKILL.md — formatting, structure, ID schemes}

  TEMPLATES:
  {Full content of each template, clearly separated by headers}
  ```

**Agent 2 — Project Context** (subagent_type: `Explore`, thoroughness: "medium"):
- Prompt: Read the following files if they exist and return a structured summary:
  - `CLAUDE.md` — project conventions
  - `README.md` — project overview
  - `package.json` — dependencies and scripts
  - `go.mod` — Go module and dependencies
  - `docker-compose.yml` — services and architecture
  Check if `prd/` directory exists and list its contents if so.
  Return:
  ```
  PROJECT_CONTEXT:
  - Project name: {name}
  - Description: {from README or package.json}
  - Stack: {detected languages, frameworks, databases}
  - Architecture: {monorepo structure, services detected}
  - Existing conventions: {key rules from CLAUDE.md}
  - PRD status: {exists with files X, Y, Z / does not exist}
  ```

Use the returned context for all subsequent steps. Do NOT read these files again yourself.

## Step 3: Strategic Interview

Conduct a structured interview using AskUserQuestion. Ask questions in focused batches (1-3 questions at a time). Cover these topics:

**Batch 1 — Vision and Problem:**
- What problem does this product solve? Who is it for?
- What is the core value proposition in one sentence?

**Batch 2 — Users:**
- Who are the primary user types? (names, roles, pain points)
- What devices/platforms do they use?

**Batch 3 — Differentiation:**
- What exists today that attempts to solve this problem?
- How is this product different/better?

**Batch 4 — Technology:**
- What technology stack is being used? (or confirm from project files)
- Any key architectural decisions already made?

**Batch 5 — Roadmap:**
- What features are being built now?
- What comes next? What's deferred to later?

Skip questions where the answer is already clear from the project context summary. Confirm pre-filled answers with the user rather than asking from scratch.

## Step 4: Generate Documents

Create the `prd/` directory and generate these files following the templates exactly:

1. **`prd/README.md`** — Master index linking all documents. Include product overview, document index, current focus, user personas, and design principles.
2. **`prd/mission.md`** — Vision statement, problem statement, target users, differentiators, success metrics, and what the product will NOT do.
3. **`prd/tech-stack.md`** — Architecture diagram (Mermaid), technology tables by layer, project structure, development commands, environment variables, standards.
4. **`prd/roadmap.md`** — Now/Next/Later tables with feature descriptions, priorities, dependencies, rationale, and roadmap principles.
5. **`prd/changelog.md`** — Initialize with domain sections based on what already exists in the codebase. If the project has existing features, describe them. If it's a fresh project, create the structure with placeholder sections.

## Step 5: Inform User

After generating all documents, tell the user:
- What files were created and where
- Suggest next steps: "Use `/m:feature` to scope your first feature, or edit the generated documents directly."

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- Follow all formatting rules from the project-management skill: no emojis, text checkboxes only, Mermaid diagrams, tables for structured data.
- Use Mermaid for the architecture diagram in tech-stack.md (not ASCII art).
- Do not use the word "comprehensive" in any document.
- Write in clear, direct English. No marketing language.
