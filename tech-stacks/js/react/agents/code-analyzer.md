---
description: Analyzes React component structure and classifies components for Atomic Design refactoring
capabilities: ["component-scanning", "import-analysis", "atomic-classification", "refactoring-plans", "import-updates", "barrel-exports"]
tools: AskUserQuestion, Read, Write, Edit, Bash, Grep, Glob
---

# Code Analyzer Agent

Analyzes existing React component structures and generates refactoring plans for migration to Atomic Design pattern.

## Core Responsibilities

1. **Scan** - Find all component files in the project
2. **Analyze** - Read and understand component structure, imports, state usage
3. **Classify** - Assign atomic level based on criteria from atomic-design skill
4. **Plan** - Generate structured refactoring plan with affected files
5. **Execute** - Move files, update imports, create barrel exports, generate stories
6. **Verify** - Run type-check, lint, and tests to confirm successful refactoring

## Required Skills

MUST reference the **atomic-design** skill for:
- Five-level hierarchy (Atoms, Molecules, Organisms, Templates, Pages)
- Classification decision flowchart
- Classification checklists
- Storybook story templates
- Barrel export patterns

## Tool Usage Patterns

### Scanning Components

Use Glob to find component files in flat structure:

```
Glob pattern: src/components/**/*.tsx
Exclude: **/*.test.tsx, **/*.spec.tsx, **/*.stories.tsx
Exclude: atoms/**, molecules/**, organisms/**, templates/**
```

For Next.js, also identify pages in `src/app/` but DO NOT move them (Next.js convention).

## Component Scanning Workflow

Detailed workflow for finding and cataloging all components in a project.

### Framework Detection

Before scanning, detect the project framework to determine component directory structure:

1. **Check for Next.js:**
   ```
   Glob pattern: next.config.{ts,js,mjs}
   If found → Framework: nextjs
   Component directory: src/components/
   ```

2. **Check for Vite:**
   ```
   Glob pattern: vite.config.{ts,js}
   If found → Framework: vite
   Component directory: src/components/
   ```

3. **Framework not detected:**
   ```
   Default to Vite patterns
   Warn: "Could not detect framework, assuming Vite React SPA"
   ```

### Scanning Patterns

**Find all component files (PascalCase .tsx files):**
```
Glob pattern: src/components/**/[A-Z]*.tsx
```

**Exclusion patterns (apply all):**
```
Exclude: src/components/**/*.test.tsx
Exclude: src/components/**/*.spec.tsx
Exclude: src/components/**/*.stories.tsx
Exclude: src/components/**/index.tsx (barrel exports)
Exclude: src/components/atoms/**
Exclude: src/components/molecules/**
Exclude: src/components/organisms/**
Exclude: src/components/templates/**
```

### Edge Case Handling

| Scenario | Action |
|----------|--------|
| Components in subdirectories | Include - nested `*.tsx` files are valid components |
| Non-standard locations (outside components/) | Warn and prompt user for confirmation |
| Empty component directories | Skip with informational message |
| Component without default export | Warn and flag for review |
| Multiple components in single file | Analyze primary export only |

### Scanning Output

