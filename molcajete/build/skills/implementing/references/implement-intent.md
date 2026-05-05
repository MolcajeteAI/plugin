# Implement Intent -- Specs First (Greenfield)

Implementation procedure for tasks with `intent: "implement"`. Specs drive code creation. Two phases: production code first, then step definitions.

## Phase A: Production Code

1. **Read Gherkin** -- Read the `.feature` file content to understand what scenarios assert. Every scenario in the file belongs to the task's UC; the task's `@SC-XXXX` identifies the specific scenario in scope.

2. **Read plan narrative** -- Read the plan.md `### T-NNN` section for "What changes", "Important snippets", and "Files to create/modify". This is the implementation-intent authority.

3. **Implement production code** -- Follow project conventions. Let the Gherkin assertions guide what the code needs to do. Create files listed in `files_to_modify`, respecting the order.

4. **Write unit tests** -- Write unit tests for the implemented code. Focus on the logic that the Gherkin scenarios exercise.

5. **Run unit tests and fix failures** -- Execute unit tests and fix any failures.

   **Infrastructure issues are NOT your problem.** If you encounter connection refused, services not running, database unreachable, missing system tools, or similar infrastructure errors: stop, surface the issue to the user via AskUserQuestion, and let them decide how to proceed. Do NOT attempt to fix Dockerfiles, docker-compose files, .env files, or system configuration.

   **Project dependencies ARE your responsibility.** Adding missing packages (npm install, pip install, cargo add) is fine when the dependency is needed for code you are writing.

6. **Self-review** -- Run `git diff` and check for:
   - Debug statements (console.log, print, debugger)
   - Commented-out code
   - Hardcoded secrets or credentials
   - TODO placeholders that should have been filled in
   - Obvious logic errors

## Phase B: Step Definitions

1. **Extract step patterns** -- Read the Gherkin `.feature` file and extract all Given/When/Then/And step patterns for `task.scenario` (the `@SC-XXXX` scenario in scope).

2. **Check for existing steps** -- Read `bdd/steps/INDEX.md` (if it exists) and check for existing reusable step definitions that match or can be parameterized to match.

3. **Determine placement** -- For each new step pattern without an existing match, determine which step file it belongs in:

   | Category | File | When to use |
   |----------|------|-------------|
   | Common | `common_steps.{ext}` | Generic steps: login, navigation, time, basic CRUD |
   | API | `api_steps.{ext}` | HTTP request/response steps |
   | Database | `db_steps.{ext}` | Database assertion steps |
   | Module-specific | `{module}_steps.{ext}` | Steps unique to a business module |

4. **Create or append** -- Create new step definition files or append to existing ones. Follow the gherkin skill's step writing rules.

5. **Implement with real logic** -- Each step definition must use real assertion logic referencing the production code just written in Phase A. Read the production code to understand actual selectors, API paths, and function signatures.

   Rules for step definitions:
   - All steps assume end-to-end execution -- real state, real actions, real assertions. Never reference mocks, stubs, fakes, or spies.
   - Given steps describe state declaratively (`Given user alice is logged in`), not procedures.
   - When/Then steps narrate the actor's experience, not internal system behavior.
   - Every `Then` step asserts a specific, deterministic value. Never use "more than", "approximately", "non-zero", "some", "any".
   - Before creating any step, check `bdd/steps/INDEX.md` for existing reusable patterns -- reuse over recreate.

6. **Update INDEX** -- Update `bdd/steps/INDEX.md` with any new step definitions added.
