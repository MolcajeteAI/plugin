# Task Tagging

Tag formats and UC-to-file mapping rules for BDD traceability.

## Tag Formats

| Tag | Regex | Placement | Example |
|-----|-------|-----------|---------|
| UC tag | `@uc-UC-[A-Za-z0-9]{4}-\d{3}` | Feature line | `@uc-UC-0KTg-001` |
| Task tag | `@task-UC-[A-Za-z0-9]{4}-\d{3}--\d+\.\d+` | Scenario line | `@task-UC-0KTg-001--1.1` |

## Tag Placement Order

**Feature line:** `@{domain} @uc-{UC-ID} @{priority-tag}`

**Scenario line:** `@task-{ID} @{scenario-tag}`

The UC tag always follows the domain tag. The task tag always comes first on scenario lines.

## UC-to-File Mapping

One `.feature` file per UC. The file name is derived from the UC title in kebab-case:

| UC Title | File Name |
|----------|-----------|
| User Registration | `user-registration.feature` |
| Password Reset Flow | `password-reset-flow.feature` |
| Invoice Generation | `invoice-generation.feature` |

The `@uc-{UC-ID}` tag on the Feature line is the canonical link between the feature file and the UC in `requirements.md`.

## Dedup Extensions

Both dedup checks happen during the **placement plan phase** (Step 3-cat), not during generation.

### UC Coverage Dedup

1. Read `bdd/features/INDEX.md`.
2. Search for any feature entry containing `@uc-{UC-ID}`.
3. If found, the UC is already covered -- mark as SKIP in the placement plan.

### Task Tag Dedup

1. Search existing `.feature` files in the target domain folder for `@task-{ID}`.
2. If found, the task is already covered -- do not generate duplicate scenarios for that task.
