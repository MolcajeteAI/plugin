# Task Update Protocol

Standardized procedure for updating tasks, changelogs, and progress tracking after implementation. This protocol is used by commands (`/m:dev`, `/m:fix`) to ensure consistent progress recording.

## Task Completion (Used by /m:dev)

After a task passes all quality gates, update these files in order:

### 1. Update tasks.md

Mark the task checkbox as complete and add completion metadata:

```markdown
- [x] N.M {Task title}
  - Complexity: {points}
  - Dependencies: {deps}
  - Acceptance: {criterion}
  - Completed: {YYYY-MM-DD}
  - Notes: {brief description of approach, key decisions, files created/modified}
```

If all sub-tasks under a parent task are complete, also mark the parent:

```markdown
- [x] N. {Parent task title}
  - [x] N.1 {Sub-task}
    - ...
    - Completed: 2026-02-14
  - [x] N.2 {Sub-task}
    - ...
    - Completed: 2026-02-14
```

### 2. Write Per-Task Changelog

Get a UTC timestamp by running `date -u +%Y%m%d-%H%M`. Create `prd/specs/{feature}/plans/{timestamp}-changelog-UC-{tag}-NNN--N.M.md` with:

```markdown
# Changelog: UC-{tag}-NNN/N.M — {Task title}

## What Was Implemented
{Description of the implementation}

## Key Decisions
- {Decision 1 and rationale}
- {Decision 2 and rationale}

## Files Created
- {path/to/file.ext}

## Files Modified
- {path/to/file.ext}

## Requirement IDs Delivered
- FR-{tag}-NNN: {requirement title}
```

### 3. Update Main Changelog

Append to `prd/changelog.md` under today's date heading:

```markdown
## {YYYY-MM-DD}

- [{HH:MM}] {Change title}
  {One-line description of what was built.}
  - Plan: [{timestamp}-{plan-filename}](specs/{feature-folder}/plans/{timestamp}-{plan-filename})
  - Changelog: [{timestamp}-{changelog-filename}](specs/{feature-folder}/plans/{timestamp}-{changelog-filename})
```

Get the current UTC time by running `date -u +%H:%M` for the entry timestamp. Get a UTC timestamp by running `date -u +%Y%m%d-%H%M` for filenames.

## Fix Notes (Used by /m:fix)

Fixes do NOT mark task checkboxes. Instead, they append fix notes.

### 1. Update tasks.md (Fix Note Only)

Append a fix note under the relevant task entry:

```markdown
- [x] N.M {Task title}
  - Complexity: {points}
  - Dependencies: {deps}
  - Acceptance: {criterion}
  - Completed: 2026-02-10
  - Notes: {original implementation notes}
  - Fix ({YYYY-MM-DD}): {brief description of what was fixed and why}
```

### 2. Write Per-Fix Changelog

Get a UTC timestamp by running `date -u +%Y%m%d-%H%M`. Create `prd/specs/{feature}/plans/{timestamp}-changelog-fix-{slug}.md` with:

```markdown
# Fix Changelog: {Fix title}

## Root Cause
{What was wrong and why}

## What Was Fixed
{Description of the fix}

## Files Modified
- {path/to/file.ext}

## Requirement IDs Affected
- FR-{tag}-NNN: {requirement title}
```

### 3. Update Main Changelog

Same format as task completion, but with "Fix" prefix in the title:

```markdown
- [{HH:MM}] Fix {description}
  {One-line description of what was fixed.}
  - Plan: [{timestamp}-{plan-filename}](specs/{feature-folder}/plans/{timestamp}-{plan-filename})
  - Changelog: [{timestamp}-{changelog-filename}](specs/{feature-folder}/plans/{timestamp}-{changelog-filename})
```
