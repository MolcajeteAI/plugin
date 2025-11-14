# Molcajete Setup Command - Specification

**Created:** 2025-11-14
**Last Updated:** 2025-11-14
**Status:** Draft

## Overview

### Feature Description

The Molcajete Setup Command is a CLI plugin that provides a streamlined, interactive setup experience for configuring Molcajete marketplace plugins in Claude Code. It automates the configuration of Claude settings by allowing users to select from available Molcajete plugins and automatically merging them into their ~/.claude/settings.local.json file with proper validation and error handling.

This command eliminates the barrier to entry for new users who want to leverage Molcajete's curated plugin collection. Rather than manually editing JSON configuration files and understanding Claude's settings structure, users can run a single command and interactively choose which specialized workflows they want to enable. The setup process is designed to be foolproof, handling edge cases like missing directories, invalid JSON, and permission issues gracefully.

### Strategic Alignment

**Product Mission:** Aligns with Molcajete.ai's mission to bring consistency, quality, and reliability to AI-assisted development by making the plugin installation process frictionless and error-free.

**User Value:** Eliminates manual configuration, reduces setup errors, speeds onboarding from zero to productive in under a minute, and preserves existing settings safely.

**Roadmap Priority:** Essential for initial user adoption - without easy setup, even the best plugins won't get used. This is a foundational piece that enables all other Molcajete features.

### Requirements Reference

Based on requirements.md: Interactive plugin selection, safe JSON merging, comprehensive error handling, macOS/Linux support for MVP, with future Windows support planned.

## Architecture

### Plugin Structure

This setup command follows the standard Molcajete markdown plugin architecture, consistent with existing plugins (defaults, git, prd, res, go, sol). It is **not** a standalone TypeScript application but rather:

**File Structure:**
```
molcajete/
├── commands/
│   └── setup.md          # Command definition (invoked via /molcajete:setup)
└── skills/
    └── setup-utils.md    # TypeScript skill with file operation logic
```

**Architecture Pattern:**

1. **Command File** (`molcajete/commands/setup.md`):
   - Markdown file that defines the `/molcajete:setup` slash command
   - Contains prompt instructions for Claude
   - Delegates to the setup-utils skill for actual execution
   - Uses AskUserQuestion tool for interactive plugin selection

2. **Skill File** (`molcajete/skills/setup-utils.md`):
   - Contains TypeScript code executed by Claude Code
   - Implements file reading, JSON parsing, merging, and writing
   - Handles error cases and validation
   - Returns results to the command context

**Execution Flow:**
```
User runs /molcajete:setup
    ↓
commands/setup.md expands
    ↓
Uses AskUserQuestion for plugin selection
    ↓
Invokes setup-utils skill with selected plugins
    ↓
Skill executes TypeScript to read/modify settings.local.json
    ↓
Returns success/error message to user
```

**Key Architectural Decisions:**

- **Markdown-based**: Follows Molcajete plugin conventions, not a compiled application
- **Skill-based execution**: TypeScript runs in Claude Code's execution context
- **Interactive UI via AskUserQuestion**: Uses Claude's native tool for selection interface
- **No external dependencies**: Leverages Claude Code's built-in capabilities

This approach ensures consistency with other Molcajete plugins and requires no separate build/distribution process.

## Data Models

### Configuration Schema

#### File: ~/.claude/settings.local.json

```json
{
  "plugins": {
    "molcajete/defaults": "latest",
    "molcajete/git": "latest",
    "molcajete/prd": "latest",
    "molcajete/research": "latest",
    "molcajete/go": "latest",
    "molcajete/sol": "latest"
  },
  // Other existing user settings preserved
}
```

**Fields:**
- `plugins`: Object mapping plugin IDs to version strings
  - Key format: `molcajete/[plugin-name]`
  - Value format: Version string, typically "latest"

