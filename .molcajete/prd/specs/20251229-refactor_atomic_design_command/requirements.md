# Refactor Atomic Design Command - Requirements

**Created:** 2025-12-29
**Last Updated:** 2025-12-29
**Status:** Draft

## Overview

This feature implements a `refactor-atomic-design` command for each JavaScript tech-stack plugin (React and React Native) that enables developers to convert existing flat component structures into the Atomic Design pattern. The command provides a guided, safe refactoring workflow that analyzes the current codebase, generates a migration plan, and executes the refactoring with user approval.

The Atomic Design pattern organizes components into five hierarchical levels (Atoms, Molecules, Organisms, Templates, Pages) promoting reusability, consistency, and scalability. While the init commands for React and React Native already create projects with this structure, existing projects lack a migration path. This command fills that gap by providing an intelligent refactoring workflow that handles component moves, import updates, test updates, and Storybook story generation.

## User Stories

### Primary User Story

**As a** developer with an existing React or React Native project
**I want** a command to refactor my flat component structure to Atomic Design
**So that** I can benefit from better organization, reusability, and consistency without manual migration

**Acceptance Criteria:**
- [ ] Command `/react:refactor-atomic-design` is available for React projects
- [ ] Command `/react-native:refactor-atomic-design` is available for React Native projects
- [ ] Command creates missing atomic design folders if they don't exist
- [ ] Command analyzes existing components and proposes classification
- [ ] User can review and approve/modify the refactoring plan before execution
- [ ] Refactoring updates all import statements across the codebase
- [ ] Refactoring updates or creates tests for moved components
- [ ] Refactoring creates or updates Storybook stories for Atoms, Molecules, and Organisms

### Additional User Story: Safe Refactoring

**As a** developer
**I want** the refactoring to be safe and reversible
**So that** I can confidently refactor without fear of breaking my codebase

**Acceptance Criteria:**
- [ ] Plan is presented before any changes are made
- [ ] User must explicitly approve the plan to proceed
- [ ] All changes are logged for review
- [ ] Command provides clear error messages if issues are detected

### Additional User Story: Incremental Refactoring

**As a** developer with a large codebase
**I want** to refactor components incrementally
**So that** I can migrate gradually without a big-bang refactoring

**Acceptance Criteria:**
- [ ] Command can target specific directories or components
- [ ] Previously refactored components are detected and skipped
- [ ] Command can be run multiple times as new components are added

## Functional Requirements

### Core Functionality

1. **Command Registration:** Register commands with respective tech-stack prefixes
   - `/react:refactor-atomic-design` for React (Vite SPA and Next.js)
   - `/react-native:refactor-atomic-design` for React Native (Expo)

2. **Directory Structure Setup:** Create atomic design folder structure if missing
   - For React: `src/components/atoms/`, `molecules/`, `organisms/`, `templates/`
   - For React Native: `components/atoms/`, `molecules/`, `organisms/`, `templates/`
   - Create `.gitkeep` files in empty directories
   - Create barrel export `index.ts` files at each level

3. **Component Analysis Phase:** Code analyzer researches existing components
   - Scan component directories for existing components
   - Analyze component structure (imports, dependencies, state usage)
   - Classify each component into atomic levels using classification criteria
   - Identify component relationships and dependencies
   - Detect existing tests and Storybook stories

4. **Plan Generation:** Create refactoring plan for user review
   - List each component with proposed atomic level
   - Show source and destination paths
   - Indicate required import updates
   - Flag potential conflicts or issues
   - Show which tests and stories will be created/updated

5. **User Approval:** Present plan and gather user feedback
   - Display clear, readable refactoring plan
   - Allow user to approve, modify classifications, or cancel
   - Support partial approval (refactor some, skip others)
   - Record user decisions for future runs

6. **Refactoring Execution:** Execute approved refactoring plan
   - Move component files to correct atomic directories
   - Update all import statements across the codebase
   - Create component barrel exports
   - Update level-specific barrel exports (atoms/index.ts, etc.)
   - Create or update component tests
   - Create Storybook stories for Atoms, Molecules, Organisms

7. **Post-Refactoring Verification:** Validate the refactoring was successful
   - Run type-check to verify imports are correct
   - Run linter to catch formatting issues
   - Run existing tests to verify functionality
   - Report any issues found

### Edge Cases

- **Existing Atomic Structure:** If project already has atomic directories with components, skip those components and report them
- **Circular Dependencies:** If circular dependencies are detected, warn user and suggest resolution
- **Non-Standard Component Locations:** If components exist outside expected directories, prompt user for confirmation
- **Missing Tests:** If component has no tests, create test file stub with basic structure
- **Missing Storybook:** If Storybook is not set up, offer to set it up or skip story generation
- **Large Codebases:** For projects with 100+ components, offer batch processing options

### Business Rules

- **Classification Priority:** Use atomic-design skill classification criteria for automatic classification
- **Storybook Scope:** Only create stories for Atoms, Molecules, and Organisms (not Templates/Pages)
- **Test Preservation:** Existing tests must be preserved and updated, never deleted
- **Import Updates:** All import statements across the entire codebase must be updated
- **Barrel Exports:** Every moved component must be added to the appropriate barrel export

## Non-Functional Requirements

### Performance

