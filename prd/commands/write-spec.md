---
description: Create formal specification for a feature
---

IMPORTANT: Immediately use the Task tool with subagent_type="prd:spec-writer" to delegate ALL work to the spec-writer agent. Do NOT do any analysis or work in the main context.

Use this exact prompt for the agent:
"Execute the spec writing workflow following these steps:

1. **Check Prerequisites**
   - Verify product context exists by checking for:
     - .molcajete/prd/PRD.md
     - .molcajete/prd/mission.md
     - .molcajete/prd/roadmap.md
     - .molcajete/prd/tech-stack.md
   - If any are missing, return error message:
     ```
     Error: Product context not found.

     Please run /prd:plan-product first to set up product context.
     ```

2. **Get Spec Name**
   - If spec name not provided in command, use AskUserQuestion to ask:
     - Question: \"What is the feature name for this spec?\"
     - Header: \"Feature Name\"
     - Options: [User can type in Other field]

3. **Check for Existing Requirements**
   - Try to read `.molcajete/prd/specs/{spec-name}/requirements.md`
   - If exists, read and use as input
   - If not exists, use AskUserQuestion to ask:
     - Question: \"Describe the feature you want to spec out. Include: user value, functional requirements, and any technical considerations.\"
     - Header: \"Feature Details\"
     - Options: [User can type in Other field]

4. **Generate Comprehensive Specification**
   - Follow the **spec-writing** skill for all section requirements and structure
   - Apply **software-principles** skill for architecture decisions
   - Create specification with these sections:
     - Overview (feature description, strategic alignment, user value, success criteria)
     - Requirements Summary (functional, non-functional, constraints, out of scope)
     - Data Models (schema, relationships, validation, indexes)
     - API Contracts if applicable (endpoints, request/response, auth, errors)
     - User Interface if applicable (components, flows, state, validation, accessibility)
     - Integration Points (external APIs, dependencies, events)
     - Acceptance Criteria (testable criteria, edge cases, performance, security)
     - Verification (test scenarios at all levels)

5. **RETURN Complete Content**
   - DO NOT attempt to write files - main context will handle file operations
   - Return in your final response:
     - The complete spec.md content
     - The roadmap update needed (what to change in roadmap.md)
   - Format as:
     ```
     === SPEC CONTENT ===
     [full spec.md content]

     === ROADMAP UPDATE ===
     [description of changes to make to roadmap.md]
     ```

Follow your agent instructions in agents/spec-writer.md and reference the spec-writing skill for all formatting and content standards."

## After Agent Returns

Once the agent provides the spec content:

1. **Create timestamped directory:**
   ```bash
   FEATURE_DIR=$(python3 -c "from datetime import datetime; from pathlib import Path; import sys; name = sys.argv[1]; timestamp = datetime.now().strftime('%Y-%m-%d'); dir_name = f'{timestamp}-{name}'; Path(f'.molcajete/prd/specs/{dir_name}').mkdir(parents=True, exist_ok=True); print(dir_name)" "{spec-name}")
   ```

2. **Write spec file:**
   Use Write tool to create `.molcajete/prd/specs/${FEATURE_DIR}/spec.md` with the content returned by the agent

3. **Update roadmap:**
   Use Edit tool on `.molcajete/prd/roadmap.md` to make the changes specified by the agent

4. **Inform user:**
   ```
   Created specification: .molcajete/prd/specs/${FEATURE_DIR}/spec.md
   Updated roadmap status

   Next step: Run /prd:create-tasks ${FEATURE_DIR} to break this into implementation tasks
   ```
