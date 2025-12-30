---
description: Refactor existing React project to Atomic Design component structure
agent: code-analyzer
---

# Refactor Atomic Design Command

Refactor existing React (Vite SPA or Next.js) project to Atomic Design component structure with analysis, plan approval, and automated execution.

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--target` | string | No | components directory | Specific directory or component to refactor |
| `--dry-run` | boolean | No | false | Show plan without executing |
| `--skip-stories` | boolean | No | false | Skip Storybook story generation |
| `--skip-tests` | boolean | No | false | Skip test file updates |

## Workflow

### Phase 1: Initialization

1. Detect project framework:
   - Check for `next.config.ts` or `next.config.js` → Next.js project
   - Check for `vite.config.ts` → Vite project

2. Identify component directory:
   - `src/components/` for both Vite and Next.js

3. Verify or create atomic design directories:
   ```
   src/components/
   ├── atoms/
   │   ├── .gitkeep
   │   └── index.ts
   ├── molecules/
   │   ├── .gitkeep
   │   └── index.ts
   ├── organisms/
   │   ├── .gitkeep
   │   └── index.ts
   ├── templates/
   │   ├── .gitkeep
   │   └── index.ts
   └── index.ts
   ```

4. Create barrel exports if missing:

   **Level barrel export template:**
   ```typescript
   // src/components/atoms/index.ts
   // Barrel export for atoms
   // Components will be added here as they are created or moved
   ```

   **Main barrel export template:**
   ```typescript
   // src/components/index.ts
   export * from './atoms';
   export * from './molecules';
   export * from './organisms';
   export * from './templates';
   ```

### Phase 2: Analysis

Invoke the **code-analyzer** agent with reference to **atomic-design** skill to:

1. Scan component directories using Glob patterns:
   - `src/components/**/*.tsx` (excluding tests and stories)
   - Exclude: `**/*.test.tsx`, `**/*.spec.tsx`, `**/*.stories.tsx`
   - Exclude: Components already in atomic directories (`atoms/`, `molecules/`, `organisms/`, `templates/`)

2. Analyze each component:
   - Read component code
   - Identify imports and dependencies
   - Detect state usage (useState, useEffect, stores)
   - Check for data fetching (useQuery, fetch)

3. Classify components using atomic-design skill criteria:
   - **Atom**: No custom imports, stateless or UI state only
   - **Molecule**: Imports 2+ atoms, single purpose, minimal state
   - **Organism**: Larger section, may have business logic or stores
   - **Template**: Accepts children, named with "Layout" suffix
   - **Page**: Named with "Page" suffix, connects to data sources

4. Assign confidence levels:
   - **High**: Component clearly matches one level's criteria
   - **Medium**: Component partially matches multiple levels
   - **Low**: Component has ambiguous characteristics

5. Detect circular dependencies and generate warnings

### Phase 3: Plan Generation

Generate RefactoringPlan with:
- Project metadata (name, framework, component directory)
- Component migrations (source path, destination path, level, confidence, reason)
- Affected files (imports to update)
- Summary statistics
- Warnings

### Phase 4: User Approval

Present plan using AskUserQuestion with options:

1. **Approve all and execute** - Proceed with full refactoring
2. **Review and modify classifications** - Change component levels before execution
3. **Select specific components** - Partial refactoring
4. **Cancel** - Exit without changes

### Phase 5: Refactoring Execution

1. Move component directories to atomic level folders:
   - `src/components/Button/` → `src/components/atoms/Button/`
   - Include all files: `*.tsx`, `index.ts`, `__tests__/*`, `*.stories.tsx`

2. Update all import statements across codebase:
   - `from '@/components/Button'` → `from '@/components/atoms'`
   - `from '../Button'` → `from '@/components/atoms'`

3. Create/update barrel exports at each level:
   ```typescript
   // src/components/atoms/index.ts
   export { Button } from './Button';
   export type { ButtonProps } from './Button';
   ```

4. Generate Storybook stories (if not `--skip-stories`):
   - Only for atoms, molecules, organisms (NOT templates)
   - Use title hierarchy: `'Atoms/Button'`, `'Molecules/FormField'`

5. Update test file imports (if not `--skip-tests`)

### Phase 6: Verification

1. Run type-check:
   ```bash
   npm run type-check   # or tsc --noEmit
   ```

2. Run lint:
   ```bash
   npm run lint
   ```

3. Run tests:
   ```bash
   npm test
   ```

4. Display completion summary:
   ```
   === REFACTORING COMPLETE ===

   Files changed: 47
   Components moved: 24
   Stories created: 19
   Barrel exports updated: 5

   Type-check: PASSED
   Lint: PASSED (2 auto-fixed)
   Tests: PASSED (24/24)

   Next steps:
   1. Run `npm run storybook` to verify stories
   2. Review the changes in your git diff
   3. Commit when satisfied

   To undo: git checkout -- src/components/
   ```

## Directory Structure

### Before Refactoring

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
  MainLayout/
    MainLayout.tsx
    index.ts
```

### After Refactoring

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
    index.ts
  templates/
    MainLayout/
      MainLayout.tsx
      index.ts
    index.ts
  index.ts
```

## Examples

### Full Refactoring

```bash
/react:refactor-atomic-design
```

### Refactor Specific Directory

```bash
/react:refactor-atomic-design --target src/components/ui
```

### Skip Story Generation

```bash
/react:refactor-atomic-design --skip-stories
```

### Dry Run (Show Plan Only)

```bash
/react:refactor-atomic-design --dry-run
```

## Skills Referenced

- **atomic-design** - Classification criteria, Storybook templates, barrel export patterns

## Notes

- Recommend committing or stashing changes before running
- Previously refactored components (already in atomic directories) are skipped
- Running command twice produces same result (idempotent)
- Next.js pages remain in `src/app/` (Next.js convention)
