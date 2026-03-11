#!/usr/bin/env bash
# status-features.sh - Show all features and their status (AWP v2)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

main() {
    require_git_repo || exit 1

    local features
    features="$(list_features)"

    if [[ -z "$features" ]]; then
        log_info "No active features"
        return 0
    fi

    # Print table header
    printf "%-20s %-8s %-10s %-20s\n" "FEATURE" "GROUP" "STATUS" "BRANCH"
    printf "%-20s %-8s %-10s %-20s\n" "-------" "-----" "------" "------"

    while IFS= read -r feature; do
        local state
        state="$(read_state "$feature" 2>/dev/null)" || continue

        local status current_group total_groups branch
        status="$(echo "$state" | jq -r '.status')"
        current_group="$(echo "$state" | jq -r '.current_group')"
        total_groups="$(echo "$state" | jq '.groups | length')"
        branch="$(echo "$state" | jq -r '.branch')"

        local group_display
        if [[ "$total_groups" -eq 0 ]]; then
            group_display="-"
        else
            group_display="${current_group}/${total_groups}"
        fi

        printf "%-20s %-8s %-10s %-20s\n" "$feature" "$group_display" "$status" "$branch"
    done <<< "$features"
}

main "$@"
