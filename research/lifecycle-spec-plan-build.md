# Plugin Lifecycle: spec → plan → build

Status: design decision captured from discussion (2026-06-16). Scope: plugin only. CLI parity deferred.

## Decision

Re-introduce `/m:plan` as a mandatory step between spec and build. Add `/m:fix` and `/m:change` for the two distinct "modify what exists" paths. Add `/m:cover` for extracting specs from existing code. Every path funnels through `/m:plan`; plan is the gate before code or tests are written. `/m:plan` runs in a mode that adapts to what produced the pending entries (default: green-field; `mode:cover` when the entries came from `/m:cover`).

```
/m:spec | /m:fix | /m:change  →  /m:plan              →  /m:build
/m:cover                      →  /m:plan (mode:cover)  →  /m:build
```

No shortcuts. No skipping plan, ever.

## Why

- Spec and build alone leave no review checkpoint between *what* and *how*. Coupling spec → build means architecture decisions hide inside build and cannot be inspected or revised before code lands.
- Spec describes behavior. Plan decides architecture, decomposition, and sequencing. Different artifacts, different lifecycles, kept separate.
- `/m:fix` and `/m:change` give bug-vs-evolution paths their own intent without becoming aliases of `/m:spec`. The distinction is real:
  - **fix:** spec is right, code is wrong (or spec was silent on the case)
  - **change:** spec was right at the time, we now want different behavior
- Plan is the equivalent of Claude's plan mode for the project: produce, review, accept, then execute.

## Commands

### `/m:spec <description>`

Free-form. Creates or amends a feature and/or use case from natural language. Description may reference an existing FEAT-XXXX or UC-XXX.

- **Input:** prose
- **Output:** spec files (REQUIREMENTS.md, USE-CASES.md, ARCHITECTURE.md, UC spec files `UC-XXXX-{slug}.md`); appends a `pending` entry to each touched UC's `CHANGELOG.md`; sets UC status to `pending` (new) or `dirty` (previously implemented).
- Does **not** produce slices, plan, or code.

### `/m:fix <FEAT-XXXX | UC-XXX> [more IDs ...] <description>`

"The use case is supposed to do X, but it does Y."

- First argument(s) **must** reference one or more feature or use case IDs.
- May update specs only when the specced behavior was wrong or missing.
- May add a new use case or slice to cover behavior that was never specced.
- Appends a `pending` entry to each touched UC's `CHANGELOG.md` even when no spec changes were needed (so `/m:plan` still runs and produces a one-task plan: regression test + code fix).
- Sets UC status to `dirty` if previously implemented.
- Does **not** write code. Hands off to `/m:plan`.

### `/m:change <FEAT-XXXX | UC-XXX> [more IDs ...] <description>`

"We want this use case to behave differently."

- First argument(s) **must** reference one or more feature or use case IDs.
- Always updates specs first.
- May introduce new use cases or slices.
- Appends a `pending` entry to each touched UC's `CHANGELOG.md`; sets UC status to `dirty` if previously implemented.
- Does **not** write code. Hands off to `/m:plan`.

### `/m:cover <path-or-glob>`

Reverse path: code exists, specs don't. Replaces the old `/m:reverse-spec`. **Spec phase only** — does not produce a plan.

- Reads the referenced source.
- Writes specs (REQUIREMENTS.md, UC spec files `UC-XXXX-{slug}.md`).
- Sets each new UC's status to `pending`.
- Appends a `pending` entry to each new UC's `CHANGELOG.md` (command: `cover`, reason: brief note on what was extracted).
- Does **not** write slices, plan, or tests. Hands off to `/m:plan`.

### `/m:plan <FEAT-XXXX | UC-XXX> [more IDs ...]`

The architect. Reads referenced specs and produces an executable plan.

