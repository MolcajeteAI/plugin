#!/usr/bin/env bash
# PreToolUse hook: Block unintentional edits to plugin.json
if echo "$CLAUDE_TOOL_INPUT" | grep -q 'plugin.json'; then
  echo "BLOCK: plugin.json edits need explicit intent — confirm this is intentional." >&2
  exit 2
fi
