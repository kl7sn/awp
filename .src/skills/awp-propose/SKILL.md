---
name: awp-propose
description: "Propose a new feature with design, specs, and tasks. Use when users say: awp propose, propose a feature, 提出一个新功能."
---

# awp propose "<description>"

Generate a feature proposal with design, specs, tasks, then auto-create the feature.

**Implementation:**
1. Derive a kebab-case change name from the description
2. Call OpenSpec CLI to create change and generate artifacts:
   ```bash
   openspec new change "<change-name>"
   openspec status --change "<change-name>" --json
   openspec instructions <artifact-id> --change "<change-name>" --json
   ```
3. Generate artifacts in dependency order: proposal.md -> design.md -> specs/*.md -> tasks.md
4. Store artifacts in `.awp/changes/<change-name>/`
5. Auto-create the feature:
   ```bash
   bash ~/.claude/skills/awp/.src/scripts/create-feature.sh "<change-name>"
   ```

**Result:** Change name = feature name = branch name. Ready for `awp run`.

## Artifact Creation Guidelines

- Follow the `instruction` field from `openspec instructions` for each artifact type
- Read dependency artifacts for context before creating new ones
- Use `template` as the structure for your output file
- `context` and `rules` are constraints for YOU, not content for the file — do NOT copy them into the artifact
- If context is critically unclear, ask the user
- If a change with that name already exists, ask if user wants to continue it or create a new one
