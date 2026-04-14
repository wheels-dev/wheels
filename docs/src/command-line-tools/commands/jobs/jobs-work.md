---
description: Start a persistent job worker daemon that polls for and processes background jobs.
---

# wheels jobs work

Start a job worker that continuously polls the job queue and processes pending jobs. The worker claims jobs using optimistic locking, making it safe to run multiple workers concurrently.

## Usage

```bash
wheels jobs work [options]
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--queue` | _(all)_ | Comma-delimited queue names to process |
| `--interval` | `5` | Seconds between poll cycles |
| `--max-jobs` | `0` | Stop after processing this many jobs (0 = unlimited) |
| `--timeout` | `300` | Job execution timeout in seconds |
| `--quiet` | `false` | Suppress per-job output, only show errors |

## Examples

```bash
# Process all queues with defaults
wheels jobs work

# Process only mailer and notification queues
wheels jobs work --queue=mailers,notifications

# Fast polling with a job limit
wheels jobs work --interval=2 --max-jobs=500

# Quiet mode for production
wheels jobs work --queue=default --quiet
```

## Concurrency

Run multiple worker processes for parallelism. Each worker independently claims jobs via optimistic locking (`UPDATE WHERE status='pending' AND id=:id`), so no job is processed twice.

```bash
# Terminal 1
wheels jobs work --queue=mailers

# Terminal 2
wheels jobs work --queue=default,reports
```

## Behavior

1. Each poll cycle, the worker calls the Wheels bridge to claim the next pending job
2. If a job is found, it's marked as `processing` and executed
3. On success, the job is marked `completed`; on failure, it's retried with exponential backoff or marked `failed`
4. If no jobs are available, the worker sleeps for `--interval` seconds
5. When a job completes successfully, the worker immediately checks for more work before sleeping
