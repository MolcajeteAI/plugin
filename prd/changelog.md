# Molcajete.ai Changelog

Chronological record of implemented changes. Each entry links to its plan file and per-task changelog file for detailed context.

## How to Use This Document

- **Organized chronologically** — newest entries first within each date group.
- **Entries link to detail files**: plan files describe what was planned, per-task changelog files describe what was implemented.
- **Update after each task**: add a dated entry when a task or fix is completed.
- Per-task changelog files live in `prd/specs/{feature}/plans/changelog-*.md`.

---

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
