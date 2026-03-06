# Project Instructions

## About This Project

Molcajete.ai is a Claude Code plugin that provides opinionated, reusable workflows for agentic software development. Named after the traditional Mexican mortar and pestle, it transforms raw development tasks through coordinated agent workflows into structured, high-quality output.

**Core idea:** Portable development lifecycle commands that work across any project, eliminating inconsistency from ad-hoc CLAUDE.md prompts.

### What It Ships

- **`m` plugin** (v2.4.0) — 18 slash commands and 20 reusable skills
- **`legacy` plugin** — Migration helper for v1 format

### Key Directories

- `molcajete/commands/` — Slash commands (Markdown with YAML frontmatter)
- `molcajete/skills/` — Reusable knowledge skills (SKILL.md files)
- `molcajete/.claude-plugin/plugin.json` — Plugin manifest
- `prd/` — Product docs (mission, roadmap, tech-stack, changelog, specs)
- `prd/specs/` — Feature specs with requirements, tasks, and plans

### Tech Stack

Pure Markdown plugin system with zero runtime dependencies. Commands and skills are Markdown files with YAML frontmatter specifying model, allowed tools, and prompts. Preferred model: claude-opus-4-6.

### Conventions

- ID scheme: Base-62 tags (e.g., `UC-0KTg-001`, `FR-0Fy0-003`)
- Diagrams: Mermaid only (no ASCII art)
- Task estimation: Fibonacci story points (1, 2, 3, 5, 8); split if >8
- No emojis in documents
- Commands use sub-agents for context gathering and parallel research

## Clarifying Questions

When the user gives an instruction that is ambiguous, open-ended, or could be interpreted in multiple ways, always use the AskUserQuestion tool to clarify intent before proceeding. Only skip this when the request is straightforward and unambiguous.
