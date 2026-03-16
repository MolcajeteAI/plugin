#!/usr/bin/env bash
set -euo pipefail

# UC-phase dispatch pipeline
# Usage: dispatch.sh <spec-folder-path>
#
# Reads tasks.json (UC-nested schema) from the spec folder and drives each
# use case through a 5-phase pipeline: plan -> bdd -> implement -> validate -> done.
# Within each UC, subtasks dispatch sequentially in dependency order.
#
# Environment:
#   MOLCAJETE_MAX_PARALLEL - max concurrent UCs (default: 1)
#   MOLCAJETE_TASK_TIMEOUT - timeout per claude -p call in seconds (default: 897)

SPEC_FOLDER="${1:?Usage: dispatch.sh <spec-folder-path>}"
TASKS_JSON="${SPEC_FOLDER}/tasks.json"
MAX_PARALLEL="${MOLCAJETE_MAX_PARALLEL:-1}"
TIMEOUT="${MOLCAJETE_TASK_TIMEOUT:-897}"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
MAX_RETRIES=2
SHUTDOWN=0

# Derive project directory and worktree base (inside project, gitignored)
PROJECT_DIR=$(git -C "$SPEC_FOLDER" rev-parse --show-toplevel)
WORKTREE_BASE="${PROJECT_DIR}/.molcajete/worktrees"
LOG_DIR="${PROJECT_DIR}/.molcajete/logs"
MERGE_LOCK="${PROJECT_DIR}/.molcajete/merge.lock"
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

# ---------------------------------------------------------------------------
# Merge lock helpers -- serialize merges to avoid git lock contention
# ---------------------------------------------------------------------------
acquire_merge_lock() {
  while ! mkdir "$MERGE_LOCK" 2>/dev/null; do
    sleep 1
  done
}

release_merge_lock() {
  rmdir "$MERGE_LOCK" 2>/dev/null || true
}

# Clean up stale merge lock from previous runs
rmdir "$MERGE_LOCK" 2>/dev/null || true

trap 'echo ""; echo "[coordinator] Received shutdown signal. Preserving worktrees and saving state."; SHUTDOWN=1; rmdir "$MERGE_LOCK" 2>/dev/null || true' INT TERM

log() { echo "[coordinator] $*"; }
error() { echo "[coordinator] ERROR: $*" >&2; }

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------
if ! command -v jq &>/dev/null; then
  error "jq is required. Install with: brew install jq"
  exit 1
fi

if [[ ! -f "$TASKS_JSON" ]]; then
  error "tasks.json not found at $TASKS_JSON"
  exit 1
fi

# ---------------------------------------------------------------------------
# tasks.json accessors (UC-nested schema)
# ---------------------------------------------------------------------------

# Get UC phase
get_uc_phase() {
  local uc_id="$1"
  jq -r --arg id "$uc_id" '.use_cases[] | select(.id == $id) | .phase' "$TASKS_JSON"
}

# Update UC phase
update_uc_phase() {
  local uc_id="$1"
  local phase="$2"
  local tmp
  tmp=$(mktemp)
  jq --arg id "$uc_id" --arg phase "$phase" \
    '(.use_cases[] | select(.id == $id)).phase = $phase' "$TASKS_JSON" > "$tmp" \
    && mv "$tmp" "$TASKS_JSON"
}

# Update UC error
update_uc_error() {
  local uc_id="$1"
  local err="$2"
  local tmp
  tmp=$(mktemp)
  jq --arg id "$uc_id" --arg err "$err" \
    '(.use_cases[] | select(.id == $id)).error = $err' "$TASKS_JSON" > "$tmp" \
    && mv "$tmp" "$TASKS_JSON"
}

# Increment UC retries and return new count
increment_uc_retries() {
  local uc_id="$1"
  local tmp
  tmp=$(mktemp)
  jq --arg id "$uc_id" \
    '(.use_cases[] | select(.id == $id)).retries += 1' "$TASKS_JSON" > "$tmp" \
    && mv "$tmp" "$TASKS_JSON"
  jq -r --arg id "$uc_id" '.use_cases[] | select(.id == $id) | .retries' "$TASKS_JSON"
}

