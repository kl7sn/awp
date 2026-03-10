---
description: Enter explore mode for thinking through ideas and requirements
---

# awp explore

Enter an interactive exploration mode for thinking through ideas, investigating problems, and clarifying requirements before or during implementation.

## Use when

- Thinking through a problem before proposing a solution
- User requests "awp explore"
- Need to investigate codebase or clarify requirements
- Brainstorming approaches to a feature

## What it does

Enters an interactive thinking-partner mode where you can:
- Explore ideas and trade-offs
- Investigate codebase structure
- Clarify requirements through discussion
- Prototype approaches before committing to a plan

## Standard execution

This is a skill-layer command. No shell script is needed — the skill handles the interaction directly.

## Notes

- Replaces `opsx:explore`
- No state changes or file modifications
- Can be used before `awp propose` or during `awp run`
- Exit explore mode by starting a concrete action (propose, create, run)
