#!/usr/bin/env bash
# create-agent.sh - Create a single agent worktree

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

usage() {
    cat << EOF
Usage: $0 <feature-name> <agent-name>

Create a worktree for a specific agent.

Arguments:
  feature-name    Name of the feature branch
  agent-name      Name of the agent (developer, tester, reviewer)

Example:
  $0 auth-feature developer
EOF
    exit 1
}

main() {
    if [[ $# -ne 2 ]]; then
        usage
    fi

    local feature="$1"
    local agent="$2"

    require_git_repo || exit 1

    local skill_root
    skill_root="$(skill_root_from_script "${BASH_SOURCE[0]}")" || exit 1

    local project_root
    project_root="$(project_root)" || exit 1

    # Validate inputs
    validate_feature_name "$feature" || exit 1
    validate_agent_name "$agent" "$skill_root" || exit 1

    local branch_name="${feature}/${agent}"
    local worktree_path="$project_root/worktrees/${feature}/${agent}"

    # Check if worktree already exists
    if worktree_exists "$worktree_path"; then
        log_error "Worktree already exists: $worktree_path"
        exit 1
    fi

    # Check if branch already exists
    if branch_exists "$branch_name"; then
        log_warn "Branch already exists: $branch_name"
        log_info "Creating worktree from existing branch..."
        git worktree add "$worktree_path" "$branch_name"
    else
        # Get main branch
        local main_branch
        main_branch="$(get_main_branch)" || exit 1

        log_info "Creating worktree: $worktree_path"
        log_info "Branch: $branch_name (from $main_branch)"

        # Create worktree with new branch
        git worktree add -b "$branch_name" "$worktree_path" "$main_branch"
    fi

    log_success "Created worktree for $agent at: $worktree_path"
    log_info "Branch: $branch_name"
}

main "$@"
