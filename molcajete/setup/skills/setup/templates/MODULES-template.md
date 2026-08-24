# Modules

> Physical application layers that make up the system.
> Each module maps to a deployable application, service, or package.
> `Tests` is the per-module root for integration/component test files; see the testing skill's Test File Convention.
> `Driving Ports` is the comma-separated list of inbound entry-point kinds the module exposes (e.g., `http, event, cron`). The entry point a task drives must be one of these values. See the setup skill's "Driving Ports Column" rule.
> `Depends on` is the complete allowed set of modules this module may call. The world is closed: a relationship not listed is forbidden.

| ID | Module | Description | Directory | Tests | Driving Ports | Depends on |
|----|--------|-------------|-----------|-------|---------------|------------|

## {module}

**Responsibilities**

{What the module does, end to end. A responsibility is owned whole; no other module implements any part of it. Name the tables the module owns.}

**Not responsible for**

{What the module explicitly does not do, and which module does.}

**Relationships**

{The why behind each allowed dependency, and any forbidden relationship worth naming with its reason.}
