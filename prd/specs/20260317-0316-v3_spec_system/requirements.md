# Requirements: V3 Use-Case-Centric Spec System

**Feature ID:** 20260317-0316-v3_spec_system
**Status:** Draft
**Created:** 2026-03-17
**Last Updated:** 2026-03-17

---

## 1. Overview

### Feature Description

Molcajete v3 replaces the old task-centric spec scaffolding (timestamped folders with throwaway `requirements.md`, `spec.md`, `tasks.md`, `impact.md`) with a knowledge-centric system where features and use cases are permanent, verifiable artifacts. Features are constants. Use cases are the variable set that grows. Plans are ephemeral — generated at runtime, not stored on disk.

The plugin restructures from a flat `commands/` and `skills/` directory into two fully independent subsystems: **Plan** (defining what to build) and **Build** (implementing and verifying what Plan defined). Each subsystem owns its own commands and skills with no shared skills between them — duplication is preferred over premature abstraction. All commands use the `/m:command` format (plugin namespace with colon separator), as required by the Claude Code plugin system. Commands and skills not part of either subsystem are moved to a `deprecated/` folder.

The new system introduces EARS syntax for requirements, Fit Criteria for verifiability, explicit Side Effects on every use case, C4 architecture diagrams, ER diagrams with invariants, event topology tables, a Feature Inventory (`FEATURES.md`), an Actors catalog (`ACTORS.md`), a domain Glossary (`GLOSSARY.md`), and a four-agent run pipeline (Planner, Tester, Developer, Verifier) that generates plans at execution time.

### Strategic Alignment

| Aspect | Alignment |
|--------|-----------|
| Mission | Directly advances "every developer gets the same high-quality, structured output" by making specs permanent, verifiable, and traceable rather than throwaway scaffolding |
| Roadmap | Implements the v3 architecture — the primary NOW priority on the roadmap |
| Success Metrics | First-run implementation accuracy of `/m:run`; time-to-spec for new features; traceability coverage (feature to Gherkin) |

### User Value

| User Type | Value Delivered |
|-----------|-----------------|
| Individual developers using Claude Code | Specs that accumulate knowledge rather than being rebuilt each time; one lookup in FEATURES.md to understand what exists; unambiguous EARS requirements that agents implement correctly on the first run |
| Team leads managing Claude Code teams | Consistent feature inventory across the team; full traceability from feature to Gherkin tag; architecture conformance checking via Verifier agent |

### Success Criteria

| Criterion | Target | Measurement |
|-----------|--------|-------------|
| Spec permanence | Features and use cases persist as living documents, never rebuilt from scratch | No timestamped throwaway folders created by v3 commands |
| Traceability | Every feature traces to use cases, use cases trace to Gherkin tags | FEATURES.md -> USE-CASES.md -> @UC-NNN tag chain is complete for every specified feature |
| First-run accuracy | /m:run implements a UC correctly without human intervention | Gherkin scenarios pass on first pipeline run for UCs with complete specs |
| Side effect coverage | Every UC's declared side effects appear in Gherkin scenarios | Verifier agent reports zero uncovered side effects |

---

## 2. Use Cases

### UC-0S96-001: Set Up Project Foundation

The user runs `/m:setup` on a new or existing project to generate the foundational documents (`PROJECT.md`, `TECH-STACK.md`, and `ACTORS.md`) that all other commands depend on. This UC also includes creating the skill templates for `PROJECT.md`, `TECH-STACK.md`, and `ACTORS.md` that the command uses to generate these documents. During setup, the system interviews the user for actor definitions — if actors can be inferred from the project description or codebase, the system suggests them and asks the user to confirm before writing.

**Primary Actor:** Developer
**Preconditions:** No `prd/PROJECT.md` or `prd/TECH-STACK.md` exists yet (or user wants to regenerate them)
**Postconditions:** `prd/PROJECT.md`, `prd/TECH-STACK.md`, and `prd/ACTORS.md` exist with user-reviewed content; skill templates for all three documents exist in the plan skills directory. If a codebase existed, the system inferred the tech stack and actors from code and confirmed with the user. If no codebase existed, the user described them directly.

### UC-0S96-002: Create Feature

The user runs `/m:feature` with freeform input to create a new feature entry. The command extracts structure from the input, presents it section-by-section for review (creation interview), and writes `requirements.md`, `USE-CASES.md`, and an `architecture.md` scaffold in `prd/features/{slug}/`. It also registers the feature in `prd/FEATURES.md`. This UC also includes creating the skill templates for `requirements.md`, `USE-CASES.md`, `architecture.md`, and `FEATURES.md` that the command uses to generate these documents.

**Primary Actor:** Developer
**Preconditions:** `prd/PROJECT.md` and `prd/TECH-STACK.md` exist; `prd/FEATURES.md` exists (created by `/m:setup` or manually)
**Postconditions:** Feature directory exists with `requirements.md` (EARS syntax, Fit Criteria), `USE-CASES.md` (empty or with extracted UCs), `architecture.md` scaffold; `FEATURES.md` has new row with status `scoped`; skill templates for all four documents exist in the plan skills directory

