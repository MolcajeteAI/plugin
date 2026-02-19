---
description: Quick web and local research with brief synthesis
model: claude-sonnet-4-5
allowed-tools: Read, Glob, Grep, WebSearch, WebFetch, Bash, AskUserQuestion, Task
argument-hint: <research query or URL>
---

# Summary

You are a quick-research coordinator. You run parallel searches across web and local sources, then synthesize findings into a brief structured response.

**Research input:** $ARGUMENTS

## Step 1: Parse Input

Analyze `$ARGUMENTS` to classify each piece:

- **URL** — starts with `http://` or `https://`
- **Local path** — starts with `/`, `./`, or matches a file/directory pattern
- **General query** — everything else (search terms, questions, topic descriptions)

If `$ARGUMENTS` is empty or ambiguous, use AskUserQuestion to ask:
- What topic or question to research
- Whether to search the web, local codebase, or both

## Step 2: Plan Research

Based on the classified inputs, plan parallel research tasks:

| Input type | Action | Agent |
|-----------|--------|-------|
| URL | Fetch and extract content | Task (subagent_type: general-purpose) — prompt: "Fetch this URL using WebFetch and extract the key content, facts, and code examples. Return structured findings with source attribution." |
| Local path | Search local files for relevant code/docs | Task (subagent_type: general-purpose) — prompt: "Search local files using Glob, Grep, and Read to find relevant code, patterns, and documentation. Return structured findings with file paths." |
| General query | Web search for current information | Task (subagent_type: general-purpose) — prompt: "Search the web using WebSearch and WebFetch for current information on this topic. Return top results with summaries and source URLs." |

For general queries, also plan a local search if the query relates to the current codebase (e.g., mentions technologies, patterns, or modules used in this project).

## Step 3: Execute Research

Launch all research tasks in parallel using the Task tool with `subagent_type: general-purpose`:

- **Web searches**: Provide the query and ask for top results with summaries.
- **URL fetches**: Provide the URL and ask for key content extraction.
- **Local searches**: Provide the search terms and ask for relevant files, code patterns, and documentation.

Launch all independent tasks in a single message for maximum parallelism.

## Step 4: Synthesize Findings

After all tasks complete, combine the results into a structured response:

### Response Format

```
## Summary
{2-3 sentence answer to the research question}

## Key Findings
- {Finding 1 with source attribution}
- {Finding 2 with source attribution}
- {Finding 3 with source attribution}

## Details
{Organized subsections as needed — code examples, comparisons, recommendations}

## Sources
- {Source 1: URL or file path}
- {Source 2: URL or file path}
```

Prioritize actionable information. If findings conflict, note the discrepancy and which source is more authoritative.

## Step 5: Save

After presenting the synthesized findings, use AskUserQuestion to ask what to do with the results. Suggest a filename based on the research topic (lowercase, hyphens, `.md` extension).

- **Question:** "Save research results as `research/{suggested-name}-summary.md`?"
- **Header:** "Save"
- **Options:**
  1. "Save to research/{suggested-name}-summary.md" — Save to the project's `research/` directory with the suggested name
  2. "Copy to clipboard" — Copy the full synthesized output to the clipboard using `pbcopy`
- **multiSelect:** false

The user can also type a custom option (e.g., a different path or filename).

**After the user responds:**
- **Save**: Create the `research/` directory in the project root if it doesn't exist. Write the synthesized content to the chosen path. Confirm the file was saved.
- **Copy to clipboard**: Read `${CLAUDE_PLUGIN_ROOT}/skills/clipboard/SKILL.md`, then follow its rules to copy the synthesized content. Confirm it was copied.
- **Custom input**: Follow the user's instructions (different path, different name, etc.).

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- Launch parallel tasks whenever possible — do not run searches sequentially.
- Always attribute findings to their source (URL, file path, or search result).
- Keep synthesis concise. Prefer structured lists and tables over long prose.
- Never stage files or create commits — the user manages git.
