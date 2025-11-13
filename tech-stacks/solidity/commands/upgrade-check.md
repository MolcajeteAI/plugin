---
description: Validate upgrade safety and storage layout compatibility
---

# Check Upgrade Safety

Validate that a contract upgrade is safe and maintains storage layout compatibility.

Use the Task tool to launch the **upgrader** agent with the following instructions:

1. Verify upgradeable contract setup:
   - Detect proxy pattern (UUPS, Transparent, Beacon)
   - Identify current implementation
   - Locate new implementation contract
2. Ask user for:
   - Current implementation contract name/path
   - New implementation contract name/path
   - Proxy address (optional, for on-chain validation)
3. Perform storage layout analysis:
   - Foundry: Use `forge inspect` to compare storage layouts
   - Hardhat: Use OpenZeppelin Upgrades plugin validation
   - Check for storage slot conflicts
   - Verify no storage variables removed or reordered
   - Check for type changes in existing variables
4. Validate upgrade safety rules:
   - No removed storage variables
   - No reordered storage variables
   - No type changes in existing variables
   - New variables only added at the end
   - Constructor not used (initializer pattern required)
   - No selfdestruct or delegatecall issues
   - Initialize functions properly protected
5. Check for common upgrade pitfalls:
   - Function selector collisions
   - Missing reinitializer version bumps
   - Uninitialized implementation contracts
   - Missing gap variables
6. Generate safety report:
   - Storage layout comparison (before/after)
   - List of all checks performed
   - Any violations or warnings found
   - Recommendation (SAFE / UNSAFE / WARNINGS)
   - Specific issues that need fixing
7. If unsafe, provide remediation steps

Reference the upgrade-safety, proxy-patterns, and framework-detection skills.
