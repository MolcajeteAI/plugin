# Atomic Design Pattern for React Tech-Stacks - Tasks

**Created:** 2025-12-29
**Last Updated:** 2025-12-29
**Status:** Complete
**Completion:** 100% (27/27 tasks complete)

## Overview

**Spec Reference:** `.molcajete/prd/specs/20251229-atomic_design_pattern/spec.md`
**Feature Description:** Integrate Atomic Design Pattern with Storybook into React and React Native tech-stack plugins
**Estimated Total Effort:** 63 points

---

## 1. [x] Users can create Vite SPA projects with atomic component structure

- 1.1 [x] Update React PLUGIN.md project structure section (Complexity: 3) ✓ 2025-12-29
  - **Details:** Update the project structure section in `/tech-stacks/js/react/PLUGIN.md` to show atomic hierarchy under components/ (atoms/, molecules/, organisms/, templates/) with barrel exports
  - **Acceptance:** PLUGIN.md shows atomic directory structure as the default for Vite SPA projects
  - **Implementation Notes:** Updated Vite SPA section with full atomic hierarchy, added .storybook directory, added explanation of Atomic Design pattern with link to Brad Frost's article

- 1.2 [x] Update spa-init.md command to create atomic directories (Complexity: 3) ✓ 2025-12-29
  - **Details:** Modify `/tech-stacks/js/react/commands/spa-init.md` to include instructions for creating atoms/, molecules/, organisms/, templates/ directories with index.ts barrel exports, plus src/pages/ for page components
  - **Acceptance:** spa-init command creates all atomic directories with proper barrel exports
  - **Implementation Notes:** Added full atomic directory structure, barrel export examples for each level, and main barrel export

- 1.3 [x] Add Storybook setup to spa-init.md (Complexity: 5) ✓ 2025-12-29
  - **Details:** Add Storybook installation and configuration instructions using `@storybook/react-vite`. Include addon-a11y, addon-viewport. Configure stories pattern to match atomic directories (atoms/, molecules/, organisms/)
  - **Acceptance:** spa-init includes Storybook setup with correct story paths for atomic levels
  - **Implementation Notes:** Added step 10 with full Storybook setup including main.ts and preview.ts configuration, addon installation, and story patterns for atoms/molecules/organisms

- 1.4 [x] Create example atom component with story (Complexity: 3) ✓ 2025-12-29
  - **Details:** Add example Button atom to spa-init with Button.tsx, Button.stories.tsx, index.ts, and __tests__/Button.test.tsx showing the full file structure pattern
  - **Acceptance:** Example Button atom demonstrates correct file structure and story format
  - **Implementation Notes:** Added step 15 with complete Button atom example including forwardRef pattern, loading state, variant/size props, Storybook story with autodocs and all argTypes, barrel export, and test file with 10 test cases

---

## 2. [x] Users can create Next.js projects with atomic component structure

- 2.1 [x] Update nextjs-init.md command to create atomic directories (Complexity: 3) ✓ 2025-12-29
  - **Details:** Modify `/tech-stacks/js/react/commands/nextjs-init.md` to create atoms/, molecules/, organisms/, templates/ under src/components/ with barrel exports. Note that pages live in src/app/ (Next.js convention)
  - **Acceptance:** nextjs-init command creates atomic directories, no src/pages/ directory (uses app/ router)
  - **Implementation Notes:** Updated project structure to show full atomic hierarchy, added barrel export creation at each level, clarified that Next.js uses app/ for pages

- 2.2 [x] Add Storybook setup to nextjs-init.md (Complexity: 5) ✓ 2025-12-29
  - **Details:** Add Storybook installation using `@storybook/nextjs`. Configure for Next.js framework with proper story patterns and addons
  - **Acceptance:** nextjs-init includes Storybook setup compatible with Next.js App Router
  - **Implementation Notes:** Added new step for Storybook installation using @storybook/nextjs, configured main.ts with atomic story patterns, added preview.ts, installed addon-a11y and addon-viewport

- 2.3 [x] Add Next.js layout example using templates (Complexity: 3) ✓ 2025-12-29
  - **Details:** Show how src/app/layout.tsx imports and uses templates from src/components/templates/. Clarify distinction between Next.js layouts (route-specific) and templates (reusable patterns)
  - **Acceptance:** Clear example showing template usage in Next.js layouts
  - **Implementation Notes:** Added MainLayout template example, updated app/layout.tsx to import and use template, added clarification about templates vs Next.js layouts distinction

---

## 3. [x] Users can create Expo projects with atomic component structure

- 3.1 [x] Update React Native PLUGIN.md project structure section (Complexity: 3) ✓ 2025-12-29
  - **Details:** Update `/tech-stacks/js/react-native/PLUGIN.md` to show atomic hierarchy under components/ without src/ prefix (Expo convention)
  - **Acceptance:** PLUGIN.md shows atomic directory structure for Expo projects
  - **Implementation Notes:** Updated project structure with full atomic hierarchy (atoms/, molecules/, organisms/, templates/), added .storybook directory, added explanation of Atomic Design pattern with note about no src/ prefix in Expo