For each discovered component, record:
```typescript
{
  name: string;           // e.g., 'Button'
  sourcePath: string;     // e.g., 'src/components/Button/Button.tsx'
  directoryPath: string;  // e.g., 'src/components/Button/'
  hasIndex: boolean;      // Does directory have index.ts?
  hasTests: boolean;      // Does *.test.tsx or *.spec.tsx exist?
  hasStory: boolean;      // Does *.stories.tsx exist?
}

### Analyzing Imports

Use Grep to find import statements:

```
Grep pattern: import.*from.*['"].*ComponentName
Files: **/*.tsx, **/*.ts
```

Count affected files for each component to populate `affectedFiles` in RefactoringPlan.

## Import Analysis Workflow

Detailed workflow for finding all files that import each component and building the affectedFiles list.

### Finding All Import Statements

For each component, find all files that import it using these patterns:

**Named import pattern:**
```
Grep pattern: import\s*\{[^}]*ComponentName[^}]*\}\s*from
Files: **/*.tsx, **/*.ts
Exclude: node_modules/**
```

**Default import pattern:**
```
Grep pattern: import\s+ComponentName\s+from
Files: **/*.tsx, **/*.ts
Exclude: node_modules/**
```

**Type import pattern:**
```
Grep pattern: import\s+type\s*\{[^}]*ComponentName
Files: **/*.tsx, **/*.ts
Exclude: node_modules/**
```

**Combined pattern (for efficiency):**
```
Grep pattern: import\s+(?:type\s*)?\{?[^}]*ComponentName.*from\s*['"]
Files: **/*.tsx, **/*.ts
Exclude: node_modules/**
```

### Building AffectedFiles List

For each Grep match:

1. **Extract file path** from match result
2. **Count imports** - How many import statements reference the component
3. **Detect import style:**
   - Path alias: `@/components/ComponentName` or `~/components/ComponentName`
   - Relative path: `../ComponentName` or `./ComponentName`
   - Package-style: `components/ComponentName`
4. **Add to affectedFiles array:**

```typescript
{
  filePath: 'src/pages/HomePage.tsx',
  importCount: 2,  // Component and its type
  importStyle: 'alias' | 'relative' | 'package'
}
```

### Path Alias Detection

Common path alias patterns in React projects:

| Alias Pattern | Example | Config Location |
|--------------|---------|-----------------|
| `@/*` | `@/components/Button` | tsconfig.json paths |
| `~/` | `~/components/Button` | vite.config.ts resolve.alias |
| `src/` | `src/components/Button` | tsconfig.json baseUrl |

**Detection approach:**
1. Read tsconfig.json to find `paths` configuration
2. Read vite.config.ts or next.config.ts for resolve aliases
3. Map component paths to actual file locations

### Import Update Planning

For each affected file, record the update needed:

```typescript
{
  filePath: 'src/pages/HomePage.tsx',
  currentImport: "import { Button } from '@/components/Button'",
  newImport: "import { Button } from '@/components/atoms'",
  lineNumber: 3
}
```

**Update rules:**
- Direct component imports → level barrel import
- Relative paths → alias paths (if configured)
- Named imports preserved; only path changes
- Type imports preserved separately

### Reading Component Code

Use Read to analyze component structure. Check for:

1. **Custom component imports:**
   ```typescript
   // Look for imports from @/components or relative paths
   import { Button } from '@/components/Button';
   import { Input } from '../Input';
   ```

2. **State hooks:**
   ```typescript
   useState, useReducer
   ```

3. **Effects:**
   ```typescript
   useEffect, useLayoutEffect
   ```

4. **Data fetching:**
   ```typescript
   useQuery, useSWR, fetch, axios
   ```

5. **Store connections:**
   ```typescript
   useStore, useContext, useSelector
   ```

6. **Children prop:**
   ```typescript
   children: React.ReactNode
   ```

7. **Layout naming:**
   ```typescript
   // Component name ends with "Layout"
   MainLayout, DashboardLayout, AuthLayout
   ```

## Classification Logic

Apply atomic-design skill criteria to determine level.

## Classification Algorithm

Step-by-step algorithm for classifying components with confidence scoring.

### Classification Order

Evaluate levels in this order (most specific to least):

1. **Template** - Check first (Layout naming is highly distinctive)
2. **Page** - Check second (Page naming and location are distinctive)
3. **Atom** - Check third (no dependencies is a clear signal)
4. **Molecule** - Check fourth (imports multiple atoms)
5. **Organism** - Default fallback (complex components)

### Step-by-Step Classification

For each component, perform these checks:

**Step 1: Check for Template**
```
IF name ends with "Layout" AND accepts children: React.ReactNode
  → Level: Template, Confidence: High
ELSE IF accepts children: React.ReactNode AND no business logic
  → Level: Template, Confidence: Medium (may be Molecule wrapper)
```

**Step 2: Check for Page**
```
IF name ends with "Page"
  → Level: Page, Confidence: High
ELSE IF located in pages/ or app/ directory
  → Level: Page, Confidence: High
ELSE IF has useNavigate OR useRouter OR useSearchParams
  → Level: Page, Confidence: Medium
```

**Step 3: Check for Atom**
```
atomScore = 0
IF no custom component imports: atomScore += 1
IF no useState with business logic: atomScore += 1
IF no useEffect with side effects: atomScore += 1
IF no useQuery/useSWR/fetch: atomScore += 1

IF atomScore == 4
  → Level: Atom, Confidence: High
ELSE IF atomScore >= 3
  → Level: Atom, Confidence: Medium
```

**Step 4: Check for Molecule**
```
moleculeScore = 0
IF imports 2+ Atom-level components: moleculeScore += 1
IF single functional purpose: moleculeScore += 1
IF no global state (useStore, useContext): moleculeScore += 1
IF no data fetching: moleculeScore += 1
IF minimal internal state: moleculeScore += 1

IF moleculeScore >= 4
  → Level: Molecule, Confidence: High
ELSE IF moleculeScore >= 3
  → Level: Molecule, Confidence: Medium
```

**Step 5: Default to Organism**
```
IF reached this step without classification
  → Level: Organism, Confidence: Medium

IF has business logic OR connects to stores
  → Level: Organism, Confidence: High
```

### Confidence Scoring Rules

| Criteria Match | Confidence Level |
|----------------|------------------|
| All criteria for level satisfied | **High** |
| 75-99% of criteria satisfied | **Medium** |
| 50-74% of criteria satisfied | **Low** |
| Less than 50% | Flag for user review |

### Edge Case Handling

| Scenario | Resolution |
|----------|------------|
| Matches multiple levels equally | Assign lower level (Atom < Molecule < Organism), Medium confidence |
| No clear match for any level | Assign Organism, Low confidence, flag for review |
| Component imports higher-level components | Warn about hierarchy violation in warnings array |
| Dynamic imports only | Classify based on static analysis, note in classificationReason |
| Component with no props | Likely Atom, check for internal state |

### Building Classification Reason

Generate human-readable reason string:

```typescript
// High confidence Atom
"Single element, no custom imports, stateless"

// Medium confidence Molecule
"Combines Label + Input, but has minor internal state"

// Low confidence Organism
"Complex structure with unclear boundaries"
```

### Classification Output

For each component, produce:
```typescript
{
  level: 'atom' | 'molecule' | 'organism' | 'template' | 'page',
  confidence: 'high' | 'medium' | 'low',
  classificationReason: string,
  criteriaChecked: {
    // Which criteria were evaluated and their results
    noCustomImports: boolean,
    noBusinessState: boolean,
    // ... etc
  },
  warnings: string[]  // Any hierarchy violations or ambiguities
}
```

---

## Criteria Checklists

Apply atomic-design skill criteria to determine level:

### Atom Criteria Checklist

- [ ] No custom component imports (only libraries like react, clsx, etc.)
- [ ] No business state (only UI state like hover/focus)
- [ ] Single element or simple composition
- [ ] Stateless or controlled via props

**If all checked → Level: Atom, Confidence: High**

### Molecule Criteria Checklist

- [ ] Imports 2+ atom-level components
- [ ] Single functional purpose
- [ ] Minimal internal state
- [ ] No data fetching
- [ ] No global state connection

**If all checked → Level: Molecule, Confidence: High**

### Organism Criteria Checklist

- [ ] Larger interface section
- [ ] May have business logic
- [ ] May connect to stores
- [ ] Relatively standalone

**If 3+ checked → Level: Organism, Confidence: High**

### Template Criteria Checklist

- [ ] Accepts children prop
- [ ] Named with "Layout" suffix
- [ ] No real data
- [ ] Handles layout concerns

**If name ends with "Layout" and accepts children → Level: Template, Confidence: High**

### Page Criteria Checklist (Vite only)

- [ ] Named with "Page" suffix
- [ ] Connects to data sources
- [ ] Uses template components

**Note:** For Next.js, pages stay in `src/app/` (not moved)

## Confidence Scoring

| Scenario | Confidence |
|----------|------------|
| Component clearly matches one level's criteria | **High** |
| Component partially matches 2+ levels | **Medium** |
| Component has ambiguous characteristics | **Low** |

When confidence is **Low**, flag for user review during approval phase.

## Circular Dependency Detection

Workflow for detecting and reporting circular dependencies between components.

### Building the Import Graph

During import analysis, build a directed graph of component dependencies:

```typescript
// Map from component name to set of components it imports
type ImportGraph = Map<string, Set<string>>;

// Build during import analysis phase
const importGraph: ImportGraph = new Map();

// For each component, record which other project components it imports
importGraph.set('SearchForm', new Set(['Button', 'Input', 'FilterPanel']));
importGraph.set('FilterPanel', new Set(['Button', 'SearchForm'])); // Circular!
```

### Detection Algorithm

Use depth-first search to detect cycles:

```
function detectCycles(importGraph):
  visited = Set()
  recursionStack = Set()
  cycles = []

  for each component in importGraph:
    if component not in visited:
      detectCyclesDFS(component, visited, recursionStack, [], cycles)

  return cycles

function detectCyclesDFS(component, visited, stack, path, cycles):
  visited.add(component)
  stack.add(component)
  path.push(component)

  for each import in importGraph[component]:
    if import in stack:
      // Found a cycle - extract the cycle from path
      cycleStart = path.indexOf(import)
      cycle = path.slice(cycleStart)
      cycles.push(cycle)
    else if import not in visited:
      detectCyclesDFS(import, visited, stack, path, cycles)

  path.pop()
  stack.remove(component)
```

### Warning Generation

For each detected cycle, generate a Warning:

```typescript
{
  type: 'circular-dependency',
  components: ['SearchForm', 'FilterPanel'],  // All components in the cycle
  message: 'SearchForm and FilterPanel have a circular dependency',
  suggestion: 'Consider extracting shared logic to a custom hook or creating a shared types file'
}
```

### Common Circular Dependency Patterns

| Pattern | Description | Suggested Resolution |
|---------|-------------|---------------------|
| A ↔ B | Direct mutual import | Extract shared types to `types.ts` |
| Form ↔ FormField | Parent-child circular | Use composition with children prop |
| Component ↔ ComponentItem | List-item circular | Extract item interface to separate file |
| Modal ↔ ModalContent | Container-content | Pass content as children, not import |

### Suggestion Templates

Generate context-aware suggestions:

```typescript
// Two components with direct cycle
`${componentA} and ${componentB} import each other. Consider:
1. Extract shared types to a common types.ts file
2. Use React context to share state instead of imports
3. Pass one component as a prop/children to the other`

// Longer cycle (3+ components)
`Found dependency cycle: ${cycle.join(' → ')} → ${cycle[0]}. Consider:
1. Review the data flow between these components
2. Extract the shared dependency into a separate module
3. Use dependency injection (props/context) instead of direct imports`
```

### Integration with Analysis

Run circular dependency detection after import analysis completes:

1. Build import graph during import analysis
2. Run cycle detection algorithm
3. Add warnings to RefactoringPlan.warnings
4. Display warnings in plan output with suggestions
5. Allow user to proceed despite warnings (dependencies will still work after refactoring)

### Output Format

In the plan display:

```
WARNINGS:
[!] Circular dependency: SearchForm ↔ FilterPanel
    Components: SearchForm, FilterPanel
    Suggestion: Consider extracting shared logic to a custom hook

[!] Circular dependency: Modal → ModalHeader → ModalFooter → Modal
    Components: Modal, ModalHeader, ModalFooter
    Suggestion: Review component boundaries - these may belong in the same directory
```

## RefactoringPlan Data Structure

```typescript
interface RefactoringPlan {
  version: '1.0';
  generatedAt: string; // ISO 8601
  project: {
    name: string;
    framework: 'vite' | 'nextjs';
    componentDirectory: string;
  };
  components: ComponentMigration[];
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
    storiesToCreate: number;
  };
  warnings: Warning[];
}

interface ComponentMigration {
  name: string;
  sourcePath: string;
  destinationPath: string;
  level: 'atom' | 'molecule' | 'organism' | 'template' | 'page' | 'skip';
  confidence: 'high' | 'medium' | 'low';
  classificationReason: string;
  affectedFiles: AffectedFile[];
  hasTests: boolean;
  testPath?: string;
  hasStory: boolean;
  storyPath?: string;
  userDecision?: 'approve' | 'modify' | 'skip';
  modifiedLevel?: 'atom' | 'molecule' | 'organism' | 'template' | 'page';
}

interface AffectedFile {
  filePath: string;
  importCount: number;
}

interface Warning {
  type: 'circular-dependency' | 'naming-conflict' | 'non-standard-location' | 'ambiguous-classification';
  components: string[];
  message: string;
  suggestion: string;
}
```

## Plan Display Format

```
=== REFACTORING PLAN ===

Project: my-react-app
Framework: Vite (React SPA)
Generated: 2025-12-29T10:30:00Z

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

MOLECULES (6 components):
[ ] FormField: src/components/FormField/ -> src/components/molecules/FormField/
    Confidence: high
    Reason: Combines Label + Input, single purpose
    Imports to update: 5
    Will create: FormField.stories.tsx

[ ] SearchForm: src/components/SearchForm/ -> src/components/molecules/SearchForm/
    Confidence: medium ⚠️
    Reason: Combines atoms, but has some business logic
    Imports to update: 3
    Will create: SearchForm.stories.tsx

ORGANISMS (5 components):
...

TEMPLATES (3 components):
[ ] MainLayout: src/components/MainLayout/ -> src/components/templates/MainLayout/
    Confidence: high
    Reason: Named "Layout", accepts children, handles layout
    Imports to update: 4
    NO story (templates excluded)

WARNINGS:
[!] SearchForm has circular dependency with FilterPanel
    Suggestion: Consider extracting shared logic to a hook

[!] CardWidget has ambiguous classification (low confidence)
    Suggestion: Review manually - could be Molecule or Organism

=== OPTIONS ===
1. Approve all and execute
2. Review and modify classifications
3. Select specific components
4. Cancel

Enter choice (1-4):
```

## User Approval Workflows

Detailed workflows for each user approval option presented in the plan display.

### Approve All Workflow (Option 1)

When user selects "Approve all and execute":

1. **Confirm intent using AskUserQuestion:**
   - Question: "This will move X components, update Y imports, and create Z stories. Proceed?"
   - Options: ["Yes, execute refactoring", "No, go back to options"]

2. **If confirmed, set all component decisions:**
   ```typescript
   for (const component of plan.components) {
     component.userDecision = 'approve';
   }
   ```

3. **Transition to Phase 5: Refactoring Execution**
   - No further user input needed
   - Execute all moves, import updates, barrel exports, story generation

4. **Progress display during execution:**
   ```
   Executing refactoring plan...

   Moving components:
   [x] Button -> src/components/atoms/Button/
   [x] Input -> src/components/atoms/Input/
   [x] FormField -> src/components/molecules/FormField/
   ...

   Updating imports:
   [x] Updated 12 imports in src/pages/HomePage.tsx
   [x] Updated 8 imports in src/App.tsx
   ...
   ```

### Modify Classifications Workflow (Option 2)

When user selects "Review and modify classifications":

1. **Enter modification loop using AskUserQuestion:**
   - Question: "Enter component name to modify"
   - Options: [list of all component names, "Done - return to options"]

2. **Show current classification and level options:**
   - Question: "SearchForm is currently classified as Molecule (medium confidence). Select new level:"
   - Options: ["Atom", "Molecule (current)", "Organism", "Template", "Skip - exclude from refactoring"]

3. **Apply modification:**
   ```typescript
   component.userDecision = 'modify';
   component.modifiedLevel = selectedLevel; // e.g., 'organism'
   ```

4. **Confirm and continue:**
   ```
   SearchForm reclassified as Organism.
   ```
   Return to step 1 for next modification.

5. **When user selects 'Done':**
   - Display updated summary showing modifications
   - Return to main options menu

**Implementation Notes:**
- Component name matching is case-insensitive
- Modified components shown with indicator in plan display
- Modifications persist for the session
- User can modify same component multiple times

### Partial Selection Workflow (Option 3)

When user selects "Select specific components":

1. **Display available components grouped by level:**
   ```
   Available components (24 total):

   Atoms (8): Button, Input, Label, Icon, Badge, Avatar, Spinner, Tooltip
   Molecules (6): FormField, SearchForm, Card, Modal, Dropdown, Tabs
   Organisms (5): Header, Footer, Sidebar, LoginForm, UserProfile
   Templates (3): MainLayout, DashboardLayout, AuthLayout
   Pages (2): HomePage, DashboardPage
   ```

2. **Ask for selection using AskUserQuestion:**
   - Question: "Select components to refactor"
   - Options: Multi-select with all component names plus shortcuts
   - Shortcuts available: "all", "all-atoms", "all-molecules", "all-organisms", "all-templates", "high-confidence"

3. **Parse and validate selection:**
   ```typescript
   // Individual components
   selectedComponents = ["Button", "Input", "FormField", "Header"];

   // Or level selection
   if (selection.includes("all-atoms")) {
     selectedComponents.push(...atomComponents);
   }

   // Or confidence filter
   if (selection.includes("high-confidence")) {
     selectedComponents = components.filter(c => c.confidence === 'high');
   }
   ```

4. **Set decisions based on selection:**
   ```typescript
   for (const component of plan.components) {
     if (selectedComponents.includes(component.name)) {
       component.userDecision = 'approve';
     } else {
       component.userDecision = 'skip';
     }
   }
   ```

5. **Display filtered summary:**
   ```
   Selected 4 components for refactoring:
   - Button (atom) -> src/components/atoms/Button/
   - Input (atom) -> src/components/atoms/Input/
   - FormField (molecule) -> src/components/molecules/FormField/
   - Header (organism) -> src/components/organisms/Header/

   Imports to update: 12
   Stories to create: 4
   Skipped: 20 components (remain in original locations)
   ```

6. **Confirm and execute:**
   - Question: "Proceed with selected components?"
   - Options: ["Yes, execute", "No, modify selection", "Cancel"]

**Selection Shortcuts:**

| Shortcut | Description |
|----------|-------------|
| `all` | Select all components |
| `all-atoms` | Select all components classified as atoms |
| `all-molecules` | Select all molecules |
| `all-organisms` | Select all organisms |
| `all-templates` | Select all templates |
| `high-confidence` | Select only high confidence classifications |

**Validation:**
- Unknown component names trigger warning: "Component 'Xyz' not found. Did you mean 'XyzButton'?"
- Empty selection displays message and returns to options menu
- Confirmation required before execution

### Cancel Workflow (Option 4)

When user selects "Cancel":

1. **Confirm cancellation:**
   - Question: "Cancel refactoring? No changes will be made."
   - Options: ["Yes, cancel", "No, go back to options"]

2. **If confirmed:**
   ```
   Refactoring cancelled. No changes were made.

   To run again: /react:refactor-atomic-design
   ```

3. **Exit command**

## File Moving Workflow

Detailed workflow for moving component directories from flat structure to atomic directories.

### Moving Strategy

Move entire component directories rather than individual files. This preserves:
- Component structure (ComponentName.tsx, index.ts)
- Test files (__tests__/, *.test.tsx, *.spec.tsx)
- Story files (*.stories.tsx)
- Style files (*.css, *.module.css, *.styles.ts)
- Type files (*.types.ts)

### Associated File Detection

For each component, detect associated files using these patterns:

| File Type | Detection Patterns |
|-----------|-------------------|
| Main component | `{ComponentName}.tsx` |
| Barrel export | `index.ts` |
| Unit tests | `{ComponentName}.test.tsx`, `{ComponentName}.spec.tsx`, `__tests__/{ComponentName}.test.tsx` |
| Stories | `{ComponentName}.stories.tsx` |
| Styles | `{ComponentName}.css`, `{ComponentName}.module.css`, `{ComponentName}.styles.ts` |
| Types | `{ComponentName}.types.ts`, `types.ts` |

### File Copy Sequence

For each approved component migration:

1. **Create destination directory:**
   ```
   Write tool:
   - file_path: src/components/{level}/{ComponentName}/.gitkeep
   - content: (empty)
   ```

2. **Copy main component file:**
   ```
   Read source: src/components/{ComponentName}/{ComponentName}.tsx
   Write tool:
   - file_path: src/components/{level}/{ComponentName}/{ComponentName}.tsx
   - content: (read content)
   ```

3. **Copy index.ts:**
   ```
   Read source: src/components/{ComponentName}/index.ts
   Write tool:
   - file_path: src/components/{level}/{ComponentName}/index.ts
   - content: (read content)
   ```

4. **Copy associated files (tests, stories, styles):**
   - Apply same read/write pattern for each detected file
   - Preserve relative paths within component directory

5. **Track copied files for verification:**
   ```typescript
   copiedFiles.push({
     source: 'src/components/Button/Button.tsx',
     destination: 'src/components/atoms/Button/Button.tsx',
     verified: false
   });
   ```

### Cleanup Strategy

**Recommended approach:** Defer cleanup until verification passes

1. After all files copied, run verification (type-check, lint, tests)
2. If verification passes, report source files that can be removed:
   ```
   Source files to clean up:
   - src/components/Button/ (moved to src/components/atoms/Button/)
   - src/components/Input/ (moved to src/components/atoms/Input/)

   Run to remove: rm -rf src/components/Button src/components/Input
   Or use git: git clean -fd src/components/Button src/components/Input
   ```

3. If verification fails, source files remain as backup

**Alternative approach:** Leave source files for user to delete manually (safest)

### Error Handling

| Error | Action |
|-------|--------|
| Source file not found | Warn and skip, continue with other files |
| Destination already exists | Check if content matches; if different, warn and skip |
| Permission denied | Report error with file path, stop execution |
| Directory creation fails | Report error, suggest checking permissions |

---

## Import Statement Update Workflow

Detailed workflow for updating import statements across the codebase after moving components.

### Path Transformation Rules

**Rule 1: Direct component imports**
```typescript
// Before
import { Button } from '@/components/Button';
import { Button } from '~/components/Button';
import { Button } from 'src/components/Button';

// After (all transform to)
import { Button } from '@/components/atoms';
```

**Rule 2: Relative imports**
```typescript
// Before
import { Button } from '../Button';
import { Button } from './Button';
import { Button } from '../../components/Button';

// After
import { Button } from '@/components/atoms';
```

**Rule 3: Index imports**
```typescript
// Before
import { Button } from '@/components/Button/index';

// After
import { Button } from '@/components/atoms';
```

**Rule 4: Named imports preserved**
```typescript
// Before
import { Button, type ButtonProps } from '@/components/Button';

// After (names preserved, only path changes)
import { Button, type ButtonProps } from '@/components/atoms';
```

**Rule 5: Type-only imports**
```typescript
// Before
import type { ButtonProps } from '@/components/Button';

// After
import type { ButtonProps } from '@/components/atoms';
```

### Edit Tool Usage Pattern

For each affected file and import statement:

```
Edit tool:
- file_path: src/pages/HomePage.tsx
- old_string: import { Button } from '@/components/Button';
- new_string: import { Button } from '@/components/atoms';
```

**Multi-line import handling:**
```
Edit tool:
- file_path: src/pages/HomePage.tsx
- old_string: |
    import {
      Button,
      type ButtonProps,
    } from '@/components/Button';
- new_string: |
    import {
      Button,
      type ButtonProps,
    } from '@/components/atoms';
```

### Path Alias Resolution

1. **Read tsconfig.json for path aliases:**
   ```json
   {
     "compilerOptions": {
       "baseUrl": ".",
       "paths": {
         "@/*": ["./src/*"],
         "~/*": ["./src/*"]
       }
     }
   }
   ```

2. **Build alias map:**
   ```typescript
   const aliasMap = {
     '@/': 'src/',
     '~/': 'src/'
   };
   ```

3. **Apply transformations using configured aliases**

### Edge Case Handling

**Dynamic imports:**
```typescript
// Before
const Button = lazy(() => import('@/components/Button'));

// After
const Button = lazy(() => import('@/components/atoms/Button'));
// Note: Dynamic imports use component path, not barrel import
```

**Re-exports in other files:**
```typescript
// Before (in src/components/ui/index.ts)
export { Button } from '../Button';

// After
export { Button } from '@/components/atoms';
```

**Namespace imports:**
```typescript
// Before
import * as ButtonModule from '@/components/Button';

// After
import * as ButtonModule from '@/components/atoms/Button';
// Note: Namespace imports keep component path for specificity
```

**Multiple components in single import:**
```typescript
// Before
import { Button } from '@/components/Button';
import { Input } from '@/components/Input';

// After (can combine if same level)
import { Button, Input } from '@/components/atoms';
```

### Import Consolidation (Optional)

When multiple components are imported from same level, optionally consolidate:

```typescript
// Before (separate imports)
import { Button } from '@/components/atoms';
import { Input } from '@/components/atoms';
import { Label } from '@/components/atoms';

// After (consolidated)
import { Button, Input, Label } from '@/components/atoms';
```

**Note:** Consolidation is optional and may be skipped to minimize changes.

---

## Barrel Export Update Workflow

Detailed workflow for creating and updating barrel export files at each atomic level.

### Level Barrel Export Pattern

Each atomic level has its own barrel export file:

```typescript
// src/components/atoms/index.ts
export { Button } from './Button';
export type { ButtonProps } from './Button';
export { Input } from './Input';
export type { InputProps } from './Input';
export { Label } from './Label';
export type { LabelProps } from './Label';
```

### Main Barrel Export Pattern

The main components index re-exports all levels:

```typescript
// src/components/index.ts
export * from './atoms';
export * from './molecules';
export * from './organisms';
export * from './templates';
```

### Update vs Create Strategy

**If level index.ts exists:**
1. Read current content
2. Parse existing exports
3. Append new exports (avoiding duplicates)
4. Use Edit tool to update

```
Edit tool:
- file_path: src/components/atoms/index.ts
- old_string: |
    export { Button } from './Button';
    export type { ButtonProps } from './Button';
- new_string: |
    export { Button } from './Button';
    export type { ButtonProps } from './Button';
    export { Input } from './Input';
    export type { InputProps } from './Input';
```

**If level index.ts doesn't exist:**
1. Create with Write tool
2. Include all moved components

```
Write tool:
- file_path: src/components/atoms/index.ts
- content: |
    // Barrel export for atoms
    export { Button } from './Button';
    export type { ButtonProps } from './Button';
    export { Input } from './Input';
    export type { InputProps } from './Input';
```

### Type Export Detection

Scan component files for exported types:

```typescript
// Patterns to detect in component files:
export type { ButtonProps };           // Re-export
export type ButtonProps = { ... };     // Type alias
export interface ButtonProps { ... }   // Interface
```

For each detected type, add to barrel export:
```typescript
export type { ButtonProps } from './Button';
```

### Alphabetical Ordering

Maintain alphabetical order in barrel exports for consistency:

```typescript
// Correct ordering
export { Avatar } from './Avatar';
export type { AvatarProps } from './Avatar';
export { Badge } from './Badge';
export type { BadgeProps } from './Badge';
export { Button } from './Button';
export type { ButtonProps } from './Button';
```

### Duplicate Prevention

Before adding export, check if it already exists:

```typescript
// Read current barrel content
const currentContent = read('src/components/atoms/index.ts');

// Check for existing export
if (currentContent.includes("export { Button }")) {
  // Skip - already exported
  return;
}

// Safe to add
appendExport("export { Button } from './Button';");
```

### Barrel Export Template

For new barrel files, use this template:

```typescript
// src/components/{level}/index.ts
// Barrel export for {level}
// Generated by refactor-atomic-design command

// Component exports
export { ComponentA } from './ComponentA';
export { ComponentB } from './ComponentB';

// Type exports
export type { ComponentAProps } from './ComponentA';
export type { ComponentBProps } from './ComponentB';
```

---

## Test File Handling Workflow

Detailed workflow for moving test files alongside components and updating imports within test files.

### Test File Detection

For each component, detect associated test files using these patterns:

| Pattern | Location | Example |
|---------|----------|---------|
| `{ComponentName}.test.tsx` | Same directory as component | `Button/Button.test.tsx` |
| `{ComponentName}.spec.tsx` | Same directory as component | `Button/Button.spec.tsx` |
| `__tests__/{ComponentName}.test.tsx` | __tests__ subdirectory | `Button/__tests__/Button.test.tsx` |
| `__tests__/{ComponentName}.spec.tsx` | __tests__ subdirectory | `Button/__tests__/Button.spec.tsx` |

### Test File Moving Strategy

Test files are moved as part of the component directory move:

1. **Detect test files during scanning:**
   ```typescript
   const testPatterns = [
     `${componentDir}/${componentName}.test.tsx`,
     `${componentDir}/${componentName}.spec.tsx`,
     `${componentDir}/__tests__/${componentName}.test.tsx`,
     `${componentDir}/__tests__/${componentName}.spec.tsx`,
   ];

   component.hasTests = testPatterns.some(p => fileExists(p));
   component.testPath = testPatterns.find(p => fileExists(p));
   ```

2. **Include tests in file copy sequence:**
   - Copy test files to same relative location in destination
   - Preserve __tests__ subdirectory structure if used

3. **Update test file imports:**
   ```typescript
   // Before (in Button/__tests__/Button.test.tsx)
   import { Button } from '../Button';
   import { render } from '@testing-library/react';

   // After (in atoms/Button/__tests__/Button.test.tsx)
   import { Button } from '../Button';  // Relative import unchanged
   import { render } from '@testing-library/react';  // External unchanged
   ```

### Test Import Update Rules

| Import Type | Update Required | Example |
|-------------|-----------------|---------|
| Relative to component | **No** - relative path still valid | `import { Button } from '../Button'` |
| Absolute to old path | **Yes** - update to new atomic path | `import { Button } from '@/components/Button'` → `import { Button } from '@/components/atoms'` |
| Other components | **Yes** - if those components were also moved | `import { Icon } from '@/components/Icon'` → `import { Icon } from '@/components/atoms'` |
| External libraries | **No** - unchanged | `import { render } from '@testing-library/react'` |

### Test Preservation Guarantees

1. **Never delete test files** - Only copy to new location
2. **Never modify test logic** - Only update import paths
3. **Preserve test file structure** - __tests__ directories maintained
4. **Report test status in plan:**
   ```
   [ ] Button: src/components/Button/ -> src/components/atoms/Button/
       Has tests: Yes (Button.test.tsx)
       Test imports to update: 2
   ```

### Error Handling

| Scenario | Action |
|----------|--------|
| Test file import cannot be resolved | Warn: "Test file {path} has import that may need manual update" |
| __tests__ directory not copied | Error and halt - tests must be preserved |
| Test file references multiple moved components | Update all relevant imports |

---

## Storybook Story Generation Workflow

Detailed workflow for generating Storybook stories for Atoms, Molecules, and Organisms.

### Story Generation Criteria

Generate stories for:
- **Atoms** - Always generate stories
- **Molecules** - Always generate stories
- **Organisms** - Always generate stories
- **Templates** - **NO stories** (layout components without meaningful props)
- **Pages** - **NO stories** (data-connected, route-specific)

### Skip Conditions

Skip story generation when:
1. Component already has a story file (*.stories.tsx exists)
2. Component is a Template or Page
3. `--skip-stories` flag is set
4. Storybook is not detected (see Storybook Detection Workflow)

### Story Template Selection

**Atom Story Template:**
```typescript
// {ComponentName}.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { {ComponentName} } from './{ComponentName}';

const meta: Meta<typeof {ComponentName}> = {
  title: 'Atoms/{ComponentName}',
  component: {ComponentName},
  tags: ['autodocs'],
  parameters: {
    layout: 'centered',
  },
};

export default meta;
type Story = StoryObj<typeof {ComponentName}>;

export const Default: Story = {
  args: {},
};
```

**Molecule Story Template:**
```typescript
// {ComponentName}.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { {ComponentName} } from './{ComponentName}';

const meta: Meta<typeof {ComponentName}> = {
  title: 'Molecules/{ComponentName}',
  component: {ComponentName},
  tags: ['autodocs'],
  parameters: {
    layout: 'centered',
  },
};

export default meta;
type Story = StoryObj<typeof {ComponentName}>;

export const Default: Story = {
  args: {},
};
```

**Organism Story Template:**
```typescript
// {ComponentName}.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { {ComponentName} } from './{ComponentName}';

const meta: Meta<typeof {ComponentName}> = {
  title: 'Organisms/{ComponentName}',
  component: {ComponentName},
  tags: ['autodocs'],
  parameters: {
    layout: 'centered',
  },
};

export default meta;
type Story = StoryObj<typeof {ComponentName}>;

export const Default: Story = {
  args: {},
};
```

### Story Title Hierarchy

The story title follows Atomic Design levels:

| Level | Title Pattern | Example |
|-------|---------------|---------|
| Atom | `Atoms/{ComponentName}` | `Atoms/Button` |
| Molecule | `Molecules/{ComponentName}` | `Molecules/FormField` |
| Organism | `Organisms/{ComponentName}` | `Organisms/LoginForm` |

### Prop Analysis for Args

Analyze component props to generate meaningful default args:

1. **Read component file:**
   ```typescript
   // Extract interface/type for props
   interface ButtonProps {
     variant: 'primary' | 'secondary';
     size?: 'sm' | 'md' | 'lg';
     disabled?: boolean;
     children: React.ReactNode;
   }
   ```

2. **Generate args based on prop types:**
   ```typescript
   export const Default: Story = {
     args: {
       variant: 'primary',      // First option for union types
       size: 'md',              // Default value if specified, else first option
       disabled: false,         // false for booleans
       children: 'Button Text', // Placeholder for children
     },
   };
   ```

3. **Generate argTypes for controls:**
   ```typescript
   argTypes: {
     variant: {
       control: 'select',
       options: ['primary', 'secondary'],
       description: 'The visual style',
     },
     size: {
       control: 'select',
       options: ['sm', 'md', 'lg'],
     },
     disabled: {
       control: 'boolean',
     },
   },
   ```

### Story File Creation

Use Write tool to create story file:

```
Write tool:
- file_path: src/components/{level}/{ComponentName}/{ComponentName}.stories.tsx
- content: (generated from template)
```

### Story Count Tracking

Track stories created for summary:

```typescript
const storySummary = {
  created: 0,
  skipped: {
    alreadyExists: 0,
    templateOrPage: 0,
    skipFlag: 0,
  }
};
```

Report in completion summary:
```
Stories created: 15
Stories skipped:
  - Already existed: 3
  - Templates/Pages: 5
```

---

## Storybook Detection Workflow

Workflow for detecting Storybook configuration and handling projects without Storybook.

### Detection Patterns

Check for Storybook installation:

1. **Check for .storybook directory:**
   ```
   Glob pattern: .storybook/main.{ts,js,mjs}
   ```

2. **Check for Storybook dependencies in package.json:**
   ```typescript
   // Read package.json
   const pkg = JSON.parse(read('package.json'));

   const hasStorybook =
     pkg.devDependencies?.['@storybook/react'] ||
     pkg.devDependencies?.['@storybook/react-vite'] ||
     pkg.devDependencies?.['@storybook/nextjs'] ||
     pkg.dependencies?.['storybook'];
   ```

3. **Detection result:**
   ```typescript
   const storybookStatus = {
     detected: boolean,
     configPath: string | null,  // e.g., '.storybook/main.ts'
     framework: 'react-vite' | 'nextjs' | 'unknown',
   };
   ```

### Framework-Specific Detection

| Project Type | Expected Storybook Package | Config Check |
|--------------|---------------------------|--------------|
| Vite SPA | `@storybook/react-vite` | `.storybook/main.ts` with `framework: '@storybook/react-vite'` |
| Next.js | `@storybook/nextjs` | `.storybook/main.ts` with `framework: '@storybook/nextjs'` |

### Warning Display

If Storybook is not detected:

```
=== WARNING ===

Storybook is not configured in this project.
Story generation will be skipped.

Options:
1. Skip story generation and continue
2. Set up Storybook now (will run: npx storybook@latest init)
3. Cancel refactoring

Enter choice (1-3):
```

### User Options

**Option 1: Skip story generation**
```typescript
// Set flag and continue
storybookStatus.skipStories = true;
plan.summary.storiesToCreate = 0;
```

**Option 2: Set up Storybook**
```bash
# Run Storybook init
npx storybook@latest init --skip-install

# Install dependencies
npm install
```

After setup, re-detect and continue with story generation.

**Option 3: Cancel**
Exit refactoring without changes.

### --skip-stories Flag Handling

When `--skip-stories` is set:

1. **Skip detection entirely:**
   ```typescript
   if (options.skipStories) {
     storybookStatus.skipStories = true;
     // No need to detect Storybook
   }
   ```

2. **Update plan summary:**
   ```
   Summary:
   - Components to refactor: 24
   - Stories to create: 0 (--skip-stories)
   ```

3. **Skip story generation in execution phase:**
   ```typescript
   if (!options.skipStories && storybookStatus.detected) {
     generateStories(component);
   }
   ```

### Integration with Plan Display

Show Storybook status in plan:

```
=== REFACTORING PLAN ===

Project: my-react-app
Framework: Vite (React SPA)
Storybook: Detected (@storybook/react-vite)

Summary:
- Components to refactor: 24
- Stories to create: 19
```

Or if not detected:

```
=== REFACTORING PLAN ===

Project: my-react-app
Framework: Vite (React SPA)
Storybook: Not detected (stories will be skipped)

Summary:
- Components to refactor: 24
- Stories to create: 0
```

### Existing Story Handling

If component already has a story:

1. **Detect during scanning:**
   ```typescript
   component.hasStory = fileExists(`${componentDir}/${componentName}.stories.tsx`);
   component.storyPath = hasStory ? `${componentDir}/${componentName}.stories.tsx` : null;
   ```

2. **Move existing story with component:**
   - Story file is included in directory move
   - Story title may need updating (e.g., `Components/Button` → `Atoms/Button`)

3. **Update story title if needed:**
   ```
   Edit tool:
   - file_path: src/components/atoms/Button/Button.stories.tsx
   - old_string: title: 'Components/Button',
   - new_string: title: 'Atoms/Button',
   ```

4. **Report in plan:**
   ```
   [ ] Button: src/components/Button/ -> src/components/atoms/Button/
       Has story: Yes (will update title)
       New title: Atoms/Button
   ```

---

## Incremental Refactoring Detection

Workflow for detecting and skipping already-refactored components to ensure idempotent execution.

### Detection Logic

During the component scanning phase, exclude components that are already in atomic directories:

```typescript
// Exclusion check
function isAlreadyRefactored(componentPath: string): boolean {
  const atomicPatterns = [
    /src\/components\/atoms\//,
    /src\/components\/molecules\//,
    /src\/components\/organisms\//,
    /src\/components\/templates\//
  ];

  return atomicPatterns.some(pattern => pattern.test(componentPath));
}
```

### Exclusion Patterns

Apply these patterns during Glob scanning to exclude already-refactored components:

```
Primary scan pattern:
  src/components/**/[A-Z]*.tsx

