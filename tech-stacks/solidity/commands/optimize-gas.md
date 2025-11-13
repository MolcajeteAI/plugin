---
description: Analyze and optimize gas usage in smart contracts
---

# Optimize Gas Usage

Analyze gas usage and apply optimization techniques to reduce costs.

Use the Task tool to launch the **gas-optimizer** agent with the following instructions:

1. Generate baseline gas report:
   - Run gas report for current state
   - Save baseline metrics
2. Analyze code for optimization opportunities using gas-optimization skill:
   - Storage variable packing
   - Cached storage reads
   - Efficient data types (uint256 vs smaller types)
   - Loop optimizations
   - Unnecessary zero initializations
   - Short-circuit evaluation order
   - Function visibility optimization
   - Immutable/constant usage
3. Prioritize optimizations by impact:
   - Calculate potential savings for each optimization
   - Focus on high-frequency functions
   - Consider deployment vs runtime costs
4. Apply optimizations:
   - Make code changes following best practices
   - Preserve functionality and readability
   - Maintain security standards
5. Verify improvements:
   - Run tests to ensure correctness
   - Generate new gas report
   - Compare with baseline
   - Calculate savings percentage
6. Generate optimization report:
   - List all optimizations applied
   - Show before/after gas costs
   - Total gas savings
   - Estimated cost savings at current gas prices

Reference the gas-optimization, framework-detection, and code-quality skills.
