#!/usr/bin/env bash
# init-project-data.sh - Initialize AWP project data directories and files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

main() {
    log_info "Initializing AWP project data..."

    # Find skill root
    local skill_root
    skill_root="$(skill_root_from_script "${BASH_SOURCE[0]}")" || exit 1

    # Find project root
    local proj_root
    proj_root="$(project_root)" || exit 1

    log_info "Skill root: $skill_root"
    log_info "Project root: $proj_root"

    # Create agents directory
    local agents_dir="$skill_root/agents"
    ensure_dir "$agents_dir"

    # Copy agent templates if available
    local templates_dir="$skill_root/.src/templates/agents"
    if [[ -d "$templates_dir" ]]; then
        for agent_dir in "$templates_dir"/*; do
            if [[ -d "$agent_dir" ]]; then
                local agent_name
                agent_name="$(basename "$agent_dir")"
                local target_dir="$agents_dir/$agent_name"

                if [[ ! -d "$target_dir" ]]; then
                    cp -r "$agent_dir" "$target_dir"
                    log_success "Created agent template: $agent_name"
                else
                    log_warn "Agent already exists: $agent_name (skipping)"
                fi
            fi
        done
    fi

    # Create .awp directories
    ensure_dir "$proj_root/.awp/features"

    # Generate SKILL.md routing file
    local skill_md="$skill_root/SKILL.md"
    if [[ -f "$skill_md" ]]; then
        log_warn "SKILL.md already exists (skipping)"
    else
        cat > "$skill_md" << 'EOF'
---
description: AWP - Feature-driven automation with unified propose/apply/merge pipeline
---

# AWP: Feature-Driven Pipeline

This skill manages feature development with automated pipelines. Each feature gets one worktree and one branch. The executor agent reviews and implements tasks group by group.

## Commands

### awp propose "<description>"

Generate a feature proposal with design, specs, and tasks.

**Execution:** Driven by skill layer using OpenSpec CLI.

### awp create <feature-name> [--change <change-name>]

Create a worktree and branch for a feature.

**Execution:**
```bash
bash .claude/skills/awp/.src/scripts/create-feature.sh <feature-name> [--change <change-name>]
```

### awp apply <feature-name>

Review and execute tasks for a feature, group by group.

**Execution:**
```bash
bash .claude/skills/awp/.src/scripts/apply-feature.sh <feature-name>
bash .claude/skills/awp/.src/scripts/apply-feature.sh <feature-name> --next
```

### awp merge <feature-name>

Merge a completed feature to main.

**Execution:**
```bash
bash .claude/skills/awp/.src/scripts/merge-feature.sh <feature-name>
```

### awp delete <feature-name>

Delete a feature's worktree, branch, and state.

**Execution:**
```bash
bash .claude/skills/awp/.src/scripts/delete-feature.sh <feature-name>
```

### awp status

Show all features and their execution status.

**Execution:**
```bash
bash .claude/skills/awp/.src/scripts/status-features.sh
```

### awp explore

Enter explore mode for thinking through ideas and requirements.

**Execution:** Driven by skill layer (interactive mode).

### awp doctor

Check project health and verify AWP installation.

**Execution:**
```bash
bash .claude/skills/awp/.src/scripts/run-doctor.sh
```

### awp upgrade

Upgrade AWP to the latest version from git.

**Execution:**
```bash
bash .claude/skills/awp/.src/scripts/run-upgrade.sh
```

## Agent

- **executor**: Reviews tasks for quality, presents summary to user, implements after confirmation

## Directory Structure

```
project-root/
├── .awp/
│   └── features/      # Runtime state (state.json)
├── openspec/
│   └── changes/       # OpenSpec artifacts (proposal, design, specs, tasks)
├── worktrees/         # Git worktrees (1 per feature)
└── .claude/skills/awp/
    ├── .src/          # System files
    └── agents/        # Agent prompt templates
```

## Workflow

1. Propose: `awp propose "feature description"`
2. Run: `awp apply my-feature` (executor pipeline)
3. Merge: `awp merge my-feature`
EOF
        log_success "Generated SKILL.md routing file"
    fi

    # Install sub-skill symlinks
    local skills_src="$skill_root/.src/skills"
    local skills_dst
    skills_dst="$(dirname "$skill_root")"  # ~/.claude/skills/

    if [[ -d "$skills_src" ]]; then
        for skill_dir in "$skills_src"/*/; do
            if [[ -f "$skill_dir/SKILL.md" ]]; then
                local skill_name
                skill_name="$(basename "$skill_dir")"
                local target="$skills_dst/$skill_name"
                if [[ -L "$target" ]]; then
                    rm "$target"
                fi
                ln -sfn "$skill_dir" "$target"
                log_success "Linked skill: /$(echo "$skill_name" | sed 's/^awp-/awp-/')"
            fi
        done
    fi

    log_success "AWP initialization complete!"
    log_info "Available commands: /awp-propose, /awp-apply, /awp-merge, /awp-status, etc."
}

main "$@"
