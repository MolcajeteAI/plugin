---
name: plan-adaptation
description: >-
  Lets /m:build change the plan it is running instead of halting. Owns the trigger catalog
  (the seven discoveries that used to stop a run), the two amendment operations (insert a task,
  revise a task), the slot-and-run task ID scheme, the three-option gate, the adaptation budget,
  and the audit trail. Calls plan-authoring to write task prose and spec-revision to edit specs.
  Loaded by /m:build.
---

# Plan Adaptation

A plan is written before the code is read, so it is always a prediction. `/m:build` executes it and finds what the prediction missed: a file nothing asserts, shipped code that is broken, a spec that says the wrong thing.

Without this skill every one of those discoveries ends the run. The user starts `/m:fix` or `/m:change`, gets a second plan, and now holds two unfinished plans instead of one. Do that twice and nothing finishes.

This skill gives `/m:build` a third move between "carry on blind" and "stop": **change the plan and keep going.** The build drafts the correction, shows it, asks once, and continues in the same run.

**Three rules bound it.** The build never amends silently — every amendment passes the gate in this skill. The build never exceeds the budget — a run that keeps finding work stops and escalates rather than growing without limit. And the build never amends a completed task — `[x]` is final.

## Task IDs: Slots and Runs

`/m:plan` writes integer tags only: `T-001`, `T-002`, `T-003`. Each one is a **slot**.

An amendment converts a slot into an ordered **run** of peer tasks. Inserting two tasks ahead of `T-003` gives:

```markdown
## [x] T-002 — Store the refreshed token
## [ ] T-003.1 — Pin the current session-store behavior
## [ ] T-003.2 — Correct the expiry off-by-one
## [ ] T-003.3 — Rotate the token on re-auth
```

`T-003.3` is the original `T-003`. It kept its position last in the run because that is when it runs.

### The four rules

**1. The anchor takes the last tag in its run.** Numeric order, reading order, and execution order are one sequence. Nobody ever reads a `T-003` that ran after `T-003.2`. This rule is the reason the scheme exists — an out-of-order tag makes the reader reconstruct the sequence by hand, months later, from a file that was supposed to record it.

**2. One decimal level, always.** A second amendment against slot `003` shifts the run again instead of nesting. A discovery raised while `T-003.3` is in flight produces a new `T-003.3` and moves the anchor to `T-003.4`. A tag like `T-003.1.1` never appears.

**3. A completed task never moves.** On insertion, every task from the insertion point through the anchor shifts up by the number of tasks added. All of them are incomplete by definition: the anchor is the task that raised the trigger, and nothing after the insertion point has run. A tag already written into a commit message or an escalation filename is therefore permanent.

**4. No bare `T-003` survives an amendment.** This is what keeps the notation clear of any subtask reading — there is no parent left for `T-003.1` to be a child of. Every `T-003.N` is a full, independent task and a peer of the others, with its own `Kind`, `Covers`, checkbox, test run, coverage gate, and commit. **A plan has no subtask concept.** The decimal marks a position in a run, not a level in a tree.

Because `/m:plan` writes only integer tags, a decimal tag is itself the signal that the build amended that slot.

### What names a task

| Reference | Resolves to |
|---|---|
| `/m:build <plan-id> T-003` after slot `003` was amended | every task in the run, in order |
| `**Depends on:** T-003` written before the amendment | satisfied when **every** task in the run reads `[x]` |
| `**Depends on:** T-003.2` | that one task |

A dependency line written before an amendment therefore never needs editing, and it never becomes weaker than it was.

## The Trigger Catalog

Seven discoveries reach this skill. Each names the `/m:build` sub-step that detects it. All seven halt the run outright when this skill is not in play.

| ID | Trigger | Detected at | Spec edit | Produces | Skip |
|----|---------|-------------|-----------|----------|------|
| A1 | A coverage gap maps to no current `SC-XXXX` | 8.7 | yes | `cover` or `fix` task | no |
| A2 | A file the task touches has no canonical coverage | 8.2 | no | `cover` task | yes |
| A3 | A `cover` task is RED before assertions — shipped code is broken | 8.5 | maybe | `fix` task | no |
| A4 | The Reviewer returns `spec_defect` — the spec is wrong or silent | 8.10 | yes | `fix` or `change` task | no |
| A5 | Phase 2 cannot reach GREEN because a dependency behaves wrong | 8.6 | maybe | `fix` task | no |
| A6 | Plan drift against provenance | 5.2 | no | revised task | yes |
| A7 | A file invariant is broken — a file the task creates already exists | 8.2 | no | revised task | yes |

**Spec edit** says whether the discovery can need a spec fact the specs do not carry. `maybe` means the diagnosis decides.

