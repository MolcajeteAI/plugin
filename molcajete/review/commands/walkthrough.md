---
description: Walk through a change set interactively, hierarchically (feature to use case to scenario), explaining what each change is and why it was made, with clickable file:line links. Read-only.
model: claude-opus-4-6
argument-hint: "[PR # | branch | ref-A ref-B — omit for current branch vs base]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
---

# Walkthrough Command

`/m:walkthrough` takes you through the changes on a branch, a pull request, or between two refs — step by step, **hierarchically from feature to use case to scenario** — explaining *what* each change is, *why* it was made, and *what it means*. It is a guided tour, not a review: it writes nothing and edits nothing. Use it to get familiar with a change set ("walk me through this branch", "what changed between `master` and `production`") before reviewing, merging, or building on it.

**Target argument:** $ARGUMENTS

**All user interaction MUST use the AskUserQuestion tool.** Never plain-text questions.

## Step 1: Load Skill

Read `${CLAUDE_PLUGIN_ROOT}/review/skills/change-review/SKILL.md` — the prerequisite gate, change-set resolution, and diff→spec mapping. Apply its **Prerequisites** gate; if it is not a Molcajete project, refuse and stop. (The walkthrough narrates changes; it does not score them, so it does not load the review rubric.)

## Step 2: Resolve the Target and Map to Specs

Follow the `change-review` skill's **Resolving the Change Set** (parse `$ARGUMENTS` — empty → current branch vs detected base; a branch; a PR number; or two refs — with base detection and AskUserQuestion confirmation) and **Mapping the Diff to Specs** to build the hierarchy: `FEAT → UC → SC → the changed files/functions under it`. Read each touched UC's scenarios (the behavioral source of truth) and, when the change came through a plan, the owning task's prose in `specs/plans/*.md` — that prose states what the increment was meant to make real and why.

Any changed file that maps to no `FEAT/UC/SC` is grouped under an **"Unmapped changes"** node at the end — mention it plainly (it has no spec authority), but still explain what it does.

## Step 3: Present the Map

Show the top-level shape first: the features touched, and under each the UCs and scenario count, plus the change size. This is the table of contents for the tour. Then ask via AskUserQuestion where to start:

> "This change set touches {N} features. Where do you want to start the walkthrough?"

Options: one per feature ("Start at {FEAT} — {name}"), plus "Walk everything top to bottom".

## Step 4: Walk the Changes (interactive, step by step)

Descend the hierarchy one node at a time — feature → UC → scenario → the concrete diff under it. At each **scenario / change** node, explain three things in plain language:

1. **What changed** — the concrete edit (files, functions), with clickable `path/to/file.ext:line` references so the user can open the exact spot in their editor.
2. **Why** — tie it to the driving reason: the UC scenario it satisfies (quote the `SC-XXXX`), the task prose in the plan file, and the commit subject. If the change has no spec behind it, say so.
3. **What it means** — the consequence: the behavior a user or caller now gets, and anything downstream that depends on it.

After each node, navigate via AskUserQuestion:

> "That's {node}. Where next?"

Options: **"Next"** (the following node in order) / **"Deeper"** (show the actual diff / more `file:line` detail for this node) / **"Show code"** (surface the touched code with `file:line` links; when the IDE MCP is connected, optionally include `mcp__ide__getDiagnostics` for the touched files so the user sees any warnings) / **"Jump to feature"** (pick another feature) / **"Done"**.

Keep each step short and concrete — one node's worth of change, not a wall of text. The clickable `file:line` references are the "give me a link I can click to open the code" path; prefer them over pasting large diffs unless the user asks to go **Deeper**.

## Step 5: Close

When the user has covered the tree (or chooses "Done"), give a one-paragraph recap: every feature/UC touched, and the single most important change to keep in mind. Remind them this was a read-only tour, and suggest the next step:

> Next: run `/m:review` for a written, severity-scored review, or `/m:preflight` to fix issues interactively before opening the PR.

## Rules for this command

- Read-only: never edit source, never write a file, never post to GitHub.
- Anchor every change to its `FEAT/UC/SC` where one exists; be explicit when a change is unmapped.
- Prefer clickable `file:line` references over pasting large diffs; expand only on request.
