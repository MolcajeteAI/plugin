# Code Principles Plugin

Foundation plugin providing core software development principles, testing standards, and code quality guidelines.

## Overview

This plugin establishes fundamental software engineering principles and practices that apply across all projects and languages. It provides guidance on writing clean, maintainable, and high-quality code.

## Skills Provided

### 1. Software Principles

Core software engineering principles including DRY, SOLID, KISS, and YAGNI.

**Use when:** Designing features, refactoring code, reviewing code, making architectural decisions

**Includes:**
- [DRY](./skills/software-principles/principles/DRY.md) - Don't Repeat Yourself
- [SOLID](./skills/software-principles/principles/SOLID.md) - Object-oriented design principles
- [KISS](./skills/software-principles/principles/KISS.md) - Keep It Simple, Stupid
- [YAGNI](./skills/software-principles/principles/YAGNI.md) - You Aren't Gonna Need It

[📖 View Software Principles Skill](./skills/software-principles/SKILL.md)

### 2. Feature Slicing

Feature-first development approach that organizes code by features rather than technical layers.

**Use when:** Building new features, organizing codebases, enabling parallel development

**Includes:**
- [Feature Workflow](./skills/feature-slicing/guides/feature-workflow.md) - Step-by-step implementation guide
- [Anti-Patterns](./skills/feature-slicing/guides/anti-patterns.md) - Common mistakes to avoid

[📖 View Feature Slicing Skill](./skills/feature-slicing/SKILL.md)

### 3. Testing Standards

Standards and best practices for writing effective tests including the testing pyramid, test structure, and coverage guidelines.

**Use when:** Writing tests, reviewing tests, establishing testing practices

**Includes:**
- [Testing Pyramid](./skills/testing-standards/patterns/testing-pyramid.md) - Test distribution strategy
- [Test Structure](./skills/testing-standards/patterns/test-structure.md) - AAA and Given-When-Then patterns
- [Coverage Guidelines](./skills/testing-standards/patterns/coverage-guidelines.md) - Coverage targets by code type

[📖 View Testing Standards Skill](./skills/testing-standards/SKILL.md)

### 4. Code Quality

Standards for maintaining high code quality including comments, test coverage, and documentation.

**Use when:** Writing code, reviewing code, documenting systems

**Includes:**
- [Code Comments](./skills/code-quality/standards/code-comments.md) - When and how to comment
- [Test Coverage](./skills/code-quality/standards/test-coverage.md) - Coverage requirements
- [Documentation](./skills/code-quality/standards/documentation.md) - Documentation standards

[📖 View Code Quality Skill](./skills/code-quality/SKILL.md)

## Usage Examples

### Example 1: Implementing a New Feature

When building a new feature, apply these skills in sequence:

1. **Software Principles** - Design with SOLID, KISS, and YAGNI in mind
2. **Feature Slicing** - Organize code as a vertical feature slice
3. **Testing Standards** - Write tests following the testing pyramid
4. **Code Quality** - Add appropriate comments and documentation

```javascript
// features/user-authentication/
//   /api
//     authController.js    // SOLID: Single responsibility
//   /domain
//     authService.js       // DRY: Extracted business logic
//     user.js              // KISS: Simple, clear models
//   /data
//     userRepository.js    // Feature slice: All layers together
//   /tests
//     authService.test.js  // Testing pyramid: Unit tests
//     integration.test.js  // Testing pyramid: Integration tests
//   README.md              // Code quality: Feature documentation
```

### Example 2: Code Review Checklist

Use these skills during code review:

**Software Principles:**
- [ ] No code duplication (DRY)
- [ ] Single responsibility per class/function (SOLID-SRP)
- [ ] Simple, not over-engineered (KISS)
- [ ] No unnecessary features (YAGNI)

**Feature Slicing:**
- [ ] Related code is grouped together
- [ ] Feature is self-contained
- [ ] No direct dependencies on other features

**Testing Standards:**
- [ ] Tests follow AAA or Given-When-Then structure
- [ ] Coverage meets standards for code type
- [ ] Tests cover edge cases and errors