- 3.2 [x] Update expo-init.md command to create atomic directories (Complexity: 3) ✓ 2025-12-29
  - **Details:** Modify `/tech-stacks/js/react-native/commands/expo-init.md` to create atoms/, molecules/, organisms/, templates/ under components/ with barrel exports. Screens live in app/ (Expo Router)
  - **Acceptance:** expo-init command creates atomic directories with proper mobile conventions
  - **Implementation Notes:** Added atomic directory structure, barrel export examples for each level, and main barrel export. Note that Expo does not use src/ prefix.

- 3.3 [x] Add Storybook React Native setup to expo-init.md (Complexity: 5) ✓ 2025-12-29
  - **Details:** Add React Native Storybook installation and configuration. Include addon-ondevice-controls and addon-ondevice-actions. Note complexity differences from web Storybook
  - **Acceptance:** expo-init includes React Native Storybook setup with on-device addons
  - **Implementation Notes:** Added Storybook React Native setup with on-device addons, configured story patterns for atoms/molecules/organisms only (not templates/pages), added note about on-device vs web browser running

- 3.4 [x] Create example mobile atom with accessibility (Complexity: 3) ✓ 2025-12-29
  - **Details:** Add example Button atom showing mobile requirements: minimum 44x44pt touch targets, accessibilityLabel, accessibilityRole, accessibilityState, Platform-specific styling
  - **Acceptance:** Example mobile atom demonstrates accessibility and platform requirements
  - **Implementation Notes:** Created Button atom with full accessibility implementation including minimum touch targets (44pt), accessibilityLabel, accessibilityRole, accessibilityState, pressed state feedback, and loading indicator support

---

## 4. [x] Component builders can classify and create components at correct atomic levels

- 4.1 [x] Update React component-builder agent for atomic classification (Complexity: 5) ✓ 2025-12-29
  - **Details:** Modify `/tech-stacks/js/react/agents/component-builder.md` to include atomic level decision logic. Agent should determine or ask for atomic level, place files correctly, update barrel exports
  - **Acceptance:** React component-builder asks/determines atomic level and creates files in correct directory
  - **Implementation Notes:** Added atomic design skill reference, classification decision flowchart, atomic level decision logic section, and updated file organization to show atomic structure with barrel exports

- 4.2 [x] Add Storybook story generation to React component-builder (Complexity: 5) ✓ 2025-12-29
  - **Details:** Component-builder generates .stories.tsx files for Atoms, Molecules, and Organisms with proper Meta, StoryObj types, argTypes, and example stories. No stories for Templates/Pages
  - **Acceptance:** Component-builder generates stories with correct title hierarchy (e.g., "Atoms/Button")
  - **Implementation Notes:** Added Storybook Story Generation section with web story template showing Meta, StoryObj patterns, argTypes configuration, and title hierarchy. Clear guidance that Templates and Pages do not get stories.

- 4.3 [x] Update React Native component-builder agent for atomic classification (Complexity: 5) ✓ 2025-12-29
  - **Details:** Modify `/tech-stacks/js/react-native/agents/component-builder.md` for atomic level decision logic. Include mobile-specific considerations (touch targets, accessibility props)
  - **Acceptance:** React Native component-builder creates mobile-appropriate components at correct atomic levels
  - **Implementation Notes:** Added atomic-design-mobile skill reference, mobile-specific classification guidance including touch targets (44pt minimum), accessibility props, and platform-specific considerations at each atomic level

- 4.4 [x] Add story generation to React Native component-builder (Complexity: 3) ✓ 2025-12-29
  - **Details:** Generate React Native Storybook stories for Atoms, Molecules, Organisms with addon-ondevice-controls compatible format
  - **Acceptance:** Mobile stories work with on-device Storybook controls
  - **Implementation Notes:** Added React Native story template using @storybook/react-native types, on-device controls compatible argTypes, and clear title hierarchy for mobile components

---

## 5. [x] Users can opt out of atomic design through configuration

- 5.1 [x] Document PRD override mechanism for component organization (Complexity: 3) [Completed: 2025-12-29]
  - **Details:** Document in skills how projects can specify `componentOrganization: flat` or `componentOrganization: feature-based` in their PRD/tech-stack configuration
  - **Acceptance:** Clear documentation on how to opt out of atomic design
  - **Implementation Notes:** Added conditional logic and documentation to all init commands. Full skill documentation deferred to Feature 6 (6.1 - atomic-design skill)

- 5.2 [x] Update spa-init.md to check for override (Complexity: 3) [Completed: 2025-12-29]
  - **Details:** Add conditional logic to spa-init to check PRD configuration and use flat or feature-based structure if specified
  - **Acceptance:** spa-init respects componentOrganization setting
  - **Implementation Notes:** Added Step 1.5 to check PRD config, added alternate directory structures for flat and feature-based, conditional Storybook setup

- 5.3 [x] Update nextjs-init.md to check for override (Complexity: 3) [Completed: 2025-12-29]
  - **Details:** Add conditional logic to nextjs-init to check PRD configuration
  - **Acceptance:** nextjs-init respects componentOrganization setting
  - **Implementation Notes:** Added Step 1.5 to check PRD config, added alternate directory structures for flat and feature-based, conditional Storybook setup

