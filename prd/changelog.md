# Molcajete.ai Changelog

Chronological record of implemented changes. Each entry links to its plan file and per-task changelog file for detailed context.

## How to Use This Document

- **Organized chronologically** — newest entries first within each date group.
- **Entries link to detail files**: plan files describe what was planned, per-task changelog files describe what was implemented.
- **Update after each task**: add a dated entry when a task or fix is completed.
- Per-task changelog files live in `prd/specs/{feature}/plans/changelog-*.md`.

---

## 2026-03-16

- [00:16] Ban UC-000 from /m:tasks and project-management skill (UC-0Rz0-003)
  Replaced UC-000 extraction in /m:tasks Step 6 with "absorb into first UC" rule. Added UC-000 ban to SKILL.md and tasks-template.md. Every UC must have testable user-facing behavior.
  - Plan: [task-UC-0Rz0-003--1.md](specs/20260316-1650-simplified_dispatch_pipeline/plans/task-UC-0Rz0-003--1.md)
  - Changelog: [changelog-UC-0Rz0-003--1.md](specs/20260316-1650-simplified_dispatch_pipeline/plans/changelog-UC-0Rz0-003--1.md), [changelog-UC-0Rz0-003--2.md](specs/20260316-1650-simplified_dispatch_pipeline/plans/changelog-UC-0Rz0-003--2.md)

- [22:48] Create dispatch.sh three-agent orchestration loop (UC-0Rz0-002/4)
  Core dispatcher for `/m:run`. Per UC: worktree -> Tester -> Developer x N (with LLM review) -> BDD Validator -> merge on green. Linear loop, no state machine. Rate limit backoff, BDD auto-detection, jq-based tasks.json mutation.
  - Plan: [task-UC-0Rz0-002--4.md](specs/20260316-1650-simplified_dispatch_pipeline/plans/task-UC-0Rz0-002--4.md)
  - Changelog: [changelog-UC-0Rz0-002--4.md](specs/20260316-1650-simplified_dispatch_pipeline/plans/changelog-UC-0Rz0-002--4.md)

- [21:37] Create merge.sh worktree merge utility (UC-0Rz0-002/3)
  Bash utility for dispatch pipeline. Merges UC worktree into base branch after BDD validation, cleans up on success, preserves on failure. No LLM assistance.
  - Plan: [task-UC-0Rz0-002--3.md](specs/20260316-1650-simplified_dispatch_pipeline/plans/task-UC-0Rz0-002--3.md)
  - Changelog: [changelog-UC-0Rz0-002--3.md](specs/20260316-1650-simplified_dispatch_pipeline/plans/changelog-UC-0Rz0-002--3.md)

- [21:15] Create run/build.md Developer command (UC-0Rz0-002/2)
  Headless Developer agent for `/m:run` dispatch pipeline. Implements one subtask's production code, runs unit tests, commits in worktree, returns structured JSON. Reads feature files and step definitions as context only.
  - Plan: [task-UC-0Rz0-002--2.md](specs/20260316-1650-simplified_dispatch_pipeline/plans/task-UC-0Rz0-002--2.md)
  - Changelog: [changelog-UC-0Rz0-002--2.md](specs/20260316-1650-simplified_dispatch_pipeline/plans/changelog-UC-0Rz0-002--2.md)

- [20:31] Create run/test.md Tester command (UC-0Rz0-002/1)
  Headless Tester agent for `/m:run` dispatch pipeline. Reads feature files by UC tag, fills step definition TODO stubs with real assertions, commits in worktree, returns structured JSON.
  - Plan: [task-UC-0Rz0-002--1.md](specs/20260316-1650-simplified_dispatch_pipeline/plans/task-UC-0Rz0-002--1.md)
  - Changelog: [changelog-UC-0Rz0-002--1.md](specs/20260316-1650-simplified_dispatch_pipeline/plans/changelog-UC-0Rz0-002--1.md)

