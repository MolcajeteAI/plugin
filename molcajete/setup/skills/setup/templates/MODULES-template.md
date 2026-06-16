# Modules

> Physical application layers that make up the system.
> Each module maps to a deployable application, service, or package.
> `Tests` is the per-module root for integration/component test files; see the slicing skill's Test File Convention.
> `Driving Ports` is the comma-separated list of inbound entry-point kinds the module exposes (e.g., `http, event, cron`). Each slice's `entry_type` must be one of these values. See the setup skill's "Driving Ports Column" rule.

| ID | Module | Description | Directory | Tests | Driving Ports |
|----|--------|-------------|-----------|-------|---------------|
