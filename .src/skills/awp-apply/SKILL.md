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

2. **Switch to worktree** — ALL file operations MUST happen inside the worktree:
   ```bash
   cd <state.worktree>
   ```
   CRITICAL: Every file read, write, edit, and git command MUST use paths relative to the worktree.

3. **Load executor agent**: Read `agents/executor/prompt.md` from the skill root.

4. **Review current task group**:
   - Read context files from `.awp/changes/<change>/` (proposal.md, design.md, specs/, tasks.md)
   - Analyze the current group's tasks: scope, dependencies, risks
   - Present summary to user:
     ```
     ## Task Group N: <group-name>

     **Tasks:**
     1. <task>
     2. <task>
     ...

     **Scope:** <expected changes>
     **Concerns:** <risks or "None">

     Proceed with execution?
     ```

5. **Wait for user confirmation**. Do NOT execute without explicit approval.

6. **On confirmation**: Invoke `openspec-apply` to execute tasks in the worktree:
   - The change name is in `state.change`
   - openspec-apply reads tasks.md and implements them one by one
   - All work happens in the worktree directory

7. **After group completes**: Advance to next group:
   ```bash
   bash ~/.claude/skills/awp/.src/scripts/apply-feature.sh <feature-name> --next
   ```

8. **Repeat** from step 1 for the next group until all groups are done (status = "done").

9. When done, inform user they can merge:
   ```
   All groups complete! Use /awp-merge <feature-name> to merge.
   ```