- **Analysis Time:** Component analysis should complete within 30 seconds for projects with up to 100 components
- **Refactoring Time:** Refactoring execution should complete within 60 seconds for typical projects
- **Memory Usage:** Should not consume excessive memory during analysis

### Security

- **No Data Transmission:** All analysis and refactoring happens locally
- **No Side Effects:** Command only modifies files user explicitly approves
- **Backup Recommendation:** Recommend user commit or stash changes before running

### Usability

- **Clear Output:** Progress and status messages should be clear and informative
- **Error Messages:** Errors should be descriptive with actionable guidance
- **Plan Readability:** Refactoring plan should be easy to understand and review

### Reliability

- **Idempotency:** Running command multiple times should not cause issues
- **Atomic Operations:** File operations should be grouped to prevent partial updates
- **Rollback Guidance:** If errors occur, provide guidance on how to recover

## Constraints

### Technical Constraints

- Must integrate with existing tech-stack plugin architecture
- Must use existing atomic-design and atomic-design-mobile skills for classification
- Must work with Vite (React SPA), Next.js (React SSR), and Expo (React Native)
- Must maintain compatibility with TypeScript strict mode
- Must work with existing Storybook configurations if present

### Business Constraints

- Implementation should reuse existing agent patterns (component-builder agents)
- Must follow Molcajete.ai documentation and command structure standards
- Should leverage existing skills rather than duplicating logic

### Resource Constraints

- Single developer implementation
- Should be completable in reasonable timeframe (vertical feature approach)

## Assumptions

- Projects use TypeScript (the tech-stacks already assume TypeScript)
- Components follow standard React/React Native patterns (function components)
- Existing project structure is relatively conventional
- User has Git or version control to revert if needed
- Storybook may or may not be already set up

## Out of Scope

Explicitly state what this feature will NOT include:

- **Automatic Classification AI:** Agent provides classification based on rules, not machine learning
- **Cross-Tech-Stack Migration:** Cannot migrate between React and React Native
- **Design System Migration:** Does not handle design token or styling migrations
- **Breaking Change Detection:** Does not analyze component API changes
- **Multi-Repository Support:** Only works within a single repository
- **Custom Atomic Levels:** Uses standard five-level hierarchy only
- **Visual Component Preview:** No visual diff or preview of changes

## Open Questions

- **Question 1:** Should the command offer a dry-run mode that shows changes without executing?
  - **Status:** Answered
  - **Answer:** Yes, the plan generation phase serves as the dry-run. User must approve before execution.

- **Question 2:** How should the command handle components that are difficult to classify?
  - **Status:** Answered
  - **Answer:** Present ambiguous components to user for manual classification during approval phase.

- **Question 3:** Should we support refactoring of CSS/style files alongside components?
  - **Status:** Deferred
  - **Answer:** Defer to future enhancement. Initial version focuses on component and import updates only.

## Visual References

- **Mockups:** N/A - this is a CLI command feature
- **Wireframes:** N/A
- **Design System:** N/A
- **Similar Implementations:** React codemod tools, Next.js migration scripts

## Dependencies

### Technical Dependencies

- React tech-stack plugin must exist (completed)
- React Native tech-stack plugin must exist (completed)
- atomic-design skill must exist (completed)
- atomic-design-mobile skill must exist (completed)
- component-builder agents must exist (completed)

### External Dependencies

- None - all functionality is local

## Success Criteria

How will we know this feature is successful?

### User Success

- Developers can refactor existing projects to Atomic Design in under 10 minutes
- Refactored projects pass type-check and lint without errors
- All existing tests continue to pass after refactoring
- New Storybook stories are generated and functional

### Business Success

- Reduced friction for adopting Atomic Design pattern
- Consistent component organization across new and existing Molcajete.ai projects
- Increased adoption of atomic-design skills

### Technical Success

- Command executes without errors on typical React and React Native projects
- All import statements are correctly updated
- Barrel exports are correctly maintained
- Type-check passes after refactoring

---

## Implementation Scope (MVP)

### Phase 1: Directory Setup

1. Create `/react:refactor-atomic-design` command definition
2. Create `/react-native:refactor-atomic-design` command definition
3. Implement atomic directory creation with .gitkeep files
4. Implement barrel export file creation

### Phase 2: Code Analysis Agent

5. Create code-analyzer agent for React (or extend component-builder)
6. Create code-analyzer agent for React Native (or extend component-builder)
7. Implement component scanning and classification logic
8. Implement dependency graph analysis

### Phase 3: Plan Generation and Approval

9. Implement refactoring plan generator
10. Implement user-facing plan display format
11. Implement approval workflow (approve/modify/cancel)

### Phase 4: Refactoring Execution

12. Implement component file moving
13. Implement import statement updates across codebase
14. Implement barrel export updates

### Phase 5: Test and Storybook Updates

15. Implement test file updates (move and fix imports)
16. Implement Storybook story generation for moved components
17. Implement post-refactoring verification (type-check, lint, test)

### Phase 6: Documentation

18. Document command usage in React PLUGIN.md
19. Document command usage in React Native PLUGIN.md
20. Add examples and common scenarios

### Future Enhancements

- Batch processing for large codebases
- Configuration file for persistent classification overrides
- Integration with CI/CD for automated verification
- Support for CSS module and styled-component migrations
