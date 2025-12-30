# Refactor Atomic Design Command - Tasks

**Created:** 2025-12-29
**Last Updated:** 2025-12-29
**Status:** Complete
**Completion:** 100% (28/28 tasks complete)

## Overview

**Spec Reference:** `.molcajete/prd/specs/20251229-refactor_atomic_design_command/spec.md`
**Feature Description:** Command to refactor existing React and React Native projects to Atomic Design pattern with analysis, plan approval, and automated execution
**Estimated Total Effort:** 74 points

### Strategic Alignment

This feature extends the recently completed Atomic Design Pattern feature by providing migration tooling for existing projects. It directly supports the mission of "consistency, quality, and reliability" by ensuring all projects - new and legacy - can benefit from organized component hierarchies.

### Success Criteria

- Developers can refactor existing flat component structures to Atomic Design in under 10 minutes
- Commands are available for both React (Vite/Next.js) and React Native (Expo)
- Refactoring preserves all existing functionality (tests pass, type-check passes)
- Users have full control through plan approval workflow

### Key Risks

- Complex import path updates across large codebases
- Edge cases in component classification (low confidence scenarios)
- Storybook compatibility across framework versions

---

## 1. [x] Developers can run the refactor-atomic-design command on React projects

- 1.1 [x] Create React refactor-atomic-design command definition (Complexity: 3) ✓ Completed 2025-12-29
  - **Details:** Create `/tech-stacks/js/react/commands/refactor-atomic-design.md` with command name, description, parameters (--target, --dry-run, --skip-stories, --skip-tests), and agent invocation
  - **Acceptance:** Command file exists with complete parameter documentation and clear workflow description
  - **Dependencies:** None
  - **Implementation Note:** Created with 6-phase workflow (Initialization, Analysis, Plan Generation, User Approval, Refactoring Execution, Verification)

- 1.2 [x] Create React code-analyzer agent definition (Complexity: 5) ✓ Completed 2025-12-29
  - **Details:** Create `/tech-stacks/js/react/agents/code-analyzer.md` with agent persona, responsibilities (scan, analyze, classify, plan, execute, verify), tool usage patterns, and skill references (atomic-design)
  - **Acceptance:** Agent definition includes classification decision flowchart, RefactoringPlan structure, and all analysis workflows
  - **Dependencies:** 1.1
  - **Implementation Note:** Includes full RefactoringPlan TypeScript interface, classification checklists for all atomic levels, confidence scoring, plan display format, and error handling

- 1.3 [x] Implement atomic directory creation logic in command (Complexity: 3) ✓ Completed 2025-12-29
  - **Details:** Add instructions for creating atoms/, molecules/, organisms/, templates/ directories with .gitkeep files and barrel export index.ts files if missing
  - **Acceptance:** Command creates complete atomic structure before refactoring begins
  - **Dependencies:** 1.1
  - **Implementation Note:** Included in Phase 1: Initialization of command definition with directory structure and barrel export templates

- 1.4 [x] Update React PLUGIN.md with refactor-atomic-design command (Complexity: 1) ✓ Completed 2025-12-29
  - **Details:** Add refactor-atomic-design to the commands section of `/tech-stacks/js/react/PLUGIN.md` with description
  - **Acceptance:** Command is discoverable in plugin documentation
  - **Dependencies:** 1.1
  - **Implementation Note:** Added Refactoring section with command and code-analyzer agent to Agents section

---

## 2. [x] Code analyzer can scan and classify existing components

- 2.1 [x] Define component scanning workflow using Glob tool (Complexity: 3) ✓ Completed 2025-12-29
  - **Details:** Document Glob patterns to find component files (*.tsx in components/, excluding test and story files). Handle Vite (src/components/), Next.js (src/components/), framework detection
  - **Acceptance:** Scanning finds all component files across supported React frameworks
  - **Dependencies:** 1.2
  - **Implementation Note:** Added "Component Scanning Workflow" section to code-analyzer.md with framework detection (Vite/Next.js), scanning patterns for PascalCase .tsx files, exclusion patterns, edge case handling, and scanning output structure

