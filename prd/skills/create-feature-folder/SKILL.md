---
name: create-feature-folder
description: Helper for creating timestamped feature directories. Use when creating new feature specs.
---

# Create Feature Folder Skill

## When to Use

- Creating new feature directories in .molcajete/prd/specs/
- Need timestamped folder names (YYYY-MM-DD-feature-name format)

## Usage

The timestamp logic is inlined directly in commands for portability:

```bash
FEATURE_DIR=$(python3 -c "from datetime import datetime; from pathlib import Path; import sys; name = sys.argv[1]; timestamp = datetime.now().strftime('%Y-%m-%d'); dir_name = f'{timestamp}-{name}'; Path(f'.molcajete/prd/specs/{dir_name}').mkdir(parents=True, exist_ok=True); print(dir_name)" "<feature-name>")
```

**Output:** Returns the timestamped directory name (e.g., `2025-11-12-feature-name`)

**How it works:**
1. Gets current date in YYYY-MM-DD format
2. Creates directory name: `{timestamp}-{feature-name}`
3. Creates directory at: `.molcajete/prd/specs/{timestamp}-{feature-name}/`
4. Returns just the directory name for use in subsequent commands

## Example

```bash
# Create folder for "user-authentication" feature
FEATURE_DIR=$(python3 -c "from datetime import datetime; from pathlib import Path; import sys; name = sys.argv[1]; timestamp = datetime.now().strftime('%Y-%m-%d'); dir_name = f'{timestamp}-{name}'; Path(f'.molcajete/prd/specs/{dir_name}').mkdir(parents=True, exist_ok=True); print(dir_name)" "user-authentication")
# Creates: .molcajete/prd/specs/2025-11-12-user-authentication/
# Returns: 2025-11-12-user-authentication

# Use in subsequent commands
echo "Feature directory: ${FEATURE_DIR}"
# Output: Feature directory: 2025-11-12-user-authentication
```

