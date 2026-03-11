---
description: Purge old completed or failed jobs from the queue table.
---

# wheels jobs purge

Delete old jobs from the `wheels_jobs` table to prevent table bloat. By default, purges completed jobs older than 7 days.

## Usage

```bash
wheels jobs purge [options]
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--completed` | `true` | Purge completed jobs |
| `--failed` | `false` | Purge failed jobs |
| `--older-than` | `7` | Delete jobs older than this many days |
| `--queue` | _(all)_ | Filter by queue name |
| `--force` | `false` | Skip confirmation prompt |

## Examples

```bash
# Purge completed jobs older than 7 days (default)
wheels jobs purge

# Purge both completed and failed jobs older than 30 days
wheels jobs purge --completed --failed --older-than=30

# Purge only from a specific queue
wheels jobs purge --queue=reports --older-than=14

# Purge failed jobs only
wheels jobs purge --completed=false --failed --older-than=3
```

## Behavior

- Completed jobs are matched by `completedAt` date
- Failed jobs are matched by `failedAt` date
- Pending and processing jobs are never purged
- When both `--completed` and `--failed` are specified, each is purged separately and totals are reported