**Code Quality:**
- [ ] Comments explain "why", not "what"
- [ ] Public APIs are documented
- [ ] README updated if needed
- [ ] No commented-out code

### Example 3: Refactoring Guidance

When refactoring, apply principles systematically:

1. **Add Tests** (Testing Standards) - Ensure existing behavior is covered
2. **Identify Violations** (Software Principles) - Find DRY, SOLID, KISS, YAGNI issues
3. **Refactor Incrementally** - Fix one principle at a time
4. **Update Documentation** (Code Quality) - Keep docs in sync
5. **Reorganize if Needed** (Feature Slicing) - Group related code together

## Integration with Other Plugins

This plugin provides foundation skills that other plugins can reference:

### For Product Manager Plugin
- Use **feature-slicing** for organizing product features
- Use **software-principles** for technical decisions

### For Solidity Dev Plugin
- Use **software-principles** for smart contract design
- Use **testing-standards** for contract testing
- Use **code-quality** for documentation

### For Go Dev Plugin
- Use **software-principles** for Go code design
- Use **testing-standards** for Go testing patterns
- Use **feature-slicing** for service organization

## Quick Reference

### Software Principles

| Principle | Key Idea | When to Apply |
|-----------|----------|---------------|
| DRY | Don't repeat logic | When extracting common code |
| SOLID | OOP design principles | When designing classes/modules |
| KISS | Keep it simple | Always, especially first implementations |
| YAGNI | Build only what's needed | When tempted to add "nice to have" features |

### Testing Distribution

| Test Type | Percentage | Speed | Scope |
|-----------|-----------|-------|-------|
| Unit | 60-70% | Fast (ms) | Single function/class |
| Integration | 20-30% | Medium (100s ms) | Component interactions |
| E2E | 5-10% | Slow (seconds) | Complete workflows |

### Coverage Targets

| Code Type | Target | Priority |
|-----------|--------|----------|
| Business Logic | 80-100% | HIGH |
| Utilities | 90-100% | HIGH |
| Data Access | 70-90% | MEDIUM |
| API Controllers | 60-80% | MEDIUM |
| UI Components | 40-70% | MEDIUM |

## Best Practices

1. **Apply Principles Together** - They reinforce each other
2. **Start Simple** - KISS and YAGNI first, add complexity when needed
3. **Test Early** - Write tests with code, not after
4. **Document Decisions** - Explain why, not what
5. **Review Regularly** - Use skills as review checklist
6. **Adapt to Context** - Principles are guidelines, not laws

## File Structure

```
code-principles/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── skills/
│   ├── software-principles/
│   │   ├── SKILL.md
│   │   └── principles/
│   │       ├── DRY.md
│   │       ├── SOLID.md
│   │       ├── KISS.md
│   │       └── YAGNI.md
│   ├── feature-slicing/
│   │   ├── SKILL.md
│   │   └── guides/
│   │       ├── feature-workflow.md
│   │       └── anti-patterns.md
│   ├── testing-standards/
│   │   ├── SKILL.md
│   │   └── patterns/
│   │       ├── testing-pyramid.md
│   │       ├── test-structure.md
│   │       └── coverage-guidelines.md
│   └── code-quality/
│       ├── SKILL.md
│       └── standards/
│           ├── code-comments.md
│           ├── test-coverage.md
│           └── documentation.md
└── README.md                 # This file
```

## Contributing

When updating this plugin:

1. **Follow the principles** - Dog food your own recommendations
2. **Include examples** - Every guideline should have code examples
3. **Test readability** - Can a junior developer understand it?
4. **Update related docs** - Keep all documentation in sync
5. **Add to changelog** - Document what changed and why

## Version History

### 1.0.0 (Current)
- Initial release
- Software principles skill (DRY, SOLID, KISS, YAGNI)
- Feature slicing skill
- Testing standards skill
- Code quality skill

## License

MIT

## Acknowledgments

These principles and practices are derived from industry best practices, books like "Clean Code" by Robert C. Martin, and the collective wisdom of the software engineering community.
