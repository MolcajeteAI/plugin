---
id: UC-NNN
name: {Verb-noun goal name}
feature: FEAT-NNN-slug
status: backlog
version: 1
actor: {Primary actor role}
tag: @UC-NNN
---

# UC-NNN: {Use Case Name}

> {One sentence: what the actor achieves by completing this use case.}

## Preconditions

- {Shared state that must exist before ANY scenario can start}
- {Actor state: authenticated, has permission, etc.}

## Trigger

{One sentence: what the actor does or what event occurs.}

## Gherkin Tags

`@FEAT-NNN @UC-NNN`

---

### S1: {Scenario Name}

**Given:**
- {State specific to THIS scenario, beyond UC-level Preconditions}

**Steps:**
1. {Actor} {action}
2. System {validates/processes/stores/returns} {what}

**Outcomes:**
- {Entity/state that now exists or has changed}

**Side Effects:**
- `{event.name}` event published with payload `{fields}`
- No {notification/email/webhook} sent

---

### S2: {Scenario Name}

**Given:**
- {Scenario-specific state}

**Steps:**
1. {Actor} {action}
2. System {response}

**Outcomes:**
- {What is true after this scenario}

**Side Effects:**
- {Side effects for this scenario}
- No {thing that does NOT happen}