### UC-0S96-003: Create Use Case

The user runs `/m:usecase {FEAT-NNN} {input}` to create a new use case file within a feature. The command follows the creation interview pattern — extracts shared context (name, actor, preconditions, trigger) and flat peer scenarios (each with Given, Steps, Outcomes, Side Effects) from the input, then reviews shared context followed by each scenario individually. A scenario loop allows adding scenarios until the user is done. This UC also includes creating the skill template for use case files that the command uses to generate the UC document.

**Primary Actor:** Developer
**Preconditions:** Feature exists in `prd/features/{slug}/`; `USE-CASES.md` exists for that feature
**Postconditions:** `UC-NNN-{slug}.md` exists in `use-cases/` with flat scenario structure; `USE-CASES.md` updated with new row; feature status in `FEATURES.md` may advance; skill template for use case files exists in the plan skills directory

### UC-0S96-004: Create or Update Architecture

The user runs `/m:spec {FEAT-NNN}` to generate or update `architecture.md` for a feature. The command reads the feature's `requirements.md` and UC files, then produces C4 L1/L2 diagrams, ER diagrams with invariants, event topology table, state transition diagrams, and architecture decision records.

**Primary Actor:** Developer
**Preconditions:** Feature exists with at least `requirements.md` populated
**Postconditions:** `architecture.md` exists with C4 Context (L1), Container (L2), Data Model (ER + invariants), Event Topology table, State Transitions (if applicable), and ADRs

### UC-0S96-005: Generate Database Schema

The user runs `/m:schema` to scan the codebase for migrations, ORM definitions, or model files and generate or update `prd/SCHEMA.md` — the project-level database schema. The schema document uses Mermaid ER diagrams for visual representation. This UC also includes creating the skill template for `SCHEMA.md` that the command uses to generate the document.

**Primary Actor:** Developer
**Preconditions:** Codebase has database-related files (migrations, ORM models, schema definitions)
**Postconditions:** `prd/SCHEMA.md` exists with Mermaid ER diagrams and all tables, fields, types, constraints, and invariants extracted from the codebase; skill template for SCHEMA.md exists in the plan skills directory

### UC-0S96-006: Generate Gherkin Stories

The user runs `/m:stories {UC-NNN}` to generate Gherkin scenarios from a use case file. The command references the `gherkin` skill (`./skills/gherkin`) for scenario generation rules, tag conventions, and step writing patterns. It reads the UC's preconditions, trigger, and flat scenario blocks (each with Given, Steps, Outcomes, Side Effects), then produces tagged Gherkin scenarios with side effect coverage.

**Primary Actor:** Developer
**Preconditions:** UC file exists with all fields populated; parent feature has `architecture.md` (for side effect and data model context); `gherkin` skill exists in the plan skills directory
**Postconditions:** Gherkin feature file exists with `@FEAT-NNN @UC-NNN` tags; every UC scenario block produces a Gherkin scenario; every side effect has an `And` clause; every explicit non-side-effect has an `And no ...` clause

### UC-0S96-007: Run Four-Agent Pipeline

The existing `/m:run` command is renamed to `/m:run`, moved to `molcajete/build/commands/`, and updated with three changes: (1) it now accepts one or more `{FEAT-NNN}` and/or `{UC-NNN}` arguments, including mixed input — expanding features to their new/dirty UCs, merging all targets, resolving inter-UC dependencies, and executing in dependency order; (2) the dispatcher builds a dependency graph from UC preconditions and architecture references, topologically sorts it, and executes in the correct order regardless of the order the user provides; (3) it switches from the current three-agent pipeline to a four-agent pipeline — Planner, Tester, Developer, Verifier. The Planner reads all spec artifacts and produces a cohesive implementation plan in context; Tester writes Gherkin scenarios (red phase); Developer implements until all scenarios pass (green phase); Verifier checks feature completeness, FR/NFR compliance, architecture conformance, and side effect coverage.

**Primary Actor:** Developer
**Preconditions:** UC file(s) exist with all fields populated; `architecture.md` exists; `GLOSSARY.md` exists; `PROJECT.md` and `TECH-STACK.md` exist
**Postconditions:** Code implements the UC; all Gherkin scenarios pass; UC status is `live`; feature `USE-CASES.md` updated; `FEATURES.md` status updated if all UCs are `live`

### UC-0S96-008: Update Feature

The user runs `/m:update-feature {FEAT-NNN} {description}` to modify an existing feature's `requirements.md` and/or `architecture.md`. The command reads the current state, proposes specific changes, and applies them after review.

