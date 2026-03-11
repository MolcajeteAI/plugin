# Features INDEX.md Template

Write this to `bdd/features/INDEX.md`:

```markdown
# BDD Features Index

## {Domain Name}

### [{Feature Name}]({domain}/{feature-name}.feature)
- **File:** `{domain}/{feature-name}.feature`
- **UCs:** `@uc-{UC-ID}`
- **Summary:** {1-sentence description}
- **Scenarios:**
  - {Scenario name} — {brief description}
  - {Scenario name} — {brief description}
```

Group features by their domain folder. Each feature entry lists the file path, UC references, a summary, and all scenario names with brief descriptions. The feature name links to the feature file. When the scaffold is first created, the INDEX.md will have domain headings but no feature entries yet.
