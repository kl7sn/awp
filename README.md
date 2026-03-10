# AWP: Feature-Driven TDD Pipeline

A Claude Code skill that automates Test-Driven Development workflows. AWP unifies feature planning, implementation, and review into a single command-line pipeline — propose a feature, create a branch, and let the TDD cycle (tester → developer → reviewer) run automatically.

## Key Concepts

- **1 feature = 1 branch = 1 worktree** — no more 3 worktrees per feature
- **Agents are pipeline stages**, not separate workspaces — tester writes tests, developer implements, reviewer audits
- **TDD cycles run per task group** — each `## N. Title` section in tasks.md gets its own tester → developer → reviewer loop
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
awp propose "user authentication"     # Design + specs + tasks + auto-create
awp run auth                           # TDD pipeline (auto)
awp merge auth                         # Rebase + merge + cleanup
```

```
                    ┌─────────────────────────┐
                    │                         │
                    ▼                         │
              ┌──────────┐                   │
              │  tester  │                   │
              │  writes  │                   │
              │  tests   │                   │
              └────┬─────┘                   │
                   │                         │
                   ▼                         │
            ┌────────────┐                   │
            │ developer  │                   │
            │ implements │                   │
            └────┬───────┘                   │
                 │                           │
                 ▼                           │
           ┌──────────┐                     │
           │ reviewer  │── reject ──────────┘
           └────┬─────┘
                │ approve
                ▼
          next group or
            approved
```

## Commands

| Command | Description |
|---------|-------------|
| `awp propose "<description>"` | Generate design, specs, and task breakdown |
| `awp create <feature> [--change <name>]` | Create worktree + branch, link to change |
| `awp run <feature>` | Drive TDD pipeline through all task groups |
| `awp merge <feature>` | Rebase main, merge, clean up |
| `awp delete <feature>` | Discard feature (worktree + branch + state) |
| `awp status` | Show all features with phase/group/cycle |
| `awp explore` | Think through ideas before proposing |
| `awp doctor` | Health check |
| `awp upgrade` | Pull latest version |

## Multi-Feature Parallel Development

Each feature is independent — run as many as you need:

```
awp status

FEATURE              GROUP    PHASE        CYCLE  BRANCH
-------              -----    -----        -----  ------
auth-system          1/2      implement    1      auth-system
payment-flow         2/3      review       2      payment-flow
user-profile         1/1      approved     1      user-profile
```

Merge order is up to you. Before merging, AWP rebases onto main. If conflicts arise, the TDD cycle re-runs from tester to ensure tests still pass.

## Directory Structure

```
project-root/
├── .awp/
│   ├── changes/                 # Proposals, designs, specs, tasks
│   │   └── <change-name>/
│   │       ├── proposal.md
│   │       ├── design.md
│   │       ├── specs/
│   │       └── tasks.md
│   └── features/                # Runtime state per feature
│       └── <feature>/
│           ├── state.json
│           └── review-feedback.md
├── worktrees/                   # Git worktrees (1 per feature)
│   └── <feature>/
└── .claude/skills/awp/
    ├── .src/                    # System scripts and tools
    └── agents/                  # Agent prompt templates
        ├── tester/prompt.md
        ├── developer/prompt.md
        └── reviewer/prompt.md
```

## State Machine

```
awp propose      awp run                              awp merge
    │                │                                     │
    ▼                ▼                                     ▼
 ┌──────┐   ┌────────────────────────────┐          ┌──────────┐
 │ init │──▶│  test → implement → review │── pass ─▶│ approved │──▶ merged
 └──────┘   └──────────┬─────────────────┘          └──────────┘
                       │          ▲
                       │ reject   │
                       └──────────┘
                      cycle++, back to test

                                              awp delete (any stage)
                                                  │
                                                  ▼
                                              deleted
```

## Task Groups

AWP reads `## N. Title` headings from tasks.md as TDD cycle boundaries:

```markdown
## 1. Backend CRUD API          ← Group 1: one TDD cycle
- [ ] 1.1 Implement repo layer
- [ ] 1.2 Implement handler layer

## 2. Frontend Admin Page       ← Group 2: another TDD cycle
- [ ] 2.1 Create route and component
- [ ] 2.2 Add API integration
```

Each group runs a full tester → developer → reviewer loop. The reviewer's rejection sends the group back to tester (not developer) — tests are the source of truth.

## Requirements

- Git 2.5+ (worktree support)
- Bash 4.0+
- jq (for JSON processing)
- Python 3 (for tasks.md parsing)
- Claude Code

## License

MIT License — see [LICENSE](LICENSE) for details.
