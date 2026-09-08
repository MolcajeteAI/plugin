---
description: Build a feature, a change, or a fix end to end — one interview, then an autonomous run through plan, specs, code, tests, scoped validation, and a change report.
model: claude-opus-5
argument-hint: "<describe what to build, change, or fix>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
---

# Build Command

`/m:build` turns one freeform request into working, spec-traceable software in a single run. It reads the project, interviews the user once, writes a plan, updates the specs, writes the code and the tests, validates only what changed, and closes with a change report. It is the end-to-end alternative to the staged chain `/m:spec` → `/m:plan` → `/m:execute`.

**Arguments:** $ARGUMENTS

The argument is a description in the user's own words. It is not a spec and not a ticket. Read it as intent, and find the rest in Step 3.

**This command performs the other commands' work inline.** It uses the skills for their formats and their mechanics only. Never run `/m:spec`, `/m:change`, `/m:fix`, `/m:plan`, or `/m:execute` from inside this command. You write the spec files, the plan, the changelog lines, the code, and the tests yourself, in exactly the shapes those skills define.

## What this command covers

Three kinds of work. Decide which ones you are doing in Step 3. Do not assume the request is a new feature.

| Kind | The request | What it produces |
| --- | --- | --- |
| **Addition** | A capability no `FEAT-` or `UC-` describes yet | A new use case, or a new feature with its own folder. Tasks of kind `implement`. |
| **Change** | Behavior a shipped `UC-` describes, which should now work differently | Edited scenarios and requirements. Tasks of kind `change`. |
| **Fix** | The code does not do what the spec says, or the spec is silent on a case the code must handle | A corrected code path, and a new scenario when the spec was silent. Tasks of kind `fix`. |

One request often carries more than one kind. Handle every kind it carries, in one plan, with a task of each kind.

## The standing rule: decide, then record the decision

This rule holds through every step below.

**Step 4 is the only place you ask the user anything.** Everywhere else — the plan, the specs, the code, the tests, a failure — you will reach forks the request does not settle. At every one of them:

1. **Explore the options.** Name each candidate.
2. **Choose the option that serves the project best over the long run**, not the one that is quickest to write today. Weigh it against the host `CLAUDE.md` and the rules in `.claude/rules/`.
3. **Record the fork at once** in the change-request file's `## Decisions taken, and what was rejected` section: the fork, the option you took, **every** option you rejected, and the reason each one lost.
4. **Continue.** Never stop, never leave a `TODO` or `TBD` marker, and never hand the user a half-built change with a question attached.

A recorded decision is the deliverable. A blocked run is not. When a decision carries a real cost, state the cost in the same paragraph.

This command does not load the `plan-adaptation` skill. That skill's amendment gate asks the user a question mid-run, and this command never asks after Step 4. The standing rule replaces the gate: amend your own task sections directly, and record the amendment as a decision.

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

