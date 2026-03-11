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

Requires feature state to be `approved`. Rebases onto main, merges, cleans up worktree/branch/state.

If conflicts arise during rebase, resolve them and the TDD cycle re-runs from tester to ensure tests still pass.
