# Product Management Plugin

Strategic product planning and feature development workflow from vision to implementation.

## Overview

The product management plugin provides a complete workflow for transforming product vision into implemented features. It guides you through strategic planning, requirements gathering, specification writing, task breakdown, and orchestrated implementation using specialized agents.

## Features

- **Strategic Foundation** - Establish product vision, mission, roadmap, and tech stack
- **Requirements Refinement** - Transform rough ideas into clear, scoped requirements
- **Formal Specifications** - Create detailed technical specs with data models and API contracts
- **Feature Organization** - Break specs into vertical features that deliver working software incrementally
- **Task Orchestration** - Delegate implementation to specialized stack-specific agents
- **Real-Time Tracking** - Maintain up-to-date progress across all planning documents
- **Vertical Development** - Enforce shortest path to working, testable software

## Installation

The product management plugin is installed as part of the Claude Code setup:

```bash
# From the claude-code repository
./scripts/install.sh
```

This installs all plugins to `~/.claude/plugins/`.

## Commands

### `/prd:plan-product`

Establish strategic foundation for your product (one-time setup).

**Usage:**
```
/prd:plan-product
```

**What it does:**
1. Conducts strategic interview covering:
   - Vision & Purpose
   - Target Users
   - Differentiation
   - Technology Stack
   - Roadmap
2. Generates four foundational documents
3. Ensures strategic alignment

**Output Files:**
```
.molcajete/prd/
├── PRD.md           # Master index
├── mission.md           # Product vision and mission
├── roadmap.md           # Feature roadmap
└── tech-stack.md        # Technology architecture
```

**Example:**
```
> /prd:plan-product

I'll help establish the strategic foundation for your product.

What problem does this product solve?
> Developers spend too much time on repetitive coding tasks...

Who are the primary users?
> Software engineers working on web applications...

[After interview completes]

✓ Created .molcajete/prd/mission.md
✓ Created .molcajete/prd/roadmap.md
✓ Created .molcajete/prd/tech-stack.md
✓ Created .molcajete/prd/PRD.md

Your product foundation is ready. Use /prd:write-spec to create your first feature.
```

### `/prd:scope-feature`

Refine rough feature ideas into clear, scoped requirements.

**When to use:**
- Feature idea is vague or underspecified
- Multiple stakeholders have different interpretations
- Feature involves complex integrations or unknowns
- You want to explore technical feasibility

**When to skip:**
- Feature is simple and well-understood
- Requirements are already clear
- You have complete mockups/designs

**Usage:**
```
/prd:scope-feature
```

**What it does:**
1. Conducts detailed requirements interview
2. Analyzes mockups and designs if provided
3. Researches technical approaches
4. Generates requirements.md with clear scope

**Output Files:**
```
.molcajete/prd/
└── specs/
    └── {feature-name}/
        └── requirements.md    # Detailed requirements
```

**Example:**
```
> /prd:scope-feature

Which feature would you like to scope?
> User authentication system

Let me ask some questions to understand the requirements...

What authentication methods should be supported?
> Email/password and OAuth (Google, GitHub)

[After interview completes]

✓ Created .molcajete/prd/specs/user-auth/requirements.md

Next step: Use /prd:write-spec user-auth to create the technical specification.
```

### `/prd:write-spec`

Create formal technical specification for a feature.

**Usage:**
```
/prd:write-spec [spec-name]
```

**What it does:**
1. Reads product context and requirements (if exists)
2. Creates comprehensive technical specification
3. Defines data models, API contracts, UI components
4. Establishes acceptance criteria
5. Updates roadmap status to "Ready for Implementation"

**Output Files:**
```
.molcajete/prd/
└── specs/
    └── {spec-name}/
        └── spec.md            # Technical specification
```

**Sections included:**
- Overview and strategic alignment
- Requirements summary
- Data models and schema
- API contracts
- User interface components
- Integration points
- Acceptance criteria
- Verification approach

**Example:**
```
> /prd:write-spec user-auth

Reading product context...
✓ Read mission.md, roadmap.md, tech-stack.md
✓ Found requirements.md

Generating technical specification...

✓ Created .molcajete/prd/specs/user-auth/spec.md
✓ Updated .molcajete/prd/roadmap.md status

The specification is complete. Next step: Use /prd:create-tasks user-auth to break it into tasks.
```

### `/prd:create-tasks`

Break specification into actionable tasks organized by features.

