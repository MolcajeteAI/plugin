---
description: Generate coverage report
model: haiku
---

# Generate Coverage Report

Run tests and generate code coverage report.

Execute the following command:

```bash
npm run test:coverage
```

This runs:
```bash
vitest run --coverage
```

**Coverage Output:**
- Text summary in terminal
- HTML report in `coverage/` directory
- JSON report for CI integration

**Coverage Thresholds (minimum 80%):**
- Lines: 80%
- Functions: 80%
- Branches: 80%
- Statements: 80%

**View HTML Report:**
```bash
open coverage/index.html
```

**Quality Requirements:**
- All coverage thresholds must be met
- No uncovered critical paths

Reference the **coverage-standards** skill.
