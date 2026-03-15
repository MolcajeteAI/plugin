#!/usr/bin/env bash
set -euo pipefail

# Display formatted task status from tasks.json
# Usage: status.sh <spec-folder-path>

SPEC_FOLDER="${1:?Usage: status.sh <spec-folder-path>}"
TASKS_JSON="${SPEC_FOLDER}/tasks.json"

if [[ ! -f "$TASKS_JSON" ]]; then
  echo "No tasks.json found at $TASKS_JSON"
  exit 1
fi

echo ""
echo "=== Build Status: $(jq -r '.spec' "$TASKS_JSON") ==="
echo ""

total=$(jq '.tasks | length' "$TASKS_JSON")
completed=$(jq '[.tasks[] | select(.status == "completed")] | length' "$TASKS_JSON")
pending=$(jq '[.tasks[] | select(.status == "pending")] | length' "$TASKS_JSON")
in_progress=$(jq '[.tasks[] | select(.status == "in_progress")] | length' "$TASKS_JSON")
failed=$(jq '[.tasks[] | select(.status == "failed")] | length' "$TASKS_JSON")
merge_pending=$(jq '[.tasks[] | select(.status == "merge_pending")] | length' "$TASKS_JSON")

echo "Total: $total | Completed: $completed | Pending: $pending | In Progress: $in_progress | Merge Pending: $merge_pending | Failed: $failed"
echo ""

# Print task table
printf "%-25s %-40s %-12s %-10s %-15s\n" "TASK ID" "TITLE" "STATUS" "RETRIES" "COMMIT/ERROR"
printf "%-25s %-40s %-12s %-10s %-15s\n" "-------" "-----" "------" "-------" "------------"

jq -r '.tasks[] | [.id, .title[0:38], .status, (.retries | tostring), (.commit // .error // "-")] | @tsv' "$TASKS_JSON" | \
while IFS=$'\t' read -r id title status retries info; do
  printf "%-25s %-40s %-12s %-10s %-15s\n" "$id" "$title" "$status" "$retries" "$info"
done

echo ""
echo "Generated: $(jq -r '.generated' "$TASKS_JSON")"
