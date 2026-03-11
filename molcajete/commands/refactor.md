---
description: Analyze the impact of a change to existing code and produce scoped requirements
model: claude-opus-4-6
allowed-tools: Read, Write, Edit, Glob, Grep, Task, WebSearch, WebFetch, Bash(*), AskUserQuestion
argument-hint: <what you want to change, e.g. "add error monitoring to the frontend">
---

# Refactor

**Input:** $ARGUMENTS

## Designated Agents

This command delegates to two agents in sequence:

- `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/SKILL.md` — invocation protocol and handoff patterns
- **Researcher** (`${CLAUDE_PLUGIN_ROOT}/agents/researcher.md`) — impact analysis (Refactor Impact mode)
- **Spec Writer** (`${CLAUDE_PLUGIN_ROOT}/agents/spec-writer.md`) — requirements generation from impact analysis

**Chain:** Researcher -> Spec Writer (see handoff protocol for context passing)

**What this command keeps:** Product context verification, folder creation, file writing.

## Step 1: Verify Product Context

Check that `prd/mission.md` and `prd/tech-stack.md` exist. If they don't, tell the user to run `/m:init` first and stop.

## Step 2: Read Skills

Read the research-methods skill and the project-management skill:

```
Read: ${CLAUDE_PLUGIN_ROOT}/skills/research-methods/SKILL.md
Read: ${CLAUDE_PLUGIN_ROOT}/skills/project-management/SKILL.md
```

## Step 3: Run Impact Analysis

Execute the research skill in **Refactor Impact** mode — skip Step 1 classification and go directly to Step 2r (Parse Input).

Use `$ARGUMENTS` as the change description for Step 2r. Follow the skill's Refactor Impact Orchestration (Steps 2r-4r) exactly.

**Save path:** Do not save yet. Hold the impact analysis document in memory for Step 4.

## Step 4: Create Feature Folder and Write Files

Using the project-management skill's conventions:

1. Compute folder name: `prd/specs/YYYYMMDD-HHmm-{slug}/` (current time UTC, slug from change description)
2. Compute the feature tag using the base-62 algorithm from the project-management skill
3. Create the folder
4. Write `impact.md` (the document produced in Step 3) into the folder

## Step 5: Generate Requirements

Read the requirements template:
```
Read: ${CLAUDE_PLUGIN_ROOT}/skills/project-management/references/requirements-template.md
```

Generate `requirements.md` in the same folder, **derived from the impact analysis**:

- Each phase from the Suggested Order of Changes becomes a **use case** (UC)
- Each affected module/directory becomes **functional requirements** (FR) grouped under its use case
- New packages and configuration changes become their own FR
- Test updates become their own UC
- Use the same ID scheme as `/m:feature`: UC-{tag}-001, FR-{tag}-001, etc.
- Reference `impact.md` for file-level details: "See impact.md, {Module} section"

## Step 6: Inform User

Tell the user:
- What folder was created and what's in it (impact.md, requirements.md)
- Summary: total files affected, number of use cases, estimated complexity
- **Next step:** "Use `/m:spec {folder-name}` to create the technical specification."

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- The research skill is the single source of truth for the impact template, agent prompts, and writing style.
- Do not use the word "comprehensive" in any document.
- Never stage files or create commits — the user manages git.