**Usage:**
```
/prd:create-tasks [spec-name]
```

**What it does:**
1. Analyzes specification thoroughly
2. Identifies sequential steps for working software
3. Organizes tasks into vertical features
4. Estimates complexity for each task
5. Analyzes dependencies and risks
6. Updates roadmap to "Ready for Implementation"

**Core Principle:**
Tasks are organized vertically through all layers, NOT horizontally by layer. Each feature delivers working, testable software.

**Output Files:**
```
.molcajete/prd/
└── specs/
    └── {spec-name}/
        └── tasks.md           # Task breakdown by features
```

**Example:**
```
> /prd:create-tasks user-auth

Analyzing specification...
Organizing into features...

✓ Created 3 features:
  1. Users can sign up (8 tasks)
  2. Users can log in (6 tasks)
  3. Users can reset password (5 tasks)

✓ Created .molcajete/prd/specs/user-auth/tasks.md
✓ Updated .molcajete/prd/roadmap.md

Total effort: 34 story points
Recommended: Sequential execution

Next step: Use /prd:execute-tasks user-auth to begin implementation.
```

### `/prd:break-task`

Break a complex task into smaller, manageable sub-tasks.

**When to use:**
- Task has complexity >8 points
- Task reveals hidden complexity during implementation
- You need more granular progress tracking
- Task needs to be divided among team members

**Usage:**
```
/prd:break-task [spec-name] [task-id]
```

**Example:**
```
> /prd:break-task user-auth 1.4

Reading task 1.4: Implement OAuth integration (8 points)

Breaking into sub-tasks...

✓ Updated .molcajete/prd/specs/user-auth/tasks.md

Task 1.4 now has 6 sub-tasks:
  - 1.4.1 Add OAuth library dependencies (1 point)
  - 1.4.2 Create OAuth callback endpoints (2 points)
  - 1.4.3 Implement Google OAuth flow (3 points)
  - 1.4.4 Implement GitHub OAuth flow (3 points)
  - 1.4.5 Link OAuth accounts to users (2 points)
  - 1.4.6 Write OAuth integration tests (2 points)
```

### `/prd:execute-tasks`

Orchestrate task implementation with specialized stack-specific subagents.

**Usage:**
```
/prd:execute-tasks [spec-name]
```

**What it does:**
1. Reads all product context and task breakdown
2. Identifies appropriate stack-specific agents
3. Asks for execution mode (sequential or parallel)
4. Delegates tasks to specialized agents
5. **Updates tracking files in real-time**
6. Verifies acceptance criteria
7. Generates implementation summary
8. Updates roadmap to "Implemented"

**Critical Feature: Real-Time Updates**

The orchestrator updates tracking files **immediately** after each task completes, not at the end:
- `tasks.md` - Checks off completed tasks, adds timestamps
- `spec.md` - Adds implementation notes as decisions are made
- `roadmap.md` - Updates status throughout execution

**Stack-Specific Delegation:**
- **Solidity:** `solidity-dev:developer`, `solidity-dev:tester`, `solidity-dev:auditor`
- **Go:** `go-dev:developer`, `go-dev:tester`, `go-dev:profiler`
- **Full-stack:** Framework-specific agents

**Example:**
```
> /prd:execute-tasks user-auth

Reading context...
✓ Product context loaded
✓ Specification loaded
✓ 19 tasks identified

Tech stack: Node.js + React + PostgreSQL

Execution mode?
  1. Sequential (recommended) - One feature at a time
  2. Parallel - Multiple features simultaneously

> 1

Starting sequential execution...

## Feature 1: Users can sign up

Task 1.1: Create user table migration
  → Delegating to backend agent...
  ✓ Migration created
  ✓ Updated tasks.md [1/19 complete]

Task 1.2: Add POST /signup endpoint
  → Delegating to backend agent...
  ✓ Endpoint implemented with tests
  ✓ Updated tasks.md [2/19 complete]

[Continues through all tasks...]

All tasks complete!

✓ Updated spec.md with implementation summary
✓ Updated roadmap.md to "Implemented"

Feature "User Authentication" is fully implemented and tested.
```

## Complete Workflow

### End-to-End Example

