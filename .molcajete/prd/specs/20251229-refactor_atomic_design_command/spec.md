# Refactor Atomic Design Command - Specification

**Created:** 2025-12-29
**Last Updated:** 2025-12-29
**Status:** Draft

## Overview

### Feature Description

This feature implements a `refactor-atomic-design` command for each JavaScript tech-stack plugin (React and React Native) that enables developers to convert existing flat component structures into the Atomic Design pattern. The command provides a guided, safe refactoring workflow that analyzes the current codebase, generates a migration plan, and executes the refactoring with user approval.

The command creates a migration path for existing projects to adopt the Atomic Design pattern - the same five-level hierarchy (Atoms, Molecules, Organisms, Templates, Pages) that the init commands already establish for new projects. This fills a gap in the tech-stack plugins: new projects get organized structure automatically, but existing projects have no tooling support for migration.

### Strategic Alignment

**Product Mission:** This feature directly supports the mission of providing "consistency, quality, and reliability" in AI-assisted development. By enabling migration of existing projects to Atomic Design, we ensure that all Molcajete.ai React and React Native projects - whether new or legacy - can benefit from organized component hierarchies and consistent patterns.

**User Value:** Developers with existing flat component structures can refactor to Atomic Design in under 10 minutes rather than hours of manual work. The command handles the tedious parts (file moves, import updates, barrel exports, Storybook stories) while keeping the developer in control through an approval workflow.

**Roadmap Priority:** This falls under "Improve Existing Plugins" in the Now (1-3 months) category. The recently completed Atomic Design Pattern feature (see `.molcajete/prd/specs/20251229-atomic_design_pattern/spec.md`) establishes the pattern; this command extends its value to existing projects.

### Requirements Reference

See `.molcajete/prd/specs/20251229-refactor_atomic_design_command/requirements.md` for detailed user stories, functional requirements, and acceptance criteria.

---

## Requirements Summary

### Functional Requirements

1. **Command Registration**
   - `/react:refactor-atomic-design` for React (Vite SPA and Next.js)
   - `/react-native:refactor-atomic-design` for React Native (Expo)

2. **Directory Structure Setup**
   - Create atomic design folder structure if missing
   - Create `.gitkeep` files in empty directories
   - Create barrel export `index.ts` files at each level

3. **Component Analysis**
   - Scan component directories for existing components
   - Analyze component structure, imports, dependencies, state usage
   - Classify components into atomic levels using skill classification criteria
   - Detect existing tests and Storybook stories

4. **Plan Generation and Approval**
   - Generate refactoring plan showing source/destination paths
   - Display plan to user for review
   - Allow approve, modify classifications, or cancel
   - Support partial approval (refactor some, skip others)

5. **Refactoring Execution**
   - Move component files to correct atomic directories
   - Update all import statements across the codebase
   - Create/update barrel exports at each level
   - Create or update component tests
   - Generate Storybook stories for Atoms, Molecules, Organisms

6. **Post-Refactoring Verification**
   - Run type-check to verify imports are correct
   - Run linter to catch formatting issues
   - Run existing tests to verify functionality

### Non-Functional Requirements

- **Performance:** Analysis completes within 30 seconds for up to 100 components
- **Security:** All operations local; no data transmission; only modifies approved files
- **Usability:** Clear output, descriptive errors, readable refactoring plan
- **Reliability:** Idempotent; atomic operations; rollback guidance if errors occur

### Constraints

- Must integrate with existing tech-stack plugin architecture
- Must use existing atomic-design and atomic-design-mobile skills for classification
- Must work with Vite (React SPA), Next.js (React SSR), and Expo (React Native)
- Must maintain compatibility with TypeScript strict mode
- Single developer implementation; vertical feature approach

### Out of Scope

- Cross-Tech-Stack Migration (React to React Native)
- Design System Migration (design tokens, styling)
- Breaking Change Detection
- Multi-Repository Support
- Custom Atomic Levels (standard five-level hierarchy only)
- Visual Component Preview

---

## Data Models

### RefactoringPlan

The refactoring plan data structure used for plan generation and user review.

