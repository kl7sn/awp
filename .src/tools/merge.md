---
description: Merge an approved feature to the main branch
---

# awp merge

Merge an approved feature branch back to the main branch, with rebase and cleanup.

## Use when

- Feature has reached `approved` state after `awp run`
- User requests "awp merge <feature-name>"
- Ready to integrate a completed feature

## What it does

1. Verifies feature state is `approved`
2. Rebases the feature branch onto the latest main
3. If rebase conflicts: aborts and prompts for resolution
4. Merges to main (fast-forward preferred, no-ff fallback)
5. Removes the worktree
6. Deletes the feature branch
7. Cleans up `.awp/features/<feature>/`

## Standard execution

```bash
bash .claude/skills/awp/.src/scripts/merge-feature.sh <feature-name>
```

Example:
```bash
bash .claude/skills/awp/.src/scripts/merge-feature.sh config-page
```

## Success indicators

- Feature branch merged into main
- Worktree removed
- Branch deleted
- Feature state cleaned up

## Failure fallback

1. **Not approved**: Run `awp run <feature>` to complete TDD pipeline
2. **Uncommitted changes**: Commit or stash before merging
3. **Rebase conflicts**: Resolve conflicts, then re-run merge (may need `awp run` to re-verify)

## Notes

- No longer requires agent name (v1: `awp merge feat developer`)
- Rebases before merge to ensure clean history
- If rebase conflicts occur after resolution, consider re-running `awp run` from tester to verify tests still pass
- Replaces the archive step of `opsx:archive`
