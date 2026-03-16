# Molcajete.ai Product Roadmap

## Roadmap Philosophy

Molcajete.ai is a mature plugin — the core command and skill set covers the full development lifecycle. The roadmap focuses on validation, quality, and ecosystem growth rather than feature expansion.

## Now (Current Priority)

**Theme: Self-Testing and Validation**

| Feature | Description | Priority | Dependencies | Spec | Tasks |
|---------|-------------|----------|--------------|------|-------|
| BDD Feature Files | Write `.feature` files that validate commands produce expected artifact structure | Critical | None | [Spec](./specs/20260223-1600-bdd_scenario_generator/spec.md) | [Tasks](./specs/20260223-1600-bdd_scenario_generator/tasks.md) |
| Simplified Dispatch Pipeline | Replace v3 four-phase dispatch with three-agent model (Tester -> Developer -> Validator) per UC worktree | Critical | BDD Feature Files | [Spec](./specs/20260316-1650-simplified_dispatch_pipeline/spec.md) | [Tasks](./specs/20260316-1650-simplified_dispatch_pipeline/tasks.md) |
| Self-Testing Framework | Establish a repeatable way to run BDD tests against commands and skills | Critical | BDD Feature Files | — | — |

**Rationale**: The core promise is consistent output. Without automated validation, that promise relies on manual inspection. BDD tests make consistency measurable and enforceable.

## Next (After Self-Testing)

**Theme: Polish and Documentation**

| Feature | Description | Priority | Dependencies |
|---------|-------------|----------|--------------|
| Command Documentation | Generate usage docs for each command with examples | Medium | None |
| Skill Refinement | Review and tighten skills based on real-world usage patterns | Medium | None |
| Error Handling | Improve command behavior when required context is missing | Medium | None |

**Rationale**: With tests in place, refinements can be made confidently without regression.

## Later (Backlog)

**Theme: Ecosystem**

| Feature | Description | Priority | Dependencies |
|---------|-------------|----------|--------------|
| Community Skills | Enable third-party skill contributions with a contribution guide | Low | Self-Testing |
| Marketplace Listing | Publish and maintain presence in Claude Code plugin marketplace | Low | Command Documentation |
| Legacy Removal | Remove `legacy/` and `deprecated/` directories once migration is complete | Low | None |

**Rationale**: Ecosystem growth depends on having a stable, tested, documented foundation first.

## Completed

| Feature | Description | Completed Date | Notes |
|---------|-------------|----------------|-------|
| Core Commands (17) | Full lifecycle: init, feature, spec, tasks, dev, fix, test, review, doc, commit, amend, rebase, debug, research, summary, copy, prompt | 2026-02 | v2 workflow |
| Core Skills (19) | Software principles, dev workflow, project management, code docs, git, testing, copywriting, stack-specific (TS, Go, React, Node) | 2026-02 | Reusable knowledge base |
| Plugin Architecture | plugin.json manifests, YAML frontmatter commands, SKILL.md format with references | 2026-02 | v2 format |
| Clipboard Skill | Copy-to-clipboard integration for commands | 2026-02 | d6be7d8 |
| v2 Workflow Redesign | Redesigned command structure and skill organization | 2026-02 | c0a9ee2 |

## Roadmap Principles

1. **Stability over features** — The command set is largely complete. Focus on making what exists reliable and tested.
2. **Validate before expanding** — No new commands without BDD tests for existing ones.
3. **Complement, don't compete** — Molcajete works with CLAUDE.md and project-level rules, not against them.

## Dependencies and Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Claude Code plugin API changes | Commands may break if plugin format changes | Pin to known-working format; monitor Claude Code releases |
| LLM behavior drift | Model updates may change output for existing commands | BDD tests catch regressions; pin model preferences in commands |
| Scope creep | Adding commands dilutes the opinionated workflow | Roadmap principles enforce restraint; self-testing validates coverage |
