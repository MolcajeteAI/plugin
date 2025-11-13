---
name: spec-writing
description: Standards and templates for writing detailed feature specifications. Use when transforming requirements into implementation-ready specs.
---

# Spec Writing Skill

## When to Use

- Writing formal feature specifications
- Refining rough requirements
- Defining acceptance criteria
- Documenting technical architecture for features

## Specification Structure

### Required Sections

1. **Overview**
   - High-level feature description
   - Strategic alignment (why this feature matters)
   - User value proposition

2. **Requirements**
   - Functional requirements (what it must do)
   - Non-functional requirements (performance, security, etc.)
   - Constraints and assumptions

3. **Data Models**
   - Database schema / smart contract storage
   - Entity relationships
   - Data validation rules

4. **API Contracts** (if applicable)
   - Endpoints and routes
   - Request/response formats
   - Error handling

5. **User Interface** (if applicable)
   - UI components and layout
   - User flows and interactions
   - Accessibility requirements

6. **Integration Points**
   - External services
   - Internal dependencies
   - Third-party APIs

7. **Acceptance Criteria**
   - Testable success criteria
   - Edge cases to handle
   - Performance targets

8. **Verification**
   - How to validate implementation
   - Test scenarios
   - Success metrics

## Best Practices

- Be specific and testable
- Include visual references when UI is involved
- Define clear boundaries and scope
- Reference product context for strategic alignment
- Apply software principles from code-principles plugin
- Think in vertical features (what's the MVP feature?)

## Formatting Standards

**CRITICAL: Follow template formatting exactly:**

- Use text checkboxes: `[ ]` for incomplete, `[x]` for complete
- **NEVER use emojis** for checkboxes or task status
- Follow the exact structure and styling from the templates
- Maintain consistent heading levels and list styles
- Use numbered lists where templates show numbers
- Preserve all formatting as shown in requirements-template.md and spec-template.md

## Templates

See templates/ directory for:
- requirements-template.md
- spec-template.md
