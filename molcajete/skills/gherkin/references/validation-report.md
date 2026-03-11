# Validation Report

Format and generation rules for BDD validation reports. Used by `/m:dev` quality gate and the coordinator's final status report.

## Report Structure

A validation report has three sections: summary, coverage by feature, and traceability matrix.

### Summary Table

| Metric | Value |
|--------|-------|
| Total scenarios | {count} |
| Passed | {count} |
| Failed | {count} |
| Skipped | {count} |
| Pass rate | {percentage} |
| Duration | {seconds} |

### Coverage by Feature

| Feature File | UC | Scenarios | Passed | Failed | Skipped |
|-------------|-----|-----------|--------|--------|---------|
| `auth/login.feature` | UC-0Fy0-001 | 8 | 8 | 0 | 0 |
| `billing/checkout.feature` | UC-0Fy0-002 | 5 | 4 | 1 | 0 |

### Traceability Matrix

Maps requirements to BDD scenarios to verify coverage completeness.

| Requirement | Task | Scenario | Status |
|------------|------|----------|--------|
| FR-0Fy0-001 | UC-0Fy0-001/1.1 | Login with valid credentials | PASS |
| FR-0Fy0-001 | UC-0Fy0-001/1.2 | Login with invalid password | PASS |
| FR-0Fy0-002 | UC-0Fy0-002/1.1 | Checkout with valid card | FAIL |

## Tag-to-Requirement Mapping

The traceability matrix is built from BDD tags:

- `@uc-{UC-ID}` on Feature lines maps scenarios to use cases
- `@task-{ID}` on Scenario lines maps scenarios to specific tasks
- Requirements are resolved by reading `requirements.md` and matching UC IDs to FR IDs

### Resolution Algorithm

1. Parse BDD runner JSON output for scenario results with tags
2. For each scenario, extract `@uc-{UC-ID}` from the parent feature and `@task-{ID}` from the scenario
3. Read `requirements.md` and build a map: UC-ID -> list of FR-IDs
4. Join scenario results with the UC-to-FR map to produce the traceability matrix

## Generation from BDD Runner Output

Each BDD framework produces JSON output that can be parsed into the report format.

### behave (Python)

```bash
behave --format json --outfile bdd/reports/results.json bdd/features/
```

Parse `results.json`: each element has `name`, `status`, `tags[]`, and `elements[]` (scenarios with `status` and `tags[]`).

### godog (Go)

```bash
godog --format cucumber --output bdd/reports/results.json bdd/features/
```

Same Cucumber JSON format as behave.

### cucumber-js (TypeScript)

```bash
npx cucumber-js --format json:bdd/reports/results.json bdd/features/
```

Same Cucumber JSON format.

### Parsing Logic

All three frameworks produce Cucumber-compatible JSON:

```
[
  {
    "name": "Feature name",
    "tags": [{"name": "@uc-UC-0Fy0-001"}],
    "elements": [
      {
        "name": "Scenario name",
        "tags": [{"name": "@task-UC-0Fy0-001--1.1"}, {"name": "@smoke"}],
        "steps": [
          {"result": {"status": "passed", "duration": 123456}}
        ]
      }
    ]
  }
]
```

A scenario's status is:
- **passed** if all steps passed
- **failed** if any step failed
- **skipped** if any step was skipped and none failed

## Usage

### In `/m:dev` Quality Gate (Step 8)

After running the full feature BDD suite (`--tags=@uc-{UC-ID}`), generate the validation report. If any scenarios failed, the quality gate fails and the Developer must fix the production code.

### In Coordinator Final Status

After all tasks complete, the coordinator runs the full BDD suite (no tag filter) and generates the validation report as the final deliverable. The traceability matrix confirms which requirements are covered.
