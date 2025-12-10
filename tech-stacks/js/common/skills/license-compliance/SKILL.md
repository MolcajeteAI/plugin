---
name: license-compliance
description: License checking and compatibility. Use when evaluating dependency licenses.
---

# License Compliance Skill

This skill covers license checking for npm dependencies.

## When to Use

Use this skill when:
- Evaluating new dependencies
- Auditing license compliance
- Preparing for release
- Setting up license policies

## Core Principle

**KNOW YOUR LICENSES** - Understand what licenses allow and require before adding dependencies.

## License Categories

### Permissive Licenses (Generally Safe)

| License | Commercial Use | Modification | Distribution | Attribution |
|---------|---------------|--------------|--------------|-------------|
| MIT | Yes | Yes | Yes | Yes |
| Apache-2.0 | Yes | Yes | Yes | Yes |
| BSD-2-Clause | Yes | Yes | Yes | Yes |
| BSD-3-Clause | Yes | Yes | Yes | Yes |
| ISC | Yes | Yes | Yes | Yes |
| 0BSD | Yes | Yes | Yes | No |
| Unlicense | Yes | Yes | Yes | No |

### Copyleft Licenses (Requires Review)

| License | Effect |
|---------|--------|
| GPL-2.0 | Derivative works must be GPL |
| GPL-3.0 | Derivative works must be GPL |
| LGPL-2.1 | Dynamic linking OK, static linking requires LGPL |
| LGPL-3.0 | Dynamic linking OK, static linking requires LGPL |
| AGPL-3.0 | Network use triggers copyleft |
| MPL-2.0 | File-level copyleft |

### Special Attention

| License | Notes |
|---------|-------|
| CC-BY-* | Not designed for software |
| WTFPL | May not be recognized legally |
| Proprietary | Requires explicit permission |
| No License | All rights reserved by default |

## License Checker Tool

### Installation

```bash
npm install -g license-checker
```

### Basic Usage

```bash
# List all licenses
npx license-checker

# Summary view
npx license-checker --summary

# JSON output
npx license-checker --json > licenses.json

# CSV output
npx license-checker --csv > licenses.csv
```

### Allowed Licenses Only

```bash
npx license-checker --onlyAllow "MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC;0BSD;Unlicense"
```

### Exclude Licenses

```bash
npx license-checker --excludeLicenses "GPL;AGPL"
```

## License Automation

### Pre-commit Hook

```json
{
  "husky": {
    "hooks": {
      "pre-commit": "npx license-checker --onlyAllow 'MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC'"
    }
  }
}
```

### CI Pipeline

```yaml
- name: License Check
  run: npx license-checker --onlyAllow "MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC;0BSD"
```

### Package.json Script

```json
{
  "scripts": {
    "license-check": "license-checker --onlyAllow 'MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC'"
  }
}
```

## License Policy

### Recommended Policy

```markdown
## Allowed Licenses

- MIT
- Apache-2.0
- BSD-2-Clause
- BSD-3-Clause
- ISC
- 0BSD
- Unlicense
- CC0-1.0

## Requires Review

- MPL-2.0
- LGPL-*
- EPL-*

## Not Allowed

- GPL-* (without explicit approval)
- AGPL-*
- Proprietary
- No License
```

### Policy Exceptions

Document any exceptions:

```markdown
## License Exceptions

### package-name@1.0.0
- **License**: GPL-2.0
- **Reason**: CLI tool only, not linked into our code
- **Approved By**: @legal-team
- **Date**: 2024-01-01
```

## Attribution Requirements

### MIT License Attribution

```markdown
## Third-Party Licenses

This software includes the following third-party packages:

### package-name
Copyright (c) 2024 Author Name
Licensed under the MIT License
```

### Generating Attribution

```bash
npx license-checker --production --csv --out THIRD_PARTY_LICENSES.csv
```

## License File Detection

### Common License Files

- LICENSE
- LICENSE.md
- LICENSE.txt
- COPYING
- NOTICE

### Package.json License Field

```json
{
  "license": "MIT"
}
```

### SPDX Identifiers

Use standard SPDX identifiers:
- `MIT`
- `Apache-2.0`
- `BSD-3-Clause`
- `(MIT OR Apache-2.0)` - dual license
- `UNLICENSED` - proprietary

## Handling License Issues

### Unknown License

```bash
# Investigate
npx license-checker --unknown

# Manual check
cat node_modules/package-name/LICENSE
```

### Missing License

1. Check package repository
2. Contact maintainer
3. Find alternative package
4. Get explicit permission

### License Conflict

1. Identify conflicting licenses
2. Consult legal if needed
3. Find alternative packages
4. Document decision

## SBOM Generation

### CycloneDX Format

```bash
npm install -g @cyclonedx/cyclonedx-npm
npx @cyclonedx/cyclonedx-npm --output-format JSON > sbom.json
```

### SPDX Format

```bash
npm install -g @spdx/spdx-sbom-generator
npx spdx-sbom-generator
```

## Best Practices Summary

1. **Define license policy** - Know what's allowed
2. **Check before adding** - Evaluate new dependencies
3. **Automate checking** - CI/CD license gates
4. **Document exceptions** - Track approved deviations
5. **Generate attribution** - For distribution
6. **Regular audits** - Dependencies change
7. **Create SBOM** - For compliance reporting

## Code Review Checklist

- [ ] New dependencies have allowed licenses
- [ ] License checker passes in CI
- [ ] Attribution file updated
- [ ] Exceptions documented
- [ ] No copyleft licenses (or approved)
- [ ] Package.json has valid license field