Exclusion patterns:
  src/components/atoms/**
  src/components/molecules/**
  src/components/organisms/**
  src/components/templates/**
```

### Reporting

In the plan summary, report already-refactored components:

```
=== REFACTORING PLAN ===

Project: my-react-app
Framework: Vite (React SPA)

Summary:
- Components to refactor: 12
- Already in atomic structure: 8 (skipped)
- Atoms: 4
- Molecules: 3
- Organisms: 3
- Templates: 2
- Pages: 0
```

### Detailed Skip Reporting

Optionally show which components were skipped:

```
Skipped (already refactored):
- Button (atoms/Button/)
- Input (atoms/Input/)
- FormField (molecules/FormField/)
- SearchBar (molecules/SearchBar/)
- Header (organisms/Header/)
- Footer (organisms/Footer/)
- MainLayout (templates/MainLayout/)
- AuthLayout (templates/AuthLayout/)
```

### Idempotency Guarantees

Running the command multiple times produces the same result:

1. **Scanning is idempotent:** Already-refactored components are always excluded
2. **Barrel exports are idempotent:** Duplicate prevention ensures no duplicate exports
3. **Import updates are idempotent:** Same transformation rules produce same results
4. **File moves are idempotent:** Destination check prevents overwriting

### Edge Cases

| Scenario | Action |
|----------|--------|
| Component exists in both locations | Warn: "Component found in both flat and atomic structure" |
| Partial refactoring (some files moved) | Detect incomplete move, suggest completing manually |
| Different component with same name | Use full path for identification |
| Barrel export has extra entries | Leave existing entries, only add missing |

---

## Execution Workflow

### File Operations

Use **Write** tool for:
- Creating new directories (via writing `.gitkeep` files)
- Creating barrel export `index.ts` files
- Creating Storybook stories

Use **Edit** tool for:
- Updating import statements
- Updating existing barrel exports

### Import Update Pattern

When updating imports, handle these cases:

**Direct component import:**
```typescript
// Before
import { Button } from '@/components/Button';
// After
import { Button } from '@/components/atoms';
```

**Relative import:**
```typescript
// Before
import { Button } from '../Button';
// After
import { Button } from '@/components/atoms';
```

**Named exports:**
```typescript
// Before
import { Button, type ButtonProps } from '@/components/Button';
// After
import { Button, type ButtonProps } from '@/components/atoms';
```

### Barrel Export Updates

After moving components, update barrel exports:

```typescript
// src/components/atoms/index.ts
export { Button } from './Button';
export { Input } from './Input';
export type { ButtonProps } from './Button';
export type { InputProps } from './Input';
```

### Storybook Story Generation

Generate stories for Atoms, Molecules, Organisms only. Use this template:

```typescript
// ComponentName.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { ComponentName } from './ComponentName';

const meta: Meta<typeof ComponentName> = {
  title: 'Level/ComponentName', // e.g., 'Atoms/Button'
  component: ComponentName,
  tags: ['autodocs'],
  parameters: {
    layout: 'centered',
  },
};

export default meta;
type Story = StoryObj<typeof ComponentName>;

export const Default: Story = {
  args: {},
};
```

## Post-Refactoring Verification

Workflow for verifying that refactoring completed successfully by running type-check, lint, and tests.

### Phase 6: Verification

After executing all file moves and import updates, run verification to ensure code quality.

---

## Type-Check Verification Workflow

Verify that all import statements are correct and TypeScript compiles without errors.

### Execution

Use Bash tool to run type checking:

```bash
# Check for project-specific type-check command
npm run type-check 2>/dev/null || npx tsc --noEmit
```

### Command Detection

1. **Check package.json for type-check script:**
   ```typescript
   const pkg = JSON.parse(read('package.json'));
   const hasTypeCheck = pkg.scripts?.['type-check'] !== undefined;

   if (hasTypeCheck) {
     command = 'npm run type-check';
   } else {
     command = 'npx tsc --noEmit';
   }
   ```

2. **Alternative commands by framework:**
   | Framework | Primary Command | Fallback |
   |-----------|-----------------|----------|
   | Vite | `npm run type-check` | `npx tsc --noEmit` |
   | Next.js | `npm run type-check` | `npx tsc --noEmit` |

### Output Parsing

Parse type-check output to identify errors:

```
Bash output:
src/pages/HomePage.tsx(5,10): error TS2307: Cannot find module '@/components/Button' or its corresponding type declarations.
src/components/organisms/Header/Header.tsx(3,22): error TS2305: Module '"@/components/atoms"' has no exported member 'IconButton'.
```

**Parse pattern:**
```typescript
const errorPattern = /(.+)\((\d+),(\d+)\): error (TS\d+): (.+)/;

// Extract:
// - File path
// - Line number
// - Column number
// - Error code
// - Error message
```

### Status Reporting

**Pass Status:**
```
Type-check: PASSED
  No TypeScript errors found.
```

**Fail Status:**
```
Type-check: FAILED (3 errors)

  src/pages/HomePage.tsx:5:10
  TS2307: Cannot find module '@/components/Button'
  Suggestion: Import path may not have been updated. Check if Button moved to atoms/

  src/components/organisms/Header/Header.tsx:3:22
  TS2305: Module '"@/components/atoms"' has no exported member 'IconButton'
  Suggestion: Verify IconButton was moved and exported from barrel file

  src/App.tsx:12:1
  TS2307: Cannot find module '@/components/Input'
  Suggestion: Import path may not have been updated. Check if Input moved to atoms/
```

### Error Guidance

Provide contextual suggestions based on error type:

| Error Code | Meaning | Suggestion |
|------------|---------|------------|
| TS2307 | Cannot find module | Import path may not have been updated; check if component moved |
| TS2305 | Module has no exported member | Verify component is exported from barrel file |
| TS2614 | Module has no default export | Check component uses named export, update import syntax |
| TS7016 | Could not find declaration | Check for missing type exports in barrel file |

### Recovery Actions

If type-check fails:

1. **Display errors with file paths and suggestions**
2. **Offer options using AskUserQuestion:**
   - Question: "Type-check failed with X errors. How would you like to proceed?"
   - Options:
     - "Review errors and fix manually (recommended)"
     - "Continue with lint and tests anyway"
     - "Rollback - undo all changes (git checkout)"

3. **If rollback selected:**
   ```
   To undo refactoring changes:

   git checkout -- src/components/

   This will restore all component files to their pre-refactoring state.
   ```

### Tracking

Record verification result for summary:

```typescript
verificationResults.typeCheck = {
  status: 'pass' | 'fail',
  errorCount: number,
  errors: Array<{
    file: string,
    line: number,
    code: string,
    message: string
  }>
};
```

---

## Lint Verification Workflow

Run linter to catch formatting issues and code quality problems after refactoring.

### Execution

Use Bash tool to run linting:

```bash
# Run lint with auto-fix enabled
npm run lint -- --fix
```

### Command Detection

1. **Check package.json for lint script:**
   ```typescript
   const pkg = JSON.parse(read('package.json'));
   const hasLint = pkg.scripts?.['lint'] !== undefined;

   if (hasLint) {
     command = 'npm run lint -- --fix';
   }
   ```

2. **Detect linter type from config files:**
   | Linter | Config Files | Command |
   |--------|--------------|---------|
   | Biome | `biome.json`, `biome.jsonc` | `npx biome check --fix .` |
   | ESLint | `.eslintrc.*`, `eslint.config.*` | `npx eslint --fix .` |

3. **Framework-specific commands:**
   | Framework | Primary Command |
   |-----------|-----------------|
   | Vite | `npm run lint -- --fix` |
   | Next.js | `npm run lint -- --fix` or `npx next lint` |

### Output Parsing

Parse lint output to count fixes and errors:

**Biome output example:**
```
Fixed 5 file(s)
Checked 47 files in 234ms
```

**ESLint output example:**
```
/src/pages/HomePage.tsx
  12:5  warning  'unused' is defined but never used  @typescript-eslint/no-unused-vars

/src/components/atoms/Button/Button.tsx
  Auto-fixed 3 issues

47 problems (2 errors, 45 warnings)
43 errors and warnings potentially fixable with the `--fix` option
```

**Parse patterns:**
```typescript
// Biome
const biomeFixPattern = /Fixed (\d+) file\(s\)/;
const biomeCheckPattern = /Checked (\d+) files/;

// ESLint
const eslintSummaryPattern = /(\d+) problems? \((\d+) errors?, (\d+) warnings?\)/;
const eslintFixPattern = /Auto-fixed (\d+) issues?/;
```

### Status Reporting

**Pass Status (no remaining issues):**
```
Lint: PASSED
  Files checked: 47
  Auto-fixed: 3 issues
  Remaining issues: 0
```

**Pass Status (warnings only):**
```
Lint: PASSED (with 2 warnings)
  Files checked: 47
  Auto-fixed: 5 issues
  Warnings: 2 (non-blocking)
```

**Fail Status:**
```
Lint: FAILED (2 errors)
  Files checked: 47
  Auto-fixed: 3 issues
  Errors: 2
  Warnings: 5

  Errors:
    src/pages/HomePage.tsx:12:5
    'importedComponent' is not defined

    src/components/organisms/Header/Header.tsx:8:10
    Parsing error: Unexpected token
```

### Auto-Fix Tracking

Report what was automatically fixed:

```typescript
lintResults = {
  filesChecked: number,
  autoFixed: number,
  errors: number,
  warnings: number,
  errorDetails: Array<{
    file: string,
    line: number,
    rule: string,
    message: string
  }>
};
```

### Lint Error Guidance

Common lint errors after refactoring:

| Error Pattern | Likely Cause | Suggestion |
|---------------|--------------|------------|
| is not defined | Import missing | Check if import statement was updated |
| Parsing error | Syntax issue | Review file for broken syntax |
| no-unused-vars | Removed usage | Import may be stale, safe to remove |
| import/order | Import ordering | Auto-fix should handle; re-run if needed |

### Integration with Verification Flow

Lint runs after type-check:

1. If type-check passed, proceed to lint
2. If type-check failed but user chose to continue, still run lint
3. Lint auto-fixes should not affect type-check results (import ordering only)

---

## Test Verification Workflow

Run existing tests to verify refactoring did not break functionality.

### Execution

Use Bash tool to run tests:

```bash
# Run tests (Vitest for Vite, Jest for Next.js)
npm test -- --run
```

### Command Detection

1. **Check package.json for test script:**
   ```typescript
   const pkg = JSON.parse(read('package.json'));
   const hasTest = pkg.scripts?.['test'] !== undefined;

   if (hasTest) {
     // Add --run flag to prevent watch mode
     command = 'npm test -- --run';
   }
   ```

2. **Detect test runner from dependencies:**
   | Test Runner | Detection | Command Flags |
   |-------------|-----------|---------------|
   | Vitest | `vitest` in devDependencies | `--run` (exit after tests) |
   | Jest | `jest` in devDependencies | `--passWithNoTests` |

3. **Framework-specific commands:**
   | Framework | Primary Test Runner | Command |
   |-----------|---------------------|---------|
   | Vite | Vitest | `npm test -- --run` |
   | Next.js | Jest | `npm test -- --passWithNoTests` |

### Output Parsing

Parse test output to extract pass/fail counts:

**Vitest output example:**
```
 DEV  v2.1.0

 ✓ src/components/atoms/Button/__tests__/Button.test.tsx (3 tests) 12ms
 ✓ src/components/molecules/FormField/__tests__/FormField.test.tsx (5 tests) 23ms
 ✗ src/components/organisms/Header/__tests__/Header.test.tsx (2 tests) 45ms
   ✗ should render header with logo
     Error: Cannot find module '@/components/Button'

 Test Files  1 failed | 2 passed (3)
 Tests       1 failed | 9 passed (10)
 Duration    2.34s
```

**Jest output example:**
```
PASS  src/components/atoms/Button/__tests__/Button.test.tsx
PASS  src/components/molecules/FormField/__tests__/FormField.test.tsx
FAIL  src/components/organisms/Header/__tests__/Header.test.tsx
  ● Header › should render header with logo
    Cannot find module '@/components/Button' from 'Header.test.tsx'

Test Suites: 1 failed, 2 passed, 3 total
Tests:       1 failed, 9 passed, 10 total
```

**Parse patterns:**
```typescript
// Vitest
const vitestSummaryPattern = /Test Files\s+(\d+) failed \| (\d+) passed/;
const vitestTestsPattern = /Tests\s+(\d+) failed \| (\d+) passed/;

// Jest
const jestSummaryPattern = /Test Suites:\s+(\d+) failed,\s+(\d+) passed/;
const jestTestsPattern = /Tests:\s+(\d+) failed,\s+(\d+) passed/;
```

### Status Reporting

**Pass Status:**
```
Tests: PASSED (24/24)
  Test files: 8 passed
  Total tests: 24 passed
  Duration: 3.45s
```

**Fail Status:**
```
Tests: FAILED (22/24)
  Test files: 1 failed, 7 passed
  Total tests: 2 failed, 22 passed
  Duration: 4.12s

  Failed tests:
    src/components/organisms/Header/__tests__/Header.test.tsx
    - should render header with logo
      Error: Cannot find module '@/components/Button'
      Suggestion: Update import in test file from '@/components/Button' to '@/components/atoms'

    - should toggle mobile menu
      Error: Cannot find module '@/components/Icon'
      Suggestion: Update import in test file from '@/components/Icon' to '@/components/atoms'
```

### Test Failure Guidance

Common test failures after refactoring:

| Error Pattern | Likely Cause | Suggestion |
|---------------|--------------|------------|
| Cannot find module | Import path not updated in test | Update import to new atomic path |
| Module has no exported member | Missing barrel export | Verify component exported from level index.ts |
| Unexpected token | Test file has syntax error | Check for broken imports |
| Component is not defined | Mock may reference old path | Update mock paths |

### Specific Suggestions

For import errors in tests, provide specific fix instructions:

```
Failed: src/components/organisms/Header/__tests__/Header.test.tsx

Current import (line 3):
  import { Button } from '@/components/Button';

Suggested fix:
  import { Button } from '@/components/atoms';

To apply fix:
  Edit the import statement in Header.test.tsx
```

### Test File Import Analysis

If tests fail, analyze test file imports:

```typescript
// Read test file
const testContent = read(failedTestPath);

// Find imports referencing moved components
const importPattern = /import\s+\{([^}]+)\}\s+from\s+['"]([^'"]+)['"]/g;

// Check if import paths match old (pre-refactoring) paths
const oldPaths = movedComponents.map(c => c.sourcePath);
const needsUpdate = imports.filter(i => oldPaths.includes(i.path));
```

### Integration with Verification Flow

Tests run after lint:

1. If lint passed (or only warnings), proceed to tests
2. If lint failed but user chose to continue, still run tests
3. Test failures are most likely due to import updates needed in test files
4. Test file import updates were attempted during refactoring, but may have missed some cases

### Tracking

Record test results for summary:

```typescript
verificationResults.tests = {
  status: 'pass' | 'fail',
  testFiles: { passed: number, failed: number, total: number },
  tests: { passed: number, failed: number, total: number },
  duration: string,
  failures: Array<{
    file: string,
    testName: string,
    error: string,
    suggestion: string
  }>
};
```

---

## Completion Summary and Next Steps

Final output after all refactoring and verification steps complete.

### Summary Display Format

```
=== REFACTORING COMPLETE ===

Duration: 45 seconds

Files Changed:
  Components moved: 24
  Import statements updated: 47
  Barrel exports created/updated: 5
  Storybook stories created: 19
  Test files moved: 12

Verification Results:
  Type-check: PASSED
  Lint: PASSED (3 auto-fixed)
  Tests: PASSED (24/24)

Components by Level:
  Atoms: 8 (Button, Input, Label, Icon, Badge, Avatar, Spinner, Tooltip)
  Molecules: 6 (FormField, SearchForm, Card, Modal, Dropdown, Tabs)
  Organisms: 5 (Header, Footer, Sidebar, LoginForm, UserProfile)
  Templates: 3 (MainLayout, DashboardLayout, AuthLayout)
  Pages: 2 (HomePage, DashboardPage)
```

### Next Steps Section

```
=== NEXT STEPS ===

1. Review changes in git:
   git diff --stat
   git diff src/components/

2. Run Storybook to verify stories:
   npm run storybook

3. Manual verification:
   - Open application in browser
   - Test key user flows
   - Verify no visual regressions

4. Commit when satisfied:
   git add .
   git commit -m "refactor: migrate components to Atomic Design structure"

=== UNDO INSTRUCTIONS ===

If you need to revert all changes:
   git checkout -- src/components/

Or to see what would be reverted:
   git diff src/components/
```

### Summary Data Structure

```typescript
interface CompletionSummary {
  duration: string;  // e.g., "45 seconds"

  filesChanged: {
    componentsMoved: number;
    importsUpdated: number;
    barrelExportsUpdated: number;
    storiesCreated: number;
    testFilesMoved: number;
  };

  verification: {
    typeCheck: 'passed' | 'failed' | 'skipped';
    typeCheckErrors?: number;
    lint: 'passed' | 'failed' | 'skipped';
    lintAutoFixed?: number;
    tests: 'passed' | 'failed' | 'skipped';
    testsPassed?: number;
    testsFailed?: number;
  };

  componentsByLevel: {
    atoms: string[];
    molecules: string[];
    organisms: string[];
    templates: string[];
    pages: string[];
  };
}
```

### Partial Success Handling

If some verifications failed:

```
=== REFACTORING COMPLETE (with warnings) ===

Duration: 52 seconds

Files Changed:
  Components moved: 24
  Import statements updated: 45 (2 may need manual review)
  Barrel exports created/updated: 5
  Storybook stories created: 19
  Test files moved: 12

Verification Results:
  Type-check: PASSED
  Lint: PASSED (3 auto-fixed)
  Tests: FAILED (22/24 passed)

=== ACTION REQUIRED ===

2 tests failed after refactoring. Please review:

  src/components/organisms/Header/__tests__/Header.test.tsx
    - Update import from '@/components/Button' to '@/components/atoms'

  src/pages/__tests__/HomePage.test.tsx
    - Update import from '@/components/Input' to '@/components/atoms'

After fixing, run tests again:
  npm test
```

### Cleanup Reminder

If source files were not deleted (safety mode):

```
=== CLEANUP (optional) ===

Source component directories were preserved as backup.
After verifying everything works, you can remove them:

  rm -rf src/components/Button
  rm -rf src/components/Input
  rm -rf src/components/FormField
  ... (20 more directories)

Or to remove all at once:
  rm -rf src/components/Button src/components/Input src/components/FormField ...

Note: Only remove after committing your changes!
```

### Storybook Verification Note

```
=== STORYBOOK ===

19 stories were created. To verify:

  npm run storybook

Stories are organized by atomic level:
  - Atoms/Button
  - Atoms/Input
  - Molecules/FormField
  - Organisms/Header
  ...

If Storybook fails to build, check that all component imports in stories are correct.
```

### Commit Message Suggestion

Provide a suggested commit message:

```
Suggested commit message:

refactor: migrate 24 components to Atomic Design structure

- Reorganized flat component structure into atoms/molecules/organisms/templates
- Updated 47 import statements across the codebase
- Created barrel exports for each atomic level
- Generated 19 Storybook stories for component documentation
- All tests passing (24/24)
```

### Integration with Command Flow

The completion summary is displayed:

1. After all verification steps complete (or user chose to continue despite failures)
2. Before command exits
3. Contains all information needed for user to:
   - Understand what changed
   - Verify the changes
   - Commit or rollback
   - Know what manual actions may be needed

---

## Verification Commands

Use Bash tool to run verification:

```bash
# Type checking
npm run type-check   # or: npx tsc --noEmit

# Linting
npm run lint

# Tests
npm test
```

## Error Handling

| Error | Action |
|-------|--------|
| Type-check fails | Report which imports may be broken, suggest reviewing affected files |
| Tests fail | Suggest checking import updates in test files |
| Component not found during move | Warn and skip with explanation |
| Circular dependency detected | Warn but allow proceeding |

## Idempotency

- Detect already-refactored components (in atomic directories) and skip
- Running command twice produces same result
- Only analyze components in flat structure

## CRITICAL: Tool Usage Requirements

You MUST use the **AskUserQuestion** tool for ALL user interactions.

**NEVER** do any of the following:
- Output questions as plain text
- End your response with a question
- Skip user approval before executing changes

**ALWAYS** invoke AskUserQuestion when:
- Presenting the refactoring plan
- Asking for classification modifications
- Confirming partial selection

## Notes

- Server Components vs Client Components detection is for informational purposes only (does not affect classification)
- Focus on component structure and composition, not rendering strategy
- Preserve all existing test files during move
- Never delete files - only move and update