- 2.2 [x] Define import analysis workflow using Grep tool (Complexity: 5) ✓ Completed 2025-12-29
  - **Details:** Document Grep patterns to find import statements referencing each component. Track which files import which components for the affectedFiles list
  - **Acceptance:** Import analysis produces accurate list of files to update
  - **Dependencies:** 1.2
  - **Implementation Note:** Added "Import Analysis Workflow" section with patterns for named, default, and type imports; path alias detection for @/, ~/, src/ patterns; import update planning with line number tracking

- 2.3 [x] Implement component classification logic (Complexity: 8) ✓ Completed 2025-12-29
  - **Details:** Document classification rules from atomic-design skill: atoms (no custom imports, stateless), molecules (2+ atoms, single purpose), organisms (larger sections, may have business logic), templates (accepts children, layout), pages (data fetching, routes). Include confidence scoring
  - **Acceptance:** Classification produces correct atomic level with confidence rating for test scenarios in spec
  - **Dependencies:** 1.2
  - **Implementation Note:** Added "Classification Algorithm" section with 5-step classification order (Template→Page→Atom→Molecule→Organism), scoring-based classification with confidence thresholds, edge case handling table, and classification output structure

- 2.4 [x] Define circular dependency detection (Complexity: 3) ✓ Completed 2025-12-29
  - **Details:** Document pattern for detecting circular dependencies (A imports B, B imports A) during analysis phase. Generate warnings with suggestions
  - **Acceptance:** Circular dependencies detected and reported with actionable suggestions
  - **Dependencies:** 2.2
  - **Implementation Note:** Added "Circular Dependency Detection" section with import graph structure, DFS cycle detection algorithm, warning generation patterns, common circular dependency patterns with resolutions, and integration with analysis workflow

---

## 3. [x] Users can review and approve refactoring plans before execution

- 3.1 [x] Define RefactoringPlan data structure (Complexity: 3) ✓ Completed 2025-12-29
  - **Details:** Document the RefactoringPlan, ComponentMigration, AffectedFile, and Warning interfaces from spec in the code-analyzer agent
  - **Acceptance:** Data structure supports all plan display and user interaction requirements
  - **Dependencies:** 2.3
  - **Implementation Note:** Already documented in code-analyzer.md (lines 568-621) with full TypeScript interfaces for RefactoringPlan, ComponentMigration, AffectedFile, and Warning

- 3.2 [x] Implement plan display formatting (Complexity: 3) ✓ Completed 2025-12-29
  - **Details:** Document output format showing summary (totals by level, imports to update, stories to create), component details grouped by level, warnings section, and options menu
  - **Acceptance:** Plan output matches spec examples and is clearly readable
  - **Dependencies:** 3.1
  - **Implementation Note:** Already documented in code-analyzer.md (lines 625-692) with full plan output format including summary, component groupings, warnings, and options menu

- 3.3 [x] Implement approve-all workflow (Complexity: 1) ✓ Completed 2025-12-29
  - **Details:** Document workflow when user selects "Approve all and execute" - proceed directly to refactoring execution
  - **Acceptance:** Approve-all triggers full refactoring execution
  - **Dependencies:** 3.2
  - **Implementation Note:** Added "User Approval Workflows" section to code-analyzer.md with detailed approve-all workflow including confirmation prompt and progress display

- 3.4 [x] Implement classification modification workflow (Complexity: 3) ✓ Completed 2025-12-29
  - **Details:** Document interactive workflow for modifying component classifications. User enters component name, sees options (Atom, Molecule, Organism, Template, Skip), updates modifiedLevel
  - **Acceptance:** Users can override any classification before execution
  - **Dependencies:** 3.2
  - **Implementation Note:** Added "Modify Classifications Workflow" section with interactive loop, level selection, and modification persistence

