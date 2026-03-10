---
description: Check AWP installation health and verify project integrity
---

# awp doctor

Run a comprehensive health check on the AWP installation and project setup.

## Use when

- Troubleshooting AWP issues
- User requests "awp doctor"
- After installation to verify everything is set up correctly
- Before starting a new feature to ensure system is healthy

## What it does

Runs multiple checks:

1. **Git repository check**: Verifies you're in a git repository
2. **Directory structure check**: Validates all required directories exist
3. **Script permissions check**: Ensures all scripts are executable
4. **Agents directory check**: Verifies agent configurations exist
5. **Worktrees check**: Lists active worktrees

## Standard execution

```bash
bash .claude/skills/awp/.src/scripts/run-doctor.sh
```

## Success indicators

- All checks pass (5/5)
- Success message: "AWP is healthy and ready to use!"
- Green checkmarks for each validation

## Failure fallback

If checks fail:

1. **Not in git repo**: Navigate to a git repository
2. **Missing directories**: Run `awp init` to initialize
3. **Missing files**: Reinstall AWP or run `awp upgrade`
4. **Script permissions**: Doctor will auto-fix by making scripts executable
5. **No agents**: Run `awp init` to create default agents

## Check details

### Git repository check
- Verifies `git rev-parse --git-dir` succeeds

### Directory structure check
- Validates directories: `.src/`, `.src/core/`, `.src/scripts/`, `.src/tools/`, `.src/templates/`, `.src/references/`
- Validates files: `manifest.json`, `schema.json`, `lib.sh`, and all core scripts

### Script permissions check
- Ensures all `.sh` files in `.src/scripts/` are executable
- Auto-fixes permissions if needed

### Agents directory check
- Verifies `agents/` directory exists
- Checks each agent has a `prompt.md` file
- Reports count of configured agents

### Worktrees check
- Lists active worktrees in `worktrees/` directory
- Reports count of active worktrees

## Notes

- Safe to run anytime
- Does not modify project files (except fixing script permissions)
- Provides detailed diagnostics for troubleshooting
- Returns exit code 0 if all checks pass, 1 if any fail