- Reads `pending` entries from each referenced UC's `CHANGELOG.md` to understand what changed and why.
- Inspects the log entries' originating command(s) to pick a **mode**:
  - **default (green-field)** — when entries came from `/m:spec`, `/m:fix`, or `/m:change`. Designs architecture (ports, adapters, domain surface, cross-cutting work) and frames tasks as "implement X."
  - **`mode:cover`** — when entries came from `/m:cover`. Skips architecture design (the code already exists). Frames tasks as "write integration test for behavior X" (and unit tests where required). Slices are derived from the existing code structure.
- Decomposes use cases into **slices** (vertical, shippable units), written as siblings of each UC file.
- Writes **Tasks** (1 task per slice) and **Sub-Tasks** into the plan folder.
- Stamps each consumed log entry with the plan-id and flips its status from `pending` to `dirty`.
- Records the mode in the plan itself so `/m:build` knows whether to write production code or tests only.
- Output is reviewable before any code or tests are written.

A single plan may span one use case, several use cases, or multiple features. Mixed-mode plans are not allowed — pending entries with different originating modes are split into separate plan folders. Plan ID is the timestamp. Every `/m:plan` invocation creates a **new** timestamped folder; existing plans are never amended.

```
.molcajete/plans/<YYYYMMDDTHHMMSS>-<descriptive-name>/
```

**`plan.md` shape.** A flat Markdown list, organized by FEAT then UC. One `T-NNN` per slice, with sub-tasks indented as `T-NNN.N`. Each task references the slice file it operates on. No tables, no frontmatter beyond what's needed for the mode marker.

```markdown
# Plan <descriptive-name>
mode: default | cover

## FEAT-0Fy0-name
### UC-0KTg-name
- [ ] T-001 — <slice-file-name>
  - [ ] T-001.1 — <sub-task>
  - [ ] T-001.2 — <sub-task>
- [ ] T-002 — <slice-file-name>

### UC-0L2x-name
- [ ] T-003 — <slice-file-name>
```

### `/m:build <plan-id> <task-or-subtask-ids ...>`

Executes the named plan, scoped to the provided identifiers.

- Accepts one task, many tasks, or sub-tasks (`T-NNN.N` form).
- Reads the plan's mode:
  - **default** — writes production code, integration tests (always), unit tests (when required).
  - **`mode:cover`** — writes integration tests (always) and unit tests (when required). **No production code.**
- Reads `TECH-STACK.md` to discover how to run tests and how to read coverage stats. If the host project doesn't expose coverage stats, build continues and estimates coverage best-effort against the 80% floor.
- On completion, flips each backing log entry from `dirty` to `implemented`. When every entry in a UC's `CHANGELOG.md` is `implemented`, the UC status becomes `implemented`.
- Marks tasks/sub-tasks complete as it goes.

## IDs

`FEAT-XXXX` and `UC-XXXX` placeholders in this document stand for **4-character base-62 timestamps** with a type prefix (e.g. `FEAT-0Fy0`, `UC-0KTg`). IDs are produced by the existing `id-generation` shared skill (`molcajete/shared/skills/id-generation/`); commands and the skill's `generate-id.js` are the only sanctioned source. Never compute base-62 inline.

## Slices

Concept: kept. Name: kept ("slice" is the industry term for *vertical, shippable, demoable unit*; replacing it loses meaning).

Files: **yes** — slices live inside the UC's support folder. They are produced by `/m:plan` (or `/m:cover` for existing code), not `/m:spec`. Spec stays prose-only at the use case level.

```
specs/
  features/
    {module}/
      FEAT-0Fy0-name/
        REQUIREMENTS.md
        USE-CASES.md
        ARCHITECTURE.md
        UC-0KTg-name.md              ← UC spec, has frontmatter status: pending | dirty | implemented
        UC-0KTg-name/                ← UC support folder
          CHANGELOG.md               ← context log + markers; NOT the status authority
          SLICE-001-{kebab-name}.md  ← has frontmatter status: pending | dirty | implemented
          SLICE-002-{kebab-name}.md  ← has frontmatter status: pending | dirty | implemented
.molcajete/
  plans/
    <YYYYMMDDTHHMMSS>-<descriptive-name>/
      plan.md
      ...
```

