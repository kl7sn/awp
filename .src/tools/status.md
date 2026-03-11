---
description: Show status of all active features
---

# awp status

Display a table of all active features with their execution status.

## Use when

- Checking progress across multiple features
- User requests "awp status"
- Need to see which features are ready to merge

## What it does

1. Scans `.awp/features/*/state.json`
2. Displays a table with columns: FEATURE, GROUP, STATUS, BRANCH

## Standard execution

```bash
bash .claude/skills/awp/.src/scripts/status-features.sh
```

## Output example

```
FEATURE              GROUP    STATUS       BRANCH
-------              -----    ------       ------
config-page          1/2      running      config-page
auth-system          2/3      done         auth-system
user-profile         1/1      approved     user-profile
```

## Notes

- Shows all features regardless of status
- GROUP column shows current/total task groups
