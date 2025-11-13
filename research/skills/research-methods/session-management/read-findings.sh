#!/bin/bash
# Read findings from session directory

# Usage:
#   read-findings.sh <session-id> [type]
#
#   session-id: Session ID
#   type: web|fetch|local|all (default: all)

read_findings() {
    local session_id=$1
    local type=${2:-all}

    if [ -z "${session_id}" ]; then
        echo "ERROR: Session ID required" >&2
        return 1
    fi

    # Get session directory
    local session_dir=$(bash skills/research-methods/session-management/get-session-dir.sh "${session_id}")
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Read findings based on type
    case "${type}" in
        web)
            ls -1 "${session_dir}/findings/web/"*.md 2>/dev/null || echo "No web findings"
            ;;
        fetch)
            ls -1 "${session_dir}/findings/fetch/"*.md 2>/dev/null || echo "No fetch findings"
            ;;
        local)
            if [ -f "${session_dir}/findings/local/references.json" ]; then
                cat "${session_dir}/findings/local/references.json"
            else
                echo "No local findings"
            fi
            ;;
        all)
            echo "=== Web Findings ==="
            ls -1 "${session_dir}/findings/web/"*.md 2>/dev/null || echo "None"
            echo ""
            echo "=== Fetch Findings ==="
            ls -1 "${session_dir}/findings/fetch/"*.md 2>/dev/null || echo "None"
            echo ""
            echo "=== Local Findings ==="
            if [ -f "${session_dir}/findings/local/references.json" ]; then
                cat "${session_dir}/findings/local/references.json"
            else
                echo "None"
            fi
            ;;
        *)
            echo "ERROR: Invalid type. Must be: web, fetch, local, or all" >&2
            return 1
            ;;
    esac
}

read_findings "$@"