## Status tracking: first-class state on slices, UCs, and features

Status lives on each artifact's frontmatter `status:` field — **slices**, **UCs**, and **features** each carry one. This is the source of truth. The CHANGELOG.md is a context log + marker file ("what needs to change and why"); it is **not** the status authority.

```
specs/features/{module}/FEAT-XXXX-{slug}/
├── REQUIREMENTS.md          ← Feature status:  pending | dirty | implemented
├── UC-AAAA-{slug}.md        ← UC status:       pending | dirty | implemented
└── UC-AAAA-{slug}/
    ├── CHANGELOG.md         ← markers + log, NOT status
    └── SLICE-001-{name}.md  ← Slice status:    pending | dirty | implemented
```

**At-a-glance read.** Open any FEAT / UC / SLICE spec file — the frontmatter answers "is this implemented?" No need to walk the CHANGELOG. No need to read `.molcajete/slices/{id}.json`.

**Who writes what.**

- `/m:plan` writes Slice status (new slice → `pending`; superseded existing slice → `dirty`). It does **not** touch UC or Feature status.
- `/m:spec`, `/m:fix`, `/m:change`, `/m:cover` write UC status directly (`pending` on new UC; `dirty` when modifying a previously-`implemented` UC) and recompute Feature status by rolling up over child UCs.
- `/m:build` writes Slice status (`implemented` on success), recomputes UC status by rolling up over sibling slices, and recomputes Feature status by rolling up over child UCs.

**The roll-up rule** (applied at any parent level over immediate children):

- All children `implemented` → parent `implemented`.
- At least one child `dirty`, OR mixed `pending` + `implemented` → parent `dirty`.
- All children `pending`/`dirty` with no `implemented` → parent `pending`.

See `${CLAUDE_PLUGIN_ROOT}/shared/skills/status-rollup/SKILL.md` for the full semantics, per-level definitions, and direct-write override at the UC level.

### CHANGELOG.md (context log + markers, not status)

Plain Markdown with two top-level sections, `TODO:` and `DONE:`. New entries are prepended (newest at the top of their section). Spec-phase commands append a `pending` entry; `/m:plan` flips it to `dirty` with a plan-id stamp; `/m:build` flips it to `implemented` and moves it from TODO to DONE.

```markdown
TODO:
- <timestamp> [dirty]  command:change  plan:<plan-id>  — <reason>
- <timestamp> [pending] command:fix    plan:—          — <reason>

DONE:
- <timestamp> [implemented] command:spec   plan:<plan-id> — <reason>
```

Entry fields: timestamp, command (`spec`/`fix`/`change`/`cover`), status (`pending`/`dirty`/`implemented`), plan-id (or `—`), reason. Same three-state vocabulary as artifact status, but the changelog entry-status tracks individual change requests through the plan/build lifecycle — it does **not** authoritatively answer "is the UC implemented?". That answer lives on the UC frontmatter.

See `${CLAUDE_PLUGIN_ROOT}/shared/skills/uc-log/SKILL.md` for the changelog file mechanics.

The two "dirty" meanings are intentionally different: at the entry level it means "in flight" (planned, not built); at the artifact level it means "was complete, now has new unfinished work."

## Engineering Principles

A separate `principles` shared skill (`plugin/molcajete/shared/skills/principles/SKILL.md`) carries the engineering principles that bind every plan, line of code, and test: tests as the trust contract, integration-first (unit only when the algorithm IS the contract), hexagonal default, dependency injection, 80% coverage floor on touched files, universal software craft (small functions, clear boundaries, no god files, refactor to reuse), technology-agnostic.

**Three locations, one source of truth:**

