#!/usr/bin/env bash
set -euo pipefail

# Coordinated build dispatcher
# Usage: dispatch.sh <spec-folder-path>
#
# Reads tasks.json from the spec folder, groups tasks into topological levels
# by dependencies, and dispatches up to N tasks concurrently per level.
#
# Environment:
#   MOLCAJETE_MAX_PARALLEL - max concurrent tasks per level (default: 1)
#   MOLCAJETE_TASK_TIMEOUT - timeout per task in seconds (default: 900)

SPEC_FOLDER="${1:?Usage: dispatch.sh <spec-folder-path>}"
TASKS_JSON="${SPEC_FOLDER}/tasks.json"
MAX_PARALLEL="${MOLCAJETE_MAX_PARALLEL:-1}"
TIMEOUT="${MOLCAJETE_TASK_TIMEOUT:-900}"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
MAX_RETRIES=2
SHUTDOWN=0

# Derive project directory and worktree base (inside project, gitignored)
PROJECT_DIR=$(git -C "$SPEC_FOLDER" rev-parse --show-toplevel)
WORKTREE_BASE="${PROJECT_DIR}/.molcajete/worktrees"
LOG_DIR="${PROJECT_DIR}/.molcajete/logs"
mkdir -p "$WORKTREE_BASE" "$LOG_DIR"

# Ensure worktree directory is gitignored
if ! grep -qxF '/.molcajete/' "${PROJECT_DIR}/.gitignore" 2>/dev/null; then
  echo '/.molcajete/' >> "${PROJECT_DIR}/.gitignore"
fi

# Commit housekeeping files so worktrees get a clean snapshot
git -C "$PROJECT_DIR" add "$TASKS_JSON" "${PROJECT_DIR}/.gitignore"
if ! git -C "$PROJECT_DIR" diff --cached --quiet 2>/dev/null; then
  spec_name=$(basename "$SPEC_FOLDER")
  git -C "$PROJECT_DIR" commit -m "chore: bootstrap dispatch for ${spec_name}"
fi

# Build the dev command prompt from dev.md with resolved paths
build_dev_prompt() {
  local task_id="$1"
  local prompt
  # Read dev.md and strip YAML frontmatter (BSD sed compatible)
  prompt=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2{print}' "$PLUGIN_ROOT/commands/dev-run.md")
  # Substitute variables
  prompt="${prompt//\$ARGUMENTS/$task_id}"
  prompt="${prompt//\$\{CLAUDE_PLUGIN_ROOT\}/$PLUGIN_ROOT}"
  echo "$prompt"
}

trap 'echo ""; echo "[coordinator] Received shutdown signal. Preserving worktrees and saving state."; SHUTDOWN=1' INT TERM

log() { echo "[coordinator] $*"; }
error() { echo "[coordinator] ERROR: $*" >&2; }

# Check prerequisites
if ! command -v jq &>/dev/null; then
  error "jq is required. Install with: brew install jq"
  exit 1
fi

if [[ ! -f "$TASKS_JSON" ]]; then
  error "tasks.json not found at $TASKS_JSON"
  exit 1
fi

# Get pending tasks sorted by dependency level
get_pending_tasks() {
  jq -r '.tasks[] | select(.status == "pending") | .id' "$TASKS_JSON"
}

# Check if all dependencies of a task are completed
deps_met() {
  local task_id="$1"
  local deps
  deps=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | .dependencies[]?' "$TASKS_JSON")

  if [[ -z "$deps" ]]; then
    return 0
  fi

  while IFS= read -r dep; do
    local dep_status
    dep_status=$(jq -r --arg id "$dep" '.tasks[] | select(.id == $id) | .status' "$TASKS_JSON")
    if [[ "$dep_status" != "completed" ]]; then
      return 1
    fi
  done <<< "$deps"
  return 0
}

