# Molcajete Setup Command - Task Breakdown

**Created:** 2025-11-14
**Last Updated:** 2025-11-14
**Status:** Planning

## Overview

### Feature Description

The Molcajete Setup Command provides a streamlined, interactive setup experience for configuring Molcajete marketplace plugins in Claude Code. It automates the configuration of Claude settings by allowing users to select from available plugins and automatically merging them into their ~/.claude/settings.local.json file with proper validation and error handling.

### Strategic Alignment

This feature aligns with Molcajete.ai's mission to bring consistency, quality, and reliability to AI-assisted development by making plugin installation frictionless and error-free. It's essential for initial user adoption - without easy setup, even the best plugins won't get used.

### Success Criteria

- Users can configure plugins through an interactive interface
- Zero data loss of existing configurations
- Setup completes in under 5 seconds
- Works reliably on macOS and Linux
- Clear error messages for all failure modes

### Estimated Effort

Total: 26 story points (3-4 days of focused development)

### Key Risks

- JSON parsing edge cases with malformed existing settings
- Platform-specific path handling differences
- File permission issues on various systems
- Interactive terminal UI compatibility

## Features

## 1. [x] Basic command and skill structure with file operations

Users should be able to invoke the molcajete:setup command which safely reads and writes Claude configuration files using a TypeScript skill.

- 1.1 [x] Create molcajete/commands/setup.md command file (Completed: 2025-11-14)
  - Complexity: 1 point
  - Dependencies: None
  - Acceptance: Command file exists, defines /molcajete:setup slash command
  - Implementation: Created command file with AskUserQuestion integration for plugin selection

- 1.2 [x] Create molcajete/skills/setup-utils.md skill file with TypeScript structure (Completed: 2025-11-14)
  - Complexity: 2 points
  - Dependencies: None
  - Acceptance: Skill file exists with basic TypeScript code structure
  - Implementation: Created skill with complete TypeScript utilities and error handling

- 1.3 [x] Implement settings file reader in skill with error handling (Completed: 2025-11-14)
  - Complexity: 3 points
  - Dependencies: 1.2
  - Acceptance: TypeScript skill reads ~/.claude/settings.local.json, handles missing file, invalid JSON
  - Implementation: readSettings() function with ENOENT, SyntaxError, and EACCES handling

- 1.4 [x] Implement atomic settings file writer in skill (Completed: 2025-11-14)
  - Complexity: 3 points
  - Dependencies: 1.3
  - Acceptance: TypeScript skill writes with proper formatting, validates JSON, creates ~/.claude directory if missing
  - Implementation: writeSettings() function with atomic write pattern, directory creation, and validation

## 2. [x] Interactive plugin selection using AskUserQuestion

Users should be able to interactively select which Molcajete plugins to install using Claude's native AskUserQuestion tool.

- 2.1 [x] Define plugin metadata in command file (Completed: 2025-11-14)
  - Complexity: 1 point
  - Dependencies: 1.1
  - Acceptance: Command file lists all available plugins with descriptions
  - Implementation: Added "Available Plugins" section with 6 plugins and descriptions

- 2.2 [x] Implement AskUserQuestion for plugin selection (Completed: 2025-11-14)
  - Complexity: 2 points
  - Dependencies: 2.1
  - Acceptance: Uses AskUserQuestion with multiSelect: true to allow multiple plugin selection
  - Implementation: Complete AskUserQuestion with proper options array, each with label and description

- 2.3 [x] Read existing plugins and pre-populate selection (Completed: 2025-11-14)
  - Complexity: 2 points
  - Dependencies: 1.3, 2.2
  - Acceptance: Reads current settings and shows already-configured plugins in selection UI
  - Implementation: Added logic to read existing settings, extract current plugins, display to user, and differentiate in success message

## 3. [ ] Settings merging and validation in TypeScript skill

Users should have their existing settings preserved while new plugin configurations are safely merged.

- 3.1 [ ] Implement JSON merge logic in skill
  - Complexity: 3 points
  - Dependencies: 1.3
  - Acceptance: TypeScript skill preserves all non-plugin settings, avoids duplicates

- 3.2 [ ] Add plugin configuration format validation
  - Complexity: 1 point
  - Dependencies: 3.1
  - Acceptance: Ensures plugin IDs follow namespace/name format

- 3.3 [ ] Handle edge cases in existing settings
  - Complexity: 2 points
  - Dependencies: 3.1
  - Acceptance: Handles missing plugins key, creates if needed, handles malformed structure

## 4. [ ] Error handling and user feedback

Users should receive clear feedback about setup progress and helpful error messages when issues occur.

- 4.1 [ ] Implement comprehensive error messages
  - Complexity: 1 point
  - Dependencies: All file operations
  - Acceptance: Specific messages for permission, JSON, file errors

- 4.2 [ ] Add success confirmation with details
  - Complexity: 1 point
  - Dependencies: 3.1
  - Acceptance: Shows count of added plugins, preserves feedback

- 4.3 [ ] Handle user cancellation gracefully
  - Complexity: 1 point
  - Dependencies: 2.2
  - Acceptance: Ctrl+C or ESC cancels without changes

## 5. [ ] Documentation and testing

