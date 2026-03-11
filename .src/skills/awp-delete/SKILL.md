---
name: awp-delete
description: "Delete a feature's worktree, branch, state, and change artifacts. Use when users say: awp delete, delete feature, 删除 feature."
---

# awp delete <feature-name> [--force] [--keep-change]

Delete a feature: worktree, branch, state, and associated OpenSpec change artifacts.

**Execution:**
```bash
bash ~/.claude/skills/awp/.src/scripts/delete-feature.sh <feature-name> [--force] [--keep-change]
```

**Flags:**
- `--force` — force delete even with uncommitted changes
- `--keep-change` — preserve `openspec/changes/<name>/` artifacts (proposal, design, specs, tasks)

**Confirm before executing** — this is a destructive action.
