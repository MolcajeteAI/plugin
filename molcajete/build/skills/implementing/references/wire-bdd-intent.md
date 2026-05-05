# Wire-BDD Intent -- Code First (Brownfield)

Implementation procedure for tasks with `intent: "wire-bdd"`. BDD wiring for existing code. Single phase: step definitions only. Production code is NOT modified.

## Single Phase: Step Definitions

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

5. **Read existing application code** -- Use the ARCHITECTURE.md Code Map section or the task description to locate relevant production code. Read the actual implementation to understand selectors, API paths, function signatures, and data shapes.

6. **Implement step definitions** -- Each step definition must call real application code and assert real behavior:
   - Given steps set up real state by calling application setup functions or APIs
   - When steps invoke real application actions
   - Then steps assert against real application responses or state

   Rules:
   - All steps assume end-to-end execution -- real state, real actions, real assertions. Never reference mocks, stubs, fakes, or spies.
   - Given steps describe state declaratively, not procedures.
   - When/Then steps narrate the actor's experience, not internal system behavior.
   - Every `Then` step asserts a specific, deterministic value.
   - Before creating any step, check `bdd/steps/INDEX.md` for existing reusable patterns.

7. **Do NOT modify production code** -- This intent wires BDD to existing code. If production code changes are needed, that is a separate task with `implement` intent.

8. **Update INDEX** -- Update `bdd/steps/INDEX.md` with any new step definitions added.
