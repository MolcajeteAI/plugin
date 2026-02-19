---
name: clipboard
description: >-
  Cross-platform clipboard operations. Use when copying text to the system
  clipboard via Bash.
---

# Clipboard

## Platform Detection

Detect the platform and use the correct clipboard command:

| Platform | Command |
|----------|---------|
| macOS | `pbcopy` |
| Linux (X11) | `xclip -selection clipboard` |
| Linux (Wayland) | `wl-copy` |
| WSL / Windows | `clip.exe` |

## Rules

- Use `echo -n` (not `printf`) when piping to the clipboard command — `printf` fails in sandboxed environments
- Always confirm to the user that the text was copied
