---
description: Create or compare gas usage snapshots
---

# Create Gas Snapshot

Create or compare gas usage snapshots.

Use the Task tool to launch the **gas-optimizer** agent with the following instructions:

1. Check if previous snapshot exists
2. Create new gas snapshot:
   - Foundry: `forge snapshot`
   - Saves to `.gas-snapshot` file
3. If previous snapshot exists:
   - Compare with previous: `forge snapshot --diff`
   - Report gas changes (increases/decreases) by function
   - Flag any significant regressions (>5% increase)
4. Report snapshot summary:
   - Total functions tested
   - Gas changes if comparing
   - Regressions detected
   - Improvements detected

Reference the framework-detection and gas-optimization skills.
