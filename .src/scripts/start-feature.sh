#!/usr/bin/env bash
# start-feature.sh - Create worktrees for all agents

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

usage() {
    cat << EOF
Usage: $0 <feature-name>

Create worktrees and branches for all configured agents.

Arguments:
  feature-name    Name of the feature to work on

Example:
  $0 auth-feature
EOF
    exit 1
}

main() {
    if [[ $# -ne 1 ]]; then
        usage
    fi

    local feature="$1"

    require_git_repo || exit 1

    local skill_root
    skill_root="$(skill_root_from_script "${BASH_SOURCE[0]}")" || exit 1

    # Validate feature name
    validate_feature_name "$feature" || exit 1

    log_info "Creating worktrees for feature: $feature"

    # Get agent roles from schema
    local agents
    agents="$(get_agent_roles "$skill_root")" || exit 1

    local created_count=0
    local failed_count=0

    # Create worktree for each agent
    while IFS= read -r agent; do
        log_info "Creating worktree for agent: $agent"
        if bash "$SCRIPT_DIR/create-agent.sh" "$feature" "$agent"; then
            ((created_count++))
        else
            log_error "Failed to create worktree for agent: $agent"
            ((failed_count++))
        fi
    done <<< "$agents"

    echo ""
    log_success "Created $created_count worktree(s)"
    if [[ $failed_count -gt 0 ]]; then
        log_warn "Failed to create $failed_count worktree(s)"
        exit 1
    fi

    log_info "Worktrees are located in: worktrees/$feature/"
}

main "$@"
