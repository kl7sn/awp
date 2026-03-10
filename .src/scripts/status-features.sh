#!/usr/bin/env bash
# status-features.sh - Show all features and their TDD pipeline status (AWP v2)

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
    printf "%-20s %-8s %-12s %-6s %-20s\n" "FEATURE" "GROUP" "PHASE" "CYCLE" "BRANCH"
    printf "%-20s %-8s %-12s %-6s %-20s\n" "-------" "-----" "-----" "-----" "------"

    while IFS= read -r feature; do
        local state
        state="$(read_state "$feature" 2>/dev/null)" || continue

        local phase current_group total_groups cycle branch
        phase="$(echo "$state" | jq -r '.phase')"
        current_group="$(echo "$state" | jq -r '.current_group')"
        total_groups="$(echo "$state" | jq '.groups | length')"
        cycle="$(echo "$state" | jq -r '.cycle')"
        branch="$(echo "$state" | jq -r '.branch')"

        local group_display
        if [[ "$total_groups" -eq 0 ]]; then
            group_display="-"
        else
            group_display="${current_group}/${total_groups}"
        fi

        printf "%-20s %-8s %-12s %-6s %-20s\n" "$feature" "$group_display" "$phase" "$cycle" "$branch"
    done <<< "$features"
}

main "$@"
