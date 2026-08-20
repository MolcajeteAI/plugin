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

One block per ID, in the order the user typed them. This is the shape, filled from a `UC`:

````markdown
## UC-3Z2L · Send Email OTP

|  |  |
|---|---|
| Status | `implemented` |
| Module | `auth` |
| Feature | FEAT-3Z2K · Email OTP Authentication |
| Spec | `specs/features/auth/FEAT-3Z2K-email-otp/UC-3Z2L-send-email-otp.md` |
| Test | `tests/auth/FEAT-3Z2K-email-otp/UC-3Z2L-send-email-otp.test.ts` |
| Last change | 2026-08-04 — raised the OTP expiry from 5 to 10 minutes |

> Deliver a one-time passcode to a registered email address so the actor can sign in without a password.

**Trigger.** The actor submits a registered email on the sign-in form.

**Scenarios**

- `SC-3Z2P` — Send OTP to a registered address
- `SC-3Z2Q` — Reject an unregistered address

**Code**

- `src/auth/otp.ts:44` — `sendEmailOtp()`
- `src/auth/mailer.ts:12` — `deliver()`
````

Three containers, one per kind of content. Never mix them.

- **The table takes every short fact.** One row each, label in the left column. Nothing else belongs here.
- **The blockquote takes the description**, quoted from the spec rather than paraphrased. It needs room to run several lines, so it never sits after a label.
- **A list takes a genuine list.** An entry may use `— ` only because both sides are short. A label followed by a dash and a paragraph is the shape this format exists to remove.

**Fill the table per prefix.** Omit a row that does not apply rather than printing it empty.

| Prefix | Rows | Body |
|--------|------|------|
| `FEAT` | Status, Module, Domain, Spec | Objective, then a Use Cases list |
| `UC` | Status, Module, Feature, Spec, Test, Last change | Objective, Trigger, Scenarios, Code |
| `SC` | Use case, Feature, Spec, Test | Given and Outcomes, then Code |
| `FR` / `NFR` | Feature, Spec, Linked to | The requirement line, then its Fit Criterion |
| `US` | Feature, Spec | The story text |
| `ADR` | Feature, Spec | The decision paragraph |

**A missing value stays a row.** Write `| Test | [missing] |` and `| Code | [no Code Map row] |`, so the gap appears where the value would. Never drop the row and never explain the absence in prose.

**A miss prints in its typed position**, as a short block with no table: the token as an H2, one line saying why it did not resolve, and whatever the not-found branch produced — a near neighbor, or a reference that no definition backs.

When one `FEAT` or `UC` resolves to several module-instances, print one block per module and state that they share the ID by design.

End with the hand-off:

> Next: run `/m:ids <capability>` to find IDs by description, or `/m:prompt <request>` to turn a change you want into the command that makes it.
