---
description: Create or update features and use cases (with inline scenarios) from free-form natural language
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

The single spec-authoring entry point. Takes free-form natural language and creates or updates features, use cases, and inline scenarios — across any number of entities in one invocation.

**Use AskUserQuestion for all user interaction.** Never plain-text questions.

## Step 1: Load Skills

Read in one batch:

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md`
3. `${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/SKILL.md`

## Step 2: Verify Prerequisites

`prd/PROJECT.md` and `prd/MODULES.md` must exist. If missing: "Project foundation not found. Run `/m:setup` first." Stop.

## Step 3: Load PRD Context

Read in parallel:

- Project-level: `prd/PROJECT.md`, `prd/TECH-STACK.md`, `prd/ACTORS.md`, `prd/MODULES.md`, `prd/DOMAINS.md`, `prd/FEATURES.md` (skip missing optional files)
- Per-feature: For every feature in FEATURES.md, read `prd/modules/{module}/features/FEAT-XXXX-{slug}/REQUIREMENTS.md` and `USE-CASES.md`. Parallelize aggressively; on very large projects launch one Explore subagent per domain.

## Step 4: Research (optional)

If `$ARGUMENTS` references `research/*.md`, load `${CLAUDE_PLUGIN_ROOT}/research/skills/headless-research/SKILL.md` and pass it the reference. Otherwise use the freeform input as the research query if the topic is new and non-obvious. Skip research for small edits.

## Step 5: Collect Input

If `$ARGUMENTS` is empty, ask via AskUserQuestion: "Describe what to spec out — new features, new use cases for existing features, edits to existing features or UCs, or any combination."

## Step 6: Classify and Plan

Parse the free-form text against PRD context. Classify each entity into:

| Category | Trigger | Action |
|----------|---------|--------|
| **New Feature** | Capability not in any existing feature | Resolve module + domain; create feature dir + REQUIREMENTS.md + USE-CASES.md + ARCHITECTURE.md; add FEATURES.md row |
| **New Use Case** | Workflow belonging to an existing feature | Create UC file with inline scenarios; add USE-CASES.md row |
| **Modified Feature** | Adds/changes requirements | Update REQUIREMENTS.md (new FRs, NFRs, acceptance criteria) |
| **Modified Use Case** | Adds/changes scenarios | Update UC file; increment version; status → dirty |

For new features, resolve module + domain per the feature-authoring skill's Module and Domain Resolution.

Present the full plan via a single AskUserQuestion (New Features, New UCs, Modified Features, Modified UCs — only sections that have entries). Options: "Proceed" / "Edit" (Other) / "Cancel".

## Step 7: Streamlined Reviews

For each entity, present a consolidated review via AskUserQuestion. Show all sections at once (not one at a time — the user already gave substantial context). For new entities, present full content for confirmation; for modifications, present a diff-style view with version-bump notice.

Follow the multi-module rules from the authoring skills when a feature spans 2+ modules.

For each new UC, after confirming the UC, ask once: "Add another scenario?" — loop until no.

## Step 8: Generate IDs

Count total new IDs (features + use cases + scenarios + FRs + NFRs + USs). One batch call:

```bash
node ${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/scripts/generate-id.js {total_count}
```

Assign prefixes in order.

## Step 9: Write PRD Documents

Write in dependency order: parents before children.

**New Features** (per selected module):
1. `mkdir -p prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases`
2. Write REQUIREMENTS.md (from template, with module + domain frontmatter; follow feature-authoring section order)
3. Write empty USE-CASES.md
4. Write ARCHITECTURE.md scaffold from `${CLAUDE_PLUGIN_ROOT}/spec/skills/architecture/templates/ARCHITECTURE-template.md`
5. Append FEATURES.md row

**Modified Features:** Edit REQUIREMENTS.md.

**New Use Cases:**
1. Write `prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}.md` (frontmatter: id, name, feature, status: pending, version: 1, actor; title; objective; preconditions; trigger; inline scenarios with `---` separators)
2. Append USE-CASES.md row

**Modified Use Cases:** Edit the UC file; increment frontmatter `version`; never change ID.

## Step 10: Report

Tell the user what was created and updated. Suggest next step: "Use `/m:plan UC-XXXX` to generate an implementation plan." If testability signals were detected in any new scenario (external APIs without sandbox, time/randomness, env-flag branches), list them as **Testability Notes** with category, for the user to record in ARCHITECTURE.md `## Testing Decisions`.
