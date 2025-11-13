#!/bin/bash
# Write a finding to the session directory

# Usage:
#   write-finding.sh <type> <session-id> <content-file>
#
#   type: web|fetch|local
#   session-id: Session ID
#   content-file: Path to markdown file with finding content

write_finding() {
    local type=$1
    local session_id=$2
    local content_file=$3

    # Validate arguments
    if [ -z "${type}" ] || [ -z "${session_id}" ] || [ -z "${content_file}" ]; then
        echo "ERROR: Missing required arguments" >&2
        echo "Usage: write-finding.sh <type> <session-id> <content-file>" >&2
        return 1
    fi

    # Validate type
    if [[ ! "${type}" =~ ^(web|fetch|local)$ ]]; then
        echo "ERROR: Invalid type. Must be: web, fetch, or local" >&2
        return 1
    fi

    # Get session directory
    local session_dir=$(bash skills/research-methods/session-management/get-session-dir.sh "${session_id}")
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Generate filename
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local content_hash=$(cat "${content_file}" | head -c 100 | md5 | cut -c1-8)
    local filename="${timestamp}-${content_hash}.md"
    local output_path="${session_dir}/findings/${type}/${filename}"

    # Copy content to findings directory
    cp "${content_file}" "${output_path}"

    # Log the write
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") - Finding written: ${type}/${filename}" >> \
        "${session_dir}/coordination/log.md"

    echo "${output_path}"
    return 0
}

write_finding "$@"