```typescript
interface RefactoringPlan {
  /** Version of the plan schema */
  version: '1.0';

  /** Timestamp when plan was generated */
  generatedAt: string; // ISO 8601

  /** Project information */
  project: {
    name: string;
    framework: 'vite' | 'nextjs' | 'expo';
    componentDirectory: string; // e.g., 'src/components' or 'components'
  };

  /** Components to be refactored */
  components: ComponentMigration[];

  /** Summary statistics */
  summary: {
    totalComponents: number;
    byLevel: {
      atoms: number;
      molecules: number;
      organisms: number;
      templates: number;
      pages: number;
      skipped: number;
    };
    importsToUpdate: number;
    storiestoCreate: number;
  };

  /** Warnings and conflicts detected */
  warnings: Warning[];
}

interface ComponentMigration {
  /** Component name (e.g., 'Button') */
  name: string;

  /** Current file path relative to project root */
  sourcePath: string;

  /** Proposed destination path */
  destinationPath: string;

  /** Classified atomic level */
  level: 'atom' | 'molecule' | 'organism' | 'template' | 'page' | 'skip';

  /** Classification confidence */
  confidence: 'high' | 'medium' | 'low';

  /** Reasoning for classification */
  classificationReason: string;

  /** Files that will be affected */
  affectedFiles: AffectedFile[];

  /** Whether component already has tests */
  hasTests: boolean;

  /** Test file path if exists */
  testPath?: string;

  /** Whether component already has Storybook story */
  hasStory: boolean;

  /** Story file path if exists */
  storyPath?: string;

  /** User decision (set during approval) */
  userDecision?: 'approve' | 'modify' | 'skip';

  /** Modified level if user changes classification */
  modifiedLevel?: 'atom' | 'molecule' | 'organism' | 'template' | 'page';
}

interface AffectedFile {
  /** File path that imports this component */
  filePath: string;

  /** Number of import statements to update */
  importCount: number;
}

interface Warning {
  /** Warning type */
  type: 'circular-dependency' | 'naming-conflict' | 'non-standard-location' | 'ambiguous-classification';

  /** Affected component(s) */
  components: string[];

  /** Warning message */
  message: string;

  /** Suggested resolution */
  suggestion: string;
}
```

### Classification Criteria

The rules for automatic component classification, derived from atomic-design skill.

```typescript
interface ClassificationCriteria {
  atom: {
    /** Component has no custom component imports */
    noCustomImports: boolean;
    /** Component has no useState/useEffect with business logic */
    noBusinessState: boolean;
    /** Component is stateless or only UI state */
    statelessOrUIState: boolean;
    /** Single element or simple composition */
    simpleStructure: boolean;
  };

  molecule: {
    /** Imports 2+ atom-level components */
    importsMultipleAtoms: boolean;
    /** Has single functional purpose */
    singlePurpose: boolean;
    /** Minimal internal state */
    minimalState: boolean;
    /** No data fetching (useQuery, fetch, etc.) */
    noDataFetching: boolean;
    /** No global state connection (useStore, useContext, etc.) */
    noGlobalState: boolean;
  };

  organism: {
    /** Larger interface section */
    largerSection: boolean;
    /** May have business logic */
    hasBusiness: boolean;
    /** May connect to stores */
    usesStores: boolean;
    /** Relatively standalone */
    standalone: boolean;
  };

  template: {
    /** Accepts children prop */
    acceptsChildren: boolean;
    /** Named with "Layout" suffix */
    hasLayoutSuffix: boolean;
    /** No real data */
    noRealData: boolean;
    /** Handles layout concerns */
    handlesLayout: boolean;
  };

  page: {
    /** Named with "Page" suffix (Vite) or in app/ directory (Next.js/Expo) */
    pageLocation: boolean;
    /** Connects to data sources */
    hasDataFetching: boolean;
    /** Uses template components */
    usesTemplates: boolean;
  };
}
```

---

## API Contracts

### Command Interface

This feature does not expose external APIs. Commands are invoked through Claude Code CLI.

#### React Command

**Command Name:** `/react:refactor-atomic-design`

**Description:** Refactor existing React project to Atomic Design component structure.

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `--target` | string | No | Specific directory or component to refactor (default: entire components directory) |
| `--dry-run` | boolean | No | Show plan without executing (default: false, plan approval serves as dry-run) |
| `--skip-stories` | boolean | No | Skip Storybook story generation (default: false) |
| `--skip-tests` | boolean | No | Skip test file updates (default: false) |

**Agent Invocation:** Uses `code-analyzer` agent with `atomic-design` skill reference.

#### React Native Command

**Command Name:** `/react-native:refactor-atomic-design`

**Description:** Refactor existing React Native (Expo) project to Atomic Design component structure.

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `--target` | string | No | Specific directory or component to refactor (default: entire components directory) |
| `--dry-run` | boolean | No | Show plan without executing |
| `--skip-stories` | boolean | No | Skip Storybook story generation |
| `--skip-tests` | boolean | No | Skip test file updates |

