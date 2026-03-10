# AWP：Feature 驱动的 TDD 自动化流水线

一个 Claude Code 技能，用于自动化测试驱动开发工作流。AWP 将功能规划、实现和审查统一为一条命令行流水线 —— 提出需求、创建分支，让 TDD 循环（tester → developer → reviewer）自动运行。

## 核心理念

- **1 个 feature = 1 个分支 = 1 个 worktree** —— 不再每个 agent 一个 worktree
- **Agent 是流水线阶段**，不是独立工作空间 —— tester 写测试、developer 实现、reviewer 审查
- **TDD 循环按 task group 运行** —— tasks.md 中的每个 `## N. 标题` 对应一轮完整的 tester → developer → reviewer
- **统一命令体系** —— `awp` 是规划、执行、交付的唯一入口

## 安装

```bash
git clone https://github.com/kl7sn/awp.git .claude/skills/awp
```

```
awp init
```

## 工作流

```
awp propose "用户认证系统"              # 设计 + 规格 + 任务拆分 + 自动创建
awp run auth                            # TDD 流水线（自动推进）
awp merge auth                          # Rebase + 合并 + 清理
```

```
                    ┌─────────────────────────┐
                    │                         │
                    ▼                         │
              ┌──────────┐                   │
              │  tester  │                   │
              │  写测试   │                   │
              └────┬─────┘                   │
                   │                         │
                   ▼                         │
            ┌────────────┐                   │
            │ developer  │                   │
            │  写实现     │                   │
            └────┬───────┘                   │
                 │                           │
                 ▼                           │
           ┌──────────┐                     │
           │ reviewer  │── 不通过 ──────────┘
           └────┬─────┘
                │ 通过
                ▼
          下一个 group
           或 approved
```

## 命令

| 命令 | 说明 |
|------|------|
| `awp propose "描述"` | 生成设计文档、规格和任务拆分 |
| `awp create <feature> [--change <name>]` | 创建 worktree + 分支，关联 change |
| `awp run <feature>` | 按 task group 驱动 TDD 流水线 |
| `awp merge <feature>` | Rebase main、合并、清理 |
| `awp delete <feature>` | 丢弃 feature（worktree + 分支 + 状态） |
| `awp status` | 查看所有 feature 的阶段/group/cycle |
| `awp explore` | 探索模式，在提案前思考方案 |
| `awp doctor` | 健康检查 |
| `awp upgrade` | 拉取最新版本 |

## 多 Feature 并行开发

每个 feature 相互独立，可以同时开发多个：

```
awp status

FEATURE              GROUP    PHASE        CYCLE  BRANCH
-------              -----    -----        -----  ------
auth-system          1/2      implement    1      auth-system
payment-flow         2/3      review       2      payment-flow
user-profile         1/1      approved     1      user-profile
```

合并顺序由你决定。合并前 AWP 自动 rebase main，如果有冲突，解决后 TDD 循环从 tester 重跑以确保测试仍然通过。

## 目录结构

```
项目根目录/
├── .awp/
│   ├── changes/                 # 提案、设计、规格、任务
│   │   └── <change-name>/
│   │       ├── proposal.md
│   │       ├── design.md
│   │       ├── specs/
│   │       └── tasks.md
│   └── features/                # 每个 feature 的运行状态
│       └── <feature>/
│           ├── state.json
│           └── review-feedback.md
├── worktrees/                   # Git worktree（每个 feature 一个）
│   └── <feature>/
└── .claude/skills/awp/
    ├── .src/                    # 系统脚本和工具
    └── agents/                  # Agent prompt 模板
        ├── tester/prompt.md
        ├── developer/prompt.md
        └── reviewer/prompt.md
```

## 状态机

```
awp propose      awp run                              awp merge
    │                │                                     │
    ▼                ▼                                     ▼
 ┌──────┐   ┌────────────────────────────┐          ┌──────────┐
 │ init │──▶│  test → implement → review │── 通过 ─▶│ approved │──▶ merged
 └──────┘   └──────────┬─────────────────┘          └──────────┘
                       │          ▲
                       │ 不通过    │
                       └──────────┘
                     cycle++, 回到 test

                                              awp delete（任意阶段可用）
                                                  │
                                                  ▼
                                              deleted
```

## Task Group

AWP 读取 tasks.md 中的 `## N. 标题` 一级标题作为 TDD 循环的边界：

```markdown
## 1. 后端 CRUD API              ← Group 1：一轮 TDD 循环
- [ ] 1.1 实现 repo 层
- [ ] 1.2 实现 handler 层

## 2. 前端管理页面               ← Group 2：另一轮 TDD 循环
- [ ] 2.1 创建路由和组件
- [ ] 2.2 对接 API
```

每个 group 运行一轮完整的 tester → developer → reviewer 循环。Reviewer 不通过时回退到 tester（不是 developer）—— 测试是源头。

## 系统要求

- Git 2.5+（worktree 支持）
- Bash 4.0+
- jq（JSON 处理）
- Python 3（tasks.md 解析）
- Claude Code

## 许可证

MIT License —— 详见 [LICENSE](LICENSE)。
