# AWP: Feature-Driven Development Pipeline

A Claude Code skill that automates feature development workflows. AWP unifies feature planning, implementation, and delivery into a single command-line pipeline — propose a feature, create a branch, and let the executor review and implement task groups with your confirmation.

## Key Concepts

- **1 feature = 1 branch = 1 worktree** — clean isolation, unified naming
- **Executor reviews before implementing** — presents task summary, waits for your confirmation, then executes
- **Task groups drive execution** — each `## N. Title` section in tasks.md is an independently reviewable unit
- **Unified command system** — `awp` is the single entry point for planning, execution, and delivery

## Installation

```bash
git clone https://github.com/kl7sn/awp.git .claude/skills/awp
```

```
awp init
```

## Workflow

```
awp explore                              # Think through ideas (optional)
awp propose "user authentication"        # Design + specs + tasks + auto-create
awp apply auth                             # Execute task groups (review → confirm → implement)
awp merge auth                           # Rebase + merge + cleanup
```

```
awp propose
    │
    ▼
┌──────────┐
│  propose  │  Generate proposal, design, specs, tasks
│  + create │  Auto-create worktree + branch
└────┬─────┘
     │
     ▼
┌──────────────────────────────────────┐
│            awp apply (per group)        │
│                                      │
│  ┌────────────┐    ┌──────────────┐  │
│  │  executor   │──▶│    user      │  │
│  │  reviews    │   │  confirms    │  │
│  └────────────┘    └──────┬───────┘  │
│                           │          │
│                    ┌──────▼───────┐  │
│                    │   executor   │  │
│                    │  implements  │  │
│                    └──────────────┘  │
│                                      │
│  repeat for each task group          │
└──────────────┬───────────────────────┘
               │ all groups done
               ▼
         ┌──────────┐
         │ awp merge │  Rebase + merge + cleanup
         └──────────┘
```

## Commands

| Command | Description |
|---------|-------------|
| `awp propose "<description>"` | Generate design, specs, and task breakdown |
| `awp create <feature> [--change <name>]` | Create worktree + branch, link to change |
| `awp apply <feature>` | Execute task groups with review and confirmation |
| `awp merge <feature>` | Rebase main, merge, clean up |
| `awp delete <feature> [--force]` | Discard feature (worktree + branch + state) |
| `awp status` | Show all features with group progress and status |
| `awp explore` | Think through ideas before proposing |
| `awp doctor` | Health check |
| `awp upgrade` | Pull latest version |

## Multi-Feature Parallel Development

Each feature is independent — run as many as you need:

```
awp status

FEATURE              GROUP    STATUS       BRANCH
-------              -----    ------       ------
auth-system          1/2      in_progress  auth-system
payment-flow         2/3      done         payment-flow
user-profile         1/1      done         user-profile
```

Merge order is up to you. Before merging, AWP rebases onto main. If conflicts arise, resolve them and re-run.

## Directory Structure

```
project-root/
├── .awp/
│   └── features/                # Runtime state per feature
│       └── <feature>/
│           └── state.json
├── openspec/
│   └── changes/                 # Proposals, designs, specs, tasks
│       └── <change-name>/
│           ├── proposal.md
│           ├── design.md
│           ├── specs/
│           └── tasks.md
├── worktrees/                   # Git worktrees (1 per feature)
│   └── <feature>/
└── agents/                      # Agent prompt templates
    └── executor/
        └── prompt.md
```

## State Machine

```
awp propose      awp apply                              awp merge
    │                │                                     │
    ▼                ▼                                     ▼
 ┌──────┐   ┌────────────────────────────┐          ┌──────────┐
 │ init │──▶│  execute group by group    │── done ─▶│  merge   │──▶ merged
 └──────┘   └────────────────────────────┘          └──────────┘

                                              awp delete (any stage)
                                                  │
                                                  ▼
                                              deleted
```

### Feature Status Flow

```
pending → in_progress → done → merged
```

### Group Execution Flow

```
For each group:
  1. Executor reads tasks and context
  2. Executor presents summary to user
  3. User confirms (or adjusts)
  4. Executor implements tasks in worktree
  5. Advance to next group
```

## Task Groups

AWP reads `## N. Title` headings from tasks.md as execution boundaries:

```markdown
## 1. Backend CRUD API          ← Group 1
- [ ] 1.1 Implement repo layer
- [ ] 1.2 Implement handler layer

## 2. Frontend Admin Page       ← Group 2
- [ ] 2.1 Create route and component
- [ ] 2.2 Add API integration
```

Each group is reviewed and confirmed independently. The executor marks completed tasks as `- [x]` during implementation.

## Requirements

- Git 2.5+ (worktree support)
- Bash 4.0+
- jq (for JSON processing)
- Python 3 (for tasks.md parsing)
- Claude Code

## License

MIT License — see [LICENSE](LICENSE) for details.
