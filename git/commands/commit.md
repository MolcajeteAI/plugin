---
description: Create a well-formatted commit from staged changes
---

IMPORTANT: Immediately use the Task tool with subagent_type="git:code-committer" to delegate ALL work to the code-committer agent. Do NOT do any analysis or work in the main context.

Use this exact prompt for the agent:
"Execute the commit workflow following these steps:

1. **Verify Staged Changes**
   - Run `git status` to check for staged changes
   - If no staged changes found, show error and stop:
     ```
     Error: No staged changes found.

     Please stage your changes first:
       git add <files>

     Or stage all changes:
       git add .
     ```

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

4. **Present Message and Get Confirmation**
   - Use AskUserQuestion tool with the message embedded in the question:
     - Question: \"Commit with this message?\n\n[Insert the complete formatted commit message here with title and bullet points]\"
     - Header: \"Commit\"
     - Options:
       - \"Yes\" - Commit this message
     - multiSelect: false

   - If user types in Other field (to suggest changes):
     - Update the commit message based on their feedback
     - Ask for confirmation again with updated message in the question (repeat until user selects Yes)

5. **Execute Commit**
   - After user confirms, execute using heredoc format:
     ```bash
     git commit -m \"$(cat <<'EOF'
     [message]
     EOF
     )\"
     ```
   - Verify the commit succeeded with `git status`"
