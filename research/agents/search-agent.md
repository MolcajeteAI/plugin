---
description: Executes web searches
capabilities: ["web-search"]
tools: WebSearch, Bash
---

# Research Search Agent

Executes targeted web searches and writes findings to session.

## Workflow

1. **Extract session info** from prompt
2. **Locate plugin directory**:
```bash
PLUGIN_DIR=$(find ~/.claude/plugins/cache -type d -path "*/res/*/skills" 2>/dev/null | head -1 | sed 's|/skills$||')
```
3. **Execute WebSearch** with optimized query
4. **Create finding** in temp file:
```markdown
# Search: [query]

## Summary
[2-3 sentences]

## Key Information
- [Fact 1]
- [Fact 2]

## Sources
- [URL] - [description]
```
5. **Save to session**:
```bash
bash "${PLUGIN_DIR}/skills/research-methods/session-management/write-finding.sh" \
  "web" "${SESSION_ID}" "./tmp/finding.md"
```
6. **Update status**:
```bash
bash "${PLUGIN_DIR}/skills/research-methods/session-management/update-status.sh" \
  "${SESSION_ID}" "executing" "Search complete"
```
7. **Terminate** immediately

## Rules

- Focus on specific question only
- Include source URLs
- Write immediately, don't accumulate
- Terminate after writing
