---
description: >-
  Process work asynchronously using Wheels' database-backed job queue with
  retry logic, priority queues, and exponential backoff.
---

# Background Jobs

Wheels includes a built-in background job system for processing work asynchronously. Jobs are persisted to a database table, support priority queues, and automatically retry with exponential backoff on failure.

Common use cases include sending emails, processing uploads, generating reports, calling external APIs, and any other work that shouldn't block a user's request.

## Quick Start

### 1. Run the Migration

First, create the jobs table by running the included migration:

```
wheels dbmigrate latest
```

This creates the `_wheels_jobs` table. The migration file is at `app/migrator/migrations/20260221000001_create_wheels_jobs_table.cfc`.

### 2. Create a Job

Jobs live in `app/jobs/` and extend `wheels.Job`. Override the `perform()` method with your logic:

{% code title="app/jobs/SendWelcomeEmailJob.cfc" %}
```javascript
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
            template="/emails/welcome",
            layout="/emails/layout"
        );
    }

}
```
{% endcode %}

### 3. Enqueue from a Controller

```javascript
function create() {
    user = model("User").create(params.user);

    if (!user.hasErrors()) {
        // Enqueue the welcome email job
        job = new app.jobs.SendWelcomeEmailJob();
        job.enqueue(data={email: user.email, name: user.firstName});

        redirectTo(action="show", key=user.id, success="Account created!");
    } else {
        renderView(action="new");
    }
}
```

### 4. Process the Queue

Call `processQueue()` from a scheduled task (e.g., every 60 seconds) or a controller action:

```javascript
// In a scheduled task or admin controller
job = new wheels.Job();
result = job.processQueue(queue="mailers", limit=10);
// result = {processed: 5, failed: 1, errors: [...]}
```

## Job Configuration

Override `config()` in your job subclass to customize behavior:

```javascript
function config() {
    super.config();
    this.queue = "default";       // Queue name (default: "default")
    this.priority = 0;            // Higher = processed first
    this.maxRetries = 3;          // Max retry attempts before marking as failed
    this.retryBackoff = "exponential"; // Backoff strategy
    this.timeout = 300;           // Timeout in seconds
}
```

## Enqueueing Jobs

### Immediate Processing

```javascript
job = new app.jobs.ProcessOrderJob();
job.enqueue(data={orderId: order.id});
```

### Delayed Processing

```javascript
// Process after 5 minutes (300 seconds)
job = new app.jobs.SendReminderJob();
job.enqueueIn(seconds=300, data={userId: user.id});
```

### Scheduled Processing

```javascript
// Process at a specific date/time
job = new app.jobs.GenerateReportJob();
job.enqueueAt(runAt=CreateDateTime(2026, 3, 1, 9, 0, 0), data={reportType: "monthly"});
```

### Overriding Queue and Priority

All enqueue methods accept optional `queue` and `priority` overrides:

```javascript
job.enqueue(
    data={email: user.email},
    queue="urgent",   // Override the default queue
    priority=10       // Higher priority = processed first
);
```

## Retry Logic

When a job's `perform()` method throws an error, Wheels automatically retries it with exponential backoff:

| Attempt | Backoff Delay |
|---------|---------------|
| 1st retry | 4 seconds |
| 2nd retry | 8 seconds |
| 3rd retry | 16 seconds |
| 4th retry | 32 seconds |
| 5th retry | 64 seconds |

The formula is `2^(attempt + 1)` seconds. After exhausting all retries (`maxRetries`), the job is marked as `failed` and moved to the dead letter queue.

## Queue Management

### Queue Statistics

```javascript
job = new wheels.Job();
stats = job.queueStats();
// stats = {pending: 12, processing: 2, completed: 150, failed: 3, total: 167}

// Filter by queue name
stats = job.queueStats(queue="mailers");
```

### Retry Failed Jobs

Reset all failed jobs back to `pending` status for reprocessing:

```javascript
job = new wheels.Job();
count = job.retryFailed();              // All queues
count = job.retryFailed(queue="mailers"); // Specific queue
```

### Purge Completed Jobs

Clean up old completed jobs to keep the table manageable:

```javascript
job = new wheels.Job();
count = job.purgeCompleted(days=7);              // Delete completed jobs older than 7 days
count = job.purgeCompleted(days=30, queue="reports"); // Specific queue
```

## Processing Jobs

### From a Scheduled Task

The most common approach is to call `processQueue()` from a CFML scheduled task that runs every 30-60 seconds:

{% code title="Scheduled task handler" %}
```javascript
job = new wheels.Job();

// Process all queues
result = job.processQueue(limit=20);

// Or process specific queues with different limits
result = job.processQueue(queue="urgent", limit=50);
result = job.processQueue(queue="mailers", limit=10);
result = job.processQueue(queue="default", limit=5);
```
{% endcode %}

### From an Admin Controller

You can also expose a manual trigger for administrators:

```javascript
// In an admin controller
function processJobs() {
    job = new wheels.Job();
    result = job.processQueue(limit=20);

    redirectTo(
        action="dashboard",
        success="Processed #result.processed# jobs (#result.failed# failed)"
    );
}
```

## Job Lifecycle

Each job goes through these statuses:

| Status | Description |
|--------|-------------|
| `pending` | Waiting to be processed (including scheduled jobs whose `runAt` hasn't arrived) |
| `processing` | Currently being executed |
| `completed` | Finished successfully |
| `failed` | Exhausted all retries — in the dead letter queue |

## Database Schema

The `_wheels_jobs` table contains:

| Column | Type | Description |
|--------|------|-------------|
| `id` | string | UUID primary key |
| `jobClass` | string | Full component path (e.g., `app.jobs.SendWelcomeEmailJob`) |
| `queue` | string | Queue name |
| `data` | text | JSON-serialized job data |
| `priority` | integer | Processing priority (higher = first) |
| `status` | string | Current status |
| `attempts` | integer | Number of execution attempts |
| `maxRetries` | integer | Maximum retry attempts |
| `lastError` | text | Error message from the last failed attempt |
| `runAt` | datetime | When the job should be processed |
| `completedAt` | datetime | When the job completed successfully |
| `failedAt` | datetime | When the job permanently failed |
| `createdAt` | datetime | When the job was enqueued |
| `updatedAt` | datetime | Last status change |

## Best Practices

1. **Keep jobs small and focused**: Each job should do one thing. Chain multiple jobs for complex workflows.
2. **Make jobs idempotent**: Design `perform()` so it can safely run multiple times (retries will re-execute it).
3. **Use named queues**: Separate jobs by type (`mailers`, `reports`, `notifications`) so you can process them at different rates.
4. **Set appropriate priorities**: Use higher priority for time-sensitive jobs (password resets) and lower priority for background work (reports).
5. **Monitor the queue**: Check `queueStats()` regularly and alert on growing `failed` counts.
6. **Purge old jobs**: Run `purgeCompleted()` on a schedule to prevent table bloat.
7. **Handle missing tables gracefully**: If the `_wheels_jobs` table doesn't exist yet, `enqueue()` will log a warning and return `persisted=false` instead of throwing an error.
