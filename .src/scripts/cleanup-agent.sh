#!/usr/bin/env bash
# cleanup-agent.sh - Remove an agent's worktree and optionally delete the branch

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

usage() {
    cat << EOF
Usage: $0 <feature-name> <agent-name> [--delete-branch]

Remove an agent's worktree and optionally delete the branch.

Arguments:
  feature-name      Name of the feature
  agent-name        Name of the agent
  --delete-branch   Also delete the branch (optional)

Example:
  $0 auth-feature developer
  $0 auth-feature developer --delete-branch
EOF
    exit 1
}

main() {
    if [[ $# -lt 2 ]]; then
        usage
    fi

    local feature="$1"
    local agent="$2"
    local delete_branch=false

    if [[ $# -ge 3 ]] && [[ "$3" == "--delete-branch" ]]; then
        delete_branch=true
    fi

    require_git_repo || exit 1

    local skill_root
    skill_root="$(skill_root_from_script "${BASH_SOURCE[0]}")" || exit 1

    # Validate inputs
    validate_feature_name "$feature" || exit 1
    validate_agent_name "$agent" "$skill_root" || exit 1

    local branch_name="${feature}/${agent}"
    local project_root
    project_root="$(project_root)" || exit 1
    local worktree_path="$project_root/worktrees/${feature}/${agent}"

    # Check if worktree exists
    if ! worktree_exists "$worktree_path"; then
        log_warn "Worktree does not exist: $worktree_path"
    else
        # Check for uncommitted changes
        if has_uncommitted_changes "$worktree_path"; then
            log_error "Worktree has uncommitted changes: $worktree_path"
            log_error "Please commit or stash changes before removing the worktree"
            exit 1
        fi

        # Check for unpushed commits
        if branch_exists "$branch_name"; then
            local main_branch
            main_branch="$(get_main_branch)" || exit 1

            local unpushed
            unpushed="$(git log "$main_branch..$branch_name" --oneline 2>/dev/null || true)"

            if [[ -n "$unpushed" ]]; then
                log_warn "Branch has unpushed commits:"
                echo "$unpushed"
                log_warn "These commits will be lost if you delete the branch"
            fi
        fi

        # Remove worktree
        log_info "Removing worktree: $worktree_path"
        git worktree remove "$worktree_path" || {
            log_error "Failed to remove worktree. Try: git worktree remove --force $worktree_path"
            exit 1
        }
        log_success "Removed worktree: $worktree_path"
    fi

    # Delete branch if requested
    if [[ "$delete_branch" == true ]]; then
        if branch_exists "$branch_name"; then
            log_info "Deleting branch: $branch_name"
            git branch -D "$branch_name" || {
                log_error "Failed to delete branch: $branch_name"
                exit 1
            }
            log_success "Deleted branch: $branch_name"
        else
            log_warn "Branch does not exist: $branch_name"
        fi
    else
        log_info "Branch preserved: $branch_name"
        log_info "To delete the branch later, run: git branch -D $branch_name"
    fi
}

main "$@"