**Skip** says whether the gate may offer "Note and continue". It is `no` wherever the current task cannot finish without the correction — offering to skip there would only produce a failed task two minutes later. A1 blocks on the coverage floor. A3, A4, and A5 block on a test that will not go green.

**Nothing outside this catalog is a trigger.** A discovery that fits no row is not an amendment — halt with the escalation the sub-step already defines. Growing the catalog is a change to this skill, not a judgment call inside a run.

## The Procedure

Run these five steps in order for each discovery.

### 1. Classify

Match the discovery to exactly one catalog row. Read the row's `Spec edit` and `Skip` columns — they set what the next steps may do.

### 2. Check the budget

Read the `adaptation` block resolved in `/m:build` Step 3. When `maxAmendments` is already spent, stop here: halt with an escalation naming the budget, the amendments already made, and this discovery. Do not ask — there is nothing the user could choose that the budget allows.

When `allowSpecEdits` is `false` and the row's `Spec edit` is `yes`, do the same and name the setting.

### 3. Diagnose, and edit the spec when the row allows it

Skip this step for a row whose `Spec edit` is `no`.

Run the three-way diagnosis from the `spec-revision` skill against the discovery: is the spec already right and the code wrong, is the spec silent, or is the spec wrong? Then:

| Diagnosis | Spec edit | Task kind |
|-----------|-----------|-----------|
| Spec correct, code wrong | none | `fix` |
| Spec silent | add the missing scenario or FR | `fix` |
| Spec wrong | correct the offending scenario or FR, increment the UC `version` | `change` |

Apply the edit per `spec-revision`'s spec-edit rules, including its module-instance fan-out — a UC that lives in three modules gets the same edit in all three unless the user narrows it at the gate. Run the `resolution-gate` categories `/m:fix` uses.

**Draft the edit; do not write it yet.** The edit is presented at the gate together with the task it produces, and both are applied by one answer. A spec edited before the user agrees to it is a spec edited without consent.

### 4. Draft the amendment

Pick the operation.

**Insert** — for a discovery that needs work the plan does not do. Write one to `maxTasksPerAmendment` new tasks per the `plan-authoring` skill's Task Shape and Task Prose rules: full prose naming the files, the entry point, how the test proves it, and the trade-offs. An amended task is a real task and gets a real task's contract; a thin one fails at 8.4 because the build cannot scaffold a test from it.

Give each new task the kind step 3 decided, or the kind the catalog row names when there was no spec edit. Assign tags per the slot-and-run rules, and set `**Depends on:**` so each inserted task depends on whatever the anchor already depended on.

**Revise** — for a discovery that means an existing task is wrong rather than missing. Rewrite that task's `Kind`, `Covers`, `Depends on`, or prose. Never touch a task whose checkbox reads `[x]`, and never change a tag. When the task needing revision is already complete, this is not a revise: it is an insert of new work that corrects it.

### 5. Ask, once

Per the `asking-questions` skill: the brief carries the decision, the question carries one sentence.

Write the brief as Markdown, in this order: what the build was doing when it found this, and what it found, stated concretely with the file and the test output or coverage number; the spec edit as a diff-style before-and-after when step 3 drafted one; the drafted tasks as a table of tag, kind, outcome, and covers, followed by each task's full prose; and one line saying how many amendments the budget allows and how many are left.

- Question: "`{T-NNN}` needs work the plan does not have. How should I proceed?"
- Header: "Amend plan"
- Options: "Amend and continue" / "Note and continue" / "Stop here"

Omit "Note and continue" when the catalog row's `Skip` is `no`. Recommend "Amend and continue" for every row except A6, where drift means the user may want to re-plan from the specs instead.

The discovery goes in the brief, never in `question` and never in an option `preview`. It is identical under every option, so it is shared context.

## What Each Answer Does

### Amend and continue

Apply the operation, in this fixed order, so a failure part-way through leaves no half-state that claims to be more than it is:

1. **Write the spec edit** drafted in step 3, if any, per `spec-revision`.
2. **Write the changelog entry**, if there was a spec edit: insert a new `pending` entry on each edited module-instance per the `uc-log` skill's mutation 1, with the `command:` token matching the diagnosis (`fix` or `change`), then flip it to `dirty` and stamp `plan:<running-plan-id>` per mutation 2. The running plan now owns that work, which is exactly true — a task in it closes the entry.
3. **Write the plan file.** Insert or revise the task sections, re-tag the run per the slot-and-run rules, and add the audit lines below. Change nothing else in the file: no prose in untouched tasks, no `**Specs:**` line, and never the `**Provenance:**` line, which records what was true when the plan was written.
4. **Re-derive `**Mode:**`** on the `**Specs:**` line from the task kinds now present, per `plan-authoring`.
5. **Count the amendment** against `maxAmendments`.

