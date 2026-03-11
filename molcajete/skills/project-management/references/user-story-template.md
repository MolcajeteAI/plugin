# User Story Template

Template for user stories with acceptance criteria linked to BDD scenarios.

## Story Format

```markdown
| ID | As a | I want | So that | Priority |
|----|------|--------|---------|----------|
| US-{tag}-NNN | {user type} | {desired action or capability} | {business value or outcome} | {Critical / High / Medium / Low} |
```

## Acceptance Criteria Format

Each user story has acceptance criteria written as testable conditions. When BDD scenarios exist, criteria link to specific scenario tags.

```markdown
#### US-{tag}-NNN: {story title}

- [ ] {Testable condition 1} `@task-UC-{tag}-NNN--N.M`
- [ ] {Testable condition 2} `@task-UC-{tag}-NNN--N.M`
- [ ] {Testable condition 3}
```

The `@task-{ID}` reference links the criterion to a BDD scenario that validates it. Not all criteria need a BDD link — some are verified through unit tests or manual review.

## Well-Formed Story Examples

### Good: Specific, testable, valuable

| ID | As a | I want | So that | Priority |
|----|------|--------|---------|----------|
| US-0Fy0-001 | patient | to enter my general information in a form | my medical profile is created for provider access | Critical |

#### US-0Fy0-001: Patient generals form

- [ ] Form displays fields for name, date of birth, gender, and contact info `@task-UC-0Fy0-001--1.1`
- [ ] Form validates required fields before submission `@task-UC-0Fy0-001--1.2`
- [ ] Successful submission creates a patient record via GraphQL mutation `@task-UC-0Fy0-001--1.3`
- [ ] Error states display user-friendly messages in Spanish

### Good: Clear boundaries

| ID | As a | I want | So that | Priority |
|----|------|--------|---------|----------|
| US-0Fy0-002 | doctor | to view a patient's general information | I can review their profile before a consultation | High |

### Bad: Too vague

| ID | As a | I want | So that | Priority |
|----|------|--------|---------|----------|
| US-0Fy0-003 | user | the system to work well | things are good | Medium |

Problems: "user" is not a specific role, "work well" is not testable, "things are good" is not a business outcome.

### Bad: Implementation-focused (not user-focused)

| ID | As a | I want | So that | Priority |
|----|------|--------|---------|----------|
| US-0Fy0-004 | developer | a GraphQL mutation for patient generals | the API layer is complete | High |

Problems: User stories describe user value, not implementation tasks. This belongs in `tasks.md`, not as a user story.

## Linking Stories to BDD

When `/m:stories` generates scenarios from a spec folder, it reads user stories and their acceptance criteria. Each acceptance criterion becomes one or more Gherkin scenarios with `@task-{ID}` tags.

The traceability chain:

```
US-{tag}-NNN (user story)
  -> Acceptance criterion
    -> @task-UC-{tag}-NNN--N.M (BDD scenario tag)
      -> Scenario in bdd/features/{domain}/{feature}.feature
```

This allows running BDD scoped to a single story's acceptance criteria:
- behave: `behave --tags=@task-UC-0Fy0-001--1.1`
- godog: `godog --tags=@task-UC-0Fy0-001--1.1`
- cucumber-js: `npx cucumber-js --tags @task-UC-0Fy0-001--1.1`
