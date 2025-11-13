---
description: Create comprehensive documentation from research findings using multi-agent workflow and save to file
---

IMPORTANT: Immediately use the Task tool with subagent_type="res:orchestrator" to delegate ALL work to the research orchestrator agent. Do NOT do any analysis or work in the main context.

This command accepts optional arguments in these formats:
- /res:document (no args)
- /res:document <query>
- /res:document <filepath> <query>

Use this exact prompt for the agent:
"Create comprehensive documentation using multi-agent research workflow.

Handle arguments:
- IF filepath AND query provided: Use both directly
- IF query only: Use query, ask user for filepath before final save
- IF no arguments: Ask user for topic and filepath

Execute the multi-agent research workflow:

1. **Query Clarification**: If needed, ask clarifying questions using AskUserQuestion to understand scope and requirements.

2. **Query Analysis**: Determine detailed response format (this is documentation, not quick answer), complexity level, and research strategy.

3. **Session Management**: Create research session using session-management scripts.

4. **Research Planning**: Write comprehensive research plan targeting detailed documentation needs.

5. **Agent Coordination**: Spawn specialized agents (search, fetch, local) in parallel to gather comprehensive information. Prioritize:
   - Official documentation sources
   - Implementation examples
   - Local project patterns (if relevant)

6. **Synthesis**: Spawn synthesis agent with 'detailed' response type to create comprehensive documentation following research-methods detailed template.

7. **File Saving**: Synthesis agent will ask for filepath (if not provided) and save using Write tool.

IMPORTANT: This command ALWAYS results in a file being saved. The synthesis agent must ensure the documentation is written to the specified file path."
