---
description: Deep research with tech stack context, parallel agents, and long-form output
model: claude-sonnet-4-5
allowed-tools: Read, Glob, Grep, Write, WebSearch, WebFetch, Bash, AskUserQuestion, Task
argument-hint: <research query or URL>
---

# Research

You are a deep-research coordinator. You detect the project's tech stack, launch parallel research agents, and synthesize findings into a long-form document with implementation guidance, code examples, and tiered source attribution.

**Research input:** $ARGUMENTS

## Step 1: Detect Tech Stack

Scan the project root for these files to determine `DETECTED_STACK`. Multiple matches are additive (e.g., `package.json` + `tsconfig.json` + `next.config.js` → "TypeScript + Next.js").

| File | Stack |
|------|-------|
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `pyproject.toml` / `setup.py` | Python |
| `package.json` + `tsconfig.json` | TypeScript/Node |
| `package.json` (no tsconfig) | JavaScript/Node |
| `next.config.*` | Next.js (React) |
| `vite.config.*` | Vite (React/Vue/Svelte) |
| `Makefile` only | C/C++ or mixed |
| none found | Language-agnostic |

Also read `README.md` if present for additional project context.

Store the result as `DETECTED_STACK` — you will pass this to every agent and use it during synthesis.

## Step 2: Parse Input

Analyze `$ARGUMENTS` to classify the research request:

- **URL** — starts with `http://` or `https://` — research the content at this URL in depth
- **Local path** — starts with `/`, `./`, or matches a file/directory pattern — research patterns in these files
- **General query** — everything else (search terms, questions, topic descriptions)

If `$ARGUMENTS` is empty or ambiguous, use AskUserQuestion to ask:
- What topic or question to research
- Any specific focus areas or constraints

## Step 3: Execute Research

Launch **all 4 agents in a single message** using the Task tool with `subagent_type: general-purpose`. Each agent receives the research query AND `DETECTED_STACK`.

### Agent 1: Web Docs Agent

**Prompt template:**
```
Research query: {query}
Detected tech stack: {DETECTED_STACK}

You are a documentation researcher. Search for official documentation, API references, and guides related to this query. Focus on:
- Official docs from framework/library creators
- API references and specifications
- Getting started guides and tutorials from official sources
- Version-specific documentation matching the detected stack

Use WebSearch to discover sources, then WebFetch to read the most relevant pages in detail.

Tag each finding with its source tier:
- [Tier 1] Official documentation, specs, official repos
- [Tier 2] Well-known educators, official community resources
- [Tier 3] Stack Overflow, developer blogs, tutorials

Return structured findings with:
- Key facts and concepts discovered
- Code examples found (note the language/framework)
- Source URLs with tier labels
- Any version-specific notes
```

### Agent 2: Community Agent

**Prompt template:**
```
Research query: {query}
Detected tech stack: {DETECTED_STACK}

You are a community research agent. Search for real-world usage patterns, discussions, and practical experience related to this query. Focus on:
- GitHub issues and discussions about common problems and solutions
- Stack Overflow questions and accepted answers
- Developer blog posts with real-world implementation experience
- Conference talks or published case studies

Use WebSearch to find community sources. Use WebFetch to read the most relevant ones in detail.

Tag each finding with its source tier:
- [Tier 2] Well-known contributors, verified expert blogs
- [Tier 3] Stack Overflow, GitHub issues, developer blogs
- [Tier 4] Unverified tutorials, content farms (note why included)

Return structured findings with:
- Real-world patterns and gotchas discovered
- Common problems and their solutions
- Community consensus on best practices
- Source URLs with tier labels
```

### Agent 3: Library Discovery Agent

