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
        var user = model("User").findByKey(arguments.data.userId);
        new app.mailers.UserMailer().sendWelcome(user);
    }
}

// Enqueue
job = new app.jobs.SendWelcomeEmailJob();
job.enqueue(data={userId: user.id});
job.enqueueIn(seconds=300, data={userId: user.id});
job.enqueueAt(runAt=scheduledDate, data={});

// Process and inspect from code
queue = new wheels.Job();
result = queue.processQueue(queue="mailers", limit=10);
stats = queue.queueStats();
```

`UserMailer` is the mailer in `.ai/mailers.md` (`app/mailers/UserMailer.cfc` plus its view). With it and a `users` table that has `email` and `firstName`, this example runs as written.

Enqueueing joins the caller's transaction: `enqueue()` writes its `wheels_jobs` row through the app's datasource, so inside `invokeWithTransaction()` the job commits or rolls back with your data. Enqueue there when the job should run only if the data commits (an outbox); enqueue after the transaction when the work must happen even if it rolls back.

Run jobs with the worker. It needs this app's server running, started with `wheels start`:
```bash
wheels jobs work --queue=mailers --interval=3   # long-lived worker loop; --quiet for less output
wheels jobs work --max-jobs=10                  # stops after 10 processed jobs (it keeps polling until then)
wheels jobs work --stop-when-empty              # exits once no job is ready to run: one-shot batches from cron/CI
wheels jobs work --job-timeout=600              # caps each job at 600s (not --timeout: that stops the worker); without it each job runs with its own this.timeout
wheels jobs status [--queue=mailers] [--format=json]
wheels jobs enqueue SendWelcomeEmailJob --data='{"userId":42}'   # enqueue from the CLI (class under app/jobs/)
wheels jobs enqueue SendWelcomeEmailJob --in=300                 # or --at=2026-10-06T09:00:00Z; a delayed run, not cron
```
The `retry`/`purge`/`monitor` verbs are tracked follow-ups ([#3090](https://github.com/wheels-dev/wheels/issues/3090)). Invoking one errors and prints the programmatic equivalent: `retryFailed(queue=...)` or `purgeCompleted(days=7, queue=...)` on a `wheels.Job` instance.

Retries: `this.maxRetries` counts the retries after the first run, so the default `3` means up to 4 runs. Backoff: `this.baseDelay = 2`, `this.maxDelay = 3600` in `config()`. Formula: `Min(baseDelay * 2^attempt, maxDelay)`. The `wheels_jobs` table is auto-created on first enqueue/processing — no migration needed.

Under a tenant datasource, inside a Wheels-managed transaction (model save, `invokeWithTransaction()`), `enqueue()` returns `{status: "deferred", deferred: true}` and the job is written on commit, dropped on rollback. A raw `transaction {}` isn't tracked. A job that can't be written throws `Wheels.Job.EnqueueFailed`.

For work that must happen even if the transaction rolls back (failure notices, audit records), pass `enqueue(..., transactional=false)` or set `this.transactional = false` in the job's `config()`: the job is written after the outermost Wheels-managed transaction ends, on commit or rollback. Not covered: a raw `transaction {}` (the job shares its fate) and a request that ends with `abort` inside the transaction (the job may not be written; enqueue it outside the transaction instead).