**Validation Rules:**
- Plugin IDs must follow namespace/name format
- Version strings must be non-empty
- No duplicate plugin entries allowed
- Preserve all non-plugin settings unchanged

### Plugin Metadata

#### Structure: Plugin Definition

```typescript
interface PluginMetadata {
  id: string;           // e.g., "molcajete/prd"
  name: string;         // e.g., "Product Requirements"
  description: string;  // Brief description for selection UI
  version: string;      // Always "latest" for MVP
  selected?: boolean;   // User selection state (runtime only)
}
```

**Available Plugins:**
- `molcajete/defaults`: Core development principles and patterns
- `molcajete/git`: Git workflow automation and commit generation
- `molcajete/prd`: Product planning and requirements management
- `molcajete/research`: Research and analysis workflows
- `molcajete/go`: Go development patterns and standards
- `molcajete/sol`: Solidity smart contract development

## API Contracts

### Command Interface

#### Command: molcajete:setup

**Purpose:** Configure Molcajete plugins in Claude settings

**Invocation:**
```bash
# From Claude Code
/molcajete:setup
```

**Parameters:** None (interactive command)

**Return States:**
- Success: Settings updated with selected plugins
- Partial: Some plugins configured, others failed
- Error: Setup failed, no changes made

**Exit Codes:**
- 0: Success
- 1: General error
- 2: Permission denied
- 3: Invalid JSON
- 4: User cancelled

### Internal Functions

#### Function: readSettings()

**Purpose:** Read and parse existing settings file

**Signature:**
```typescript
function readSettings(): Promise<SettingsObject | null>
```

**Returns:** Parsed settings object or null if file doesn't exist

**Error Handling:**
- File not found: Return null (will create new)
- Invalid JSON: Throw with line number
- Permission denied: Throw with clear message

#### Function: mergePlugins()

**Purpose:** Merge selected plugins into existing settings

**Signature:**
```typescript
function mergePlugins(
  existing: SettingsObject,
  selected: PluginMetadata[]
): SettingsObject
```

**Logic:**
1. Preserve all existing settings
2. Add/update plugins object
3. Avoid duplicates
4. Maintain key ordering where possible

#### Function: writeSettings()

**Purpose:** Write settings back to file

**Signature:**
```typescript
function writeSettings(settings: SettingsObject): Promise<void>
```

**Behavior:**
- Create ~/.claude directory if missing
- Format JSON with 2-space indentation
- Atomic write (temp file + rename)
- Verify written content is valid JSON

## User Interface

### Components

#### Component: Plugin Selection Interface

**Purpose:** Present available plugins for user selection

**Display Format:**
```
Select Molcajete plugins to install:

[ ] defaults - Core development principles and patterns
[ ] git - Git workflow automation and commit generation
[x] prd - Product planning and requirements management
[x] research - Research and analysis workflows
[ ] go - Go development patterns and standards
[ ] sol - Solidity smart contract development

[a] Select all  [n] Select none  [Enter] Confirm selection
```

**User Interactions:**
1. User navigates with arrow keys
2. User toggles selection with space
3. User confirms with Enter
4. System validates at least one selection
5. System proceeds with installation

**States:**
- Initial: No plugins selected
- Selecting: User toggling options
- Processing: Installing selected plugins
- Complete: Success message displayed
- Error: Error message with recovery options

### User Flows

#### Flow: New User Setup

1. **User Action:** Run `/molcajete:setup`
   - **System Response:** Check for ~/.claude directory
   - **Validation:** Create if missing

2. **User Action:** Select desired plugins
   - **System Response:** Display selection interface
   - **Validation:** At least one plugin selected

3. **User Action:** Confirm selection
   - **System Response:** Create/update settings.local.json

4. **Success:** "Settings updated successfully. X plugins configured."
   - **Alternative:** Show specific errors for failed plugins

#### Flow: Existing User Addition