# Update task status in tasks.json
update_task() {
  local task_id="$1"
  local field="$2"
  local value="$3"
  local tmp
  tmp=$(mktemp)
  jq --arg id "$task_id" --arg field "$field" --arg val "$value" \
    '(.tasks[] | select(.id == $id))[$field] = $val' "$TASKS_JSON" > "$tmp" \
    && mv "$tmp" "$TASKS_JSON"
}

update_task_num() {
  local task_id="$1"
  local field="$2"
  local value="$3"
  local tmp
  tmp=$(mktemp)
  jq --arg id "$task_id" --arg field "$field" --argjson val "$value" \
    '(.tasks[] | select(.id == $id))[$field] = $val' "$TASKS_JSON" > "$tmp" \
    && mv "$tmp" "$TASKS_JSON"
}

# Dispatch a single task
dispatch_task() {
  local task_id="$1"
  local worktree_name="task-${task_id//\//-}"

  local worktree_path="$WORKTREE_BASE/$worktree_name"
  local branch_name="worktree-$worktree_name"

  log "Dispatching: $task_id (worktree: $worktree_path)"
  update_task "$task_id" "status" "in_progress"
  update_task "$task_id" "worktree" "$worktree_name"

  # Clean up stale worktree/branch from previous attempts
  if [[ -d "$worktree_path" ]]; then
    git -C "$PROJECT_DIR" worktree remove --force "$worktree_path" 2>/dev/null || true
  fi
  git -C "$PROJECT_DIR" branch -D "$branch_name" 2>/dev/null || true

  # Create worktree from the project repo
  if ! git -C "$PROJECT_DIR" worktree add "$worktree_path" -b "$branch_name" 2>&1; then
    error "Failed to create worktree for $task_id"
    update_task "$task_id" "status" "failed"
    update_task "$task_id" "error" "worktree_creation"
    return 1
  fi

  local dev_prompt
  dev_prompt=$(build_dev_prompt "$task_id")

  local output
  local exit_code=0
  output=$(unset CLAUDECODE; cd "$worktree_path" && timeout "${TIMEOUT}s" claude --dangerously-skip-permissions -p "$dev_prompt" --output-format json 2>&1) || exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    log "Task $task_id completed successfully"
    update_task "$task_id" "status" "merge_pending"

    # Extract commit hash from output if available
    local commit_hash
    commit_hash=$(echo "$output" | jq -r '.commit_hash // empty' 2>/dev/null || true)
    if [[ -n "$commit_hash" ]]; then
      update_task "$task_id" "commit" "$commit_hash"
    fi
  elif [[ $exit_code -eq 124 ]]; then
    error "Task $task_id timed out after ${TIMEOUT}s"
    update_task "$task_id" "status" "failed"
    update_task "$task_id" "error" "timeout"
    return 1
  else
    error "Task $task_id failed (exit code: $exit_code)"
    update_task "$task_id" "status" "failed"

    # Detect specific failure types
    if echo "$output" | grep -qi "rate limit"; then
      update_task "$task_id" "error" "rate_limit"
      return 2  # Signal rate limit
    elif echo "$output" | grep -qi "spend limit\|budget"; then
      update_task "$task_id" "error" "spend_limit"
      return 3  # Signal spend limit
    elif echo "$output" | grep -qi "context.*exhaust\|context.*limit"; then
      update_task "$task_id" "error" "context_exhaustion"
      return 1
    else
      update_task "$task_id" "error" "execution_failure"
      return 1
    fi
  fi
}

# Retry a failed task with backoff
retry_task() {
  local task_id="$1"
  local attempt="$2"
  local error_type
  error_type=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | .error // "unknown"' "$TASKS_JSON")

  # Backoff for rate limits
  if [[ "$error_type" == "rate_limit" ]]; then
    local delay=$((30 * attempt))
    log "Rate limit hit. Backing off ${delay}s before retrying $task_id (attempt $attempt)"
    sleep "$delay"
  fi

  update_task "$task_id" "status" "pending"
  update_task "$task_id" "error" "null"
  update_task_num "$task_id" "retries" "$attempt"

  dispatch_task "$task_id"
}

