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
		local.result = {success = false, jobId = "", jobClass = "", error = "", skipped = false, fenced = false};

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

		// Try to claim each candidate with optimistic locking
		for (local.row in local.candidates) {
			try {
				local.claimFn = this["$claimJob"];
				local.claimed = local.claimFn(local.row.id, arguments.timeout);
			} catch (any e) {
				// Persist/claim errors are contained — they must not look like an idle skip.
				local.result.skipped = false;
				local.result.success = false;
				local.result.jobId = local.row.id;
				local.result.jobClass = local.row.jobClass;
				local.result.error = Left(e.message, 1000);
				return local.result;
			}
			if (local.claimed) {
				// We claimed it — fetch the payload for just this job, then process
				local.jobRow = {
					id = local.row.id,
					jobClass = local.row.jobClass,
					queue = local.row.queue,
					data = $fetchJobData(local.row.id),
					attempts = local.row.attempts,
					maxRetries = local.row.maxRetries,
					claimToken = $takeClaimToken(local.row.id)
				};
				local.processResult = $executeJob(jobRow = local.jobRow, timeout = arguments.timeout);
				local.result.jobId = local.row.id;
				local.result.jobClass = local.row.jobClass;

				if (local.processResult.fenced) {
					// Ran, but the claim was reaped and re-issued while it did: the completion
					// was rejected, and retrying it would requeue the attempt that replaced it.
					local.result.fenced = true;
					local.result.error = local.processResult.error;
				} else if (local.processResult.success) {
					this.jobsProcessed++;
					local.result.success = true;
				} else {
					this.jobsFailed++;
					local.result.error = local.processResult.error;
					local.result.fenced = $recordFailedAttempt(jobRow = local.jobRow, processResult = local.processResult);
				}
				return local.result;
			}
		}

		// All candidates were claimed by other workers
		local.result.skipped = true;
		return local.result;
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
		local.whereClause = "WHERE status = 'processing' AND updatedAt < :cutoff" & local.queueFilter;
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
			local.rowTimeout = local.timeout;
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
			if (local.currentAttempts <= local.maxRetries) {
				// Reschedule for retry
				local.won = $scheduleRetry(local.row.id, local.currentAttempts, local.row.jobClass, local.maxRetries, "Job timed out after #local.rowTimeout# seconds", local.currentAttempts, local.rowCutoff);
			} else {
				// Exhausted retries
				local.won = $markFailed(local.row.id, local.row.jobClass, local.maxRetries, "Job timed out after #local.rowTimeout# seconds (max retries exhausted)", local.currentAttempts, local.rowCutoff);
				if (local.won > 0) {
					$fireReapedFailure(row = local.row, seconds = local.rowTimeout);
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
			totals = {pending = 0, processing = 0, completed = 0, failed = 0, total = 0}
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
				local.result.queues[local.row.queue] = {pending = 0, processing = 0, completed = 0, failed = 0, total = 0};
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
		if (!ListFindNoCase("completed,failed", arguments.status)) {
			throw(type = "Wheels.InvalidArgument", message = "Purge status must be 'completed' or 'failed'.");
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
		local.result = {success = false, fenced = false, error = "", errorType = "", errorDetail = "", jobInstance = "", tenantPending = false};
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
			local.jobData = DeserializeJSON(arguments.jobRow.data);

			// Restore tenant context if the job was enqueued within a tenant scope and
			// strip the internal $wheelsTenantContext key before passing data to
			// perform() — shared with Job.$processJob so both processing paths run
			// tenant jobs against the correct tenant datasource.
			local.hasTenantContext = $jobBridge().$restoreTenantContext(local.jobData);
			local.fromRow = $jobBridge().$takeJobTimeout(jobData = local.jobData, fallback = 300);
			local.workerCap = Val(arguments.timeout);
			if (local.workerCap <= 0) {
				local.workerCap = 300;
			}
			local.timeoutSeconds = Min(local.fromRow, local.workerCap);
			local.performOutcome = $jobBridge().$runPerformWithTimeout(
				jobInstance = local.jobInstance,
				jobData = local.jobData,
				timeoutSeconds = local.timeoutSeconds
			);
			local.result.jobInstance = local.jobInstance;
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
	 * Runs the failure hooks for a job the reaper just marked failed: its worker died or ran past
	 * its timeout on its last attempt. Best-effort and never blocks the reap loop; the job class
	 * is loaded on this server, and no tenant context is restored (the row's data isn't read).
	 */
	private void function $fireReapedFailure(required struct row, required numeric seconds) {
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
				error = $jobBridge().$jobError(type = "Wheels.JobTimeout", message = "Job timed out after #arguments.seconds# seconds (max retries exhausted)"),
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
			local.staleGuard = " AND updatedAt < :staleCutoff";
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
			local.staleGuard = " AND updatedAt < :staleCutoff";
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
