---
description: Review and execute tasks for a feature
---

# awp apply

Review and execute tasks for a feature, group by group, using the executor agent.

## Use when

- Ready to implement a feature after `awp propose`
- User requests "awp apply <feature-name>"
- Resuming work on a partially completed feature

## What it does

For each task group in the feature:

1. **Review**: Executor reads context files from `openspec/changes/<change>/` and analyzes the current group's tasks
2. **Confirm**: Presents summary to user, waits for approval
3. **Execute**: Implements tasks one by one in the worktree
4. **Mark done**: Updates `openspec/changes/<change>/tasks.md` (`- [ ]` → `- [x]`)
5. **Advance**: Moves to next group
6. When all groups complete: status becomes `done`

## Standard execution

```bash
# Show current state
bash ~/.claude/skills/awp/.src/scripts/apply-feature.sh <feature-name>

# Advance to next group (after completing current group)
bash ~/.claude/skills/awp/.src/scripts/apply-feature.sh <feature-name> --next
```

The skill layer orchestrates execution:
1. Calls `apply-feature.sh <feature>` to get current state (JSON)
2. Loads `agents/executor/prompt.md`
3. Reads context from `openspec/changes/<change>/` (NOT `.awp/changes/`)
4. Executor reviews and executes tasks in `worktrees/<feature>/`
5. Marks completed tasks in `openspec/changes/<change>/tasks.md`
6. Calls `apply-feature.sh <feature> --next` to advance

## Data sources

- **Task artifacts**: `openspec/changes/<change>/` — the single source of truth for proposals, designs, specs, and tasks
- **Execution state**: `.awp/features/<feature>/state.json` — tracks which group is current and feature status

## Resume support

If interrupted, `awp apply` resumes from the last saved group. State is persisted to `.awp/features/<feature>/state.json` after each transition.

## Success indicators

- Feature status progresses: pending → in_progress → done
- All groups marked as `done` in state.json
- Completed tasks marked as `- [x]` in `openspec/changes/<change>/tasks.md`
- Final status: `done`