- 3.5 [x] Implement partial selection workflow (Complexity: 3) ✓ Completed 2025-12-29
  - **Details:** Document workflow for selecting specific components. User enters comma-separated list, only selected components are included in execution
  - **Acceptance:** Partial refactoring only affects selected components
  - **Dependencies:** 3.2
  - **Implementation Note:** Added "Partial Selection Workflow" section with selection shortcuts (all-atoms, all-molecules, etc.), validation, and filtered summary display

---

## 4. [x] Refactoring execution moves files and updates imports correctly

- 4.1 [x] Implement file moving logic (Complexity: 5) ✓ Completed 2025-12-29
  - **Details:** Document workflow for moving component directories from source to destination path. Handle component file, index.ts, test files, story files. Use Write tool for new locations, track for cleanup
  - **Acceptance:** Components moved to correct atomic directories with all associated files
  - **Dependencies:** 3.3
  - **Implementation Note:** Added "File Moving Workflow" section to code-analyzer.md with directory-based moving strategy, associated file detection patterns, file copy sequence, and cleanup strategy

- 4.2 [x] Implement import statement updates (Complexity: 8) ✓ Completed 2025-12-29
  - **Details:** Document pattern for updating import paths across affected files. Handle relative paths, alias paths (@/components), named imports, default imports. Use Edit tool for precise replacements
  - **Acceptance:** All import statements updated without breaking syntax
  - **Dependencies:** 4.1
  - **Implementation Note:** Added "Import Statement Update Workflow" section with path transformation rules, Edit tool usage patterns, path alias resolution, and edge case handling for dynamic imports, re-exports, type imports, and namespace imports

- 4.3 [x] Implement barrel export updates (Complexity: 5) ✓ Completed 2025-12-29
  - **Details:** Document pattern for creating/updating index.ts files at each atomic level. Add moved components to level barrel exports. Update main components/index.ts
  - **Acceptance:** Barrel exports enable importing from @/components/atoms, @/components/molecules, etc.
  - **Dependencies:** 4.1
  - **Implementation Note:** Added "Barrel Export Update Workflow" section with level and main barrel export patterns, update strategy using Edit and Write tools, type export detection, and duplicate prevention

- 4.4 [x] Implement incremental refactoring detection (Complexity: 3) ✓ Completed 2025-12-29
  - **Details:** Document logic to detect already-refactored components (already in atomic directories). Skip these during analysis to avoid duplicate moves
  - **Acceptance:** Running command twice does not re-process already-moved components
  - **Dependencies:** 2.1
  - **Implementation Note:** Added "Incremental Refactoring Detection" section with detection logic, exclusion patterns for atomic directories, reporting format, and idempotency guarantees

---

## 5. [x] Refactoring generates Storybook stories for applicable components

- 5.1 [x] Implement test file handling (Complexity: 3) ✓ Completed 2025-12-29
  - **Details:** Document workflow for moving test files alongside components. Update import paths within test files. Never delete existing tests
  - **Acceptance:** Test files move with components, imports updated, all tests continue to pass
  - **Dependencies:** 4.1
  - **Implementation Note:** Added "Test File Handling Workflow" section to code-analyzer.md with test file detection patterns, test import update rules, and preservation guarantees

- 5.2 [x] Implement Storybook story generation for React (Complexity: 5) ✓ Completed 2025-12-29
  - **Details:** Document story generation for atoms, molecules, organisms only. Use atomic-design skill templates. Generate with Meta, StoryObj types, appropriate title hierarchy (e.g., "Atoms/Button")
  - **Acceptance:** Stories generated for lower three levels with correct format and controls
  - **Dependencies:** 4.3
  - **Implementation Note:** Added "Storybook Story Generation Workflow" section with level-specific templates, prop analysis for argTypes, story title hierarchy, and skip conditions for templates/pages

- 5.3 [x] Implement Storybook detection and skip option (Complexity: 3) ✓ Completed 2025-12-29
  - **Details:** Document detection of Storybook setup (check for .storybook/). If not found, warn and offer skip option. Support --skip-stories flag
  - **Acceptance:** Command gracefully handles projects without Storybook configured
  - **Dependencies:** 5.2
  - **Implementation Note:** Added "Storybook Detection Workflow" section with detection patterns, warning messages, user prompts for skip/setup options, and --skip-stories flag handling

