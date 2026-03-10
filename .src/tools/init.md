---
description: Initialize AWP in the current project
---

# awp init

Initialize AWP (Multi-Agent Worktree Project) in the current project.

## Use when

- Setting up AWP for the first time in a project
- User explicitly requests "awp init"
- Need to create agent directories and configuration files

## What it does

1. Creates the `agents/` directory in the skill root
2. Copies default agent templates (developer, tester, reviewer) from `.src/templates/agents/`
3. Creates the `.state/` directory for internal state
4. Generates the `SKILL.md` routing file with command documentation

## Standard execution

```bash
bash .claude/skills/awp/.src/scripts/init-project-data.sh
```

## Success indicators

- `agents/` directory created with subdirectories for each agent role
- Each agent directory contains a `prompt.md` file
- `SKILL.md` file generated at skill root
- Success message: "AWP initialization complete!"

## Failure fallback

If initialization fails:
1. Check that you're in a git repository
2. Verify the skill is properly installed at `.claude/skills/awp/`
3. Check file permissions on the `.src/` directory
4. Run `awp doctor` to diagnose issues

## Notes

- Safe to run multiple times (skips existing files)
- Does not modify the project's git repository
- Only creates user data directories and configuration files
