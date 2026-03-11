---
description: Merge a completed feature to its base branch
---

# awp merge

Merge a completed feature branch back to its base branch, with rebase and cleanup.

## Use when

- Feature has reached `done` state after `awp apply`
- User requests "awp merge <feature-name>"
- Ready to integrate a completed feature

## What it does

1. Verifies feature state is `done`
2. Reads `base_branch` from state.json (fallback: main/master)
3. Rebases the feature branch onto the latest base branch
4. If rebase conflicts: aborts and prompts for resolution
5. Merges to base branch (fast-forward preferred, no-ff fallback)
6. Removes the worktree
7. Deletes the feature branch
8. Cleans up `.awp/features/<feature>/`
9. Archives the change via `openspec archive` (if linked to a change)

## Standard execution

```bash
bash .claude/skills/awp/.src/scripts/merge-feature.sh <feature-name>
```

Example:
```bash
bash .claude/skills/awp/.src/scripts/merge-feature.sh config-page
```

## Success indicators

- Feature branch merged into base branch
- Worktree removed
- Branch deleted
- Feature state cleaned up
- Change archived via openspec (if applicable)

## Failure fallback

1. **Not done**: Run `/awp-apply <feature>` to complete all task groups
2. **Uncommitted changes**: Commit or stash before merging
3. **Rebase conflicts**: Resolve conflicts, then re-run merge (may need `awp apply` to re-verify)

## Notes

- Rebases before merge to ensure clean history
- If rebase conflicts occur after resolution, consider re-running `/awp-merge`
- Calls `openspec archive --change <name>` after merge to archive change artifacts
- If openspec is not installed, logs a warning with the manual archive command