**Agent Invocation:** Uses `code-analyzer` agent with `atomic-design-mobile` skill reference.

---

## User Interface

### Command Flow

The command follows a multi-phase interactive workflow.

#### Phase 1: Initialization

```
/react:refactor-atomic-design

Analyzing project structure...

Project: my-react-app
Framework: Vite (React SPA)
Component Directory: src/components/

Found 24 components in flat structure.
```

#### Phase 2: Analysis Progress

```
Analyzing components...

[============================] 24/24 components

Classifying components...
- Button -> Atom (high confidence)
- Input -> Atom (high confidence)
- FormField -> Molecule (high confidence)
- SearchForm -> Molecule (medium confidence)
- Header -> Organism (high confidence)
- LoginForm -> Organism (high confidence)
- MainLayout -> Template (high confidence)
- DashboardLayout -> Template (high confidence)
- HomePage -> Page (high confidence)

Analysis complete.
```

#### Phase 3: Plan Presentation

```
=== REFACTORING PLAN ===

Summary:
- Components to refactor: 24
- Atoms: 8
- Molecules: 6
- Organisms: 5
- Templates: 3
- Pages: 2
- Imports to update: 47
- Stories to create: 19

ATOMS (8 components):
[ ] Button: src/components/Button/ -> src/components/atoms/Button/
    Confidence: high
    Reason: Single element, no custom imports, stateless
    Imports to update: 12
    Will create: Button.stories.tsx

[ ] Input: src/components/Input/ -> src/components/atoms/Input/
    Confidence: high
    Reason: Single element, no custom imports, stateless
    Imports to update: 8
    Will create: Input.stories.tsx

... (remaining components)

WARNINGS:
[!] SearchForm has circular dependency with FilterPanel
    Suggestion: Consider extracting shared logic to a hook

=== OPTIONS ===
1. Approve all and execute
2. Review and modify classifications
3. Select specific components
4. Cancel

Enter choice (1-4):
```

#### Phase 4: User Interaction

**Option 1 - Approve All:**
```
Executing refactoring plan...

Moving components:
[x] Button -> src/components/atoms/Button/
[x] Input -> src/components/atoms/Input/
...

Updating imports:
[x] Updated 12 imports in src/pages/HomePage.tsx
[x] Updated 8 imports in src/App.tsx
...

Creating barrel exports:
[x] Created src/components/atoms/index.ts
[x] Created src/components/molecules/index.ts
[x] Created src/components/organisms/index.ts
[x] Created src/components/templates/index.ts
[x] Updated src/components/index.ts

Generating Storybook stories:
[x] Created Button.stories.tsx
[x] Created Input.stories.tsx
...

Refactoring complete!
```

**Option 2 - Modify Classifications:**
```
Enter component name to modify (or 'done' to finish): SearchForm

Current classification: Molecule
Options:
1. Atom
2. Molecule (current)
3. Organism
4. Template
5. Skip (exclude from refactoring)

Enter choice (1-5): 3

SearchForm reclassified as Organism.

Enter component name to modify (or 'done' to finish): done
```

**Option 3 - Select Specific:**
```
Select components to include (comma-separated, or 'all'):
Button, Input, FormField, Header

Selected 4 components for refactoring.
Proceeding with selected components only.
```

#### Phase 5: Verification

```
Running verification...

Type-check: PASSED
Lint: PASSED (2 auto-fixed)
Tests: PASSED (24/24)

=== REFACTORING COMPLETE ===

Files changed: 47
Components moved: 24
Stories created: 19
Barrel exports updated: 5

Next steps:
1. Run `npm run storybook` to verify stories
2. Review the changes in your git diff
3. Commit when satisfied

To undo: git checkout -- src/components/
```

---

## Integration Points

### Tech-Stack Plugin Integration

#### Files to Create

| File | Path | Purpose |
|------|------|---------|
| refactor-atomic-design.md | `/tech-stacks/js/react/commands/refactor-atomic-design.md` | React command definition |
| refactor-atomic-design.md | `/tech-stacks/js/react-native/commands/refactor-atomic-design.md` | React Native command definition |
| code-analyzer.md | `/tech-stacks/js/react/agents/code-analyzer.md` | Component analysis agent for React |
| code-analyzer.md | `/tech-stacks/js/react-native/agents/code-analyzer.md` | Component analysis agent for React Native |

#### Files to Modify

