---
description: Show status of all active features
---

# awp status

Display a table of all active features with their TDD pipeline status.

## Use when

- Checking progress across multiple features
- User requests "awp status"
- Need to see which features are ready to merge

## What it does

1. Scans `.awp/features/*/state.json`
2. Displays a table with columns: FEATURE, GROUP, PHASE, CYCLE, BRANCH

## Standard execution

```bash
bash .claude/skills/awp/.src/scripts/status-features.sh
```

## Output example

```
FEATURE              GROUP    PHASE        CYCLE  BRANCH
-------              -----    -----        -----  ------
config-page          1/2      implement    1      config-page
auth-system          2/3      review       2      auth-system
user-profile         1/1      approved     1      user-profile
```

## Notes

- Shows all features regardless of phase
- GROUP column shows current/total task groups
- CYCLE shows how many TDD iterations the current group has gone through
