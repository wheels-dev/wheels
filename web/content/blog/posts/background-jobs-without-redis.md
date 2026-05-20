---
title: Background Jobs Without Redis
slug: background-jobs-without-redis
publishedAt: '2026-05-09T14:00:00.000Z'
updatedAt: '2026-05-07T02:00:09.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - background-jobs
  - multi-tenancy
categories: []
excerpt: >-
  Wheels 4.0 ships a production-ready job queue that needs only your database.
  You get a persistent CLI worker, live monitoring, configurable backoff, and
  tenant-aware enqueueing without any extra services. Redis still wins for
  very high throughput and pub/sub fan-out — this post names where the
  DB-backed queue is the right call and where it is not.
coverImage: null
---

Every non-trivial web app eventually grows a job queue. Welcome emails, report generation, third-party API syncs, thumbnailing, retries that must not block the request — at some point the controller action hands work to something else and returns.

For years the default answer in most framework ecosystems has been "add Redis." And Redis is a reasonable dependency. It is fast, well-understood, operationally boring in the good sense. But it is also an extra one: a separate process, a separate RAM budget, a separate failure mode, a separate line in the ops runbook, a separate thing to back up, a separate thing to patch. For a 10,000-user SaaS or an internal tool that already has a perfectly good relational database, asking the team to stand up and babysit a second data store for the sole purpose of running a few thousand background jobs a day is a real cost.

Wheels 4.0 takes a different position. There is a first-class background job queue, and it lives in your existing database.

## The Redis tax on small-to-medium apps

The case for a database-backed queue is not new. `delayed_job` has been the pragmatic Rails choice for over a decade. Laravel ships a `database` queue driver in the box. The pattern is simple: a table of jobs with columns for payload, run-at time, attempts, and a lock. Workers poll, claim, execute.

What this trades away is throughput. A Redis-backed queue can pop tens of thousands of jobs per second per worker; a database-backed one is bound by row-locking throughput, which is usually a couple of orders of magnitude slower. What this trades for is one less moving part. No new service to stand up. No new credentials to rotate. Transactional semantics with the rest of your application data — you can enqueue a job in the same transaction that creates the record it operates on, and if the transaction rolls back, the job disappears with it.

For the majority of Wheels apps in the wild, the throughput floor of a DB-backed queue is well above their ceiling. The ones that need more know who they are. For everyone else, "one less service" is the right trade.

## The Job CFC surface

Jobs are plain CFCs that extend `wheels.Job`. You declare the queue and retry policy in `config()` and put the actual work in `perform()`.

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

The `config()` contract is the usual Wheels pattern. `this.queue` is the named queue this job runs on — `default` if you do not set it, anything you like if you want to shard work by priority. `this.maxRetries` caps how many times a failed job gets re-attempted before it is marked dead. `this.baseDelay` and `this.maxDelay` control retry backoff: the formula is `Min(baseDelay * 2^attempt, maxDelay)`, so with the defaults above a failed job waits 2, 4, 8, 16, 32 seconds and then ceilings at one hour on later attempts. If you need linear backoff, constant backoff, or something else entirely, override `$calculateBackoff()`.

Enqueueing is three methods on the job instance:

```cfm
// Enqueue three ways
job = new app.jobs.SendWelcomeEmailJob();
job.enqueue(data={email: user.email});
job.enqueueIn(seconds=300, data={email: user.email});
job.enqueueAt(runAt=reminderDate, data={email: user.email});
```

`enqueue()` schedules the job for immediate pickup. `enqueueIn()` defers it by a number of seconds — useful for retry-after-a-cooldown patterns. `enqueueAt()` pins it to a specific datetime — useful for scheduled reminders, subscription expirations, any "run this on Tuesday" case. The `data` struct is the payload; it is serialized into the `wheels_jobs` row and deserialized by the worker.

## The CLI daemon

Enqueued jobs do not run themselves. A worker process picks them up, which in 4.0 is a first-class CLI command:

```bash
# Operating the worker
wheels jobs work --queue=mailers --interval=3
wheels jobs status
wheels jobs status --format=json
wheels jobs retry --queue=mailers
wheels jobs purge --completed --older-than=30
wheels jobs monitor
```

`wheels jobs work` is the daemon. It polls the queue on an interval you control, claims ready jobs, runs them, writes the result back, and moves on. `--queue=mailers` restricts it to a single queue so you can scale shards independently. `--interval=3` sets a three-second poll; the default is one second.

`wheels jobs status` gives you the per-queue breakdown: pending, processing, completed, failed. `--format=json` emits the same view as structured output, which is what you pipe into a log aggregator or a Prometheus exporter.

`wheels jobs retry` re-enqueues failed jobs — useful when the failure was a downstream outage you have now fixed. `wheels jobs purge` garbage-collects old completed and failed rows so the table does not grow unbounded. And `wheels jobs monitor` is a live terminal dashboard for when you want to watch the queue breathe during an incident.

The worker exits cleanly on SIGTERM, which is what any reasonable process supervisor is going to send it. That makes the systemd unit or supervisord config trivial — point it at `wheels jobs work`, let it rip, and let the supervisor restart it if it ever crashes.

## What makes the DB-backed implementation work

The details that matter on a database-backed queue are the ones that prevent two workers from ever running the same job and the ones that make sure a crashed worker does not leave work stuck forever.