| File | Changes |
|------|---------|
| `/tech-stacks/js/react/PLUGIN.md` | Add refactor-atomic-design command to command list |
| `/tech-stacks/js/react-native/PLUGIN.md` | Add refactor-atomic-design command to command list |

### Agent Dependencies

The command relies on a new `code-analyzer` agent that:

1. **Scans directories** - Uses Glob tool to find component files
2. **Analyzes imports** - Uses Grep tool to find import statements
3. **Reads component code** - Uses Read tool to analyze structure
4. **Classifies components** - References atomic-design skill for rules
5. **Generates plan** - Structures analysis into RefactoringPlan
6. **Executes changes** - Uses Write/Edit tools for file operations
7. **Runs verification** - Uses Bash tool for type-check, lint, test

### Skill Dependencies

- **atomic-design** skill: Classification rules, barrel export patterns, naming conventions (React)
- **atomic-design-mobile** skill: Mobile-specific classification, accessibility requirements (React Native)

### External Dependencies

None. All functionality is local to the project.

---

## Acceptance Criteria

### Functional Acceptance

- [ ] Command `/react:refactor-atomic-design` is available and documented
- [ ] Command `/react-native:refactor-atomic-design` is available and documented
- [ ] Command creates missing atomic design folders with `.gitkeep` files
- [ ] Command creates barrel export `index.ts` files at each level
- [ ] Command scans existing component directories
- [ ] Command classifies components using atomic-design skill criteria
- [ ] Command generates readable refactoring plan
- [ ] User can approve, modify, or cancel the plan
- [ ] User can select specific components for partial refactoring
- [ ] Refactoring moves component files to correct atomic directories
- [ ] Refactoring updates all import statements across the codebase
- [ ] Refactoring creates/updates barrel exports
- [ ] Refactoring generates Storybook stories for Atoms, Molecules, Organisms
- [ ] Post-refactoring verification runs type-check, lint, and tests
- [ ] Previously refactored components are detected and skipped
- [ ] Command can be run multiple times without errors (idempotent)

### Non-Functional Acceptance

- [ ] Analysis completes within 30 seconds for 100 components
- [ ] Refactoring execution completes within 60 seconds
- [ ] Clear error messages with actionable guidance
- [ ] Works with TypeScript strict mode
- [ ] Compatible with Vite 6.x, Next.js 15.x, and Expo 52+
- [ ] All changes are logged for review

### Business Acceptance

- [ ] Developers can refactor existing projects to Atomic Design in under 10 minutes
- [ ] Refactored projects pass type-check and lint without errors
- [ ] All existing tests continue to pass after refactoring
- [ ] New Storybook stories are generated and functional
- [ ] Reduced friction for adopting Atomic Design pattern in existing projects

---

## Verification

### Test Scenarios

#### Scenario 1: Full Refactoring - React Vite SPA

**Given:** Developer has existing Vite React project with flat component structure
```
src/components/
  Button/
    Button.tsx
    index.ts
  Input/
    Input.tsx
    index.ts
  FormField/
    FormField.tsx
    index.ts
  Header/
    Header.tsx
    index.ts
  LoginForm/
    LoginForm.tsx
    index.ts
  MainLayout/
    MainLayout.tsx
    index.ts
```

**When:** Developer runs `/react:refactor-atomic-design` and approves the plan

**Then:**
- Directory structure becomes:
  ```
  src/components/
    atoms/
      Button/
        Button.tsx
        Button.stories.tsx
        index.ts
      Input/
        Input.tsx
        Input.stories.tsx
        index.ts
      index.ts
    molecules/
      FormField/
        FormField.tsx
        FormField.stories.tsx
        index.ts
      index.ts
    organisms/
      Header/
        Header.tsx
        Header.stories.tsx
        index.ts
      LoginForm/
        LoginForm.tsx
        LoginForm.stories.tsx
        index.ts
      index.ts
    templates/
      MainLayout/
        MainLayout.tsx
        index.ts
      index.ts
    index.ts
  ```
- All import statements updated (e.g., `from '@/components/Button'` becomes `from '@/components/atoms'`)
- Type-check passes
- Tests pass

#### Scenario 2: Full Refactoring - React Native Expo

**Given:** Developer has existing Expo project with flat component structure
```
components/
  Button/
    Button.tsx
    index.ts
  Input/
    Input.tsx
    index.ts
  SearchBar/
    SearchBar.tsx
    index.ts
  Header/
    Header.tsx
    index.ts
  ScreenLayout/
    ScreenLayout.tsx
    index.ts
```

**When:** Developer runs `/react-native:refactor-atomic-design` and approves the plan

