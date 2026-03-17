---
description: Generate a state machine diagram for a component or file
---

IMPORTANT: Immediately use the Task tool with subagent_type="prd:system-architect" to delegate ALL work to the system-architect agent. Do NOT do any analysis or work in the main context.

Use this exact prompt for the agent:
"Execute the state machine generation workflow:

1.  **Identify Target**:
    - If the user provided a filename/component name in their request, use it.
    - If not, use `AskUserQuestion` to ask: 'Which component or file would you like to map out?'

2.  **Analyze & Diagram**:
    - Find and read the target file(s).
    - Apply the **state-modeling** skill to extract the state machine.
    - Generate a comprehensive Mermaid `stateDiagram-v2`.

3.  **Output Results**:
    - Display the Mermaid code block.
    - Provide the 'Visualize this diagram' instruction (linking to Mermaid Live Editor).
    - Ask the user if they want to save this to `.molcajete/architecture/`.
      - If YES:
        1. Create the directory `.molcajete/architecture/` if needed.
        2. Ask for a filename (default to `{component-name}-state.md`).
        3. Write the file with the diagram and a brief explanation.
"
