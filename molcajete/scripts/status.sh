#!/usr/bin/env bash
set -euo pipefail

# Display formatted UC-level and subtask-level status from tasks.json
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

# UC-level summary
total_ucs=$(jq '.use_cases | length' "$TASKS_JSON")
completed_ucs=$(jq '[.use_cases[] | select(.phase == "completed")] | length' "$TASKS_JSON")
pending_ucs=$(jq '[.use_cases[] | select(.phase == "pending")] | length' "$TASKS_JSON")
planning_ucs=$(jq '[.use_cases[] | select(.phase == "planning")] | length' "$TASKS_JSON")
bdd_ucs=$(jq '[.use_cases[] | select(.phase == "bdd_writing")] | length' "$TASKS_JSON")
implementing_ucs=$(jq '[.use_cases[] | select(.phase == "implementing")] | length' "$TASKS_JSON")
validating_ucs=$(jq '[.use_cases[] | select(.phase == "validating")] | length' "$TASKS_JSON")
failed_ucs=$(jq '[.use_cases[] | select(.phase == "failed")] | length' "$TASKS_JSON")

echo "Use Cases: $total_ucs | Completed: $completed_ucs | Pending: $pending_ucs | Planning: $planning_ucs | BDD: $bdd_ucs | Implementing: $implementing_ucs | Validating: $validating_ucs | Failed: $failed_ucs"
echo ""

# Subtask-level summary
total_subtasks=$(jq '[.use_cases[].subtasks[]] | length' "$TASKS_JSON")
completed_subtasks=$(jq '[.use_cases[].subtasks[] | select(.status == "completed")] | length' "$TASKS_JSON")
pending_subtasks=$(jq '[.use_cases[].subtasks[] | select(.status == "pending")] | length' "$TASKS_JSON")
in_progress_subtasks=$(jq '[.use_cases[].subtasks[] | select(.status == "in_progress")] | length' "$TASKS_JSON")
failed_subtasks=$(jq '[.use_cases[].subtasks[] | select(.status == "failed")] | length' "$TASKS_JSON")

echo "Subtasks: $total_subtasks | Completed: $completed_subtasks | Pending: $pending_subtasks | In Progress: $in_progress_subtasks | Failed: $failed_subtasks"
echo ""

# UC table
printf "%-20s %-40s %-15s %-8s %-15s\n" "UC ID" "TITLE" "PHASE" "RETRIES" "ERROR"
printf "%-20s %-40s %-15s %-8s %-15s\n" "-----" "-----" "-----" "-------" "-----"

jq -r '.use_cases[] | [.id, .title[0:38], .phase, (.retries | tostring), (.error // "-")] | @tsv' "$TASKS_JSON" | \
while IFS=$'\t' read -r id title phase retries err; do
  printf "%-20s %-40s %-15s %-8s %-15s\n" "$id" "$title" "$phase" "$retries" "$err"
done

echo ""

# Subtask table
printf "%-25s %-40s %-12s %-8s %-15s\n" "SUBTASK ID" "TITLE" "STATUS" "RETRIES" "COMMIT/ERROR"
printf "%-25s %-40s %-12s %-8s %-15s\n" "----------" "-----" "------" "-------" "------------"

jq -r '.use_cases[].subtasks[] | [.id, .title[0:38], .status, (.retries | tostring), (.commit // .error // "-")] | @tsv' "$TASKS_JSON" | \
while IFS=$'\t' read -r id title status retries info; do
  printf "%-25s %-40s %-12s %-8s %-15s\n" "$id" "$title" "$status" "$retries" "$info"
done

echo ""
echo "Generated: $(jq -r '.generated' "$TASKS_JSON")"
echo "Timeout: $(jq -r '.timeout // 897' "$TASKS_JSON")s"
