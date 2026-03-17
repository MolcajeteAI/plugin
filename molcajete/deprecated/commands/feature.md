---
description: Scope a feature into structured requirements
model: claude-opus-4-6
allowed-tools: Read, Write, Edit, Glob, Grep, Task, AskUserQuestion
argument-hint: <feature name or description>
---

# Scope Feature Requirements

You are analyzing a feature and producing a structured requirements document. Output goes to a timestamped folder inside `prd/specs/`.

**Feature input:** $ARGUMENTS

## Critical Directives

These override every step below. No exceptions.

1. **Right over easy.** When scoping requirements and use cases, favor correctness and completeness over simplicity. Do not simplify scope to make requirements easier to define. Capture the real complexity of the feature.
2. **Fix everything you see.** If you encounter inconsistencies, gaps, or errors in existing PRD files while working, fix them.

## Step 1: Verify Product Context

Check that `prd/mission.md` and `prd/tech-stack.md` exist. If they don't, tell the user to run `/m:init` first and stop.

## Step 2: Load Context via Sub-Agents

Launch 2 parallel `Explore` sub-agents using the Task tool in a single message:

**Agent 1 — Skills and Templates** (subagent_type: `Explore`, thoroughness: "very thorough"):
- Prompt: Read the following files and return their full content:
  - `${CLAUDE_PLUGIN_ROOT}/skills/project-management/SKILL.md`
  - `${CLAUDE_PLUGIN_ROOT}/skills/project-management/references/requirements-template.md`
  Return:
  ```
  SKILL_RULES:
  {Key rules and conventions from SKILL.md — formatting, ID schemes, structure}

  TEMPLATE:
  {Full content of requirements-template.md}
  ```

**Agent 2 — Project and Codebase Context** (subagent_type: `Explore`, thoroughness: "very thorough"):
- Prompt: Read the following files and return a structured summary:
  - `prd/mission.md` — vision, users, metrics
  - `prd/tech-stack.md` — architecture, stack choices
  - `prd/roadmap.md` — current priorities (if exists)
  - Per-task changelog files in `prd/specs/*/plans/changelog-*.md` — what's already built (scan all feature folders)
  - `CLAUDE.md` — project conventions
  Also scan for `**/README.md` files in the codebase (excluding `node_modules/`, `prd/`). Read frontmatter of README.md files in directories related to the feature being scoped.
  Return:
  ```
  PRD_CONTEXT:
  - Mission: {one-line summary}
  - Target users: {user types}
  - Stack: {relevant stack}
  - Current roadmap priorities: {now/next items, or "No roadmap found"}
  - Already built: {summary from per-task changelog files, or "No changelog files found"}

  CODEBASE_CONTEXT:
  {Summary of existing modules, data structures, and processes from README scans that the feature may interact with}

  CONVENTIONS:
  {Key project conventions from CLAUDE.md relevant to requirements writing}
  ```

Use the returned context for all subsequent steps. Do NOT read these files again yourself.

## Step 3: Identify Feature

If `$ARGUMENTS` is provided, use it as the feature name/description. If not, use AskUserQuestion to ask what feature the user wants to scope.

## Step 4: Requirements Interview

> Remember: **Right over easy.** Scope decisions must favor correctness over simplicity. Capture the real complexity of the feature — do not simplify to make requirements easier to define.

Conduct a structured interview using AskUserQuestion. Ask in focused batches:

**Batch 1 — Feature Scope:**
- What should this feature do? (high-level description)
- Which user types does it serve?

**Batch 2 — Use Cases:**
- What are the main use cases? (actions users perform)
- What are the preconditions and postconditions for each?

**Batch 3 — Functional Details:**
- What are the key functional requirements for each use case?
- Any specific validation rules, error handling, or edge cases?

**Batch 4 — Technical Considerations:**
- Does this require new database tables or schema changes?
- Any external integrations or API changes?
- Security or performance concerns?

**Batch 5 — Scope Boundaries:**
- What is explicitly in scope for this feature?
- What is out of scope or deferred?

Skip questions where the answer is obvious from context. Pre-fill from existing documents where possible.

## Step 5: Generate Requirements

> Remember: **Right over easy.** Requirements must reflect the correct solution, not the easiest one to specify. Include edge cases, error scenarios, and non-functional requirements even when they add complexity.

Create a timestamped feature folder and requirements document:

1. Generate the folder name: `prd/specs/YYYYMMDD-HHmm-{slug}/` where the timestamp is the current time in UTC and the slug is derived from the feature name (lowercase, underscores).
2. Compute the feature tag from the folder timestamp using the base-62 algorithm described in the project-management skill (ID Scheme section).
3. Write `requirements.md` following the requirements template exactly.
4. Ensure all IDs follow the scheme: UC-{tag}-001, US-{tag}-001, FR-{tag}-001, NFR-{tag}-001 (sequential within this document, using the computed tag).
5. Map functional requirements to use cases in section headers.
6. Use text checkboxes for acceptance criteria and success criteria.

## Step 6: Inform User

After generating the document, tell the user:
- What file was created and where
- Summary of use cases and requirement counts
- Suggest next steps: "Use `/m:spec {folder-name}` to create the technical specification."

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- Follow all formatting rules from the project-management skill: no emojis, text checkboxes only, tables for structured data, consistent ID scheme.
- Do not use the word "comprehensive" in any document.
- One requirements.md per feature folder. Do not create other files in this step.
