---
description: Explain a topic clearly in a 3-5 minute read with friendly language and practical examples
model: claude-sonnet-4-6
allowed-tools: Read, Glob, Grep, Write, WebSearch, WebFetch, Bash(*), AskUserQuestion, Task
argument-hint: <topic to explain>
---

# Explain

**Topic:** $ARGUMENTS

## Designated Agents

This command delegates directly to the Researcher agent:

- `${CLAUDE_PLUGIN_ROOT}/skills/agent-coordination/SKILL.md` — invocation protocol
- **Researcher** (`${CLAUDE_PLUGIN_ROOT}/agents/researcher.md`) — topic explanation with friendly language and practical examples

Read the research-methods skill and execute it in **Explain** mode — skip Step 1 classification and go directly to Step 2e (Parse Input).

```
Read: ${CLAUDE_PLUGIN_ROOT}/skills/research-methods/SKILL.md
```

Follow the skill's Explain Orchestration (Steps 2e-4e) exactly. The skill is the single source of truth for the Introduction template, writing style, agent prompts, synthesis format, and save flow.
