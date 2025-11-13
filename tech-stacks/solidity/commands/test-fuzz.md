---
description: Run fuzz tests to discover edge cases and vulnerabilities
---

# Run Fuzz Tests

Execute fuzz testing to automatically discover edge cases and potential vulnerabilities.

Use the Task tool to launch the **tester** agent with the following instructions:

1. Detect project framework using framework-detection skill
2. Check for existing fuzz tests:
   - Foundry: Functions starting with `testFuzz_` in test files
   - Hardhat: Tests using property-based testing libraries
3. Run fuzz tests:
   - Foundry: `forge test --match-test testFuzz`
   - Configure number of runs if needed (default: 256)
4. Analyze fuzz test results:
   - Show discovered edge cases
   - Report any failures with input values that caused failure
   - Display coverage of input space
5. If failures found:
   - Show exact input values that caused failure
   - Provide trace of the failing execution
   - Suggest fixes based on failure pattern
6. Report summary:
   - Number of fuzz tests run
   - Total fuzzing runs executed
   - Edge cases discovered
   - Failures found

Reference the framework-detection and testing-patterns skills.
