#!/bin/bash
# Get session directory path from session ID

# Usage:
#   get-session-dir.sh 20251111-143052-a1b2c3

get_session_dir() {
    local session_id=$1

    if [ -z "${session_id}" ]; then
        echo "ERROR: Session ID required" >&2
        echo "Usage: get-session-dir.sh <session-id>" >&2
        return 1
    fi

    local session_dir=".molcajete/tmp/claude-code-researcher-${session_id}"

    if [ -d "${session_dir}" ]; then
        echo "${session_dir}"
        return 0
    else
        echo "ERROR: Session not found: ${session_id}" >&2
        return 1
    fi
}

get_session_dir "$@"