# Get UC retries
get_uc_retries() {
  local uc_id="$1"
  jq -r --arg id "$uc_id" '.use_cases[] | select(.id == $id) | .retries // 0' "$TASKS_JSON"
}

# Update subtask status
update_subtask() {
  local uc_id="$1"
  local subtask_id="$2"
  local field="$3"
  local value="$4"
  local tmp
  tmp=$(mktemp)
  jq --arg uc "$uc_id" --arg st "$subtask_id" --arg f "$field" --arg v "$value" \
    '(.use_cases[] | select(.id == $uc) | .subtasks[] | select(.id == $st))[$f] = $v' \
    "$TASKS_JSON" > "$tmp" \
    && mv "$tmp" "$TASKS_JSON"
}

# Update subtask numeric field
update_subtask_num() {
  local uc_id="$1"
  local subtask_id="$2"
  local field="$3"
  local value="$4"
  local tmp
  tmp=$(mktemp)
  jq --arg uc "$uc_id" --arg st "$subtask_id" --arg f "$field" --argjson v "$value" \
    '(.use_cases[] | select(.id == $uc) | .subtasks[] | select(.id == $st))[$f] = $v' \
    "$TASKS_JSON" > "$tmp" \
    && mv "$tmp" "$TASKS_JSON"
}

# List all UC IDs
get_all_uc_ids() {
  jq -r '.use_cases[].id' "$TASKS_JSON"
}

# Get UCs whose cross-UC dependencies are met.
# A UC is ready when all subtasks in OTHER UCs that its own subtasks depend on are completed.
get_ready_ucs() {
  jq -r '
    [.use_cases[] | {id: .id, phase: .phase, deps: [.subtasks[].dependencies[]?]}] as $ucs |
    .use_cases as $all |
    $ucs[] |
    select(.phase != "completed" and .phase != "failed") |
    . as $uc |
    # Collect cross-UC dependency subtask IDs
    [$uc.deps[] | select(startswith($uc.id) | not)] as $cross_deps |
    # Check if all cross-UC deps are completed
    if ($cross_deps | length) == 0 then .id
    else
      if [$cross_deps[] | . as $dep |
        $all[] | .subtasks[]? | select(.id == $dep) | .status == "completed"
      ] | all then .id
      else empty
      end
    end
  ' "$TASKS_JSON"
}

