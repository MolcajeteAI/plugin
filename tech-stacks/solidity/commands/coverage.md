---
description: Generate test coverage report and analyze results
---

# Generate Coverage Report

Generate test coverage report and analyze results.

Use the Task tool to launch the **tester** agent with the following instructions:

1. Detect project framework using framework-detection skill
2. Generate coverage:
   - Foundry: `forge coverage`
   - Hardhat: `npx hardhat coverage`
3. Parse coverage results:
   - Line coverage
   - Branch coverage
   - Function coverage
4. Identify uncovered code sections
5. Report coverage summary with percentage by contract
6. Suggest tests for uncovered critical paths
7. Check if coverage meets goal (>95% line, >90% branch)

Reference the framework-detection and testing-patterns skills.
