# Research Plugin

Intelligent research and information gathering plugin for Claude Code with automatic detection, smart formatting, and comprehensive source tracking.

## Overview

The Research plugin automatically detects when you need information from external sources and delegates to a specialized researcher agent that:

- Conducts thorough research across documentation and web sources
- Intelligently determines whether you need a simple answer or detailed analysis
- Prioritizes official documentation sources
- Tracks and cites all sources properly
- Formats responses in clean, scannable templates
- Optionally saves detailed research to disk for future reference

## Features

### Automatic Detection

The plugin automatically triggers when you ask research-type questions:

```
You: "How do I amend a git commit?"
→ Researcher agent activates, provides concise answer with sources

You: "Research all available hooks in Claude Code"
→ Researcher agent activates, provides comprehensive analysis
```

### Intelligent Response Types

**Simple Response** - For quick, specific questions:
- Direct answers with code examples
- Concise explanations
- 2-4 sources
- Fast results

**Detailed Response** - For comprehensive research:
- Executive summary
- Organized sections by topic
- Key takeaways
- 5+ sources
- Optional disk save

### Source Priority

1. **Primary**: Official documentation (code.claude.com, github.com, gist.github.com)
2. **Secondary**: Community resources when needed
3. **General**: Web search for broader topics

All sources are tracked and cited properly.

## Usage

### Via Command

Explicitly trigger research:

```bash
/research How do React hooks work?
```

### Automatic Invocation

Simply ask questions naturally:

```
How do I configure Claude Code hooks?
What are all the available git commands for amending?
Research the best practices for error handling in Python
Give me a comprehensive overview of TypeScript generics
```

### Response Format

**Simple Response Example:**
```markdown
# How to Amend a Git Commit

Use `git commit --amend` to modify the most recent commit...

[concise answer with code examples]

## Sources
- https://git-scm.com/docs/git-commit - Official documentation
- https://github.com/git-guides/git-commit - GitHub guide
```

**Detailed Response Example:**
```markdown
# Claude Code Hooks: Complete Guide

Claude Code hooks are event-driven commands that execute automatically...

## Overview
[context and background]

## Available Hook Events
[detailed sections]

## Key Takeaways
- [important points]

## Sources
- [comprehensive source list]
```

## Architecture

### Command → Agent → Skill Pattern

```
/research (command)
    ↓
    Triggers researcher agent
    ↓
researcher agent (orchestrates workflow)
    ↓
    References research-methods skill (provides standards)
    ↓
    Uses WebFetch/WebSearch tools
    ↓
    Returns formatted response with sources
```

### Components

**Command**: `/research`
- Minimal trigger that delegates to agent
- Located: `commands/research.md`

**Agent**: `researcher`
- Orchestrates research workflow
- Determines response type
- Manages source tracking
- Handles file saving
- Located: `agents/researcher.md`

**Skill**: `research-methods`
- Defines templates and standards
- Search strategies per domain
- Source evaluation criteria
- Quality guidelines
- Located: `skills/research-methods/`

## Configuration

### Enable Plugin

Add to your marketplace configuration:

```json
{
  "enabledPlugins": {
    "research@molcajete": true
  }
}
```

### Customize Behavior

The plugin works out of the box, but you can customize by modifying:

- **Agent behavior**: Edit `agents/researcher.md`
- **Templates**: Edit `skills/research-methods/templates.md`
- **Search strategies**: Edit `skills/research-methods/search-strategies.md`
- **Source criteria**: Edit `skills/research-methods/source-evaluation.md`

## Examples

### Quick Reference

**Input:**
```
How do I use the WebFetch tool?
```

**Output:**
Simple response with syntax, example, and 2-3 sources

### Comprehensive Research

**Input:**
```
Research all available Claude Code hooks and give me a 5 min intro
```

**Output:**
Detailed response with:
- Executive summary
- All hook types explained
- Configuration examples
- Best practices
- 5-10 authoritative sources
- Prompt to save to disk

### Clarification Flow

**Input:**
```
Research React hooks
```

**Agent asks:**
```
Are you asking about:
1. React library hooks (useState, useEffect, etc.)
2. Claude Code hooks for React projects
```

