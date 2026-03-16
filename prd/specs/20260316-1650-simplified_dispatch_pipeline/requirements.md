# Requirements: Simplified Dispatch Pipeline

**Feature ID:** 20260316-1650-simplified_dispatch_pipeline
**Status:** Draft
**Created:** 2026-03-16
**Last Updated:** 2026-03-16

---

## 1. Overview

### Feature Description

Replace the v3 four-phase UC dispatch pipeline with a simplified three-agent model. The current architecture spreads each use case across four distinct AI calls (plan, bdd, task, validate) managed by a 764-line dispatch.sh with a phase state machine. This compounds failure probability, loses context between calls, and produces untestable intermediate output.

The v3-2 approach uses one Planner call to generate tasks.json, then a dispatch loop that orchestrates three agents per UC inside a single worktree: a **Tester** writes BDD step definition bodies (red phase), a **Developer** implements subtasks one at a time with a lightweight LLM review after each commit, and a **Validator** runs the BDD test suite — only on green does it merge the worktree to the base branch. The dispatcher is simplified to a linear orchestration loop with no phase state machine.

Additionally, the `/m:tasks` command must stop producing UC-000 "Shared Prerequisites" sections. Every UC must have a corresponding BDD feature file so the dispatcher can validate it.

### Strategic Alignment

| Aspect | Alignment |
|--------|-----------|
| Mission | Core to Molcajete's value proposition: reliable agentic workflows that produce trustworthy output |
| Roadmap | "Coordinated Builds" is a Now priority; v3-2 replaces the broken v3 implementation |
| Success Metrics | Time to complete a spec run; percentage of tasks marked done with passing tests; dispatcher script size |

### User Value

| User Type | Value Delivered |
|-----------|-----------------|
| Plugin user (developer) | `/m:run` produces working code with passing tests instead of stalling or producing unverified output |
| Plugin maintainer | Dispatcher is a simple linear loop instead of a 764-line phase state machine; three well-scoped agents instead of four overlapping phases |

### Success Criteria

| Criterion | Target | Measurement |
|-----------|--------|-------------|
| Dispatch simplicity | Linear orchestration loop, no phase state machine | Code review |
| AI calls per subtask | 2 max (Developer + review) | Count calls in dispatch loop |
| UC validation | BDD tests pass for every completed UC | Test exit code = 0 |
| No untestable UCs | Every UC in tasks.json has a feature_file | Schema validation |
| Spec completion rate | Higher than v3 (which effectively produced 0% trusted output) | End-to-end test with a real spec |

---

## 2. Use Cases

### UC-0Rz0-001: Simplified Planner

Parse `tasks.md` into `tasks.json` with a simplified schema — no phase field, UC-level `done` boolean, `feature_file` and `tag` per UC. Match each UC to its BDD feature file in `bdd/features/`.

**Primary Actor:** `/m:run` command (automated)
**Preconditions:** `tasks.md` exists in the spec folder; BDD feature files exist in `bdd/features/`
**Postconditions:** `tasks.json` written with all UCs mapped to feature files; all subtasks marked `pending`

### UC-0Rz0-002: Three-Agent Dispatch Loop

Create one worktree per UC. Three agents operate inside the worktree:

1. **Tester** (`run/test.md`) — called once per UC, before any subtask begins. Reads requirements, spec, feature files, and step stubs. Writes step definition bodies (fills TODOs with real assertions). Commits step definitions. This is the red phase — tests should fail because no production code exists yet.
2. **Developer** (`run/build.md`) — called once per subtask, in dependency order. Implements production code, runs unit tests, commits. A lightweight LLM review checks each subtask after commit. The Developer does not write step definitions, run BDD tests, or merge.
3. **Validator** (inline Bash in dispatch.sh) — called once per UC, after all subtasks are done. Runs BDD tests inside the worktree. On green: merges worktree to base branch. On red: feeds test output back to Developer for fix (max 2 retries).

The merge is the Validator's responsibility, not the Developer's. The base branch never receives untested code. Continue until all UCs complete or fail.

