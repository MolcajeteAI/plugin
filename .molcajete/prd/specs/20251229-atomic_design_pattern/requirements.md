# Atomic Design Pattern for React Tech-Stacks - Requirements

**Created:** 2025-12-29
**Last Updated:** 2025-12-29
**Status:** Draft

## Overview

This feature integrates the Atomic Design Pattern into the React and React Native tech-stack plugins, establishing a default component organization hierarchy (Atoms, Molecules, Organisms, Templates, Pages) that promotes reusability, consistency, and scalability across projects. The implementation includes Storybook integration for Atoms, Molecules, and Organisms to provide living documentation and component testing.

Atomic Design is a methodology created by Brad Frost that organizes UI components into five distinct levels based on their complexity and composition. By implementing this pattern as the default in our tech-stack plugins, developers using Molcajete.ai will benefit from a consistent, battle-tested approach to component architecture that scales from simple applications to complex enterprise systems.

## User Stories

### Primary User Story
**As a** developer using the React or React Native tech-stack
**I want** a clear, organized component hierarchy following Atomic Design principles
**So that** I can build scalable, maintainable UI components with consistent patterns

**Acceptance Criteria:**
- [ ] New projects created with `spa-init`, `nextjs-init`, or `expo-init` include the atomic directory structure
- [ ] Component-builder agent provides guidance on which atomic level to use
- [ ] Skills documentation explains the five-level hierarchy with examples
- [ ] Barrel exports (index.ts files) enable clean imports across levels

### Additional User Story: Storybook Integration
**As a** developer building UI components
**I want** Storybook stories automatically configured for Atoms, Molecules, and Organisms
**So that** I can document, test, and showcase components in isolation

**Acceptance Criteria:**
- [ ] Storybook is set up as part of init commands
- [ ] Story files follow a consistent template
- [ ] Stories are organized by atomic level in Storybook sidebar
- [ ] Autodocs are enabled for component documentation

### Additional User Story: Project Flexibility
**As a** developer with existing project conventions
**I want** the ability to opt out of Atomic Design or use alternative organization
**So that** I can maintain consistency with my team's established patterns

**Acceptance Criteria:**
- [ ] PRD can specify `componentOrganization: flat` to disable atomic structure
- [ ] PRD can specify `componentOrganization: feature-based` for alternative organization
- [ ] Init commands respect the PRD configuration
- [ ] Documentation explains override mechanism

## Functional Requirements

### Core Functionality

1. **Atomic Directory Structure:** The tech-stack plugins must create the following directory hierarchy by default:
   - `components/atoms/` - Basic building blocks (Button, Input, Label, Icon, Text, Image)
   - `components/molecules/` - Functional units combining atoms (SearchForm, InputGroup, Card)
   - `components/organisms/` - Complex UI sections (Header, Footer, Navigation, Sidebar)
   - `components/templates/` - Page-level layout structures (MainLayout, DashboardLayout)
   - `pages/` or `app/` - Specific template instances with real content

2. **Atomic Design Skill:** Create new skill files that provide:
   - Detailed explanation of each atomic level
   - Decision guide for classifying components
   - Code examples for each level
   - Best practices and naming conventions
   - Barrel export patterns

3. **Init Command Updates:** Update initialization commands to:
   - Create the atomic directory structure
   - Generate index.ts barrel export files
   - Set up Storybook with atomic-level organization
   - Create example components at each level (optional)

4. **Component Builder Agent Updates:** Update the component-builder agent to:
   - Ask or determine which atomic level the new component belongs to
   - Place files in the correct directory
   - Generate appropriate Storybook story for Atoms/Molecules/Organisms
   - Follow naming conventions for the level

5. **Storybook Configuration:** Configure Storybook to:
   - Include stories from atoms, molecules, and organisms directories
   - Organize sidebar by atomic level (Atoms/, Molecules/, Organisms/)
   - Enable autodocs for automatic documentation
   - Include accessibility and viewport addons

### Edge Cases

- **Existing Projects:** When running init on a project with existing components, warn user and offer migration guidance
- **Component Misclassification:** If a component outgrows its level (e.g., an atom gains state), provide refactoring guidance
- **Empty Levels:** Some projects may not need all levels; do not require components at every level

### Business Rules

- **Storybook Scope:** Only Atoms, Molecules, and Organisms get Storybook stories; Templates and Pages do not
- **State Management:** Atoms should be stateless or have only UI state; state increases as you go up the hierarchy
- **Composition Direction:** Higher levels compose lower levels (Molecules use Atoms, Organisms use Molecules/Atoms)

