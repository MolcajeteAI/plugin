---
description: Refactor existing React Native (Expo) project to Atomic Design component structure
agent: code-analyzer
---

# Refactor Atomic Design Command

Refactor existing React Native (Expo) project to Atomic Design component structure with analysis, plan approval, and automated execution.

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--target` | string | No | components directory | Specific directory or component to refactor |
| `--dry-run` | boolean | No | false | Show plan without executing |
| `--skip-stories` | boolean | No | false | Skip Storybook story generation |
| `--skip-tests` | boolean | No | false | Skip test file updates |

## Workflow

### Phase 1: Initialization

1. Detect Expo project:
   - Check for `app.json` or `app.config.js` -> Expo project
   - Verify Expo Router in package.json

2. Identify component directory:
   - `components/` for Expo projects (no `src/` prefix)

3. Verify or create atomic design directories:
   ```
   components/
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
   // components/atoms/index.ts
   // Barrel export for atoms
   // Components will be added here as they are created or moved
   ```

   **Main barrel export template:**
   ```typescript
   // components/index.ts
   export * from './atoms';
   export * from './molecules';
   export * from './organisms';
   export * from './templates';
   ```

### Phase 2: Analysis

Invoke the **code-analyzer** agent with reference to **atomic-design-mobile** skill to:

1. Scan component directories using Glob patterns:
   - `components/**/*.tsx` (excluding tests and stories)
   - Exclude: `**/*.test.tsx`, `**/*.spec.tsx`, `**/*.stories.tsx`
   - Exclude: Components already in atomic directories (`atoms/`, `molecules/`, `organisms/`, `templates/`)
   - Exclude: `app/**` (Expo Router screens)

2. Analyze each component:
   - Read component code
   - Identify imports and dependencies
   - Detect state usage (useState, useEffect, stores)
   - Check for data fetching (useQuery, fetch)
   - **Detect accessibility props** (accessibilityLabel, accessibilityRole, accessibilityState)
   - **Detect platform-specific code** (Platform.OS, Platform.select)

3. Classify components using atomic-design-mobile skill criteria:
   - **Atom**: No custom imports, stateless, 44pt touch targets, accessibility props
   - **Molecule**: Imports 2+ atoms, single purpose, keyboard handling
   - **Organism**: Larger section, may have business logic, safe area handling
   - **Template**: Accepts children, named with "Layout" suffix, safe areas, keyboard avoidance
   - **Screen**: Located in app/ directory, connects to data sources (NOT moved)

4. Assign confidence levels:
   - **High**: Component clearly matches one level's criteria with accessibility
   - **Medium**: Component partially matches multiple levels
   - **Low**: Component has ambiguous characteristics or missing accessibility

5. Detect circular dependencies and generate warnings

### Phase 3: Plan Generation

Generate RefactoringPlan with:
- Project metadata (name, framework: expo, component directory)
- Component migrations (source path, destination path, level, confidence, reason)
- Affected files (imports to update)
- Summary statistics
- Warnings (including accessibility warnings)

### Phase 4: User Approval

Present plan using AskUserQuestion with options:

1. **Approve all and execute** - Proceed with full refactoring
2. **Review and modify classifications** - Change component levels before execution
3. **Select specific components** - Partial refactoring
4. **Cancel** - Exit without changes

### Phase 5: Refactoring Execution

1. Move component directories to atomic level folders:
   - `components/Button/` -> `components/atoms/Button/`
   - Include all files: `*.tsx`, `index.ts`, `__tests__/*`, `*.stories.tsx`

2. Update all import statements across codebase:
   - `from '@/components/Button'` -> `from '@/components/atoms'`
   - `from '../Button'` -> `from '@/components/atoms'`

3. Create/update barrel exports at each level:
   ```typescript
   // components/atoms/index.ts
   export { Button } from './Button';
   export type { ButtonProps } from './Button';
   ```

4. Generate Storybook stories (if not `--skip-stories`):
   - Only for atoms, molecules, organisms (NOT templates)
   - Use React Native Storybook format (@storybook/react-native)
   - Use title hierarchy: `'Atoms/Button'`, `'Molecules/FormField'`

5. Update test file imports (if not `--skip-tests`)

### Phase 6: Verification

1. Run type-check:
   ```bash
   npm run type-check   # or npx tsc --noEmit
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

   Files changed: 35
   Components moved: 18
   Stories created: 14
   Barrel exports updated: 5

   Type-check: PASSED
   Lint: PASSED (2 auto-fixed)
   Tests: PASSED (18/18)

   Next steps:
   1. Run Storybook on device to verify stories
   2. Review the changes in your git diff
   3. Commit when satisfied

   To undo: git checkout -- components/
   ```

## Directory Structure

### Before Refactoring

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

### After Refactoring

```
components/
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
    SearchBar/
      SearchBar.tsx
      SearchBar.stories.tsx
      index.ts
    index.ts
  organisms/
    Header/
      Header.tsx
      Header.stories.tsx
      index.ts
    index.ts
  templates/
    ScreenLayout/
      ScreenLayout.tsx
      index.ts
    index.ts
  index.ts
```

## Examples

### Full Refactoring

```bash
/react-native:refactor-atomic-design
```

### Refactor Specific Directory

```bash
/react-native:refactor-atomic-design --target components/ui
```

### Skip Story Generation

```bash
/react-native:refactor-atomic-design --skip-stories
```

### Dry Run (Show Plan Only)

```bash
/react-native:refactor-atomic-design --dry-run
```

## Skills Referenced

- **atomic-design-mobile** - Classification criteria with mobile accessibility, touch targets, Storybook templates, barrel export patterns

## Notes

- Expo projects do NOT use a `src/` directory
- Recommend committing or stashing changes before running
- Previously refactored components (already in atomic directories) are skipped
- Running command twice produces same result (idempotent)
- Screens in `app/` directory remain there (Expo Router convention)
- Stories use @storybook/react-native format for on-device viewing