**Primary Actor:** `dispatch.sh` (automated, called by `/m:run`)
**Preconditions:** `tasks.json` exists with valid schema; BDD feature files and step stubs exist (from `/m:stories`); Claude CLI available via `claude -p`
**Postconditions:** Each completed UC has passing BDD tests and is merged to the base branch; `tasks.json` updated with final status per subtask and UC; base branch only contains validated code

### UC-0Rz0-003: Task Planning Without UC-000

The `/m:tasks` command must generate tasks.md without infrastructure-only UC-000 sections. Infrastructure tasks are absorbed by the first UC that needs them. Every UC must correspond to testable user-facing behavior with a BDD feature file.

**Primary Actor:** Plugin user running `/m:tasks`
**Preconditions:** `spec.md` exists in the feature folder
**Postconditions:** `tasks.md` generated with no UC-000 section; first UC absorbs all groundwork; every UC has testable acceptance criteria

### UC-0Rz0-004: Status Reporting and Documentation

Update `status.sh`, `README.md`, and skill documentation to reflect the v3-2 architecture. Remove all references to phases, phase state machine, and UC-000 pattern.

**Primary Actor:** Plugin maintainer
**Preconditions:** v3-2 dispatch loop implemented
**Postconditions:** `status.sh` reads `done` boolean; README Coordinated Builds section rewritten; agent-coordination skill updated; project-management skill updated

---

## 3. User Stories

### Plugin User Stories

| ID | As a | I want | So that | Priority |
|----|------|--------|---------|----------|
| US-0Rz0-001 | plugin user | to run `/m:run` and get working code with passing tests | I can trust the output without manually checking every file | Critical |
| US-0Rz0-002 | plugin user | the dispatcher to retry failed subtasks automatically | I don't have to manually re-run tasks that hit transient errors | High |
| US-0Rz0-003 | plugin user | every UC to have a BDD validation gate | I know with certainty which UCs are done and which are not | Critical |
| US-0Rz0-004 | plugin user | `/m:tasks` to not create UC-000 sections | every UC I implement has testable acceptance criteria | High |

### Plugin Maintainer Stories

| ID | As a | I want | So that | Priority |
|----|------|--------|---------|----------|
| US-0Rz0-005 | maintainer | dispatch.sh to be a simple linear loop | the dispatcher is debuggable and auditable | High |
| US-0Rz0-006 | maintainer | no phase state machine in the dispatcher | I can reason about the dispatch loop without tracking 6 states | High |

### Acceptance Criteria

#### US-0Rz0-001: Trustworthy `/m:run` output

- [ ] Each completed UC has a BDD test suite that passes (exit code 0)
- [ ] Base branch only receives code that passed BDD validation (merge happens after tests, not before)
- [ ] `tasks.json` reflects actual completion status (not self-reported by Developer)
- [ ] Failed subtasks are retried up to 2 times before marking as failed

#### US-0Rz0-003: UC-level BDD validation

- [ ] Dispatcher runs `behave --tags=@uc-{id}` (or equivalent) inside the UC worktree when all subtasks are done
- [ ] Test exit code determines UC status, not Developer's text output
- [ ] Only after tests pass, worktree is merged to base branch
- [ ] If BDD tests fail, a new Developer session is started with full UC context and test output for fix (max 2 retries); base branch untouched

#### US-0Rz0-004: No UC-000 in task plans

- [ ] `/m:tasks` generates tasks.md with no `UC-{tag}-000` section
- [ ] Infrastructure tasks (command skeleton, argument router, shared migrations) are subtasks of the first UC
- [ ] Cross-UC dependencies point backward only (UC-002 depends on UC-001, never forward)

---

## 4. Functional Requirements

