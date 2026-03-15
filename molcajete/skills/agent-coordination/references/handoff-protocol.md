# Agent Handoff Protocol

Standard patterns for chaining agents in sequence, passing context between them.

## Principle

Each agent in a chain receives:
1. Its own task context (from the command)
2. The output of the previous agent (structured result)
3. Cumulative file lists (so later agents know what was created/modified)

## Pattern 1: Tester -> Developer -> Reviewer -> Committer

Used by: `/m:dev`

```
Step 1: Command gathers context (task brief, plan, BDD scenarios)
        |
Step 2: Command writes plan autonomously (no user approval)
        |
Step 3: Launch Tester agent (RED PHASE)
        - Input: task brief + plan (with planned interfaces) + step def TODOs
        - Output: FILES_MODIFIED (bdd/steps/ only), STEPS_IMPLEMENTED
        - Boundary: NO production code
        |
Step 4: RED GATE (inline Bash)
        - Run BDD: --tags=@task-{ID}
        - Expected: EXIT != 0 (tests fail — production code doesn't exist)
        |
Step 5: Launch Developer agent (GREEN PHASE)
        - Input: task brief + plan + Tester output
        - Output: FILES_CREATED, FILES_MODIFIED, TESTS_WRITTEN
        - Boundary: NO bdd/features/ changes, minor bdd/steps/ adjustments OK
        |
Step 6: GREEN GATE (inline Bash)
        - Run BDD: --tags=@task-{ID}
        - Expected: EXIT == 0 (tests pass)
        - If fail: Developer fixes -> re-run (max 3 cycles)
        |
Step 7: REGRESSION GATE (inline Bash)
        - Run BDD: --tags=@uc-{UC-ID} + unit tests + lint
        - All must pass. Fix cycles via Developer (max 3).
        |
Step 8: Launch Reviewer + README updater in parallel
        - Fix cycles as before (max 3)
        |
Step 9: Update progress (only after all gates pass)
        |
Step 10: Launch Committer
```

### Context Accumulation

```
After Tester:
  FILES_MODIFIED: [bdd/steps/gameplay_steps.py]

After Developer:
  FILES_CREATED: [src/game.ts, src/game.test.ts]
  FILES_MODIFIED: [src/app.ts]

After README updater:
  FILES_CREATED: [pkg/auth/README.md]

Committer receives: all files from Tester + Developer + README updater
```

### Failure at Any Step

- Tester fails -> stop chain, report to user
- RED GATE passes (tests unexpectedly pass) -> re-invoke Tester to strengthen assertions (max 2 retries), then skip BDD enforcement
- Developer fails -> stop chain, report to user
- GREEN GATE fails -> Developer fixes, re-run (max 3 cycles), then stop and report
- REGRESSION GATE fails -> Developer fixes, re-run (max 3 cycles), then stop and report
- Reviewer finds CRITICAL/WARNING issues -> Developer fixes, re-run Reviewer (max 3 cycles), then escalate to user
- Committer hook failure -> Developer fixes, re-run Reviewer + Committer (max 3 cycles), then escalate to user

## Pattern 1b: Developer -> Reviewer -> Committer

Used by: `/m:fix`

```
Step 1: Command gathers context (task brief, plan, BDD scenarios)
        |
Step 2: Launch Developer agent
        - Input: task brief + approved plan
        - Output: FILES_CREATED, FILES_MODIFIED, KEY_DECISIONS, TESTS_WRITTEN, FORMAT_STATUS, LINT_STATUS
        |
Step 3: Launch Reviewer + README updater in parallel
        - Reviewer input: all files from Developer output
        - Reviewer output: FINDINGS, VERDICT
        - README updater: directory scanning for README updates
        |
Step 4: Process Reviewer output
        - APPROVE (no CRITICAL/WARNING) -> Step 5
        - CRITICAL/WARNING findings -> Developer fixes -> re-run Reviewer (max 3 cycles)
        |
Step 5: Launch Committer agent
        - Input: accumulated file list + task context
        - Output: COMMIT_STATUS, COMMIT_HASH, HOOK_OUTPUT
        |
Step 6: Process Committer output
        - SUCCESS -> done
        - HOOK_FAILURE -> Developer fixes -> Reviewer -> Committer (max 3 cycles)
```

## Pattern 2: Standalone Agent

Used by: `/m:review` (Reviewer), `/m:stories` (BDD Analyst), `/m:feature` (Spec Writer), `/m:research` (Researcher)

```
Step 1: Command gathers context
        |
Step 2: Launch single agent
        - Input: command's context
        - Output: agent's standard output format
        |
Step 3: Command processes output and reports to user
```

No handoff needed — the command owns the full lifecycle.

## Pattern 3: Researcher -> Spec Writer

Used by: `/m:refactor`

```
Step 1: Command gathers context (change description, tech stack)
        |
Step 2: Launch Researcher agent in Refactor Impact mode
        - Input: change description + codebase context
        - Output: AFFECTED_MODULES, SUGGESTED_ORDER, RISKS
        |
Step 3: Launch Spec Writer agent
        - Input: Researcher's impact analysis + project-management templates
        - Output: requirements.md derived from the impact analysis
        |
Step 4: Command writes both documents and reports to user
```

### Context Passing

The Researcher's full output (impact document) is passed to the Spec Writer as input. The Spec Writer uses:
- `AFFECTED_MODULES` → functional requirements (one FR per affected module)
- `SUGGESTED_ORDER` → use cases (one UC per phase)
- `RISKS` → risk section in requirements.md

## Pattern 4: Parallel Agents

Used when agents are independent and can work simultaneously.

```
Step 1: Command gathers context
        |
Step 2: Launch agents in parallel (single message, multiple Task calls)
        - Agent A: specific context for A
        - Agent B: specific context for B
        |
Step 3: Collect all results
        |
Step 4: Merge outputs and report
```

Rules for parallel execution:
- Only parallelize agents with no data dependencies between them
- All parallel agents must be launched in a single message
- Command waits for all agents before proceeding
- If one agent fails, others are not affected — handle failure independently

## Pattern 5: BDD Setup (Standalone)

Used by: `/m:bdd-setup`

```
Step 1: Command checks for existing bdd/CLAUDE.md config
        |
Step 2: Launch BDD Setup agent
        - Input: project root path
        - Output: SETUP_STATUS, LANGUAGE, FRAMEWORK, E2E_FRAMEWORK, DB_DRIVER, DB_STATE_STRATEGY, PAGE_OBJECT_MODEL
        |
Step 3: Command presents detected values to user for confirmation
        |
Step 4: Command writes extended bdd/CLAUDE.md config
        |
Step 5: Command runs gherkin scaffold procedure
```

No handoff needed -- the BDD Setup agent returns detection results, and the command handles interactive confirmation and file writing.

## Formatter and Linter: Not Agents

Formatting and linting remain as inline Bash operations, not agent invocations. They are mechanical tasks that do not require reasoning:

```
After Developer + Reviewer chain completes:

1. Run formatter (Bash): gofmt, pnpm run format
2. Run linter (Bash): golangci-lint, pnpm run lint
3. If issues found → fix inline, re-run tests
```

These steps are orchestrated by the command, not delegated to agents.
