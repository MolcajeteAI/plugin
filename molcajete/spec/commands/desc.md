---
description: Print what an ID is about — its description plus the surrounding spec, code, and test context — for one or more FEAT/UC/SC/FR/NFR/US/ADR IDs. Read-only.
model: claude-sonnet-5
argument-hint: <FEAT-XXXX | UC-XXXX | SC-XXXX | FR-XXXX | NFR-XXXX | US-XXXX | ADR-XXXX> [more IDs ...]
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
---

# Desc Command

`/m:desc` tells you what an ID means. Give it one or more `FEAT`, `UC`, `SC`, `FR`, `NFR`, `US`, or `ADR` IDs and it prints each one's description plus the context around it — the parent chain, the status, the code that implements it, and the test that covers it. Use it when you meet an ID in a plan, a review, or a commit message and need to recall what it was about.

**Read-only.** This command writes nothing and asks nothing.

**Target argument:** $ARGUMENTS

**Writing style:** every message you print uses Simplified Technical English, and carries only what its reader needs. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/shared/skills/output-economy/SKILL.md` before writing.

## Step 1: Parse Arguments

Split `$ARGUMENTS` on whitespace. Keep every token that matches `^(FEAT|UC|SC|FR|NFR|US|ADR)-[0-9A-Za-z]{1,4}$`, and keep a bare 1-4 character token as a prefix-less ID. Preserve the order the user typed.

If no token qualifies, print the usage line and stop:

> Usage: `/m:desc <FEAT-XXXX | UC-XXXX | SC-XXXX | FR-XXXX | NFR-XXXX | US-XXXX | ADR-XXXX> [more IDs ...]`. To search by description instead, run `/m:ids <capability>`.

## Step 2: Load Skill

Read `${CLAUDE_PLUGIN_ROOT}/spec/skills/spec-lookup/SKILL.md` — the ID taxonomy, resolve-by-ID, and context assembly. Apply its **Prerequisites** gate; if this is not a Molcajete project, refuse and stop.

## Step 3: Resolve Each ID

Run the skill's **Resolve by ID** for each token, including the case-retry, partial-ID, and not-found branches.

One miss never aborts the run. Record it and continue to the next token.

## Step 4: Assemble Context

Run the skill's **Context Assembly** at **depth 2** for every resolved entity: the parent chain, the implementation files from the feature's `ARCHITECTURE.md` Code Map, the integration test path, and the newest changelog reason.

## Step 5: Report

One block per ID, in the order the user typed them. Each block carries:

- The **ID Summary Line** from the skill.
- **What it is** — the description, quoted from the spec rather than paraphrased. For a UC, the objective and the trigger. For an SC, the Given and the Outcomes. For an FR or NFR, the requirement line and its Fit Criterion. For an ADR, the decision paragraph.
- **Where it sits** — the parent chain, and for a UC its scenario names.
- **Where it lives in code** — the implementation files as clickable `path/to/file.ext:line` references. Say `[no Code Map row]` when neither the Code Map nor a traceability comment names a file.
- **How it is covered** — the integration test path, or `[missing]` when no file exists there.
- **Last change** — the newest changelog entry's reason and date, for a UC.

A miss prints inline in its typed position: the token, why it did not resolve, and whatever the not-found branch found — a near neighbor, or a reference with no definition.

When one `FEAT` or `UC` resolves to several module-instances, print one block per module and state that they share the ID by design.

End with the hand-off:

> Next: run `/m:ids <capability>` to find IDs by description, or `/m:prompt <request>` to turn a change you want into the command that makes it.