---

## 6. [x] Post-refactoring verification ensures code quality

- 6.1 [x] Implement type-check verification (Complexity: 3) [Completed 2025-12-29]
  - **Details:** Document running npm run type-check (or tsc --noEmit) after refactoring. Report pass/fail status. If fail, provide guidance
  - **Acceptance:** Type errors from broken imports are detected and reported
  - **Dependencies:** 4.2
  - **Implementation Note:** Added "Post-Refactoring Verification" section and "Type-Check Verification Workflow" to code-analyzer.md with command detection, output parsing, status reporting, error guidance, and recovery actions

- 6.2 [x] Implement lint verification (Complexity: 1) [Completed 2025-12-29]
  - **Details:** Document running npm run lint after refactoring. Note auto-fixed count. Report any remaining errors
  - **Acceptance:** Linting runs and reports status
  - **Dependencies:** 6.1
  - **Implementation Note:** Added "Lint Verification Workflow" section to code-analyzer.md with Biome/ESLint detection, auto-fix tracking, and lint error guidance

- 6.3 [x] Implement test verification (Complexity: 3) [Completed 2025-12-29]
  - **Details:** Document running npm test after refactoring. Report pass/fail count. If failures, suggest checking import updates in test files
  - **Acceptance:** Existing tests run and report status
  - **Dependencies:** 6.1
  - **Implementation Note:** Added "Test Verification Workflow" section to code-analyzer.md with Vitest/Jest detection, pass/fail parsing, and test failure guidance with specific import update suggestions

- 6.4 [x] Implement completion summary and next steps (Complexity: 1) [Completed 2025-12-29]
  - **Details:** Document final output format showing files changed, components moved, stories created, barrel exports updated, and next steps (run storybook, review git diff, commit). Include undo guidance
  - **Acceptance:** Clear summary helps user understand what changed and what to do next
  - **Dependencies:** 6.3
  - **Implementation Note:** Added "Completion Summary and Next Steps" section to code-analyzer.md with summary display format, next steps, undo instructions, cleanup reminders, and commit message suggestions

---

## 7. [x] Developers can run the refactor-atomic-design command on React Native projects

- 7.1 [x] Create React Native refactor-atomic-design command definition (Complexity: 3) [Completed 2025-12-29]
  - **Details:** Create `/tech-stacks/js/react-native/commands/refactor-atomic-design.md` with same parameters as React command, referencing atomic-design-mobile skill
  - **Acceptance:** Command file exists with complete parameter documentation for Expo projects
  - **Dependencies:** 1.1 (parallel from)
  - **Implementation Note:** Created command definition adapted for Expo projects with no src/ prefix, referencing atomic-design-mobile skill

