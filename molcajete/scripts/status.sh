#!/usr/bin/env bash
set -euo pipefail

# status.sh — Display dispatch progress from tasks.json.
#
# Usage: status.sh <tasks.json>

if ! command -v jq &>/dev/null; then
  echo "Error: jq required but not found." >&2
  exit 1
fi

if [ $# -ne 1 ]; then
  echo "Usage: status.sh <tasks.json>" >&2
  exit 1
fi

TASKS_JSON="$1"
if [ ! -f "$TASKS_JSON" ]; then
  echo "Error: tasks.json not found: $TASKS_JSON" >&2
  exit 1
fi

# ── Header ──

SPEC=$(jq -r '.spec_folder' "$TASKS_JSON")
BRANCH=$(jq -r '.base_branch' "$TASKS_JSON")
CREATED=$(jq -r '.created_at' "$TASKS_JSON")
UC_COUNT=$(jq '.use_cases | length' "$TASKS_JSON")
UC_DONE=$(jq '[.use_cases[] | select(.done == true)] | length' "$TASKS_JSON")

echo "Spec:    $SPEC"
echo "Branch:  $BRANCH"
echo "Created: $CREATED"
echo ""

# ── UC Summary ──

printf "%-16s %-8s %-24s %s\n" "UC" "Status" "Tester" "Subtasks"
printf "%-16s %-8s %-24s %s\n" "──────────────" "──────" "──────────────────────" "────────"

for uc_idx in $(seq 0 $((UC_COUNT - 1))); do
  uc_id=$(jq -r ".use_cases[$uc_idx].id" "$TASKS_JSON")
  uc_done=$(jq -r ".use_cases[$uc_idx].done" "$TASKS_JSON")

  tester_status=$(jq -r ".use_cases[$uc_idx].tester.status" "$TASKS_JSON")
  tester_scenarios=$(jq -r ".use_cases[$uc_idx].tester.scenarios_count // 0" "$TASKS_JSON")
  tester_retries=$(jq -r ".use_cases[$uc_idx].tester.retries // 0" "$TASKS_JSON")

  st_total=$(jq ".use_cases[$uc_idx].subtasks | length" "$TASKS_JSON")
  st_done=$(jq "[.use_cases[$uc_idx].subtasks[] | select(.status == \"done\")] | length" "$TASKS_JSON")
  st_failed=$(jq "[.use_cases[$uc_idx].subtasks[] | select(.status == \"failed\")] | length" "$TASKS_JSON")

  # UC status
  if [ "$uc_done" = "true" ]; then
    status="done"
  elif [ "$st_failed" -gt 0 ]; then
    status="failed"
  else
    status="pending"
  fi

  # Tester info
  tester_info="$tester_status"
  if [ "$tester_status" = "done" ]; then
    tester_info="done ($tester_scenarios scenarios)"
  elif [ "$tester_retries" -gt 0 ]; then
    tester_info="$tester_status (retries: $tester_retries)"
  fi

  printf "%-16s %-8s %-24s %s/%s\n" "$uc_id" "$status" "$tester_info" "$st_done" "$st_total"
done

echo ""

# ── Subtask Detail ──

echo "Subtask Detail:"
for uc_idx in $(seq 0 $((UC_COUNT - 1))); do
  uc_id=$(jq -r ".use_cases[$uc_idx].id" "$TASKS_JSON")
  st_count=$(jq ".use_cases[$uc_idx].subtasks | length" "$TASKS_JSON")

  echo "  $uc_id:"
  for st_idx in $(seq 0 $((st_count - 1))); do
    st_id=$(jq -r ".use_cases[$uc_idx].subtasks[$st_idx].id" "$TASKS_JSON")
    st_status=$(jq -r ".use_cases[$uc_idx].subtasks[$st_idx].status" "$TASKS_JSON")
    st_commit=$(jq -r ".use_cases[$uc_idx].subtasks[$st_idx].commit // \"-\"" "$TASKS_JSON")
    st_review=$(jq -r ".use_cases[$uc_idx].subtasks[$st_idx].review // \"-\"" "$TASKS_JSON")
    st_retries=$(jq -r ".use_cases[$uc_idx].subtasks[$st_idx].retries // 0" "$TASKS_JSON")
    st_error=$(jq -r ".use_cases[$uc_idx].subtasks[$st_idx].error // empty" "$TASKS_JSON")

    # Truncate commit to 7 chars
    if [ "$st_commit" != "-" ] && [ ${#st_commit} -gt 7 ]; then
      st_commit="${st_commit:0:7}"
    fi

    line="    $st_id  $st_status"
    [ "$st_commit" != "-" ] && line="$line  commit:$st_commit"
    [ "$st_review" != "-" ] && line="$line  review:$st_review"
    [ "$st_retries" -gt 0 ] && line="$line  retries:$st_retries"
    echo "$line"

    if [ -n "$st_error" ]; then
      echo "         error: $st_error"
    fi
  done
done

echo ""
echo "Total: $UC_DONE/$UC_COUNT UCs done"
