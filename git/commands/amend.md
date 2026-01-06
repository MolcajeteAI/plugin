---
description: Amend the last commit with staged changes
---

IMPORTANT: Immediately use the Task tool with subagent_type="git:code-committer" to delegate ALL work to the code-committer agent. Do NOT do any analysis or work in the main context.

Use this exact prompt for the agent:
"Execute the amend workflow following these steps:

## MANDATORY REQUIREMENTS - READ BEFORE PROCEEDING

**REQUIREMENT 1 - USE AskUserQuestion TOOL:**
You MUST use the AskUserQuestion tool to get user confirmation. NEVER ask questions in plain text. NEVER output "Would you like to proceed?" or similar. NEVER end your response with a question. The ONLY way to ask for confirmation is by invoking the AskUserQuestion tool. If you cannot use this tool, STOP and report an error.

**REQUIREMENT 2 - NO AI ATTRIBUTION:**
NEVER add "Generated with Claude Code", "Co-Authored-By: Claude", or any AI-related text to commit messages.

1. **Safety Checks (CRITICAL - ALL MUST PASS)**
   - Run `git status` and verify commit is unpushed
     - Look for 'Your branch is ahead of' or no upstream
     - If commit is pushed, show error and STOP:
       ```
       Error: Cannot safely amend this commit.

       Reason: This commit has already been pushed to the remote repository.

       Amending pushed commits can cause problems for collaborators.
       Instead, create a new commit with /git:commit
       ```

   - Run `git log -1 --format='%an %ae'` to check authorship
     - Verify name/email matches your identity
     - If authored by someone else, show error and STOP:
       ```
       Error: Cannot safely amend this commit.

       Reason: This commit was authored by someone else.

       You should only amend commits you created.
       To make changes, create a new commit with /git:commit
       ```

   - Verify a previous commit exists
     - If no commits exist, show error and STOP:
       ```
       Error: Cannot amend - no previous commit exists.

       This appears to be a new repository with no commits yet.
       Use /git:commit to create your first commit.
       ```

2. **Analyze Current State**
   - Run `git log -1` to see current commit message
   - Run `git diff --staged` to see new changes being added
   - Run `git log -5 --oneline` to match project style

3. **Draft Improved Message**
   - Follow the **commit-standards** skill for all formatting rules
   - Incorporate existing commit context and intent
   - Add new staged changes to the description
   - Improve clarity or detail if needed
   - Keep same commit type unless changes warrant a different one
   - CRITICAL: Never mention AI, Claude, or tools in the message

4. **Present Message and Get Confirmation (USE AskUserQuestion TOOL - NO EXCEPTIONS)**

   Invoke the AskUserQuestion tool with:
   - Question: \"Amend the last commit with this message?\n\nCurrent:\n[current message]\n\nNew:\n[new message]\"
   - Header: \"Amend\"
   - Options: [\"Yes\" - Amend with this message]
   - multiSelect: false

   The tool provides an "Other" option automatically. If user types in Other:
   - Treat their input as instructions to modify the message (e.g., "make it shorter", "keep original title")
   - Update the message and invoke AskUserQuestion again
   - Repeat until user selects "Yes"

   If AskUserQuestion is unavailable: STOP with error "AskUserQuestion tool not available. Cannot proceed."

5. **Execute Amend**
   - After user confirms, execute using heredoc format:
     ```bash
     git commit --amend -m \"$(cat <<'EOF'
     [new message]
     EOF
     )\"
     ```
   - Verify the amend succeeded with `git log -1 --oneline`"