- 7.2 [x] Create React Native code-analyzer agent definition (Complexity: 5) [Completed 2025-12-29]
  - **Details:** Create `/tech-stacks/js/react-native/agents/code-analyzer.md` adapted for mobile. Reference atomic-design-mobile skill. Handle components/ (no src/ prefix), Expo Router conventions
  - **Acceptance:** Agent handles Expo project structure correctly
  - **Dependencies:** 7.1, 1.2
  - **Implementation Note:** Created agent with mobile-specific scanning patterns (components/**), Expo framework detection, and reference to atomic-design-mobile skill

- 7.3 [x] Adapt classification logic for mobile (Complexity: 3) [Completed 2025-12-29]
  - **Details:** Include mobile-specific classification criteria: touch target size checks, accessibility prop presence, platform-specific code detection
  - **Acceptance:** Classification considers mobile requirements when assigning confidence
  - **Dependencies:** 7.2, 2.3
  - **Implementation Note:** Added mobile classification criteria including 44pt touch targets, accessibility props (accessibilityLabel, accessibilityRole, accessibilityState), and platform-specific code patterns

- 7.4 [x] Implement React Native Storybook story generation (Complexity: 3) [Completed 2025-12-29]
  - **Details:** Document story generation using @storybook/react-native format with addon-ondevice-controls compatible argTypes
  - **Acceptance:** Mobile stories work with on-device Storybook
  - **Dependencies:** 7.2, 5.2
  - **Implementation Note:** Added story templates using @storybook/react-native imports, on-device control patterns, and Storybook detection for React Native

- 7.5 [x] Update React Native PLUGIN.md with refactor-atomic-design command (Complexity: 1) [Completed 2025-12-29]
  - **Details:** Add refactor-atomic-design to the commands section of `/tech-stacks/js/react-native/PLUGIN.md`
  - **Acceptance:** Command is discoverable in React Native plugin documentation
  - **Dependencies:** 7.1
  - **Implementation Note:** Added Refactoring section with command and code-analyzer agent to Agents section

---

## Execution Strategy

**Recommended Approach:** Mostly Sequential with Parallel Opportunities

**Rationale:** Features 1-6 are sequential for React (foundation builds on itself). Feature 7 (React Native) can begin after Feature 1 completes since it shares command structure but has independent implementation.

### Sequential Execution Plan

1. Complete Feature 1 (Command infrastructure) - establishes foundation
2. Complete Feature 2 (Code analysis) - depends on command structure
3. Complete Feature 3 (Plan approval) - depends on analysis
4. Complete Feature 4 (Refactoring execution) - depends on plan
5. Complete Feature 5 (Test and stories) - depends on execution
6. Complete Feature 6 (Verification) - depends on execution
7. Complete Feature 7 (React Native) - can start after Feature 1

### Parallel Opportunities

- Feature 7 (React Native) can run in parallel with Features 2-6 after Feature 1 completes
- Tasks 7.1-7.2 can start immediately after 1.1-1.2
- Tasks 3.3, 3.4, 3.5 can run in parallel (independent approval workflows)
- Tasks 6.1, 6.2, 6.3 can run in parallel (independent verification steps)

### Critical Path

1.1 -> 1.2 -> 2.1 -> 2.2 -> 2.3 -> 3.1 -> 3.2 -> 4.1 -> 4.2 -> 4.3 -> 6.1 -> 6.4

---

## Risk Assessment

### Technical Risks

- **Import path complexity:** Large codebases may have various import patterns (relative, absolute, aliases). Mitigation: Test against common patterns, provide clear error messages for unsupported patterns
- **Classification accuracy:** Low confidence classifications may frustrate users. Mitigation: Always show reasoning, make modification easy
- **File system operations:** Moving files could fail mid-operation. Mitigation: Recommend git commit before running, provide clear rollback guidance

### Dependencies

- Atomic Design Pattern feature must be complete (verified - 100% complete)
- atomic-design skill exists for React (verified)
- atomic-design-mobile skill exists for React Native (verified)
- Storybook compatibility with Vite 6.x, Next.js 15.x, Expo 52+ (per spec constraints)

### Performance Considerations

- Analysis must complete within 30 seconds for 100 components (per spec NFR)
- Refactoring execution must complete within 60 seconds (per spec NFR)
- Consider batch processing for very large codebases

### Security Considerations

- All operations local; no data transmitted externally
- Only modifies files that user explicitly approves
- File operations use existing Claude Code tools with standard permissions

---

## Progress Tracking

**Overall Progress:** 100% (28/28 tasks complete)

| Feature | Tasks | Complete | Progress |
|---------|-------|----------|----------|
| 1. React Command Infrastructure | 4 | 4 | 100% |
| 2. Code Analysis | 4 | 4 | 100% |
| 3. Plan Approval Workflow | 5 | 5 | 100% |
| 4. Refactoring Execution | 4 | 4 | 100% |
| 5. Test and Story Handling | 3 | 3 | 100% |
| 6. Post-Refactoring Verification | 4 | 4 | 100% |
| 7. React Native Command | 5 | 5 | 100% |
