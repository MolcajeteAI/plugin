---
description: Interactive plugin configuration to streamline Molcajete.ai onboarding
---

Execute the setup workflow to configure Molcajete plugins in Claude settings:

## Available Plugins

The following plugins are available in the Molcajete marketplace:

- **defaults**: Core development principles and patterns that all plugins follow
- **git**: Git workflow automation and commit message generation
- **prd**: Product planning and requirements management
- **research**: Research and analysis workflows
- **go**: Go development patterns and standards
- **sol**: Solidity smart contract development

## Workflow Steps

### 1. Read Existing Settings

Use the `molcajete:setup-utils` skill to read current configuration:

```typescript
import { readSettings } from 'molcajete:setup-utils';

// Read existing settings
const existingSettings = await readSettings();

// Extract currently configured plugins
const currentPlugins: string[] = [];
if (existingSettings?.plugins) {
  for (const pluginId of Object.keys(existingSettings.plugins)) {
    // Extract plugin name from "molcajete/[name]" format
    const match = pluginId.match(/^molcajete\/(.+)$/);
    if (match) {
      currentPlugins.push(match[1]);
    }
  }
}
```

### 2. Present Interactive Plugin Selection

Use the AskUserQuestion tool to let users select plugins:

```typescript
const response = await AskUserQuestion({
  questions: [{
    question: "Which Molcajete plugins would you like to install?",
    header: "Plugins",
    multiSelect: true,
    options: [
      {
        label: "defaults",
        description: "Core development principles and patterns that all plugins follow"
      },
      {
        label: "git",
        description: "Git workflow automation and commit message generation"
      },
      {
        label: "prd",
        description: "Product planning and requirements management"
      },
      {
        label: "research",
        description: "Research and analysis workflows"
      },
      {
        label: "go",
        description: "Go development patterns and standards"
      },
      {
        label: "sol",
        description: "Solidity smart contract development"
      }
    ]
  }]
});

// Extract selected plugins from response
const selectedPlugins = response.answers["Which Molcajete plugins would you like to install?"]
  .split(',')
  .map(s => s.trim())
  .filter(s => s.length > 0);
```

**Pre-population Logic:**

If the user already has plugins configured, inform them which ones are currently installed before showing the selection:

```typescript
if (currentPlugins.length > 0) {
  console.log(`Currently installed plugins: ${currentPlugins.join(', ')}`);
  console.log('You can add more plugins or re-confirm existing ones.');
}
```

### 3. Merge and Write Settings

Use the `molcajete:setup-utils` skill to merge and save:

```typescript
import { setupPlugins } from 'molcajete:setup-utils';

// Call the setup function with selected plugin IDs
const result = await setupPlugins(selectedPlugins);

if (result.success) {
  console.log(result.message);
} else {
  console.error(`Error: ${result.message}`);
}
```

### 4. Confirm Success

Display detailed feedback:

```typescript
if (result.success) {
  const newPlugins = selectedPlugins.filter(p => !currentPlugins.includes(p));
  const existingPlugins = selectedPlugins.filter(p => currentPlugins.includes(p));

  console.log('\n✓ Setup completed successfully!\n');

  if (newPlugins.length > 0) {
    console.log(`Added plugins: ${newPlugins.join(', ')}`);
  }

  if (existingPlugins.length > 0) {
    console.log(`Confirmed existing: ${existingPlugins.join(', ')}`);
  }

  console.log(`\nTotal configured: ${selectedPlugins.length} plugins`);
  console.log('\nNote: You may need to restart Claude Code for changes to take effect.');
}
```

## Error Handling

The setup-utils skill handles common error scenarios:

- **Invalid JSON**: Shows error with line number, offers to backup and recreate
- **Permission denied**: Provides chmod command to fix permissions
- **Missing directory**: Automatically creates ~/.claude directory
- **No selections**: If user selects no plugins, show message and exit gracefully

## Usage Example

```bash
# From Claude Code CLI
/molcajete:setup
```

The command will:
1. Check for existing configuration
2. Show interactive multi-select menu
3. Display currently installed plugins (if any)
4. Allow selection of plugins to install
5. Merge with existing settings safely
6. Confirm success with details