**Then:**
- Directory structure includes atomic hierarchy under `components/` (no `src/` prefix)
- Stories use React Native Storybook format with on-device controls
- Accessibility props verified in moved components
- All imports updated to use `@/components/atoms`, etc.

#### Scenario 3: Partial Refactoring

**Given:** Developer has 20 components but only wants to refactor 5

**When:** Developer runs command and selects "Select specific components"

**Then:**
- Only selected components are moved
- Unselected components remain in original location
- Imports for selected components are updated
- Barrel exports only include moved components

#### Scenario 4: Classification Override

**Given:** Component `SearchForm` is classified as Molecule but developer thinks it's an Organism

**When:** Developer modifies classification during approval

**Then:**
- `SearchForm` is moved to `organisms/` instead of `molecules/`
- Story title uses `Organisms/SearchForm`
- Barrel exports updated accordingly

#### Scenario 5: Incremental Refactoring

**Given:** Project was partially refactored previously (some components in atomic directories)

**When:** Developer runs command again

**Then:**
- Previously refactored components are detected and skipped
- Only components in flat structure are analyzed
- No duplicate moves or import updates

#### Scenario 6: Circular Dependency Warning

**Given:** ComponentA imports ComponentB and ComponentB imports ComponentA

**When:** Command analyzes the codebase

**Then:**
- Warning is displayed with affected components
- Suggestion to extract shared logic is provided
- User can still proceed with refactoring

#### Scenario 7: Next.js Project

**Given:** Developer has Next.js project with App Router

**When:** Developer runs `/react:refactor-atomic-design`

**Then:**
- Command detects Next.js framework
- Templates are created in `src/components/templates/`
- Pages remain in `src/app/` (not moved, Next.js convention)
- Storybook uses `@storybook/nextjs` configuration

#### Scenario 8: Project Without Storybook

**Given:** Developer has project without Storybook configured

**When:** Command runs with default options

**Then:**
- Command warns that Storybook is not set up
- Offers to skip story generation or set up Storybook
- If skip selected, refactoring proceeds without stories

### Edge Case Testing

- [ ] Empty component directory - graceful handling with message
- [ ] Component with no default export - warning and skip option
- [ ] Component in non-standard location (outside components/) - prompt for confirmation
- [ ] Very large project (100+ components) - batch processing with progress
- [ ] Component naming conflicts (two Button components) - warning and resolution
- [ ] TypeScript errors in existing code - continue with warnings

### Verification Commands

After refactoring, these commands should pass:

```bash
# Type checking
npm run type-check

# Linting
npm run lint

# Unit tests
npm test

# Storybook build (if applicable)
npm run build-storybook
```

---

## Implementation Notes

### Feature 1 Implementation (2025-12-29)

**Files Created:**
- `/tech-stacks/js/react/commands/refactor-atomic-design.md` - Command definition with 6-phase workflow
- `/tech-stacks/js/react/agents/code-analyzer.md` - Agent for component analysis and classification

**Files Modified:**
- `/tech-stacks/js/react/PLUGIN.md` - Added Refactoring section with command and code-analyzer agent

**Key Decisions:**
1. Combined task 1.3 (atomic directory creation) into the command definition Phase 1 rather than a separate implementation
2. Included full RefactoringPlan TypeScript interface in agent definition for clarity
3. Agent references atomic-design skill for classification criteria consistency
4. Added confidence scoring (high/medium/low) to help users identify components needing review
5. Command supports both Vite and Next.js projects with framework auto-detection

**Deviations from Spec:**
- None

### Technical Decisions

1. **Agent-based implementation** - Create dedicated `code-analyzer` agent rather than extending component-builder. The analysis workflow is distinct from component creation and benefits from separation.

2. **Plan-first approach** - Generate complete plan before any file operations. This enables dry-run functionality, user review, and rollback awareness.

3. **Classification confidence levels** - High/Medium/Low confidence helps users identify components that may need manual review. Low confidence triggers during approval phase.

4. **Preserve test files** - Tests are updated (imports fixed) but never deleted. If tests exist, they're moved alongside the component.

5. **Stories for lower levels only** - Following atomic-design skill, only Atoms, Molecules, and Organisms get Storybook stories. Templates and Pages are excluded.

6. **Barrel export strategy** - Use named exports with type re-exports. Support tree-shaking through explicit exports rather than star exports at component level.

### Implementation Phases

**Phase 1: Command and Directory Setup**
1. Create command definition files
2. Implement atomic directory creation logic
3. Implement barrel export file creation

