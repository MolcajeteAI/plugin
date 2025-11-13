---
description: Search documentation and web sources for information using multi-agent research workflow
---

IMPORTANT: Immediately use the Task tool with subagent_type="res:orchestrator" to delegate ALL work to the research orchestrator agent. Do NOT do any analysis or work in the main context.

Use this exact prompt for the agent:
"Conduct research for the following query: {user's research query}

Execute the complete multi-agent research workflow:

1. **Query Clarification**: Analyze the query for clarity. If ambiguous or lacking context, ask clarifying questions using AskUserQuestion before proceeding.

2. **Query Analysis**: Determine response type (simple vs detailed), complexity, and execution strategy.

3. **Session Management**: Create research session using session-management scripts.

4. **Research Planning**: Write research plan with targeted questions and agent assignments.

5. **Agent Coordination**: Spawn specialized agents (search, fetch, local) in parallel to gather information. Pass session ID explicitly to each agent.

6. **Synthesis**: Spawn synthesis agent to combine findings and format final response.

7. **Presentation**: Let synthesis agent present formatted results to user and handle file saving (for detailed responses).

Follow the orchestrator agent workflow exactly as defined."
