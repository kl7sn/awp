---
description: Propose a new feature with design, specs, and tasks, then auto-create the feature
---

# awp propose

Generate a complete feature proposal with design, specifications, and implementation tasks. After all artifacts are generated, automatically create the feature (worktree + branch + state).

## Use when

- Starting a new feature from a description or idea
- User requests "awp propose <description>"
- Need to create design docs and task breakdown before implementation

## What it does

1. Derives a kebab-case change name from the description
2. Creates a change directory at `.awp/changes/<change-name>/`
3. Generates artifacts in sequence:
   - `proposal.md` — motivation and scope
   - `design.md` — technical decisions
   - `specs/` — detailed specifications
   - `tasks.md` — implementation task breakdown (grouped by `## N. Title`)
4. **Auto-creates the feature**: runs `create-feature.sh <change-name>` which:
   - Creates worktree at `worktrees/<change-name>/`
   - Creates branch `<change-name>`
   - Parses tasks.md into task groups
   - Initializes state.json linked to the change

## Standard execution

This command is driven by the skill layer. Internally it calls:

```bash
# 1. Create the change structure
openspec new change "<change-name>"

# 2. Generate artifacts (skill layer handles this)
openspec instructions <artifact-id> --change "<change-name>" --json
openspec status --change "<change-name>" --json

# 3. Auto-create feature after all artifacts are done
bash .claude/skills/awp/.src/scripts/create-feature.sh "<change-name>"
```

## Success indicators

- Change directory created at `.awp/changes/<change-name>/`
- All artifacts generated: proposal.md, design.md, specs/*.md, tasks.md
- Worktree created at `worktrees/<change-name>/`
- Branch created: `<change-name>`
- State initialized: `.awp/features/<change-name>/state.json`

## After propose

Feature is ready to run immediately:

```
awp apply <change-name>
```

## Notes

- Replaces `opsx:propose`
- Change name = feature name = branch name (unified naming)
- Task groups (## headings) in tasks.md define the execution group boundaries
- Each group should be a cohesive, independently verifiable unit of work
- If auto-create fails (e.g., branch conflict), artifacts are still preserved — run `awp create` manually
