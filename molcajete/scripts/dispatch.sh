#!/usr/bin/env bash
set -euo pipefail

# dispatch.sh — Three-agent orchestration loop for /m:run.
#
# Usage: dispatch.sh <tasks.json path>
#
# Per UC: Tester (once) -> Developer (per subtask) -> Validator (BDD gate) -> merge.
# Linear loop, no state machine. All work inside UC worktrees.

# ── Prerequisites ──

if ! command -v jq &>/dev/null; then
  echo "Error: jq required but not found. Install jq and retry." >&2
  exit 1
fi

if ! command -v claude &>/dev/null; then
  echo "Error: claude CLI required but not found." >&2
  exit 1
fi

if [ $# -ne 1 ]; then
  echo "Usage: dispatch.sh <tasks.json>" >&2
  exit 1
fi

TASKS_JSON="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
if [ ! -f "$TASKS_JSON" ]; then
  echo "Error: tasks.json not found: $TASKS_JSON" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
SPEC_FOLDER="${PROJECT_ROOT}/$(jq -r '.spec_folder' "$TASKS_JSON")"
BASE_BRANCH=$(jq -r '.base_branch' "$TASKS_JSON")

# ── Constants ──

MAX_RETRIES="${MOLCAJETE_MAX_RETRIES:-2}"
BACKOFF_BASE="${MOLCAJETE_BACKOFF_BASE:-30}"
MAX_TURNS_AGENT="${MOLCAJETE_MAX_TURNS_AGENT:-30}"
MAX_TURNS_REVIEW="${MOLCAJETE_MAX_TURNS_REVIEW:-5}"
BUDGET_AGENT="${MOLCAJETE_BUDGET_AGENT:-3.00}"
BUDGET_REVIEW="${MOLCAJETE_BUDGET_REVIEW:-0.50}"
TIMEOUT="${MOLCAJETE_TASK_TIMEOUT:-897}"

TESTER_SCHEMA='{"type":"object","properties":{"status":{"type":"string","enum":["done","failed"]},"step_files":{"type":"array","items":{"type":"string"}},"scenarios_count":{"type":"integer"},"commit":{"type":["string","null"]},"error":{"type":["string","null"]}},"required":["status","step_files","scenarios_count","commit"]}'

DEVELOPER_SCHEMA='{"type":"object","properties":{"status":{"type":"string","enum":["done","failed"]},"files_modified":{"type":"array","items":{"type":"string"}},"commit":{"type":["string","null"]},"error":{"type":["string","null"]}},"required":["status","files_modified","commit"]}'

REVIEW_SCHEMA='{"type":"object","properties":{"verdict":{"type":"string","enum":["pass","fail"]},"reason":{"type":"string"}},"required":["verdict","reason"]}'

# ── Helpers ──

log() { echo "[$(date -u +%H:%M:%S)] $*"; }

update_json() {
  # Usage: update_json '.jq.filter' "$TASKS_JSON"
  local filter="$1"
  local tmp="${TASKS_JSON}.tmp"
  jq "$filter" "$TASKS_JSON" > "$tmp" && mv "$tmp" "$TASKS_JSON"
}

invoke_claude() {
  # Wrapper for claude -p with rate limit retry.
  # First arg is working directory; remaining args passed to claude -p.
  # Usage: invoke_claude <workdir> [claude args...] — stores output in $CLAUDE_OUTPUT
  local workdir="$1"; shift
  local attempt=0
  while [ $attempt -le $MAX_RETRIES ]; do
    CLAUDE_OUTPUT=$(cd "$workdir" && timeout "$TIMEOUT" claude -p "$@" 2>&1) && return 0
    local exit_code=$?
    if echo "$CLAUDE_OUTPUT" | grep -qi "rate.limit\|429\|too many requests"; then
      attempt=$((attempt + 1))
      local wait=$((BACKOFF_BASE * (2 ** (attempt - 1))))
      log "Rate limited. Retrying in ${wait}s (attempt $attempt/$MAX_RETRIES)..."
      sleep "$wait"
    else
      return $exit_code
    fi
  done
  log "Rate limit retries exhausted."
  return 1
}

detect_bdd() {
  # Detect BDD runner from bdd/ directory. Sets BDD_COMMAND.
  if [ -f "bdd/CLAUDE.md" ]; then
    # Try to extract runner hint from CLAUDE.md
    local runner
    runner=$(grep -oi 'behave\|cucumber-js\|cucumber\|godog' "bdd/CLAUDE.md" | head -1) || true
    case "$runner" in
      behave)      BDD_COMMAND="behave --no-capture" ;;
      cucumber-js|cucumber) BDD_COMMAND="npx cucumber-js" ;;
      godog)       BDD_COMMAND="godog" ;;
    esac
  fi
  # Fallback: detect from step file extensions
  if [ -z "${BDD_COMMAND:-}" ]; then
    if ls bdd/steps/*.py &>/dev/null; then
      BDD_COMMAND="behave --no-capture"
    elif ls bdd/steps/*.ts bdd/steps/*.js &>/dev/null; then
      BDD_COMMAND="npx cucumber-js"
    elif ls bdd/steps/*.go &>/dev/null; then
      BDD_COMMAND="godog"
    else
      log "Warning: could not detect BDD runner. Defaulting to behave."
      BDD_COMMAND="behave --no-capture"
    fi
  fi
}

parse_json_field() {
  # Extract a field from JSON output. Usage: parse_json_field "field" "$json"
  echo "$2" | jq -r ".$1 // empty" 2>/dev/null || echo ""
}

# ── Agent Functions ──
#
# All agents for a UC share one session. The Tester starts it with --name "$UC_ID",
# and every subsequent call (Developer, Review, BDD fix) uses --resume "$UC_ID".
# This keeps the full UC context (spec, step defs, prior subtask work) in one
# 1M-token window instead of starting fresh each call.

run_tester() {
  local uc_id="$1" worktree="$2"
  local attempt=0

  while [ $attempt -le $MAX_RETRIES ]; do
    log "Tester: $uc_id (attempt $((attempt + 1)))"
    if invoke_claude "$worktree" \
      --model claude-opus-4-6 \
      --allowedTools "Read,Write,Edit,Glob,Grep,Bash,Agent" \
      --max-turns "$MAX_TURNS_AGENT" --max-budget-usd "$BUDGET_AGENT" \
      --output-format json --json-schema "$TESTER_SCHEMA" \
      --name "$uc_id" \
      --dangerously-skip-permissions \
      "/m:run:test $SPEC_FOLDER $uc_id"; then

      local status
      status=$(parse_json_field "status" "$CLAUDE_OUTPUT")
      if [ "$status" = "done" ]; then
        local commit step_files scenarios
        commit=$(parse_json_field "commit" "$CLAUDE_OUTPUT")
        step_files=$(echo "$CLAUDE_OUTPUT" | jq -c '.step_files // []' 2>/dev/null)
        scenarios=$(parse_json_field "scenarios_count" "$CLAUDE_OUTPUT")
        update_json "(.use_cases[] | select(.id == \"$uc_id\") | .tester) |=
          {status: \"done\", retries: $attempt, commit: \"$commit\",
           step_files: $step_files, scenarios_count: ${scenarios:-0}, error: null}"
        log "Tester done: $uc_id ($scenarios scenarios, commit $commit)"
        return 0
      fi
    fi

    attempt=$((attempt + 1))
    local error
    error=$(parse_json_field "error" "$CLAUDE_OUTPUT") || error="Unknown error"
    update_json "(.use_cases[] | select(.id == \"$uc_id\") | .tester) |=
      {status: \"failed\", retries: $attempt, commit: null,
       step_files: [], scenarios_count: 0, error: \"$error\"}"

    if [ $attempt -le $MAX_RETRIES ]; then
      log "Tester failed ($error). Retrying..."
    fi
  done

  log "Tester failed after $MAX_RETRIES retries: $uc_id"
  return 1
}

run_developer() {
  local uc_id="$1" subtask_id="$2" worktree="$3" task_id="${uc_id}/${subtask_id}"

  log "Developer: $task_id"
  update_json "(.use_cases[] | select(.id == \"$uc_id\") | .subtasks[] |
    select(.id == \"$subtask_id\")) |= (.status = \"in_progress\")"

  if invoke_claude "$worktree" \
    --model claude-opus-4-6 \
    --allowedTools "Read,Write,Edit,Glob,Grep,Bash,Agent" \
    --max-turns "$MAX_TURNS_AGENT" --max-budget-usd "$BUDGET_AGENT" \
    --output-format json --json-schema "$DEVELOPER_SCHEMA" \
    --resume "$uc_id" \
    --dangerously-skip-permissions \
    "/m:run:build $SPEC_FOLDER $uc_id $subtask_id"; then

    local status
    status=$(parse_json_field "status" "$CLAUDE_OUTPUT")
    if [ "$status" = "done" ]; then
      local commit files_modified
      commit=$(parse_json_field "commit" "$CLAUDE_OUTPUT")
      files_modified=$(echo "$CLAUDE_OUTPUT" | jq -c '.files_modified // []' 2>/dev/null)
      update_json "(.use_cases[] | select(.id == \"$uc_id\") | .subtasks[] |
        select(.id == \"$subtask_id\")) |=
        (.status = \"done\" | .commit = \"$commit\" | .error = null)"
      log "Developer done: $task_id (commit $commit)"
      echo "$commit"  # Return commit SHA to caller
      return 0
    fi
  fi

  local error
  error=$(parse_json_field "error" "$CLAUDE_OUTPUT") || error="Developer failed"
  update_json "(.use_cases[] | select(.id == \"$uc_id\") | .subtasks[] |
    select(.id == \"$subtask_id\")) |=
    (.status = \"failed\" | .error = \"$error\")"
  log "Developer failed: $task_id ($error)"
  return 1
}

run_review() {
  local uc_id="$1" subtask_id="$2" subtask_title="$3" worktree="$4"

  log "Review: ${uc_id}/${subtask_id}"
  if invoke_claude "$worktree" \
    --model claude-sonnet-4-6 \
    --max-turns "$MAX_TURNS_REVIEW" --max-budget-usd "$BUDGET_REVIEW" \
    --output-format json --json-schema "$REVIEW_SCHEMA" \
    --resume "$uc_id" \
    --dangerously-skip-permissions \
    "Review the last commit. Check: (1) files were committed, (2) changes match task '$subtask_title', (3) no obvious errors. Return pass or fail with reason."; then

    local verdict
    verdict=$(parse_json_field "verdict" "$CLAUDE_OUTPUT")
    if [ "$verdict" = "pass" ]; then
      update_json "(.use_cases[] | select(.id == \"$uc_id\") | .subtasks[] |
        select(.id == \"$subtask_id\")) |= (.review = \"pass\")"
      log "Review passed: ${uc_id}/${subtask_id}"
      return 0
    fi
    local reason
    reason=$(parse_json_field "reason" "$CLAUDE_OUTPUT")
    log "Review failed: $reason"
  else
    log "Review returned malformed output — treating as failure"
  fi

  update_json "(.use_cases[] | select(.id == \"$uc_id\") | .subtasks[] |
    select(.id == \"$subtask_id\")) |= (.review = \"fail\")"
  return 1
}

run_validator() {
  local uc_id="$1" worktree="$2"

  log "Validator: running BDD tests for $uc_id"
  local test_output exit_code=0
  test_output=$(cd "$worktree" && $BDD_COMMAND --tags="@${uc_id}" 2>&1) || exit_code=$?

  if [ $exit_code -eq 0 ]; then
    log "Validator: BDD tests passed for $uc_id"
    return 0
  else
    log "Validator: BDD tests failed for $uc_id (exit $exit_code)"
    echo "$test_output"  # Return test output to caller
    return 1
  fi
}

run_bdd_fix() {
  # Resume the UC session with BDD failure context.
  local uc_id="$1" worktree="$2" test_output="$3"

  log "Fix: resuming $uc_id session with BDD failure context"
  if invoke_claude "$worktree" \
    --model claude-opus-4-6 \
    --allowedTools "Read,Write,Edit,Glob,Grep,Bash,Agent" \
    --max-turns "$MAX_TURNS_AGENT" --max-budget-usd "$BUDGET_AGENT" \
    --output-format json --json-schema "$DEVELOPER_SCHEMA" \
    --resume "$uc_id" \
    --dangerously-skip-permissions \
    "BDD tests failed for $uc_id. Fix the failing scenarios and recommit.

Test output:
$test_output

Read the feature files tagged @${uc_id} and the step definitions to understand what the tests expect. Fix the production code to make the tests pass. Commit your fixes."; then

    local status
    status=$(parse_json_field "status" "$CLAUDE_OUTPUT")
    [ "$status" = "done" ] && return 0
  fi
  return 1
}

# ── Main Loop ──

log "Starting dispatch: $TASKS_JSON"
log "Spec: $SPEC_FOLDER | Base: $BASE_BRANCH"

detect_bdd
log "BDD runner: $BDD_COMMAND"

UC_COUNT=$(jq '.use_cases | length' "$TASKS_JSON")
DONE_COUNT=0
FAILED_COUNT=0

for uc_idx in $(seq 0 $((UC_COUNT - 1))); do
  UC_ID=$(jq -r ".use_cases[$uc_idx].id" "$TASKS_JSON")
  UC_TITLE=$(jq -r ".use_cases[$uc_idx].title" "$TASKS_JSON")
  UC_DONE=$(jq -r ".use_cases[$uc_idx].done" "$TASKS_JSON")

  if [ "$UC_DONE" = "true" ]; then
    log "Skipping $UC_ID (already done)"
    DONE_COUNT=$((DONE_COUNT + 1))
    continue
  fi

  log "━━━ UC: $UC_ID — $UC_TITLE ━━━"

  # Create worktree
  WORKTREE_BRANCH="dispatch/${UC_ID}"
  WORKTREE_PATH=".worktrees/${UC_ID}"
  git worktree add -b "$WORKTREE_BRANCH" "$WORKTREE_PATH" "$BASE_BRANCH" 2>/dev/null || {
    # Branch may already exist from a prior run
    git worktree add "$WORKTREE_PATH" "$WORKTREE_BRANCH" 2>/dev/null || {
      log "Error: could not create worktree for $UC_ID"
      FAILED_COUNT=$((FAILED_COUNT + 1))
      continue
    }
  }
  WORKTREE_PATH="$(cd "$WORKTREE_PATH" && pwd)"

  update_json "(.use_cases[$uc_idx].worktree) = \"$WORKTREE_PATH\""

  # ── Phase 1: Tester ──
  if ! run_tester "$UC_ID" "$WORKTREE_PATH"; then
    log "UC $UC_ID failed: Tester could not write step definitions"
    FAILED_COUNT=$((FAILED_COUNT + 1))
    continue
  fi

  # ── Phase 2: Developer (per subtask) ──
  SUBTASK_COUNT=$(jq ".use_cases[$uc_idx].subtasks | length" "$TASKS_JSON")
  for st_idx in $(seq 0 $((SUBTASK_COUNT - 1))); do
    ST_ID=$(jq -r ".use_cases[$uc_idx].subtasks[$st_idx].id" "$TASKS_JSON")
    ST_TITLE=$(jq -r ".use_cases[$uc_idx].subtasks[$st_idx].title" "$TASKS_JSON")
    ST_STATUS=$(jq -r ".use_cases[$uc_idx].subtasks[$st_idx].status" "$TASKS_JSON")

    if [ "$ST_STATUS" = "done" ]; then
      log "Skipping subtask $ST_ID (already done)"
      continue
    fi

    # Developer + Review loop with retry
    local_retries=0
    subtask_done=false
    while [ $local_retries -le $MAX_RETRIES ] && [ "$subtask_done" = "false" ]; do
      if run_developer "$UC_ID" "$ST_ID" "$WORKTREE_PATH"; then
        # Developer succeeded — run review
        if run_review "$UC_ID" "$ST_ID" "$ST_TITLE" "$WORKTREE_PATH"; then
          subtask_done=true
        else
          # Review failed — retry Developer with feedback
          local_retries=$((local_retries + 1))
          update_json "(.use_cases[$uc_idx].subtasks[$st_idx].retries) = $local_retries"
          if [ $local_retries -le $MAX_RETRIES ]; then
            local reason
            reason=$(parse_json_field "reason" "$CLAUDE_OUTPUT")
            log "Retrying Developer with review feedback (attempt $((local_retries + 1)))..."
            # Resume the Developer session with feedback
            if invoke_claude "$WORKTREE_PATH" \
              --resume "$UC_ID" \
              --max-turns "$MAX_TURNS_AGENT" --max-budget-usd "$BUDGET_AGENT" \
              --output-format json --json-schema "$DEVELOPER_SCHEMA" \
              --dangerously-skip-permissions \
              "Review feedback: $reason. Fix the issues and recommit."; then
              local status
              status=$(parse_json_field "status" "$CLAUDE_OUTPUT")
              if [ "$status" = "done" ]; then
                local commit
                commit=$(parse_json_field "commit" "$CLAUDE_OUTPUT")
                update_json "(.use_cases[$uc_idx].subtasks[$st_idx]) |=
                  (.status = \"done\" | .commit = \"$commit\" | .error = null)"
                # Re-run review
                if run_review "$UC_ID" "$ST_ID" "$ST_TITLE" "$WORKTREE_PATH"; then
                  subtask_done=true
                fi
              fi
            fi
          fi
        fi
      else
        # Developer failed outright
        local_retries=$((local_retries + 1))
        update_json "(.use_cases[$uc_idx].subtasks[$st_idx].retries) = $local_retries"
        if [ $local_retries -le $MAX_RETRIES ]; then
          log "Retrying Developer (attempt $((local_retries + 1)))..."
        fi
      fi
    done

    if [ "$subtask_done" = "false" ]; then
      log "Subtask $ST_ID failed after $MAX_RETRIES retries"
      update_json "(.use_cases[$uc_idx].subtasks[$st_idx]) |=
        (.status = \"failed\" | .retries = $MAX_RETRIES)"
    fi
  done

  # ── Phase 3: Validator (BDD gate) ──
  bdd_passed=false
  bdd_retries=0
  while [ $bdd_retries -le $MAX_RETRIES ] && [ "$bdd_passed" = "false" ]; do
    test_output=""
    if test_output=$(run_validator "$UC_ID" "$WORKTREE_PATH" 2>&1); then
      bdd_passed=true
    else
      bdd_retries=$((bdd_retries + 1))
      if [ $bdd_retries -le $MAX_RETRIES ]; then
        log "BDD fix attempt $bdd_retries/$MAX_RETRIES for $UC_ID"
        run_bdd_fix "$UC_ID" "$WORKTREE_PATH" "$test_output" || true
      fi
    fi
  done

  if [ "$bdd_passed" = "true" ]; then
    # Merge worktree to base branch
    if bash "$SCRIPT_DIR/merge.sh" "$WORKTREE_PATH" "$BASE_BRANCH"; then
      update_json "(.use_cases[$uc_idx]) |= (.done = true | .worktree = null)"
      log "UC $UC_ID: done (merged to $BASE_BRANCH)"
      DONE_COUNT=$((DONE_COUNT + 1))
    else
      log "UC $UC_ID: merge failed — worktree preserved at $WORKTREE_PATH"
      FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
  else
    log "UC $UC_ID: BDD tests failed after $MAX_RETRIES fix attempts"
    log "Worktree preserved at: $WORKTREE_PATH"
    FAILED_COUNT=$((FAILED_COUNT + 1))
  fi
done

# ── Completion Report ──

log "━━━ Dispatch Complete ━━━"
log "Done: $DONE_COUNT | Failed: $FAILED_COUNT | Total: $UC_COUNT"
echo ""
echo "UC Status:"
for uc_idx in $(seq 0 $((UC_COUNT - 1))); do
  uc_id=$(jq -r ".use_cases[$uc_idx].id" "$TASKS_JSON")
  uc_done=$(jq -r ".use_cases[$uc_idx].done" "$TASKS_JSON")
  st_total=$(jq ".use_cases[$uc_idx].subtasks | length" "$TASKS_JSON")
  st_done=$(jq "[.use_cases[$uc_idx].subtasks[] | select(.status == \"done\")] | length" "$TASKS_JSON")
  if [ "$uc_done" = "true" ]; then
    echo "  $uc_id  done     ($st_done/$st_total subtasks)"
  else
    echo "  $uc_id  failed   ($st_done/$st_total subtasks)"
  fi
done

[ "$FAILED_COUNT" -eq 0 ] && exit 0 || exit 1