### Planner (maps to UC-0Rz0-001)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0Rz0-001 | Planner reads `tasks.md` and generates `tasks.json` with simplified schema: UC-level `done`, `feature_file`, `tag`; subtask-level `status`, `retries`, `commit`, `error` | Critical |
| FR-0Rz0-002 | Planner matches each UC to its BDD feature file in `bdd/features/` by UC tag (`@uc-{id}`) | Critical |
| FR-0Rz0-003 | Planner rejects tasks.md files that contain UC-000 sections (fail with clear error message) | High |
| FR-0Rz0-004 | tasks.json uses flat subtask status (`pending | in_progress | done | failed`), no phase field on UCs | Critical |
| FR-0Rz0-039 | If `tasks.json` already exists when Planner runs, detect it and offer to resume (skip done UCs, restart failed ones) rather than regenerating from scratch | High |
| FR-0Rz0-040 | Planner validates that `bdd/steps/` exists and contains step files before launching dispatch | High |

### Three-Agent Dispatch Loop (maps to UC-0Rz0-002)

#### Dispatcher

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0Rz0-005 | Dispatcher creates one worktree per UC; all agents operate inside it | Critical |
| FR-0Rz0-006 | Dispatcher orchestrates three agents per UC in order: Tester (once) -> Developer (per subtask) -> Validator (once) | Critical |
| FR-0Rz0-007 | Dispatcher updates `tasks.json` after each subtask completion and UC validation | Critical |
| FR-0Rz0-008 | Dispatcher cleans up UC worktree after successful merge; preserves worktree on failure for manual inspection | Medium |
| FR-0Rz0-009 | Dispatcher handles rate limits with exponential backoff (30s base, max 2 retries) | Medium |
| FR-0Rz0-010 | dispatch.sh is a simplified linear orchestration loop with no phase state machine | High |

#### Tester (`run/test.md`)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0Rz0-011 | Tester is invoked once per UC, inside the UC worktree, before any subtask begins | Critical |
| FR-0Rz0-012 | Tester reads requirements, spec, tasks.md, and feature files tagged `@uc-{id}` | Critical |
| FR-0Rz0-013 | Tester reads step stub files (with TODO bodies from `/m:stories`) and fills them with real assertions | Critical |
| FR-0Rz0-014 | Tester commits step definitions inside the UC worktree | High |
| FR-0Rz0-015 | Tester returns structured JSON: `{status, step_files, scenarios_count, commit}` | High |
| FR-0Rz0-016 | Tester uses `--max-turns 30` and `--max-budget-usd 3.00` as safety bounds | High |
| FR-0Rz0-038 | Tester is retried up to 2 times on failure (transient errors, rate limits, timeouts) before marking UC as failed | High |

#### Developer (`run/build.md`)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0Rz0-017 | Developer is invoked once per subtask, inside the UC worktree, after Tester has written step definitions | Critical |
| FR-0Rz0-018 | Developer reads task brief, feature file (for context), and existing step definitions (written by Tester) | Critical |
| FR-0Rz0-019 | Developer implements production code and runs unit tests for the subtask | Critical |
| FR-0Rz0-020 | Developer commits work inside the UC worktree; does NOT merge, run BDD tests, or write step definitions | Critical |
| FR-0Rz0-021 | Developer returns structured JSON via `--json-schema`: `{status, files_modified, commit, error}` | Critical |
| FR-0Rz0-022 | Developer uses `--name "$TASK_ID"` for session naming and `--resume` for retry cycles | High |
| FR-0Rz0-023 | Developer uses `--max-turns 30` and `--max-budget-usd 3.00` as safety bounds | High |
| FR-0Rz0-024 | After each Developer commit, a lightweight LLM review checks: work committed, files look correct, no obvious errors; returns `pass/fail` verdict (`--max-turns 5`, `--max-budget-usd 0.50`) | High |
| FR-0Rz0-025 | If LLM review fails, Developer is retried with feedback (max 2 retries) | High |

#### Validator (inline Bash in dispatch.sh)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0Rz0-026 | Validator runs BDD tests inside the UC worktree with `--tags=@uc-{id}` after all subtasks are done | Critical |
| FR-0Rz0-027 | Validator uses test exit code as done signal (not Developer or Tester output) | Critical |
| FR-0Rz0-028 | Only after BDD tests pass, the Validator merges the UC worktree to the base branch | Critical |
| FR-0Rz0-029 | If BDD tests fail, a new Developer session is started with full UC context (all subtask briefs, test failure output, full diff) for fix inside worktree; max 2 retries; base branch is never polluted | High |

