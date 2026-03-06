---
description: Create a well-formatted commit from staged changes
model: claude-sonnet-4-6
allowed-tools: Read, Bash(*), Write, Task, AskUserQuestion
argument-hint: <optional: issue number or context hint>
---

# Commit

**Context hint:** $ARGUMENTS

Read the git-committing skill and execute its Commit Orchestration workflow.

```
Read: ${CLAUDE_PLUGIN_ROOT}/skills/git-committing/SKILL.md
```

Follow the skill's Commit Orchestration (Steps 1-5) exactly. The skill is the single source of truth for commit message standards, scope assessment, split flow, confirmation, and execution.

If `$ARGUMENTS` is not empty, incorporate it as context when drafting the commit message in Step 3.
