---
description: Break specification into actionable, prioritized tasks organized by features
---

**Note:** The {spec-name} should be the timestamped directory name (e.g., `2025-11-12-feature-name`) created by previous commands.

IMPORTANT: Immediately use the Task tool with subagent_type="prd:task-planner" to delegate ALL work to the task-planner agent. Do NOT do any analysis or work in the main context.

Use this exact prompt for the agent:
"Execute the task planning workflow following these steps:

1. **Verify Prerequisites**
   - Check if spec name is provided
   - If not provided, use AskUserQuestion to ask:
     - Question: \"Which spec should I create tasks for?\"
     - Header: \"Spec Name\"
     - Options: [User can type in Other field]

2. **Read All Context**
   - Read product context files:
     - .molcajete/prd/PRD.md
     - .molcajete/prd/mission.md
     - .molcajete/prd/tech-stack.md
   - Read the specification:
     - .molcajete/prd/specs/{spec-name}/spec.md
   - If spec.md doesn't exist, return error message:
     ```
     Error: Specification not found.

     Please run /prd:write-spec {spec-name} first to create the specification.
     ```

3. **Identify Sequential Steps for Working Software**
   - Follow the **task-breakdown** skill methodology exactly
   - Think vertically through all layers for each feature (NOT horizontally)
   - Organize tasks so each step produces working software
   - For each task, ask: 'After this task, is the user one step closer to using this feature?'
   - Shortest path to working software is the guiding principle

4. **Organize Tasks Into Features**
   - Each feature delivers complete, user-facing functionality
   - Each feature works across all layers (vertical, not horizontal)
   - Each feature can be tested end-to-end
   - Feature boundaries should enable iterative delivery
   - Good: \"Users can sign up for an account\"
   - Bad: \"All database migrations\"

5. **Estimate Complexity**
   - Use story points from task-breakdown skill:
     - 1 point: Simple, well-understood, minimal dependencies
     - 3 points: Medium complexity, some unknowns
     - 5 points: High complexity, many unknowns
     - 8 points: Very complex (break down further if possible)
   - Flag tasks larger than 8 points as needing breakdown

6. **Analyze Dependencies**
   - Identify blockers (what must be done before this task)
   - Note what each task enables
   - Flag parallel opportunities (tasks with no dependencies)
   - Identify critical path (longest chain of dependent tasks)

7. **Generate Tasks Document**
   - Follow task-breakdown skill template exactly
   - Include all required sections:
     - Overview (feature description, strategic alignment, success criteria, estimated effort, key risks)
     - Features (organized vertically with progress tracking)
     - Task Breakdown (numbered tasks with checkboxes, complexity, dependencies, acceptance)
     - Execution Strategy (sequential vs parallel approach)
     - Risk Assessment (technical risks, dependencies, performance, security)
     - Progress Tracking (overall progress percentage)

8. **RETURN Complete Content**
   - DO NOT attempt to write files - main context will handle file operations
   - Return in your final response:
     - The complete tasks.md content
     - The roadmap update needed (what to change in roadmap.md)
   - Format as:
     ```
     === TASKS CONTENT ===
     [full tasks.md content]

     === ROADMAP UPDATE ===
     [description of changes to make to roadmap.md]
     ```

Follow your agent instructions in agents/task-planner.md and reference the task-breakdown skill for all methodology and templates."

## After Agent Returns

Once the agent provides the tasks content:

1. **Write tasks.md file:**
   Use Write tool to create `.molcajete/prd/specs/{spec-name}/tasks.md` with the content returned by the agent

2. **Update roadmap:**
   Use Edit tool to update `.molcajete/prd/roadmap.md` with the changes specified by the agent

3. **Inform user:**
   ```
   Created task breakdown: .molcajete/prd/specs/{spec-name}/tasks.md
   Updated roadmap status to "Ready for Implementation"

   Next step: Run /prd:execute-tasks {spec-name} to begin implementation
   ```