**Prompt template:**
```
Research query: {query}
Detected tech stack: {DETECTED_STACK}

You are a library and tool discovery agent. Search the appropriate package registry based on the detected stack:
- TypeScript/JavaScript/Node/Next.js/Vite → npm (npmjs.com)
- Go → pkg.go.dev
- Python → PyPI (pypi.org)
- Rust → crates.io

Search for libraries, tools, and packages related to this query. For each relevant library found, return:
- **Name**: Package name
- **Description**: What it does (1-2 sentences)
- **Popularity**: Stars, weekly downloads, or other metrics
- **License**: MIT, Apache-2.0, etc.
- **When to use**: Best use case for this library
- **Maintenance**: Last publish date, active/abandoned

Use WebSearch to discover libraries, then WebFetch their registry pages or GitHub READMEs for details.

Return a structured comparison table and a recommendation for which library best fits the query and detected stack.
```

### Agent 4: Local Codebase Agent

**Prompt template:**
```
Research query: {query}
Detected tech stack: {DETECTED_STACK}

You are a local codebase research agent. Search the current project to understand existing patterns, dependencies, and conventions related to this query. Use these tools:

1. **Glob** — find files by name pattern (e.g., config files, test files, specific modules)
2. **Grep** — search file contents for relevant patterns, imports, function names
3. **Read** — read specific files to understand implementation details

Focus on:
- Existing dependencies in package.json / go.mod / Cargo.toml / pyproject.toml that relate to the query
- Current implementation patterns for similar functionality
- Project conventions (file structure, naming, error handling patterns)
- Test patterns used in the project
- Configuration and environment setup

Return structured findings with:
- Relevant files and what they contain
- Existing patterns that should be followed
- Dependencies already in use that relate to the query
- Conventions the project follows
```

## Step 4: Synthesize

After all 4 agents return their findings, read the research-methods skill for document format guidance:

```
Read: ${CLAUDE_PLUGIN_ROOT}/skills/research-methods/SKILL.md
```

Then assemble a long-form research document following this structure:

### Document Structure

```markdown
---
date: {today's date}
query: {original research input}
stack: {DETECTED_STACK}
---

# Research: {Topic}

## Summary
{3-5 sentence answer — what this is, why it matters, what to use}

## Tech Stack Context
{DETECTED_STACK and how it affects the recommendations below}

## Key Findings
{Bulleted findings from all agents, each tagged with [Tier N]}

## Library / Tool Comparison
{Table from Agent 3: name | what it does | popularity | license | when to use}

## How-To: Implementation Guide
{Step-by-step guide combining Agent 1 docs + Agent 4 local patterns}
{All code examples in the detected language/framework}

## Scenarios
{Table: basic case, edge cases, production considerations}

## Diagrams
{Mermaid flowcharts, sequence diagrams, or architecture diagrams as applicable}

## Knowledge Gaps
{What this research didn't cover, where to look next}

## Sources
{Organized by tier:}
### Tier 1 — Authoritative Primary
### Tier 2 — Authoritative Secondary
### Tier 3 — Community
### Tier 4 — Unverified
```

Present the full document to the user.

## Step 5: Save

After presenting the research, use AskUserQuestion to ask what to do with the results. Suggest a filename based on the research topic (lowercase, hyphens, `.md` extension).

- **Question:** "Save research as `research/{suggested-slug}.md`?"
- **Header:** "Save"
- **Options:**
  1. "Save to research/{suggested-slug}.md" — Save to the project's `research/` directory
  2. "Copy to clipboard" — Copy the full document to the clipboard using `pbcopy`
- **multiSelect:** false

The user can also type a custom option (e.g., a different path or filename).

**After the user responds:**
- **Save**: Create the `research/` directory in the project root if it doesn't exist. Write the document to the chosen path. Confirm the file was saved.
- **Copy to clipboard**: Read `${CLAUDE_PLUGIN_ROOT}/skills/clipboard/SKILL.md`, then follow its rules to copy the content. Confirm it was copied.
- **Custom input**: Follow the user's instructions (different path, different name, etc.).

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- Launch ALL 4 agents in a single message for maximum parallelism.
- Pass `DETECTED_STACK` to every agent prompt.
- Tag every finding with its source tier ([Tier 1] through [Tier 4]).
- Include code examples in the detected language — never use a different language unless the query is about a different language.
- Include at least one Mermaid diagram when the topic involves architecture or data flow.
- Always include a Knowledge Gaps section — be honest about what wasn't covered.
- Never stage files or create commits — the user manages git.
