---
status: skeleton
slot: post 4 (week 2; pairs with ecosystem comparison story)
target_length: 1200–1500 words
---

# Background Jobs Without Redis

**Subhead / dek:** *A production-ready job queue that needs only your database — with a CLI daemon, live monitoring, and tenant awareness built in.*

**Target audience:**
- Rails developers tired of the Redis + Sidekiq + Sidekiq Pro layer cake
- Laravel developers who've priced out Horizon + Redis
- Django developers running Celery + RabbitMQ + Redis for simple email sending
- Wheels teams who've been running cron-driven scripts as a "queue"

**Lead paragraph intent:**
- Every mainstream framework ships a job queue story — and every one of them assumes Redis.
- Wheels 4.0 ships a job queue that assumes only your existing database.
- Optimistic locking, exponential backoff, timeout recovery, CLI daemon, live dashboard.
- And because it's DB-backed, it inherits multi-tenancy for free.

## Sections

### 1. "The Redis tax on small-to-medium apps"
- Redis is a reasonable dependency. It's also a reasonable *extra* dependency — separate process, separate RAM budget, separate failure mode, separate ops doc.
- For a 10k-user SaaS or an internal tool, a queue that lives in the DB you already have is often the right engineering trade.
- Precedent: `delayed_job` (Ruby), `database_cleaner`-style queues, Laravel's database driver. Wheels picks this lane and makes it first-class.

### 2. The Job CFC surface
- Define a job: extend `wheels.Job`, set `this.queue` and `this.maxRetries` in `config()`, put work in `perform(struct data)`.
- Enqueue: `job.enqueue(data={...})`, `job.enqueueIn(seconds=300, data={...})`, `job.enqueueAt(runAt=date, data={...})`.
- Retries: configurable exponential backoff — `this.baseDelay = 2` and `this.maxDelay = 3600`. Formula: `Min(baseDelay * 2^attempt, maxDelay)`.

### 3. The CLI daemon
- `wheels jobs work` — pick up jobs, process, exit on SIGTERM.
- `wheels jobs work --queue=mailers --interval=3` — target a queue, poll every 3s.
- `wheels jobs status` — per-queue breakdown (`pending / processing / completed / failed / total`).
- `wheels jobs retry --queue=mailers` — retry failures.
- `wheels jobs purge --completed --older-than=30` — housekeeping.
- `wheels jobs monitor` — live dashboard.

### 4. What makes the DB-backed implementation work
- **Optimistic locking** so two workers never claim the same job.
- **Timeout recovery** — stuck jobs get requeued.
- **Configurable backoff** — per-job, not framework-wide.
- **Single table (`wheels_jobs`)** — auto-created via migration; inspect with SQL you already know.

### 5. Multi-tenancy for free
- Because tenant switching ([#1951](https://github.com/wheels-dev/wheels/pull/1951)) happens at the datasource layer, jobs enqueued in tenant A land in tenant A's queue.
- No "tenant ID in payload" dance. The worker picks up the job with the tenant context already resolved.
- Tease post #7 (multi-tenancy).

### 6. When to pick Redis anyway
- **Throughput ceiling:** hundreds of thousands of jobs/minute — Redis-based queues (Sidekiq, Oban) will outpace a DB-backed one.
- **Pub/sub fanout:** you want real-time push to N workers with no polling cost.
- **Latency:** sub-50ms pickup matters.
- For most SaaS apps, you're nowhere near those limits.

### 7. Operating the worker in production
- Run under systemd/supervisord; rely on `wheels jobs work` exit codes.
- Log ingestion: stdout is structured; pipe to your log stack.
- Scale horizontally — run multiple workers against the same DB; the optimistic lock handles contention.
- Monitoring: `wheels jobs status --format=json` for your metrics pipeline.

### 8. The SSE channel adjacency (brief)
- While you're wiring background work, know that 4.0 also shipped **pub/sub SSE channels** ([#1940](https://github.com/wheels-dev/wheels/pull/1940)). Jobs complete → publish to an SSE channel → user's browser updates. No websockets required.

## Code / config snippets to include (pick 3)

```cfm
// app/jobs/SendWelcomeEmailJob.cfc
component extends="wheels.Job" {
    function config() {
        super.config();
        this.queue = "mailers";
        this.maxRetries = 5;
        this.baseDelay = 2;
        this.maxDelay = 3600;
    }
    public void function perform(struct data = {}) {
        sendEmail(to=data.email, subject="Welcome!", from="app@example.com");
    }
}
```

```cfm
// Enqueue three ways
job = new app.jobs.SendWelcomeEmailJob();
job.enqueue(data={email: user.email});                     // immediate
job.enqueueIn(seconds=300, data={email: user.email});       // 5 min delay
job.enqueueAt(runAt=reminderDate, data={email: user.email}); // exact time
```

```bash
# Operating the worker
wheels jobs work --queue=mailers --interval=3   # foreground daemon
wheels jobs status                              # quick health check
wheels jobs status --format=json                # for metrics
wheels jobs retry --queue=mailers               # retry failures
wheels jobs purge --completed --older-than=30   # housekeeping
wheels jobs monitor                             # live dashboard
```

## Suggested visuals

- **Architecture diagram:** two stacks side-by-side. Left: "Rails + Sidekiq" with Redis box, Sidekiq worker, scheduler, web. Right: "Wheels 4.0" with the same DB, `wheels jobs work` daemon, web. Visually emphasize the removed Redis box.
- **Screenshot:** `wheels jobs monitor` live dashboard showing a queue working. Even a simulated screenshot tells the story.
- **Simple timeline:** job enqueued → picked up → failed → retry 1 (backoff 2s) → retry 2 (4s) → retry 3 (8s) → exhausted. Teaches the backoff formula visually.

## Outro / CTA

- "Check your production dependency list. If Redis is there only for the job queue, consider the one-less-service version."
- Link to jobs docs in `docs/src/`.
- Tease post #7 (multi-tenancy).

## Citations (must link in final post)

- [Job worker daemon PR #1934](https://github.com/wheels-dev/wheels/pull/1934)
- [Multi-tenancy PR #1951](https://github.com/wheels-dev/wheels/pull/1951)
- [SSE pub/sub channels PR #1940](https://github.com/wheels-dev/wheels/pull/1940)
- [Feature audit § Background jobs](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md#7-background-jobs)
- CLAUDE.md "Background Jobs Quick Reference" section as the canonical API reference
