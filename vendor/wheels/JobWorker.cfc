/**
 * Job Worker engine for the Wheels background job system.
 * Provides single-job claiming with optimistic locking, timeout recovery,
 * queue statistics, monitoring, and management operations.
 *
 * Used by CLI commands (wheels jobs work/status/retry/purge/monitor)
 * and the CLI bridge to process jobs from the _wheels_jobs table.
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
		local.result = {success = false, jobId = "", jobClass = "", error = "", skipped = false};

		// Find the next candidate job
		local.params = {
			runAt = {value = Now(), cfsqltype = "cf_sql_timestamp"}
		};

		local.sql = "SELECT id, jobClass, queue, data, attempts, maxRetries
			FROM _wheels_jobs
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

		// Fetch a small batch of candidates for optimistic locking
		try {
			local.candidates = queryExecute(local.sql, local.params, {datasource = variables.$datasource, maxrows = 5});
		} catch (any e) {
			$ensureJobTable();
			local.result.skipped = true;
			return local.result;
		}

		if (!local.candidates.recordCount) {
			local.result.skipped = true;
			return local.result;
		}

		// Try to claim each candidate with optimistic locking
		for (local.row in local.candidates) {
			local.claimed = $claimJob(local.row.id);
			if (local.claimed) {
				// We claimed it — now process
				local.processResult = $executeJob(local.row);
				local.result.jobId = local.row.id;
				local.result.jobClass = local.row.jobClass;

				if (local.processResult.success) {
					this.jobsProcessed++;
					local.result.success = true;
				} else {
					this.jobsFailed++;
					local.result.error = local.processResult.error;

					// Determine retry eligibility
					local.currentAttempts = Val(local.row.attempts) + 1;
					local.maxRetries = Val(local.row.maxRetries);

					if (local.currentAttempts < local.maxRetries) {
						$scheduleRetry(local.row.id, local.currentAttempts, local.row.jobClass, local.maxRetries, local.processResult.error);
					} else {
						$markFailed(local.row.id, local.row.jobClass, local.maxRetries, local.processResult.error);
					}
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
	public numeric function checkTimeouts(numeric timeout = 300) {
		local.cutoff = DateAdd("s", -arguments.timeout, Now());

		// Find timed-out jobs
		try {
			local.timedOut = queryExecute(
				"SELECT id, jobClass, attempts, maxRetries
				FROM _wheels_jobs
				WHERE status = 'processing' AND updatedAt < :cutoff",
				{cutoff = {value = local.cutoff, cfsqltype = "cf_sql_timestamp"}},
				{datasource = variables.$datasource}
			);
		} catch (any e) {
			$ensureJobTable();
			return 0;
		}

		local.recovered = 0;
		for (local.row in local.timedOut) {
			local.currentAttempts = Val(local.row.attempts);
			local.maxRetries = Val(local.row.maxRetries);

			if (local.currentAttempts < local.maxRetries) {
				// Reschedule for retry
				$scheduleRetry(local.row.id, local.currentAttempts, local.row.jobClass, local.maxRetries, "Job timed out after #arguments.timeout# seconds");
				local.recovered++;
			} else {
				// Exhausted retries
				$markFailed(local.row.id, local.row.jobClass, local.maxRetries, "Job timed out after #arguments.timeout# seconds (max retries exhausted)");
				local.recovered++;
			}
		}

		return local.recovered;
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
			local.sql = "SELECT queue, status, COUNT(*) as cnt FROM _wheels_jobs";
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

		local.lookback = DateAdd("n", -arguments.minutes, Now());
		local.params = {lookback = {value = local.lookback, cfsqltype = "cf_sql_timestamp"}};

		// Throughput — completed and failed in the window
		try {
			local.sql = "SELECT status, COUNT(*) as cnt FROM _wheels_jobs
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
				FROM _wheels_jobs ORDER BY updatedAt DESC";
			local.recentRows = queryExecute(local.recentSql, {}, {datasource = variables.$datasource, maxrows = 10});

			for (local.row in local.recentRows) {
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
			local.oldestSql = "SELECT createdAt FROM _wheels_jobs WHERE status = 'pending' ORDER BY createdAt ASC";
			local.oldestRow = queryExecute(local.oldestSql, {}, {datasource = variables.$datasource, maxrows = 1});
			if (local.oldestRow.recordCount) {
				local.result.oldestPending = local.oldestRow.createdAt;
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
		local.now = Now();

		// If limit specified, get the IDs first
		if (arguments.limit > 0) {
			try {
				local.selectSql = "SELECT id FROM _wheels_jobs WHERE status = 'failed'";
				local.selectParams = {};
				if (Len(arguments.queue)) {
					local.selectSql &= " AND queue = :queue";
					local.selectParams.queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"};
				}
				local.selectSql &= " ORDER BY failedAt ASC";
				local.failedJobs = queryExecute(local.selectSql, local.selectParams, {datasource = variables.$datasource, maxrows = arguments.limit});

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

				local.updateSql = "UPDATE _wheels_jobs
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
		local.sql = "UPDATE _wheels_jobs
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
			queryExecute(local.sql, local.params, {datasource = variables.$datasource, result = "local.updateResult"});
			return local.updateResult.recordCount ?: 0;
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

		local.cutoff = DateAdd("d", -arguments.days, Now());
		local.dateColumn = (arguments.status == "completed") ? "completedAt" : "failedAt";

		local.sql = "DELETE FROM _wheels_jobs WHERE status = :status AND #local.dateColumn# < :cutoff";
		local.params = {
			status = {value = arguments.status, cfsqltype = "cf_sql_varchar"},
			cutoff = {value = local.cutoff, cfsqltype = "cf_sql_timestamp"}
		};

		if (Len(arguments.queue)) {
			local.sql &= " AND queue = :queue";
			local.params.queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"};
		}

		try {
			queryExecute(local.sql, local.params, {datasource = variables.$datasource, result = "local.deleteResult"});
			return local.deleteResult.recordCount ?: 0;
		} catch (any e) {
			$ensureJobTable();
			return 0;
		}
	}

	// ── Private Methods ──────────────────────────────────────────────

	/**
	 * Claim a job using optimistic locking.
	 * Returns true if this worker successfully claimed the job.
	 */
	private boolean function $claimJob(required string jobId) {
		try {
			queryExecute(
				"UPDATE _wheels_jobs
				SET status = 'processing', attempts = attempts + 1, updatedAt = :updatedAt
				WHERE id = :id AND status = 'pending'",
				{
					updatedAt = {value = Now(), cfsqltype = "cf_sql_timestamp"},
					id = {value = arguments.jobId, cfsqltype = "cf_sql_varchar"}
				},
				{datasource = variables.$datasource, result = "local.updateResult"}
			);
			return (local.updateResult.recordCount ?: 0) > 0;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Execute a job's perform() method.
	 */
	private struct function $executeJob(required struct jobRow) {
		local.result = {success = false, error = ""};
		try {
			local.jobInstance = CreateObject("component", arguments.jobRow.jobClass);
			local.jobData = DeserializeJSON(arguments.jobRow.data);
			local.jobInstance.perform(data = local.jobData);

			// Mark completed
			queryExecute(
				"UPDATE _wheels_jobs
				SET status = 'completed', completedAt = :completedAt, updatedAt = :updatedAt
				WHERE id = :id",
				{
					completedAt = {value = Now(), cfsqltype = "cf_sql_timestamp"},
					updatedAt = {value = Now(), cfsqltype = "cf_sql_timestamp"},
					id = {value = arguments.jobRow.id, cfsqltype = "cf_sql_varchar"}
				},
				{datasource = variables.$datasource}
			);

			writeLog(
				text = "Job '#arguments.jobRow.jobClass#' [#arguments.jobRow.id#] completed successfully",
				type = "information",
				file = "wheels_jobs"
			);
			local.result.success = true;
		} catch (any e) {
			local.result.error = Left(e.message, 1000);
		}
		return local.result;
	}

	/**
	 * Schedule a failed job for retry with configurable exponential backoff.
	 */
	private void function $scheduleRetry(
		required string jobId,
		required numeric currentAttempts,
		required string jobClass,
		required numeric maxRetries,
		required string errorMessage
	) {
		// Use configurable backoff: baseDelay * 2^attempt, capped at maxDelay
		// Default values match Job.cfc: baseDelay=2, maxDelay=3600
		local.baseDelay = 2;
		local.maxDelay = 3600;

		// Try to get the job instance's backoff settings
		try {
			local.jobInstance = CreateObject("component", arguments.jobClass);
			if (StructKeyExists(local.jobInstance, "baseDelay")) local.baseDelay = local.jobInstance.baseDelay;
			if (StructKeyExists(local.jobInstance, "maxDelay")) local.maxDelay = local.jobInstance.maxDelay;
		} catch (any e) {
			// Use defaults
		}

		local.backoffSeconds = Min(local.baseDelay * (2 ^ arguments.currentAttempts), local.maxDelay);
		local.nextRunAt = DateAdd("s", local.backoffSeconds, Now());

		queryExecute(
			"UPDATE _wheels_jobs
			SET status = 'pending',
				lastError = :lastError,
				runAt = :runAt,
				updatedAt = :updatedAt
			WHERE id = :id",
			{
				lastError = {value = Left(arguments.errorMessage, 1000), cfsqltype = "cf_sql_longvarchar"},
				runAt = {value = local.nextRunAt, cfsqltype = "cf_sql_timestamp"},
				updatedAt = {value = Now(), cfsqltype = "cf_sql_timestamp"},
				id = {value = arguments.jobId, cfsqltype = "cf_sql_varchar"}
			},
			{datasource = variables.$datasource}
		);

		writeLog(
			text = "Job '#arguments.jobClass#' [#arguments.jobId#] failed (attempt #arguments.currentAttempts#/#arguments.maxRetries#), retrying in #local.backoffSeconds#s",
			type = "warning",
			file = "wheels_jobs"
		);
	}

	/**
	 * Mark a job as permanently failed.
	 */
	private void function $markFailed(
		required string jobId,
		required string jobClass,
		required numeric maxRetries,
		required string errorMessage
	) {
		queryExecute(
			"UPDATE _wheels_jobs
			SET status = 'failed',
				failedAt = :failedAt,
				lastError = :lastError,
				updatedAt = :updatedAt
			WHERE id = :id",
			{
				failedAt = {value = Now(), cfsqltype = "cf_sql_timestamp"},
				lastError = {value = Left(arguments.errorMessage, 1000), cfsqltype = "cf_sql_longvarchar"},
				updatedAt = {value = Now(), cfsqltype = "cf_sql_timestamp"},
				id = {value = arguments.jobId, cfsqltype = "cf_sql_varchar"}
			},
			{datasource = variables.$datasource}
		);

		writeLog(
			text = "Job '#arguments.jobClass#' [#arguments.jobId#] permanently failed after #arguments.maxRetries# attempts",
			type = "error",
			file = "wheels_jobs"
		);
	}

	/**
	 * Ensure the _wheels_jobs table exists. Delegates to Job.cfc's implementation.
	 */
	private boolean function $ensureJobTable() {
		try {
			local.job = new wheels.Job();
			return true;
		} catch (any e) {
			return false;
		}
	}

}
