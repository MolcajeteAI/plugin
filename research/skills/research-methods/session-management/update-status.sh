#!/bin/bash
# Update coordination status

# Usage:
#   update-status.sh <session-id> <phase> <message>
#
#   session-id: Session ID
#   phase: planning|executing|synthesizing|complete
#   message: Status message

update_status() {
    local session_id=$1
    local phase=$2
    local message=$3

    if [ -z "${session_id}" ] || [ -z "${phase}" ] || [ -z "${message}" ]; then
        echo "ERROR: Missing required arguments" >&2
        echo "Usage: update-status.sh <session-id> <phase> <message>" >&2
        return 1
    fi

    # Get session directory
    local session_dir=$(bash skills/research-methods/session-management/get-session-dir.sh "${session_id}")
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Update status file
    cat > "${session_dir}/coordination/status.json" <<EOF
{
  "current_phase": "${phase}",
  "message": "${message}",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

    # Log the update
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") - Status: ${phase} - ${message}" >> \
        "${session_dir}/coordination/log.md"

    return 0
}

update_status "$@"
