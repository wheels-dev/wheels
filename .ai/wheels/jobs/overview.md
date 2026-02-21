# Background Jobs

## Description
Wheels provides a database-backed job queue system for running tasks asynchronously. Jobs are persisted to a `_wheels_jobs` table, processed in priority order, and automatically retried with exponential backoff on failure.

## Key Points
- Jobs extend `wheels.Job` and implement a `perform()` method
- Database-backed persistence ensures jobs survive server restarts
- Automatic retry with exponential backoff (2^n seconds)
- Priority queues with named queue support
- Dead letter handling for permanently failed jobs
- Queue stats, retry, and purge management

## Quick Start

### 1. Run the Migration
```bash
wheels dbmigrate latest
```
This creates the `_wheels_jobs` table. The migration is at `app/migrator/migrations/20260221000001_create_wheels_jobs_table.cfc`.

### 2. Create a Job
```cfm
// app/jobs/SendWelcomeEmailJob.cfc
component extends="wheels.Job" {

    function config() {
        super.config();
        this.queue = "mailers";
        this.maxRetries = 5;
    }

    public void function perform(struct data = {}) {
        sendEmail(
            to=data.email,
            from="noreply@example.com",
            subject="Welcome!",
            template="/emails/welcome"
        );
    }
}
```

### 3. Enqueue the Job
```cfm
// In a controller action
job = new app.jobs.SendWelcomeEmailJob();
job.enqueue(data={email: user.email, name: user.firstName});
```

### 4. Process Jobs
```cfm
// In a scheduled task, CLI command, or controller
job = new wheels.Job();
result = job.processQueue(queue="mailers", limit=10);
// result = {processed: 5, failed: 1, errors: [...]}
```

## Job Configuration

Override defaults in your job's `config()` method:

| Property | Default | Description |
|----------|---------|-------------|
| `this.queue` | `"default"` | Queue name for routing jobs |
| `this.priority` | `0` | Priority (higher = processed first) |
| `this.maxRetries` | `3` | Max retry attempts before marking as failed |
| `this.retryBackoff` | `"exponential"` | Backoff strategy |
| `this.timeout` | `300` | Job timeout in seconds |

```cfm
component extends="wheels.Job" {
    function config() {
        super.config();
        this.queue = "critical";
        this.priority = 10;
        this.maxRetries = 5;
    }
}
```

## Enqueueing Jobs

### Immediate Processing
```cfm
job = new app.jobs.ProcessOrderJob();
result = job.enqueue(data={orderId: 123});
// result.id = "UUID", result.status = "pending"
```

### Delayed Processing
```cfm
// Process after 5 minutes
job.enqueueIn(seconds=300, data={orderId: 123});

// Process after 1 hour
job.enqueueIn(seconds=3600, data={report: "daily"});
```

### Scheduled Processing
```cfm
// Process at a specific time
job.enqueueAt(
    runAt=CreateDateTime(2026, 3, 1, 9, 0, 0),
    data={type: "monthly_report"}
);
```

### Override Queue and Priority
```cfm
job.enqueue(data={}, queue="high_priority", priority=100);
```

## Processing Jobs

### Basic Processing
```cfm
job = new wheels.Job();
result = job.processQueue();
// Processes up to 10 pending jobs from all queues
```

### Filtered Processing
```cfm
// Process only from a specific queue
result = job.processQueue(queue="mailers", limit=20);
```

### Processing Flow
1. Jobs with `status='pending'` and `runAt <= NOW()` are selected
2. Ordered by `priority DESC, runAt ASC` (highest priority, oldest first)
3. Each job is marked `status='processing'` and `attempts` incremented
4. The job's `perform()` method is called with the stored data
5. On success: `status='completed'`, `completedAt` set
6. On failure:
   - If attempts < maxRetries: `status='pending'`, `runAt` set to future (exponential backoff)
   - If attempts >= maxRetries: `status='failed'`, `failedAt` set (dead letter)

### Retry Backoff Schedule
| Attempt | Delay |
|---------|-------|
| 1st retry | 4 seconds |
| 2nd retry | 8 seconds |
| 3rd retry | 16 seconds |
| 4th retry | 32 seconds |
| 5th retry | 64 seconds |

## Queue Management

### Queue Statistics
```cfm
job = new wheels.Job();
stats = job.queueStats();
// {pending: 12, processing: 2, completed: 458, failed: 3, total: 475}

// Filter by queue
stats = job.queueStats(queue="mailers");
```

### Retry Failed Jobs
```cfm
// Retry all failed jobs (resets attempts, sets status to pending)
count = job.retryFailed();

// Retry only a specific queue
count = job.retryFailed(queue="mailers");
```

### Purge Completed Jobs
```cfm
// Delete completed jobs older than 7 days
count = job.purgeCompleted(days=7);

// Delete completed jobs older than 30 days from a specific queue
count = job.purgeCompleted(days=30, queue="reports");
```

## Database Schema

The `_wheels_jobs` table has these columns:

| Column | Type | Description |
|--------|------|-------------|
| `id` | VARCHAR(36) | UUID primary key |
| `jobClass` | VARCHAR(255) | Fully qualified CFC path |
| `queue` | VARCHAR(100) | Queue name |
| `data` | TEXT | JSON-serialized job data |
| `priority` | INTEGER | Processing priority |
| `status` | VARCHAR(20) | pending, processing, completed, failed |
| `attempts` | INTEGER | Number of execution attempts |
| `maxRetries` | INTEGER | Max allowed retries |
| `lastError` | TEXT | Last error message |
| `runAt` | DATETIME | When to process |
| `completedAt` | DATETIME | When completed |
| `failedAt` | DATETIME | When permanently failed |
| `createdAt` | DATETIME | When enqueued |
| `updatedAt` | DATETIME | Last status change |

## Running Workers

### Scheduled Task (Recommended)
Set up a CFML scheduled task to call `processQueue()` periodically:

```cfm
// In a controller or scheduled task runner
function processJobs() {
    var job = new wheels.Job();

    // Process each queue
    var result = job.processQueue(queue="default", limit=25);
    var mailResult = job.processQueue(queue="mailers", limit=10);

    // Clean up old completed jobs
    job.purgeCompleted(days=7);

    renderWith(data={
        default: result,
        mailers: mailResult
    });
}
```

### CLI Command
```bash
# Process jobs via a controller endpoint
curl http://localhost:8080/jobs/process?queue=default&limit=50
```

## Best Practices

1. **Keep `perform()` idempotent** — Jobs may be retried, so handle duplicate execution gracefully
2. **Use specific queues** — Separate `mailers`, `reports`, `default` to control throughput
3. **Set appropriate retries** — Transient failures (network) deserve more retries than logic errors
4. **Pass minimal data** — Store IDs, not entire objects. Look up fresh data in `perform()`
5. **Handle errors** — Let exceptions propagate for automatic retry; catch only for graceful handling
6. **Purge regularly** — Schedule `purgeCompleted()` to prevent table bloat
7. **Monitor stats** — Use `queueStats()` to track queue health

## Related
- [Database Migrations](../database/migrations/creating-migrations.md)
- [Controller Architecture](../controllers/architecture.md)
- [Email Sending](../communication/email-sending.md)
