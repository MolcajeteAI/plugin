#!/bin/bash
# Cleanup session directory

# Usage:
#   cleanup-session.sh <session-id>       # Delete specific session
#   cleanup-session.sh --all              # Delete all sessions
#   cleanup-session.sh --older-than 7     # Delete sessions older than 7 days

cleanup_session() {
    local arg=$1

    case "${arg}" in
        --all)
            echo "Removing all research sessions..."
            rm -rf .molcajete/tmp/claude-code-researcher-*/
            rm -f .molcajete/tmp/claude-code-researcher-latest
            echo "All sessions removed"
            ;;
        --older-than)
            local days=$2
            echo "Removing sessions older than ${days} days..."
            find .molcajete/tmp -maxdepth 1 -name "claude-code-researcher-*" -type d -mtime +${days} -exec rm -rf {} \;
            echo "Old sessions removed"
            ;;
        *)
            # Specific session ID
            local session_id=$1
            local session_dir=".molcajete/tmp/claude-code-researcher-${session_id}"

            if [ -d "${session_dir}" ]; then
                echo "Removing session: ${session_id}"
                rm -rf "${session_dir}"

                # Update symlink if it pointed to this session
                if [ -L .molcajete/tmp/claude-code-researcher-latest ]; then
                    local link_target=$(readlink .molcajete/tmp/claude-code-researcher-latest)
                    if [ "${link_target}" = "${session_dir}" ]; then
                        rm -f .molcajete/tmp/claude-code-researcher-latest
                    fi
                fi

                echo "Session removed"
            else
                echo "ERROR: Session not found: ${session_id}" >&2
                return 1
            fi
            ;;
    esac
}

cleanup_session "$@"
