#!/usr/bin/env bash
# PostToolUse hook: Validate YAML frontmatter in edited .md files
FILE=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.file_path // .filePath // empty')
if [ -z "$FILE" ]; then exit 0; fi
if ! echo "$FILE" | grep -qE '\.md$'; then exit 0; fi
if ! head -1 "$FILE" 2>/dev/null | grep -q '^---'; then exit 0; fi

# Extract and validate frontmatter
FRONTMATTER=$(sed -n '2,/^---$/p' "$FILE" | sed '$d')
if [ -z "$FRONTMATTER" ]; then exit 0; fi

echo "$FRONTMATTER" | python3 -c 'import sys,yaml; yaml.safe_load(sys.stdin)' 2>&1
if [ $? -ne 0 ]; then
  echo "WARNING: Invalid YAML frontmatter in $FILE"
fi
