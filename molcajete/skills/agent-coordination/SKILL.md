---
name: agent-coordination
description: >-
  Defines how commands invoke designated agents and coordinate handoffs between
  them. Use this skill when a command needs to dispatch work to Developer,
  Reviewer, Spec Writer, BDD Analyst, or Researcher agents. Covers invocation
  protocol, handoff patterns, result parsing, failure handling, and runtime skill
  discovery.
user-invocable: false
---

# Agent Coordination

Protocol for commands to invoke designated agents and coordinate handoffs between them.

## When to Use

- A command needs to dispatch implementation work to the Developer agent
- A command needs a code review from the Reviewer agent
- A command needs requirements or spec writing from the Spec Writer agent
- A command needs BDD scenario generation from the BDD Analyst agent
- A command needs research or impact analysis from the Researcher agent
- A command needs to commit completed work via the Committer agent
- A command needs to chain multiple agents in sequence (e.g., Developer -> Reviewer -> Committer)
- A command needs BDD environment configuration from the BDD Setup agent

## Agent Roster

| Agent | File | Model | Primary Role |
|-------|------|-------|--------------|
| Developer | `${CLAUDE_PLUGIN_ROOT}/agents/developer.md` | sonnet | Implements code and tests from approved plans |
| Reviewer | `${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md` | opus | Reviews code across 5 dimensions |
| Spec Writer | `${CLAUDE_PLUGIN_ROOT}/agents/spec-writer.md` | opus | Writes requirements, specs, task breakdowns |
| BDD Analyst | `${CLAUDE_PLUGIN_ROOT}/agents/bdd-analyst.md` | opus | Translates requirements into Gherkin scenarios |
| Researcher | `${CLAUDE_PLUGIN_ROOT}/agents/researcher.md` | sonnet | Deep research, explanations, impact analysis |
| Committer | `${CLAUDE_PLUGIN_ROOT}/agents/committer.md` | sonnet | Stages files and commits with proper message format |
| BDD Setup | `${CLAUDE_PLUGIN_ROOT}/agents/bdd-setup.md` | sonnet | Detects tech stack and configures BDD environment |

## Invocation Protocol

Commands invoke agents using the Task tool. Each invocation follows a consistent pattern:

1. **Read the agent definition** — Load the agent's `.md` file to understand its responsibilities, boundaries, skills, and output format
2. **Build the agent prompt** — Use the invocation template (see references) to construct a prompt that includes: task context, agent role, skills to load, and expected output format
3. **Set the model** — Use the agent's declared model (from frontmatter) when launching the Task tool
4. **Parse the result** — Validate the agent's output matches its declared Output Format section

See [references/invocation-template.md](./references/invocation-template.md) for the standard prompt template.

## Handoff Patterns

Agents work in sequences defined by the command. Each agent receives the output of the previous agent as part of its context.

See [references/handoff-protocol.md](./references/handoff-protocol.md) for standard handoff patterns.

### Common Chains

| Chain | Used By | Pattern |
|-------|---------|---------|
| Developer -> Reviewer -> Committer | `/m:dev`, `/m:fix` | Implementation, review with fix loop, then commit with hook-failure loop |
| BDD Analyst (standalone) | `/m:stories` | Scenario generation from requirements |
| Reviewer (standalone) | `/m:review` | Read-only code review |
| Spec Writer (standalone) | `/m:feature`, `/m:spec`, `/m:tasks` | Document generation |
| Researcher (standalone) | `/m:research`, `/m:explain` | Research and explanation |
| Researcher -> Spec Writer | `/m:refactor` | Impact analysis, then requirements |
| BDD Setup (standalone) | `/m:bdd-setup` | Tech stack detection and BDD environment configuration |

## Runtime Skill Discovery Protocol

Agents that support runtime skill discovery follow this procedure:

1. Read the agent's "Discovered (Runtime)" section to determine the glob pattern
2. Run `Glob` with `${CLAUDE_PLUGIN_ROOT}/skills/{pattern}` to find matching skill files
3. Include discovered skill paths in the agent's prompt alongside primary skills
4. If no matching skills are found, proceed without them — missing stack-specific skills are not errors

### Discovery Patterns

| Agent | Pattern | Example Matches |
|-------|---------|-----------------|
| Developer | `*-writing-code/SKILL.md`, `*-testing/SKILL.md` | `go-writing-code/SKILL.md`, `go-testing/SKILL.md`, `typescript-writing-code/SKILL.md` |
| Reviewer | `*-writing-code/SKILL.md` | Same as Developer's writing-code skills (for convention checking) |

## Failure Handling

When an agent returns a `FAILURE` result or its output does not match the expected format:

1. **Parse the ISSUES field** — Understand what went wrong
2. **Decide: retry or escalate**
   - If the failure is transient (timeout, context limit) — retry once with a narrowed prompt
   - If the failure is substantive (missing information, blocked by dependency) — escalate to the user via AskUserQuestion
3. **Never retry more than once** — Two failures on the same task means human intervention is needed
4. **Preserve partial results** — If an agent completed some work before failing, include that context in the retry prompt

## Mechanical Tasks Stay Inline

Not everything needs an agent. These tasks stay as inline Bash operations within commands:

- Running formatters (`gofmt`, `pnpm run format`)
- Running linters (`golangci-lint`, `pnpm run lint`)
- Running test suites (the Developer runs them and writes tests)
- File system checks

Git operations are handled by the Committer agent within dev/fix chains, and inline for standalone commands (e.g., `/m:commit`).

## Reference Files

| File | Description |
|------|-------------|
| [references/invocation-template.md](./references/invocation-template.md) | Standard prompt template for launching an agent via Task tool |
| [references/handoff-protocol.md](./references/handoff-protocol.md) | Handoff patterns between agents with context passing |
