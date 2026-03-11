#!/usr/bin/env bash
# apply-feature.sh - Read or advance feature state (AWP v2)
#
# Outputs current group info for the skill layer.
# --next marks current group done and advances.
# Actual task execution is handled by the executor agent.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

usage() {
    cat << EOF
Usage: $0 <feature-name> [--next]

Read or advance the feature state.

Arguments:
  feature-name    Name of the feature
  --next          Mark current group done, advance to next

Without flags: outputs current state (JSON) for the skill layer.

Example:
  $0 config-page          # Show current state
  $0 config-page --next   # Advance to next group
EOF
    exit 1
}

show_state() {
    local feature="$1"
    local state
    state="$(read_state "$feature")" || exit 1

    local status current_group total_groups group_name
    status="$(echo "$state" | jq -r '.status')"
    current_group="$(echo "$state" | jq -r '.current_group')"
    total_groups="$(echo "$state" | jq '.groups | length')"
    group_name="$(echo "$state" | jq -r ".groups[$((current_group - 1))].name // \"(no groups)\"")"

    local proj_root
    proj_root="$(project_root)" || exit 1
    local worktree_path="$proj_root/worktrees/$feature"
    local change
    change="$(echo "$state" | jq -r '.change // empty')"

    jq -n \
        --arg feature "$feature" \
        --arg status "$status" \
        --arg current_group "$current_group" \
        --arg total_groups "$total_groups" \
        --arg group_name "$group_name" \
        --arg worktree "$worktree_path" \
        --arg change "$change" \
        --argjson groups "$(echo "$state" | jq '.groups')" \
        '{
            feature: $feature,
            status: $status,
            current_group: ($current_group | tonumber),
            total_groups: ($total_groups | tonumber),
            group_name: $group_name,
            worktree: $worktree,
            change: $change,
            groups: $groups
        }'
}

advance_group() {
    local feature="$1"
    local state
    state="$(read_state "$feature")" || exit 1

    local status current_group total_groups
    status="$(echo "$state" | jq -r '.status')"
    current_group="$(echo "$state" | jq -r '.current_group')"
    total_groups="$(echo "$state" | jq '.groups | length')"

    if [[ "$status" == "done" ]]; then
        log_warn "Feature is already done. Use '/awp-merge $feature' to merge."
        return 0
    fi

    local next_group=$((current_group + 1))
    if [[ $next_group -gt $total_groups ]]; then
        update_state_field "$feature" "
            .groups[$((current_group - 1))].status = \"done\" |
            .status = \"done\"
        "
        log_success "All groups complete! Feature is ready to merge."
        log_info "Use '/awp-merge $feature' to merge to main."
    else
        update_state_field "$feature" "
            .groups[$((current_group - 1))].status = \"done\" |
            .groups[$((next_group - 1))].status = \"in_progress\" |
            .current_group = $next_group
        "
        log_success "Group $current_group done. Starting group $next_group."
    fi
}

main() {
    if [[ $# -lt 1 ]]; then
        usage
    fi

    local feature="$1"
    local action="show"

    if [[ $# -ge 2 ]]; then
        case "$2" in
            --next) action="next" ;;
            *) usage ;;
        esac
    fi

    require_git_repo || exit 1
    validate_feature_name "$feature" || exit 1

    if ! feature_exists "$feature"; then
        log_error "Feature not found: $feature"
        log_error "Use '/awp-propose' to create a feature first"
        exit 1
    fi

    case "$action" in
        show) show_state "$feature" ;;
        next) advance_group "$feature" ;;
    esac
}

main "$@"