- **Plugin skill** at `shared/skills/principles/SKILL.md` — the shipped defaults.
- **Host file** at `<host-project>/.claude/rules/principles.md` — written by `/m:setup` on first run (copy of the plugin skill's body), editable by the team. This is the operative version.
- **Host `CLAUDE.md` fenced block** between `<!-- molcajete:principles:start -->` / `<!-- molcajete:principles:end -->` markers — short summary + pointer, written by `/m:setup`, replaced idempotently on re-run.

`/m:plan` and `/m:build` always read the host file. If it is missing, they fall back to the plugin skill and emit a one-line warning telling the user to run `/m:setup`. The user can edit the host file to adapt principles to their context (e.g., "we always hit Stripe test mode and never mock the payments adapter") and Molcajete will respect the override.

`/m:setup` preserves the host file by default on re-run (asks via AskUserQuestion before overwriting). The `CLAUDE.md` fenced block, by contrast, is silently replaced on every `/m:setup` run so it always reflects current plugin defaults; content outside the markers is never touched.

### Update mode — propagating plugin upgrades

`/m:setup` on an existing project offers three paths: **Cancel**, **Regenerate all**, and **Update**. Update mode detects drift between the host state and the current plugin defaults, reports what's stale or missing, asks for confirmation, and patches only what the user approves. Foundation files with user content are never overwritten in update mode — only schema gaps are patched in place (e.g., missing `Running tests`/`Coverage` fields in `specs/TECH-STACK.md`) and plugin-owned artifacts are written or refreshed (principles file, `CLAUDE.md` block, `.molcajete/settings.json` keys).

Update mode is driven by the **Drift Catalog** in `plugin/molcajete/setup/skills/setup/SKILL.md`. Every plugin release that adds a new shared host artifact or extends an existing template adds a new entry; `/m:setup` walks the catalog at run time. The catalog is the single source of truth for what update mode can repair — no separate registry to keep in sync.

## Non-negotiables

- Plan is never skipped, ever. `/m:cover` is a spec-phase command and still hands off to `/m:plan`.
- `/m:fix` and `/m:change` always reference an existing spec ID as first arg(s).
- Production code is only written by `/m:build`. Spec-phase and plan-phase commands never touch source files.
- `/m:build` against a `mode:cover` plan writes tests only — never production code.
- Plans are single-mode. Mixed pending entries (some from green-field commands, some from `/m:cover`) split into separate plan folders.
- Slices belong to use cases, not to plans. The plan references slices; it does not own them.
- Integration tests target a **80% coverage floor**. The plan scopes tests to hit this floor. Coverage tooling and threshold enforcement (collector, reports, CI gates) are the **host project's responsibility**, not Molcajete's.
- The host project's `TECH-STACK.md` documents (1) how to run the tests and (2) how to read coverage stats. When the project doesn't provide a coverage collector, `/m:plan` and `/m:build` make a best-effort estimate to reach the floor.
- **Engineering principles are mandatory inputs to `/m:plan` and `/m:build`.** They read `.claude/rules/principles.md` first; the plugin skill is a fallback. The principles are technology-agnostic — they bind regardless of the host project's stack.
- **Status lives on artifact frontmatter, not on the changelog.** Slice, UC, and Feature each carry a `status:` field. The CHANGELOG.md is a context log + markers for what needs to change and why — it is not the state authority. Any reader (human or AI) answers "is this implemented?" by opening one spec file.
- **Spec traceability lives in comments, not in names.** Test names describe behavior in plain English (`it('rejects an empty email …')`); spec IDs (`UC-XXXX`, `SLICE-NNN`, `SC-XXXX`) appear as leading-line comments above the relevant file / group / test per Principle 1.2. The same pattern applies to production code per Principle 5.1: file-header `// FEAT-XXXX` / `// UC-XXXX` / `// SLICE-NNN`, and `// SC-XXXX, SC-YYYY:` above functions that satisfy specific scenarios. The slice's `covers:` array remains the canonical machine-readable mapping.

## Out of scope (deferred)

- CLI parity: the `molcajete` CLI's build phase will need to align with this lifecycle later; not addressed in this design.
- Slice file shape — already covered by the existing slice template.
