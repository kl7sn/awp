#!/usr/bin/env bash
# lib.sh - Shared utility functions for AWP v2 scripts

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Find skill root by locating manifest.json
skill_root_from_script() {
    local script_path="$1"
    local current_dir
    current_dir="$(cd "$(dirname "$script_path")" && pwd)"

    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/.src/manifest.json" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done

    log_error "Could not find .src/manifest.json - are you running from within the AWP skill?"
    return 1
}

# Find project root (git repository root)
project_root() {
    local root
    root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
        log_error "Not in a git repository"
        return 1
    }
    echo "$root"
}

# Require that we're in a git repository
require_git_repo() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_error "This command must be run from within a git repository"
        return 1
    fi
}

# Safely create a directory if it doesn't exist
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_info "Created directory: $dir"
    fi
}

# Check if a branch exists
branch_exists() {
    local branch="$1"
    git rev-parse --verify "$branch" >/dev/null 2>&1
}

# Check if a worktree exists
worktree_exists() {
    local path="$1"
    [[ -d "$path" ]] && git worktree list | grep -q "$path"
}

# Get the main branch name (main or master)
get_main_branch() {
    if git rev-parse --verify main >/dev/null 2>&1; then
        echo "main"
    elif git rev-parse --verify master >/dev/null 2>&1; then
        echo "master"
    else
        log_error "Could not find main or master branch"
        return 1
    fi
}

# Get the current branch name
get_current_branch() {
    local branch
    branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" || {
        log_error "Could not determine current branch"
        return 1
    }
    if [[ "$branch" == "HEAD" ]]; then
        log_error "Detached HEAD state, cannot determine branch"
        return 1
    fi
    echo "$branch"
}

# Check if there are uncommitted changes in a worktree
has_uncommitted_changes() {
    local worktree_path="$1"
    (cd "$worktree_path" && ! git diff-index --quiet HEAD --)
}

# Validate feature name (alphanumeric, hyphens, underscores only)
validate_feature_name() {
    local feature="$1"
    if [[ ! "$feature" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Invalid feature name: $feature"
        log_error "Feature names must contain only letters, numbers, hyphens, and underscores"
        return 1
    fi
}

# ============================================================
# AWP v2: State management functions
# ============================================================

# Get the .awp directory path (in project root)
awp_dir() {
    local proj_root
    proj_root="$(project_root)" || return 1
    echo "$proj_root/.awp"
}

# Get the features state directory
features_dir() {
    echo "$(awp_dir)/features"
}

# Get the changes directory (openspec/changes in project root)
changes_dir() {
    local proj_root
    proj_root="$(project_root)" || return 1
    echo "$proj_root/openspec/changes"
}

# Get a specific feature's state directory
feature_state_dir() {
    local feature="$1"
    echo "$(features_dir)/$feature"
}

# Get the state.json path for a feature
state_file() {
    local feature="$1"
    echo "$(feature_state_dir "$feature")/state.json"
}

# Read state.json for a feature (outputs JSON to stdout)
read_state() {
    local feature="$1"
    local sf
    sf="$(state_file "$feature")"

    if [[ ! -f "$sf" ]]; then
        log_error "State file not found: $sf"
        return 1
    fi

    cat "$sf"
}

# Write state.json for a feature (reads JSON from stdin or argument)
write_state() {
    local feature="$1"
    local json="${2:-$(cat)}"
    local sf
    sf="$(state_file "$feature")"

    ensure_dir "$(dirname "$sf")"
    echo "$json" > "$sf"
}

# Read a field from state.json using jq
read_state_field() {
    local feature="$1"
    local field="$2"

    read_state "$feature" | jq -r "$field"
}

# Update a field in state.json using jq
update_state_field() {
    local feature="$1"
    local jq_expr="$2"
    local sf
    sf="$(state_file "$feature")"

    local current
    current="$(read_state "$feature")" || return 1

    echo "$current" | jq "$jq_expr" > "$sf"
}

# Initialize state.json for a new feature
init_state() {
    local feature="$1"
    local branch="$2"
    local change="${3:-}"
    local groups_json="${4:-[]}"
    local base_branch="${5:-}"

    local source_field="null"
    local change_field="null"
    if [[ -n "$change" ]]; then
        source_field='"openspec"'
        change_field="\"$change\""
    fi

    # Default base branch to current branch if not specified
    if [[ -z "$base_branch" ]]; then
        base_branch="$(get_current_branch)" || return 1
    fi

    local json
    json=$(cat <<EOF
{
  "status": "pending",
  "current_group": 1,
  "groups": $groups_json,
  "branch": "$branch",
  "base_branch": "$base_branch",
  "source": $source_field,
  "change": $change_field,
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)

    write_state "$feature" "$json"
}

# ============================================================
# AWP v2: tasks.md parser
# ============================================================

# Parse tasks.md and output groups JSON array
# Input: path to tasks.md
# Output: JSON array of groups
parse_tasks_md() {
    local tasks_file="$1"

    if [[ ! -f "$tasks_file" ]]; then
        log_error "Tasks file not found: $tasks_file"
        return 1
    fi

    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import json, re, sys

groups = []
current_group = None

with open('$tasks_file', 'r') as f:
    for line in f:
        line = line.rstrip()
        # Match group heading: ## N. Title
        m = re.match(r'^## (\d+)\.\s+(.+)', line)
        if m:
            if current_group:
                groups.append(current_group)
            current_group = {
                'id': int(m.group(1)),
                'name': m.group(2).strip(),
                'status': 'pending',
                'tasks': []
            }
            continue
        # Match task: - [ ] N.M description or - [x] N.M description
        m = re.match(r'^- \[[ x]\] (\d+\.\d+)\s+', line)
        if m and current_group:
            current_group['tasks'].append(m.group(1))

if current_group:
    groups.append(current_group)

print(json.dumps(groups))
"
    else
        log_error "python3 is required for parsing tasks.md"
        return 1
    fi
}

# ============================================================
# AWP v2: Feature directory management
# ============================================================

# Create feature state directory
create_feature_dir() {
    local feature="$1"
    ensure_dir "$(feature_state_dir "$feature")"
}

# Remove feature state directory
remove_feature_dir() {
    local feature="$1"
    local dir
    dir="$(feature_state_dir "$feature")"
    if [[ -d "$dir" ]]; then
        rm -rf "$dir"
        log_info "Removed feature state: $dir"
    fi
}

# List all features (outputs feature names, one per line)
list_features() {
    local fdir
    fdir="$(features_dir)"
    if [[ ! -d "$fdir" ]]; then
        return 0
    fi
    for d in "$fdir"/*/; do
        if [[ -d "$d" ]] && [[ -f "$d/state.json" ]]; then
            basename "$d"
        fi
    done
}

# Check if a feature exists
feature_exists() {
    local feature="$1"
    local sf
    sf="$(state_file "$feature")"
    [[ -f "$sf" ]]
}

# ============================================================
# AWP v2: Changes directory management
# ============================================================

# Create changes directory for a change (in openspec/changes)
create_change_dir() {
    local change_name="$1"
    ensure_dir "$(changes_dir)/$change_name"
}

# Check if a change exists
change_exists() {
    local change_name="$1"
    local cdir
    cdir="$(changes_dir)/$change_name"
    [[ -d "$cdir" ]]
}

# Get tasks.md path for a change
change_tasks_file() {
    local change_name="$1"
    echo "$(changes_dir)/$change_name/tasks.md"
}