Claim is optimistic. A worker reads the next ready job, updates its state to `processing` with a `WHERE state = 'pending'` guard, and checks the affected-row count. If another worker grabbed it first, the count is zero and the first worker moves on. No advisory locks, no external coordinator, no race.

Timeout recovery handles the crash case. Each claimed job records a worker heartbeat; if a job has been in `processing` longer than the configured timeout without a heartbeat update, a sweeper requeues it. A worker that was killed mid-job does not leave its work orphaned — it gets picked up by someone else on the next pass.

Retries are per-job and exponential by default. The `baseDelay`/`maxDelay` values from `config()` feed a backoff formula that spaces out attempts. A flapping downstream does not stampede. When the retry budget is exhausted, the job is marked `failed` and sits there until you decide what to do — retry manually, dig into the payload, or purge.

The whole thing runs on one table: `wheels_jobs`. It is auto-created on first enqueue or first processing run by `Job.cfc::$ensureJobTable()`. No migration file to ship; the table appears when you need it.

## Multi-tenancy without the payload ceremony

This is where the design really pays off. Wheels 4.0's [tenant-aware datasource switching](https://github.com/wheels-dev/wheels/pull/1951) resolves the active tenant at the request layer. When a request for tenant A enqueues a job, the job row is written against tenant A's database connection — which is to say, in most multi-tenant configurations, into tenant A's physical database or tenant A's logical schema.

When the worker picks the job up, the tenant context is resolved from the datasource the worker is pointed at. You do not stuff tenant IDs into the payload. You do not write a tenant-aware job base class. You do not train your team to remember which jobs need tenant scoping and which do not.

If you run a pool-per-tenant setup — one worker per tenant database — jobs route themselves naturally. If you run a shared-pool setup with tenant-resolved datasources, enqueueing in the request context and dequeueing in the worker context just works because the datasource resolution logic is the same in both places. You get tenant-aware jobs without ceremony.

For anyone who has shipped multi-tenant job queues before and lived with the "did I remember to set `tenant_id`?" bug class, this is a quiet but significant quality-of-life win.

## When to pick Redis anyway

It would be dishonest to pretend a DB-backed queue is the right answer for every workload. It is not.

If you are pushing hundreds of thousands of jobs per minute through a single queue, Redis wins. The polling overhead and row-lock contention on a relational table eventually become the bottleneck; Redis's in-memory list and stream operations do not. If your workload is "the e-commerce site that has a flash sale at 9am Pacific," do the math before committing.

If you need pub/sub fan-out — one event that lights up N workers simultaneously — Redis's native pub/sub is built for it. A DB-backed queue can approximate this with polling, but approximate is the key word.

If you need sub-50ms job pickup latency — real-time pipelines, trading systems, interactive notification delivery — a one-second polling interval is not going to cut it, and pushing the interval down to 100ms puts a lot of pressure on your DB. Redis pub/sub is designed for this shape.

Most SaaS apps are nowhere near these limits. If your current Redis instance is serving the queue and nothing else, and your queue depth rarely exceeds a few thousand, you are paying Redis taxes for capacity you will not use this decade.

## Operating the worker in production

Running `wheels jobs work` under a supervisor is the standard shape. systemd is the most common choice on modern Linux — one unit file, `ExecStart=/usr/local/bin/wheels jobs work --queue=default`, `Restart=always`, done. supervisord works equivalently. Container orchestrators (Nomad, Kubernetes deployments, plain Docker Compose with `restart: unless-stopped`) handle it the same way.

Logging is plain stdout. Pipe it to your log stack — journald, Loki, Elasticsearch, whatever you already run. Jobs that throw surface as structured error lines with the job ID, the queue, the attempt count, and the exception message.

Horizontal scaling is a matter of starting more worker processes — same command, same database, different hosts if you want. The optimistic-lock claim handles contention; there is no coordinator to configure. If you need to grow from one worker to ten, the command does not change; you just run it in ten places.

Monitoring hooks into the status surface. `wheels jobs status --format=json` gives you a consumable snapshot; run it from a cron or a Prometheus textfile exporter and alert on `failed > 0` or `pending > 1000` or whatever thresholds match your business.

## The SSE adjacency

One last note for anyone building interactive apps on top of the queue. Wheels 4.0 also shipped [pub/sub SSE channels](https://github.com/wheels-dev/wheels/pull/1940), which means a completed job can publish to a channel and every connected browser gets the update. No websocket server, no Pusher account, no third-party dependency. The combination — DB-backed queue plus SSE pub/sub — covers a large slice of what you would previously have needed Redis plus a websocket gateway for.

## Where to go next

Check your production dependency list. If Redis is in your stack only for the job queue, consider the one-less-service version. The framework now has an opinion about this layer, and the opinion is that for most apps, your database is already a perfectly good place to keep a queue.

- [Background jobs guide](https://guides.wheels.dev/v4-0-0/digging-deeper/background-jobs/) — job definition, enqueueing, retries, worker operation.
- [Multi-tenancy guide](https://guides.wheels.dev/v4-0-0/digging-deeper/multi-tenancy/) — how tenant-aware datasource switching interacts with jobs and the rest of the request lifecycle.
- [SSE guide](https://guides.wheels.dev/v4-0-0/digging-deeper/server-sent-events/) — pub/sub channels, push from job completion to browser.

If you are currently running Wheels with an external queue service and think the DB-backed path might be a fit, we would love to hear how the migration goes. The surface is new, the edges are still being polished, and the feedback from the first wave of adopters is what shapes the 4.0.x series.

