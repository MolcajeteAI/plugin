#!/usr/bin/env bash
set -euo pipefail

# Merge a worktree branch into the current branch
# Usage: merge.sh <worktree-name>
#
# If merge conflicts occur, attempts LLM-assisted resolution.

WORKTREE_NAME="${1:?Usage: merge.sh <worktree-name>}"
BRANCH_NAME="$WORKTREE_NAME"

log() { echo "[merge] $*"; }
error() { echo "[merge] ERROR: $*" >&2; }

# Find and remove the worktree
WORKTREE_PATH=$(git worktree list --porcelain | grep -A2 "worktree.*$WORKTREE_NAME" | head -1 | sed 's/worktree //' || true)

if [[ -z "$WORKTREE_PATH" ]]; then
  # Worktree may already be removed; just try to merge the branch
  log "Worktree not found. Attempting branch merge only."
fi

# Attempt merge
log "Merging branch $BRANCH_NAME"
if git merge "$BRANCH_NAME" --no-edit 2>/dev/null; then
  log "Merge successful"
else
  log "Merge conflict detected. Attempting LLM-assisted resolution."

  # Get conflict files
  conflict_files=$(git diff --name-only --diff-filter=U)

  if [[ -z "$conflict_files" ]]; then
    error "Merge failed but no conflict files found"
    git merge --abort 2>/dev/null || true
    exit 1
  fi

  # Attempt resolution via claude
  resolution_prompt="Resolve the following git merge conflicts. For each file, choose the correct resolution that preserves both changes where possible. Files with conflicts: $conflict_files"

  if claude -p "$resolution_prompt" --output-format json 2>/dev/null; then
    # Check if conflicts are resolved
    remaining=$(git diff --name-only --diff-filter=U 2>/dev/null || true)
    if [[ -z "$remaining" ]]; then
      git add -A
      git commit --no-edit
      log "Conflicts resolved and committed"
    else
      error "Some conflicts remain unresolved: $remaining"
      git merge --abort 2>/dev/null || true
      exit 1
    fi
  else
    error "LLM-assisted resolution failed"
    git merge --abort 2>/dev/null || true
    exit 1
  fi
fi

# Clean up worktree and branch
if [[ -n "$WORKTREE_PATH" ]]; then
  git worktree remove "$WORKTREE_PATH" --force 2>/dev/null || true
fi
git branch -d "$BRANCH_NAME" 2>/dev/null || true

log "Cleanup complete"
