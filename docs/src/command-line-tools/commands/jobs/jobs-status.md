---
description: Display job queue statistics with per-queue breakdown.
---

# wheels jobs status

Show the current state of the job queue, broken down by queue name and status.

## Usage

```bash
wheels jobs status [options]
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--queue` | _(all)_ | Filter by queue name |
| `--format` | `table` | Output format: `table` or `json` |

## Examples

```bash
# Show all queues in table format
wheels jobs status

# Filter to a specific queue
wheels jobs status --queue=mailers

# JSON output for scripting
wheels jobs status --format=json
```

## Output

The table displays per-queue counts for each status (pending, processing, completed, failed) with a totals row:

```
| Queue       | Pending | Processing | Completed | Failed | Total |
|-------------|---------|------------|-----------|--------|-------|
| default     | 5       | 1          | 230       | 2      | 238   |
| mailers     | 12      | 0          | 89        | 0      | 101   |
| TOTAL       | 17      | 1          | 319       | 2      | 339   |
```
