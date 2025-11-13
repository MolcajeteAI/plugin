---
description: Tidy dependencies
---

# Tidy Dependencies

Clean up go.mod and go.sum files.

Use the Task tool to launch the **developer** agent with instructions:

1. Run `go mod tidy`
2. Show which dependencies were added/removed
3. Verify go.mod and go.sum are updated
4. Check for any errors
5. Display summary of changes

**What go mod tidy does:**
- Adds missing module requirements
- Removes unused module requirements
- Updates go.sum
- Ensures consistency

Reference the project-structure skill.
