/**
 * Job Worker engine for the Wheels background job system.
 * Provides single-job claiming with optimistic locking, timeout recovery,
 * queue statistics, monitoring, and management operations.
 *
 * Used by CLI commands (wheels jobs work/status/retry/purge/monitor)
 * and the CLI bridge to process jobs from the wheels_jobs table.
 */
component {

	/**
	 * Constructor — generates a unique worker ID.
	 */
	public function init() {
		this.workerId = CreateUUID();
		this.startedAt = Now();
		this.jobsProcessed = 0;
		this.jobsFailed = 0;
		// Runs that finished after their exclusive lease had expired and been taken over.
		this.leasesLost = 0;
		// Per-job timeouts (processQueue): when true, each candidate is claimed and run with its
		// own job class's timeout (capped by timeoutCap when that is > 0) instead of this poll's.
		this.perJobTimeout = false;
		this.timeoutCap = 0;
		// Reap window floor for rows that recorded no claimTimeout (claimed before the column
		// existed): such a row is reaped at Max(this poll's timeout, legacyReapTimeout), so a
		// small processQueue timeout cap can't reap a still-running older job early.
		this.legacyReapTimeout = 0;
		// Per-host concurrency cap for this worker's polls: -1 = use set(jobsMaxConcurrentPerHost),
		// 0 = none, n = at most n jobs running on this host at once (JobRunner.tick sets it).
		this.maxConcurrentPerHost = -1;
		variables.$datasource = "";
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "dataSourceName")) {
			variables.$datasource = application.wheels.dataSourceName;
		}
		return this;
	}

	/**
	 * Claim and process the next available job using optimistic locking.
	 * Returns a struct with success, jobId, jobClass, and error keys.
	 *
	 * @queues Comma-delimited list of queue names to process. Empty = all queues.
	 * @timeout Timeout in seconds for a single job execution.
	 */
	public struct function processNext(string queues = "", numeric timeout = 300) {
		local.result = {success = false, jobId = "", jobClass = "", error = "", skipped = false, fenced = false, capped = false, draining = false, deferred = false, leaseLost = false};

		// Ensure the table (and the claimTimeout column) on the normal path, so an existing
		// install gets the column once per worker rather than only when a query happens to
		// fail. The per-instance $tableVerified cache makes this run the probe+ALTER exactly
		// once per worker — re-run by each new worker, so it's not a persisted flag (#2780).
		$ensureJobTable();

		// Recover jobs left in 'processing' by a crashed/killed worker before claiming:
		// the candidate SELECT below only ever considers status='pending', so without
		// this a row stuck in 'processing' would never be picked up again (#3888). A job
		// idle past the grace window is either a crashed worker or one that blew its
		// execution timeout; checkTimeouts requeues it for retry (counting the attempt) or
		// marks it failed when retries are exhausted. Scoped to the queues this poll serves
		// so we never reap another worker's live job on a queue we don't process. Cheap when
		// nothing is stuck.
		this.checkTimeouts(timeout = arguments.timeout, queues = arguments.queues);

		// Keep schedules running from the same poll (throttled to jobsScheduleCheckSeconds).
		$jobBridge().$enqueueDueSchedules();

		// A draining host starts nothing new (in-flight jobs finish; the reap above still runs).
		local.host = $jobBridge().$jobHostName();
		if ($jobBridge().$hostDraining(local.host)) {
			local.result.skipped = true;
			local.result.draining = true;
			return local.result;
		}

		// Find the next candidate job
		local.params = {
			runAt = {value = $now(), cfsqltype = "cf_sql_timestamp"}
		};

		// The candidate SELECT deliberately excludes the data column: at backlog scale
		// dragging every pending row's payload across the wire per poll is expensive.
		// The claimed job's payload is fetched by id after the claim succeeds.
		local.sql = "SELECT id, jobClass, queue, attempts, maxRetries
			FROM wheels_jobs
			WHERE status = 'pending' AND runAt <= :runAt";

		if (Len(arguments.queues)) {
			local.queueList = ListToArray(arguments.queues);
			local.queueConditions = [];
			for (local.i = 1; local.i <= ArrayLen(local.queueList); local.i++) {
				local.paramName = "queue#local.i#";
				ArrayAppend(local.queueConditions, ":queue#local.i#");
				local.params[local.paramName] = {value = Trim(local.queueList[local.i]), cfsqltype = "cf_sql_varchar"};
			}
			local.sql &= " AND queue IN (#ArrayToList(local.queueConditions)#)";
		}

		local.sql &= " ORDER BY priority DESC, runAt ASC";

		// Bound the candidate scan in SQL text so the database never materializes the
		// whole pending backlog. A handful of candidates is enough — the loop below
		// claims the first one it wins and the rest only matter when claims are lost
		// to concurrent workers.
		// NOTE: Avoid the maxrows option — BoxLang + PostgreSQL throws when setMaxRows()
		// is called on the JDBC PreparedStatement with certain parameter combinations,
		// and maxrows only truncates client-side after the driver fetched everything.
		local.candidateLimit = 25;
		local.dbType = $dbType();
		local.sql &= $candidateLimitClause(dbType = local.dbType, candidateLimit = local.candidateLimit);

		try {
			local.candidates = queryExecute(local.sql, local.params, {datasource = variables.$datasource});
		} catch (any e) {
			$ensureJobTable();
			try {
				local.candidates = queryExecute(local.sql, local.params, {datasource = variables.$datasource});
			} catch (any e2) {
				local.result.skipped = true;
				local.result.error = e2.message;
				return local.result;
			}
		}

		if (!local.candidates.recordCount) {
			local.result.skipped = true;
			return local.result;
		}

		// Claim one candidate. With a per-host cap, counting this host's running jobs and claiming
		// happen under one exclusive lock per host, so two polls on this server can't both take
		// the last free slot; the job itself runs outside the lock. Servers sharing a host name
		// share the cap but not the lock: give each its own jobsHostName.
		local.cap = $hostCap();
		if (local.cap > 0) {
			local.claim = {claimed = false, capped = true, error = "", row = {}};
			lock name="wheels.jobs.host.#local.host#" type="exclusive" timeout="10" throwOnTimeout="false" {
				if ($jobBridge().$runningOnHost(local.host) < local.cap) {
					local.claim = $claimFirstCandidate(candidates = local.candidates, timeout = arguments.timeout);
				}
			}
		} else {
			local.claim = $claimFirstCandidate(candidates = local.candidates, timeout = arguments.timeout);
		}
		if (local.claim.capped) {
			local.result.skipped = true;
			local.result.capped = true;
			return local.result;
		}
		if (Len(local.claim.error)) {
			// Persist/claim errors are contained — they must not look like an idle skip.
			local.result.skipped = false;
			local.result.success = false;
			local.result.jobId = local.claim.row.id;
			local.result.jobClass = local.claim.row.jobClass;
			local.result.error = local.claim.error;
			return local.result;
		}
		if (local.claim.claimed) {
			return $runClaimedJob(row = local.claim.row, timeout = arguments.timeout, result = local.result);
		}

		// All candidates were claimed by other workers
		local.result.skipped = true;
		return local.result;
	}

	/**
	 * Try each candidate in turn with the optimistic claim until one is won. Returns
	 * `{claimed, capped, error, row}`; a persist/claim error stops at that row.
	 */
	private struct function $claimFirstCandidate(required query candidates, numeric timeout = 300) {
		var outcome = {claimed = false, capped = false, error = "", row = {}};
		for (local.row in arguments.candidates) {
			// Resolved before the claim so the claim itself records the right claimTimeout (the
			// reap window) and the job runs with the same value.
			local.jobTimeout = $claimTimeoutFor(jobClass = local.row.jobClass, pollTimeout = arguments.timeout);
			try {
				local.claimFn = this["$claimJob"];
				local.won = local.claimFn(local.row.id, local.jobTimeout);
			} catch (any e) {
				outcome.error = Left(e.message, 1000);
				outcome.row = {id = local.row.id, jobClass = local.row.jobClass};
				return outcome;
			}
			if (local.won) {
				outcome.claimed = true;
				outcome.row = {
					id = local.row.id,
					jobClass = local.row.jobClass,
					queue = local.row.queue,
					attempts = local.row.attempts,
					maxRetries = local.row.maxRetries,
					timeout = local.jobTimeout
				};
				return outcome;
			}
		}
		return outcome;
	}

	/**
	 * Run a job this worker claimed and record its outcome in `result`: completed, retried or
	 * failed — or fenced, when its claim was reaped and re-issued while it ran.
	 */
	private struct function $runClaimedJob(required struct row, required numeric timeout, required struct result) {
		local.jobRow = {
			id = arguments.row.id,
			jobClass = arguments.row.jobClass,
			queue = arguments.row.queue,
			data = $fetchJobData(arguments.row.id),
			attempts = arguments.row.attempts,
			maxRetries = arguments.row.maxRetries,
			claimToken = $takeClaimToken(arguments.row.id)
		};
		// The timeout the claim recorded (the job's own, with per-job timeouts), else this poll's.
		local.jobTimeout = StructKeyExists(arguments.row, "timeout") ? arguments.row.timeout : arguments.timeout;
		local.processResult = $executeJob(jobRow = local.jobRow, timeout = local.jobTimeout);
		arguments.result.jobId = arguments.row.id;
		arguments.result.jobClass = arguments.row.jobClass;
		if (local.processResult.leaseLost) {
			this.leasesLost++;
			arguments.result.leaseLost = true;
		}

		if (local.processResult.busy) {
			// Another run holds the job's lease: it waits without using up an attempt.
			$jobBridge().$deferJobForLease(
				jobId = arguments.row.id,
				jobClass = arguments.row.jobClass,
				claimToken = local.jobRow.claimToken,
				delaySeconds = local.processResult.retryInSeconds,
				leaseName = local.processResult.leaseName
			);
			arguments.result.skipped = true;
			arguments.result.deferred = true;
			return arguments.result;
		}
		if (local.processResult.fenced) {
			// Ran, but the claim was reaped and re-issued while it did: the completion
			// was rejected, and retrying it would requeue the attempt that replaced it.
			arguments.result.fenced = true;
			arguments.result.error = local.processResult.error;
			return arguments.result;
		}
		if (local.processResult.success) {
			this.jobsProcessed++;
			arguments.result.success = true;
			return arguments.result;
		}
		this.jobsFailed++;
		arguments.result.error = local.processResult.error;
		arguments.result.fenced = $recordFailedAttempt(jobRow = local.jobRow, processResult = local.processResult);
		return arguments.result;
	}

	/**
	 * This worker's per-host cap: maxConcurrentPerHost when the caller set it (JobRunner.tick),
	 * else set(jobsMaxConcurrentPerHost = n). 0 = no cap.
	 */
	private numeric function $hostCap() {
		if (IsNumeric(this.maxConcurrentPerHost) && this.maxConcurrentPerHost >= 0) {
			return Int(this.maxConcurrentPerHost);
		}
		return $jobBridge().$jobsMaxConcurrentPerHost();
	}

	/**
	 * Recover jobs stuck in 'processing' status that have exceeded their timeout.
	 * @timeout Seconds after which a processing job is considered timed out. Default 300.
	 */
	public numeric function checkTimeouts(numeric timeout = 300, string queues = "") {
		// Normalise a blank/<=0 timeout to the default exactly as $executeJob does, so a
		// bridge call with timeout=0 (or blank) doesn't collapse the grace window to 60s
		// and reap jobs that are still legitimately running (#3984 review).
		local.timeout = Val(arguments.timeout);
		if (local.timeout <= 0) {
			local.timeout = 300;
		}

		// Grace margin: a row is only reapable once it has been idle past
		// claimTimeout + max(60s, claimTimeout), where claimTimeout is the timeout the
		// OWNING worker recorded when it claimed the job (#3989) — so a worker with a short
		// timeout can't reap a job still running under a longer-timeout worker, even across
		// queues. The real per-row grace is applied in the loop; here we bound the scan with
		// a floor cutoff of 60s, since max(60s, …) makes the smallest possible grace ~60s so
		// a row idle 60s or less can never be reapable. Rows with no claimTimeout (pre-#3989
		// or an ALTER-blocked table) fall back to this poller's own timeout.
		local.floorCutoff = DateAdd("s", -60, $now());

		local.params = {cutoff = {value = local.floorCutoff, cfsqltype = "cf_sql_timestamp"}};

		// Scope the reap to the queues this poll serves. A blank "queues" reaps across all
		// queues (the standalone jobsMonitor path); processNext passes its own queue set so
		// one worker can't reap another worker's live jobs on a queue it doesn't serve.
		local.queueFilter = "";
		if (Len(Trim(arguments.queues))) {
			local.queueList = ListToArray(arguments.queues);
			local.placeholders = [];
			for (local.qi = 1; local.qi <= ArrayLen(local.queueList); local.qi++) {
				local.pName = "reapQueue#local.qi#";
				ArrayAppend(local.placeholders, ":" & local.pName);
				local.params[local.pName] = {value = Trim(local.queueList[local.qi]), cfsqltype = "cf_sql_varchar"};
			}
			local.queueFilter = " AND queue IN (" & ArrayToList(local.placeholders) & ")";
		}

		// Find candidate rows idle past the floor; the SELECT prefers claimTimeout and falls
		// back without it when the column is absent.
		// A job is alive as of its latest heartbeat, or its claim when it never heartbeat.
		local.whereClause = "WHERE status = 'processing' AND " & $lastSeenSql() & " < :cutoff" & local.queueFilter;
		try {
			local.timedOut = $selectStaleCandidates(whereClause = local.whereClause, params = local.params);
		} catch (any e) {
			$ensureJobTable();
			return 0;
		}

		local.now = $now();
		local.recovered = 0;
		for (local.row in local.timedOut) {
			// Per-row reap window from the OWNER's recorded timeout (claimTimeout), falling back
			// to this poller's timeout when the row has none. rowCutoff is the "idle past its own
			// grace" boundary; the staleness test itself runs SQL-side inside the requeue UPDATE
			// (AND updatedAt < :staleCutoff), so we never diff a query timestamp in CFML (#3989).
			local.rowTimeout = Max(local.timeout, Val(this.legacyReapTimeout));
			if (StructKeyExists(local.row, "claimTimeout") && IsNumeric(local.row.claimTimeout) && Val(local.row.claimTimeout) > 0) {
				local.rowTimeout = Val(local.row.claimTimeout);
			}
			local.grace = local.rowTimeout + Max(60, local.rowTimeout);
			local.rowCutoff = DateAdd("s", -local.grace, local.now);

			local.currentAttempts = Val(local.row.attempts);
			local.maxRetries = Val(local.row.maxRetries);

			// Optimistic requeue guarded by (a) the attempts value we just read — every $claimJob
			// bumps attempts, so a finish or re-claim between SELECT and UPDATE matches 0 rows —
			// and (b) the per-row staleness cutoff, so a row still inside its own window is left
			// alone. Two concurrent reapers race on the same guard; exactly one wins.
			if (!$jobIsIdempotent(local.row.jobClass)) {
				// this.idempotent = false: never run it a second time. The reaped attempt may have
				// done some or all of its work, so it ends 'interrupted' instead of being retried.
				local.won = $markInterrupted(
					jobId = local.row.id,
					jobClass = local.row.jobClass,
					errorMessage = "Job timed out after #local.rowTimeout# seconds and is not idempotent, so it was not retried",
					expectedAttempts = local.currentAttempts,
					staleCutoff = local.rowCutoff
				);
				// Interrupted is final: it is never run again.
				if (local.won > 0) {
					$fireReapedFailure(
						row = local.row,
						message = "Job timed out after #local.rowTimeout# seconds and is not idempotent, so it was not retried"
					);
				}
			} else if (local.currentAttempts <= local.maxRetries) {
				// Reschedule for retry
				local.won = $scheduleRetry(local.row.id, local.currentAttempts, local.row.jobClass, local.maxRetries, "Job timed out after #local.rowTimeout# seconds", local.currentAttempts, local.rowCutoff);
			} else {
				// Exhausted retries
				local.won = $markFailed(local.row.id, local.row.jobClass, local.maxRetries, "Job timed out after #local.rowTimeout# seconds (max retries exhausted)", local.currentAttempts, local.rowCutoff);
				if (local.won > 0) {
					$fireReapedFailure(row = local.row, message = "Job timed out after #local.rowTimeout# seconds (max retries exhausted)");
				}
			}
			if (local.won > 0) {
				local.recovered++;
			}
		}

		return local.recovered;
	}

	/**
	 * SELECT the stale-processing candidates, preferring the claimTimeout column and retrying
	 * without it when the column is absent (an ALTER-blocked or pre-#3989 table). On the
	 * fallback path the rows carry no claimTimeout, so checkTimeouts uses the poller's timeout.
	 */
	private query function $selectStaleCandidates(required string whereClause, required struct params) {
		// Pick the SELECT variant from the per-worker memo so a column-less install doesn't pay
		// a failing SELECT every poll; the catch is a safety net if the memo is stale.
		if ($claimTimeoutColumnAvailable()) {
			try {
				return queryExecute(
					"SELECT id, jobClass, queue, attempts, maxRetries, updatedAt, claimTimeout
					FROM wheels_jobs " & arguments.whereClause,
					arguments.params,
					{datasource = variables.$datasource}
				);
			} catch (any e) {
				variables.$claimTimeoutColumnPresent = false;
			}
		}
		return queryExecute(
			"SELECT id, jobClass, queue, attempts, maxRetries, updatedAt
			FROM wheels_jobs " & arguments.whereClause,
			arguments.params,
			{datasource = variables.$datasource}
		);
	}

	/**
	 * Get queue statistics with per-queue breakdown.
	 * @queue Optional queue name to filter by. Empty = all queues.
	 */
	public struct function getStats(string queue = "") {
		local.result = {
			queues = {},
			totals = {pending = 0, processing = 0, completed = 0, failed = 0, interrupted = 0, total = 0}
		};

		try {
			local.sql = "SELECT queue, status, COUNT(*) as cnt FROM wheels_jobs";
			local.params = {};

			if (Len(arguments.queue)) {
				local.sql &= " WHERE queue = :queue";
				local.params.queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"};
			}

			local.sql &= " GROUP BY queue, status ORDER BY queue, status";
			local.rows = queryExecute(local.sql, local.params, {datasource = variables.$datasource});
		} catch (any e) {
			$ensureJobTable();
			return local.result;
		}

		for (local.row in local.rows) {
			if (!StructKeyExists(local.result.queues, local.row.queue)) {
				local.result.queues[local.row.queue] = {pending = 0, processing = 0, completed = 0, failed = 0, interrupted = 0, total = 0};
			}
			if (StructKeyExists(local.result.queues[local.row.queue], local.row.status)) {
				local.result.queues[local.row.queue][local.row.status] = local.row.cnt;
			}
			local.result.queues[local.row.queue].total += local.row.cnt;

			if (StructKeyExists(local.result.totals, local.row.status)) {
				local.result.totals[local.row.status] += local.row.cnt;
			}
			local.result.totals.total += local.row.cnt;
		}

		return local.result;
	}

	/**
	 * Get monitoring data: throughput metrics, recent jobs, error rates.
	 * @queue Optional queue filter.
	 * @minutes Lookback window in minutes. Default 60.
	 */
	public struct function getMonitorData(string queue = "", numeric minutes = 60) {
		local.result = {
			throughput = {completed = 0, failed = 0, avgDuration = 0},
			recentJobs = [],
			errorRate = 0,
			oldestPending = "",
			worker = {id = this.workerId, startedAt = this.startedAt, processed = this.jobsProcessed, failed = this.jobsFailed}
		};

		local.lookback = DateAdd("n", -arguments.minutes, $now());
		local.params = {lookback = {value = local.lookback, cfsqltype = "cf_sql_timestamp"}};

		// Throughput — completed and failed in the window
		try {
			local.sql = "SELECT status, COUNT(*) as cnt FROM wheels_jobs
				WHERE updatedAt >= :lookback AND status IN ('completed', 'failed')";
			if (Len(arguments.queue)) {
				local.sql &= " AND queue = :queue";
				local.params.queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"};
			}
			local.sql &= " GROUP BY status";
			local.throughputRows = queryExecute(local.sql, local.params, {datasource = variables.$datasource});

			for (local.row in local.throughputRows) {
				if (local.row.status == "completed") local.result.throughput.completed = local.row.cnt;
				if (local.row.status == "failed") local.result.throughput.failed = local.row.cnt;
			}

			local.totalFinished = local.result.throughput.completed + local.result.throughput.failed;
			if (local.totalFinished > 0) {
				local.result.errorRate = Round((local.result.throughput.failed / local.totalFinished) * 100 * 100) / 100;
			}
		} catch (any e) {
			// Table may not exist yet
		}

		// Recent jobs
		try {
			local.recentSql = "SELECT id, jobClass, queue, status, attempts, lastError, updatedAt
				FROM wheels_jobs";
			local.recentParams = {};
			if (Len(arguments.queue)) {
				local.recentSql &= " WHERE queue = :queue";
				local.recentParams.queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"};
			}
			local.recentSql &= " ORDER BY updatedAt DESC";
			// Bound in SQL text via the dialect clause, not the driver maxrows
			// option: BoxLang's JDBC layer calls setLargeMaxRows(), which the
			// PostgreSQL driver does not implement ("is not yet implemented") —
			// the query throws and the catch below returned an empty
			// recentJobs. The CFML break is a belt-and-braces backstop.
			local.recentSql &= $candidateLimitClause(dbType = $dbType(), candidateLimit = 10);
			local.recentRows = queryExecute(local.recentSql, local.recentParams, {datasource = variables.$datasource});

			for (local.row in local.recentRows) {
				if (ArrayLen(local.result.recentJobs) >= 10) {
					break;
				}
				ArrayAppend(local.result.recentJobs, {
					id = local.row.id,
					jobClass = local.row.jobClass,
					queue = local.row.queue,
					status = local.row.status,
					attempts = local.row.attempts,
					lastError = local.row.lastError ?: "",
					updatedAt = local.row.updatedAt
				});
			}
		} catch (any e) {
			// Ignore
		}

		// Oldest pending job
		try {
			local.oldestSql = "SELECT createdAt FROM wheels_jobs WHERE status = 'pending'";
			local.oldestParams = {};
			if (Len(arguments.queue)) {
				local.oldestSql &= " AND queue = :queue";
				local.oldestParams.queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"};
			}
			local.oldestSql &= " ORDER BY createdAt ASC";
			// Bound in SQL text (see the recentJobs note on driver maxrows) —
			// the ORDER BY puts the oldest pending row first.
			local.oldestSql &= $candidateLimitClause(dbType = $dbType(), candidateLimit = 1);
			local.oldestRow = queryExecute(local.oldestSql, local.oldestParams, {datasource = variables.$datasource});
			if (local.oldestRow.recordCount) {
				// This reads through a raw queryExecute, so the Wheels adapter's
				// date canonicalization never runs. The shapes the drivers hand
				// back vary: epoch-millis longs (Adobe + sqlite-jdbc), real date
				// objects, fractional-second strings, and Oracle's
				// oracle.sql.TIMESTAMP (which is not a java.util.Date, #3649).
				// This component is standalone (no Global mixin), so reach the
				// shared normalizer through the application object and keep the
				// old epoch-milliseconds conversion as the fallback.
				local.normalized = "";
				try {
					local.normalized = application.wo.$normalizeDbTimestamp(local.oldestRow.createdAt);
				} catch (any e) {
					local.normalized = IsNumeric(local.oldestRow.createdAt)
						? DateAdd("s", Int(local.oldestRow.createdAt / 1000), CreateDate(1970, 1, 1))
						: local.oldestRow.createdAt;
				}
				local.result.oldestPending = IsDate(local.normalized)
					? local.normalized
					: local.oldestRow.createdAt;
			}
		} catch (any e) {
			// Ignore
		}

		return local.result;
	}

	/**
	 * Reset failed jobs to pending for retry.
	 * @queue Optional queue filter.
	 * @limit Maximum number of jobs to retry. 0 = unlimited.
	 */
	public numeric function retryFailed(string queue = "", numeric limit = 0) {
		local.now = $now();

		// If limit specified, get the IDs first
		if (arguments.limit > 0) {
			try {
				local.selectSql = "SELECT id FROM wheels_jobs WHERE status = 'failed'";
				local.selectParams = {};
				if (Len(arguments.queue)) {
					local.selectSql &= " AND queue = :queue";
					local.selectParams.queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"};
				}
				local.selectSql &= " ORDER BY failedAt ASC";
				// Bound in SQL text (BoxLang + PostgreSQL throws on the driver
				// maxrows option — setLargeMaxRows is not implemented).
				local.selectSql &= $candidateLimitClause(dbType = $dbType(), candidateLimit = arguments.limit);
				local.failedJobs = queryExecute(local.selectSql, local.selectParams, {datasource = variables.$datasource});

				if (!local.failedJobs.recordCount) return 0;

				local.ids = ValueList(local.failedJobs.id);
				local.idConditions = [];
				local.updateParams = {
					runAt = {value = local.now, cfsqltype = "cf_sql_timestamp"},
					updatedAt = {value = local.now, cfsqltype = "cf_sql_timestamp"}
				};
				local.i = 0;
				for (local.id in ListToArray(local.ids)) {
					local.i++;
					local.paramName = "id#local.i#";
					ArrayAppend(local.idConditions, ":#local.paramName#");
					local.updateParams[local.paramName] = {value = local.id, cfsqltype = "cf_sql_varchar"};
				}

				local.updateSql = "UPDATE wheels_jobs
					SET status = 'pending', attempts = 0, lastError = NULL, failedAt = NULL,
						runAt = :runAt, updatedAt = :updatedAt
					WHERE id IN (#ArrayToList(local.idConditions)#)";

				queryExecute(local.updateSql, local.updateParams, {datasource = variables.$datasource});
				return local.failedJobs.recordCount;
			} catch (any e) {
				$ensureJobTable();
				return 0;
			}
		}

		// No limit — update all
		local.sql = "UPDATE wheels_jobs
			SET status = 'pending', attempts = 0, lastError = NULL, failedAt = NULL,
				runAt = :runAt, updatedAt = :updatedAt
			WHERE status = 'failed'";
		local.params = {
			runAt = {value = local.now, cfsqltype = "cf_sql_timestamp"},
			updatedAt = {value = local.now, cfsqltype = "cf_sql_timestamp"}
		};

		if (Len(arguments.queue)) {
			local.sql &= " AND queue = :queue";
			local.params.queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"};
		}

		try {
			// DML recordCount is unreliable across CFML engines; count the rows we are
			// about to reset BEFORE the UPDATE. Counting status='pending' afterwards
			// would also include unrelated jobs that were already pending.
			local.countSql = "SELECT COUNT(*) AS cnt FROM wheels_jobs WHERE status = 'failed'";
			local.countParams = {};
			if (Len(arguments.queue)) {
				local.countSql &= " AND queue = :queue";
				local.countParams.queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"};
			}
			local.countResult = queryExecute(local.countSql, local.countParams, {datasource = variables.$datasource});

			queryExecute(local.sql, local.params, {datasource = variables.$datasource});
			return local.countResult.cnt ?: 0;
		} catch (any e) {
			$ensureJobTable();
			return 0;
		}
	}

	/**
	 * Purge jobs by status and age.
	 * @status Job status to purge: "completed" or "failed".
	 * @days Delete jobs older than this many days.
	 * @queue Optional queue filter.
	 */
	public numeric function purge(required string status, numeric days = 7, string queue = "") {
		if (!ListFindNoCase("completed,failed,interrupted", arguments.status)) {
			throw(type = "Wheels.InvalidArgument", message = "Purge status must be 'completed', 'failed' or 'interrupted'.");
		}

		local.cutoff = DateAdd("d", -arguments.days, $now());
		local.dateColumn = (arguments.status == "completed") ? "completedAt" : "failedAt";

		local.sql = "DELETE FROM wheels_jobs WHERE status = :status AND #local.dateColumn# < :cutoff";
		local.params = {
			status = {value = arguments.status, cfsqltype = "cf_sql_varchar"},
			cutoff = {value = local.cutoff, cfsqltype = "cf_sql_timestamp"}
		};

		if (Len(arguments.queue)) {
			local.sql &= " AND queue = :queue";
			local.params.queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"};
		}

		try {
			local.countSql = "SELECT COUNT(*) AS cnt FROM wheels_jobs WHERE status = :status AND #local.dateColumn# < :cutoff";
			local.countParams = {
				status = {value = arguments.status, cfsqltype = "cf_sql_varchar"},
				cutoff = {value = local.cutoff, cfsqltype = "cf_sql_timestamp"}
			};
			if (Len(arguments.queue)) {
				local.countSql &= " AND queue = :queue";
				local.countParams.queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"};
			}
			local.countResult = queryExecute(local.countSql, local.countParams, {datasource = variables.$datasource});
			local.cnt = local.countResult.cnt ?: 0;
			if (local.cnt <= 0) {
				return 0;
			}
			queryExecute(local.sql, local.params, {datasource = variables.$datasource});
			return local.cnt;
		} catch (any e) {
			$ensureJobTable();
			return 0;
		}
	}

	// ── Private Methods ──────────────────────────────────────────────

	/**
	 * Claim a job using optimistic locking.
	 * Returns true if this worker successfully claimed the job.
	 * A lost race (0 rows) returns false. A persist/query error is not a lost
	 * race — it throws Wheels.JobClaimFailed so processNext can contain it
	 * without disguising the failure as an idle skip.
	 */
	public boolean function $claimJob(required string jobId, numeric timeout = 300) {
		// Record the claiming worker's timeout on the row so the stale-job reaper can reap on
		// THIS worker's timeout rather than the polling worker's (#3989). Normalise a
		// blank/<=0 timeout to the default exactly as checkTimeouts/$executeJob do.
		local.claimTimeout = Val(arguments.timeout);
		if (local.claimTimeout <= 0) {
			local.claimTimeout = 300;
		}
		// Pick the query variant from the per-worker memos so a column-less install doesn't pay
		// a failing UPDATE on every claim; keep a re-probe-and-retry only as a safety net.
		local.withColumn = $claimTimeoutColumnAvailable();
		local.withToken = $claimTokenColumnAvailable();
		try {
			return $claimJobUpdate(jobId = arguments.jobId, claimTimeout = local.claimTimeout, withClaimTimeout = local.withColumn, withClaimToken = local.withToken);
		} catch (any e) {
			// A memo was wrong (e.g. a column was added or dropped mid-worker). Re-probe both and
			// retry once with what the table really has, so claiming never breaks; a genuine
			// failure rethrows.
			try {
				variables.$claimTimeoutColumnPresent = $jobBridge().$jobTableHasClaimTimeout();
				variables.$claimTokenColumnPresent = $jobBridge().$jobTableHasClaimToken();
				variables.$heartbeatColumnPresent = $jobBridge().$jobTableHasColumn("heartbeatAt");
				return $claimJobUpdate(
					jobId = arguments.jobId,
					claimTimeout = local.claimTimeout,
					withClaimTimeout = variables.$claimTimeoutColumnPresent,
					withClaimToken = variables.$claimTokenColumnPresent
				);
			} catch (any e2) {
				throw(
					type = "Wheels.JobClaimFailed",
					message = "Failed to claim job #arguments.jobId#: #e2.message#"
				);
			}
		}
	}

	/**
	 * The claim UPDATE, optionally writing claimTimeout and a fresh claimToken/claimedBy. Split
	 * out so $claimJob can retry without a column when it is missing. Uses the result option to
	 * read the affected-row count from the same connection (a separate SELECT can miss the
	 * uncommitted UPDATE on BoxLang + PostgreSQL). A won claim's token is kept for processNext
	 * to hand to $executeJob, which may only finish the job while the row still carries it.
	 */
	private boolean function $claimJobUpdate(
		required string jobId,
		required numeric claimTimeout,
		required boolean withClaimTimeout,
		boolean withClaimToken = false
	) {
		local.setClaim = arguments.withClaimTimeout ? ", claimTimeout = :claimTimeout" : "";
		// A new claim starts with no heartbeat, so an earlier attempt's can't make it look stale.
		if ($heartbeatColumnAvailable()) {
			local.setClaim &= ", heartbeatAt = NULL";
		}
		local.params = {
			updatedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"},
			id = {value = arguments.jobId, cfsqltype = "cf_sql_varchar"}
		};
		if (arguments.withClaimTimeout) {
			local.params.claimTimeout = {value = arguments.claimTimeout, cfsqltype = "cf_sql_integer"};
		}
		local.claimToken = "";
		if (arguments.withClaimToken) {
			local.claimToken = $jobBridge().$newClaimToken();
			local.setClaim &= ", claimToken = :claimToken, claimedBy = :claimedBy";
			local.params.claimToken = {value = local.claimToken, cfsqltype = "cf_sql_varchar"};
			local.params.claimedBy = {value = $jobBridge().$jobHostName(), cfsqltype = "cf_sql_varchar"};
		}
		queryExecute(
			"UPDATE wheels_jobs
			SET status = 'processing', attempts = attempts + 1, updatedAt = :updatedAt" & local.setClaim & "
			WHERE id = :id AND status = 'pending'",
			local.params,
			{datasource = variables.$datasource, result = "local.updateResult"}
		);
		local.won = (local.updateResult.recordCount ?: 0) > 0;
		if (local.won && Len(local.claimToken)) {
			if (!StructKeyExists(variables, "$claimTokens")) {
				variables.$claimTokens = {};
			}
			variables.$claimTokens[arguments.jobId] = local.claimToken;
		}
		return local.won;
	}

	/**
	 * The token this worker's claim of the job wrote, removed as it is read ("" when the claim
	 * ran unfenced — a column-less table, or a $claimJob override that bypasses the UPDATE).
	 */
	private string function $takeClaimToken(required string jobId) {
		if (!StructKeyExists(variables, "$claimTokens") || !StructKeyExists(variables.$claimTokens, arguments.jobId)) {
			return "";
		}
		local.token = variables.$claimTokens[arguments.jobId];
		StructDelete(variables.$claimTokens, arguments.jobId);
		return local.token;
	}

	/**
	 * Execute a job's perform() method.
	 */
	private struct function $executeJob(required struct jobRow, numeric timeout = 300) {
		local.result = {success = false, fenced = false, busy = false, retryInSeconds = 0, leaseName = "", leaseLost = false, error = "", errorType = "", errorDetail = "", jobInstance = "", tenantPending = false};
		// The failure's type/detail for the hooks, filled in by the catch (so not through local.).
		var failure = {type = "", detail = ""};
		local.claimToken = StructKeyExists(arguments.jobRow, "claimToken") ? arguments.jobRow.claimToken : "";

		// Initialized before the try so the cleanup below never reads an undefined
		// variable when instantiation/deserialization fails inside the try.
		local.hasTenantContext = false;

		try {
			// Shared with Job.$processJob so both processing paths report an unresolvable
			// jobClass the same way (issue #3351)
			local.jobInstance = $jobBridge().$instantiateJobClass(
				jobClass = arguments.jobRow.jobClass,
				jobId = arguments.jobRow.id
			);
			// So heartbeat() inside perform() renews this attempt's claim, and only this one's.
			local.jobInstance.$setClaimContext(jobId = arguments.jobRow.id, claimToken = local.claimToken);
			local.jobData = DeserializeJSON(arguments.jobRow.data);

			// Restore tenant context if the job was enqueued within a tenant scope and
			// strip the internal $wheelsTenantContext key before passing data to
			// perform() — shared with Job.$processJob so both processing paths run
			// tenant jobs against the correct tenant datasource.
			local.hasTenantContext = $jobBridge().$restoreTenantContext(local.jobData);
			local.workerCap = Val(arguments.timeout);
			if (local.workerCap <= 0) {
				local.workerCap = 300;
			}
			// With per-job timeouts the timeout passed in is already this job's own, so it is also
			// the fallback for a payload that carries none.
			local.fromRow = $jobBridge().$takeJobTimeout(jobData = local.jobData, fallback = this.perJobTimeout ? local.workerCap : 300);
			local.timeoutSeconds = Min(local.fromRow, local.workerCap);
			local.performOutcome = $jobBridge().$runPerformExclusively(
				jobInstance = local.jobInstance,
				jobData = local.jobData,
				timeoutSeconds = local.timeoutSeconds,
				jobId = arguments.jobRow.id,
				jobClass = arguments.jobRow.jobClass,
				claimToken = local.claimToken,
				claimTimeout = local.workerCap
			);
			local.result.leaseLost = local.performOutcome.leaseLost;
			local.result.jobInstance = local.jobInstance;
			if (local.performOutcome.busy) {
				local.result.busy = true;
				local.result.retryInSeconds = local.performOutcome.retryInSeconds;
				local.result.leaseName = local.performOutcome.leaseName;
				if (local.hasTenantContext) {
					$jobBridge().$clearTenantContext();
				}
				return local.result;
			}
			if (local.performOutcome.timedOut) {
				throw(type = "Wheels.JobTimeout", message = local.performOutcome.error);
			}
			if (!local.performOutcome.success) {
				failure.type = local.performOutcome.errorType;
				failure.detail = local.performOutcome.errorDetail;
				throw(type = "Wheels.JobFailed", message = local.performOutcome.error);
			}

			// Mark completed — only while the row is still this attempt's claim. Without the
			// token guard, an attempt that was reaped and re-claimed while it ran would match
			// the NEW attempt's 'processing' row here and complete it out from under it.
			local.doneParams = {
				completedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"},
				updatedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"},
				id = {value = arguments.jobRow.id, cfsqltype = "cf_sql_varchar"}
			};
			local.doneGuard = $jobBridge().$claimTokenGuard(claimToken = local.claimToken, params = local.doneParams);
			local.resultSet = $jobBridge().$resultAssignment(performOutcome = local.performOutcome, params = local.doneParams);
			queryExecute(
				"UPDATE wheels_jobs
				SET status = 'completed', completedAt = :completedAt, updatedAt = :updatedAt" & local.resultSet & "
				WHERE id = :id AND status = 'processing'" & local.doneGuard,
				local.doneParams,
				{datasource = variables.$datasource, result = "local.doneResult"}
			);

			if (Len(local.claimToken) && Val(local.doneResult.recordCount ?: 0) == 0) {
				$jobBridge().$logFencedAttempt(jobId = arguments.jobRow.id, jobClass = arguments.jobRow.jobClass, outcome = "completed");
				local.result.fenced = true;
				local.result.error = "Wheels.Job.Fenced: the claim on job #arguments.jobRow.id# was reaped before it completed";
			} else {
				writeLog(
					text = "Job '#arguments.jobRow.jobClass#' [#arguments.jobRow.id#] completed successfully",
					type = "information",
					file = "wheels_jobs"
				);
				local.result.success = true;
				$jobBridge().$fireJobSuccess(
					jobInstance = local.jobInstance,
					performOutcome = local.performOutcome,
					jobId = arguments.jobRow.id,
					jobClass = arguments.jobRow.jobClass
				);
			}
		} catch (any e) {
			local.result.error = Left(e.message, 1000);
			if (!Len(failure.type)) {
				failure.type = e.type;
			}
		}
		local.result.errorType = failure.type;
		local.result.errorDetail = failure.detail;

		// Clean up tenant context after job execution. A failed attempt keeps it until
		// $recordFailedAttempt() has run the failure hooks, which then clears it.
		if (local.hasTenantContext) {
			if (local.result.success || local.result.fenced) {
				$jobBridge().$clearTenantContext();
			} else {
				local.result.tenantPending = true;
			}
		}

		return local.result;
	}

	/**
	 * Records a failed attempt (a retry, or failed when retries are exhausted), then runs the
	 * failure hooks unless the attempt was fenced, and clears the tenant context the attempt
	 * kept for them. Returns true when the attempt was fenced.
	 */
	private boolean function $recordFailedAttempt(required struct jobRow, required struct processResult) {
		var outcome = {fenced = false};
		try {
			local.currentAttempts = Val(arguments.jobRow.attempts) + 1;
			local.maxRetries = Val(arguments.jobRow.maxRetries);
			local.isFinal = local.currentAttempts > local.maxRetries;
			if (!local.isFinal) {
				local.recorded = $scheduleRetry(
					jobId = arguments.jobRow.id,
					currentAttempts = local.currentAttempts,
					jobClass = arguments.jobRow.jobClass,
					maxRetries = local.maxRetries,
					errorMessage = arguments.processResult.error,
					claimToken = arguments.jobRow.claimToken
				);
			} else {
				local.recorded = $markFailed(
					jobId = arguments.jobRow.id,
					jobClass = arguments.jobRow.jobClass,
					maxRetries = local.maxRetries,
					errorMessage = arguments.processResult.error,
					claimToken = arguments.jobRow.claimToken
				);
			}
			if (Len(arguments.jobRow.claimToken) && local.recorded == 0) {
				$jobBridge().$logFencedAttempt(jobId = arguments.jobRow.id, jobClass = arguments.jobRow.jobClass, outcome = "failed");
				outcome.fenced = true;
			} else {
				$jobBridge().$fireJobFailure(
					jobInstance = arguments.processResult.jobInstance,
					jobId = arguments.jobRow.id,
					jobClass = arguments.jobRow.jobClass,
					queue = arguments.jobRow.queue,
					error = $jobBridge().$jobError(
						type = arguments.processResult.errorType,
						message = arguments.processResult.error,
						detail = arguments.processResult.errorDetail
					),
					attempt = local.currentAttempts,
					maxRetries = local.maxRetries,
					isFinal = local.isFinal
				);
			}
		} finally {
			if (arguments.processResult.tenantPending) {
				$jobBridge().$clearTenantContext();
			}
		}
		return outcome.fenced;
	}

	/**
	 * Runs the failure hooks for a job the reaper just ended for good: marked failed (its worker
	 * died or ran past its timeout on its last attempt), or interrupted (not idempotent, so never
	 * re-run). Best-effort and never blocks the reap loop; the job class
	 * is loaded on this server, and no tenant context is restored (the row's data isn't read).
	 */
	private void function $fireReapedFailure(required struct row, required string message) {
		try {
			var instance = "";
			try {
				instance = $jobBridge().$instantiateJobClass(jobClass = arguments.row.jobClass);
			} catch (any loadError) {
				instance = "";
			}
			$jobBridge().$fireJobFailure(
				jobInstance = instance,
				jobId = arguments.row.id,
				jobClass = arguments.row.jobClass,
				queue = StructKeyExists(arguments.row, "queue") ? arguments.row.queue : "",
				error = $jobBridge().$jobError(type = "Wheels.JobTimeout", message = arguments.message),
				attempt = Val(arguments.row.attempts),
				maxRetries = Val(arguments.row.maxRetries),
				isFinal = true
			);
		} catch (any e) {
			writeLog(text = "Job '#arguments.row.jobClass#' [#arguments.row.id#] failure hooks after the reap failed: #e.message#", type = "error", file = "wheels_jobs");
		}
	}

	/**
	 * Schedule a failed job for retry with configurable exponential backoff.
	 */
	private numeric function $scheduleRetry(
		required string jobId,
		required numeric currentAttempts,
		required string jobClass,
		required numeric maxRetries,
		required string errorMessage,
		numeric expectedAttempts = -1,
		any staleCutoff = "",
		string claimToken = ""
	) {
		local.baseDelay = 2;
		local.maxDelay = 3600;
		local.retryBackoff = "exponential";

		try {
			local.jobInstance = $jobBridge().$instantiateJobClass(jobClass = arguments.jobClass);
			if (StructKeyExists(local.jobInstance, "baseDelay")) local.baseDelay = local.jobInstance.baseDelay;
			if (StructKeyExists(local.jobInstance, "maxDelay")) local.maxDelay = local.jobInstance.maxDelay;
			if (StructKeyExists(local.jobInstance, "retryBackoff")) local.retryBackoff = local.jobInstance.retryBackoff;
		} catch (any e) {
			// Use defaults
		}

		local.backoffSeconds = $jobBridge().$backoffDelay(
			attempts = arguments.currentAttempts,
			baseDelay = local.baseDelay,
			maxDelay = local.maxDelay,
			retryBackoff = local.retryBackoff
		);
		local.nextRunAt = DateAdd("s", local.backoffSeconds, $now());

		local.params = {
			lastError = {value = Left(arguments.errorMessage, 1000), cfsqltype = "cf_sql_longvarchar"},
			runAt = {value = local.nextRunAt, cfsqltype = "cf_sql_timestamp"},
			updatedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"},
			id = {value = arguments.jobId, cfsqltype = "cf_sql_varchar"}
		};
		// Optimistic version token: when the reaper passes the attempts it read,
		// only this row-state wins the requeue, so two concurrent reapers (or a
		// re-claim, which bumps attempts) can't double-requeue the same job (#3888).
		local.attemptsGuard = "";
		if (arguments.expectedAttempts >= 0) {
			local.attemptsGuard = " AND attempts = :expectedAttempts";
			local.params.expectedAttempts = {value = arguments.expectedAttempts, cfsqltype = "cf_sql_integer"};
		}
		// Per-row staleness guard (#3989): the reaper passes the cutoff built from THIS row's
		// own claimTimeout, and the DB compares the timestamp — keeping all timestamp
		// comparison SQL-side (a query's updatedAt is an epoch number on BoxLang / mishandled
		// on Adobe when diffed in CFML). A row still inside its own window matches 0 rows.
		local.staleGuard = "";
		if (IsDate(arguments.staleCutoff)) {
			local.staleGuard = " AND " & $lastSeenSql() & " < :staleCutoff";
			local.params.staleCutoff = {value = arguments.staleCutoff, cfsqltype = "cf_sql_timestamp"};
		}
		// Fence (the owning attempt's own retry): only while the row is still its claim.
		local.tokenGuard = $jobBridge().$claimTokenGuard(claimToken = arguments.claimToken, params = local.params);
		// A requeued row is nobody's claim, so its token goes with it — the reaper path clears
		// the reaped attempt's token here too.
		local.clearToken = $claimTokenColumnAvailable() ? ", claimToken = NULL" : "";
		queryExecute(
			"UPDATE wheels_jobs
			SET status = 'pending',
				lastError = :lastError,
				runAt = :runAt,
				updatedAt = :updatedAt" & local.clearToken & "
			WHERE id = :id AND status = 'processing'" & local.attemptsGuard & local.staleGuard & local.tokenGuard,
			local.params,
			{datasource = variables.$datasource, result = "local.updateResult"}
		);

		writeLog(
			text = "Job '#arguments.jobClass#' [#arguments.jobId#] failed (attempt #arguments.currentAttempts#/#arguments.maxRetries#), retrying in #local.backoffSeconds#s",
			type = "warning",
			file = "wheels_jobs"
		);
		return StructKeyExists(local, "updateResult") ? Val(local.updateResult.recordCount) : 0;
	}

	/**
	 * Mark a job as permanently failed.
	 */
	private numeric function $markFailed(
		required string jobId,
		required string jobClass,
		required numeric maxRetries,
		required string errorMessage,
		numeric expectedAttempts = -1,
		any staleCutoff = "",
		string claimToken = ""
	) {
		local.params = {
			failedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"},
			lastError = {value = Left(arguments.errorMessage, 1000), cfsqltype = "cf_sql_longvarchar"},
			updatedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"},
			id = {value = arguments.jobId, cfsqltype = "cf_sql_varchar"}
		};
		// Same optimistic version token as $scheduleRetry: only this attempts-value wins (#3888).
		local.attemptsGuard = "";
		if (arguments.expectedAttempts >= 0) {
			local.attemptsGuard = " AND attempts = :expectedAttempts";
			local.params.expectedAttempts = {value = arguments.expectedAttempts, cfsqltype = "cf_sql_integer"};
		}
		// Per-row staleness guard built from the row's own claimTimeout, compared SQL-side (#3989).
		local.staleGuard = "";
		if (IsDate(arguments.staleCutoff)) {
			local.staleGuard = " AND " & $lastSeenSql() & " < :staleCutoff";
			local.params.staleCutoff = {value = arguments.staleCutoff, cfsqltype = "cf_sql_timestamp"};
		}
		local.tokenGuard = $jobBridge().$claimTokenGuard(claimToken = arguments.claimToken, params = local.params);
		queryExecute(
			"UPDATE wheels_jobs
			SET status = 'failed',
				failedAt = :failedAt,
				lastError = :lastError,
				updatedAt = :updatedAt
			WHERE id = :id AND status = 'processing'" & local.attemptsGuard & local.staleGuard & local.tokenGuard,
			local.params,
			{datasource = variables.$datasource, result = "local.updateResult"}
		);

		writeLog(
			text = "Job '#arguments.jobClass#' [#arguments.jobId#] permanently failed after #arguments.maxRetries# attempts",
			type = "error",
			file = "wheels_jobs"
		);
		return StructKeyExists(local, "updateResult") ? Val(local.updateResult.recordCount) : 0;
	}

	/**
	 * Returns Now() truncated to whole seconds.
	 * Prevents MySQL/H2 DATETIME rounding: fractional seconds >= 0.5 round UP.
	 */
	private date function $now() {
		local.n = Now();
		return CreateDateTime(Year(local.n), Month(local.n), Day(local.n), Hour(local.n), Minute(local.n), Second(local.n));
	}

	/**
	 * Ensure the wheels_jobs table exists. Delegates to Job.cfc's real table bootstrap —
	 * merely instantiating wheels.Job performs no database work, so on a fresh database
	 * the worker could previously never create the table. Guarded so the many catch
	 * paths that call this don't re-probe once the table has been verified.
	 */
	private boolean function $ensureJobTable() {
		if (StructKeyExists(variables, "$tableVerified")) {
			return true;
		}
		try {
			if ($jobBridge().$ensureJobTable()) {
				variables.$tableVerified = true;
				// Memoise whether claimTimeout is present AFTER the ensure (which may have just
				// added it), so claims/reaps pick the right query up front instead of letting a
				// missing column throw. A blocked ALTER leaves this false: one attempt per
				// worker, then straight to the no-column path (#3989 review).
				variables.$claimTimeoutColumnPresent = $jobBridge().$jobTableHasClaimTimeout();
				variables.$claimTokenColumnPresent = $jobBridge().$jobTableHasClaimToken();
				variables.$heartbeatColumnPresent = $jobBridge().$jobTableHasColumn("heartbeatAt");
				return true;
			}
			return false;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Whether the wheels_jobs.claimTimeout column is available to this worker. Memoised per
	 * worker instance — set when $ensureJobTable runs, or probed lazily the first time a
	 * claim/reap needs it (so a direct checkTimeouts call still gets a correct answer). Re-run
	 * by each new worker, so it is not a persisted flag (#2780).
	 */
	private boolean function $claimTimeoutColumnAvailable() {
		if (!StructKeyExists(variables, "$claimTimeoutColumnPresent")) {
			try {
				variables.$claimTimeoutColumnPresent = $jobBridge().$jobTableHasClaimTimeout();
			} catch (any e) {
				variables.$claimTimeoutColumnPresent = false;
			}
		}
		return variables.$claimTimeoutColumnPresent;
	}

	/**
	 * Whether the claim-fencing columns (claimToken/claimedBy) are available to this worker.
	 * Memoised per worker exactly like $claimTimeoutColumnAvailable.
	 */
	private boolean function $claimTokenColumnAvailable() {
		if (!StructKeyExists(variables, "$claimTokenColumnPresent")) {
			try {
				variables.$claimTokenColumnPresent = $jobBridge().$jobTableHasClaimToken();
			} catch (any e) {
				variables.$claimTokenColumnPresent = false;
			}
		}
		return variables.$claimTokenColumnPresent;
	}

	/**
	 * The timeout to claim and run a candidate with: this poll's timeout, or — with per-job
	 * timeouts — the candidate's own job class's timeout, capped by timeoutCap. A class that
	 * can't be loaded falls back to this poll's timeout (its run then fails as it always has).
	 */
	private numeric function $claimTimeoutFor(required string jobClass, required numeric pollTimeout) {
		if (!this.perJobTimeout) {
			return arguments.pollTimeout;
		}
		local.own = $jobClassTimeout(jobClass = arguments.jobClass, fallback = arguments.pollTimeout);
		if (IsNumeric(this.timeoutCap) && this.timeoutCap > 0) {
			return Min(local.own, this.timeoutCap);
		}
		return local.own;
	}

	/**
	 * A job class's own timeout (this.timeout), memoised per worker and class.
	 */
	private numeric function $jobClassTimeout(required string jobClass, required numeric fallback) {
		if (!StructKeyExists(variables, "$timeoutByClass")) {
			variables.$timeoutByClass = {};
		}
		if (!StructKeyExists(variables.$timeoutByClass, arguments.jobClass)) {
			var resolved = {seconds = arguments.fallback};
			try {
				var instance = $jobBridge().$instantiateJobClass(jobClass = arguments.jobClass);
				if (StructKeyExists(instance, "timeout") && IsNumeric(instance.timeout) && instance.timeout > 0) {
					resolved.seconds = instance.timeout;
				}
			} catch (any e) {
				resolved.seconds = arguments.fallback;
			}
			variables.$timeoutByClass[arguments.jobClass] = resolved.seconds;
		}
		return variables.$timeoutByClass[arguments.jobClass];
	}

	/**
	 * Whether the heartbeatAt column is available to this worker. Memoised per worker like the
	 * claimTimeout memo: set by $ensureJobTable, or probed lazily on first use.
	 */
	private boolean function $heartbeatColumnAvailable() {
		if (!StructKeyExists(variables, "$heartbeatColumnPresent")) {
			try {
				variables.$heartbeatColumnPresent = $jobBridge().$jobTableHasColumn("heartbeatAt");
			} catch (any e) {
				variables.$heartbeatColumnPresent = false;
			}
		}
		return variables.$heartbeatColumnPresent;
	}

	/**
	 * The SQL for when a processing job was last known alive: its latest heartbeat, or its
	 * claim (updatedAt) when it never heartbeat or the table has no heartbeatAt column.
	 */
	private string function $lastSeenSql() {
		return $heartbeatColumnAvailable() ? "COALESCE(heartbeatAt, updatedAt)" : "updatedAt";
	}

	/**
	 * Whether a reaped job may be retried: its class's this.idempotent, true by default. A class
	 * that can't be loaded counts as the default; its retry then fails the usual way.
	 * Memoised per worker and class.
	 */
	private boolean function $jobIsIdempotent(required string jobClass) {
		if (!StructKeyExists(variables, "$idempotentByClass")) {
			variables.$idempotentByClass = {};
		}
		if (!StructKeyExists(variables.$idempotentByClass, arguments.jobClass)) {
			var verdict = {idempotent = true};
			try {
				var instance = $jobBridge().$instantiateJobClass(jobClass = arguments.jobClass);
				if (StructKeyExists(instance, "idempotent") && IsBoolean(instance.idempotent)) {
					verdict.idempotent = instance.idempotent;
				}
			} catch (any e) {
				verdict.idempotent = true;
			}
			variables.$idempotentByClass[arguments.jobClass] = verdict.idempotent;
		}
		return variables.$idempotentByClass[arguments.jobClass];
	}

	/**
	 * End a reaped attempt of a non-idempotent job: status 'interrupted', not retried. Guarded
	 * like the reaper's retry (attempts read + per-row staleness), so it can't race a finish or
	 * a re-claim. Returns the number of rows changed.
	 */
	private numeric function $markInterrupted(
		required string jobId,
		required string jobClass,
		required string errorMessage,
		required numeric expectedAttempts,
		required any staleCutoff
	) {
		local.params = {
			failedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"},
			lastError = {value = Left(arguments.errorMessage, 1000), cfsqltype = "cf_sql_longvarchar"},
			updatedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"},
			id = {value = arguments.jobId, cfsqltype = "cf_sql_varchar"},
			expectedAttempts = {value = arguments.expectedAttempts, cfsqltype = "cf_sql_integer"},
			staleCutoff = {value = arguments.staleCutoff, cfsqltype = "cf_sql_timestamp"}
		};
		queryExecute(
			"UPDATE wheels_jobs
			SET status = 'interrupted',
				failedAt = :failedAt,
				lastError = :lastError,
				updatedAt = :updatedAt
			WHERE id = :id AND status = 'processing' AND attempts = :expectedAttempts AND " & $lastSeenSql() & " < :staleCutoff",
			local.params,
			{datasource = variables.$datasource, result = "local.updateResult"}
		);
		local.changed = StructKeyExists(local, "updateResult") ? Val(local.updateResult.recordCount) : 0;
		// Only the reaper that won the row logs it: a concurrent one (or a row that came back to
		// life) changed nothing.
		if (local.changed > 0) {
			writeLog(
				text = "Job '#arguments.jobClass#' [#arguments.jobId#] was interrupted: its worker stopped responding and the job is not idempotent, so it was not retried",
				type = "warning",
				file = "wheels_jobs"
			);
		}
		return local.changed;
	}

	/**
	 * Fetch a single job's data payload by id. Called only for the job this worker
	 * actually claimed, so the candidate scan doesn't transfer every pending payload.
	 */
	private string function $fetchJobData(required string jobId) {
		local.dataRow = queryExecute(
			"SELECT data FROM wheels_jobs WHERE id = :id",
			{id = {value = arguments.jobId, cfsqltype = "cf_sql_varchar"}},
			{datasource = variables.$datasource}
		);
		if (local.dataRow.recordCount) {
			return local.dataRow.data;
		}
		return "";
	}

	/**
	 * Database type for SQL syntax selection, detected once per worker instance.
	 */
	private string function $dbType() {
		if (!StructKeyExists(variables, "$dbTypeCached")) {
			variables.$dbTypeCached = $jobBridge().$detectDatabaseType();
		}
		return variables.$dbTypeCached;
	}

	/**
	 * Lazily instantiate the wheels.Job bridge used to share framework job helpers
	 * (tenant context handling, table bootstrap, database type detection).
	 */
	private any function $jobBridge() {
		if (!StructKeyExists(variables, "$jobBridgeInstance")) {
			variables.$jobBridgeInstance = new wheels.Job();
		}
		return variables.$jobBridgeInstance;
	}

	/**
	 * SQL fragment that bounds a pending-job candidate SELECT.
	 * Unknown database types get LIMIT too — an unbounded backlog scan is worse
	 * than a syntax error that the existing catch already contains.
	 */
	public string function $candidateLimitClause(required string dbType, numeric candidateLimit = 25) {
		local.n = Int(Val(arguments.candidateLimit));
		if (local.n <= 0) {
			local.n = 25;
		}
		local.normalized = LCase(Trim(arguments.dbType));
		if (local.normalized == "sqlserver") {
			return " OFFSET 0 ROWS FETCH NEXT #local.n# ROWS ONLY";
		}
		if (local.normalized == "oracle") {
			return " FETCH FIRST #local.n# ROWS ONLY";
		}
		return " LIMIT #local.n#";
	}

}
