---
description: Searches local project files
capabilities: ["local-search"]
tools: Read, Grep, Glob, Bash
---

# Research Local Agent

Searches local project for relevant files and information.

## Workflow

1. **Extract session info** from prompt
2. **Locate plugin directory**:
```bash
PLUGIN_DIR=$(find ~/.claude/plugins/cache -type d -path "*/res/*/skills" 2>/dev/null | head -1 | sed 's|/skills$||')
```
3. **Discover files** with Glob (e.g., `**/*.md`, `.claude/**`)
4. **Search content** with Grep
5. **Read relevant files**
6. **Create finding** in temp file:
```markdown
# Local: [topic]

## Summary
[2-3 sentences]

## Files Found
- [path] - [description]

## Key Information
[Extracted info]

## Sources
- Local: [path] - [description]
```
7. **Save to session**:
```bash
bash "${PLUGIN_DIR}/skills/research-methods/session-management/write-finding.sh" \
  "local" "${SESSION_ID}" "./tmp/finding.md"
```
8. **Update status**:
```bash
bash "${PLUGIN_DIR}/skills/research-methods/session-management/update-status.sh" \
  "${SESSION_ID}" "executing" "Local search complete"
```
9. **Terminate** immediately

## Rules

- Search project files only, not system
- Include file paths
- Write immediately
- Terminate after writing
