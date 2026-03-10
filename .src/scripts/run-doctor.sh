#!/usr/bin/env bash
# run-doctor.sh - Health check for AWP installation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

check_git_repo() {
    log_info "Checking git repository..."
    if git rev-parse --git-dir >/dev/null 2>&1; then
        log_success "Git repository detected"
        return 0
    else
        log_error "Not in a git repository"
        return 1
    fi
}

check_directory_structure() {
    log_info "Checking directory structure..."
    local skill_root
    skill_root="$(skill_root_from_script "${BASH_SOURCE[0]}")" || return 1

    local schema_file="$skill_root/.src/core/schema.json"
    if [[ ! -f "$schema_file" ]]; then
        log_error "Schema file not found: $schema_file"
        return 1
    fi

    local errors=0

    # Check required directories
    local required_dirs
    if command -v jq >/dev/null 2>&1; then
        required_dirs="$(jq -r '.required_dirs[]' "$schema_file")"
    else
        required_dirs=".src .src/core .src/scripts .src/tools .src/templates .src/references"
    fi

    for dir in $required_dirs; do
        local full_path="$skill_root/$dir"
        if [[ -d "$full_path" ]]; then
            log_success "Directory exists: $dir"
        else
            log_error "Missing directory: $dir"
            ((errors++))
        fi
    done

    # Check critical files
    local critical_files
    if command -v jq >/dev/null 2>&1; then
        critical_files="$(jq -r '.critical_files[]' "$schema_file")"
    else
        critical_files=".src/manifest.json .src/core/schema.json .src/scripts/lib.sh"
    fi

    for file in $critical_files; do
        local full_path="$skill_root/$file"
        if [[ -f "$full_path" ]]; then
            log_success "File exists: $file"
        else
            log_error "Missing file: $file"
            ((errors++))
        fi
    done

    if [[ $errors -eq 0 ]]; then
        log_success "Directory structure is valid"
        return 0
    else
        log_error "Found $errors issue(s) with directory structure"
        return 1
    fi
}

check_scripts_executable() {
    log_info "Checking script permissions..."
    local skill_root
    skill_root="$(skill_root_from_script "${BASH_SOURCE[0]}")" || return 1

    local scripts_dir="$skill_root/.src/scripts"
    local errors=0

    for script in "$scripts_dir"/*.sh; do
        if [[ -f "$script" ]]; then
            if [[ -x "$script" ]]; then
                log_success "Executable: $(basename "$script")"
            else
                log_warn "Not executable: $(basename "$script")"
                chmod +x "$script"
                log_info "Fixed permissions for: $(basename "$script")"
            fi
        fi
    done

    log_success "Script permissions verified"
    return 0
}

check_agents_directory() {
    log_info "Checking agents directory..."
    local skill_root
    skill_root="$(skill_root_from_script "${BASH_SOURCE[0]}")" || return 1

    local agents_dir="$skill_root/agents"
    if [[ ! -d "$agents_dir" ]]; then
        log_warn "Agents directory not found: $agents_dir"
        log_info "Run 'awp init' to initialize the project"
        return 1
    fi

    local agent_count=0
    for agent_dir in "$agents_dir"/*; do
        if [[ -d "$agent_dir" ]]; then
            local agent_name
            agent_name="$(basename "$agent_dir")"
            if [[ -f "$agent_dir/prompt.md" ]]; then
                log_success "Agent configured: $agent_name"
            else
                log_warn "Agent missing prompt.md: $agent_name"
            fi
            ((agent_count++))
        fi
    done

    if [[ $agent_count -eq 0 ]]; then
        log_warn "No agents configured"
        log_info "Run 'awp init' to create default agents"
        return 1
    fi

    log_success "Found $agent_count agent(s)"
    return 0
}

check_worktrees() {
    log_info "Checking active worktrees..."
    local project_root
    project_root="$(project_root 2>/dev/null)" || {
        log_warn "Not in a git repository, skipping worktree check"
        return 0
    }

    local worktrees_dir="$project_root/worktrees"
    if [[ ! -d "$worktrees_dir" ]]; then
        log_info "No worktrees directory found (this is normal if no features are active)"
        return 0
    fi

    local worktree_count=0
    while IFS= read -r line; do
        if [[ "$line" =~ worktrees/ ]]; then
            log_info "Active worktree: $line"
            ((worktree_count++))
        fi
    done < <(git worktree list)

    if [[ $worktree_count -eq 0 ]]; then
        log_info "No active worktrees"
    else
        log_success "Found $worktree_count active worktree(s)"
    fi

    return 0
}

main() {
    log_info "Running AWP health check..."
    echo ""

    local total_checks=0
    local passed_checks=0

    # Run all checks
    ((total_checks++))
    check_git_repo && ((passed_checks++))
    echo ""

    ((total_checks++))
    check_directory_structure && ((passed_checks++))
    echo ""

    ((total_checks++))
    check_scripts_executable && ((passed_checks++))
    echo ""

    ((total_checks++))
    check_agents_directory && ((passed_checks++))
    echo ""

    ((total_checks++))
    check_worktrees && ((passed_checks++))
    echo ""

    # Summary
    log_info "Health check complete: $passed_checks/$total_checks checks passed"

    if [[ $passed_checks -eq $total_checks ]]; then
        log_success "AWP is healthy and ready to use!"
        return 0
    else
        log_warn "Some checks failed. Please review the output above."
        return 1
    fi
}

main "$@"