```bash
# 1. Establish product foundation (one-time)
> /prd:plan-product

# 2. (Optional) Scope complex feature
> /prd:scope-feature user-auth

# 3. Write formal specification
> /prd:write-spec user-auth

# 4. Break into tasks organized by features
> /prd:create-tasks user-auth

# 5. (Optional) Break down complex tasks
> /prd:break-task user-auth 1.4

# 6. Execute implementation
> /prd:execute-tasks user-auth
```

### Workflow Diagram

```
/prd:plan-product
    ↓
.molcajete/prd/
├── mission.md
├── roadmap.md
├── tech-stack.md
└── PRD.md

    ↓

/prd:scope-feature (optional)
    ↓
.molcajete/prd/specs/{name}/requirements.md

    ↓

/prd:write-spec
    ↓
.molcajete/prd/specs/{name}/spec.md

    ↓

/prd:create-tasks
    ↓
.molcajete/prd/specs/{name}/tasks.md

    ↓

/prd:break-task (optional)
    ↓
tasks.md updated with sub-tasks

    ↓

/prd:execute-tasks
    ↓
Implementation complete!
Real-time updates to tasks.md, spec.md, roadmap.md
```

## File Structure

### Product Directory Organization

```
.molcajete/prd/
├── PRD.md                      # Master index
├── mission.md                      # Product vision and mission
├── roadmap.md                      # Feature roadmap (Now/Next/Later)
├── tech-stack.md                   # Technology architecture
│
└── specs/                          # Feature specifications
    ├── user-auth/
    │   ├── requirements.md         # Requirements (optional)
    │   ├── spec.md                 # Technical specification
    │   └── tasks.md                # Task breakdown
    │
    ├── payment-flow/
    │   ├── spec.md
    │   └── tasks.md
    │
    └── analytics-dashboard/
        ├── requirements.md
        ├── spec.md
        └── tasks.md
```

### Document Lifecycle

```
Feature Idea
    ↓
requirements.md (optional - for complex features)
    ↓
spec.md (formal specification)
    ↓
tasks.md (implementation plan)
    ↓
Implementation (tasks checked off in real-time)
    ↓
spec.md updated with implementation summary
    ↓
roadmap.md status: "Implemented" ✓
```

## Agents

### product-strategist

Conducts strategic interview to establish product foundation.

**Namespace:** `prd:`

**Capabilities:**
- Strategic planning
- User research
- Technology selection
- Roadmap planning

**Responsibilities:**
- Conduct comprehensive strategic interview
- Generate mission, roadmap, tech-stack, PRD.md
- Ensure strategic alignment across documents

**Tool Access:** AskUserQuestion, Write, Read

### feature-analyst

Transforms rough feature ideas into detailed specifications.

**Namespace:** `prd:`

**Capabilities:**
- Requirements gathering
- Specification writing
- Technical analysis
- Feature scoping

**Responsibilities:**
- Conduct detailed requirements interview
- Generate comprehensive feature specifications
- Validate strategic alignment
- Define clear scope boundaries

**Tool Access:** AskUserQuestion, Write, Read

### spec-writer

Transforms requirements into formal technical specifications.

**Namespace:** `prd:`

**Capabilities:**
- Technical architecture
- API design
- Data modeling
- User flow design

**Responsibilities:**
- Create detailed technical specifications
- Define data models and API contracts
- Establish acceptance criteria
- Update roadmap status

**Tool Access:** Write, Read, Edit

### task-planner

Breaks specifications into actionable tasks organized by features.

**Namespace:** `prd:`

**Capabilities:**
- Task decomposition
- Dependency analysis
- Estimation
- Feature slicing

**Responsibilities:**
- Break specs into sequential steps for working software
- Organize tasks into vertical features
- Estimate complexity and analyze dependencies
- Support task breakdown for complex items

**Tool Access:** Read, Write, Edit

**Core Principle:**
Tasks are organized as sequential steps toward working software, NOT by technical layers. Ask: "After this task, is the user one step closer to using this feature?"

### orchestrator

Orchestrates task execution by delegating to specialized stack-specific subagents.

**Namespace:** `prd:`

**Capabilities:**
- Task orchestration
- Subagent delegation
- Integration
- Verification

**Responsibilities:**
- Delegate tasks to stack-specific agents
- **Maintain real-time updates to all tracking files**
- Verify acceptance criteria
- Generate implementation summaries

**Tool Access:** Task, Read, Write, Edit, AskUserQuestion

**Critical Behavior:**
The orchestrator updates `tasks.md`, `spec.md`, and `roadmap.md` **immediately after each task completes**, not at the end. This provides real-time visibility into progress.

