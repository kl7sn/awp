---
name: awp-merge
description: "Merge an approved feature to main. Use when users say: awp merge, merge feature, 合并到 main."
---

# awp merge <feature-name>

Merge an approved feature to main.

**Execution:**
```bash
bash ~/.claude/skills/awp/.src/scripts/merge-feature.sh <feature-name>
```

Requires feature state to be `done`. Rebases onto main, merges, cleans up worktree/branch/state, and archives the change via `openspec archive`.

If conflicts arise during rebase, resolve them and re-run `/awp-merge`.
