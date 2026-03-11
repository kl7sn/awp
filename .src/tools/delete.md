---
description: Delete a feature's worktree, branch, and state
---

# awp delete

Remove a feature entirely: worktree, branch, and state files.

## Use when

- Abandoning a feature
- User requests "awp delete <feature-name>"
- Cleaning up after a feature is no longer needed

## What it does

1. Checks for uncommitted changes (blocks unless `--force`)
2. Removes the worktree at `worktrees/<feature>/`
3. Deletes the branch `<feature>`
4. Removes `.awp/features/<feature>/` state directory

## Standard execution

```bash
bash .claude/skills/awp/.src/scripts/delete-feature.sh <feature-name>
bash .claude/skills/awp/.src/scripts/delete-feature.sh <feature-name> --force
```

Example:
```bash
bash .claude/skills/awp/.src/scripts/delete-feature.sh config-page
```

## Success indicators

- Worktree removed
- Branch deleted
- Feature state directory removed

## Failure fallback

1. **Uncommitted changes**: Use `--force` or commit/stash first
2. **Worktree locked**: Close editors/terminals using the worktree

## Notes

- Usable at any stage (test, implement, review, approved)
- Use `--force` to bypass uncommitted changes check
- Does not remove `openspec/changes/` artifacts (proposal/design/specs remain)
