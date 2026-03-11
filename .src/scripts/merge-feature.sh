#!/usr/bin/env bash
# merge-feature.sh - Merge a completed feature to main (AWP v2)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

usage() {
    cat << EOF
Usage: $0 <feature-name>

Merge a completed feature branch back to the main branch.

Arguments:
  feature-name    Name of the feature to merge

Prerequisites:
  Feature must be in 'done' state (run '/awp-apply' first).

Example:
  $0 config-page
EOF
    exit 1
}

main() {
    if [[ $# -ne 1 ]]; then
        usage
    fi

    local feature="$1"

    require_git_repo || exit 1
    validate_feature_name "$feature" || exit 1

    if ! feature_exists "$feature"; then
        log_error "Feature not found: $feature"
        exit 1
    fi

    # Check state is done
    local status
    status="$(read_state_field "$feature" '.status')"
    if [[ "$status" != "done" ]]; then
        log_error "Feature is not done (current status: $status)"
        log_error "Run '/awp-apply $feature' to complete all task groups first"
        exit 1
    fi

    local proj_root
    proj_root="$(project_root)" || exit 1
    local branch_name
    branch_name="$(read_state_field "$feature" '.branch')"
    local worktree_path="$proj_root/worktrees/$feature"

    # Check for uncommitted changes in worktree
    if [[ -d "$worktree_path" ]] && has_uncommitted_changes "$worktree_path"; then
        log_error "Worktree has uncommitted changes: $worktree_path"
        log_error "Please commit or stash changes before merging"
        exit 1
    fi

    # Get main branch
    local main_branch
    main_branch="$(get_main_branch)" || exit 1

    # Check for uncommitted changes in main repo
    if ! git diff-index --quiet HEAD --; then
        log_error "Main repository has uncommitted changes"
        log_error "Please commit or stash changes before merging"
        exit 1
    fi

    # Rebase feature branch onto main
    log_info "Rebasing $branch_name onto $main_branch..."
    if [[ -d "$worktree_path" ]]; then
        (cd "$worktree_path" && git rebase "$main_branch") || {
            log_error "Rebase failed. Conflicts detected."
            log_error "Resolve conflicts in $worktree_path, then re-run 'awp merge $feature'"
            log_warn "After resolving, re-run '/awp-merge $feature'"
            (cd "$worktree_path" && git rebase --abort 2>/dev/null || true)
            exit 1
        }
    fi

    # Switch to main and merge
    log_info "Merging $branch_name into $main_branch..."
    git checkout "$main_branch"

    if git merge --ff-only "$branch_name"; then
        log_success "Successfully merged $branch_name into $main_branch (fast-forward)"
    elif git merge --no-ff "$branch_name" -m "Merge feature: $feature"; then
        log_success "Successfully merged $branch_name into $main_branch"
    else
        log_error "Merge failed. Please resolve conflicts manually."
        exit 1
    fi

    # Cleanup: remove worktree
    if [[ -d "$worktree_path" ]]; then
        log_info "Removing worktree: $worktree_path"
        git worktree remove "$worktree_path" 2>/dev/null || {
            log_warn "Could not remove worktree automatically. Run: git worktree remove $worktree_path"
        }
    fi

    # Cleanup: delete branch
    if branch_exists "$branch_name"; then
        log_info "Deleting branch: $branch_name"
        git branch -d "$branch_name" 2>/dev/null || {
            log_warn "Could not delete branch. Run: git branch -D $branch_name"
        }
    fi

    # Cleanup: remove feature state
    remove_feature_dir "$feature"

    # Archive change if it was from openspec
    local change
    change="$(read_state_field "$feature" '.change' 2>/dev/null || echo "null")"
    if [[ "$change" != "null" ]] && [[ -n "$change" ]]; then
        log_info "Archiving change: $change"
        # The actual archive is handled by openspec CLI or manually
        log_info "Change artifacts remain at: $(changes_dir)/$change/"
    fi

    log_success "Feature '$feature' merged and cleaned up!"
}

main "$@"