- [19:02] Create run.md Planner command (UC-0Rz0-001/1)
  Entry point for `/m:run`: parses tasks.md into validated tasks.json with v3-2 schema, resume flow for existing runs, feature file matching via BDD tags, 7-invariant validation, and dispatcher launch.
  - Plan: [task-UC-0Rz0-001--1.md](specs/20260316-1650-simplified_dispatch_pipeline/plans/task-UC-0Rz0-001--1.md)
  - Changelog: [changelog-UC-0Rz0-001--1.md](specs/20260316-1650-simplified_dispatch_pipeline/plans/changelog-UC-0Rz0-001--1.md)

---

## 2026-03-06 — v2.6.1

### Changed

- `git-committing` skill now owns the full commit orchestration — `commit.md` is a thin trigger that delegates entirely to the skill
- Commit orchestration gathers git context once (parallel commands) in Step 2 and reuses it throughout, eliminating redundant tool calls
- Single-commit flow drafts the message directly without spawning a sub-agent — faster path from staged changes to confirmation
- Split-flow sub-agent receives diff data inline instead of re-running git commands and reading files at runtime

---

## 2026-03-06 — v2.6.0

### Added

- Project-local Claude config (`CLAUDE.md`, `.claude/` directory) with hooks, agents, skills, and `/bump` command for in-repo development tooling
- `/bump` command for version bumping and changelog workflow
- `versioning` skill with semver conventions and changelog format rules
- `skill-reviewer` agent for checking skill consistency
- PreToolUse/PostToolUse hooks for `plugin.json` guard and frontmatter validation

### Changed

- `git-committing` skill now owns the full commit orchestration workflow — `commit.md` is a thin trigger
- Added natural language trigger phrases to `git-committing` skill description so committing works without `/m:commit`
- Commit workflow now detects large staged changes with multiple independent concerns and offers to split them into smaller logical commits, confirming each one individually

## 2026-03-06 — v2.5.0

- [add] Extract inline templates from `research-methods` skill into individual files
  Creates `templates/` directory with 6 self-contained template files (introduction, learning-guide, how-to, reference, refactor-impact, deep-research). Each file includes structure, rules, and a worked example. SKILL.md reduced from ~1057 lines to ~570 lines. Each orchestration path now reads only the template it needs instead of loading all 5 templates on every invocation. Deletes `references/templates.md` (683 lines) — content distributed into focused files.

- [add] Add `/m:explain` command — replaces `/m:summary` with a focused 3-5 minute Introduction format
  Introduces a new explain command that launches 2 parallel agents (web + local) and synthesizes findings into a friendly, beginner-oriented Introduction. Replaces the old summary command.

- [change] Merge `summary` command into `research-methods` skill
  The `research-methods` skill is now the single source of truth for all research flows. Orchestration logic (agents, synthesis, save) moved from individual commands into the skill. Commands (`/m:explain`, `/m:research`) are thin triggers that skip the router and go straight to their respective depth.

- [add] Add 3-tier routing to `research-methods` skill
  Skill now classifies requests into Quick Question (inline, no agents), Explain (2 agents, Introduction template), or Deep Research (4 agents, Learning Guide). Ambiguous requests prompt the user with AskUserQuestion.

- [add] Add Introduction template to `research-methods` skill
  New 600-1200 word template for the Explain tier. Flat structure, one analogy, one Mermaid diagram, one code example, and a "Go Deeper" section instead of a raw sources list.

- [change] Skill triggers on natural language
  The `research-methods` skill description now includes natural language trigger phrases so it activates without a slash command ("explain X", "research X", "help me understand X", etc.).

- [remove] Remove `/m:summary` command

## 2026-02-27

- [15:23] Fix: Use UTC for all timestamps
  Adds explicit UTC qualification to all timestamp references in skill files and commands — changelog HH:MM entries, feature folder YYYYMMDD-HHmm naming, and Base-62 tag epoch. Ensures consistency across time zones.
  - Plan: [fix-utc-timestamps.md](specs/chores/plans/fix-utc-timestamps.md)
  - Changelog: [changelog-fix-utc-timestamps.md](specs/chores/plans/changelog-fix-utc-timestamps.md)

