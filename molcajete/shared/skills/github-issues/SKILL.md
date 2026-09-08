---
name: github-issues
description: >-
  How Molcajete opens a GitHub issue for work it found but does not do here.
  Owns the label vocabulary (AI-finding plus one kind label), the label creation
  that must run first, the batched offer question, the issue body shape, and the
  rule that every issue carries the Molcajete prompt that fixes it. Loaded by
  /m:review and /m:preflight for an out-of-scope observation, and by /m:execute
  and /m:build for a file under the coverage threshold.
---

# GitHub Issues

Molcajete opens an issue for a real problem it found while doing something else. The review commands find them beside the change they judge. `/m:execute` and `/m:build` find them in a file they edited but did not write. In both cases the work belongs to a later pull request, and the issue is how it survives until then.

Every issue this skill produces is **findable** and **actionable**: findable because the labels say where it came from and what class it belongs to, actionable because it carries the prompt that fixes it.

## Labels

Every issue carries **`AI-finding`**, plus exactly **one** kind label.

`AI-finding` marks the source. The user filters on it to see everything Molcajete raised, apart from the issues people wrote by hand. The kind label marks the class, so the user takes them one class at a time.

| Kind label | What earns it |
|---|---|
| `bug` | The code does the wrong thing |
| `coverage` | Code below the coverage threshold, or behavior no test asserts |
| `rule violation` | Breaks a project rule, an engineering principle, or the architecture |
| `spec` | Behavior no specification describes |

Map a review finding onto a kind label by its issue type:

| Finding type | Kind label |
|---|---|
| `bug` | `bug` |
| `low-coverage`, `missing-test` | `coverage` |
| `missing-spec` | `spec` |
| `rule`, `architecture`, `shortcut`, `confusing` | `rule violation` |

**Never attach two kind labels.** When a finding fits two rows, take the one that names the work the fix does. An untested rule violation is `rule violation`, because the fix changes the code and the test follows it.

### Create the labels first

`gh issue create --label` fails on a label the repository does not define, and the issue is lost with the command. Run the creation before the first issue. Each command is safe to repeat, and `|| true` absorbs the "already exists" error:

```bash
gh label create "AI-finding"     --color BFD4F2 --description "Found by a Molcajete review" 2>/dev/null || true
gh label create "bug"            --color D73A4A --description "Something does not work" 2>/dev/null || true
gh label create "coverage"       --color D4C5F9 --description "Below the coverage threshold" 2>/dev/null || true
gh label create "rule violation" --color FBCA04 --description "Breaks a project rule or an engineering principle" 2>/dev/null || true
gh label create "spec"           --color 0E8A16 --description "Behavior no specification describes" 2>/dev/null || true
```

Then open the issue with both labels:

```bash
gh issue create --title "<title>" --label "AI-finding" --label "coverage" --body "<body>"
```

## The Offer

**Ask once for the whole list. Never once per item.** None of this work belongs to the run the user is in, so it never earns one conversation per item.

1. **Check the remote.** Run `gh repo view --json nameWithOwner`. If `gh` is absent or the command fails, print one line — "No GitHub repository reachable, so these stay in this report." — and stop here.
2. **Write the brief** per the `asking-questions` skill: the table of what was found, plus the title and the labels each issue would carry. The question itself carries none of it.
3. **Ask:**
   - Question: the caller's own wording, naming what the issues would be for
   - Header: "Observations" for a review finding, "Coverage" for a threshold breach
   - Options: "Open all" / "Let me pick" / "Open none"
4. **On "Let me pick"**, ask again with one option per item and `multiSelect: true`. Four options is the hard cap, so ask in batches of four when there are more than four.
5. **Create the labels, then the approved issues.**

Print each created issue as `#<n> <url>` on its own line, and record the URL against the item it came from, so the report or document that follows carries it.

## The Issue Body

The body carries what a person needs to pick the work up cold, months later, with none of this session's context.

````markdown
Found while <what was running>, outside the scope of that work.

**Location** — `src/auth/session.ts:88`

**What it is** — `refreshToken()` returns `null` on every failure, so an expired token and a network failure look identical to every caller.

**Why it is separate** — the line predates that branch, and the change did not touch it.

**Fix with Molcajete**

1. Spec the error path and log the work:

```
/m:cover "the refresh-token error path at src/auth/session.ts:88 — refreshToken() returns null on every failure, and no scenario describes the expired-token case"
```

2. Run the plan it writes:

```
/m:execute <plan-id>
```
````

## Every Issue Carries a Prompt

**No exception.** An issue that states a problem and no way in hands the reader a research task, and it sits unfixed. The prompt is what turns the issue into work someone can start.

- **Resolve every value before you write it.** The `UC-XXXX`, the `file:line`, and the behavior in one sentence. A prompt that tells its reader to work something out is not finished.
- **List multiple commands in run order**, numbered, each in its own fenced block, with one line above it that says what it does.
- **A route through `/m:cover`, `/m:fix`, or `/m:change` always takes at least two commands.** Each of them writes a plan and stops, so the list ends with `/m:execute <plan-id>` or the work never runs.
- **When no command owns the work** — a behavior-preserving cleanup — write the direct instruction in the fenced block instead: the `file:line`, the change, the reason, and the constraint that behavior stays identical.

Pick the command from the `change-review` skill's **Choosing the Fix Command**, which maps what the fix must move onto the command that owns it.
