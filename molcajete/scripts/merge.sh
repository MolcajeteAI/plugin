#!/usr/bin/env bash
set -euo pipefail

# Merge a worktree branch into the current branch
# Usage: merge.sh <worktree-name> [project-dir]
#
# If merge conflicts occur, attempts LLM-assisted resolution.

WORKTREE_NAME="${1:?Usage: merge.sh <worktree-name> [project-dir]}"
PROJECT_DIR="${2:-.}"
BRANCH_NAME="worktree-$WORKTREE_NAME"
WORKTREE_BASE="${PROJECT_DIR}--molcajete"
WORKTREE_PATH="$WORKTREE_BASE/$WORKTREE_NAME"

log() { echo "[merge] $*"; }
error() { echo "[merge] ERROR: $*" >&2; }

# Attempt merge
log "Merging branch $BRANCH_NAME into $(git -C "$PROJECT_DIR" branch --show-current)"
merge_stderr=$(mktemp)
if git -C "$PROJECT_DIR" merge "$BRANCH_NAME" --no-edit 2>"$merge_stderr"; then
  rm -f "$merge_stderr"
  log "Merge successful"
else
  merge_error=$(cat "$merge_stderr")
  rm -f "$merge_stderr"

  # Get conflict files
  conflict_files=$(git -C "$PROJECT_DIR" diff --name-only --diff-filter=U 2>/dev/null || true)

  if [[ -z "$conflict_files" ]]; then
    error "Merge failed (not a conflict): $merge_error"
    git -C "$PROJECT_DIR" merge --abort 2>/dev/null || true
    exit 1
  fi

  log "Merge conflict detected. Attempting LLM-assisted resolution."

  # Attempt resolution via claude
  resolution_prompt="Resolve the following git merge conflicts. For each file, choose the correct resolution that preserves both changes where possible. Files with conflicts: $conflict_files"

  if (cd "$PROJECT_DIR" && claude -p "$resolution_prompt" --output-format json 2>/dev/null); then
    # Check if conflicts are resolved
    remaining=$(git -C "$PROJECT_DIR" diff --name-only --diff-filter=U 2>/dev/null || true)
    if [[ -z "$remaining" ]]; then
      git -C "$PROJECT_DIR" add -A
      git -C "$PROJECT_DIR" commit --no-edit
      log "Conflicts resolved and committed"
    else
      error "Some conflicts remain unresolved: $remaining"
      git -C "$PROJECT_DIR" merge --abort 2>/dev/null || true
      exit 1
    fi
  else
    error "LLM-assisted resolution failed"
    git -C "$PROJECT_DIR" merge --abort 2>/dev/null || true
    exit 1
  fi
fi

# Clean up worktree and branch
if [[ -d "$WORKTREE_PATH" ]]; then
  git -C "$PROJECT_DIR" worktree remove "$WORKTREE_PATH" --force 2>/dev/null || true
fi
git -C "$PROJECT_DIR" branch -d "$BRANCH_NAME" 2>/dev/null || true

log "Cleanup complete"
