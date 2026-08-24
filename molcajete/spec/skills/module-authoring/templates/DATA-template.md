# Data — {module}

```mermaid
erDiagram
    {table} {
        {type} {column} PK "{The column's responsibility — mandatory on every attribute}"
        {type} {column} FK "{The column's responsibility; name the interface a cross-module read goes through}"
        {type} {column} "{The column's responsibility}"
    }
    {table} ||--o{ {other_table} : "{what the relationship carries}"
```

## Used by

| Table | Used by |
|---|---|
| `{table}` | [{UC-XXXX}](../../features/{module}/{FEAT-XXXX-slug}/{UC-XXXX-slug}.md#{UC-XXXX}) |

## Relationships

- `{table}.{column} → {other-module}.{table}.{column}` — cross-module, read through the {other-module} interface.
