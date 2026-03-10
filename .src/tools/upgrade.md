---
description: Upgrade AWP to the latest version from git
---

# awp upgrade

Upgrade AWP to the latest version by pulling changes from the git repository.

## Use when

- Want to get the latest features and bug fixes
- User requests "awp upgrade"
- After seeing a notification about a new version
- Periodically to stay up to date

## What it does

1. Verifies AWP is installed as a git repository
2. Checks for uncommitted changes in AWP directory
3. Fetches latest changes from remote
4. Compares local and remote versions
5. Pulls changes using fast-forward only
6. Shows what changed in the upgrade

## Standard execution

```bash
bash .claude/skills/awp/.src/scripts/run-upgrade.sh
```

## Success indicators

- Success message: "AWP upgraded successfully!"
- Shows commit log of changes
- No errors during git pull

## Failure fallback

If upgrade fails:

1. **Not a git repository**: AWP was not installed via git clone
   - Solution: Reinstall by cloning from git

2. **Uncommitted changes**: Local modifications to AWP files
   - Solution: Commit or stash changes before upgrading

3. **Fast-forward not possible**: Local and remote have diverged
   - Solution: Resolve conflicts manually or reinstall

4. **No remote branch**: Branch doesn't exist on remote
   - Solution: Check your git remote configuration

5. **Network issues**: Cannot reach remote repository
   - Solution: Check internet connection and git remote URL

## Notes

- Only works if AWP was installed via `git clone`
- Uses `--ff-only` to prevent merge commits
- Does not modify user data (`agents/`, `worktrees/`, `.state/`)
- Shows changelog of what was updated
- If already up to date, reports "AWP is already up to date"
- Preserves current branch (usually main or master)

## Installation method matters

AWP must be installed as a git repository for upgrades to work:

```bash
# Correct installation (supports upgrade)
git clone https://github.com/kl7sn/awp.git .claude/skills/awp

# Incorrect installation (no upgrade support)
# Downloading and extracting a zip file
```
