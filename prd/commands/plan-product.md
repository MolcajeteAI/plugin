---
description: Establish strategic foundation for product (one-time setup)
---

IMPORTANT: Immediately use the Task tool with subagent_type="prd:product-strategist" to delegate ALL work to the product-strategist agent. Do NOT do any analysis or work in the main context.

Use this exact prompt for the agent:
"Execute the product planning workflow following these steps:

1. **Introduction**
   - Explain this is a one-time setup to establish product foundation
   - Let user know this creates strategic context that guides all future development
   - Mention this can be updated later as the product evolves

2. **Conduct Strategic Interview**
   - Use AskUserQuestion tool to gather information across five key areas:

   **Vision & Purpose:**
   - What problem does this product solve?
   - What is the long-term vision?
   - What makes this product unique?
   - What does success look like?

   **Target Users:**
   - Who are the primary users?
   - What are their key pain points?
   - What are their technical capabilities?
   - What platforms/devices do they use?

   **Differentiation:**
   - What alternatives exist?
   - Why would users choose this product?
   - What are the key competitive advantages?
   - What won't this product do?

   **Technology Stack:**
   - What technology choices have been made or are preferred?
   - Are there existing systems to integrate with?
   - What are the scalability requirements?
   - What are the security/compliance requirements?

   **Roadmap:**
   - What features are most critical (Now)?
   - What features come next (Next)?
   - What features are on the horizon (Later)?
   - Why this prioritization?

3. **Generate Product Documents**
   - Follow the **product-planning** skill templates exactly
   - Create four foundational documents:
     - mission.md (Vision, Target Users, Key Differentiators, Success Metrics)
     - roadmap.md (Features organized into Now/Next/Later/Completed with rationale)
     - tech-stack.md (Backend, frontend, infrastructure, integrations, standards)
     - PRD.md (Master index with links to all context files)
   - All files will be placed in `.molcajete/prd/` directory

4. **Ensure Strategic Alignment**
   - Verify all roadmap features align with the mission
   - Ensure tech stack supports the product vision
   - Check that target users' needs are addressed
   - Validate success metrics are measurable

5. **RETURN Complete Content**
   - DO NOT attempt to write files - main context will handle file operations
   - Return in your final response all four document contents
   - Format as:
     ```
     === MISSION.MD ===
     [full mission.md content]

     === ROADMAP.MD ===
     [full roadmap.md content]

     === TECH-STACK.MD ===
     [full tech-stack.md content]

     === PRODUCT.MD ===
     [full PRD.md content]
     ```

Follow your agent instructions in agents/product-strategist.md and reference the product-planning skill for all templates and guidance."

## After Agent Returns

Once the agent provides all document contents:

1. **Create product directory:**
   ```bash
   mkdir -p .molcajete/prd
   ```

2. **Write all files:**
   - Use Write tool to create `.molcajete/prd/PRD.md`
   - Use Write tool to create `.molcajete/prd/mission.md`
   - Use Write tool to create `.molcajete/prd/roadmap.md`
   - Use Write tool to create `.molcajete/prd/tech-stack.md`

3. **Inform user:**
   ```
   Created product foundation:
   - .molcajete/prd/PRD.md (master index)
   - .molcajete/prd/mission.md (vision and strategy)
   - .molcajete/prd/roadmap.md (feature roadmap)
   - .molcajete/prd/tech-stack.md (technology decisions)

   Next steps:
   - Run /prd:scope-feature to analyze a specific feature, OR
   - Run /prd:write-spec {feature-name} to create a specification
   ```
