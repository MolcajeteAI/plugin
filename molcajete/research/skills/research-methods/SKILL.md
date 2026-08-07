---
name: research-methods
description: >-
  Full research orchestration skill — detects tech stack, parses input type,
  launches 4 parallel agents (web docs, community, library discovery, local
  codebase), and synthesizes findings into a progressive research guide.
---

# Research Methods

Orchestrates deep research by launching parallel agents and synthesizing their findings into a single progressive guide. Every research request — regardless of topic — produces the same document format. The depth and breadth of each section adapts naturally to the topic.


## Step 1: Detect Tech Stack

1. Check `.molcajete/settings.json` for cached tech-stack settings (Framework, Language)
2. If not cached, scan project root for stack indicators: `package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `requirements.txt`, `Gemfile`, `pom.xml`, `build.gradle`, `composer.json`, `mix.exs`
3. Store the detected stack as `DETECTED_STACK` — pass to all agents so they tailor results to the project's language and ecosystem

## Step 2: Parse Input

Classify the research input into one of three types:

| Type | Detection | Agent Behavior |
|------|-----------|----------------|
| **URL** | Starts with `http://` or `https://` | WebFetch the URL first, then research the topic it covers |
| **Local path** | Matches an existing file or directory path | Read the file/directory first, then research the topic it covers |
| **General query** | Everything else | Research the topic directly |

For URLs and local paths, extract the core topic from the content before launching agents.

## Step 3: Launch Parallel Agents

Launch all 4 agents in a single message for maximum parallelism. Each agent receives `DETECTED_STACK` and the research topic.

### Agent 1: Web Docs Agent

- **Type:** `subagent_type: general-purpose`
- **Task:** Search for official documentation, API references, getting-started guides, and specification documents
- **Instructions:**
  - Read the most relevant pages (limit to 3-5 pages)
  - Tag each finding with a source tier (see `references/source-evaluation.md`)
  - Return structured findings: title, URL, key content summary, source tier
  - Prioritize: official docs > API references > tutorials from the official source

### Agent 2: Community Agent

- **Type:** `subagent_type: general-purpose`
- **Task:** Search for real-world usage patterns, common issues, and community knowledge
- **Instructions:**
  - Search GitHub issues, Stack Overflow answers, blog posts, and tutorials
  - Focus on: common gotchas, production lessons, migration guides, performance tips
  - Tag each finding with a source tier
  - Return structured findings: title, URL, key takeaway, source tier
  - Prioritize recent content (within last 2 years) over older content

### Agent 3: Library Discovery Agent

- **Type:** `subagent_type: general-purpose`
- **Task:** Search the appropriate package registry for relevant libraries and tools
- **Instructions:**
  - Search the package registry that matches `DETECTED_STACK`
  - For each relevant library, collect: name, description, weekly downloads/popularity, license, last updated, key features
  - Return a structured comparison table
  - Include an opinionated recommendation for the current project context

### Agent 4: Local Codebase Agent

- **Type:** `subagent_type: Explore`
- **Task:** Find existing code patterns, dependencies, and conventions relevant to the research topic
- **Instructions:**
  - Return: existing dependencies (from package.json/go.mod/etc.), existing patterns, conventions, architecture decisions
  - Note any existing implementations that relate to the research topic

## Step 4: Synthesize

Assemble the agent findings into the research guide using the template at:

```
${CLAUDE_PLUGIN_ROOT}/research/skills/research-methods/templates/research-guide.md
```

Read the template first, then populate the sections the agents' findings support. Omit a section when the research produced nothing for it — an empty heading is not completeness.

### Writing Principles

- Code examples in detected language with comments
- Always cite sources — every claim traceable to Sources section

## Step 5: Save

Present the completed guide as the brief, then offer save options as a short question — see `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` (the question itself is handled by the calling command).

## References

| Reference | Purpose |
|-----------|---------|
| [search-strategies.md](./references/search-strategies.md) | Query construction, search techniques, progressive refinement |
| [source-evaluation.md](./references/source-evaluation.md) | Source tiers (1-4), evaluation criteria, confidence levels |

## Templates

| Template | Purpose |
|----------|---------|
| [research-guide.md](./templates/research-guide.md) | Single progressive guide format for all research output |
