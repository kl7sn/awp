#!/usr/bin/env bash
# delete-feature.sh - Delete a feature's worktree, branch, and state (AWP v2)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

usage() {
    cat << EOF
Usage: $0 <feature-name> [--force]

Delete a feature: remove worktree, branch, and state files.

Arguments:
  feature-name    Name of the feature to delete
  --force         Force delete even with uncommitted changes

Example:
  $0 config-page
  $0 config-page --force
EOF
    exit 1
}

main() {
    if [[ $# -lt 1 ]]; then
        usage
    fi

    local feature="$1"
    local force=false

    if [[ $# -ge 2 ]] && [[ "$2" == "--force" ]]; then
        force=true
    fi

    require_git_repo || exit 1
    validate_feature_name "$feature" || exit 1

    local proj_root
    proj_root="$(project_root)" || exit 1

    local branch_name="$feature"
    local worktree_path="$proj_root/worktrees/$feature"

    # Read branch name from state if available
    if feature_exists "$feature"; then
        branch_name="$(read_state_field "$feature" '.branch' 2>/dev/null || echo "$feature")"
    fi

    # Check for uncommitted changes
    if [[ "$force" == false ]] && [[ -d "$worktree_path" ]] && has_uncommitted_changes "$worktree_path"; then
        log_error "Worktree has uncommitted changes: $worktree_path"
        log_error "Use --force to delete anyway, or commit/stash changes first"
        exit 1
    fi

    log_info "Deleting feature: $feature"

    # Remove worktree
    if [[ -d "$worktree_path" ]]; then
        log_info "Removing worktree: $worktree_path"
        if [[ "$force" == true ]]; then
            git worktree remove --force "$worktree_path" 2>/dev/null || {
                log_warn "git worktree remove failed, removing directory manually"
                rm -rf "$worktree_path"
                git worktree prune
            }
        else
            git worktree remove "$worktree_path" || {
                log_error "Failed to remove worktree. Use --force to override."
                exit 1
            }
        fi
        log_success "Removed worktree"
    fi

    # Delete branch
    if branch_exists "$branch_name"; then
        log_info "Deleting branch: $branch_name"
        git branch -D "$branch_name" 2>/dev/null || {
            log_warn "Could not delete branch: $branch_name"
        }
        log_success "Deleted branch"
    fi

    # Remove feature state
    if feature_exists "$feature"; then
        remove_feature_dir "$feature"
        log_success "Removed feature state"
    fi

    log_success "Feature '$feature' deleted"
}

main "$@"
