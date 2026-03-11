# Domain Categorization

Domain classification heuristic, placement plan format, and incremental growth rules for BDD features.

## Domain Classification Heuristic

For each UC in the spec, determine the target domain folder using these steps in order:

1. **Extract UC metadata:** Read the UC title, actor, and primary entities from `requirements.md`.
2. **Check existing domain folders:** Glob `bdd/features/*/` for keyword matches against the UC title, actor, or entities. If a folder name overlaps with the UC subject area, assign to that domain.
3. **Determine from subject matter:** If no existing folder matches, infer the domain from the UC's subject matter, primary actor, or core entities (e.g., an "Invoice" UC -> `billing/`, a "User Login" UC -> `authentication/`).
4. **Create domain if new:** If the inferred domain does not exist as a folder, it will be created during generation. Use kebab-case naming.
5. **Cross-functional check:** If the UC spans multiple domains with no clear primary, place it in `cross-domain/`.
6. **Multi-domain tagging:** If the UC has a clear primary domain but touches a secondary domain, place the file in the primary domain folder and add `@domain:{secondary}` tags to affected scenarios.

## Placement Plan Format

The placement plan is presented to the user via AskUserQuestion before generation begins.

```
## BDD Placement Plan

### Existing Features
| Domain | File | UCs Covered | Status |
|--------|------|-------------|--------|
| {domain} | {file}.feature | @uc-{UC-ID} | Unchanged |

### New UCs
| UC-ID | UC Title | Domain | File | Action | Scenario Count |
|-------|----------|--------|------|--------|----------------|
| {UC-ID} | {title} | {domain}/ | {file}.feature | CREATE | {count} |
| {UC-ID} | {title} | -- | -- | SKIP (covered) | -- |

### Cross-Functional Coverage
| NFR | Type | Target | Tag |
|-----|------|--------|-----|
| {NFR title} | Universal | cross-domain/{file}.feature | @nfr |
| {NFR title} | Scoped | {domain}/{file}.feature | @nfr |

### Totals
- UCs to create: {count}
- UCs skipped (already covered): {count}
- Cross-functional files: {count}
- Total new scenarios: {count}
```

## Incremental Growth

When generating BDD for a spec folder that already has partial coverage:

1. Read `bdd/features/INDEX.md` for existing `@uc-{UC-ID}` references.
2. For each UC in `requirements.md`, check if it already has a feature file (UC coverage dedup from `references/task-tagging.md`).
3. **SKIP** UCs that are already covered -- do not modify their existing feature files.
4. **CREATE** feature files only for uncovered UCs.
5. Place new files in existing domain directories when the domain matches. Do not reorganize existing files.

## Cross-Functional Placement

### Universal NFRs

NFRs that apply across all domains (e.g., "All API responses must include request-id header", "All mutations must emit audit events") get:

1. A dedicated feature file in `cross-domain/` (e.g., `cross-domain/audit-logging.feature`).
2. `@nfr` tag on the Feature line.
3. Scenarios that validate the NFR across representative domains.

### Scoped NFRs

NFRs that apply to specific domains or UCs (e.g., "Password reset tokens expire after 30 minutes") get:

1. `And` assertion steps appended to relevant scenarios in the domain feature file.
2. `@nfr` tag on affected scenarios.
3. No separate feature file -- the assertions live where the behavior is tested.
