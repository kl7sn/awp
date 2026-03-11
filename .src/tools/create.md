---
description: Create a worktree and branch for a feature
---

# awp create

Create a git worktree and branch for a feature, with optional OpenSpec change association.

## Use when

- Starting implementation of a new feature
- User requests "awp create <feature-name>"
- After `awp propose` to begin working on a proposed change

## What it does

1. Validates the feature name (alphanumeric, hyphens, underscores)
2. Creates a single git worktree at `worktrees/<feature>/`
3. Creates a branch named `<feature>` from the main branch
4. If `--change` is specified:
   - Reads `openspec/changes/<change-name>/tasks.md`
   - Parses task groups from `## N. Title` headings
   - Initializes state.json with groups and task references
5. Creates `.awp/features/<feature>/state.json` with initial state

## Standard execution

```bash
bash .claude/skills/awp/.src/scripts/create-feature.sh <feature-name>
bash .claude/skills/awp/.src/scripts/create-feature.sh <feature-name> --change <change-name>
```

Example:
```bash
bash .claude/skills/awp/.src/scripts/create-feature.sh config-page --change config-page
```

## Success indicators

- Worktree created at `worktrees/<feature>/`
- Branch created: `<feature>`
- State file created: `.awp/features/<feature>/state.json`

## Failure fallback

1. Check that you're in a git repository
2. Verify the feature name is valid
3. Check if worktree already exists (`awp delete` first)
4. Run `awp doctor` to verify installation

## Notes

- Creates exactly 1 worktree per feature (not 3 like v1)
- Feature state is stored in `.awp/features/`, separate from the worktree