**Phase 2: Code Analysis Agent**
4. Create code-analyzer agent definition
5. Implement component scanning (Glob patterns)
6. Implement import analysis (Grep patterns)
7. Implement classification logic (rules from atomic-design skill)

**Phase 3: Plan Generation and Approval**
8. Implement RefactoringPlan data structure
9. Implement plan display formatting
10. Implement user interaction (approve/modify/cancel)

**Phase 4: Refactoring Execution**
11. Implement file moving
12. Implement import statement updates
13. Implement barrel export updates

**Phase 5: Test and Story Updates**
14. Implement test file handling
15. Implement Storybook story generation
16. Implement post-refactoring verification

**Phase 6: Documentation**
17. Update React PLUGIN.md
18. Update React Native PLUGIN.md
19. Add usage examples

### Feature 2 Implementation (2025-12-29)

**Files Modified:**
- `/tech-stacks/js/react/agents/code-analyzer.md` - Extended with detailed workflow documentation

**Sections Added to code-analyzer.md:**

1. **Component Scanning Workflow**
   - Framework detection (Vite vs Next.js via config file presence)
   - Detailed Glob patterns for PascalCase .tsx files
   - Exclusion patterns for tests, stories, index files, atomic directories
   - Edge case handling table
   - Scanning output structure

2. **Import Analysis Workflow**
   - Grep patterns for named, default, and type imports
   - Combined pattern for efficiency
   - Path alias detection (@/, ~/, src/)
   - Import update planning with line numbers
   - Update rules for transforming imports

3. **Classification Algorithm**
   - 5-step classification order (Template→Page→Atom→Molecule→Organism)
   - Scoring-based classification with pseudocode
   - Confidence scoring rules (All=High, 75%=Medium, 50%=Low)
   - Edge case resolution table
   - Classification reason generation
   - Classification output structure

4. **Circular Dependency Detection**
   - Import graph data structure (Map<string, Set<string>>)
   - DFS cycle detection algorithm with pseudocode
   - Warning generation for detected cycles
   - Common patterns table with resolutions
   - Context-aware suggestion templates
   - Integration with analysis workflow
   - Output format for warnings

**Key Decisions:**
1. Classification order prioritizes specificity (Template/Page naming is more distinctive than dependency analysis)
2. Scoring-based classification allows for nuanced confidence levels
3. DFS algorithm handles both direct cycles (A↔B) and longer chains
4. Suggestions are pattern-specific to help developers resolve issues

**Deviations from Spec:**
- None

**Technical Debt:**
- Classification heuristics may need tuning based on real-world testing
- No automated testing of classification accuracy yet

### Feature 3 Implementation (2025-12-29)

**Files Modified:**
- `/tech-stacks/js/react/agents/code-analyzer.md` - Added User Approval Workflows section

**Sections Added to code-analyzer.md:**

1. **User Approval Workflows** (new section after Plan Display Format)
   - Approve All Workflow (Option 1)
   - Modify Classifications Workflow (Option 2)
   - Partial Selection Workflow (Option 3)
   - Cancel Workflow (Option 4)

2. **Approve All Workflow**
   - Confirmation prompt with action summary
   - userDecision = 'approve' for all components
   - Transition to Phase 5 execution
   - Progress display format

3. **Modify Classifications Workflow**
   - Interactive modification loop
   - Component name input with validation
   - Level selection (1-5) including Skip option
   - Case-insensitive matching
   - Persistence within session

4. **Partial Selection Workflow**
   - Display of all available components grouped by level
   - Comma-separated input parsing
   - Level shortcuts (all-atoms, all-molecules, etc.)
   - high-confidence shortcut
   - Filtered summary display
   - Confirmation before execution

**Key Decisions:**
1. Tasks 3.1 and 3.2 were already implemented during Feature 2 - marked as complete
2. Added selection shortcuts for productivity (all-atoms, high-confidence, etc.)
3. Modification workflow uses simple selection rather than typing level names
4. Partial selection supports both individual components and level-based selection
5. All workflows use AskUserQuestion tool for consistent interaction patterns

**Deviations from Spec:**
- None

**Technical Debt:**
- None identified

### Feature 4 Implementation (2025-12-29)

**Files Modified:**
- `/tech-stacks/js/react/agents/code-analyzer.md` - Added detailed execution workflows

**Sections Added to code-analyzer.md:**

1. **File Moving Workflow**
   - Directory-based moving strategy (move entire component directories)
   - Associated file detection patterns for tests, stories, styles
   - File copy sequence using Write tool
   - Cleanup strategy (defer deletion until verification passes)
   - Error handling for missing files and permission issues

