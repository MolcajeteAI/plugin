---
description: Debug failed transaction or test with trace analysis
---

# Debug Transaction or Test

Debug failed transaction or test with trace analysis.

Use the Task tool to launch the **debugger** agent with the following instructions:

1. Ask user what to debug:
   - Failing test name
   - Transaction hash (for on-chain transactions)
2. Detect framework and run debugging:
   - Foundry test: `forge test --match-test [name] -vvvv`
   - Foundry transaction: `cast run [hash] --trace`
   - Foundry interactive: `forge test --debug [name]`
   - Hardhat: Run test with console.log output
3. Analyze traces to identify:
   - Revert location
   - Parameter values at revert
   - State changes before revert
   - Call stack at failure
4. Form hypothesis about cause
5. Report findings with:
   - Exact failure location (file:line)
   - Reason for failure
   - Values that caused failure
   - Suggested fix

Reference the framework-detection skill.
