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
        user = model("User").findByKey(arguments.data.userId);
        new app.mailers.UserMailer().sendWelcome(user);
    }
}
```

`model()` works inside a job. `sendEmail()` does not: it is a controller
function, so send mail through a mailer (see `app/mailers/README.md`).

Enqueue from a controller:

```cfm
var job = new app.jobs.SendWelcomeEmailJob();
job.enqueue(data={userId: user.id});                // immediate
job.enqueueIn(seconds=300, data={userId: user.id}); // delayed 5 minutes
```

## Running jobs

Jobs persist to a `wheels_jobs` table and are dequeued by a worker process:

```bash
wheels jobs work                          # process all queues
wheels jobs work --queue=mailers          # specific queue
wheels jobs status                        # per-queue breakdown
```

The `wheels_jobs` table is created automatically on first use; there is no
migration to run.

See [Background Jobs](https://guides.wheels.dev/v4-2-0/digging-deeper/background-jobs/) in the guides for retries, backoff, priority queues, and the monitoring dashboard.
