---
id: UC-XXXX-NNN
name: kebab-case-name
use_case: UC-XXXX
feature: FEAT-XXXX
objective: implement
files:
  create: [path/to/new-file]
  modify: []
depends_on: []
provides: [namedExport]
entry_type: http
covers: [SC-XXXX]
last_update: YYYY-MM-DD
---

# UC-XXXX-NNN: {Slice Name}

## Rationale

{One paragraph: what this slice does, why it exists, which scenarios it closes. Plain prose, no implementation detail.}

## Contracts

The locked surface for this slice. Pinned at spec time so independent slice runs stay consistent. The CodeWriter implements against these; it does not redesign them.

Use whichever flavors apply, skip the rest. Replace `{contract-lang}` with the project's contract language (`typescript`, `python`, `go`, etc.).

### Types

```{contract-lang}
// Data shape declarations only — no implementation, no runtime values.

{example: an interface, a TypedDict, a Go interface declaration, a JSON schema, etc.}
```

### API Surface

For function-shaped APIs:

| Name | Signature | Auth | Notes |
|------|-----------|------|-------|
| `exampleEntry` | `(input: ExampleInput) => Promise<ExampleResponse>` | none | {edge cases} |

For HTTP routes, swap the columns:

| Method | Path | Request | Response | Status codes |
|--------|------|---------|----------|--------------|

For event handlers / message dispatch, use the column set that fits the project's transport.

### Behavior

- **Preconditions:** {what must hold before any `provides` export is called}
- **Postconditions:** {what holds after a successful call}
- **Invariants:** {what must always hold while this slice's code runs}
- **Error modes:** {named failure cases downstream slices can rely on}

## Tests

Nested-bullet test plan. Each leaf is one assertion. The CodeWriter translates this list into actual test code in the project's runner — top-level bullets become outermost `describe` blocks (or the runner-equivalent), nesting becomes nested `describe` blocks, leaves become `it` blocks.

- **SC-XXXX: {scenario name}**
  - Given {context setup}
    - When {action}
      - Then {expected outcome / assertion}
      - And {additional assertion}
  - Given {different context}
    - When {action}
      - Then {expected outcome}
- **FR-XXXX: {requirement label}**
  - {top-level assertion that ties to the requirement}
