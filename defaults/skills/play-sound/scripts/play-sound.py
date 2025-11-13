#!/usr/bin/env python3
"""
Cross-platform sound notification script for Claude Code.
Plays system sounds on macOS, Linux, and Windows.
"""

import sys
import platform
import os
import subprocess


def play_sound_macos(sound_type):
    """Play sound on macOS using system sounds."""
    sound_map = {
        'success': '/System/Library/Sounds/Hero.aiff',
        'prompt': '/System/Library/Sounds/Blow.aiff'
    }

    sound_file = sound_map.get(sound_type, sound_map['prompt'])

    try:
        subprocess.run(['afplay', sound_file], check=False,
                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except FileNotFoundError:
        # Fallback to osascript beep if afplay not available
        subprocess.run(['osascript', '-e', 'beep 1'], check=False,
                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def play_sound_linux(sound_type):
    """Play sound on Linux using system sounds."""
    # Try different sound paths common in Linux distributions
    sound_paths = [
        '/usr/share/sounds/freedesktop/stereo/',
        '/usr/share/sounds/ubuntu/stereo/',
        '/usr/share/sounds/gnome/default/alerts/'
    ]

    sound_map = {
        'success': ['complete.oga', 'message.oga', 'glass.oga'],
        'prompt': ['dialog-warning.oga', 'message-new-instant.oga', 'bell.oga']
    }

    sounds = sound_map.get(sound_type, sound_map['prompt'])

    # Try to find and play a sound file
    for base_path in sound_paths:
        for sound_file in sounds:
            full_path = os.path.join(base_path, sound_file)
            if os.path.exists(full_path):
                try:
                    # Try paplay first (PulseAudio)
                    subprocess.run(['paplay', full_path], check=False,
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    return
                except FileNotFoundError:
                    try:
                        # Fallback to aplay (ALSA)
                        subprocess.run(['aplay', '-q', full_path], check=False,
                                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                        return
                    except FileNotFoundError:
                        pass

    # If no sound found, try system beep
    try:
        subprocess.run(['beep', '-f', '800', '-l', '100'], check=False,
                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except FileNotFoundError:
        # Last resort: terminal bell
        print('\a', end='', flush=True)


def play_sound_windows(sound_type):
    """Play sound on Windows using winsound module."""
    try:
        import winsound

        # Use different frequencies/patterns for different sound types
        if sound_type == 'success':
            # Play a pleasant success sound (higher pitch, shorter)
            winsound.Beep(1000, 100)
        else:  # prompt
            # Play a notification sound (medium pitch, brief)
            winsound.Beep(800, 150)
    except ImportError:
        # Fallback to system default beep
        try:
            import winsound
            winsound.MessageBeep()
        except:
            print('\a', end='', flush=True)


def main():
    if len(sys.argv) < 2:
        sound_type = 'prompt'
    else:
        sound_type = sys.argv[1]

    system = platform.system()

    try:
        if system == 'Darwin':  # macOS
            play_sound_macos(sound_type)
        elif system == 'Linux':
            play_sound_linux(sound_type)
        elif system == 'Windows':
            play_sound_windows(sound_type)
        else:
            # Unknown system, use terminal bell
            print('\a', end='', flush=True)
    except Exception:
        # Silently fail if something goes wrong - don't interrupt workflow
        pass


if __name__ == '__main__':
    main()
