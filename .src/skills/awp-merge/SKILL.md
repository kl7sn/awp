---
name: awp-merge
description: "Merge a completed feature to its base branch. Use when users say: awp merge, merge feature, 合并 feature."
---

# awp merge <feature-name>

Merge a completed feature to its base branch.

**Execution:**
```bash
bash ~/.claude/skills/awp/.src/scripts/merge-feature.sh <feature-name>
```

Requires feature state to be `done`. Reads `base_branch` from state.json, rebases onto it, merges, cleans up worktree/branch/state, and archives the change via `openspec archive`.

The base branch is set during `awp create --base <branch>`. If not specified, defaults to the current branch at creation time.

If conflicts arise during rebase, resolve them and re-run `/awp-merge`.