1. **User Action:** Run `/molcajete:setup`
   - **System Response:** Read existing settings.local.json
   - **Validation:** Parse JSON successfully

2. **User Action:** Select additional plugins
   - **System Response:** Show current plugins as pre-selected
   - **Validation:** Detect changes from current state

3. **User Action:** Confirm changes
   - **System Response:** Merge new plugins with existing

4. **Success:** "Settings updated. Added X new plugins."
   - **Alternative:** "No changes made - plugins already configured"

## Integration Points

### File System Integration

#### Service: Node.js File System API

**Purpose:** Read and write Claude configuration files

**Operations:**
- `fs.readFile`: Read existing settings
- `fs.writeFile`: Write updated settings
- `fs.mkdir`: Create ~/.claude directory
- `fs.access`: Check permissions

**Data Flow:**
1. Check directory existence and permissions
2. Read current settings if exist
3. Parse and validate JSON
4. Merge configurations
5. Write updated settings atomically

**Error Handling:**
- ENOENT: Create missing directories/files
- EACCES: Report permission requirements
- JSON parse error: Show line number and error

### Environment Integration

#### Service: Home Directory Resolution

**Purpose:** Locate user's Claude configuration

**Method:**
```typescript
const configPath = path.join(os.homedir(), '.claude', 'settings.local.json');
```

**Platform Support:**
- macOS: /Users/[username]/.claude/
- Linux: /home/[username]/.claude/
- Windows (future): C:\Users\[username]\.claude\

## Acceptance Criteria

### Functional Acceptance

- [ ] User can run molcajete:setup command from Claude Code
- [ ] Interactive plugin selection displays all available plugins
- [ ] User can select multiple plugins using space key
- [ ] User can select all/none with keyboard shortcuts
- [ ] Settings file is created if it doesn't exist
- [ ] Existing settings are preserved without modification
- [ ] Selected plugins are added to configuration
- [ ] No duplicate plugin entries are created
- [ ] JSON remains valid after all operations
- [ ] Clear success message displays plugin count

### Non-Functional Acceptance

- [ ] Setup completes in under 5 seconds
- [ ] Works reliably on macOS and Linux
- [ ] Handles settings files up to 1MB
- [ ] No external network calls required
- [ ] Clear error messages for all failure modes

### Business Acceptance

- [ ] Reduces setup time from minutes to seconds
- [ ] Eliminates JSON syntax errors during setup
- [ ] Provides consistent experience for all users
- [ ] No data loss of existing configurations

## Verification

### Manual Testing Scenarios

#### Scenario 1: New User Happy Path
**Given:** No ~/.claude directory exists
**When:** User runs molcajete:setup and selects prd and git plugins
**Then:** Directory created, settings.local.json created with selected plugins

#### Scenario 2: Existing Settings Preservation
**Given:** User has existing settings.local.json with custom configurations
**When:** User runs molcajete:setup and adds research plugin
**Then:** Research plugin added, all existing settings preserved unchanged

#### Scenario 3: Invalid JSON Recovery
**Given:** Existing settings.local.json contains invalid JSON
**When:** User runs molcajete:setup
**Then:** Clear error message with line number, offer to backup and recreate

#### Scenario 4: Permission Denied
**Given:** ~/.claude/settings.local.json is read-only
**When:** User runs molcajete:setup
**Then:** Clear permission error, suggest chmod command to fix

#### Scenario 5: User Cancellation
**Given:** Plugin selection interface is displayed
**When:** User presses Ctrl+C or ESC
**Then:** Setup cancelled cleanly, no changes made

### Automated Testing Requirements

- **Unit Tests:**
  - JSON parsing and merging logic
  - Plugin selection state management
  - Path resolution across platforms

- **Integration Tests:**
  - File system operations with temp directories
  - Settings merge with various existing configs
  - Error handling for all failure modes

- **E2E Tests:**
  - Complete flow from command to settings update
  - Verify Claude can load configured plugins

