---
description: Refine rough feature ideas into clear, scoped requirements (optional for complex features)
---

## When to Use This Command

**Use `/prd:scope-feature` when:**
- Feature idea is vague or underspecified
- Multiple stakeholders have different interpretations
- Feature involves complex integrations or unknowns
- You want to explore technical feasibility before full spec
- Feature scope needs clear boundaries defined

**Skip this and go directly to `/prd:write-spec` when:**
- Feature is simple and well-understood
- Requirements are already crystal clear
- You have mockups/designs that fully define the feature
- Feature is a minor enhancement to existing functionality

---

IMPORTANT: Immediately use the Task tool with subagent_type="prd:feature-analyst" to delegate ALL work to the feature-analyst agent. Do NOT do any analysis or work in the main context.

Use this exact prompt for the agent:
"Execute the feature scoping workflow following these steps:

1. **Check Product Context**
   - Verify product context exists:
     - .molcajete/prd/PRD.md
     - .molcajete/prd/mission.md
     - .molcajete/prd/roadmap.md
     - .molcajete/prd/tech-stack.md
   - If any are missing, return error message:
     ```
     Error: Product context not found.

     Please run /prd:plan-product first to set up product context.
     ```

2. **Identify Feature to Analyze**
   - Use AskUserQuestion to ask:
     - Question: \"Which feature should I analyze? You can select from the roadmap or describe a new feature idea.\"
     - Header: \"Feature\"
     - Options: [User can type in Other field to describe new feature]

3. **Conduct Requirements Interview**
   - Use AskUserQuestion tool to gather detailed requirements across these areas:
     - **User Stories & Value**: Who benefits? What problem does this solve? What value does it deliver?
     - **Functional Requirements**: What must the feature do? What are the core capabilities?
     - **Technical Considerations**: Integration points? Performance requirements? Security needs?
     - **User Experience**: How will users interact? What's the happy path? What about errors?
     - **Scope & Boundaries**: What's included? What's explicitly excluded? What's MVP vs. future?
   - Ask follow-up questions to clarify ambiguous or incomplete answers
   - Reference **spec-writing** skill for requirements gathering best practices

4. **Generate Requirements Document**
   - Follow the **spec-writing** skill requirements template
   - Include these sections:
     - Overview (feature description, user value, success criteria)
     - User Stories (who, what, why for each user type)
     - Functional Requirements (detailed capabilities)
     - Technical Considerations (integrations, performance, security, scalability)
     - User Experience (flows, interactions, validation, errors)
     - Scope Definition (in scope, out of scope, MVP boundaries, future enhancements)
   - Reference product context for strategic alignment

5. **RETURN Complete Content**
   - DO NOT attempt to write files - main context will handle file operations
   - Return in your final response:
     - The complete requirements.md content
     - Suggested feature name (derived from the requirements)
   - Format as:
     ```
     === FEATURE NAME ===
     [suggested-feature-name]

     === REQUIREMENTS CONTENT ===
     [full requirements.md content]
     ```

Follow your agent instructions in agents/feature-analyst.md and reference the spec-writing skill for requirements format."

## After Agent Returns

Once the agent provides the requirements content:

1. **Create timestamped spec directory:**
   ```bash
   FEATURE_DIR=$(python3 -c "from datetime import datetime; from pathlib import Path; import sys; name = sys.argv[1]; timestamp = datetime.now().strftime('%Y-%m-%d'); dir_name = f'{timestamp}-{name}'; Path(f'.molcajete/prd/specs/{dir_name}').mkdir(parents=True, exist_ok=True); print(dir_name)" "{feature-name}")
   ```

2. **Write requirements.md file:**
   Use Write tool to create `.molcajete/prd/specs/${FEATURE_DIR}/requirements.md` with the content returned by the agent

3. **Inform user:**
   ```
   Created requirements: .molcajete/prd/specs/${FEATURE_DIR}/requirements.md

   Next step: Run /prd:write-spec ${FEATURE_DIR} to create the full technical specification
   ```
