# Background Jobs Quick Reference

Part of the Wheels application guide; start with `../CLAUDE.md`.

```cfm
// app/jobs/SendWelcomeEmailJob.cfc
component extends="wheels.Job" {
    function config() {
        super.config();
        this.queue = "mailers";
        this.maxRetries = 5;
    }
    public void function perform(struct data = {}) {
        // model() works in a job; sendEmail() is controller-only, so send through a mailer
        user = model("User").findByKey(arguments.data.userId);
        new app.mailers.UserMailer().sendWelcome(user);
    }
}

// Enqueue
job = new app.jobs.SendWelcomeEmailJob();
job.enqueue(data={userId: user.id});
job.enqueueIn(seconds=300, data={userId: user.id});
job.enqueueAt(runAt=scheduledDate, data={});

// Process
result = (new wheels.Job()).processQueue(queue="mailers", limit=10);
stats = (new wheels.Job()).queueStats();
```

Worker CLI (`cli/lucli/Module.cfc::jobs()` — thin wrapper over the `jobsProcessNext`/`jobsStatus` bridge commands in `vendor/wheels/public/views/cli.cfm`; requires a running server):
```bash
wheels jobs work --queue=mailers --interval=3   # long-lived worker loop; --max-jobs=N for one-shot batches, --quiet
wheels jobs status [--queue=mailers] [--format=json]
```
The `retry`/`purge`/`monitor` verbs are tracked follow-ups ([#3090](https://github.com/wheels-dev/wheels/issues/3090)) — invoking one errors with the programmatic equivalent (`(new wheels.Job()).retryFailed()` / `.purgeCompleted()`).

Backoff: `this.baseDelay = 2`, `this.maxDelay = 3600` in `config()`. Formula: `Min(baseDelay * 2^attempt, maxDelay)`. The `wheels_jobs` table is auto-created on first enqueue/processing — no migration needed.
