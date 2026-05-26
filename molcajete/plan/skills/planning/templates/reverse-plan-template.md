<!--
Reverse / coverage-recovery plan.md template — companion to plan.json,
produced by /m:reverse-plan.

This file is a human-readable WYSIWYG preview of the coverage-recovery
work the build loop will execute. It is regenerated from plan.json +
coverage scan results on every plan write; never hand-edit. Authoring
rules live in `molcajete/plan/skills/planning/SKILL.md` →
"Companion plan.md (reverse / coverage-recovery)".

Do NOT include execution state fields: status, summary, errors,
estimated_context, depends_on.
-->

# {plan.title} — Coverage Recovery

## Context

Coverage-recovery plan for {N} module(s). The Implementer + Validator loop
in `/m:build` will add tests for the behaviors listed below until each
file reaches the project coverage threshold from
`.molcajete/settings.json` `testing.threshold`.

## Modules

<!--
One subsection per in-scope module. Omit modules already at or above
threshold. For each module include current coverage and threshold, then
the per-file gaps the planner identified.
-->

### {module-name}

- **Current coverage:** {pct}%
- **Threshold:** {threshold}%
- **Files needing coverage:**
  - `{file-relative-path}` — {pct}% — {short note on the gap}
  - `{file-relative-path}` — {pct}% — {short note on the gap}

## Tasks

<!-- One section per top-level task in plan.tasks. Order matches JSON order. -->

### T-NNN — Cover {file-relative-path}

- **File under test:** `{file-relative-path}`
- **Current coverage:** {pct}%

**Uncovered behaviors / branches**

<!--
The gap clusters as the planner identified them. These are the behaviors
the Implementer will write tests for. The Implementer chooses actual
test placement and assertion shape; the planner does not enumerate
test file paths or assertions.
-->

- {behavior or branch description, with line range when known}
- {behavior or branch description}

**Files to modify**

- `{file-relative-path}` — production file under test

**Verification**

- Coverage gate: this file reaches `.molcajete/settings.json`
  `testing.threshold` AND total project coverage stays at or above the
  threshold. Confirmed by the Validator subagent during `/m:build`.