## Skills

### product-planning

Standards and templates for product vision, roadmap, and tech stack.

**When to use:**
- Establishing product foundation
- Making strategic decisions
- Planning roadmap
- Selecting technologies

**Templates:**
- `mission-template.md` - Product vision and mission
- `roadmap-template.md` - Feature roadmap (Now/Next/Later)
- `tech-stack-template.md` - Technology architecture

### spec-writing

Standards and templates for writing detailed feature specifications.

**When to use:**
- Transforming requirements into specs
- Defining technical architecture
- Documenting acceptance criteria

**Templates:**
- `requirements-template.md` - Requirements document
- `spec-template.md` - Technical specification

**Required Sections:**
- Overview, Requirements, Data Models, API Contracts, User Interface, Integration Points, Acceptance Criteria, Verification

### task-breakdown

Methodology for breaking specs into actionable tasks organized by features.

**When to use:**
- Creating task lists
- Orchestrating implementation
- Planning delivery

**Core Principle:**
The best path is the shortest to get working software that can be tested end-to-end.

**Template:**
- `tasks-template.md` - Task breakdown by features

**Feature Examples:**

✅ **Good (Vertical):**
```
1. Users can sign up
   - Create user table
   - Add /signup endpoint
   - Build signup form
   - Add validation
   - Send confirmation email
   - Add verification endpoint
   - Build verification page
```

❌ **Bad (Horizontal):**
```
1. All database migrations
2. All API endpoints
3. All UI components
4. All validations
5. All tests
```

## When to Use scope-feature (Optional)

### Use `/prd:scope-feature` when:

✅ **Complex Features:**
- Multiple integration points
- Unclear technical approach
- Many edge cases to consider
- Stakeholder alignment needed

✅ **Exploratory Work:**
- Feasibility research required
- Multiple implementation options
- Prototype needed first
- Technical risks unclear

✅ **Team Coordination:**
- Multiple stakeholders
- Different interpretations of feature
- Need clear boundaries
- Dependencies on other teams

### Skip and go to `/prd:write-spec` when:

⏩ **Simple Features:**
- Well-understood requirements
- Clear implementation path
- Minor enhancements
- Standard patterns

⏩ **Complete Specifications:**
- Detailed mockups exist
- Technical approach decided
- All edge cases documented
- Acceptance criteria clear

## When to Use break-task (Optional)

### Use `/prd:break-task` when:

✅ **High Complexity:**
- Task >8 story points
- Hidden sub-components
- Multiple implementation steps
- Uncertain time estimate

✅ **Granular Tracking:**
- Need detailed progress visibility
- Milestone tracking required
- Sub-deliverables important
- Risk mitigation needed

✅ **Team Collaboration:**
- Task divided among developers
- Parallel work possible
- Clear handoff points needed
- Individual accountability required

### Skip when:

⏩ **Reasonable Complexity:**
- Task 1-5 story points
- Clear implementation path
- Single responsibility
- Quick to complete

⏩ **Overhead Not Worth It:**
- Breaking down adds no value
- Team understands the task
- Task already clear enough
- Time better spent implementing

## Orchestrator File Updates

### Real-Time Update Behavior

The orchestrator agent is **required** to maintain real-time updates to tracking documents throughout execution. This is not optional.

### What Gets Updated

#### tasks.md - Immediate Updates
```markdown
- [x] 1.1 Create user table (Completed: 2025-11-09 10:15)
- [x] 1.2 Add /signup endpoint (Completed: 2025-11-09 10:45)
- [ ] 1.3 Build signup form
```

**Updated after each task:**
- Checkbox marked [x]
- Completion timestamp added
- Progress percentage recalculated

#### spec.md - Decision Tracking
```markdown
## Implementation Notes

**Authentication Approach (2025-11-09):**
- Chose JWT over sessions for horizontal scalability
- Used bcrypt cost factor 12 (spec didn't specify)
- Added rate limiting: 100 requests/15 minutes
```

**Updated when:**
- Important architectural decisions made
- Deviations from spec occur
- Technical debt introduced
- Performance optimizations applied

#### roadmap.md - Status Tracking
```markdown
### User Authentication
**Status:** 🔄 In Progress (60% complete)
**Started:** 2025-11-09
**Estimated Completion:** 2025-11-10
```

**Updated:**
- Start: "In Progress" when execution begins
- During: Progress percentages
- End: "Implemented" with completion date

