---
description: Find the spec IDs that match a capability description — grouped by module, with each ID's description, its use cases and scenarios, and its spec file path. Read-only.
model: claude-sonnet-5
argument-hint: <freeform capability description>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# Ids Command

`/m:ids` answers the reverse of `/m:desc`: you know the capability, you need its IDs. Give it a freeform description — `/m:ids odds calibration` — and it returns the matching features, use cases, and scenarios grouped by module, each with its description and its spec file path.

**Read-only.** This command writes nothing.

**Target argument:** $ARGUMENTS

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

**Writing style:** every message you print uses Simplified Technical English, and carries only what its reader needs. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/shared/skills/output-economy/SKILL.md` before writing.

## Step 1: Parse the Query

Take `$ARGUMENTS` as the capability description. If it is empty, ask via AskUserQuestion: "Which capability do you want the IDs for?" This question only collects free-form input, so it needs no brief.

If `$ARGUMENTS` is a single ID-shaped token, say so and stop:

> That is already an ID. Run `/m:desc <ID>` to see what it covers.

## Step 2: Load Skill

Read `${CLAUDE_PLUGIN_ROOT}/spec/skills/spec-lookup/SKILL.md` — resolve-by-keyword and context assembly. Apply its **Prerequisites** gate; if this is not a Molcajete project, refuse and stop.

## Step 3: Search and Rank

Run the skill's **Resolve by Keyword** end to end: glossary expansion, index sweep, body grep, scoring, and both cutoff rules.

Both cutoff rules are mandatory. Module completeness pulls in every instance of a surviving UC, and the two-tier split demotes a weak match instead of dropping it.

Search inline with Glob and Grep. Do not dispatch a subagent — the skill states why.

## Step 4: Assemble Context

Run the skill's **Context Assembly** at **depth 1** for every main-tier hit, then add depth 2's **implementation files** for each one. The user asked where each ID lives, so the Code Map lookup is part of the answer.

Skip the mention tier. Those entries report as IDs only.

## Step 5: Report

Group the output by module, because one `UC-XXXX` can exist in several modules with different content. Under each module heading, one block per feature:

- The feature's **ID Summary Line** and its one-line description.
- Its matching use cases, each as an ID Summary Line plus one line of what the actor achieves.
- Under each use case, the matching scenario IDs and names.
- The implementation files for each use case, as clickable `path/to/file.ext:line` references.

Every block ends with its spec file path, so the user can open the source.

When a `UC-XXXX` appears under more than one module, state that the instances share the ID by design and their content differs per module.

Close the main output with the mention tier as one line, when it has entries:

```
Also mentions "calibration": UC-4A2P, UC-51KX, FR-3Z2Z.
```

When the search found nothing, say so, print the three closest entities by name, and add:

> No spec covers that. If the code already exists, run `/m:cover <description>` to extract the spec from it. If it does not, run `/m:spec <description>` to write it.

End a successful report with the hand-off:

> Next: run `/m:desc <ID>` for the full description of any ID above, or `/m:prompt <request>` to turn a change you want into the command that makes it.
