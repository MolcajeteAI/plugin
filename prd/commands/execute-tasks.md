---
description: Orchestrate task implementation with specialized stack-specific subagents
---

**Note:** The {spec-name} should be the timestamped directory name (e.g., `20251112-feature_name`) created by previous commands.

IMPORTANT: Immediately use the Task tool with subagent_type="prd:orchestrator" to delegate ALL work to the orchestrator agent. Do NOT do any analysis or work in the main context.

Use this exact prompt for the agent:
"Execute the task orchestration workflow following these steps:

**CRITICAL SCOPE CONTROL:**
- ONLY execute the specific tasks that are explicitly requested
- If user specifies task IDs (e.g., \"complete task 1.1\" or \"implement Feature 2\"), execute ONLY those tasks
- STOP immediately after completing the requested tasks - DO NOT continue to other tasks
- DO NOT assume you should build everything - ask if unclear about scope
- Completing more than requested wastes time and violates user intent

**IMPORTANT: You CANNOT write files due to subagent limitations. Track all changes and return them to main context for file updates.**

1. **Verify Prerequisites and Scope**
   - Check if spec name is provided
   - If not provided, use AskUserQuestion to ask:
     - Question: \"Which spec should I execute tasks for?\"
     - Header: \"Spec Name\"
     - Options: [User can type in Other field]
   - Check if specific tasks are requested (task IDs, feature numbers, or \"all\")
   - If unclear, use AskUserQuestion to ask:
     - Question: \"Which tasks should I execute? (e.g., 'task 1.1', 'Feature 2', or 'all')\"
     - Header: \"Task Scope\"
     - Options:
       - \"All tasks\" - Execute everything in tasks.md
       - \"Specific tasks\" - User will specify in Other field
     - multiSelect: false

2. **Read All Context**
   - Read product context:
     - .molcajete/prd/PRD.md
     - .molcajete/prd/mission.md
     - .molcajete/prd/tech-stack.md
   - Read specification:
     - .molcajete/prd/specs/{spec-name}/spec.md
     - .molcajete/prd/specs/{spec-name}/tasks.md
   - Read roadmap:
     - .molcajete/prd/roadmap.md
   - If any files are missing, return error message

3. **Discover Available Plugins and Agents**
   - Read plugin metadata from */PLUGIN.md files of the plugin directory
   - Parse YAML frontmatter for plugin id, techStackKeywords, and agents list
   - Build agent registry with capabilities and "Use When" guidance
   - If no PLUGIN.md files found, fall back to general-purpose agents

4. **Identify Tech Stack and Match Agents**
   - From tech-stack.md, identify technologies mentioned (e.g., "Solidity", "Go", "React")
   - Match keywords against plugin techStackKeywords
   - Load agents from matching plugins
   - Example: tech-stack mentions "Solidity" → load sol:* agents from tech-stacks/solidity/PLUGIN.md
   - Map tasks to appropriate subagents based on task type and agent capabilities
   - Follow **task-breakdown** skill for understanding feature organization

5. **Plan Execution Strategy**
   - Use AskUserQuestion to ask user:
     - Question: \"Execute tasks sequentially (one at a time) or in parallel (multiple at once)?\"
     - Header: \"Execution\"
     - Options:
       - \"Sequential\" - One feature at a time, safer for learning codebases
       - \"Parallel\" - Multiple features simultaneously, faster but requires clear boundaries
     - multiSelect: false
   - Reference task-breakdown skill for orchestration strategies

6. **Execute Tasks (RESPECT SCOPE)**
   - Execute ONLY the tasks specified in step 1 - DO NOT continue beyond requested scope
   - Before starting each task, verify it's within the requested scope
   - Delegate tasks to appropriate tech-specific subagents using Task tool
   - For each completed task:
     - Verify acceptance criteria are met
     - Run tests
     - Track all changes made
   - If tasks fail, document the failure and blockers
   - After completing requested tasks, STOP and return results - DO NOT continue to additional tasks

7. **Track All Changes (DO NOT WRITE FILES)**
   For each task, record:
   - Task ID and description
   - Completion status and timestamp
   - Implementation notes and decisions
   - Any deviations from spec
   - Files created/modified by subagents
   - Test results (pass/fail)
   - Technical debt identified

8. **RETURN Complete Update Package**
   - DO NOT attempt to write files - main context will handle file operations
   - Return in your final response:

   ```
   === COMPLETED TASKS ===
   [List of task IDs with completion timestamps, format: 1.1 - Task description (Completed: YYYY-MM-DD HH:MM)]

   === TASKS.MD UPDATES ===
   [Specific edits needed: which tasks to check off, implementation notes to add]

   === SPEC.MD IMPLEMENTATION NOTES ===
   [All important decisions, technical debt, deviations from original design]

   === SPEC.MD IMPLEMENTATION SUMMARY ===
   [Status, what was built, key decisions, test results, next steps]

   === ROADMAP UPDATE ===
   [New status (In Progress/Implemented/Blocked), completion percentage, completion date if done]

   === FILES CREATED/MODIFIED ===
   [List all files created or modified by subagents with brief descriptions]
   ```

Follow your agent instructions in agents/orchestrator.md and reference task-breakdown skill for orchestration strategies."

## After Agent Returns

Once the agent provides the update package:

1. **Update roadmap.md:**
   Use Edit tool on `.molcajete/prd/roadmap.md` to change feature status as specified by agent

2. **Update tasks.md:**
   Use Edit tool on `.molcajete/prd/specs/{spec-name}/tasks.md` to:
   - Check off completed tasks
   - Add completion timestamps
   - Add implementation notes

3. **Update spec.md:**
   Use Edit tool on `.molcajete/prd/specs/{spec-name}/spec.md` to:
   - Add \"Implementation Notes\" section (if not exists) with decisions and deviations
   - Add \"Implementation Summary\" section at end with status, decisions, test results, next steps

4. **Inform user:**
   ```
   Implementation complete for {spec-name}

   Updated files:
   - .molcajete/prd/specs/{spec-name}/tasks.md (X tasks completed)
   - .molcajete/prd/specs/{spec-name}/spec.md (added implementation notes)
   - .molcajete/prd/roadmap.md (status updated)

   Files created/modified:
   [List from agent]

   Summary: [Brief summary from agent]
   ```
