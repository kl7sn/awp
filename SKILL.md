---
name: awp
description: "AWP overview and help. Use when users say: awp, awp help, what is awp, AWP 帮助."
---

# AWP: Feature-Driven Development Pipeline

AWP automates feature development workflows. Each feature gets one worktree and one branch. An executor agent reviews tasks, then delegates to openspec-apply for execution.

## Commands

| Command | Description |
|---------|-------------|
| `/awp-propose` | Propose — design, specs, tasks, auto-create feature |
| `/awp-apply` | Apply — review tasks, confirm, execute via openspec-apply |
| `/awp-merge` | Merge — rebase main, merge, archive, clean up |
| `/awp-delete` | Delete — discard feature + change artifacts |
| `/awp-status` | Status — show all features with group/status |
| `/awp-explore` | Explore — think through ideas before proposing |
| `/awp-init` | Init — initialize AWP in current project |
| `/awp-doctor` | Doctor — health check |
| `/awp-upgrade` | Upgrade — pull latest version |

## Quick Start

```
/awp-propose "user authentication"     # Design + specs + tasks + auto-create
/awp-apply auth                          # Review tasks -> confirm -> execute
/awp-merge auth                        # Rebase + merge + archive + cleanup
```

## Pipeline

```
executor reviews task group -> user confirms -> openspec-apply executes
         |                                              |
         next group <--- group done -------------------+
```

Run `/awp-init` first to set up the project and install all sub-commands.
