---
name: awp-init
description: "Initialize AWP in the current project. Use when users say: awp init, initialize awp, 初始化 AWP."
---

# awp init

Initialize AWP in the current project.

**Execution:**
```bash
bash ~/.claude/skills/awp/.src/scripts/init-project-data.sh
```

Creates `.awp/features/` directory, copies agent templates, and sets up the project for AWP workflows. Change artifacts are managed by OpenSpec in `openspec/changes/`.