# Main loop
log "Starting coordinated build for $SPEC_FOLDER"
log "Max parallel: $MAX_PARALLEL | Timeout: ${TIMEOUT}s | Max retries: $MAX_RETRIES"

completed_count=$(jq '[.tasks[] | select(.status == "completed")] | length' "$TASKS_JSON")
total_count=$(jq '.tasks | length' "$TASKS_JSON")
log "Progress: $completed_count/$total_count tasks completed"

while true; do
  if [[ $SHUTDOWN -eq 1 ]]; then
    log "Shutting down gracefully. State saved to $TASKS_JSON"
    break
  fi

  # Collect ready tasks (pending + deps met)
  ready_tasks=()
  while IFS= read -r task_id; do
    [[ -z "$task_id" ]] && continue
    if deps_met "$task_id"; then
      ready_tasks+=("$task_id")
    fi
  done < <(get_pending_tasks)

  # No ready tasks
  if [[ ${#ready_tasks[@]} -eq 0 ]]; then
    pending=$(jq '[.tasks[] | select(.status == "pending")] | length' "$TASKS_JSON")
    failed=$(jq '[.tasks[] | select(.status == "failed")] | length' "$TASKS_JSON")

    if [[ $pending -eq 0 && $failed -eq 0 ]]; then
      log "All tasks completed successfully"
      break
    elif [[ $pending -gt 0 ]]; then
      # Check if remaining pending tasks have unmet deps due to failures
      log "No ready tasks. $pending pending, $failed failed. Blocked by failed dependencies."
      break
    else
      log "No pending tasks. $failed failed."
      break
    fi
  fi

  # Dispatch ready tasks up to MAX_PARALLEL
  pids=()
  dispatched_ids=()
  for task_id in "${ready_tasks[@]}"; do
    if [[ ${#pids[@]} -ge $MAX_PARALLEL ]]; then
      break
    fi

    dispatch_task "$task_id" &
    pids+=($!)
    dispatched_ids+=("$task_id")
  done

  # Wait for all dispatched tasks in this level
  for i in "${!pids[@]}"; do
    local_exit=0
    wait "${pids[$i]}" || local_exit=$?
    task_id="${dispatched_ids[$i]}"

    if [[ $local_exit -ne 0 ]]; then
      # Check retry eligibility
      retries=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | .retries' "$TASKS_JSON")

      if [[ $local_exit -eq 3 ]]; then
        log "Spend limit detected. Pausing pipeline."
        SHUTDOWN=1
        break
      elif [[ $retries -lt $MAX_RETRIES ]]; then
        log "Retrying $task_id (attempt $((retries + 1)))"
        retry_task "$task_id" "$((retries + 1))" &
        wait $! || true
      else
        log "Task $task_id failed after $MAX_RETRIES retries. Skipping."
      fi
    fi
  done

  # Sequential merge phase -- one at a time to avoid git lock contention
  for task_id in "${dispatched_ids[@]}"; do
    task_status=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | .status' "$TASKS_JSON")
    [[ "$task_status" != "merge_pending" ]] && continue

    worktree_name="task-${task_id//\//-}"
    log "Merging worktree for $task_id"

    if bash "$SCRIPTS_DIR/merge.sh" "$worktree_name" "$PROJECT_DIR" 2>&1; then
      update_task "$task_id" "status" "completed"
    else
      error "Merge failed for $task_id. Worktree preserved at $worktree_name"
      update_task "$task_id" "status" "failed"
      update_task "$task_id" "error" "merge_conflict"
    fi
  done
done

# Final status
bash "$SCRIPTS_DIR/status.sh" "$SPEC_FOLDER"

completed=$(jq '[.tasks[] | select(.status == "completed")] | length' "$TASKS_JSON")
failed=$(jq '[.tasks[] | select(.status == "failed")] | length' "$TASKS_JSON")

if [[ $failed -gt 0 ]]; then
  log "Build completed with $failed failed task(s). Review tasks.json for details."
  exit 1
else
  log "Build completed successfully. $completed/$total_count tasks done."
fi
