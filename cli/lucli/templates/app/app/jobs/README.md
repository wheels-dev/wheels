# app/jobs/

Background jobs. Each job is a `.cfc` extending `wheels.Job`.

## Quick start

Define a job:

```cfm
// app/jobs/SendWelcomeEmailJob.cfc
component extends="wheels.Job" {
    function config() {
        super.config();
        this.queue = "mailers";
        this.maxRetries = 5;
    }

    public void function perform(struct data = {}) {
        sendEmail(to=arguments.data.email, subject="Welcome!", from="app@example.com");
    }
}
```

Enqueue from a controller:

```cfm
var job = new app.jobs.SendWelcomeEmailJob();
job.enqueue(data={email: user.email});           // immediate
job.enqueueIn(seconds=300, data={email: "..."}); // delayed 5 minutes
```

## Running jobs

Jobs persist to a `wheels_jobs` table and are dequeued by a worker process:

```bash
wheels jobs work                          # process all queues
wheels jobs work --queue=mailers          # specific queue
wheels jobs status                        # per-queue breakdown
```

## Requirements

The first job enqueued needs the job table. Generate and run the migration:

```bash
wheels generate migration create_wheels_jobs_table
wheels migrate latest
```

See [Background Jobs](https://wheels.dev/v4-0-0-snapshot/digging-deeper/) in the guides for retries, backoff, priority queues, and the monitoring dashboard.