2. **Import Statement Update Workflow**
   - Path transformation rules for all import types
   - Direct imports, relative imports, index imports
   - Edit tool usage pattern with old_string/new_string
   - Path alias resolution from tsconfig.json
   - Edge case handling: dynamic imports, re-exports, type imports, namespace imports
   - Multi-line import handling

3. **Barrel Export Update Workflow**
   - Level barrel export pattern (atoms/index.ts, molecules/index.ts, etc.)
   - Main barrel export pattern (components/index.ts)
   - Update vs create strategy
   - Type export detection and separation
   - Alphabetical ordering for consistency
   - Duplicate prevention logic

4. **Incremental Refactoring Detection**
   - Detection logic during scanning phase
   - Exclusion patterns for atomic directories
   - Reporting format for already-refactored components
   - Idempotency guarantees

**Key Decisions:**
1. Move entire directories rather than individual files to preserve component structure
2. Defer source file cleanup until verification passes for safety
3. Use Edit tool for import updates to preserve file formatting
4. Prefer barrel imports over direct component imports for cleaner import statements
5. Separate type exports from value exports in barrel files
6. Alphabetical ordering in barrel exports for consistency

**Deviations from Spec:**
- None

**Technical Debt:**
- Cleanup of source files after move is documented but marked as optional (user can choose)
- Dynamic import handling is documented but may need real-world testing

### Feature 5 Implementation (2025-12-29)

**Files Modified:**
- `/tech-stacks/js/react/agents/code-analyzer.md` - Added test and story handling workflows

**Sections Added to code-analyzer.md:**

1. **Test File Handling Workflow**
   - Test file detection patterns (.test.tsx, .spec.tsx, __tests__/)
   - Test file moving strategy (copy with component directory)
   - Test import update rules (relative unchanged, absolute updated)
   - Preservation guarantees (never delete, never modify logic)
   - Error handling for unresolvable imports

2. **Storybook Story Generation Workflow**
   - Story generation criteria (atoms, molecules, organisms only)
   - Skip conditions (existing, template/page, --skip-stories, no Storybook)
   - Story templates for each atomic level (Atoms/, Molecules/, Organisms/)
   - Story title hierarchy for Storybook navigation
   - Prop analysis for generating meaningful args and argTypes
   - Story count tracking for summary

3. **Storybook Detection Workflow**
   - Detection patterns (.storybook/ directory, package.json dependencies)
   - Framework-specific detection (react-vite vs nextjs)
   - Warning display and user options (skip, setup, cancel)
   - --skip-stories flag handling
   - Existing story handling (move and update title)

**Key Decisions:**
1. Test files move with component directories to preserve relative imports
2. Stories use level-specific title hierarchy for Storybook navigation
3. Storybook detection checks both directory and package.json for reliability
4. Existing stories are moved and have titles updated rather than regenerated
5. Three user options when Storybook not detected: skip, setup, or cancel

**Deviations from Spec:**
- None

**Technical Debt:**
- Story argTypes generation from prop analysis is basic; may need enhancement for complex prop types
- Storybook setup option uses `npx storybook@latest init` which may need version pinning

### Feature 6 Implementation (2025-12-29)

**Files Modified:**
- `/tech-stacks/js/react/agents/code-analyzer.md` - Added post-refactoring verification workflows

**Sections Added to code-analyzer.md:**

1. **Post-Refactoring Verification** (overview section)
   - Phase 6: Verification description

2. **Type-Check Verification Workflow**
   - Command detection (npm run type-check vs tsc --noEmit)
   - Framework-specific commands (Vite, Next.js)
   - Output parsing with error pattern matching
   - Pass/fail status reporting
   - Error guidance table (TS2307, TS2305, TS2614, TS7016)
   - Recovery actions with AskUserQuestion prompts
   - Result tracking structure

3. **Lint Verification Workflow**
   - Command detection (Biome vs ESLint)
   - Auto-fix execution and tracking
   - Output parsing for Biome and ESLint formats
   - Pass/fail status reporting with warning counts
   - Lint error guidance table

4. **Test Verification Workflow**
   - Command detection (Vitest vs Jest)
   - Framework-specific flags (--run, --passWithNoTests)
   - Output parsing for both test runners
   - Pass/fail count reporting
   - Test failure guidance with specific import update suggestions
   - Test file import analysis workflow

