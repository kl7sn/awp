# AWP：Feature 驱动的开发流水线

一个 Claude Code 技能，用于自动化功能开发工作流。AWP 将功能规划、实现和交付统一为一条命令行流水线 —— 提出需求、创建分支，让 executor 在你确认后逐组审查和实现任务。

## 核心理念

- **1 个 feature = 1 个分支 = 1 个 worktree** —— 干净隔离，统一命名
- **可配置基础分支** —— feature 默认从当前分支创建，合并回基础分支，再通过 PR 合入 main
- **Executor 先审查再实现** —— 展示任务摘要，等待你确认，然后执行
- **Task group 驱动执行** —— tasks.md 中的每个 `## N. 标题` 是一个独立的审查单元
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
awp explore                              # 探索想法（可选）
awp propose "用户认证系统"                  # 设计 + 规格 + 任务拆分 + 自动创建（基础分支：当前分支）
awp propose "认证" --base develop          # 同上，但从 develop 分支创建
awp apply auth                           # 逐组执行（审查 → 确认 → 实现）
awp merge auth                           # Rebase + 合并到基础分支 + 清理
```

```
awp propose
    │
    ▼
┌──────────┐
│  propose  │  生成提案、设计、规格、任务
│  + create │  自动创建 worktree + 分支
└────┬─────┘
     │
     ▼
┌──────────────────────────────────────┐
│            awp apply（逐组）            │
│                                      │
│  ┌────────────┐    ┌──────────────┐  │
│  │  executor   │──▶│    用户      │  │
│  │  审查任务    │   │  确认执行    │  │
│  └────────────┘    └──────┬───────┘  │
│                           │          │
│                    ┌──────▼───────┐  │
│                    │   executor   │  │
│                    │   实现任务    │  │
│                    └──────────────┘  │
│                                      │
│  每个 task group 重复以上流程         │
└──────────────┬───────────────────────┘
               │ 所有 group 完成
               ▼
         ┌──────────┐
         │ awp merge │  Rebase + 合并 + 清理
         └──────────┘
```

## 命令

| 命令 | 说明 |
|------|------|
| `awp propose "描述" [--base <branch>]` | 生成设计文档、规格和任务拆分 |
| `awp create <feature> [--change <name>] [--base <branch>]` | 创建 worktree + 分支，关联 change |
| `awp apply <feature>` | 逐组执行任务（审查 + 确认 + 实现） |
| `awp merge <feature>` | Rebase 基础分支、合并、清理 |
| `awp delete <feature> [--force]` | 丢弃 feature（worktree + 分支 + 状态） |
| `awp status` | 查看所有 feature 的分组进度和状态 |
| `awp explore` | 探索模式，在提案前思考方案 |
| `awp doctor` | 健康检查 |
| `awp upgrade` | 拉取最新版本 |

## 多 Feature 并行开发

每个 feature 相互独立，可以同时开发多个：

```
awp status

FEATURE              GROUP    STATUS       BRANCH
-------              -----    ------       ------
auth-system          1/2      in_progress  auth-system
payment-flow         2/3      done         payment-flow
user-profile         1/1      done         user-profile
```

合并顺序由你决定。合并前 AWP 自动 rebase 基础分支，如果有冲突，解决后重新运行。所有 feature 合并完成后，从基础分支向 main 提交 PR。

## 目录结构

```
项目根目录/
├── .awp/
│   └── features/                # 每个 feature 的运行状态
│       └── <feature>/
│           └── state.json
├── openspec/
│   └── changes/                 # 提案、设计、规格、任务
│       └── <change-name>/
│           ├── proposal.md
│           ├── design.md
│           ├── specs/
│           └── tasks.md
├── worktrees/                   # Git worktree（每个 feature 一个）
│   └── <feature>/
└── agents/                      # Agent prompt 模板
    └── executor/
        └── prompt.md
```

## 状态机

```
awp propose      awp apply                              awp merge
    │                │                                     │
    ▼                ▼                                     ▼
 ┌──────┐   ┌────────────────────────────┐          ┌──────────┐
 │ init │──▶│    逐组执行任务             │── 完成 ─▶│  merge   │──▶ merged
 └──────┘   └────────────────────────────┘          └──────────┘

                                              awp delete（任意阶段可用）
                                                  │
                                                  ▼
                                              deleted
```

### Feature 状态流转

```
pending → in_progress → done → merged
```

### Group 执行流程

```
每个 group：
  1. Executor 读取任务和上下文
  2. Executor 向用户展示任务摘要
  3. 用户确认（或调整）
  4. Executor 在 worktree 中实现任务
  5. 推进到下一个 group
```

## Task Group

AWP 读取 tasks.md 中的 `## N. 标题` 作为执行边界：

```markdown
## 1. 后端 CRUD API              ← Group 1
- [ ] 1.1 实现 repo 层
- [ ] 1.2 实现 handler 层

## 2. 前端管理页面               ← Group 2
- [ ] 2.1 创建路由和组件
- [ ] 2.2 对接 API
```

每个 group 独立审查和确认。Executor 在实现过程中将完成的任务标记为 `- [x]`。

## 系统要求

- Git 2.5+（worktree 支持）
- Bash 4.0+
- jq（JSON 处理）
- Python 3（tasks.md 解析）
- Claude Code

## 许可证

MIT License —— 详见 [LICENSE](LICENSE)。
