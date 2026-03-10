#!/usr/bin/env bash
# run-upgrade.sh - Upgrade AWP to the latest version

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

main() {
    log_info "Upgrading AWP..."

    local skill_root
    skill_root="$(skill_root_from_script "${BASH_SOURCE[0]}")" || exit 1

    # Check if skill_root is a git repository
    if [[ ! -d "$skill_root/.git" ]]; then
        log_error "AWP skill directory is not a git repository"
        log_error "Cannot upgrade. Please reinstall AWP by cloning from git."
        exit 1
    fi

    # Save current directory
    local original_dir
    original_dir="$(pwd)"

    # Change to skill root
    cd "$skill_root" || exit 1

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        log_error "AWP has uncommitted changes"
        log_error "Please commit or stash changes before upgrading"
        cd "$original_dir"
        exit 1
    fi

    # Get current branch
    local current_branch
    current_branch="$(git rev-parse --abbrev-ref HEAD)"

    log_info "Current branch: $current_branch"

    # Fetch latest changes
    log_info "Fetching latest changes..."
    if ! git fetch origin; then
        log_error "Failed to fetch from remote"
        cd "$original_dir"
        exit 1
    fi

    # Check if there are updates
    local local_commit
    local_commit="$(git rev-parse HEAD)"
    local remote_commit
    remote_commit="$(git rev-parse "origin/$current_branch" 2>/dev/null || echo "")"

    if [[ -z "$remote_commit" ]]; then
        log_warn "Remote branch not found: origin/$current_branch"
        log_info "Skipping upgrade"
        cd "$original_dir"
        return 0
    fi

    if [[ "$local_commit" == "$remote_commit" ]]; then
        log_success "AWP is already up to date"
        cd "$original_dir"
        return 0
    fi

    # Pull changes (fast-forward only)
    log_info "Pulling latest changes..."
    if git pull --ff-only origin "$current_branch"; then
        log_success "AWP upgraded successfully!"

        # Show what changed
        log_info "Changes:"
        git log --oneline "$local_commit..$remote_commit"
    else
        log_error "Failed to upgrade (fast-forward not possible)"
        log_error "Your local changes may conflict with remote changes"
        log_error "Please resolve manually or reinstall AWP"
        cd "$original_dir"
        exit 1
    fi

    cd "$original_dir"
}

main "$@"
