#!/bin/bash
# Create a new research session directory

set -e  # Exit on error

# Generate unique session ID
generate_session_id() {
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local random=$(head /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | head -c 6)
    echo "${timestamp}-${random}"
}

# Create session directory structure
create_session_structure() {
    local session_id=$1
    local session_dir=".molcajete/tmp/claude-code-researcher-${session_id}"

    # Check if directory already exists (collision prevention)
    if [ -d "${session_dir}" ]; then
        echo "ERROR: Session directory already exists: ${session_dir}" >&2
        return 1
    fi

    # Create directory structure
    mkdir -p "${session_dir}/findings/web"
    mkdir -p "${session_dir}/findings/fetch"
    mkdir -p "${session_dir}/findings/local"
    mkdir -p "${session_dir}/coordination"
    mkdir -p "${session_dir}/synthesis"
    mkdir -p "${session_dir}/output"

    # Create metadata file
    cat > "${session_dir}/meta.json" <<EOF
{
  "session_id": "${session_id}",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "status": "initialized",
  "version": "1.0"
}
EOF

    # Create initial status file
    cat > "${session_dir}/coordination/status.json" <<EOF
{
  "current_phase": "planning",
  "completed_tasks": [],
  "active_tasks": [],
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

    # Create empty log
    cat > "${session_dir}/coordination/log.md" <<EOF
# Research Session Log

Session ID: ${session_id}
Created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

---

EOF

    # Create symlink to latest session (for convenience)
    ln -snf "${session_dir}" .molcajete/tmp/claude-code-researcher-latest

    echo "${session_id}"
}

# Main execution
main() {
    local session_id=$(generate_session_id)

    if create_session_structure "${session_id}"; then
        echo "Session created: ${session_id}" >&2
        echo "Directory: .molcajete/tmp/claude-code-researcher-${session_id}" >&2
        echo "Symlink: .molcajete/tmp/claude-code-researcher-latest" >&2
        echo "${session_id}"  # Return session ID to stdout
        return 0
    else
        return 1
    fi
}

main "$@"
