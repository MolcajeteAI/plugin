---
description: Create a well-formatted commit from staged changes
---

IMPORTANT: Immediately use the Task tool with subagent_type="git:code-committer" to delegate ALL work to the code-committer agent. Do NOT do any analysis or work in the main context.

Use this exact prompt for the agent:
"Execute the commit workflow following these steps:

## MANDATORY REQUIREMENTS - READ BEFORE PROCEEDING

**REQUIREMENT 1 - STAGED CHANGES ONLY:**
This command ONLY commits already-staged changes. NEVER run `git add` under any circumstance. If there are no staged changes, show an error and stop immediately.

**REQUIREMENT 2 - USE AskUserQuestion TOOL:**
You MUST use the AskUserQuestion tool to get user confirmation. NEVER ask questions in plain text. NEVER output "Would you like to proceed?" or similar. NEVER end your response with a question. The ONLY way to ask for confirmation is by invoking the AskUserQuestion tool. If you cannot use this tool, STOP and report an error.

**REQUIREMENT 3 - NO AI ATTRIBUTION:**
NEVER add "Generated with Claude Code", "Co-Authored-By: Claude", or any AI-related text to commit messages.

1. **Verify Staged Changes**
   - Run `git status` to check for staged changes
   - If no staged changes found, show error and STOP:
     ```
     Error: No staged changes found.

     Please stage your changes first:
       git add <files>

     Or stage all changes:
       git add .
     ```
   - Do NOT offer to stage files. Do NOT run git add. Just stop.

2. **Analyze Changes**
   - Run `git diff --staged` to see what will be committed
   - Run `git log -5 --oneline` to match project commit style
   - Determine the type of changes (feature, fix, refactor, etc.)

3. **Draft Commit Message**
   - Follow the **commit-standards** skill for all formatting rules
   - Choose appropriate imperative verb (adds, fixes, updates, removes, refactors, improves)
   - Keep first line under 50 characters
   - Add bullet points for complex changes
   - CRITICAL: Never mention AI, Claude, or tools in the message

4. **Present Message and Get Confirmation (USE AskUserQuestion TOOL - NO EXCEPTIONS)**

   Invoke the AskUserQuestion tool with:
   - Question: \"Commit with this message?\n\n[Insert the complete formatted commit message here]\"
   - Header: \"Commit\"
   - Options: [\"Yes\" - Commit this message]
   - multiSelect: false

   The tool provides an "Other" option automatically. If user types in Other:
   - Treat their input as instructions to modify the message (e.g., "make it shorter", "change adds to fixes")
   - Update the message and invoke AskUserQuestion again
   - Repeat until user selects "Yes"

   If AskUserQuestion is unavailable: STOP with error "AskUserQuestion tool not available. Cannot proceed."

5. **Execute Commit**
   - After user confirms, execute using heredoc format:
     ```bash
     git commit -m \"$(cat <<'EOF'
     [message]
     EOF
     )\"
     ```
   - Verify the commit succeeded with `git status`"
