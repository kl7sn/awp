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
    ensure_dir "$proj_root/.awp/changes"

    # Generate SKILL.md routing file
    local skill_md="$skill_root/SKILL.md"
    if [[ -f "$skill_md" ]]; then
        log_warn "SKILL.md already exists (skipping)"
    else
        cat > "$skill_md" << 'EOF'
---
description: AWP - Feature-driven TDD automation with unified propose/create/run/merge pipeline
---

# AWP: Feature-Driven TDD Pipeline

This skill manages feature development with automated TDD pipelines. Each feature gets one worktree and one branch. Agent roles (tester, developer, reviewer) are pipeline stages, not separate workspaces.

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

### awp run <feature-name>

Run the TDD pipeline (tester → developer → reviewer) for a feature.

**Execution:**
```bash
bash .claude/skills/awp/.src/scripts/run-feature.sh <feature-name>
bash .claude/skills/awp/.src/scripts/run-feature.sh <feature-name> --advance
bash .claude/skills/awp/.src/scripts/run-feature.sh <feature-name> --reject
```

### awp merge <feature-name>

Merge an approved feature to main.

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

Show all features and their TDD pipeline status.

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

## Pipeline Stages

- **tester**: Writes tests first (TDD red phase)
- **developer**: Implements code to pass tests (TDD green phase)
- **reviewer**: Audits changes, approves or rejects (sends back to tester)

## Directory Structure

```
project-root/
├── .awp/
│   ├── changes/       # OpenSpec artifacts (proposal, design, specs, tasks)
│   └── features/      # Runtime state (state.json, review-feedback.md)
├── worktrees/         # Git worktrees (1 per feature)
└── .claude/skills/awp/
    ├── .src/          # System files
    └── agents/        # Agent prompt templates
```

## Workflow

1. Propose: `awp propose "feature description"`
2. Create: `awp create my-feature --change my-feature`
3. Run: `awp run my-feature` (TDD pipeline)
4. Merge: `awp merge my-feature`
EOF
        log_success "Generated SKILL.md routing file"
    fi

    log_success "AWP initialization complete!"
    log_info "Use 'awp propose' to start a new feature or 'awp create <name>' to begin"
}

main "$@"
