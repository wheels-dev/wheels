---
description: Live monitoring dashboard for the job queue.
---

# wheels jobs monitor

Display a continuously refreshing dashboard showing queue statistics, throughput metrics, error rates, and recent job activity.

## Usage

```bash
wheels jobs monitor [options]
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--interval` | `3` | Refresh interval in seconds |
| `--queue` | _(all)_ | Filter by queue name |

## Examples

```bash
# Watch the dashboard with default settings
wheels jobs monitor

# Slower refresh rate
wheels jobs monitor --interval=10

# Monitor a specific queue
wheels jobs monitor --queue=mailers
```

## Dashboard Sections

### Queue Summary
Pending, processing, completed, and failed counts across all queues.

### Throughput (last 60 minutes)
- Completed and failed job counts
- Error rate percentage

### Recent Jobs
The 5 most recently updated jobs with status, class, queue, and timestamp.

### Timeout Recovery
If any processing jobs have exceeded their timeout, they are automatically recovered and reported.

## Behavior

- Each refresh cycle calls the Wheels bridge to fetch fresh statistics
- Timed-out jobs (stuck in `processing` longer than 300 seconds) are automatically recovered
- Press `Ctrl+C` to stop monitoring
