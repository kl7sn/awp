#!/usr/bin/env bash
# create-feature.sh - Create a single worktree + branch for a feature (AWP v2)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

usage() {
    cat << EOF
Usage: $0 <feature-name> [--change <change-name>]

Create a worktree and branch for a feature.

Arguments:
  feature-name              Name of the feature
  --change <change-name>    Associate with an OpenSpec change (optional)

Example:
  $0 auth-feature
  $0 config-page --change config-page
EOF
    exit 1
}

main() {
    if [[ $# -lt 1 ]]; then
        usage
    fi

    local feature="$1"
    shift

    local change=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --change)
                change="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    require_git_repo || exit 1

    # Validate feature name
    validate_feature_name "$feature" || exit 1

    local proj_root
    proj_root="$(project_root)" || exit 1

    # Auto-detect change: if --change not specified, look for same-name change
    if [[ -z "$change" ]]; then
        if change_exists "$feature"; then
            change="$feature"
            log_info "Auto-detected change: $change"
        fi
    fi

    local branch_name="$feature"
    local worktree_path="$proj_root/worktrees/$feature"

    # Check if feature already exists
    if feature_exists "$feature"; then
        log_error "Feature already exists: $feature"
        log_error "Use 'awp apply $feature' to continue or 'awp delete $feature' to remove"
        exit 1
    fi

    # Check if worktree already exists
    if worktree_exists "$worktree_path"; then
        log_error "Worktree already exists: $worktree_path"
        exit 1
    fi

    log_info "Creating feature: $feature"

    # Create worktree with branch
    if branch_exists "$branch_name"; then
        log_warn "Branch already exists: $branch_name"
        log_info "Creating worktree from existing branch..."
        git worktree add "$worktree_path" "$branch_name"
    else
        local main_branch
        main_branch="$(get_main_branch)" || exit 1

        log_info "Creating worktree: $worktree_path"
        log_info "Branch: $branch_name (from $main_branch)"
        git worktree add -b "$branch_name" "$worktree_path" "$main_branch"
    fi

    # Parse task groups if change is specified
    local groups_json="[]"
    if [[ -n "$change" ]]; then
        local tasks_file
        tasks_file="$(change_tasks_file "$change")"
        if [[ -f "$tasks_file" ]]; then
            log_info "Parsing tasks from change: $change"
            groups_json="$(parse_tasks_md "$tasks_file")" || {
                log_warn "Failed to parse tasks.md, initializing with empty groups"
                groups_json="[]"
            }
            local group_count
            group_count="$(echo "$groups_json" | jq 'length')"
            log_info "Found $group_count task group(s)"
        else
            log_warn "Tasks file not found for change: $change"
            log_warn "Initializing with empty groups"
        fi
    fi

    # Initialize state
    create_feature_dir "$feature"
    init_state "$feature" "$branch_name" "$change" "$groups_json"

    log_success "Feature created: $feature"
    log_info "Worktree: $worktree_path"
    log_info "Branch: $branch_name"
    if [[ -n "$change" ]]; then
        log_info "Change: $change"
    fi
    log_info "Use '/awp-apply $feature' to start executing tasks"
}

main "$@"
