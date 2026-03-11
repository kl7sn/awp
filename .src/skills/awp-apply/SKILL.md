---
name: awp-apply
description: "Apply a feature's tasks. Use when users say: awp apply, apply feature, 应用 feature, execute tasks."
---

# awp apply <feature-name>

Review and execute tasks for a feature, group by group.

**Implementation:**

1. Get current state:
   ```bash
   bash ~/.claude/skills/awp/.src/scripts/apply-feature.sh <feature-name>
   ```
   This returns JSON with: feature, status, current_group, total_groups, group_name, worktree, change, base_branch, groups.

2. **Switch to worktree** — ALL file operations MUST happen inside the worktree:
   ```bash
   cd <state.worktree>
   ```
   CRITICAL: Every file read, write, edit, and git command MUST use paths relative to the worktree.

3. **Load executor agent**: Read `agents/executor/prompt.md` from the skill root.

4. **Read context from `openspec/changes/<change>/`** (in the project root, NOT in `.awp/`):
   - proposal.md, design.md, specs/, tasks.md
   - These files live at `<project-root>/openspec/changes/<state.change>/`

5. **Review current task group** and assess risk:
   - **Low risk** (new files, tests, config, docs, clear-cut CRUD): show brief summary, auto-execute
   - **High risk** (deleting/renaming code, changing APIs, security, migrations, ambiguous tasks): show full summary, wait for confirmation

6. **Execute tasks** in the worktree:
   - Implement each task one by one
   - All code changes happen in the worktree directory
   - After completing each task, mark it in `<project-root>/openspec/changes/<change>/tasks.md`: `- [ ]` → `- [x]`
   - IMPORTANT: Do NOT create or write to `.awp/changes/` — the only tasks.md is in `openspec/changes/`

8. **After group completes**: Advance to next group:
   ```bash
   bash ~/.claude/skills/awp/.src/scripts/apply-feature.sh <feature-name> --next
   ```

9. **Repeat** from step 1 for the next group until all groups are done (status = "done").

10. When done, inform user they can merge:
    ```
    All groups complete! Use /awp-merge <feature-name> to merge.
    ```