Users should have confidence the command works reliably and understand how to use it.

- 5.1 [ ] Add molcajete plugin to PLUGIN.md
  - Complexity: 1 point
  - Dependencies: 1.1
  - Acceptance: PLUGIN.md lists molcajete plugin with setup command

- 5.2 [ ] Test command with real settings file
  - Complexity: 2 points
  - Dependencies: All features
  - Acceptance: Manual testing confirms command works end-to-end

- 5.3 [ ] Create usage documentation in molcajete/README.md
  - Complexity: 1 point
  - Dependencies: All features
  - Acceptance: README with usage examples, troubleshooting common errors

## Task Breakdown

### Phase 1: Foundation (Sequential)
- 1.1 [ ] Create molcajete/commands/setup.md (1 point)
- 1.2 [ ] Create molcajete/skills/setup-utils.md (2 points)
- 1.3 [ ] Implement settings file reader in skill (3 points)
- 1.4 [ ] Implement atomic settings writer in skill (3 points)

### Phase 2: Interactive Selection (Sequential)
- 2.1 [ ] Define plugin metadata in command file (1 point)
- 2.2 [ ] Implement AskUserQuestion for plugin selection (2 points)
- 2.3 [ ] Read existing plugins and pre-populate selection (2 points)

### Phase 3: Core Logic (Sequential)
- 3.1 [ ] Implement JSON merge logic in skill (3 points)
- 3.2 [ ] Add plugin configuration format validation (1 point)
- 3.3 [ ] Handle edge cases in existing settings (2 points)

### Phase 4: Polish (Parallel)
- 4.1 [ ] Implement comprehensive error messages (1 point)
- 4.2 [ ] Add success confirmation with details (1 point)
- 4.3 [ ] Handle user cancellation gracefully (1 point)

### Phase 5: Documentation (Parallel)
- 5.1 [ ] Add molcajete plugin to PLUGIN.md (1 point)
- 5.2 [ ] Test command with real settings file (2 points)
- 5.3 [ ] Create usage documentation (1 point)

## Execution Strategy

### Approach: Sequential Foundation, Then Parallel Polish

1. **Phase 1 (Sequential):** Build file operations foundation - must work before anything else
2. **Phase 2 (Sequential):** Add interactive UI - depends on knowing what plugins exist
3. **Phase 3 (Sequential):** Implement merge logic - core functionality
4. **Phase 4 (Parallel):** Polish and error handling - can be done simultaneously
5. **Phase 5 (Parallel):** Testing and documentation - can proceed in parallel

### Critical Path

1.1 → 1.2 → 1.3 → 1.4 → 2.1 → 2.2 → 2.3 → 3.1 → 3.2 → 3.3 → 5.2

The critical path is approximately 22 story points, suggesting 3-4 days of focused development.

### Parallel Opportunities

- Phase 4 tasks (4.1, 4.2, 4.3) can be done in parallel once Phase 3 is complete
- Phase 5 tasks (5.1, 5.2, 5.3) can be done in parallel
- Tasks 1.1 and 1.2 can be done in parallel (both are file creation)

## Risk Assessment

### Technical Risks

1. **JSON Parsing Issues**
   - Risk: Malformed existing settings files
   - Mitigation: Comprehensive error handling with line numbers
   - Fallback: Offer to backup and recreate

2. **Platform Compatibility**
   - Risk: Path handling differences between OS
   - Mitigation: Use Node.js path and os modules
   - Fallback: Test on both macOS and Linux

3. **File Permissions**
   - Risk: Unable to write to ~/.claude directory
   - Mitigation: Check permissions before operations
   - Fallback: Provide clear fix instructions

### Dependencies

- Node.js file system APIs (fs/promises)
- Claude Code's AskUserQuestion tool for selection interface
- JSON parsing and validation (native JSON.parse/stringify)

### Performance Considerations

- File operations should be atomic to prevent corruption
- UI should be responsive (< 100ms feedback)
- Total execution time target: < 5 seconds

### Security Considerations

- No network calls (prevents supply chain attacks)
- Local-only operations (ensures privacy)
- Safe JSON parsing (prevents injection)
- File permission validation

## Progress Tracking

**Overall Progress:** 54% (14/26 story points completed)

**Phase Status:**
- Phase 1 (Foundation): **COMPLETE** (9/9 points) ✓
- Phase 2 (Interactive Selection): **COMPLETE** (5/5 points) ✓
- Phase 3 (Core Logic): Not started (0/6 points)
- Phase 4 (Polish): Not started (0/3 points)
- Phase 5 (Documentation): Not started (0/4 points)

**Completed (2025-11-14):**
- 1.1 ✓ Create molcajete/commands/setup.md
- 1.2 ✓ Create molcajete/skills/setup-utils.md
- 1.3 ✓ Implement settings file reader
- 1.4 ✓ Implement atomic settings writer
- 2.1 ✓ Define plugin metadata in command file
- 2.2 ✓ Implement AskUserQuestion for plugin selection
- 2.3 ✓ Read existing plugins and pre-populate selection

**Next Actions:**
1. Task 3.1 - Implement JSON merge logic in skill
2. Task 3.2 - Add plugin configuration format validation
3. Task 3.3 - Handle edge cases in existing settings