# Get next pending subtask within a UC (in dependency order)
get_next_ready_subtask() {
  local uc_id="$1"
  jq -r --arg uc "$uc_id" '
    .use_cases[] | select(.id == $uc) |
    .subtasks[] | select(.status == "pending") |
    # Check that all dependencies are completed
    . as $st |
    if (($st.dependencies // []) | length) == 0 then .id
    else
      [($st.dependencies // [])[] | . as $dep |
        [$st | path(.)][0] as $_ |  # dummy to stay in scope
        $dep
      ] as $deps |
      # Look up each dep status in the full doc
      if [$deps[] | . as $d | input_line_number == 0 or true] | all then .id
      else empty
      end
    end
  ' "$TASKS_JSON" 2>/dev/null | head -1

  # Simpler fallback: get first pending subtask whose deps are all completed
  # The jq above can be tricky with nested lookups; use a reliable version:
}

# Reliable version: get next ready subtask
get_next_ready_subtask() {
  local uc_id="$1"
  local pending_subtasks
  pending_subtasks=$(jq -r --arg uc "$uc_id" \
    '.use_cases[] | select(.id == $uc) | .subtasks[] | select(.status == "pending") | .id' \
    "$TASKS_JSON")

  for subtask_id in $pending_subtasks; do
    local deps_met=true
    local deps
    deps=$(jq -r --arg uc "$uc_id" --arg st "$subtask_id" \
      '.use_cases[] | select(.id == $uc) | .subtasks[] | select(.id == $st) | (.dependencies // [])[]' \
      "$TASKS_JSON" 2>/dev/null || true)

    for dep in $deps; do
      local dep_status
      dep_status=$(jq -r --arg dep "$dep" \
        '[.use_cases[].subtasks[] | select(.id == $dep) | .status][0] // "unknown"' \
        "$TASKS_JSON")
      if [[ "$dep_status" != "completed" ]]; then
        deps_met=false
        break
      fi
    done

    if [[ "$deps_met" == "true" ]]; then
      echo "$subtask_id"
      return
    fi
  done
}

# Check if all subtasks in a UC are completed
all_subtasks_done() {
  local uc_id="$1"
  local pending
  pending=$(jq --arg uc "$uc_id" \
    '[.use_cases[] | select(.id == $uc) | .subtasks[] | select(.status != "completed")] | length' \
    "$TASKS_JSON")
  [[ "$pending" -eq 0 ]]
}

# Check if any subtask in a UC has failed
any_subtask_failed() {
  local uc_id="$1"
  local failed
  failed=$(jq --arg uc "$uc_id" \
    '[.use_cases[] | select(.id == $uc) | .subtasks[] | select(.status == "failed")] | length' \
    "$TASKS_JSON")
  [[ "$failed" -gt 0 ]]
}

# ---------------------------------------------------------------------------
# Prompt builders -- strip YAML frontmatter and substitute variables
# ---------------------------------------------------------------------------
build_phase_prompt() {
  local command_file="$1"
  local arguments="$2"
  local prompt
  prompt=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2{print}' "$command_file")
  prompt="${prompt//\$ARGUMENTS/$arguments}"
  prompt="${prompt//\$\{CLAUDE_PLUGIN_ROOT\}/$PLUGIN_ROOT}"
  echo "$prompt"
}

# ---------------------------------------------------------------------------
# Worktree management
# ---------------------------------------------------------------------------
setup_worktree() {
  local worktree_name="$1"
  local worktree_path="$WORKTREE_BASE/$worktree_name"
  local branch_name="worktree-$worktree_name"

  local reused=0
  if [[ -d "$worktree_path" ]]; then
    local stale_changes
    stale_changes=$(git -C "$worktree_path" status --porcelain 2>/dev/null || true)
    local stale_commits
    stale_commits=$(git -C "$PROJECT_DIR" log "HEAD..${branch_name}" --oneline 2>/dev/null || true)

    if [[ -n "$stale_changes" || -n "$stale_commits" ]]; then
      log "Worktree $worktree_name has WIP from previous attempt. Preserving for retry." >&2
      reused=1
    else
      git -C "$PROJECT_DIR" worktree remove --force "$worktree_path" >/dev/null 2>&1 || true
      git -C "$PROJECT_DIR" branch -D "$branch_name" >/dev/null 2>&1 || true
    fi
  else
    git -C "$PROJECT_DIR" branch -D "$branch_name" >/dev/null 2>&1 || true
  fi

  if [[ $reused -eq 0 ]]; then
    if ! git -C "$PROJECT_DIR" worktree add "$worktree_path" -b "$branch_name" >/dev/null 2>&1; then
      error "Failed to create worktree $worktree_name"
      return 1
    fi
  fi

  echo "$worktree_path"
}

# Merge a worktree and clean up
merge_worktree() {
  local worktree_name="$1"
  acquire_merge_lock
  local merge_exit=0
  bash "$SCRIPTS_DIR/merge.sh" "$worktree_name" "$PROJECT_DIR" 2>&1 || merge_exit=$?
  release_merge_lock
  return $merge_exit
}

# ---------------------------------------------------------------------------
# Run a claude -p call and handle output/errors
# Returns: 0=success, 1=failure, 2=rate_limit, 3=spend_limit
# ---------------------------------------------------------------------------
run_claude_phase() {
  local worktree_path="$1"
  local prompt="$2"
  local phase_label="$3"
  local log_prefix="$4"

  local output
  local exit_code=0
  output=$(unset CLAUDECODE; cd "$worktree_path" && timeout "${TIMEOUT}s" claude --dangerously-skip-permissions -p "$prompt" --output-format json 2>&1) || exit_code=$?

  # Log raw output
  local log_file="${LOG_DIR}/${log_prefix}-$(date -u +%Y%m%d-%H%M%S).log"
  echo "$output" > "$log_file"
  log "$phase_label output logged to $log_file"

  if [[ $exit_code -eq 0 ]]; then
    # Check for headless failure in output
    if echo "$output" | jq -e '.result // empty' 2>/dev/null | grep -q "HEADLESS_FAILURE"; then
      error "$phase_label reported HEADLESS_FAILURE"
      return 1
    fi
    return 0
  elif [[ $exit_code -eq 124 ]]; then
    error "$phase_label timed out after ${TIMEOUT}s"
    return 1
  else
    error "$phase_label failed (exit code: $exit_code)"
    if echo "$output" | grep -qi "rate limit"; then
      return 2
    elif echo "$output" | grep -qi "spend limit\|budget"; then
      return 3
    fi
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Phase execution functions
# ---------------------------------------------------------------------------

# Phase 1: UC Plan
run_uc_plan() {
  local uc_id="$1"
  local worktree_name="uc-plan-${uc_id//\//-}"
  local worktree_path

  log "Phase 1 (PLAN): $uc_id"
  update_uc_phase "$uc_id" "planning"

  worktree_path=$(setup_worktree "$worktree_name") || {
    update_uc_phase "$uc_id" "failed"
    update_uc_error "$uc_id" "worktree_creation"
    return 1
  }

  local prompt
  prompt=$(build_phase_prompt "$PLUGIN_ROOT/commands/run/plan.md" "$uc_id $SPEC_FOLDER")

  local result=0
  run_claude_phase "$worktree_path" "$prompt" "UC-PLAN($uc_id)" "uc-plan-${uc_id//\//-}" || result=$?

  if [[ $result -eq 0 ]]; then
    # Check for uncommitted changes and auto-commit
    auto_commit_if_needed "$worktree_path" "plan($uc_id): generate subtask plans" "$uc_id"

    local new_commits
    new_commits=$(git -C "$PROJECT_DIR" log "HEAD..worktree-${worktree_name}" --oneline 2>/dev/null || true)
    if [[ -n "$new_commits" ]]; then
      merge_worktree "$worktree_name" || {
        update_uc_phase "$uc_id" "failed"
        update_uc_error "$uc_id" "merge_conflict"
        return 1
      }
    else
      # No commits but success -- plans may have already existed
      git -C "$PROJECT_DIR" worktree remove --force "$worktree_path" 2>/dev/null || true
      git -C "$PROJECT_DIR" branch -D "worktree-$worktree_name" 2>/dev/null || true
    fi

    update_uc_phase "$uc_id" "bdd_writing"
    log "Phase 1 (PLAN) completed for $uc_id"
    return 0
  else
    update_uc_phase "$uc_id" "failed"
    update_uc_error "$uc_id" "plan_failure"
    return $result
  fi
}

# Phase 2: UC BDD
run_uc_bdd() {
  local uc_id="$1"
  local worktree_name="uc-bdd-${uc_id//\//-}"
  local worktree_path

  log "Phase 2 (BDD): $uc_id"
  update_uc_phase "$uc_id" "bdd_writing"

  worktree_path=$(setup_worktree "$worktree_name") || {
    update_uc_phase "$uc_id" "failed"
    update_uc_error "$uc_id" "worktree_creation"
    return 1
  }

  local prompt
  prompt=$(build_phase_prompt "$PLUGIN_ROOT/commands/run/bdd.md" "$uc_id $SPEC_FOLDER")

  local result=0
  run_claude_phase "$worktree_path" "$prompt" "UC-BDD($uc_id)" "uc-bdd-${uc_id//\//-}" || result=$?

  if [[ $result -eq 0 ]]; then
    auto_commit_if_needed "$worktree_path" "test($uc_id): BDD step definitions (red phase)" "$uc_id"

    local new_commits
    new_commits=$(git -C "$PROJECT_DIR" log "HEAD..worktree-${worktree_name}" --oneline 2>/dev/null || true)
    if [[ -n "$new_commits" ]]; then
      merge_worktree "$worktree_name" || {
        update_uc_phase "$uc_id" "failed"
        update_uc_error "$uc_id" "merge_conflict"
        return 1
      }
    else
      # No commits -- BDD may have been skipped (no scenarios)
      git -C "$PROJECT_DIR" worktree remove --force "$worktree_path" 2>/dev/null || true
      git -C "$PROJECT_DIR" branch -D "worktree-$worktree_name" 2>/dev/null || true
    fi

    update_uc_phase "$uc_id" "implementing"
    log "Phase 2 (BDD) completed for $uc_id"
    return 0
  else
    update_uc_phase "$uc_id" "failed"
    update_uc_error "$uc_id" "bdd_failure"
    return $result
  fi
}

# Phase 3: Dispatch a single subtask
run_subtask() {
  local uc_id="$1"
  local subtask_id="$2"
  local worktree_name="subtask-${subtask_id//\//-}"
  local worktree_path

  log "Phase 3 (IMPLEMENT): $subtask_id"
  update_subtask "$uc_id" "$subtask_id" "status" "in_progress"
  update_subtask "$uc_id" "$subtask_id" "worktree" "$worktree_name"

  worktree_path=$(setup_worktree "$worktree_name") || {
    update_subtask "$uc_id" "$subtask_id" "status" "failed"
    update_subtask "$uc_id" "$subtask_id" "error" "worktree_creation"
    return 1
  }

  local prompt
  prompt=$(build_phase_prompt "$PLUGIN_ROOT/commands/run/task.md" "$subtask_id $SPEC_FOLDER")

  local result=0
  run_claude_phase "$worktree_path" "$prompt" "SUBTASK($subtask_id)" "subtask-${subtask_id//\//-}" || result=$?

  if [[ $result -eq 0 ]]; then
    local task_title
    task_title=$(jq -r --arg uc "$uc_id" --arg st "$subtask_id" \
      '.use_cases[] | select(.id == $uc) | .subtasks[] | select(.id == $st) | .title // "untitled"' \
      "$TASKS_JSON")
    auto_commit_if_needed "$worktree_path" "feat: ${task_title}" "$subtask_id"

    local new_commits
    new_commits=$(git -C "$PROJECT_DIR" log "HEAD..worktree-${worktree_name}" --oneline 2>/dev/null || true)

    if [[ -z "$new_commits" ]]; then
      error "Subtask $subtask_id produced no commits"
      update_subtask "$uc_id" "$subtask_id" "status" "failed"
      update_subtask "$uc_id" "$subtask_id" "error" "no_commits"
      return 1
    fi

    log "Subtask $subtask_id completed ($(echo "$new_commits" | wc -l | tr -d ' ') commit(s))"

    merge_worktree "$worktree_name" || {
      error "Merge failed for subtask $subtask_id"
      update_subtask "$uc_id" "$subtask_id" "status" "failed"
      update_subtask "$uc_id" "$subtask_id" "error" "merge_conflict"
      return 1
    }

    update_subtask "$uc_id" "$subtask_id" "status" "completed"
    log "Subtask $subtask_id merged successfully"
    return 0
  else
    update_subtask "$uc_id" "$subtask_id" "status" "failed"
    if [[ $result -eq 2 ]]; then
      update_subtask "$uc_id" "$subtask_id" "error" "rate_limit"
    elif [[ $result -eq 3 ]]; then
      update_subtask "$uc_id" "$subtask_id" "error" "spend_limit"
    else
      update_subtask "$uc_id" "$subtask_id" "error" "execution_failure"
    fi
    return $result
  fi
}

# Phase 4: UC Validate
run_uc_validate() {
  local uc_id="$1"
  local worktree_name="uc-validate-${uc_id//\//-}"
  local worktree_path

  log "Phase 4 (VALIDATE): $uc_id"
  update_uc_phase "$uc_id" "validating"

  worktree_path=$(setup_worktree "$worktree_name") || {
    update_uc_phase "$uc_id" "failed"
    update_uc_error "$uc_id" "worktree_creation"
    return 1
  }

  local prompt
  prompt=$(build_phase_prompt "$PLUGIN_ROOT/commands/run/validate.md" "$uc_id $SPEC_FOLDER")

  local result=0
  run_claude_phase "$worktree_path" "$prompt" "UC-VALIDATE($uc_id)" "uc-validate-${uc_id//\//-}" || result=$?

  # Clean up validation worktree (no code changes expected)
  git -C "$PROJECT_DIR" worktree remove --force "$worktree_path" 2>/dev/null || true
  git -C "$PROJECT_DIR" branch -D "worktree-$worktree_name" 2>/dev/null || true

  if [[ $result -eq 0 ]]; then
    # Check if output indicates SUCCESS or SKIPPED
    update_uc_phase "$uc_id" "completed"
    log "Phase 4 (VALIDATE) passed for $uc_id"
    return 0
  else
    update_uc_phase "$uc_id" "failed"
    update_uc_error "$uc_id" "validation_failure"
    return $result
  fi
}

# ---------------------------------------------------------------------------
# Auto-commit helper
# ---------------------------------------------------------------------------
auto_commit_if_needed() {
  local worktree_path="$1"
  local message="$2"
  local identifier="$3"

  local uncommitted
  uncommitted=$(git -C "$worktree_path" status --porcelain 2>/dev/null || true)
  if [[ -n "$uncommitted" ]]; then
    log "Agent left uncommitted changes. Auto-committing."
    git -C "$worktree_path" add -A 2>&1 || true
    git -C "$worktree_path" commit -m "${message}

Auto-committed by dispatcher (agent could not commit)
Identifier: ${identifier}" 2>&1 || {
      error "Auto-commit failed for $identifier"
      return 1
    }
    log "Auto-commit successful"
  fi
}

# ---------------------------------------------------------------------------
# Retry helper with backoff
# ---------------------------------------------------------------------------
retry_uc_phase() {
  local uc_id="$1"
  local error_type="$2"

  if [[ "$error_type" == "rate_limit" ]]; then
    local retries
    retries=$(get_uc_retries "$uc_id")
    local delay=$((30 * (retries + 1)))
    log "Rate limit hit. Backing off ${delay}s before retrying $uc_id"
    sleep "$delay"
  fi
}

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
log "Starting UC-phase pipeline for $SPEC_FOLDER"
log "Max parallel UCs: $MAX_PARALLEL | Timeout: ${TIMEOUT}s | Max retries: $MAX_RETRIES"

# Reset non-completed UCs from previous runs back to appropriate state
reset_count=$(jq '[.use_cases[] | select(.phase == "failed")] | length' "$TASKS_JSON")
if [[ $reset_count -gt 0 ]]; then
  log "Resetting $reset_count failed UCs from previous run"
  tmp=$(mktemp)
  jq '(.use_cases[] | select(.phase == "failed")) |= (.phase = "pending" | .error = null)' "$TASKS_JSON" > "$tmp" \
    && mv "$tmp" "$TASKS_JSON"
fi

# Reset in_progress subtasks back to pending
tmp=$(mktemp)
jq '(.use_cases[].subtasks[] | select(.status == "in_progress")) |= (.status = "pending" | .error = null)' "$TASKS_JSON" > "$tmp" \
  && mv "$tmp" "$TASKS_JSON"

total_ucs=$(jq '.use_cases | length' "$TASKS_JSON")
completed_ucs=$(jq '[.use_cases[] | select(.phase == "completed")] | length' "$TASKS_JSON")
log "Progress: $completed_ucs/$total_ucs UCs completed"

while true; do
  if [[ $SHUTDOWN -eq 1 ]]; then
    log "Shutting down gracefully. State saved to $TASKS_JSON"
    break
  fi

  # Collect ready UCs
  ready_ucs=()
  while IFS= read -r uc_id; do
    [[ -z "$uc_id" ]] && continue
    ready_ucs+=("$uc_id")
  done < <(get_ready_ucs)

  if [[ ${#ready_ucs[@]} -eq 0 ]]; then
    completed_ucs=$(jq '[.use_cases[] | select(.phase == "completed")] | length' "$TASKS_JSON")
    failed_ucs=$(jq '[.use_cases[] | select(.phase == "failed")] | length' "$TASKS_JSON")
    pending_ucs=$(jq '[.use_cases[] | select(.phase != "completed" and .phase != "failed")] | length' "$TASKS_JSON")

    if [[ $pending_ucs -eq 0 && $failed_ucs -eq 0 ]]; then
      log "All UCs completed successfully"
      break
    elif [[ $pending_ucs -gt 0 ]]; then
      log "No ready UCs. $pending_ucs in progress/blocked, $failed_ucs failed."
      break
    else
      log "No pending UCs. $failed_ucs failed."
      break
    fi
  fi

  # Process ready UCs (up to MAX_PARALLEL concurrently)
  # For simplicity, process one UC at a time through its next phase step
  uc_count=0
  for uc_id in "${ready_ucs[@]}"; do
    if [[ $uc_count -ge $MAX_PARALLEL ]]; then
      break
    fi
    if [[ $SHUTDOWN -eq 1 ]]; then
      break
    fi

    local_phase=$(get_uc_phase "$uc_id")
    phase_exit=0

    case "$local_phase" in
      "pending")
        run_uc_plan "$uc_id" || phase_exit=$?
        ;;

      "planning")
        # Resume: plan was started but not completed, retry
        run_uc_plan "$uc_id" || phase_exit=$?
        ;;

      "bdd_writing")
        run_uc_bdd "$uc_id" || phase_exit=$?
        ;;

      "implementing")
        # Dispatch next ready subtask
        next_subtask=$(get_next_ready_subtask "$uc_id")

        if [[ -z "$next_subtask" ]]; then
          # No ready subtask -- check if all done or blocked
          if all_subtasks_done "$uc_id"; then
            update_uc_phase "$uc_id" "validating"
            log "All subtasks completed for $uc_id. Advancing to validation."
          elif any_subtask_failed "$uc_id"; then
            log "Subtask(s) failed in $uc_id. Cannot proceed to validation."
            update_uc_phase "$uc_id" "failed"
            update_uc_error "$uc_id" "subtask_failure"
            phase_exit=1
          else
            log "No ready subtasks for $uc_id (blocked by dependencies)"
          fi
        else
          run_subtask "$uc_id" "$next_subtask" || phase_exit=$?
        fi
        ;;

      "validating")
        run_uc_validate "$uc_id" || phase_exit=$?
        ;;
    esac

    # Handle phase failure -- retry logic
    if [[ $phase_exit -ne 0 ]]; then
      if [[ $phase_exit -eq 3 ]]; then
        log "Spend limit detected. Pausing pipeline."
        SHUTDOWN=1
        break
      fi

      current_retries=$(get_uc_retries "$uc_id")
      if [[ $current_retries -lt $MAX_RETRIES ]]; then
        new_retries=$(increment_uc_retries "$uc_id")
        log "UC $uc_id failed (attempt $new_retries/$MAX_RETRIES). Will retry."

        # For validation failures, reset to pending to re-plan the delta
        failed_phase=$(get_uc_phase "$uc_id")
        if [[ "$failed_phase" == "failed" ]]; then
          # Preserve completed subtasks, reset failed ones to pending
          tmp=$(mktemp)
          jq --arg uc "$uc_id" '
            (.use_cases[] | select(.id == $uc) | .subtasks[] | select(.status == "failed")) |=
              (.status = "pending" | .error = null)
          ' "$TASKS_JSON" > "$tmp" && mv "$tmp" "$TASKS_JSON"

          update_uc_phase "$uc_id" "pending"
          update_uc_error "$uc_id" "null"
        fi

        # Backoff for rate limits
        error_type=$(jq -r --arg uc "$uc_id" '.use_cases[] | select(.id == $uc) | .error // "unknown"' "$TASKS_JSON")
        retry_uc_phase "$uc_id" "$error_type"
      else
        log "UC $uc_id failed after $MAX_RETRIES retries. Skipping."
      fi
    fi

    uc_count=$((uc_count + 1))
  done
done

# ---------------------------------------------------------------------------
# Final status
# ---------------------------------------------------------------------------
bash "$SCRIPTS_DIR/status.sh" "$SPEC_FOLDER"

completed_ucs=$(jq '[.use_cases[] | select(.phase == "completed")] | length' "$TASKS_JSON")
failed_ucs=$(jq '[.use_cases[] | select(.phase == "failed")] | length' "$TASKS_JSON")

if [[ $failed_ucs -gt 0 ]]; then
  log "Pipeline completed with $failed_ucs failed UC(s). Review tasks.json for details."
  exit 1
else
  log "Pipeline completed successfully. $completed_ucs/$total_ucs UCs done."
fi