### Why Real-Time Updates Matter

1. **Visibility** - See progress as it happens
2. **Recovery** - Resume if interrupted
3. **Coordination** - Team knows current state
4. **Accountability** - Clear completion record
5. **Learning** - Implementation notes capture decisions

## Best Practices

### Product Planning

- **Start with vision** - Run `/prd:plan-product` before anything else
- **Update roadmap** - Keep roadmap.md current as priorities change
- **Reference tech-stack** - Use established patterns from tech-stack.md
- **Validate alignment** - Ensure features support product mission

### Specification Writing

- **Be specific** - Vague specs lead to implementation issues
- **Think in features** - Identify MVP and future enhancements
- **Document assumptions** - Make constraints explicit
- **Testable criteria** - Acceptance criteria must be verifiable
- **Apply principles** - Use SOLID, DRY, KISS, YAGNI

### Task Breakdown

- **Think vertically** - Never organize by horizontal layers
- **Working software** - Each task should produce working functionality
- **Small tasks** - Keep complexity 1-5 points (break down >8)
- **Clear dependencies** - Make blockers explicit
- **Test alongside** - Include test tasks with implementation

### Execution

- **Sequential first** - Complete one feature before starting next
- **Verify immediately** - Check acceptance criteria after each task
- **Update in real-time** - Don't batch file updates
- **Document decisions** - Add implementation notes as you go
- **Handle blockers** - Escalate issues early

## Examples

### New Product Workflow

```bash
# Establish foundation
> /prd:plan-product

[Answers strategic questions about vision, users, roadmap, tech stack]

✓ Product foundation created

# Create first feature
> /prd:write-spec user-signup

✓ Specification created

# Break into tasks
> /prd:create-tasks user-signup

✓ 3 features, 15 tasks created

# Implement
> /prd:execute-tasks user-signup

✓ All tasks complete
✓ Feature implemented and tested
```

### Complex Feature Workflow

```bash
# Scope complex integration
> /prd:scope-feature payment-gateway

[Detailed requirements interview]

✓ Requirements documented

# Write formal spec
> /prd:write-spec payment-gateway

✓ Specification created

# Break into tasks
> /prd:create-tasks payment-gateway

✓ 5 features, 32 tasks created

# Break down complex task
> /prd:break-task payment-gateway 2.4

✓ Task 2.4 split into 7 sub-tasks

# Implement
> /prd:execute-tasks payment-gateway

[Sequential execution with real-time updates]

✓ Implementation complete
```

## Troubleshooting

### Missing Product Context

```
Error: Product context not found.

Please run /prd:plan-product first to establish the product foundation.
```

**Solution:** Run `/prd:plan-product` to create mission.md, roadmap.md, tech-stack.md

### Specification Not Found

```
Error: Specification not found at .molcajete/prd/specs/feature-name/spec.md

Please run /prd:write-spec feature-name first.
```

**Solution:** Create specification before creating tasks

### Tasks Not Organized as Features

If tasks are organized horizontally (by layer), provide feedback:
- "Reorganize as vertical features"
- "Each feature should deliver working software"
- Agent will restructure tasks

### File Updates Not Happening

If orchestrator doesn't update files in real-time, remind:
- "Update tasks.md immediately after each task"
- "Don't wait until end to update files"
- This is required behavior

## Integration with Other Plugins

### code-principles Plugin

All agents reference software principles:
- `software-principles` - SOLID, DRY, KISS, YAGNI
- `task-breakdown` - Vertical feature methodology
- `testing-standards` - Test coverage guidelines

### Stack-Specific Plugins

The orchestrator delegates to:
- `solidity-dev` - Smart contract development
- `go-dev` - Go application development
- Framework-specific plugins as available

## Future Enhancements

Planned features:
- `/prd:update-roadmap` - Bulk roadmap updates
- `/prd:feature-status` - Quick status checks
- `/prd:estimate-feature` - Sizing before specification
- `/prd:dependency-graph` - Visualize feature dependencies
- `/prd:milestone-plan` - Group features into milestones
- `/prd:retrospective` - Capture learnings after implementation

## Contributing

To improve the product management plugin:

1. Edit skill templates for better guidance
2. Add examples for common scenarios
3. Update agent behavior in `agents/` directory
4. Test with real product workflows
5. Share improvements

## License

Part of the Claude Code plugin system.
