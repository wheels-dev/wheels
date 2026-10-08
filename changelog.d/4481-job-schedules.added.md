- Recurring background jobs.
  - **Defining schedules.** Define schedules in `config/schedules.cfm`:
    - `schedule("digest").job("DigestJob").cron("0 7 * * MON").timezone("America/New_York")`
    - `schedule("canary").job("CanaryJob").every(15, "minutes")`

    They are synced to a new `wheels_job_schedules` table at application start. Apps can also insert their own rows at runtime (e.g. from an admin page); the sync never changes those, and a code schedule removed from the file is disabled, not deleted.
  - **Running them.** Call `new wheels.JobScheduler().enqueueDue()` regularly on one or every server. Each due slot is enqueued once, with `uniqueKey = "<schedule>:<slot time, UTC>"`, however many servers call it.
  - **Expressions.** Cron takes the standard 5 fields with lists, ranges, steps and month and day names, the `@hourly` to `@yearly` aliases, and an IANA time zone. A local time skipped by a DST change runs at the next valid instant, and a repeated one runs once. Intervals are minutes or hours, aligned to UTC.
  - **Missed slots.** `catchUp("latest")` (default) runs only the newest missed slot within `catchUpWindow()` (default 3600 seconds); `catchUp("none")` runs only a current one. A slot never runs twice.

  ([#4481](https://github.com/wheels-dev/wheels/issues/4481))
