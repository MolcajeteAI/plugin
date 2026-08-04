---
description: Deep research with tech stack context, parallel agents, and long-form output
model: claude-sonnet-5
argument-hint: <topic, URL, or local path to research>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Agent
  - WebSearch
  - WebFetch
  - Bash
  - AskUserQuestion
---

# Research

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

## Step 1: Load Skill

Read the research-methods skill for orchestration rules, search strategies, source evaluation, and the research guide template:

```
Read: ${CLAUDE_PLUGIN_ROOT}/research/skills/research-methods/SKILL.md
```

Follow the skill's rules for all subsequent steps.

## Step 2: Collect Input

If `$ARGUMENTS` is not empty, use it as the research input.

If `$ARGUMENTS` is empty, ask. The examples go in the brief — inside the question string they render as literal escapes:

- Brief: say that the input can be a topic, a URL, or a local file path, and give one example of
  each as a Markdown list — "WebSocket authentication patterns",
  `https://docs.stripe.com/api/charges`, `src/auth/middleware.ts`. Note the answer is typed into
  `Other`.
- Question: "What would you like to research?"
- Header: "Topic"

## Step 3: Execute Research

Run the skill's workflow.

## Step 4: Save

The completed guide is the brief — present it in full first, then offer save options:
- Question: "Where should I save this research?"
- Header: "Save"
- Options: "Save to research/{suggested-slug}.md" / "Copy to clipboard" / "Custom path"

Save to the chosen location.
