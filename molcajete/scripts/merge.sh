#!/usr/bin/env bash
set -euo pipefail

# Merge a worktree branch into the current branch (rebase + fast-forward)
# Usage: merge.sh <worktree-name> [project-dir]
#
# Rebases the worktree branch onto the current branch first, resolving
# conflicts with LLM assistance if needed, then fast-forward merges.

WORKTREE_NAME="${1:?Usage: merge.sh <worktree-name> [project-dir]}"
PROJECT_DIR="${2:-.}"
BRANCH_NAME="worktree-$WORKTREE_NAME"
WORKTREE_BASE="${PROJECT_DIR}/.molcajete/worktrees"
WORKTREE_PATH="$WORKTREE_BASE/$WORKTREE_NAME"

log() { echo "[merge] $*"; }
error() { echo "[merge] ERROR: $*" >&2; }

BASE_BRANCH=$(git -C "$PROJECT_DIR" branch --show-current)
log "Rebasing $BRANCH_NAME onto $BASE_BRANCH, then fast-forward merge"

# Step 1: Rebase worktree branch onto the current branch
rebase_stderr=$(mktemp)
if git -C "$WORKTREE_PATH" rebase "$BASE_BRANCH" 2>"$rebase_stderr"; then
  rm -f "$rebase_stderr"
  log "Rebase successful"
else
  rebase_error=$(cat "$rebase_stderr")
  rm -f "$rebase_stderr"

  # Check for conflicts
  conflict_files=$(git -C "$WORKTREE_PATH" diff --name-only --diff-filter=U 2>/dev/null || true)

  if [[ -z "$conflict_files" ]]; then
    error "Rebase failed (not a conflict): $rebase_error"
    git -C "$WORKTREE_PATH" rebase --abort 2>/dev/null || true
    exit 1
  fi

  log "Rebase conflict detected. Attempting LLM-assisted resolution."

  resolution_prompt="Resolve the following git rebase conflicts. For each file, choose the correct resolution that preserves both changes where possible. After resolving, run: git add <files> && git rebase --continue. Files with conflicts: $conflict_files"

  if (cd "$WORKTREE_PATH" && unset CLAUDECODE && claude --dangerously-skip-permissions -p "$resolution_prompt" --output-format json 2>/dev/null); then
    # Verify rebase completed
    if git -C "$WORKTREE_PATH" rebase --show-current-patch &>/dev/null; then
      error "Rebase still in progress after LLM resolution"
      git -C "$WORKTREE_PATH" rebase --abort 2>/dev/null || true
      exit 1
    fi
    log "Conflicts resolved, rebase complete"
  else
    error "LLM-assisted resolution failed"
    git -C "$WORKTREE_PATH" rebase --abort 2>/dev/null || true
    exit 1
  fi
fi

# Step 2: Fast-forward merge
if git -C "$PROJECT_DIR" merge --ff-only "$BRANCH_NAME" 2>&1; then
  log "Fast-forward merge successful"
else
  error "Fast-forward merge failed — rebase did not produce a linear history"
  exit 1
fi

# Clean up worktree and branch
if [[ -d "$WORKTREE_PATH" ]]; then
  git -C "$PROJECT_DIR" worktree remove "$WORKTREE_PATH" --force 2>/dev/null || true
fi
git -C "$PROJECT_DIR" branch -d "$BRANCH_NAME" 2>/dev/null || true

log "Cleanup complete"
