---
description: Retry failed jobs by resetting them to pending status.
---

# wheels jobs retry

Reset failed jobs back to `pending` status so they will be picked up by the next worker cycle. Resets the attempt counter and clears the error state.

## Usage

```bash
wheels jobs retry [options]
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--queue` | _(all)_ | Filter by queue name |
| `--limit` | `0` | Maximum number of jobs to retry (0 = all) |

## Examples

```bash
# Retry all failed jobs across all queues
wheels jobs retry

# Retry only failed mailer jobs
wheels jobs retry --queue=mailers

# Retry at most 10 failed jobs (oldest first)
wheels jobs retry --limit=10
```

## Behavior

- Sets `status` back to `pending`
- Resets `attempts` to `0`
- Clears `lastError` and `failedAt`
- Sets `runAt` to now (immediate processing)
- When `--limit` is specified, retries the oldest failed jobs first
