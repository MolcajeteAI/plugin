---
name: module-authoring
description: >-
  The module contract surface. Defines the module charter in MODULES.md
  (Responsibilities, Not responsible for, Relationships, the closed Depends on
  set), the INTERFACE.md traceability map, the DATA.md owned-store file, the
  per-property responsibility rules, and the two questions authoring must ask
  when a change does not fit the charters (orphan responsibility, undeclared
  relationship). Loaded by /m:setup, /m:spec, /m:change, /m:fix, /m:cover,
  and /m:migrate.
---

# Module Authoring

A module owns one significant responsibility end to end, and the outside world touches only its interface. This is the deep-module principle from John Ousterhout's *A Philosophy of Software Design*, applied twice. To the code: business logic that belongs to one module never appears in another, and no module touches another module's tables. To the review: the human reviews the interface and the data, never the inside.

Three artifacts carry the module contract:

| Artifact | Location | Holds |
|---|---|---|
| The module charter | `specs/MODULES.md`, one section per module | What the module does, what it does not do, and why each relationship exists |
| The interface map | `specs/modules/{module}/INTERFACE.md` | The public surface, mapped to spec IDs |
| The data file | `specs/modules/{module}/DATA.md` | The tables the module owns and how they relate |

Every identifier in these files follows the writing-style skill: name first, identifier in parentheses, and the identifier is a Markdown link to its `<a id>` anchor.

## The Module Charter (MODULES.md)

The registry table carries a `Depends on` column, and below the table each module gets a charter section with three parts:

- **Responsibilities** — what the module does, end to end. A responsibility is owned whole; no other module implements any part of it. Name the tables the module owns.
- **Not responsible for** — what the module explicitly does not do, and which module does. The Non-Goals pattern the features already use, applied to modules.
- **Relationships** — the why behind each allowed dependency, and any forbidden relationship worth naming with its reason.

The `Depends on` column in the registry table is the complete allowed set, and the world is closed: **a relationship not listed is forbidden.**

```markdown
## orders

**Responsibilities**

Order lifecycle end to end: placement, matching hand-off, expiry, cancellation. Owns the `orders` and `order_events` tables.

**Not responsible for**

Pricing — the pricing engine owns quotes and spreads. Funds — accounts owns balances and reservations; orders asks, never computes.

**Relationships**

`accounts` — reserve and release funds through its interface. `notifications` — receives OrderPlaced and OrderExpired. Never talks to `pricing` directly; matching consumes pricing, orders does not.
```

The CLI's final verification enforces all three: work outside a module's responsibilities, work inside another module's responsibilities, and any call across an undeclared relationship are all findings.

## INTERFACE.md — The Traceability Map

One file per module, three parts, in this order:

1. **A Mermaid class diagram of the public surface.** Every public element with its parameter and return types, and every one of those types with its properties. A type that an element consumes or returns appears in the diagram, connected (`..> Type : consumes`, `..> Type : returns`) — the reader sees what comes back without opening code.
2. **An element table.** One row per public element: name, kind (the transport and address — `http POST /orders`, `event order.expiry.tick`), signature, and `Covers` — links to every use case, scenario, and requirement the element serves.
3. **A types section.** Every type the interface consumes or returns gets a heading with a one-line purpose, and a table of its properties. **Every property declares its responsibility** — a column or field whose purpose nobody can state is one nobody can safely change.

The template is [INTERFACE-template.md](./templates/INTERFACE-template.md). Fill it; never compose the shape from prose memory.

This is the source map at the granularity that matters: the public surface. Change a scenario and a lookup over these tables finds every element, and through the elements every test and every file — by ID, never by regular expression. Line-level traceability already exists below it: the principles skill puts `FEAT`/`UC` comments at each file head and `SC` comments above each function. INTERFACE.md is the public layer above, and it is the layer the human reviews.

**Who maintains it.** The build maintains these files: when a task changes a public element or a type, updating the diagram, the element row, and the property table is part of the task. Authoring commands propose INTERFACE.md diffs inside `request.md`; `/m:setup` and `/m:migrate` scaffold the file.

## DATA.md — The Owned Stores

One file per module: the tables the module owns, their columns, and their relationships. Two rules make it enforceable:

- **Only the owning module touches its tables.** Every other module goes through the interface. This is the deep-module rule applied to storage, and the final verification enforces it.
- **A relationship between two modules' tables is a contract.** It appears in both DATA.md files, and changing it is a contract change.

The stores are expressed as a Mermaid entity-relationship diagram, and **every field declares its responsibility** — the quoted comment on each attribute is mandatory. After the diagram:

- **Used by** — one row per table, linking every use case that reads or writes it.
- **Relationships** — one line per cross-module relationship: `orders.account_id → accounts.accounts.id — cross-module, read through the accounts interface.`

The template is [DATA-template.md](./templates/DATA-template.md).

**Who maintains it.** Same as INTERFACE.md: the build maintains it task by task, authoring proposes diffs in the request, setup and migrate scaffold it.

## The Two Questions Authoring Must Ask

The charter creates two situations where a spec command stops and asks, through the resolution-gate machinery (`${CLAUDE_PLUGIN_ROOT}/shared/skills/resolution-gate/SKILL.md`). Both are contract decisions, so both belong to the human, and both happen at spec time — when asking is cheap — rather than mid-run.

**Orphan responsibility.** The new behavior fits no module's charter. Ask: which existing module absorbs it — the charter amendment goes into the request — or does this justify a new module? Never assign an orphan responsibility silently, because a misplaced responsibility is the seed of a shallow module.

**Undeclared relationship.** The change needs module A to call module B, and the relationship is not in A's `Depends on`. Ask: should this relationship exist — the charter addition, with its why, goes into the request — and if not, what does the design do instead? The closed-world rule only works if the moment of temptation is a question, not a shortcut.

When the *run* discovers an undeclared-relationship need mid-execution, it follows the executor's autonomy rule: decide, update the charter on the run branch, record the decision in `decisions.md`. The spec-time question is preferred; the mid-run path exists so the discovery does not halt an unattended run.

## Scaffolding at Setup

`/m:setup` creates, per module, `specs/modules/{module}/INTERFACE.md` and `specs/modules/{module}/DATA.md` from the templates. On a fresh project both start empty — diagram stub, empty tables — and fill as the build delivers elements. On an existing codebase, setup populates what it can detect and `/m:migrate` or `/m:cover` completes the extraction. The charters cannot be extracted from code — responsibilities are intent — so setup collects each module's charter from the user's description, or through a short interview when the description does not carry it.