Then resume. The next task to run is the first `[ ]` task in file order, which is the first task just inserted.

An inserted task carries an `**Added:**` line, and the re-tagged anchor carries a `**Retagged:**` line, both directly under the `**Kind:**` field:

```markdown
## [ ] T-003.1 — Pin the current session-store behavior

**Kind:** cover
**Added:** 20260820T143052 · A2 · during T-003.3
**Covers:** SC-3Z2P
**Depends on:** T-002
```

```markdown
## [ ] T-003.3 — Rotate the token on re-auth

**Kind:** change
**Retagged:** T-003 → T-003.3 · 20260820T143052
**Covers:** SC-3Z2R
**Depends on:** T-002
```

A revised task carries `**Revised:** {timestamp} · {trigger}` in the same position. When a task is revised more than once, add a line per revision rather than editing the existing one — the audit trail is append-only for the same reason the changelog is.

Read the timestamp from the clock with `date -u +%Y%m%dT%H%M%S`. Never compose one.

### Note and continue

The user knows about the gap and chooses to finish the plan first. Record it so it is not lost, and change no task:

1. **Write a `pending` changelog entry** on each affected module-instance per `uc-log` mutation 1, with the `command:` token matching the work (`fix`, `change`, or `cover`) and `plan:—`. It stays `pending` and unstamped, so the next `/m:plan` on that UC consumes it through the ordinary path. This is the whole mechanism — no new state, no new file, nothing to remember.
2. **Append one line** to a `## Known Issues` section at the foot of the plan file, creating the section when it does not exist. One line per issue: the timestamp, the trigger ID, the task that hit it, and the reason, matching the changelog entry's reason text.

```markdown
## Known Issues

- 20260820T143052 · A2 · during T-003 — `src/auth/session.ts` has no canonical integration coverage.
```

3. **Continue the current task** from where it stopped. The task must still be able to finish, which is why this option is absent for a row whose `Skip` is `no`.

The `## Known Issues` section is the only heading in a plan file that is not a task. It never carries a checkbox, and `/m:build` never executes it.

### Stop here

The original behavior. Write `.molcajete/escalations/{plan-id}-{T-NNN}.md` carrying the discovery, the drafted amendment, and the drafted spec edit, then halt the run per `/m:build` Step 8's failure policy. Completed tasks keep their `[x]`, Step 9 still runs, and the user resolves it and re-runs `/m:build {plan-id}`.

Write the draft into the escalation file even though nothing applied it. The work of diagnosing was already done, and throwing it away makes the user do it again.

## Budget

`/m:build` Step 3 reads an `adaptation` block from `.molcajete/settings.json`:

```json
"adaptation": {
  "maxAmendments": 3,
  "maxTasksPerAmendment": 2,
  "allowSpecEdits": true
}
```

| Key | Default | Meaning |
|-----|---------|---------|
| `maxAmendments` | `3` | Amendments allowed in one `/m:build` run. "Note and continue" does not count — it changes no task. |
| `maxTasksPerAmendment` | `2` | Tasks one amendment may insert. A discovery needing more is too large to absorb mid-run. |
| `allowSpecEdits` | `true` | When `false`, a trigger whose row says `Spec edit: yes` escalates instead of asking. |

The count runs across the whole invocation, including discoveries raised while running a task that a previous amendment inserted. That is what stops a `cover` task from finding a bug whose `fix` task finds another gap, without end.

Set `maxAmendments` to `0` to restore the pre-adaptation behavior exactly: every trigger halts.

## Headless Runs

The gate cannot run when no user is present, and this skill never picks an option on the user's behalf — "Amend and continue" edits specs and plans, and "Note and continue" decides that a known defect is acceptable. Both are the user's call.

In a headless run every trigger writes its escalation and halts, per the `resolution-gate` skill's halt-and-escalate rule. Write the drafted amendment into the escalation file so the user can approve it in one read when they return.

## What This Skill Never Does

- It never writes production code or test code. It changes the plan; `/m:build`'s own sub-steps then run the amended task through the full lifecycle, including the coverage gate, the mutation check, and the correctness review. An amended task gets no shortcut.
- It never flips a checkbox. `/m:build` 8.11 owns that.
- It never edits the `**Provenance:**` line. That line is evidence of the plan's origin, and amending it would erase the only record drift detection reads.
- It never removes a task, a `## Known Issues` line, or an audit line.
- It never re-tags or renumbers a task whose checkbox reads `[x]`.
