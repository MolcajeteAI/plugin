# Agent Invocation Template

Standard prompt structure for launching an agent via the Task tool.

## Template

When invoking an agent, construct the prompt using this structure:

```
You are the {Agent Name} agent.

Read your agent definition for full responsibilities, boundaries, and quality standards:
- Read: {agent definition path}

## Skills to Load

### Primary
{List primary skill paths from the agent definition}

### Discovered
{List any runtime-discovered skill paths, or "None"}

## Task Context

{Brief from the command: what needs to be done, which files are involved, acceptance criteria}

## Input from Previous Agent

{Output from the previous agent in the chain, or "N/A — first agent in chain"}

## Constraints

- Model: {agent's declared model}
- Scope: {what the agent should and should not touch}
- Output: Return results in the format specified in your agent definition's Output Format section
```

## Example: Invoking the Developer Agent

```
You are the Developer agent.

Read your agent definition for full responsibilities, boundaries, and quality standards:
- Read: ${CLAUDE_PLUGIN_ROOT}/agents/developer.md

## Skills to Load

### Primary
- ${CLAUDE_PLUGIN_ROOT}/skills/software-principles/SKILL.md
- ${CLAUDE_PLUGIN_ROOT}/skills/dev-workflow/SKILL.md

### Discovered
- ${CLAUDE_PLUGIN_ROOT}/skills/go-writing-code/SKILL.md

## Task Context

Task ID: UC-0Fy0-001/1.1
Title: Create patient generals form with GraphQL mutation
Plan: prd/specs/20260212-1500-patient_onboarding/plans/task-UC-0Fy0-001--1.1.md
Acceptance: Form submits patient generals data via CreatePatientGenerals mutation

## Input from Previous Agent

N/A — first agent in chain

## Constraints

- Model: sonnet
- Scope: Only implement task UC-0Fy0-001/1.1. Do not modify files outside the plan.
- Output: Return results in the format specified in your agent definition's Output Format section
```

## Example: Invoking the Reviewer After Developer

```
You are the Reviewer agent.

Read your agent definition for full responsibilities, boundaries, and quality standards:
- Read: ${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md

## Skills to Load

### Primary
- ${CLAUDE_PLUGIN_ROOT}/skills/software-principles/SKILL.md

### Discovered
- ${CLAUDE_PLUGIN_ROOT}/skills/react-writing-code/SKILL.md

## Task Context

Task ID: UC-0Fy0-001/1.1
Title: Create patient generals form with GraphQL mutation
Acceptance: Form submits patient generals data via CreatePatientGenerals mutation

## Input from Previous Agent

RESULT: SUCCESS
TASK_ID: UC-0Fy0-001/1.1
SUMMARY: Created PatientGeneralsForm component with CreatePatientGenerals mutation
FILES_CREATED: [patient/src/components/organisms/PatientGeneralsForm/index.tsx, patient/src/components/organisms/PatientGeneralsForm/__tests__/PatientGeneralsForm.test.tsx]
FILES_MODIFIED: [server/internal/patient/graph/schema.graphqls]
KEY_DECISIONS: ["Used controlled form pattern with react-hook-form"]
TESTS_WRITTEN: 5
TESTS_PASSED: 5
TESTS_FAILED: 0
BDD_TASK_STATUS: PASS
BDD_FEATURE_STATUS: N/A
FORMAT_STATUS: PASS
LINT_STATUS: PASS
ISSUES: NONE

## Constraints

- Model: opus
- Scope: Review all files created/modified above. Do not modify code.
- Output: Return results in the format specified in your agent definition's Output Format section
```