### Task Planning Reform (maps to UC-0Rz0-003)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0Rz0-030 | `/m:tasks` Step 6 removes UC-000 extraction logic; replaces with "absorb into first UC" rule | Critical |
| FR-0Rz0-031 | Cross-UC dependencies resolved by reordering UCs, not extracting shared prerequisites | High |
| FR-0Rz0-032 | project-management skill bans UC-000 pattern; documents "first UC absorbs infrastructure" rule | High |

### Status and Documentation (maps to UC-0Rz0-004)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0Rz0-033 | `status.sh` displays UC-level `done` boolean and subtask-level status; no phase counters | Medium |
| FR-0Rz0-034 | `agent-coordination/SKILL.md` documents three-agent chain for `/m:run`: Tester -> Developer x N -> Validator | Medium |
| FR-0Rz0-035 | README Coordinated Builds section rewritten for v3-2 architecture (worktree-per-UC, three agents, merge-after-validation) | Medium |
| FR-0Rz0-036 | `plugin.json` updated: remove deleted phase commands, add `run/build.md` and `run/test.md` | Medium |
| FR-0Rz0-037 | `tech-stack.md` updated to describe v3-2 dispatcher model with three agents | Low |

---

## 5. Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-0Rz0-001 | Developer call completes within timeout | 897 seconds per subtask (existing MOLCAJETE_TASK_TIMEOUT) |
| NFR-0Rz0-002 | Subtask LLM review completes quickly | Under 30 seconds; max 5 turns |
| NFR-0Rz0-003 | Total cost per subtask | Under $4.00 (Developer $3.00 + review $0.50 + buffer) |
| NFR-0Rz0-004 | dispatch.sh maintainability | Simplified linear loop; no nested state machines |
| NFR-0Rz0-005 | BDD gate latency | Under 60 seconds for a typical UC test suite |

---

## 6. Technical Considerations

### Integration Points

| System | Integration |
|--------|-------------|
| `claude -p` CLI | Developer and review calls via `--output-format json`, `--json-schema`, `--name`, `--resume` |
| BDD test runner | Determined by `bdd/CLAUDE.md` in target project (behave, cucumber-js, godog) |
| Git worktrees | One per UC; cleanup after merge, preserved on failure |
| Go Task (`task`) | Taskfile.yml launches dispatch.sh and status.sh |

### Performance Requirements

| Metric | Target | Rationale |
|--------|--------|-----------|
| Subtask dispatch latency | Under 5 seconds overhead per subtask | Dispatch loop should not add significant time beyond the Developer call itself |
| Schema parsing | Under 1 second | `jq` operations on tasks.json must be fast even with 20+ subtasks |

### Security Considerations

- [ ] `--dangerously-skip-permissions` used only in headless dispatch; compensate with `--max-turns` and `--max-budget-usd` bounds
- [ ] Developer cannot `git push` — only commits locally; push is done by the user after review

---

## 7. User Experience

### User Flows

**Flow 1: Run a spec end-to-end**

1. User runs `/m:run {spec-folder}`
2. Planner generates tasks.json from tasks.md
3. User reviews summary table and confirms launch
4. Per UC: dispatcher creates worktree, runs Tester (step definitions), iterates subtasks (Developer -> review), then runs Validator (BDD gate) inside worktree
5. Only UCs with passing tests get merged to base branch
6. User sees final completion report with pass/fail per UC

### Error States

| Scenario | Handling |
|----------|----------|
| No BDD feature files found for a UC | Planner validation fails; UC not dispatched |
| `bdd/steps/` missing or empty | Planner rejects with error: "Step files required — run /m:stories first" |
| Developer call times out | Subtask marked failed; retried up to 2 times |
| Tester fails to write step definitions | Retried up to 2 times; UC marked failed if all retries exhausted |
| BDD tests fail after all subtasks done | New Developer session started with full UC context and test output; max 2 fix retries |
| Rate limit hit | Exponential backoff (30s base); retry up to 2 times |
| tasks.md contains UC-000 | Planner rejects with error: "UC-000 not allowed; absorb infrastructure into first UC" |