**After clarification:**
Provides targeted research based on your answer

## Saving Research

For detailed responses, the agent will ask:

```
Would you like to save this research to a file?
```

If yes, provide a file path:
```
.molcajete/research/claude-hooks.md
```

The formatted markdown will be saved for future reference.

## Detection Patterns

### Triggers Research Agent

- "How do I..."
- "How to..."
- "What is..."
- "What are..."
- "Explain..."
- "Research..."
- "Find documentation for..."
- "Look up..."
- Contains: "documentation", "docs", "reference", "guide"

### Doesn't Trigger

- Questions about current codebase files
- Implementation requests
- Debugging current code
- Code review requests

## Skills Documentation

### Main Skill

**research-methods** (`skills/research-methods/SKILL.md`)
- Response type selection rules
- Research process workflow
- Formatting standards
- Source attribution guidelines
- Quality criteria

### Supporting Documentation

**templates.md** - Complete template examples
- Simple response template with examples
- Detailed response template with examples
- Template selection guide
- Tone and style guidelines

**search-strategies.md** - Advanced search techniques
- Tool usage (WebFetch vs WebSearch)
- Domain-specific strategies
- Query construction patterns
- Multi-source research workflow

**source-evaluation.md** - Quality assessment
- Source quality tiers
- Evaluation criteria
- Version awareness
- Cross-referencing methods
- Code quality assessment

## Best Practices

### For Users

1. **Be specific** - Better questions get better answers
2. **Provide context** - Mention versions, platforms when relevant
3. **Ask clarifying questions** - Agent will ask if needed
4. **Save important research** - Accept save prompt for references

### For Developers

1. **Trust the agent** - It determines simple vs detailed automatically
2. **Verify critical info** - Agent cross-references but always verify
3. **Check dates** - Note version-specific information
4. **Save research** - Build your knowledge base over time

## Troubleshooting

### Agent Not Triggering

If research agent doesn't activate for a question:
- Use explicit `/research` command
- Rephrase as a question ("How to..." instead of "I need...")
- Add keywords like "research", "documentation"

### Wrong Response Type

If you get detailed when you wanted simple (or vice versa):
- Be explicit: "Give me a quick answer to..."
- Or: "I need a comprehensive guide to..."
- The agent learns from your feedback

### No Sources Found

If agent can't find information:
- Check terminology (correct tool/library name?)
- Try alternative search terms
- Verify the feature exists in current version
- Agent will ask for clarification

### Outdated Information

If sources seem outdated:
- Check version numbers in response
- Ask agent to search for current version
- Cross-reference with official docs
- Note: Agent prioritizes recent sources

## Development

### Plugin Structure

```
research/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── commands/
│   └── research.md          # /research command
├── agents/
│   └── researcher.md        # Main agent orchestrator
├── skills/
│   └── research-methods/
│       ├── SKILL.md                    # Main skill entry
│       ├── templates.md                # Response templates
│       ├── search-strategies.md        # Search techniques
│       └── source-evaluation.md        # Quality criteria
└── README.md                # This file
```

### Extending the Plugin

**Add new response types:**
1. Define template in `templates.md`
2. Add selection logic in `SKILL.md`
3. Update agent workflow in `researcher.md`

**Add new source types:**
1. Add search strategy in `search-strategies.md`
2. Add evaluation criteria in `source-evaluation.md`
3. Update agent source priority

**Add new features:**
1. Update agent workflow in `researcher.md`
2. Document in skill files
3. Update README

## Contributing

This plugin follows the standard Claude Code plugin architecture:

1. **Commands** are minimal triggers
2. **Agents** orchestrate workflows
3. **Skills** provide detailed rules

When making changes:
- Keep commands simple (just trigger agent)
- Put logic in agent workflows
- Put standards/rules in skills
- Document everything thoroughly

## License

Part of the local Claude Code plugin marketplace.

## Author

Ivan Torres (ivantorresedge@gmail.com)

## Version

1.0.0 - Initial release

## Keywords

research, search, analysis, documentation, information-gathering, web-search, sources, citations
