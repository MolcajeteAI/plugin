---
description: Execute test suite with framework-appropriate testing language
---

# Run Tests

Execute test suite with framework-appropriate testing language.

Use the Task tool to launch the **tester** agent with the following instructions:

1. Detect project framework using framework-detection skill
2. Run tests:
   - Foundry: `forge test` (Solidity tests)
   - Hardhat: `npx hardhat test` (TypeScript tests)
3. Show test results with pass/fail counts
4. Display any failing test details with traces
5. Report test execution time
6. Suggest running with increased verbosity if tests fail

Reference the framework-detection and testing-patterns skills.