## Non-Functional Requirements

### Performance
- **Init Time:** Adding atomic structure should not significantly increase init command execution time (< 2 seconds additional)
- **Import Performance:** Barrel exports must not cause bundle size issues (support tree-shaking)

### Security
- Not applicable - this feature is about code organization patterns

### Usability
- **Discoverability:** Component locations should be intuitive and match Atomic Design mental model
- **Documentation:** In-skill examples should be copy-paste ready
- **Error Messages:** Clear guidance when components are placed in wrong directory

### Reliability
- **Backward Compatibility:** Existing projects not using atomic structure should continue to work
- **Cross-Platform:** Skills and patterns must work for both React (web) and React Native (mobile)

## Constraints

### Technical Constraints
- Must integrate with existing tech-stack plugin architecture
- Must work with Vite (React SPA), Next.js (React SSR), and Expo (React Native)
- Must maintain compatibility with TypeScript strict mode
- Storybook version must be compatible with React 19 and React Native

### Business Constraints
- Implementation should reuse existing skill structure patterns
- Must follow Molcajete.ai documentation standards

### Resource Constraints
- Single developer implementation
- Should be completable in reasonable timeframe (vertical feature approach)

## Assumptions

- Developers are familiar with or willing to learn Atomic Design concepts
- Projects use TypeScript (the tech-stacks already assume TypeScript)
- Storybook is a welcome addition (can be opted out via PRD)
- The five-level hierarchy is sufficient for most applications

## Out of Scope

Explicitly state what this feature will NOT include:

- **Component Library Generation:** We provide patterns and structure, not pre-built component libraries
- **Design Token System:** Atomic Design is about component hierarchy, not design tokens (separate concern)
- **Automated Component Classification:** AI will not auto-detect which level a component belongs to
- **Component Migration Tools:** No automated migration of existing flat structures to atomic
- **Custom Atomic Levels:** We implement standard five-level hierarchy only; no custom levels
- **Storybook Addons Beyond Core:** Only essential addons (a11y, viewport); no advanced addons

## Open Questions

- **Question 1:** Should example components be generated by init commands or kept minimal?
  - **Status:** Deferred
  - **Default:** Minimal - create directories and index files only; examples in documentation

- **Question 2:** Should there be a command to generate components at specific atomic levels?
  - **Status:** Deferred
  - **Answer:** Defer to component-builder agent; consider future `/react-component --level=atom` command

## Visual References

- **Mockups:** N/A - this is a code organization feature
- **Wireframes:** Directory structure diagrams in research document
- **Design System:** N/A
- **Similar Implementations:** Brad Frost's Atomic Design book and patternlab.io

## Dependencies

### Technical Dependencies
- React tech-stack plugin must exist (completed)
- React Native tech-stack plugin must exist (completed)
- JavaScript common skills must exist (completed)

### External Dependencies
- Storybook compatibility with React 19 (verify during implementation)
- Storybook React Native support for Expo (verify during implementation)

## Success Criteria

How will we know this feature is successful?

### User Success
- Developers can create new projects with organized component structure in under 1 minute
- Developers can find components by name and purpose using atomic hierarchy
- Developers can add Storybook stories following provided templates

### Business Success
- Reduced "where should I put this component" decisions
- Consistent component organization across all Molcajete.ai React projects
- Living documentation via Storybook for all reusable components

### Technical Success
- All init commands create atomic structure without errors
- Skill files provide sufficient guidance for component classification
- Barrel exports work correctly with tree-shaking
- Storybook builds and runs without configuration issues

---

## Implementation Scope (MVP)

### Phase 1: Core Structure (MVP)
1. Create `atomic-design` skill for React tech-stack
2. Create `atomic-design-mobile` skill for React Native tech-stack
3. Update `spa-init.md` command to create atomic directories
4. Update `nextjs-init.md` command to create atomic directories
5. Update `expo-init.md` command to create atomic directories

### Phase 2: Agent Integration
6. Update `component-builder.md` agent (React) with atomic level guidance
7. Update `component-builder.md` agent (React Native) with atomic level guidance

### Phase 3: Storybook Integration
8. Add Storybook setup instructions to React init commands
9. Add Storybook setup instructions to React Native init commands
10. Provide story file templates in skills

### Phase 4: PRD Override
11. Document `componentOrganization` override in PLUGIN.md files
12. Update init commands to check PRD settings

### Future Enhancements
- Generate example components at each level (optional feature)
- `/react-component --level=atom` command for scaffolding
- Component migration guide for existing projects
