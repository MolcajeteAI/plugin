# MDG Feature Template

Use this template for `.feature.md` files (Markdown-Gherkin format). Select this format when the project uses MDG. Never mix formats.

````markdown
# Feature: {Feature Name}

{1-2 sentence description of the feature}

**Tags:** `@{domain}` `@uc-{UC-ID}` `@{priority-tag}`

## Background

- **Given** {shared precondition}

## Scenario: {Scenario Name}

**Tags:** `@task-{ID}` `@{scenario-tag}`

- **Given** {declarative system state}
- **When** {user action}
- **Then** {exact assertion}

## Scenario Outline: {Parameterized Scenario Name}

**Tags:** `@task-{ID}` `@{scenario-tag}`

- **Given** {state with `<param>`}
- **When** {action with `<param>`}
- **Then** {assertion with `<expected>`}

### Examples

| param   | expected |
|---------|----------|
| value1  | result1  |
| value2  | result2  |
````