5. **Completion Summary and Next Steps**
   - Summary display format with all metrics
   - Next steps section (git diff, storybook, manual verification, commit)
   - Undo instructions with git checkout command
   - CompletionSummary data structure
   - Partial success handling for failed verifications
   - Cleanup reminder for preserved source files
   - Storybook verification note
   - Commit message suggestion

**Key Decisions:**
1. Type-check prioritizes project-specific command (npm run type-check) over fallback (tsc --noEmit)
2. Lint runs with --fix flag by default to auto-correct formatting issues
3. Test verification adds --run flag to prevent watch mode
4. Recovery actions use AskUserQuestion for user choice (fix manually, continue, rollback)
5. Completion summary provides copy-ready commit message
6. Source file cleanup is optional and user-controlled (safety mode)

**Deviations from Spec:**
- None

**Technical Debt:**
- Output parsing patterns may need adjustment for different versions of Vitest/Jest/Biome/ESLint
- Commit message suggestion could be customized based on actual changes made

### Feature 7 Implementation (2025-12-29)

**Files Created:**
- `/tech-stacks/js/react-native/commands/refactor-atomic-design.md` - Command definition adapted for Expo projects
- `/tech-stacks/js/react-native/agents/code-analyzer.md` - Mobile-specific component analyzer agent

**Files Modified:**
- `/tech-stacks/js/react-native/PLUGIN.md` - Added Refactoring section with command and code-analyzer agent

**Key Decisions:**
1. No src/ prefix in scanning patterns - Expo projects use `components/` directly
2. Mobile classification criteria include touch target validation (44pt minimum)
3. Accessibility prop detection: accessibilityLabel, accessibilityRole, accessibilityState
4. Platform-specific code detection for Platform.OS, Platform.select patterns
5. React Native Storybook uses @storybook/react-native imports (not @storybook/react)
6. Storybook detection checks for @storybook/react-native in package.json
7. Templates are named "Screens" in mobile terminology (consistent with atomic-design-mobile skill)
8. App directory components (Expo Router) are excluded from refactoring

**Deviations from Spec:**
- None

**Technical Debt:**
- Mobile classification heuristics may need real-world testing and tuning
- Touch target size validation is documentation-based (not automated measurement)

### Known Limitations

- **No visual diff** - Changes are shown as file paths, not actual code diffs
- **No automatic rollback** - User must use git to revert; guidance provided
- **Limited CSS handling** - Style files are moved with components but not analyzed
- **No custom atomic levels** - Standard five-level hierarchy only

### Security Considerations

- All operations are local; no data transmitted externally
- Command only modifies files that user explicitly approves
- Recommendation to commit/stash before running is displayed
- File operations use existing Write/Edit tools with standard permissions

### Future Enhancements

- **Batch processing UI** - For projects with 100+ components
- **Classification learning** - Remember user overrides for future runs
- **CSS/Style migration** - Analyze and move style files intelligently
- **Component API analysis** - Detect breaking changes in moved components
- **Visual diff preview** - Show actual code changes before execution

---

## Implementation Summary

**Status:** Complete

**What Was Built:**
- React `refactor-atomic-design` command with 6-phase workflow
- React Native `refactor-atomic-design` command adapted for Expo projects
- `code-analyzer` agent for React with complete documentation for:
  - Component scanning and framework detection
  - Import analysis and path alias resolution
  - Classification algorithm with confidence scoring
  - Circular dependency detection
  - User approval workflows (approve all, modify, partial, cancel)
  - File moving with associated file detection
  - Import statement updates with edge case handling
  - Barrel export creation and updates
  - Test file handling with preservation guarantees
  - Storybook story generation and detection
  - Incremental refactoring detection (idempotency)
  - Post-refactoring verification (type-check, lint, tests)
  - Completion summary with next steps and undo guidance
- `code-analyzer` agent for React Native with mobile-specific features:
  - Expo project structure (no src/ prefix)
  - Mobile classification criteria (touch targets, accessibility)
  - @storybook/react-native story generation
  - Platform-specific code detection

**Key Decisions:**
1. Agent-based implementation with dedicated code-analyzer agents for each platform
2. Plan-first approach with user approval before execution
3. Directory-based moving preserves component structure
4. Verification runs type-check, lint, tests in sequence
5. User controls cleanup of source files (safety mode)
6. Mobile-specific classification criteria for React Native

**Test Results:**
- Documentation complete, ready for real-world testing
- Classification heuristics may need tuning based on usage

**Next Steps:**
- Real-world testing with actual React and React Native projects
- Tune classification heuristics based on feedback
- Consider automated touch target validation for mobile
