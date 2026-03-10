#!/usr/bin/env bash
# run-feature.sh - Drive TDD pipeline for a feature (AWP v2)
#
# This script reads state.json and outputs the current phase info
# for the calling tool/skill to load the appropriate agent prompt.
# The actual agent execution is handled by the skill layer (Claude),
# not by this shell script.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

usage() {
    cat << EOF
Usage: $0 <feature-name> [--advance | --reject]

Read or advance the TDD pipeline state for a feature.

Arguments:
  feature-name    Name of the feature
  --advance       Mark current phase as complete, advance to next
  --reject        Reviewer rejects, reset to test phase (cycle++)

Without flags: outputs current state info (JSON) for the skill layer.

Example:
  $0 config-page              # Show current state
  $0 config-page --advance    # Advance to next phase
  $0 config-page --reject     # Reject and reset to tester
EOF
    exit 1
}

show_state() {
    local feature="$1"
    local state
    state="$(read_state "$feature")" || exit 1

    local phase current_group cycle total_groups group_name
    phase="$(echo "$state" | jq -r '.phase')"
    current_group="$(echo "$state" | jq -r '.current_group')"
    cycle="$(echo "$state" | jq -r '.cycle')"
    total_groups="$(echo "$state" | jq '.groups | length')"
    group_name="$(echo "$state" | jq -r ".groups[$((current_group - 1))].name // \"(no groups)\"")"

    local proj_root
    proj_root="$(project_root)" || exit 1
    local worktree_path="$proj_root/worktrees/$feature"
    local feedback_file
    feedback_file="$(review_feedback_file "$feature")"

    # Build info JSON for the skill layer
    jq -n \
        --arg feature "$feature" \
        --arg phase "$phase" \
        --arg cycle "$cycle" \
        --arg current_group "$current_group" \
        --arg total_groups "$total_groups" \
        --arg group_name "$group_name" \
        --arg worktree "$worktree_path" \
        --arg feedback_file "$feedback_file" \
        --argjson has_feedback "$([ -f "$feedback_file" ] && echo true || echo false)" \
        --argjson groups "$(echo "$state" | jq '.groups')" \
        '{
            feature: $feature,
            phase: $phase,
            cycle: ($cycle | tonumber),
            current_group: ($current_group | tonumber),
            total_groups: ($total_groups | tonumber),
            group_name: $group_name,
            worktree: $worktree,
            feedback_file: $feedback_file,
            has_feedback: $has_feedback,
            groups: $groups
        }'
}

advance_phase() {
    local feature="$1"
    local state
    state="$(read_state "$feature")" || exit 1

    local phase current_group total_groups
    phase="$(echo "$state" | jq -r '.phase')"
    current_group="$(echo "$state" | jq -r '.current_group')"
    total_groups="$(echo "$state" | jq '.groups | length')"

    case "$phase" in
        test)
            update_state_field "$feature" '.phase = "implement"'
            log_success "Advanced: test → implement"
            ;;
        implement)
            update_state_field "$feature" '.phase = "review"'
            log_success "Advanced: implement → review"
            ;;
        review)
            # Reviewer approved: mark group done, advance to next group or approved
            local next_group=$((current_group + 1))
            if [[ $next_group -gt $total_groups ]]; then
                # All groups done
                update_state_field "$feature" "
                    .groups[$((current_group - 1))].status = \"done\" |
                    .phase = \"approved\"
                "
                log_success "All groups complete! Feature is now approved."
                log_info "Use 'awp merge $feature' to merge to main."
            else
                # Advance to next group
                update_state_field "$feature" "
                    .groups[$((current_group - 1))].status = \"done\" |
                    .groups[$((next_group - 1))].status = \"in_progress\" |
                    .current_group = $next_group |
                    .phase = \"test\" |
                    .cycle = 1
                "
                # Clear review feedback for new group
                local feedback_file
                feedback_file="$(review_feedback_file "$feature")"
                rm -f "$feedback_file"
                log_success "Group $current_group done. Starting group $next_group."
            fi
            ;;
        approved)
            log_warn "Feature is already approved. Use 'awp merge $feature' to merge."
            ;;
        *)
            log_error "Unknown phase: $phase"
            exit 1
            ;;
    esac
}

reject_phase() {
    local feature="$1"
    local state
    state="$(read_state "$feature")" || exit 1

    local phase
    phase="$(echo "$state" | jq -r '.phase')"

    if [[ "$phase" != "review" ]]; then
        log_error "Can only reject during review phase (current: $phase)"
        exit 1
    fi

    update_state_field "$feature" '
        .phase = "test" |
        .cycle = (.cycle + 1)
    '

    local cycle
    cycle="$(read_state_field "$feature" '.cycle')"
    log_warn "Reviewer rejected. Resetting to tester (cycle $cycle)."
    log_info "Review feedback should be written to: $(review_feedback_file "$feature")"
}

main() {
    if [[ $# -lt 1 ]]; then
        usage
    fi

    local feature="$1"
    local action="show"

    if [[ $# -ge 2 ]]; then
        case "$2" in
            --advance) action="advance" ;;
            --reject) action="reject" ;;
            *) usage ;;
        esac
    fi

    require_git_repo || exit 1
    validate_feature_name "$feature" || exit 1

    if ! feature_exists "$feature"; then
        log_error "Feature not found: $feature"
        log_error "Use 'awp create $feature' to create it first"
        exit 1
    fi

    case "$action" in
        show) show_state "$feature" ;;
        advance) advance_phase "$feature" ;;
        reject) reject_phase "$feature" ;;
    esac
}

main "$@"
