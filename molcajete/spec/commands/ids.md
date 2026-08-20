---
description: Find the spec IDs that match a capability description — grouped by module, with each ID's description, its use cases and scenarios, and its spec file path. Read-only.
model: claude-sonnet-5
argument-hint: <freeform capability description>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# Ids Command

`/m:ids` answers the reverse of `/m:desc`: you know the capability, you need its IDs. Give it a freeform description — `/m:ids odds calibration` — and it returns the matching features, use cases, and scenarios grouped by module, each with its description and its spec file path.

**Read-only.** This command writes nothing.

**Target argument:** $ARGUMENTS

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

**Writing style:** every message you print uses Simplified Technical English, and carries only what its reader needs. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/shared/skills/output-economy/SKILL.md` before writing.

## Step 1: Parse the Query

Take `$ARGUMENTS` as the capability description. If it is empty, ask via AskUserQuestion: "Which capability do you want the IDs for?" This question only collects free-form input, so it needs no brief.

If `$ARGUMENTS` is a single ID-shaped token, say so and stop:

> That is already an ID. Run `/m:desc <ID>` to see what it covers.

## Step 2: Load Skill

Read `${CLAUDE_PLUGIN_ROOT}/spec/skills/spec-lookup/SKILL.md` — resolve-by-keyword and context assembly. Apply its **Prerequisites** gate; if this is not a Molcajete project, refuse and stop.

## Step 3: Search and Rank

Run the skill's **Resolve by Keyword** end to end: glossary expansion, index sweep, body grep, scoring, and both cutoff rules.

Both cutoff rules are mandatory. Module completeness pulls in every instance of a surviving UC, and the two-tier split demotes a weak match instead of dropping it.

Search inline with Glob and Grep. Do not dispatch a subagent — the skill states why.

## Step 4: Assemble Context

Run the skill's **Context Assembly** at **depth 1** for every main-tier hit, then add depth 2's **implementation files** for each one. The user asked where each ID lives, so the Code Map lookup is part of the answer.

Skip the mention tier. Those entries report as IDs only.

## Step 5: Report

Group the output by module, because one `UC-XXXX` can exist in several modules with different content. This is the shape:

````markdown
## `auth`

### FEAT-3Z2K · Email OTP Authentication

Sign a user in with a one-time passcode sent to their registered email.

| Use case | What the actor achieves | Status | Scenarios |
|---|---|---|---|
| `UC-3Z2L` Send Email OTP | Receives a passcode at their registered address | implemented | `SC-3Z2P`, `SC-3Z2Q` |
| `UC-3Z2M` Verify Email OTP | Exchanges a valid passcode for a session | implemented | `SC-3Z2R` |

**Code**

- `UC-3Z2L` — `src/auth/otp.ts:44`, `src/auth/mailer.ts:12`
- `UC-3Z2M` — `src/auth/verify.ts:20`

**Specs**

- `specs/features/auth/FEAT-3Z2K-email-otp/UC-3Z2L-send-email-otp.md`
- `specs/features/auth/FEAT-3Z2K-email-otp/UC-3Z2M-verify-email-otp.md`

## `console`

### FEAT-3Z2K · Email OTP Authentication

> Same `FEAT-3Z2K` and `UC-3Z2L` as `auth`. The IDs are shared by design and the content is module-scoped.

...

---

Also mentions "calibration": `UC-4A2P`, `UC-51KX`, `FR-3Z2Z`.
````

**The use case table is the core of the block.** One row per matching UC, four columns, every cell one clause.

**Code and Specs are lists keyed by UC ID**, so a feature with four use cases stays readable. When a UC has no Code Map row, write `[no Code Map row]` after its ID rather than omitting the line.

**A repeated module-instance gets the blockquote note**, once per module, so nobody reads the two blocks as two different use cases.

**The mention tier is the last line of the output**, after a rule. IDs only — no description and no path.

When the search found nothing, say so, print the three closest entities by name, and add:

> No spec covers that. If the code already exists, run `/m:cover <description>` to extract the spec from it. If it does not, run `/m:spec <description>` to write it.

End a successful report with the hand-off:

> Next: run `/m:desc <ID>` for the full description of any ID above, or `/m:prompt <request>` to turn a change you want into the command that makes it.
