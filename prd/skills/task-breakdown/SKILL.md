---
name: task-breakdown
description: Methodology for breaking specifications into actionable tasks organized by features. Use when creating task lists or orchestrating implementation.
---

# Task Breakdown Skill

## When to Use

- Breaking specs into implementation tasks
- Organizing work by features
- Planning sequential or parallel execution
- Estimating implementation effort

## Feature Organization Methodology

### Principle
**UPMOST IMPORTANCE:** The best path is the shortest to get working software that can be tested end-to-end.

Each feature delivers a complete user-facing capability that works across all application layers. Tasks are organized sequentially within each feature to achieve working, testable software as quickly as possible.

### Feature Organization

**Feature Structure:**
```
## 1. [ ] Users should be able to signup

- 1.1 [ ] Create user migrations
- 1.2 [ ] Add /signup end-point
- 1.3 [ ] Build user signup form
- 1.4 [ ] Add user signup form validations
- 1.5 [ ] Send signup confirmation email
- 1.6 [ ] Add /signup/confirmation/:confirmation_id end-point
  - 1.6.1 [ ] Verify valid token
  - 1.6.2 [ ] Throw error with expired tokens
  - 1.6.3 [ ] Activate user account
- 1.7 [ ] Build user email confirmation page

## 2. [ ] Users should be able to login

- 2.1 [ ] Add /signin end-point
- 2.2 [ ] Build user sign-in form
- 2.3 [ ] Add user sign-in validations
- 2.4 [ ] Display "Lost password?" link after failed attempt
```

### Feature Boundaries

**Good feature:** "Users should be able to signup"
- Complete end-to-end functionality
- Works across all layers (database, backend, frontend)
- Can be tested and demonstrated
- Delivers immediate user value

**Bad feature:** "All database migrations"
- Horizontal layer, not vertical feature
- Cannot be tested end-to-end
- Doesn't deliver user value by itself

### Task Types Within Features

As you break down each feature, you'll typically encounter these types of tasks in logical sequence:

- **Data layer:** Migrations, schema design, indexes
- **Backend:** API endpoints, business logic, validation, error handling
- **Frontend:** UI components, forms, user flows, state management
- **Integration:** Email sending, external APIs, webhooks
- **Testing:** Unit tests, integration tests, E2E tests

The key is to organize these in the shortest path to working software, not in separate sections.

## Estimation Guidelines

**Complexity Levels:**
- **Simple (1 point):** Straightforward, well-understood, minimal dependencies
- **Medium (3 points):** Moderate complexity, some unknowns, few dependencies
- **Complex (5 points):** High complexity, many unknowns, multiple dependencies
- **Very Complex (8 points):** Requires research, high risk, many dependencies

**Red Flags:**
- Tasks larger than 8 points (break down further)
- Vague task descriptions
- Hidden dependencies

## Dependency Analysis

1. **Identify Dependencies:**
   - What must be done before this task?
   - What blocks this task?
   - What does this task enable?

2. **Critical Path:**
   - Longest chain of dependent tasks
   - High-risk items should be tackled early

3. **Parallel Opportunities:**
   - Tasks with no dependencies can run in parallel
   - Different specialties can work simultaneously within a feature

## Orchestration Strategies

### Sequential Execution
- One feature at a time, in priority order
- Complete all tasks for feature 1, then move to feature 2
- Each feature delivers working, testable software before moving to the next
- Best for: Learning codebases, tight coordination needed, high-risk features

### Parallel Execution
- Multiple features simultaneously
- Multiple subagents working on independent features
- Best for: Large specs with independent features, experienced teams, well-defined boundaries
- Requires careful dependency management

## Formatting Standards

**CRITICAL: Follow template formatting exactly:**

- Use text checkboxes: `[ ]` for incomplete, `[x]` for complete
- **NEVER use emojis** for checkboxes or task status
- **ALL tasks MUST have task IDs** in the format: 1.1, 1.2, 2.1, 2.2, etc.
- **ALL subtasks MUST have nested IDs** like: 1.3.1, 1.3.2, 1.3.3
- Follow the exact structure and styling from tasks-template.md
- Maintain consistent indentation (2 spaces for nested items)
- Feature headers use: `## N. [ ] Feature description`
- Tasks use: `- N.M [ ] Task description`
- Subtasks use: `  - N.M.K [ ] Subtask description`

## Templates

See templates/ directory for:
- tasks-template.md
