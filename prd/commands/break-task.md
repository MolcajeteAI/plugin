---
description: Break a complex task into smaller, manageable sub-tasks
---

**Note:** The {spec-name} should be the timestamped directory name (e.g., `2025-11-12-feature-name`) created by previous commands.

## When to Use This Command

**Use `/prd:break-task` when:**
- Task has complexity >8 points
- Task reveals hidden complexity during implementation
- You need more granular tracking of progress
- Task is blocking and needs to be divided among team members

**Example:**
```
/prd:break-task user-auth 1.2
```

This breaks down task 1.2 in the user-auth spec into smaller sub-tasks.

---

IMPORTANT: Immediately use the Task tool with subagent_type="prd:task-planner" to delegate ALL work to the task-planner agent. Do NOT do any analysis or work in the main context.

Use this exact prompt for the agent:
"Execute the task breakdown workflow following these steps:

1. **Verify Inputs**
   - Check if spec name is provided
   - Check if task ID is provided
   - If either is missing, use AskUserQuestion to ask:
     - Question: \"Please provide the spec name and task ID (e.g., user-auth 1.2)\"
     - Header: \"Task Info\"
     - Options: [User can type in Other field]

2. **Read Context**
   - Read .molcajete/prd/specs/{spec-name}/tasks.md
   - Read .molcajete/prd/specs/{spec-name}/spec.md
   - Find the specific task by ID in tasks.md
   - If task not found, return error message

3. **Analyze Task Complexity**
   - Follow **task-breakdown** skill methodology
   - Identify why this task is complex (>8 points if applicable)
   - Determine the hidden sub-components
   - Understand dependencies within the task
   - Plan shortest path to completion using vertical slicing

4. **Generate Sub-tasks**
   - Break into smaller pieces (1-3 points each)
   - Create indented checklist structure with proper numbering
   - Maintain sequential order for working software delivery
   - Follow vertical slicing principles (NOT horizontal layers)
   - Each sub-task should contribute to end-to-end functionality

5. **RETURN Updated Task Section**
   - DO NOT attempt to write files - main context will handle file operations
   - Return in your final response:
     - The original task line
     - The complete sub-task breakdown
     - Exact formatting with proper indentation
   - Format as:
     ```
     === OLD TASK ===
     [original task line to be replaced]

     === NEW TASK WITH SUB-TASKS ===
     [complete replacement including parent task and all sub-tasks]
     ```

Example transformation:
```
=== OLD TASK ===
- 1.2 [ ] Implement authentication system (8 points)

=== NEW TASK WITH SUB-TASKS ===
- 1.2 [ ] Implement authentication system
  - 1.2.1 [ ] Add JWT library dependency (1 point)
  - 1.2.2 [ ] Create token generation utility (2 points)
  - 1.2.3 [ ] Add authentication middleware (3 points)
  - 1.2.4 [ ] Implement token refresh flow (3 points)
  - 1.2.5 [ ] Add logout endpoint (1 point)
  - 1.2.6 [ ] Write authentication tests (2 points)
```

Follow your agent instructions in agents/task-planner.md and reference the task-breakdown skill."

## After Agent Returns

Once the agent provides the task breakdown:

1. **Update tasks.md:**
   Use Edit tool on `.molcajete/prd/specs/{spec-name}/tasks.md` to replace the old task with the new sub-task breakdown

2. **Inform user:**
   ```
   Broke down task {task-id} into {N} sub-tasks
   Updated: .molcajete/prd/specs/{spec-name}/tasks.md

   You can now work through the sub-tasks incrementally.
   ```
