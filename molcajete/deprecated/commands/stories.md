---
description: Generate BDD scenarios and step definitions for a feature
model: claude-opus-4-6
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(*), Task, AskUserQuestion
argument-hint: <UC-ID like "UC-0KTg-001", feature name, or description>
---

# Generate BDD Scenarios

You are a BDD scenario generator. You create Gherkin feature files and step definitions in the project's `bdd/` directory.

**Target feature:** $ARGUMENTS

## Step 1: Parse Argument

Determine what the user is asking for by evaluating `$ARGUMENTS` in this order:

### 1a. Empty Argument

If `$ARGUMENTS` is empty or blank, use AskUserQuestion:
- Question: "What feature should I generate scenarios for?"
- Header: "Feature"
- Options:
  - "Enter a use case ID (e.g., UC-0KTg-001)" — user provides a UC-ID via the "Other" option
  - "Enter a feature name or description" — user provides a name via the "Other" option
- multiSelect: false

Use the user's response as the argument and re-evaluate from step 1b.

### 1b. Use Case ID

If the argument matches the regex `/^UC-[A-Za-z0-9]{4}-\d{3}$/`:

1. Search `prd/specs/*/requirements.md` for the matching UC-ID section.
2. If found, read the matching `requirements.md` and `spec.md` to extract scenario context (FR-0KTg-014):
   - **From requirements.md:** Use case title, actors, preconditions, main flow steps, alternative flows, exception flows, acceptance criteria, and validation rules
   - **From spec.md:** Data models, API contracts, edge cases, security constraints, and integration points
   - Store this extracted context — it will be used in Step 3 to generate implementation-specific scenarios
3. If NOT found, warn the user: "UC-ID `{argument}` not found in any spec." Then use AskUserQuestion:
   - Question: "How should I proceed?"
   - Header: "UC not found"
   - Options:
     - "Treat as a generic feature name" — proceed to step 1d (Generic Name path)
     - "Cancel" — stop execution
   - multiSelect: false

### 1c. Existing Feature Name

If `bdd/features/INDEX.md` exists, read it and check whether the argument (converted to kebab-case) matches any `{feature-name}` portion of a feature entry's file path (e.g., `auth/user-authentication.feature` → match against `user-authentication`).

If a match is found:
1. Read the existing feature file listed in INDEX.md.
2. Prepare to append new scenarios to it (do not overwrite).

### 1d. Generic Name

If the argument did not match steps 1b or 1c, treat it as a generic feature name (FR-0KTg-038). Proceed to Step 2 (scaffold), then to Step 2-exp (exploration) before Step 3.

## Step 2: Ensure BDD Scaffold

Read the following skill files, then follow the scaffold procedure:
- `${CLAUDE_PLUGIN_ROOT}/skills/gherkin/SKILL.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/gherkin/references/scaffold.md`

This step runs on every invocation. It ensures the `bdd/` directory structure exists and that INDEX.md files are in sync with the file system. If the scaffold already exists and indexes are in sync, this step completes instantly.

## Step 2-exp: Explore Codebase for Generic Name

This step runs **only** when the argument is a generic name (Step 1d path). If the argument was a UC-ID (Step 1b) or an existing feature (Step 1c), skip this step entirely and proceed to Step 3.

Read the exploration procedure and follow it:
- `${CLAUDE_PLUGIN_ROOT}/skills/gherkin/references/exploration.md`

## Step 3: Generate Scenarios

Read the following skill files, then follow the generation procedure:
- `${CLAUDE_PLUGIN_ROOT}/skills/gherkin/SKILL.md` (if not already loaded)
- `${CLAUDE_PLUGIN_ROOT}/skills/gherkin/references/generation.md`

This step runs after the scaffold is ensured. It uses the conventions detected in Step 2 (language, format) to generate a feature file and step definitions, then updates both INDEX.md files.

### Step 3 — Splitting Check

After generation and indexing, if the target feature file has more than 15 scenarios, read and follow the splitting procedure:
- `${CLAUDE_PLUGIN_ROOT}/skills/gherkin/references/splitting.md`

## Summary Output

After every successful invocation, display a structured summary:

```
## BDD Generation Summary

| Field              | Value                                          |
|--------------------|------------------------------------------------|
| Feature file       | `bdd/features/{domain}/{feature-name}.feature` |
| Action             | Created / Updated / Split into directory       |
| Scenarios added    | {count}                                        |
| Steps reused       | {count} (from existing INDEX.md entries)       |
| Steps created      | {count} (new step definitions)                 |
| Index files updated| features/INDEX.md, steps/INDEX.md              |

**Run tests:**
{language-specific command, e.g.:}
- Python: `behave bdd/features/{domain}/{feature-name}.feature`
- Go: `godog bdd/features/{domain}/{feature-name}.feature`
- TypeScript: `npx cucumber-js bdd/features/{domain}/{feature-name}.feature`
```

## Error Handling

| Scenario | Handling |
|----------|----------|
| Empty argument | Use AskUserQuestion to ask what feature to generate (see Step 1a) |
| UC-ID not found in specs | Warn user with the exact UC-ID. Offer to treat as generic name or cancel (see Step 1b) |
| Mixed language files in `bdd/steps/` | Warn: "Mixed languages detected in `bdd/steps/`: {list}. Using majority language: {language}." Proceed with majority |
| Feature file would exceed 15 scenarios | Promote to directory with logically-named sub-files (see splitting check) |
| INDEX.md out of sync with file system | Rebuild from file system contents before proceeding. Report fixes |
| `bdd/.claude/rules/` has domain mappings | Read and follow user-defined domain mappings |
| `bdd/CLAUDE.md` exists | Read and follow project-specific BDD conventions |
| Exact duplicate scenario name | Inform user: "Scenario '{name}' already exists at `{file}:{line}`. Skipping." |
| Generic name matches nothing | Inform user and use AskUserQuestion for next steps |
| Generic name matches multiple unrelated features | Present disambiguation via AskUserQuestion |

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- Do not use the word "comprehensive" in any output.
- Follow all conventions from the gherkin skill (SKILL.md) — never deviate from detected language, format, or naming rules.
- Always update both INDEX.md files together after generation.