**Primary Actor:** Developer
**Preconditions:** Feature exists with `requirements.md`
**Postconditions:** `requirements.md` and/or `architecture.md` updated; feature status unchanged (update commands don't change lifecycle state)

### UC-0S96-009: Update Use Case

The user runs `/m:update-usecase {UC-NNN} {description}` to modify an existing UC file. The command reads the current UC, proposes specific changes, increments the version, and sets status to `dirty`.

**Primary Actor:** Developer
**Preconditions:** UC file exists
**Postconditions:** UC file updated with version incremented; status set to `dirty`; `USE-CASES.md` status column updated

### UC-0S96-010: Reverse-Engineer Feature from Code

The user runs `/m:reverse-feature {description}` to scan the codebase for an existing capability and generate a feature directory with `requirements.md`, `USE-CASES.md`, `architecture.md`, and individual UC files populated from the code.

**Primary Actor:** Developer
**Preconditions:** Codebase has an existing capability not yet documented in the spec system
**Postconditions:** Feature directory exists under `prd/features/` with all documents populated from code analysis; `FEATURES.md` has new row

### UC-0S96-011: Reverse-Engineer Use Case from Code

The user runs `/m:reverse-usecase {description}` to scan the codebase for a specific interaction and generate a single UC file with all fields populated from the code.

**Primary Actor:** Developer
**Preconditions:** Feature directory exists; codebase has an existing interaction not yet documented
**Postconditions:** UC file created with all fields populated from code; `USE-CASES.md` updated

### UC-0S96-012: Reverse-Engineer Glossary from Code

The user runs `/m:reverse-glossary {seed terms}` to scan the codebase for how terms are used and generate a starter `prd/GLOSSARY.md`.

**Primary Actor:** Developer
**Preconditions:** Codebase exists; no `prd/GLOSSARY.md` exists yet (or user wants to regenerate)
**Postconditions:** `prd/GLOSSARY.md` exists with definitions derived from code usage

### UC-0S96-013: Restructure Plugin into Plan/Build

The plugin's flat `molcajete/commands/` and `molcajete/skills/` directories are reorganized into two independent subsystems: `molcajete/plan/` and `molcajete/build/`. Each subsystem has its own `commands/` and `skills/` directories. Commands and skills that don't belong to either subsystem (e.g., commit, review, doc, research) remain at the plugin root (`molcajete/commands/`, `molcajete/skills/`). No `/shared` directory — the root level serves that purpose. The plugin manifest (`plugin.json`) is updated to reference the new paths and the `/m:command` naming convention.

**Primary Actor:** Developer (plugin maintainer)
**Preconditions:** Current flat plugin structure exists
**Postconditions:** `molcajete/plan/commands/`, `molcajete/plan/skills/`, `molcajete/build/commands/`, `molcajete/build/skills/` directories exist; shared commands remain at `molcajete/commands/`; shared skills remain at `molcajete/skills/`; `plugin.json` updated with new paths and `/m:command` naming; no `molcajete/shared/` directory

### UC-0S96-014: Deprecate Old Commands

Commands not part of the Plan or Build subsystems are moved to `molcajete/deprecated/commands/`. The plugin manifest no longer references them, but the files are preserved for reference.

**Primary Actor:** Developer (plugin maintainer)
**Preconditions:** Current commands exist in `molcajete/commands/`
**Postconditions:** The following commands are in `molcajete/deprecated/commands/`: init, tasks, feature (v2), spec (v2), stories (v2), amend, rebase, copy, prompt, explain, fix, refactor. The following commands remain active (outside pipeline but kept): commit, review, doc, research. Plugin manifest updated.

### UC-0S96-015: Deprecate Language/Stack Skills

Language-specific and stack-specific skills are moved to `molcajete/deprecated/skills/`. The plugin manifest no longer references them.

**Primary Actor:** Developer (plugin maintainer)
**Preconditions:** Language/stack skills exist in `molcajete/skills/`
**Postconditions:** The following skills are in `molcajete/deprecated/skills/`: go-writing-code, go-testing, node-writing-code, node-testing, typescript-writing-code, typescript-testing, react-writing-code, react-testing, react-components, tailwind-css. Remaining workflow/utility skills stay in place until v3 is complete, then evaluated.

---

## 3. User Stories

### Developer Stories

| ID | As a | I want | So that | Priority |
|----|------|--------|---------|----------|
| US-0S96-001 | developer | to run a single setup command and get my project's foundational docs generated | I don't need to manually create PROJECT.md and TECH-STACK.md | Critical |
| US-0S96-002 | developer | to describe a feature in freeform text and get structured EARS requirements back | I get unambiguous requirements without learning EARS syntax myself | Critical |
| US-0S96-003 | developer | to create use cases with flat peer scenarios, each with explicit side effects and non-side-effects | agents implement the complete behavior including all side effects on the first run | Critical |
| US-0S96-004 | developer | architecture docs generated with C4 diagrams, ER with invariants, and event topology | implementing agents know exactly which components exist and how they relate | Critical |
| US-0S96-005 | developer | to run /m:run on a use case and have four agents (plan, test, build, verify) handle it | I get unattended implementation with verification that nothing was missed | Critical |
| US-0S96-006 | developer | to look up FEATURES.md and instantly know what the system does | I don't need to scan directories or read multiple files to understand the system | High |
| US-0S96-007 | developer | to run /m:stories on a UC and get Gherkin with full side effect coverage | the verification gate catches incomplete implementations | High |
| US-0S96-008 | developer | to update a use case and have its status go to `dirty` | I know which UCs need /m:run to catch up with spec changes | High |
| US-0S96-009 | developer | to reverse-engineer specs from an existing codebase | I can adopt this system on projects that already have code | Medium |
| US-0S96-010 | developer | to generate a project-level database schema from codebase | agents have the full data model context when implementing | Medium |
| US-0S96-011 | developer | commands organized into Plan and Build subsystems | each agent's context stays focused and within the instruction ceiling | High |

### Acceptance Criteria

#### US-0S96-001: Project setup

- [ ] `/m:setup` interviews the user for project description, tech stack, and actors
- [ ] Generates `prd/PROJECT.md` with 1-2 paragraph description
- [ ] Generates `prd/TECH-STACK.md` with languages, frameworks, data, infrastructure, conventions
- [ ] Generates `prd/ACTORS.md` with actor roles, descriptions, and permissions/constraints
- [ ] If actors can be inferred from project description or codebase, suggests them and asks user to confirm
- [ ] Creates `prd/GLOSSARY.md` with starter terms
- [ ] Creates `prd/FEATURES.md` with empty table
- [ ] Creates `prd/features/` directory

#### US-0S96-002: Feature creation with EARS

- [ ] `/m:feature` accepts freeform text input
- [ ] Extracts and presents back: name, non-goals, actors, FRs (EARS syntax), NFRs, acceptance criteria
- [ ] User reviews each section before file creation
- [ ] Generates `requirements.md` with EARS requirements and Fit Criteria
- [ ] Generates `USE-CASES.md` index
- [ ] Generates `architecture.md` scaffold
- [ ] Registers feature in `FEATURES.md` with status `scoped`

#### US-0S96-003: Use case creation with side effects

- [ ] `/m:usecase` accepts feature ID and freeform text
- [ ] Extracts and presents: name, actor, preconditions, trigger, and scenarios (each with Given, Steps, Outcomes, Side Effects)
- [ ] User reviews shared context (name, actor, preconditions, trigger) then each scenario individually
- [ ] Scenario loop: after reviewing extracted scenarios, asks "Add another scenario?" until user is done
- [ ] Writes UC file with flat scenario structure (no main/alternative distinction)
- [ ] Updates parent feature's `USE-CASES.md`

#### US-0S96-004: Architecture generation

- [ ] `/m:spec` reads feature's requirements.md and UC files
- [ ] Generates C4 System Context (L1) Mermaid diagram
- [ ] Generates C4 Container View (L2) Mermaid diagram
- [ ] Generates ER diagram with field constraints
- [ ] Writes invariants block below ER diagram
- [ ] Generates event topology table (event, publisher, payload, condition, consumers)
- [ ] Generates state transition diagram for entities with lifecycle
- [ ] Includes ADR section for non-obvious decisions

#### US-0S96-005: Four-agent run pipeline

- [ ] `/m:run {UC-NNN}` runs Planner, Tester, Developer, Verifier in sequence
- [ ] `/m:run {UC-NNN} {UC-NNN} ...` accepts multiple UCs, resolves dependencies, executes in dependency order
- [ ] `/m:run {FEAT-NNN}` expands to new/dirty UCs, resolves dependencies, iterates until all live
- [ ] `/m:run {FEAT-NNN} {FEAT-NNN} ...` accepts multiple features with cross-feature dependency resolution
- [ ] `/m:run {FEAT-NNN} {UC-NNN}` accepts mixed input (features + UCs)
- [ ] Dispatcher builds dependency graph and topologically sorts (not user-provided order)
- [ ] Dispatcher detects and reports dependency cycles, stops without executing
- [ ] Planner reads PROJECT.md, TECH-STACK.md, ACTORS.md, GLOSSARY.md, FEATURES.md, requirements.md, architecture.md, UC file
- [ ] Planner produces implementation plan in context (not written to disk)
- [ ] Tester writes Gherkin scenarios from UC file with full side effect coverage
- [ ] Developer implements until all scenarios pass
- [ ] Verifier checks: feature completeness, FR/NFR compliance, architecture conformance, non-goals respected, side effect coverage
- [ ] UC status updated to `live` on success
- [ ] FEATURES.md status updated if all UCs in feature are `live`

#### US-0S96-006: Feature inventory lookup

- [ ] `FEATURES.md` has columns: ID, Feature, Description, Status, Tag, Directory
- [ ] Status values: backlog, scoped, specified, building, live, dirty, deprecated
- [ ] Feature IDs are `FEAT-NNN-slug` format, sequential, never reused
- [ ] Tag column has `@FEAT-NNN` for Gherkin filtering

#### US-0S96-007: Gherkin with side effect coverage

- [ ] `/m:stories {UC-NNN}` reads UC file fields
- [ ] UC Preconditions map to `Background: Given` block
- [ ] Scenario Given maps to additional `Given` / `And` after Background
- [ ] Scenario Steps map to `When` / `And` clauses
- [ ] Scenario Outcomes map to `Then` clauses
- [ ] Scenario Side Effects (positive) map to `And` clauses
- [ ] Scenario Side Effects ("No ...") map to `And no ...` clauses
- [ ] Every scenario in the UC produces a corresponding Gherkin scenario
- [ ] Scenarios tagged with `@FEAT-NNN @UC-NNN`

#### US-0S96-008: Use case updates and dirty status

- [ ] `/m:update-usecase {UC-NNN}` reads current UC file
- [ ] Shows proposed changes against current state
- [ ] Increments version in frontmatter on apply
- [ ] Sets status to `dirty`
- [ ] Updates `USE-CASES.md` status column

---

## 4. Functional Requirements

### Project Foundation (maps to UC-0S96-001)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0S96-001 | When the user runs `/m:setup`, the system shall interview the user for a project description, tech stack, and actors, then generate `prd/PROJECT.md`, `prd/TECH-STACK.md`, and `prd/ACTORS.md`. If a codebase exists, the system shall infer the tech stack and actors from code and confirm with the user; if no codebase exists, the user describes them directly | Critical |
| FR-0S96-002 | When the user runs `/m:setup`, the system shall also create `prd/GLOSSARY.md` with starter terms, `prd/FEATURES.md` with an empty feature table, and `prd/features/` directory | Critical |
| FR-0S96-055 | When the system can infer actors from the project description or codebase during `/m:setup`, it shall suggest them to the user and ask for confirmation before writing `ACTORS.md` | Critical |
| FR-0S96-003 | The system shall use `prd/PROJECT.md` (1-2 paragraphs) instead of the v2 `prd/mission.md` for project context | Critical |
| FR-0S96-004 | The system shall use `prd/TECH-STACK.md` instead of the v2 `prd/tech-stack.md` for technology context | Critical |

### Feature Creation (maps to UC-0S96-002)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0S96-005 | When the user runs `/m:feature {input}`, the system shall extract structured content from freeform input and present it section-by-section for review before writing files | Critical |
| FR-0S96-006 | The system shall write all functional requirements in EARS syntax (When/While/If-Then patterns) with a Fit Criterion for each | Critical |
| FR-0S96-007 | The system shall place the Non-Goals section second in `requirements.md` — immediately after the one-sentence objective, before actors and requirements | Critical |
| FR-0S96-008 | When the system creates a feature, it shall generate `requirements.md`, `USE-CASES.md`, and an `architecture.md` scaffold in `prd/features/{slug}/` | Critical |
| FR-0S96-009 | When the system creates a feature, it shall register it in `prd/FEATURES.md` with a `FEAT-NNN-slug` ID and status `scoped` | Critical |

### Use Case Creation (maps to UC-0S96-003)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0S96-010 | When the user runs `/m:usecase {FEAT-NNN} {input}`, the system shall create a UC file with flat scenario structure: shared preconditions, trigger, Gherkin tags, and one or more peer scenarios each with Given, Steps, Outcomes, and Side Effects | Critical |
| FR-0S96-011 | The system shall require an explicit Side Effects field on every scenario within a use case, including deliberate non-side-effects ("No email sent", "No event published") | Critical |
| FR-0S96-012 | The system shall write one file per use case: `prd/features/{slug}/use-cases/UC-NNN-{slug}.md` | Critical |
| FR-0S96-013 | When the system creates a UC, it shall update the parent feature's `USE-CASES.md` index with the new row | Critical |
| FR-0S96-014 | The UC file shall include YAML frontmatter with: id, name, feature, status, version, actor, tag | Critical |

### Architecture (maps to UC-0S96-004)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0S96-015 | When the user runs `/m:spec {FEAT-NNN}`, the system shall generate `architecture.md` with C4 System Context (L1) and Container View (L2) Mermaid diagrams | Critical |
| FR-0S96-016 | The system shall generate ER diagrams with field constraints followed by an Invariants block listing rules the data model must never violate | Critical |
| FR-0S96-017 | The system shall generate an Event Topology table with columns: Event, Publisher, Payload, Condition, Consumers | Critical |
| FR-0S96-018 | The system shall include explicit Non-events in the event topology section for scenarios where no event should be published | High |
| FR-0S96-019 | The system shall generate state transition diagrams (Mermaid stateDiagram-v2) for entities with lifecycle | High |
| FR-0S96-020 | The system shall include an Architecture Decisions section using the format: "In the context of {situation}, facing {concern}, we decided {choice} to achieve {quality}, accepting {tradeoff}" | High |

### Schema Generation (maps to UC-0S96-005)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0S96-021 | When the user runs `/m:schema`, the system shall scan the codebase for migrations, ORM definitions, or model files and generate `prd/SCHEMA.md` using Mermaid ER diagrams for visual representation | Medium |
| FR-0S96-022 | The system shall always reverse-engineer the schema from code — there is no "create from scratch" mode | Medium |

### Gherkin Generation (maps to UC-0S96-006)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0S96-023 | When the user runs `/m:stories {UC-NNN}`, the system shall reference the `gherkin` skill (`./skills/gherkin`) for scenario generation rules and generate Gherkin scenarios from the UC file: Preconditions to Background, per-scenario Given/Steps/Outcomes/Side Effects to Gherkin Given/When/Then/And | Critical |
| FR-0S96-024 | The system shall generate an `And` clause for every declared side effect and an `And no ...` clause for every explicit non-side-effect within each scenario | Critical |
| FR-0S96-025 | The system shall tag every scenario with `@FEAT-NNN @UC-NNN` for traceability | Critical |
| FR-0S96-026 | The system shall generate a Gherkin scenario for every scenario block (S1, S2, ...) in the UC file | High |

### Run Pipeline (maps to UC-0S96-007)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0S96-027 | When the user runs `/m:run {UC-NNN}`, the system shall execute a four-agent pipeline: Planner, Tester, Developer, Verifier | Critical |
| FR-0S96-028 | When the user runs `/m:run {FEAT-NNN}`, the system shall iterate through all new or `dirty` UCs in the feature's `USE-CASES.md` and run the four-agent pipeline for each until all are `live` | Critical |
| FR-0S96-056 | When the user runs `/m:run` with multiple UCs (`/m:run UC-001 UC-003 UC-002`), the dispatcher shall resolve inter-UC dependencies, topologically sort them, and execute in dependency order regardless of input order | Critical |
| FR-0S96-057 | When the user runs `/m:run` with multiple features (`/m:run FEAT-001 FEAT-003`) or mixed input (`/m:run FEAT-001 UC-007`), the dispatcher shall expand features to their new/dirty UCs, merge all targets, resolve cross-feature dependencies, and execute in dependency order | Critical |
| FR-0S96-058 | If the dispatcher detects a dependency cycle among the target UCs, it shall report the cycle to the user and stop without executing any pipeline | Critical |
| FR-0S96-029 | The Planner agent shall read PROJECT.md, TECH-STACK.md, ACTORS.md, GLOSSARY.md, FEATURES.md, the feature's requirements.md, architecture.md, and the target UC file to produce an implementation plan | Critical |
| FR-0S96-030 | The Planner agent shall produce the plan in context only — not written to disk | Critical |
| FR-0S96-031 | The Tester agent shall receive the plan and UC file, then write Gherkin scenarios covering every scenario block (S1, S2, ...) with full side effect and non-side-effect coverage | Critical |
| FR-0S96-032 | The Developer agent shall receive the plan and failing Gherkin scenarios, then implement until all scenarios pass | Critical |
| FR-0S96-033 | The Verifier agent shall check: feature completeness, FR/NFR compliance, architecture conformance, non-goals respected, and side effect coverage | Critical |
| FR-0S96-034 | If the Verifier finds gaps, the system shall report them back to the user rather than attempting autonomous fixes | Critical |
| FR-0S96-035 | After a successful run, the system shall update the UC's status to `live`, update the feature's `USE-CASES.md`, and update `FEATURES.md` status if all UCs are `live` | High |

### Update Commands (maps to UC-0S96-008, UC-0S96-009)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0S96-036 | When the user runs `/m:update-feature {FEAT-NNN} {description}`, the system shall read the current requirements.md and architecture.md, propose specific changes, and apply after review | High |
| FR-0S96-037 | When the user runs `/m:update-usecase {UC-NNN} {description}`, the system shall increment the UC's version, set status to `dirty`, and update USE-CASES.md | High |
| FR-0S96-038 | Update commands shall not run the creation interview — they show only proposed changes against the current document | High |

### Reverse-Engineering Commands (maps to UC-0S96-010, UC-0S96-011, UC-0S96-012)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0S96-039 | When the user runs `/m:reverse-feature {description}`, the system shall scan the codebase and generate a feature directory with requirements.md, USE-CASES.md, architecture.md, and individual UC files | Medium |
| FR-0S96-040 | When the user runs `/m:reverse-usecase {description}`, the system shall scan the codebase and generate a single UC file with all fields populated from code analysis | Medium |
| FR-0S96-041 | When the user runs `/m:reverse-glossary {seed terms}`, the system shall scan the codebase and generate `prd/GLOSSARY.md` with definitions derived from code usage | Medium |

### Plugin Restructure (maps to UC-0S96-013, UC-0S96-014, UC-0S96-015)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0S96-042 | The system shall restructure the plugin into `molcajete/plan/` (commands + skills) and `molcajete/build/` (commands + skills), with commands and skills not belonging to either subsystem remaining at the plugin root (`molcajete/commands/`, `molcajete/skills/`). No `molcajete/shared/` directory. | Critical |
| FR-0S96-043 | The system shall use the `/m:command` naming format (plugin namespace with colon separator) for all commands in the plugin manifest — command names are derived from the markdown filename, and the `m:` prefix is applied automatically by the Claude Code plugin system | Critical |
| FR-0S96-044 | The system shall move deprecated commands to `molcajete/deprecated/commands/`: init, tasks, feature (v2), spec (v2), stories (v2), amend, rebase, copy, prompt, explain, fix, refactor | Critical |
| FR-0S96-045 | The system shall keep these commands active outside the pipeline: commit, review, doc, research | Critical |
| FR-0S96-046 | The system shall move language/stack skills to `molcajete/deprecated/skills/`: go-writing-code, go-testing, node-writing-code, node-testing, typescript-writing-code, typescript-testing, react-writing-code, react-testing, react-components, tailwind-css | Critical |
| FR-0S96-047 | The system shall retain existing workflow/utility skills in place until v3 is complete, then evaluate which to deprecate | High |

### Feature Inventory and Glossary (maps to UC-0S96-001)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0S96-048 | The `FEATURES.md` file shall contain columns: ID (FEAT-NNN-slug), Feature, Description, Status, Tag (@FEAT-NNN), Directory | Critical |
| FR-0S96-049 | Feature status values shall be: backlog, scoped, specified, building, live, dirty, deprecated | Critical |
| FR-0S96-050 | Feature IDs shall be sequential `FEAT-NNN-slug` format, never reused, never deleted | Critical |
| FR-0S96-051 | The `GLOSSARY.md` file shall define all business and technical terms, loaded first in every agent context | High |
| FR-0S96-052 | Existing `prd/specs/` folders shall remain as read-only historical artifacts — not migrated or modified | High |

### Command Naming Convention

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-0S96-053 | The system shall use `/m:command` naming (plugin namespace with colon separator) for all v3 commands, as required by the Claude Code plugin system | Critical |
| FR-0S96-054 | Command names are derived from the markdown filename by the plugin system; the `commands` field in `plugin.json` uses string paths (not objects with name/description/path) | Critical |

---

## 5. Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-0S96-001 | Each agent in the /m:run pipeline shall receive only the spec artifacts relevant to its UC — not the entire feature or project spec | Stay within 150-200 instruction ceiling per agent context |
| NFR-0S96-002 | Plan and Build subsystems shall have fully independent skill sets with no shared skills directory; if both need similar knowledge, each gets its own copy | Zero cross-subsystem coupling; refactor for overlap only after v3 is complete |
| NFR-0S96-003 | All Mermaid diagrams generated by /m:spec shall use double-quoted node labels for any label containing special characters | 100% render success rate |
| NFR-0S96-004 | The plugin shall maintain zero runtime dependencies — all commands and skills are pure Markdown with YAML frontmatter | No external tooling required |
| NFR-0S96-005 | All documents generated by v3 commands shall follow the existing formatting rules: text checkboxes only, no emojis, Mermaid-only diagrams, markdown tables for structured data | Consistent with project conventions |

---

## 6. Technical Considerations

### Integration Points

| System | Integration |
|--------|-------------|
| Claude Code plugin system | Plugin manifest (`plugin.json`) must reference new directory structure; command and skill discovery depends on manifest paths |
| Git | Per-UC worktree isolation in /m:run; version tracking for UC files via frontmatter `version:` field |
| BDD test runners | Gherkin tags (`@FEAT-NNN`, `@UC-NNN`) must be compatible with pytest, cucumber, godog tag filtering |
| Existing v2 specs | prd/specs/ remains untouched; no migration needed |

### Database Changes

No database changes — Molcajete is a pure Markdown plugin system with zero runtime dependencies. All state is in files.

### Performance Requirements

| Metric | Target | Rationale |
|--------|--------|-----------|
| Agent context size per UC | < 150 instructions | Research shows LLMs follow 150-200 instructions with consistent adherence before degradation |
| Feature lookup time | One file read (FEATURES.md) | Agents should never need to scan directories to understand what exists |

### Security Considerations

- [ ] No credentials or secrets stored in spec documents
- [ ] Reverse-engineering commands must not expose sensitive values found in code (API keys, passwords) in generated spec documents

---

## 7. User Experience

### User Flows

**Flow 1: New project setup**

1. User runs `/m:setup`
2. System asks about the project (description, tech stack)
3. System generates PROJECT.md, TECH-STACK.md, ACTORS.md, GLOSSARY.md, FEATURES.md
4. User runs `/m:feature` with feature description
5. System runs creation interview, generates feature directory
6. User runs `/m:usecase FEAT-001 {description}` for each UC
7. User runs `/m:spec FEAT-001` to generate architecture
8. User runs `/m:stories UC-001` to generate Gherkin
9. User runs `/m:run UC-001` to implement

**Flow 2: Adopt spec system on existing codebase**

1. User runs `/m:setup` for foundational docs
2. User runs `/m:reverse-feature` for each existing capability
3. User runs `/m:schema` for database schema
4. User runs `/m:reverse-glossary` with seed terms
5. User reviews and edits generated specs
6. User continues forward with normal create/update commands

**Flow 3: Modify existing UC**

1. User runs `/m:update-usecase UC-001 {change description}`
2. System shows proposed changes, user confirms
3. UC version increments, status goes `dirty`
4. User runs `/m:run UC-001` to implement the change

### Error States

| Scenario | Handling |
|----------|----------|
| `/m:feature` run without `/m:setup` first | Error: "Run /m:setup first — PROJECT.md and TECH-STACK.md are required" |
| `/m:usecase` with invalid FEAT-NNN | Error: "Feature {FEAT-NNN} not found in FEATURES.md" |
| `/m:run` on a UC with empty fields | Error: "UC-NNN is missing required fields: {list}. Complete the UC spec before running." |
| `/m:spec` on a feature with no UCs | Warning: "No use cases found — generating architecture scaffold only" |
| Verifier finds gaps | Report gaps to user with specific references to UC fields, FRs, or architecture elements that aren't covered |

---

## 8. Scope Definition

### In Scope

- [ ] Plugin restructure into plan/build subsystems (no shared directory)
- [ ] Command deprecation (11 commands to deprecated/)
- [ ] Skill deprecation (10 language/stack skills to deprecated/)
- [ ] Commands use `/m:command` naming (plugin namespace with colon separator)
- [ ] All 11 Plan commands: /m:setup, /m:feature, /m:usecase, /m:spec, /m:schema, /m:stories, /m:update-feature, /m:update-usecase, /m:reverse-feature, /m:reverse-usecase, /m:reverse-glossary
- [ ] All 4 Build commands: /m:run (with 4-agent pipeline), /m:dev, /m:test, /m:debug
- [ ] 4 kept commands repositioned: /m:commit, /m:review, /m:doc, /m:research
- [ ] New prd/ directory structure with GLOSSARY.md, FEATURES.md, PROJECT.md, TECH-STACK.md, ACTORS.md, features/
- [ ] New Plan skills: feature-authoring, usecase-authoring, architecture, gherkin, reverse-engineering
- [ ] New Build skills: planner, tester, developer, verifier
- [ ] Skills not belonging to plan or build remain at plugin root (`molcajete/skills/`)
- [ ] EARS syntax for all requirements
- [ ] Fit Criteria on every requirement
- [ ] Explicit side effects and non-side-effects on every UC
- [ ] C4 L1/L2 diagrams, ER with invariants, event topology tables in architecture.md
- [ ] Feature lifecycle state machine (backlog -> scoped -> specified -> building -> live -> dirty -> deprecated)
- [ ] Creation interview pattern for /m:feature and /m:usecase

### Out of Scope

- Migration of existing v2 specs (prd/specs/) to v3 format — they remain as historical artifacts
- Automated FEATURES.md sync on partial command failures (noted as knowledge gap)
- Gherkin re-generation validation when UC version changes (noted as knowledge gap)
- CI/CD hooks for Feature Inventory maintenance
- Multi-feature dependency specs
- FEAT-NNN collision handling for parallel branch development
- Evaluation and deprecation of remaining workflow/utility skills — deferred to post-v3 completion

### MVP Boundaries

| Feature | MVP | Future |
|---------|-----|--------|
| Plan commands | All 11 commands functional | Automated validation of spec completeness |
| Build pipeline | 4-agent pipeline for single UC and full feature | Parallel UC execution, auto-retry on Verifier failure |
| Reverse-engineering | All 3 reverse commands functional | Incremental reverse-engineering (update specs from code changes) |
| Feature Inventory | Manual maintenance via commands | Automated consistency checks, CI integration |
| Schema generation | Single-run extraction from code | Incremental schema updates, migration generation |

---

## 9. Dependencies

### Technical Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| Claude Code plugin system | Current | Command and skill registration, YAML frontmatter parsing |
| Mermaid | Latest supported by Claude Code | C4, ER, state, flowchart, sequence diagrams in architecture.md |
| Git worktrees | Git 2.x | Per-UC isolation during /m:run pipeline |

### Feature Dependencies

| Depends On | Relationship |
|------------|--------------|
| Existing BDD scenario generator (UC-0KTg) | /m:stories is an enhanced replacement; existing Gherkin skill knowledge is reused |
| Existing dispatch pipeline (UC-0Rz0) | /m:run is an enhanced replacement; worktree isolation pattern is reused |

### Blocked By

- None — can proceed independently. Existing v2 commands continue working during implementation.

---

## 10. Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Scope size causes implementation to stall | High | Medium | Vertical slicing by UC; each command is independently implementable and testable |
| FEATURES.md index drifts from actual feature state | Medium | High | Commands that create/update features always update FEATURES.md atomically; Verifier checks consistency |
| EARS syntax learning curve for users | Low | Medium | /m:feature creation interview handles the conversion — user writes freeform, system outputs EARS |
| Ephemeral plans may lose valuable architectural decisions | Medium | Low | Architecture decisions belong in architecture.md ADR section, not in the plan; plans are for implementation sequence only |
| Four-agent pipeline increases /m:run latency | Medium | Medium | Each agent receives only UC-scoped context (instruction ceiling compliance); parallelism not in MVP but planned |
| Deprecating 11 commands breaks existing workflows | High | Low | Deprecated commands are preserved in deprecated/ folder; users can reference them; kept commands (commit, review, doc, research) cover daily utilities |

---

## 11. Open Questions

| # | Question | Status | Answer |
|---|----------|--------|--------|
| 1 | Should /m:dev, /m:test, /m:debug be rewritten for v3 or kept as-is with minor path updates? | Open | |
| 2 | Where should kept commands (commit, review, doc, research) live — in plan/, build/, or a top-level commands/? | Open | |
| 3 | Should the Verifier agent attempt auto-fixes for minor gaps, or always report back to user? | Resolved | Always report back — per proposal Part 7 |
| 4 | How should FEAT-NNN IDs handle parallel creation on different branches? | Open | Noted as knowledge gap in proposal |
| 5 | Should /m:setup detect existing v2 documents (mission.md, tech-stack.md) and offer to migrate them? | Open | |
| 6 | What happens to prd/roadmap.md and prd/changelog.md in the v3 structure? | Open | |