## 2026-02-24

- [14:30] Add codebase exploration workflow for generic feature names to /m:stories
  Adds Step 2-exp (Explore Codebase for Generic Name) with changelog scanning, specs directory scanning, README scanning, source code scanning as last resort, and disambiguation logic for ambiguous or missing matches.
  - Plan: [task-UC-0KTg-005--1.md](specs/20260223-1600-bdd_scenario_generator/plans/task-UC-0KTg-005--1.md)
  - Changelog: [changelog-UC-0KTg-005--1.1.md](specs/20260223-1600-bdd_scenario_generator/plans/changelog-UC-0KTg-005--1.1.md), [changelog-UC-0KTg-005--1.2.md](specs/20260223-1600-bdd_scenario_generator/plans/changelog-UC-0KTg-005--1.2.md), [changelog-UC-0KTg-005--1.3.md](specs/20260223-1600-bdd_scenario_generator/plans/changelog-UC-0KTg-005--1.3.md)

- [02:15] Add index rebuild from file system to /m:stories
  Adds section 2h (Rebuild Indexes from File System) with language-aware extraction for features and steps, domain/category grouping, and change reporting.
  - Plan: [task-UC-0KTg-004--1.2.md](specs/20260223-1600-bdd_scenario_generator/plans/task-UC-0KTg-004--1.2.md)
  - Changelog: [changelog-UC-0KTg-004--1.2.md](specs/20260223-1600-bdd_scenario_generator/plans/changelog-UC-0KTg-004--1.2.md)

- [02:00] Add index drift detection to /m:stories
  Adds section 2g (Validate Index Files) with drift detection logic — compares INDEX.md entries against actual files on disk, reports stale and missing entries.
  - Plan: [task-UC-0KTg-004--1.1.md](specs/20260223-1600-bdd_scenario_generator/plans/task-UC-0KTg-004--1.1.md)
  - Changelog: [changelog-UC-0KTg-004--1.1.md](specs/20260223-1600-bdd_scenario_generator/plans/changelog-UC-0KTg-004--1.1.md)

- [01:00] Add scenario append, deduplication, and file splitting to /m:stories
  Adds existing-feature handling: duplicate scenario detection (exact + near-duplicate with user prompt), append-to-file instructions preserving existing content, INDEX.md append-only updates, and feature file splitting when scenario count exceeds 15.
  - Plan: [task-UC-0KTg-003--1.1.md](specs/20260223-1600-bdd_scenario_generator/plans/task-UC-0KTg-003--1.1.md), [task-UC-0KTg-003--1.2.md](specs/20260223-1600-bdd_scenario_generator/plans/task-UC-0KTg-003--1.2.md), [task-UC-0KTg-003--2.md](specs/20260223-1600-bdd_scenario_generator/plans/task-UC-0KTg-003--2.md)
  - Changelog: [changelog-UC-0KTg-003--1.1.md](specs/20260223-1600-bdd_scenario_generator/plans/changelog-UC-0KTg-003--1.1.md), [changelog-UC-0KTg-003--1.2.md](specs/20260223-1600-bdd_scenario_generator/plans/changelog-UC-0KTg-003--1.2.md), [changelog-UC-0KTg-003--2.md](specs/20260223-1600-bdd_scenario_generator/plans/changelog-UC-0KTg-003--2.md)

- [00:30] Add PRD spec integration for UC-ID arguments
  Enhances Step 1b with detailed spec extraction and adds Step 3 preamble for implementation-specific scenario generation.
  - Plan: [task-UC-0KTg-002--4.md](specs/20260223-1600-bdd_scenario_generator/plans/task-UC-0KTg-002--4.md)
  - Changelog: [changelog-UC-0KTg-002--4.md](specs/20260223-1600-bdd_scenario_generator/plans/changelog-UC-0KTg-002--4.md)