**Writing style:** every document you write and every message you print uses Simplified Technical English. Every one carries only what its reader needs. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/shared/skills/output-economy/SKILL.md` before writing.

## Step 1: Load Skills and Principles

Read now:

1. `${CLAUDE_PLUGIN_ROOT}/plan/skills/plan-authoring/SKILL.md` — the task shape (`**Kind:**`, `**Covers:**`, `**Depends on:**`), task ordering, and the Test File Convention. The change-request file embeds this format.
2. `${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/SKILL.md` — every new ID comes from the shared script; an ID never changes.
3. `${CLAUDE_PLUGIN_ROOT}/shared/skills/uc-log/SKILL.md` — changelog mechanics. This command performs all three permitted mutations.
4. `${CLAUDE_PLUGIN_ROOT}/shared/skills/status-rollup/SKILL.md` — UC status writes and the Feature roll-up.
5. `${CLAUDE_PLUGIN_ROOT}/shared/skills/resolution-gate/SKILL.md` — the analysis sweep Step 4 folds into the interview.
6. `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md` — Implementer / Validator / Reviewer roles, Runner Inference, outer-edge mocking, the scoped coverage gate.
7. `${CLAUDE_PLUGIN_ROOT}/spec/skills/architecture/SKILL.md` — the ARCHITECTURE.md tables this run must keep current, and the vocabulary the change report reuses.
8. **Engineering principles.** Read `.claude/rules/principles.md` from the host project. If the host file is missing, read `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md` instead and emit a one-line warning: "No host principles file found at `.claude/rules/principles.md`. Using plugin defaults. Run `/m:setup` to generate the host file." Also read every other file under the host `.claude/rules/`. Host rules outrank anything a skill says.

Read later, only when needed:

9. **When any part is an Addition** — `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md`.
10. **When any part is a Change or a Fix** — `${CLAUDE_PLUGIN_ROOT}/spec/skills/spec-revision/SKILL.md` — the three-way diagnosis and the spec-edit application rules.
11. **At Step 9** — `${CLAUDE_PLUGIN_ROOT}/build/skills/change-report/SKILL.md` — the report template.
12. **When Step 8 produces a legacy-coverage list** — `${CLAUDE_PLUGIN_ROOT}/shared/skills/github-issues/SKILL.md`.

Prerequisites: `specs/PROJECT.md`, `specs/MODULES.md`, and `specs/TECH-STACK.md` must exist and be read in full now. If any is missing: "Project foundation not found. Run `/m:setup` first." Stop.

## Step 2: Detect an Interrupted Run

List `.molcajete/change-request/*.md`. Read the YAML frontmatter of each file found. A file whose `state` is not `done` is an interrupted run.

- **None found** — continue to Step 3.
- **One or more found** — compare each file's `request` line with `$ARGUMENTS`. Carry the candidates into the Step 4 interview as its first question:
  - Brief: name each candidate file, its `request` line, and the step it stopped at.
  - Question: "Resume an interrupted run, or start fresh?"
  - Header: "Resume"
  - Options: "Resume {slug}" (one per candidate, recommend the best match) / "Start fresh"

**On resume:** read the whole change-request file. The `## Progress` checklist names the completed steps; verify each claim against the artifacts before you trust it (spec edits present, task checkboxes ticked, tests on disk). Continue from the first unchecked step. Append to the decisions section — never rewrite an existing entry. Skip every interview question `## What the user asked for` already answers; ask only the proceed/adjust confirmation.

## Step 3: Understand the Project and Classify

Read before you ask, so Step 4's questions are about decisions and not about the code.

1. **The features and use cases the request touches.** Search `specs/` — `FEATURES.md`, then each candidate feature's `REQUIREMENTS.md`, `USE-CASES.md`, every in-scope `UC-*.md`, and `ARCHITECTURE.md`.
2. **The kind of work each part needs**, per the table above. For a suspected defect, run the three-way diagnosis the `spec-revision` skill defines: the spec is right and the code is wrong, the spec is silent, or the spec itself is wrong. The first two produce a `fix`. The third produces a `change`.
3. **The code that serves those use cases.** Follow each feature's Code Map. Read the files it names.
4. **What else reads the code you are about to change.** A shared module, a configuration key, or an event may serve another feature. Name that feature. If your change reaches its requirements, amend those too, and log the change on its use cases.

## Step 4: Interview Once, Then Confirm

This is the one step that stops for the user. Everything after it runs on its own.

### 4.1 The sweep

Run the `resolution-gate` analysis sweep now, before you ask anything. Its questions fold into this interview. After this step, every hole the sweep found is either answered here or becomes a decided default recorded under the standing rule — which the gate permits.

### 4.2 Ask

Follow `asking-questions`: brief first, then `AskUserQuestion`. **Ask only what changes the work.** Before you ask a question, finish the sentence "if they answer B instead of A, I will build ______". If you cannot finish it, do not ask it.

Ask about these, when the request leaves them open: scope edges, behavior at the edges (the empty state, the refusal, the already-done case), the words a person reads, a visual fork the design system cannot settle, and a trade-off with a real cost either way — stated with the cost, with your recommendation marked.

At most two rounds, at most four questions each. Answer from the codebase every question the codebase can answer.

### 4.3 Summarize and confirm

Print a short brief of what you are about to build, in product language — no file paths and no class names. When the request touches a screen, draw the layout before and after in ASCII art, at each width where they differ, plus the empty state and the refusal when the change creates one.

Then one confirmation question:

- Question: "Proceed with this build, or adjust?"
- Header: "Confirm"
- Options: "Proceed" (recommend) / "Adjust"

Once the user answers, the interview is over. Do not ask again in any later step. The standing rule owns every remaining fork.

## Step 5: Write the Change-Request File

Run `date -u +%Y%m%dT%H%M%S` and copy the output — never compose a timestamp. The slug is kebab-case, at most 40 characters. Create the file:

`.molcajete/change-request/<timestamp>-<slug>.md`

This one file is the plan, the decision log, and the progress record. The TUI and the file carry the same content, so the user reads either. It is also the resume state Step 2 reads. Update it at every step boundary, not at the end.

```markdown
---
state: specs
request: <the request in one line, for resume matching>
created: <timestamp>
updated: <timestamp>
---

# <Title>

<One- or two-line summary.>

**Specs:** <every FEAT-, UC-, and SC- in scope> · **Mode:** <label>
**Prerequisites:** <per plan-authoring>

## Progress

- [x] Step 3 — understood the project: <one-line result>
- [x] Step 4 — interviewed: <one-line result>
- [ ] Step 5 — change-request file written
- [ ] Step 6 — specs updated
- [ ] Step 7 — code and tests written
- [ ] Step 8 — validated: <filled when done>
- [ ] Step 9 — report appended

## What the user asked for

<The request in one paragraph, plus every interview answer, stated as a decision.>

## Decisions taken, and what was rejected

**<The fork, in a few words>.** <The option you chose. Then each option you rejected and the reason it lost.>

## Replaced spec text

<Empty at creation. Step 6 appends the verbatim before-text of every spec block it replaces.>

<Context paragraph, per plan-authoring.>

## [ ] T-001 — <outcome>

**Kind:** <implement | change | fix>
**Covers:** <SC- and FR- IDs>
**Depends on:** <task tags or —>

<Prose per plan-authoring: the files it creates and modifies, the route it is driven through, and what green means in concrete observable terms.>
```

Task rules come from `plan-authoring`: a task is one vertical increment of working software, never a layer; every scenario is covered exactly once; two tasks never edit the same file unless one depends on the other. Order the kinds `fix` before `change` and `implement` wherever two touch the same behavior.

Update the frontmatter `state` at each step boundary: `specs` → `code` → `validate` → `report` → `done`. Update `updated` from the clock each time. Tick each Progress box, with its one-line result, the moment the step completes.

## Step 6: Update the Specs

Specs come before code. Always. The owning skills define every format — apply them, do not restate them:

| You are writing | Owning skill |
| --- | --- |
| A new feature, use case, scenario, or requirement | `feature-authoring`, `usecase-authoring` |
| An edit to an existing spec element | `spec-revision` — edits replace, never annotate |
| New IDs | `id-generation` — the shared script, then a collision check against the whole spec tree |
| Changelog entries, `dirty`/`pending` status, version bumps, roll-up | `uc-log`, `status-rollup` — stamp the change-request file name as the plan-id |
| Component Inventory, API Surface, Event Topology, Data Model, and Code Map rows | `architecture` |

Two rules this command owns:

1. **Keep the before text.** Before you replace any spec block, append it verbatim to the change-request file's `## Replaced spec text` section — the file path, the ID, then the old text in a fenced block. Step 9 builds the report from it, and an interrupted run keeps it.
2. **The screen the user approved goes into the spec.** Put the Step 4 ASCII art in the feature's `REQUIREMENTS.md` UI section and the scenario's `**UI:**` block.

Set `state: code` when this step completes.

## Step 7: Write the Code, Then the Tests

Follow the task order. The host rules and the loaded principles govern every edit. Put traceability comments carrying the `FEAT-`, `UC-`, and `SC-` IDs on every production file a task produces. Comment the constraint that forced a shape, never the code itself.

The standing rule bites hardest here. A shape the plan did not settle is a fork: a reused module or a second one, a scope, a name. Choose it and record it as you go, not at the end.

Then the tests, per the `testing` skill: integration tests exclusively, outer-edge mocking, names that read as sentences, IDs in comments, exact pinned values, the test path from plan-authoring's Test File Convention. Two rules this command owns:

- **A fix starts with a failing test that reproduces the defect.** Write it, watch it fail, then correct the code.
- **Reconcile what a change retired.** Delete the tests of every scenario the spec no longer holds. Rewrite a changed expectation rather than keeping the old one beside it. Never turn a retired behavior into a test that asserts it is gone.

Set `state: validate` when the last task's code and tests are on disk.

## Step 8: Validate Only What Changed

Resolve the runner per the `testing` skill's Runner Inference from `specs/TECH-STACK.md`. Then run **only** the tests for the use cases you touched, plus the tests of every feature your change reached. **Never run the whole suite.** The user runs the full suite themselves.

Coverage is scoped per the `testing` skill: a new file in full, the changed lines of an existing file. A pre-existing file below the floor is legacy coverage — report it, never block on it, and offer the GitHub issue per the `github-issues` skill.

**Before you blame your change for a failure, prove the failure is yours.** Save the working tree to the scratchpad, stash your changes, run the failing test against `HEAD`, then restore and verify the restore byte for byte. Report a pre-existing failure as pre-existing.

Loop until the tests you wrote pass and the linters the project configures are clean. Then close the books:

1. Tick every `## [ ] T-NNN` in the change-request file to `## [x]`.
2. Flip each stamped changelog entry to `[implemented]` and move it to the top of `DONE:`, per `uc-log`.
3. Write each touched use case to `status: implemented` and roll the features up, per `status-rollup`.

Set `state: report`.

## Step 9: Report

Read `${CLAUDE_PLUGIN_ROOT}/build/skills/change-report/SKILL.md` now. Fill its template from the run: the saved `## Replaced spec text` blocks, the decisions section, the new-ID list, and the validation results.

Append the finished report to the change-request file as its final `## Report` section, **and** print the same report to the screen. The double write is deliberate: the file is the durable record the user re-reads, the screen is the delivery. Set `state: done` and tick the last Progress box.
