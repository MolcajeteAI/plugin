<!--
Greenfield plan.md template — companion to plan.json, produced by /m:plan.

This file is a human-readable WYSIWYG preview of what `molcajete build` will
produce. It is regenerated from plan.json + PRD context on every plan write;
never hand-edit. Authoring rules live in
`molcajete/plan/skills/planning/SKILL.md` → "Companion plan.md (greenfield)".

Do NOT include execution state fields: status, summary, errors,
estimated_context, depends_on.
-->

# {plan.title}

## Context

<!--
1–3 paragraphs on why this plan exists:
- what problem/need drove it (from scoped features' REQUIREMENTS.md "why")
- what the user asked for (the plan's scope)
- intended outcome after `molcajete build` finishes
-->

## Scope

- **Features:**
  - [FEAT-XXXX — name](../../../prd/modules/{module}/features/FEAT-XXXX-{slug}/README.md)
- **Use cases:**
  - [UC-XXXX — name](../../../prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}.md)
- **Base branch:** {plan.base_branch}

## Non-requirements (plan-level)

<!--
Bulleted list of things explicitly NOT changing at plan scope.
Source: REQUIREMENTS.md "out of scope" sections + planner inference.
-->

- {non-requirement}

## Tasks

<!-- One section per top-level task in plan.tasks. Order matches JSON order. -->

### T-NNN — {task.title}

**References**

- Feature: [FEAT-XXXX — name](../../../prd/modules/{module}/features/FEAT-XXXX-{slug}/README.md)
- Use case: [UC-XXXX — name](../../../prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}.md)
- Scenario: [SC-XXXX — name](../../../prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}.md#sc-xxxx)
- Architecture: [ARCHITECTURE.md]({task.architecture})

**What changes**

<!-- 1–2 paragraphs — narrative version of task.description. User-facing prose. -->

**Important snippets**

<!--
Small illustrative code fragments (≤ ~15 lines each) that clarify the
approach. Derive from ARCHITECTURE.md Code Map entries and the task's
files_to_modify. These are sketches, not final code.
-->

```
// illustrative shape
```

**Files to create/modify**

- `{path}` — {short note}

<!-- If task.sub_tasks is not null, list each here as a nested bullet: -->
<!-- - sub-task T-NNN-M: {sub_task.title} — {one-line note} -->

**Non-requirements (task-level)**

- {what this task is NOT doing, to prevent scope creep}

**Verification**

- BDD gate: scenario `@{task.scenario}` (executed by the project's verify hook)
- Manual smoke: {1–3 user-level steps derived from Gherkin Given/When/Then}
- File-level assertions: {expected files + key exports/functions}
