---
description: Run the TDD pipeline for a feature
---

# awp run

Drive the TDD pipeline (tester → developer → reviewer) for a feature, cycling through task groups until approved.

## Use when

- Ready to implement a feature after `awp create`
- User requests "awp run <feature-name>"
- Resuming work on a partially completed feature

## What it does

For each task group in the feature:

1. **Test phase**: Loads `agents/tester/prompt.md`, tester writes tests for the group's tasks
2. **Implement phase**: Loads `agents/developer/prompt.md`, developer implements code to pass tests
3. **Review phase**: Loads `agents/reviewer/prompt.md`, reviewer audits the group's changes
   - **Pass**: Marks group as done, advances to next group
   - **Reject**: Writes feedback to `review-feedback.md`, resets to test phase (cycle++)
4. When all groups pass review: state becomes `approved`

## Standard execution

```bash
# Show current state
bash .claude/skills/awp/.src/scripts/run-feature.sh <feature-name>

# Advance current phase (after agent completes work)
bash .claude/skills/awp/.src/scripts/run-feature.sh <feature-name> --advance

# Reviewer rejects (reset to tester)
bash .claude/skills/awp/.src/scripts/run-feature.sh <feature-name> --reject
```

The skill layer orchestrates agent execution:
1. Calls `run-feature.sh <feature>` to get current state
2. Loads the appropriate agent prompt based on phase
3. Agent works in `worktrees/<feature>/`
4. Calls `run-feature.sh <feature> --advance` or `--reject` based on outcome

## State transitions

```
test → implement → review → (next group's test | approved)
                     ↓ reject
                    test (cycle++)
```

## Resume support

If interrupted, `awp run` resumes from the last saved phase. State is persisted to `.awp/features/<feature>/state.json` after each transition.

## Success indicators

- Feature state progresses through phases
- Final state: `approved`
- All groups marked as `done` in state.json

## Notes

- Replaces `opsx:apply`
- TDD cycles run per task group (## heading in tasks.md), not per individual task
- Reviewer rejection always returns to tester (TDD principle)
- Review feedback is written to `.awp/features/<feature>/review-feedback.md`
