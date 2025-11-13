# Defaults Plugin

Defaults plugin for Claude Code providing essential hooks and audio feedback system.

## Overview

This plugin provides core functionality that enhances the Claude Code experience with non-intrusive audio notifications. It's designed as a "defaults" plugin - providing basic services that other plugins can build upon.

## Features

### Audio Feedback Hooks

- **Task Completion Sound**: Plays when tasks are completed successfully
- **User Prompt Sound**: Plays when user input or decisions are required
- **Cross-Platform**: Works seamlessly on macOS, Linux, and Windows
- **Zero Dependencies**: Uses only system sounds and Python standard library
- **Silent Failure**: Won't interrupt your workflow if sounds can't play

## Installation

This plugin is enabled by default in your Claude Code setup.

To manually enable:

```json
// In your settings.json
{
  "enabledPlugins": {
    "defaults@molcajete": true
  }
}
```

## Usage

Once enabled, the audio feedback works automatically:

1. **Complete a task** → Hear a success sound
2. **Get prompted for input** → Hear a notification sound

No additional configuration needed!

## Customization

### Modify Hook Behavior

Edit `settings.json` to customize or disable hooks:

```json
{
  "hooks": {
    "SubagentStop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ${CLAUDE_PLUGIN_ROOT}/skills/play-sound/scripts/play-sound.py success"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ${CLAUDE_PLUGIN_ROOT}/skills/play-sound/scripts/play-sound.py prompt"
          }
        ]
      }
    ]
  }
}
```

### Change Sounds

Edit `skills/play-sound/scripts/play-sound.py` to customize:
- Sound file paths (macOS/Linux)
- Beep frequencies and durations (Windows)
- Add new sound types

## Testing

Test the audio system manually:

```bash
cd skills/play-sound/scripts

# Test success sound
python3 play-sound.py success

# Test prompt sound
python3 play-sound.py prompt
```

## Platform Support

- **macOS**: Uses system sounds (Glass.aiff, Tink.aiff)
- **Linux**: Uses freedesktop/Ubuntu/GNOME sounds via paplay or aplay
- **Windows**: Uses winsound module with system beeps

All platforms use sounds available by default on the latest OS versions.

## Skills

### play-sound

Cross-platform audio feedback system. See `skills/play-sound/SKILL.md` for detailed documentation.

## Architecture

This plugin follows the defaults plugin pattern:
- **Type**: Foundation (library-only, no commands/agents)
- **Skills Only**: Provides reusable functionality via skills
- **Hooks**: Defines event hooks for integration
- **Default Enabled**: Active by default for all users

## Contributing

When extending this plugin:
1. Keep it lightweight and dependency-free
2. Ensure cross-platform compatibility
3. Fail silently to avoid interrupting workflows
4. Document all customization options

## License

Part of Ivan's personal Claude Code setup.
