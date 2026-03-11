# State Validation Patterns

Generic Gherkin-level step patterns for validating state changes and side effects.

## Principle

Business language in Gherkin, technical assertions in step definitions. BDD scenarios validate behavior including state changes and side effects -- they replace the need for separate integration tests.

## Generic Step Patterns

| Category | Pattern | Step File |
|----------|---------|-----------|
| DB existence | `Then a {entity} record should exist where {condition}` | `db_steps` |
| DB count | `Then there should be {count} {entity} records where {condition}` | `db_steps` |
| DB content | `Then the {entity} record should have:` (DataTable) | `db_steps` |
| DB absence | `Then no {entity} record should exist where {condition}` | `db_steps` |
| File existence | `Then a file should exist at {path}` | `fs_steps` |
| File absence | `Then no file should exist at {path}` | `fs_steps` |
| File content | `Then the file at {path} should contain {content}` | `fs_steps` |
| Queue message | `Then a message should be published to the {queue} queue` | `queue_steps` |
| Queue content | `Then the {queue} message should contain {field} with value {value}` | `queue_steps` |
| Queue count | `Then {count} messages should be published to the {queue} queue` | `queue_steps` |
| Audit log | `Then an audit event should be recorded with type {type}` | `common_steps` |
| Cache state | `Then the {store} should contain key {key} with value {value}` | `common_steps` |
| Cache absence | `Then the {store} should not contain key {key}` | `common_steps` |

## DataTable Examples

Use DataTables for structured multi-field record assertions:

```gherkin
Then the user record should have:
  | field      | value              |
  | email      | alice@example.com  |
  | status     | active             |
  | role       | admin              |

Then the order record should have:
  | field      | value    |
  | status     | shipped  |
  | total      | 94.00    |
  | currency   | USD      |
```

## Technology-Agnostic Note

These are Gherkin-level patterns only. The step definitions that implement these patterns are project-specific and depend on the actual database client, file system API, message queue library, and caching layer used by the project. The patterns define **what** to assert, not **how** to assert it.
