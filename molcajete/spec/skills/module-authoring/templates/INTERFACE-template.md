# Interface — {module}

```mermaid
classDiagram
    class {module} {
        +{elementName}({param}: {ParamType}) {ReturnType}
    }
    class {ParamType} {
        +{property}: {type}
    }
    class {ReturnType} {
        +{property}: {type}
    }
    {module} ..> {ParamType} : consumes
    {module} ..> {ReturnType} : returns
```

## Elements

| Element | Kind | Signature | Covers |
|---|---|---|---|
| `{elementName}` | {http `POST /path` \| event `topic.name` \| cli `command` \| ...} | `({param}: {ParamType}) => Promise<{ReturnType}>` | [{UC-XXXX}](../../features/{module}/{FEAT-XXXX-slug}/{UC-XXXX-slug}.md#{UC-XXXX}), [{SC-XXXX-NN}](../../features/{module}/{FEAT-XXXX-slug}/{UC-XXXX-slug}.md#{SC-XXXX-NN}) |

## Types

### `{ParamType}` — {one-line purpose of the type}

| Property | Type | Responsibility |
|---|---|---|
| `{property}` | `{type}` | {What the property is for, and any validation or constraint that governs it} |