---

## 8. Scope Definition

### In Scope

- [ ] Rewrite `dispatch.sh` with three-agent orchestration model
- [ ] Rewrite `run.md` with simplified Planner and tasks.json schema
- [ ] Delete 4 phase commands (`run/plan.md`, `run/bdd.md`, `run/task.md`, `run/validate.md`)
- [ ] Update `/m:tasks` to remove UC-000 pattern
- [ ] Update `status.sh` for new schema
- [ ] Update `plugin.json` to remove deleted commands
- [ ] Update skills: agent-coordination, project-management
- [ ] Update documentation: README, tech-stack.md

### Out of Scope

- Agent Teams integration — too experimental and expensive (3-5x cost)
- Claude Agent SDK migration — keep raw `claude -p` for simplicity
- Parallel UC dispatch — start with sequential; parallelism is a future optimization
- Changes to `/m:dev` or `/m:fix` beyond compatibility verification

### MVP Boundaries

| Feature | MVP | Future |
|---------|-----|--------|
| Dispatch model | Sequential subtasks, one UC at a time | Parallel UCs with file-level isolation |
| Worktree strategy | One per UC (all agents share the same worktree) | Parallel UC worktrees with file-level isolation |
| LLM review | Basic merge/correctness check | Full code review with structured findings |
| BDD gate | Run tests, check exit code | Detailed scenario-level reporting |

---

## 9. Dependencies

### Technical Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| `claude` CLI | Latest (supports `--json-schema`, `--name`, `--resume`) | Developer and review calls |
| `jq` | 1.6+ | JSON parsing in dispatch.sh |
| `git` | 2.20+ | Worktree management |
| `task` (Go Task) | 3.x | Taskfile.yml orchestration |

### Feature Dependencies

| Depends On | Relationship |
|------------|--------------|
| BDD feature files | Must exist before `/m:run`; generated by `/m:stories` |
| tasks.md | Must exist before `/m:run`; generated by `/m:tasks` |
| spec.md | Must exist before `/m:tasks`; generated by `/m:spec` |

### Blocked By

- None — can proceed independently. v3 branch remains as reference.

---

## 10. Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| dispatch.sh rewrite introduces new bugs | Specs fail to complete | Medium | Test with 1-UC and 3-UC specs before merging |
| `--json-schema` flag behavior undocumented on error | Dispatch loop hangs on malformed output | Medium | Add `--max-turns` as fallback; test error cases explicitly |
| UC-000 removal breaks specs with genuine cross-UC deps | Dependency resolution fails | Low | Verify absorption logic with real specs |
| Subtask LLM review adds cost | Budget per spec run increases | Low | Cap at $0.50 per review; skip if budget exceeded |
| Starting from master loses v3 improvements | Merge lock, worktree reuse may be needed | Medium | Cherry-pick specific improvements if needed |

---

## 11. Related Documents

| Document | Location |
|----------|----------|
| Research | [v3-2-redesign.md](../../../research/v3-2-redesign.md) |
| Impact Analysis | [impact.md](./impact.md) |
| Spec | [spec.md](./spec.md) |
| Tasks | [tasks.md](./tasks.md) |

---

## 12. Open Questions

| # | Question | Status | Answer |
|---|----------|--------|--------|
| 1 | Should the Planner reject tasks.md with UC-000, or silently absorb it into UC-001? | Closed | Reject with clear error message. Simpler implementation; pushes the fix to `/m:tasks` where it belongs. |
| 2 | What happens when a UC has no matching feature file in bdd/features/? | Closed | Planner validation rejects it. Every UC must have a feature file. |
| 3 | Should the Developer prompt include the full spec.md or just the task brief? | Closed | File reference, not pasted content. Developer reads files directly. |
| 4 | Is `--json-schema` reliable enough to replace text parsing, or do we need a fallback? | Open | Must be tested before building dispatch.sh. Test: call `claude -p --json-schema` with prompts that hit budget/turn limits to verify output format on error paths. If unreliable, add a text-parsing fallback. |
