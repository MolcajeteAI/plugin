---
name: blocker-protocol
description: >-
  What a build does when it meets an issue outside its scope — shipped code
  that is broken, a test that fails for a reason the work did not cause, a
  platform limit. Owns the size test that splits small from significant, the
  rule that a small issue is fixed in place and recorded, the brief for a
  significant one (why, what if not, effort in counted units), the two-option
  question, and the rule that the build never creates a branch. Loaded by
  /m:build and /m:execute. Runs before the plan-adaptation catalog.
---

# Blocker Protocol

Every issue a build meets mid-run is a reason to change the plan. Most of them should not be. This skill draws one line, once, so that a run fixes what is small and stops for what is not. The run never widens its own scope to decide.

## What Is Out of Scope

An issue is **out of scope** when both hold:

1. No task in the plan covers the behavior.
2. The file, test, setting, or tool it lives in is not one the current task creates or modifies.

Everything else is the task's own work and follows the caller's own retry and escalation rules. The task's own failing test is never out of scope. Do not run this protocol on it.

## The Size Test

An out-of-scope issue is **small** only when every one of these is true:

1. The fix changes at most 2 files.
2. The fix creates no production file.
3. The fix changes no spec. No scenario, requirement, or `ARCHITECTURE.md` row is wrong or missing because of it.
4. The fix changes no behavior a scenario asserts. It restores what the spec already states, or it touches test scaffolding only.
5. The fix adds no setting, no dependency, and no migration.
6. A test asserts the corrected behavior after the fix, and it is green. The current task's test or an existing canonical test both count.
7. You can state the fix in one sentence.

When any condition is false, the issue is **significant**. When you cannot decide a condition, the issue is **significant**. Never round down.

## A Small Issue

Fix it inside the current task, in the same edit set, and record it. The record has one fixed shape:

```markdown
- {timestamp} · fixed in passing · during {T-NNN} — `{file}`: {the one sentence}. {N} files, no spec.
```

Read the timestamp from the clock with `date -u +%Y%m%dT%H%M%S`. Never compose one.

The caller says where the record goes:

| Caller | Where |
|--------|-------|
| `/m:execute` | Under `## Fixed in passing` at the foot of the plan file, created when it does not exist. Printed again in the Step 11 report. |
| `/m:build` | Under `## Decisions taken, and what was rejected` in the change-request file. |

A fix in passing is never silent.

## A Significant Issue

Stop the current task. Do not start the fix. Do not create a branch, a stash, or a commit. Write the brief below, then ask the one question.

## The Brief

Write it as Markdown in your response, per the `asking-questions` skill. This is the shape:

````markdown
## Blocker — {the issue, in a few words}

**What I need to decide.** Whether this run absorbs the fix, or stops so the fix lands first.

**Where we are.** {T-NNN and its outcome} · {the sub-step} · {what the build was doing}.

**What I found.** {file:line, the command, and the output, quoted.}

|  |  |
|---|---|
| Why it must be fixed | {one or two sentences} |
| If it is not fixed | {what fails, or what ships wrong} |
| Why it is out of scope | {no task covers it · the file belongs to {feature}} |
| Effort | {N} files · {N} tests · {N} specs · {N} use cases · {N} tasks |

**Amend and continue**

{The task or tasks the run would insert, as a table: tag, kind, outcome, covers. The run grows by that many tasks and the fix ships in this branch.}

**Stop here**

{The escalation path. The ready prompt, on a branch off `master`. The command that resumes this run.}

**Recommendation.** {label} — {one clause}.
````

Effort is a count. Never write hours or days. A model estimates in human time, and that number argues for the cheap option.

## The Question

```
- Question: "`{T-NNN}` is blocked by work outside the plan. How should I proceed?"
- Header: "Blocker"
- Options: "Amend and continue" / "Stop here"
```

Two options. Never a third. Recommend **Stop here** when the fix reaches a spec, another feature's use case, or more than one task. Recommend **Amend and continue** otherwise. The drafted task prose goes below the recommendation, the way the `plan-adaptation` brief carries it.

## What Each Answer Does

| Caller | Amend and continue | Stop here |
|--------|--------------------|-----------|
| `/m:execute` | This is trigger **A8** in the `plan-adaptation` skill. Its Amend path inserts the drafted `fix` task (or `cover` + `fix`) ahead of the current task, counts the budget, and resumes. | The `plan-adaptation` skill's Stop-here path writes the escalation file. For A8 the file also carries the ready prompt and the branch name. |
| `/m:build` | Insert the task ahead of the current one in the change-request file, tagged per the `plan-adaptation` skill's **Task IDs: Slots and Runs** section. That section is the only part of that skill this command reads. Add the `**Added:**` line. Record the fork under `## Decisions taken, and what was rejected`. Continue. | Record the fork under Decisions with "the user chose to stop". Write `.molcajete/escalations/{change-request-id}-blocker.md` with the brief and the ready prompt. Leave the frontmatter `state` as it is, so Step 2 resumes the run later. Print the brief. Stop. |

## The Ready Prompt

Always a `/m:build "..."` command, with every value resolved. The reader starts work from it. Nothing in it is left for them to decide. When a spec already states the behavior, one line above the prompt names the narrower command in parentheses:

````markdown
(Alternative command: /m:fix UC-XXXX "...")

```
/m:build "..."
```
````

Name the branch: `fix/{slug}` off `master`. The user lands it, updates the current branch, and re-runs the command that stopped.

## What This Skill Never Does

- It never creates a branch, a stash, or a commit.
- It never picks an option in a headless run. It writes the escalation and halts, per the `resolution-gate` skill.
- It never widens the size test in the moment. The seven conditions are the whole test.
- It never turns a small issue into a task.
