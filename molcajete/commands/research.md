---
description: Deep research with tech stack context, parallel agents, and long-form output
model: claude-sonnet-4-6
allowed-tools: Read, Glob, Grep, Write, WebSearch, WebFetch, Bash(*), AskUserQuestion, Task
argument-hint: <research query or URL>
---

# Research

**Research input:** $ARGUMENTS

## Designated Agents

This command delegates directly to the Researcher agent:

- `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/SKILL.md` — invocation protocol
- **Researcher** (`${CLAUDE_PLUGIN_ROOT}/agents/researcher.md`) — deep research with parallel sub-agents and source evaluation

Read the research-methods skill and execute it in **Deep Research** mode — skip Step 1 classification and go directly to Step 2 (Detect Tech Stack).

```
Read: ${CLAUDE_PLUGIN_ROOT}/skills/research-methods/SKILL.md
```

Follow the skill's Deep Research Orchestration (Steps 2-6) exactly. The skill is the single source of truth for templates, writing style, agent prompts, synthesis format, and save flow.
