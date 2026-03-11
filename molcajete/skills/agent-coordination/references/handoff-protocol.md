# Agent Handoff Protocol

Standard patterns for chaining agents in sequence, passing context between them.

## Principle

Each agent in a chain receives:
1. Its own task context (from the command)
2. The output of the previous agent (structured result)
3. Cumulative file lists (so later agents know what was created/modified)

## Pattern 1: Developer -> Reviewer -> Committer

Used by: `/m:dev`, `/m:fix`

```
Step 1: Command gathers context (task brief, plan, BDD scenarios)
        |
Step 2: Launch Developer agent
        - Input: task brief + approved plan
        - Output: FILES_CREATED, FILES_MODIFIED, KEY_DECISIONS, TESTS_WRITTEN, BDD_TASK_STATUS, FORMAT_STATUS, LINT_STATUS
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

### Context Accumulation

The Developer produces all code and test files. The Reviewer receives the full file list. The Committer receives the accumulated file list from all agents:

```
After Developer:
  FILES_CREATED: [a.go, b.go, a_test.go, b_test.go]
  FILES_MODIFIED: [c.go]

Reviewer receives: all 5 files above

After README updater:
  FILES_CREATED: [pkg/auth/README.md]

Committer receives: all 6 files (Developer + README updater output)
```

### Failure at Any Step

- Developer fails -> stop chain, report to user
- Reviewer finds CRITICAL/WARNING issues -> Developer fixes, re-run Reviewer (max 3 cycles), then escalate to user
- Committer hook failure -> Developer fixes, re-run Reviewer + Committer (max 3 cycles), then escalate to user

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