### Success Metrics

**User Metrics:**
- Setup completion rate > 95%
- Time to complete setup < 30 seconds
- Error rate < 5%

**Technical Metrics:**
- Zero data loss incidents
- JSON validation success rate 100%
- Cross-platform compatibility confirmed

## Implementation Notes

### Technical Decisions

- **Decision 1:** Use interactive selection rather than command arguments for better UX and discoverability
- **Decision 2:** Always use "latest" version for simplicity - version management deferred to future enhancement
- **Decision 3:** Atomic file writes using temp file + rename to prevent corruption
- **Decision 4:** No backup by default to keep MVP simple - users can use git for version control

### Known Limitations

- Windows support not included in MVP - will be added based on user demand
- No plugin verification - assumes plugins exist at specified IDs
- No dependency resolution - users must know which plugins work together
- No rollback mechanism - users rely on git or manual backup

### Future Enhancements

- Windows platform support with proper path handling
- Plugin verification to check accessibility before adding
- Version selection for specific plugin versions
- Automatic backup before modifications
- Update command to refresh existing plugins
- Remove command to uninstall plugins
- Dependency resolution for plugin requirements
- Custom plugin repository support

### Security Considerations

- No network calls prevents supply chain attacks
- Local-only operations ensure privacy
- No credential handling reduces attack surface
- File permissions checked before modifications
- JSON parsing uses safe parser to prevent injection

## Implementation Notes

### Phase 1: Foundation - COMPLETE (2025-11-14)

**What Was Built:**
- `molcajete/commands/setup.md`: Command file defining `/molcajete:setup` workflow
- `molcajete/skills/setup-utils.md`: TypeScript utilities for settings management

**Implementation Decisions:**

1. **Skill-based TypeScript execution**: Created TypeScript code in a skill file rather than a compiled package, following Molcajete plugin architecture
2. **AskUserQuestion for selection**: Used Claude's native tool instead of custom terminal UI library
3. **Atomic write pattern**: Implemented temp file + rename to prevent corruption
4. **Comprehensive error handling**: Handles ENOENT (missing file), EACCES (permissions), and SyntaxError (invalid JSON)

**Key Functions Implemented:**
- `readSettings()`: Reads settings.local.json with error handling
- `writeSettings()`: Atomic write with validation and directory creation
- `mergePlugins()`: Preserves existing settings while adding new plugins
- `setupPlugins()`: Main orchestration function

**Progress:** 9/26 story points (35% complete)

### Deviations from Original Spec

- Specified TypeScript skill approach instead of standalone application
- Used markdown plugin architecture (commands + skills) instead of compiled Node.js package

### Phase 2: Interactive Selection - COMPLETE (2025-11-14)

**What Was Built:**
- Enhanced `molcajete/commands/setup.md` with complete plugin metadata and AskUserQuestion implementation

**Implementation Decisions:**

1. **Explicit plugin catalog**: Added "Available Plugins" section listing all 6 plugins with descriptions for documentation
2. **Complete AskUserQuestion structure**: Implemented proper options array with label/description pairs for each plugin
3. **Pre-population logic**: Added code to read existing settings, extract current plugins, display to user before selection
4. **Success differentiation**: Success message differentiates between newly added and re-confirmed existing plugins

**Key Enhancements:**
- Plugin metadata clearly defined in command file
- AskUserQuestion properly structured with multiSelect: true
- Existing plugin detection and display before user selection
- Detailed success feedback showing new vs. existing plugins

**Progress:** 14/26 story points (54% complete)

### Next Steps

Phase 3 will enhance the TypeScript skill with JSON merge logic and validation.

## Implementation Summary (Final - To be added after completion)

**Implemented:** [To be added after full implementation]
**Implemented By:** [Team or subagent]

### What Was Built
[To be added after implementation]

### Known Issues
[To be added after implementation]

### Future Work
[To be added after implementation]
