# [Feature Name] - Specification

**Created:** [YYYY-MM-DD]
**Last Updated:** [YYYY-MM-DD]
**Status:** Draft | Under Review | Approved | In Progress | Implemented

## Overview

### Feature Description
[2-3 paragraphs describing the feature. What is it? Why are we building it?]

### Strategic Alignment
**Product Mission:** [How this aligns with product mission from mission.md]
**User Value:** [Primary user benefit]
**Roadmap Priority:** [Why this feature now?]

### Requirements Reference
[Link to requirements.md if it exists, or brief summary of key requirements]

## Data Models

### Database Schema (if applicable)

#### Table: [table_name]
```sql
CREATE TABLE table_name (
  id SERIAL PRIMARY KEY,
  field1 VARCHAR(255) NOT NULL,
  field2 INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**Fields:**
- `id`: Primary key
- `field1`: [Description and validation rules]
- `field2`: [Description and validation rules]

**Indexes:**
- `idx_field1`: On field1 for [reason]

**Relationships:**
- Belongs to: [related_table]
- Has many: [related_table]

### Smart Contract Storage (if applicable)

#### Contract: [ContractName]
```solidity
contract ContractName {
    // State variables
    mapping(address => uint256) public balances;
    address public owner;

    // Events
    event BalanceUpdated(address indexed user, uint256 newBalance);
}
```

**State Variables:**
- `balances`: Maps user addresses to their balances
- `owner`: Contract owner address

**Storage Layout Considerations:**
- [Gas optimization notes]
- [Upgrade safety notes if using proxies]

## API Contracts

### REST Endpoints (if applicable)

#### POST /api/[resource]
**Purpose:** [What this endpoint does]

**Request:**
```json
{
  "field1": "string",
  "field2": 123,
  "field3": {
    "nested": "object"
  }
}
```

**Response (Success - 200):**
```json
{
  "id": "uuid",
  "field1": "string",
  "field2": 123,
  "created_at": "2025-01-01T00:00:00Z"
}
```

**Response (Error - 400):**
```json
{
  "error": "Validation failed",
  "details": {
    "field1": ["Required field missing"]
  }
}
```

**Authentication:** Bearer token required
**Rate Limiting:** 100 requests/minute
**Validation Rules:**
- field1: Required, max 255 chars
- field2: Required, integer, min 0

#### GET /api/[resource]/:id
[Similar structure]

### Smart Contract Functions (if applicable)

#### `function deposit() public payable`
**Purpose:** Allow users to deposit ETH

**Parameters:** None (payable)

**Returns:** None

**Events Emitted:**
- `BalanceUpdated(msg.sender, newBalance)`

**Access Control:** Public

**Gas Considerations:** ~50,000 gas

**Reverts:**
- If amount is 0
- If contract is paused

## User Interface

### Components

#### Component: [ComponentName]
**Purpose:** [What this component does]

**Props/State:**
- `prop1`: [Type] - [Description]
- `prop2`: [Type] - [Description]

**User Interactions:**
1. User clicks [button]
2. System validates [input]
3. System displays [feedback]
4. System navigates to [page]

**States:**
- Loading: [How component appears]
- Success: [How component appears]
- Error: [How component appears]

**Accessibility:**
- Keyboard navigation: [Tab order, shortcuts]
- Screen reader: [ARIA labels, announcements]
- Color contrast: [WCAG AA/AAA compliance]

### User Flows

#### Flow: [Flow Name]
1. **User Action:** [What user does]
   - **System Response:** [What system does]
   - **Validation:** [Any validation]

2. **User Action:** [Next action]
   - **System Response:** [Response]

3. **Success:** [End state]
   - **Alternative:** [Error path]

**Wireframe:** [Link to design]

## Integration Points

### External Services

#### Service: [Service Name]
**Purpose:** [Why we integrate with this service]
**Provider:** [Provider name and docs link]
**Authentication:** [API key, OAuth, etc.]
**Endpoints Used:**
- `GET /api/endpoint`: [Purpose]
- `POST /api/endpoint`: [Purpose]

**Data Flow:**
1. System sends [data] to service
2. Service processes and returns [result]
3. System stores/displays [result]

**Error Handling:**
- Timeout: [What happens]
- Rate limit: [What happens]
- Service down: [Fallback behavior]

**Cost:** [Pricing model, expected volume]

### Internal Services

#### Service: [Internal Service Name]
**Communication:** REST | GraphQL | Message Queue | Event Bus
**Endpoints:**
- [Endpoint]: [Purpose]

**Data Synchronization:**
- [How data stays in sync]

## Acceptance Criteria

### Functional Acceptance

- [ ] User can [action] successfully
- [ ] System validates [input] correctly
- [ ] Error messages are clear and actionable
- [ ] [Specific behavior] works as expected
- [ ] Edge case [X] is handled properly

### Non-Functional Acceptance

- [ ] API responds in under [X]ms for [Y]% of requests
- [ ] UI is responsive on mobile devices
- [ ] All accessibility requirements met (WCAG AA)
- [ ] Security scan passes with no critical issues
- [ ] Load testing handles [X] concurrent users

### Business Acceptance

- [ ] Feature solves [problem] for [user segment]
- [ ] Analytics tracking is implemented
- [ ] Documentation is complete
- [ ] Stakeholder approval obtained

## Verification

### Manual Testing Scenarios

#### Scenario 1: [Happy Path]
**Given:** [Initial state]
**When:** [User action]
**Then:** [Expected outcome]

#### Scenario 2: [Edge Case]
**Given:** [Initial state]
**When:** [User action]
**Then:** [Expected outcome]

#### Scenario 3: [Error Path]
**Given:** [Initial state]
**When:** [User action]
**Then:** [Expected error handling]

### Automated Testing Requirements

- **Unit Tests:** [What needs unit test coverage]
- **Integration Tests:** [What needs integration testing]
- **E2E Tests:** [What needs end-to-end testing]
- **Performance Tests:** [Load testing requirements]

### Success Metrics

**User Metrics:**
- Task completion rate > [X]%
- Time to complete task < [X] seconds
- Error rate < [X]%

**Technical Metrics:**
- API p95 latency < [X]ms
- Error rate < [X]%
- Uptime > [X]%

**Business Metrics:**
- [Conversion rate, retention, etc.]

## Implementation Notes

### Technical Decisions
- **Decision 1:** [Description and rationale]
- **Decision 2:** [Description and rationale]

### Known Limitations
- [Limitation 1: Description and when it might be addressed]
- [Limitation 2: Description]

### Future Enhancements
- [Enhancement 1: What could be improved in the future]
- [Enhancement 2: Description]

### Security Considerations
- [Security concern 1 and how it's addressed]
- [Security concern 2 and how it's addressed]

## Implementation Summary (Added after completion)

**Implemented:** [YYYY-MM-DD]
**Implemented By:** [Team or subagent]

### What Was Built
[Summary of what was actually implemented]

### Deviations from Spec
- [Deviation 1: Why it changed]
- [Deviation 2: Why it changed]

### Key Implementation Decisions
- [Decision 1: What was decided during implementation and why]
- [Decision 2: Description]

### Known Issues
- [Issue 1: Description and tracking link]
- [Issue 2: Description]

### Future Work
- [Task 1: What should be done next]
- [Task 2: Description]