- 5.4 [x] Update expo-init.md to check for override (Complexity: 3) [Completed: 2025-12-29]
  - **Details:** Add conditional logic to expo-init to check PRD configuration
  - **Acceptance:** expo-init respects componentOrganization setting
  - **Implementation Notes:** Added Step 1.5 to check PRD config, added alternate directory structures for flat and feature-based, conditional Storybook setup

---

## 6. [x] Developers have documentation to understand and apply atomic design

- 6.1 [x] Create atomic-design skill for React (Complexity: 5) [Completed: 2025-12-29]
  - **Details:** Create `/tech-stacks/js/react/skills/atomic-design/SKILL.md` with five-level hierarchy explanation, classification flowchart, naming conventions, import strategies, barrel export patterns, code examples for each level
  - **Acceptance:** Skill explains atomic design with practical examples and decision guides
  - **Implementation Notes:** Created detailed skill with classification flowchart, complete code examples for each atomic level, Storybook story templates, naming conventions, import strategies, barrel export patterns, and PRD override documentation

- 6.2 [x] Create atomic-design-mobile skill for React Native (Complexity: 5) [Completed: 2025-12-29]
  - **Details:** Create `/tech-stacks/js/react-native/skills/atomic-design-mobile/SKILL.md` with mobile-specific considerations: touch targets, accessibility, platform-specific code, safe areas, keyboard handling
  - **Acceptance:** Mobile skill addresses all platform-specific atomic design considerations
  - **Implementation Notes:** Created mobile-specific skill with 44pt touch targets, accessibility requirements at each level, platform-specific styling patterns, safe area handling, keyboard avoidance, and React Native Storybook templates

- 6.3 [x] Add story file templates to skills (Complexity: 3) [Completed: 2025-12-29]
  - **Details:** Include ready-to-use story templates for web and mobile in respective skills. Show Meta, StoryObj patterns, argTypes, and multiple story variants
  - **Acceptance:** Developers can copy story templates directly
  - **Implementation Notes:** Story templates included in both atomic-design and atomic-design-mobile skills with complete Meta/StoryObj patterns, argTypes configuration, and multiple story variants

- 6.4 [x] Add component classification checklist to skills (Complexity: 1) [Completed: 2025-12-29]
  - **Details:** Include the classification checklist from spec (Is it an Atom? Is it a Molecule? etc.) with clear criteria
  - **Acceptance:** Checklist helps developers quickly classify components
  - **Implementation Notes:** Classification checklist and decision flowchart included in both skills

- 6.5 [x] Document barrel export patterns (Complexity: 1) [Completed: 2025-12-29]
  - **Details:** Document the barrel export pattern at each level and top-level, including type re-exports
  - **Acceptance:** Clear examples of barrel exports for atoms, molecules, organisms, templates, and main index
  - **Implementation Notes:** Barrel export patterns documented at each atomic level with type re-exports in both skills

---

## Execution Strategy

**Recommended Approach:** Sequential
**Rationale:** Features build on each other - React foundation first, then Next.js variant, then React Native. Component builders depend on directory structure. Documentation should reflect implemented patterns.

### Sequential Execution Plan
1. Complete Feature 1 (Vite SPA atomic setup) - establishes patterns
2. Complete Feature 2 (Next.js atomic setup) - extends patterns
3. Complete Feature 3 (Expo atomic setup) - mobile adaptation
4. Complete Feature 4 (Component builders) - uses all structures
5. Complete Feature 5 (PRD override) - adds flexibility
6. Complete Feature 6 (Documentation) - documents implemented behavior
7. Final verification across all platforms

### Parallel Opportunities
- Tasks 1.1-1.4 and 2.1-2.3 could run in parallel (both React web)
- Tasks 4.1-4.2 and 4.3-4.4 could run in parallel (web vs mobile)
- Tasks 6.1-6.5 could run in parallel (independent docs)

---

## Risk Assessment

### Technical Risks
- **Storybook React 19 compatibility:** Storybook may have edge cases with React 19 features. Mitigation: Test with latest Storybook version, document known issues
- **React Native Storybook complexity:** Mobile Storybook setup is more involved than web. Mitigation: Provide detailed setup instructions, note that it's optional

### Dependencies
- React tech-stack plugin must exist (verified)
- React Native tech-stack plugin must exist (verified)
- Storybook compatibility with Vite 6.x, Next.js 15.x, Expo 52+

### Performance Considerations
- Barrel exports must support tree-shaking to avoid bundle size regression
- Init command execution should not increase by more than 2 seconds

---

## Progress Tracking

**Overall Progress:** 100% (27/27 tasks complete)

| Feature | Tasks | Complete | Progress |
|---------|-------|----------|----------|
| 1. Vite SPA Atomic Setup | 4 | 4 | 100% |
| 2. Next.js Atomic Setup | 3 | 3 | 100% |
| 3. Expo Atomic Setup | 4 | 4 | 100% |
| 4. Component Builders | 4 | 4 | 100% |
| 5. PRD Override | 4 | 4 | 100% |
| 6. Documentation | 5 | 5 | 100% |