- [00:15] Embed step definition templates in /m:stories
  Adds Python/behave, Go/godog, and TypeScript/cucumber-js step definition templates as a reference section.
  - Plan: [task-UC-0KTg-002--3.md](specs/20260223-1600-bdd_scenario_generator/plans/task-UC-0KTg-002--3.md)
  - Changelog: [changelog-UC-0KTg-002--3.md](specs/20260223-1600-bdd_scenario_generator/plans/changelog-UC-0KTg-002--3.md)

- [00:00] Embed feature file templates in /m:stories
  Adds standard Gherkin and MDG feature file templates as a reference section.
  - Plan: [task-UC-0KTg-002--2.md](specs/20260223-1600-bdd_scenario_generator/plans/task-UC-0KTg-002--2.md)
  - Changelog: [changelog-UC-0KTg-002--2.md](specs/20260223-1600-bdd_scenario_generator/plans/changelog-UC-0KTg-002--2.md)

## 2026-02-23

- [18:30] Add index update instructions to /m:stories
  Adds section 3d (Update Index Files) ensuring both features and steps INDEX.md are updated after every generation.
  - Plan: [task-UC-0KTg-002--1.3.md](specs/20260223-1600-bdd_scenario_generator/plans/task-UC-0KTg-002--1.3.md)
  - Changelog: [changelog-UC-0KTg-002--1.3.md](specs/20260223-1600-bdd_scenario_generator/plans/changelog-UC-0KTg-002--1.3.md)

- [18:15] Add step definition generation rules to /m:stories
  Adds section 3c (Generate Step Definitions) with INDEX.md reuse check, step file placement rules, docstring requirements, and language consistency enforcement.
  - Plan: [task-UC-0KTg-002--1.2.md](specs/20260223-1600-bdd_scenario_generator/plans/task-UC-0KTg-002--1.2.md)
  - Changelog: [changelog-UC-0KTg-002--1.2.md](specs/20260223-1600-bdd_scenario_generator/plans/changelog-UC-0KTg-002--1.2.md)

- [18:00] Add feature file generation rules to /m:stories
  Adds Step 3 (Generate Scenarios) with domain folder placement and Gherkin generation rules: kebab-case naming, tag requirements, declarative Given/exact Then rules, and construct selection.
  - Plan: [task-UC-0KTg-002--1.1.md](specs/20260223-1600-bdd_scenario_generator/plans/task-UC-0KTg-002--1.1.md)
  - Changelog: [changelog-UC-0KTg-002--1.1.md](specs/20260223-1600-bdd_scenario_generator/plans/changelog-UC-0KTg-002--1.1.md)

- [17:00] Initialize BDD scaffold instructions
  Adds scaffold creation to `/m:stories`: directory structure, domain detection (6-priority algorithm), language/format detection, INDEX.md templates, and world/context module templates for Python, Go, and TypeScript.
  - Changelog: [changelog-UC-0KTg-001.md](specs/20260223-1600-bdd_scenario_generator/plans/changelog-UC-0KTg-001.md)

- [16:30] Implement shared prerequisites for BDD Scenario Generator
  Creates the `/m:stories` command file skeleton with YAML frontmatter, argument parsing (UC-ID, feature name, generic name), summary output template, error handling, and plugin registration.
  - Changelog: [changelog-UC-0KTg-000.md](specs/20260223-1600-bdd_scenario_generator/plans/changelog-UC-0KTg-000.md)

- [--:--] Product documentation initialized
  Created `prd/` directory with mission, tech-stack, roadmap, and changelog documents.

## 2026-02 (Pre-PRD)

The following features were built before product documentation was established. Entries are derived from git history.

- Clipboard skill and command integration (d6be7d8)
  Added clipboard skill and updated commands to use it.

- v2 workflow redesign (c0a9ee2)
  Redesigned Molcajete.ai with v2 workflow — new command structure, skill organization, and plugin format.

- Command updates for Bash allowed-tools (249e05c)
  Updated commands to use `Bash(*)` allowed-tools format.

- Heredoc removal from commit commands (9bc633d)
  Removed heredoc usage from commit commands for compatibility.

- Loop command removal (fe6fc67)
  Removed the loop command from the command set.
