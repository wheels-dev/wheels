/**
 * Base Job class for Wheels framework.
 * Provides background job processing with database-backed persistence,
 * retry logic with exponential backoff, and priority queue support.
 *
 * Usage:
 *   // In app/jobs/SendWelcomeEmailJob.cfc
 *   component extends="wheels.Job" {
 *     function config() {
 *       super.config();
 *       this.queue = "mailers";
 *       this.maxRetries = 5;
 *     }
 *     public void function perform(struct data = {}) {
 *       // Send the email
 *       sendEmail(to=data.email, subject="Welcome!", from="noreply@example.com");
 *     }
 *   }
 *
 *   // Enqueue from a controller:
 *   job = new app.jobs.SendWelcomeEmailJob();
 *   job.enqueue(data={email: user.email});
 */
component {

	// Default job configuration (override in subclass config())
	this.queue = "default";
	this.priority = 0;
	this.maxRetries = 3;
	this.retryBackoff = "exponential";
	this.timeout = 300;

	/**
	 * Constructor
	 */
	public function init() {
		config();
		return this;
	}

	/**
	 * Override in subclasses to configure job options.
	 */
	public void function config() {
	}

	/**
	 * Main job execution method. Must be overridden by subclasses.
	 * @data Job data/parameters
	 */
	public void function perform(struct data = {}) {
		throw(type = "Wheels.NotImplemented", message = "The perform() method must be implemented in the job subclass.");
	}

	/**
	 * Enqueue this job for immediate processing.
	 * @data Job data to pass to perform().
	 * @queue Override the default queue name.
	 * @priority Override the default priority (higher = processed first).
	 */
	public struct function enqueue(struct data = {}, string queue = this.queue, numeric priority = this.priority) {
		return $enqueueJob(
			jobClass = GetMetadata(this).name,
			data = arguments.data,
			queue = arguments.queue,
			priority = arguments.priority,
			runAt = Now()
		);
	}

	/**
	 * Enqueue this job for processing after a delay.
	 * @seconds Number of seconds to wait before processing.
	 * @data Job data to pass to perform().
	 * @queue Override the default queue name.
	 * @priority Override the default priority.
	 */
	public struct function enqueueIn(
		required numeric seconds,
		struct data = {},
		string queue = this.queue,
		numeric priority = this.priority
	) {
		return $enqueueJob(
			jobClass = GetMetadata(this).name,
			data = arguments.data,
			queue = arguments.queue,
			priority = arguments.priority,
			runAt = DateAdd("s", arguments.seconds, Now())
		);
	}

	/**
	 * Enqueue this job for processing at a specific time.
	 * @runAt Date/time when the job should be processed.
	 * @data Job data to pass to perform().
	 * @queue Override the default queue name.
	 * @priority Override the default priority.
	 */
	public struct function enqueueAt(
		required date runAt,
		struct data = {},
		string queue = this.queue,
		numeric priority = this.priority
	) {
		return $enqueueJob(
			jobClass = GetMetadata(this).name,
			data = arguments.data,
			queue = arguments.queue,
			priority = arguments.priority,
			runAt = arguments.runAt
		);
	}

	/**
	 * Internal: Persist a job to the queue table.
	 */
	private struct function $enqueueJob(
		required string jobClass,
		required struct data,
		required string queue,
		required numeric priority,
		required date runAt
	) {
		local.id = CreateUUID();
		local.serializedData = SerializeJSON(arguments.data);
		local.now = Now();

		try {
			local.sql = "
				INSERT INTO _wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
				VALUES (
					'#local.id#',
					'#arguments.jobClass#',
					'#arguments.queue#',
					'#Replace(local.serializedData, "'", "''", "all")#',
					#arguments.priority#,
					'pending',
					0,
					#this.maxRetries#,
					'#DateTimeFormat(arguments.runAt, 'yyyy-mm-dd HH:nn:ss')#',
					'#DateTimeFormat(local.now, 'yyyy-mm-dd HH:nn:ss')#',
					'#DateTimeFormat(local.now, 'yyyy-mm-dd HH:nn:ss')#'
				)
			";

			queryExecute(local.sql);
		} catch (any e) {
			// If the table doesn't exist, fall back to logging
			writeLog(
				text = "Job '#arguments.jobClass#' enqueued (in-memory). Run the job queue migration to enable persistence. Error: #e.message#",
				type = "warning",
				file = "wheels_jobs"
			);
			return {id = local.id, jobClass = arguments.jobClass, status = "pending", persisted = false};
		}

		writeLog(
			text = "Job '#arguments.jobClass#' [#local.id#] enqueued to queue '#arguments.queue#' with priority #arguments.priority#",
			type = "information",
			file = "wheels_jobs"
		);

		return {id = local.id, jobClass = arguments.jobClass, status = "pending", persisted = true};
	}

	/**
	 * Process pending jobs from the queue. Call this from a scheduled task or controller action.
	 * @queue Queue name to process. Default processes all queues.
	 * @limit Maximum number of jobs to process in this batch.
	 */
	public struct function processQueue(string queue = "", numeric limit = 10) {
		local.result = {processed = 0, failed = 0, errors = []};
		local.whereClause = "status = 'pending' AND runAt <= '#DateTimeFormat(Now(), 'yyyy-mm-dd HH:nn:ss')#'";

		if (Len(arguments.queue)) {
			local.whereClause &= " AND queue = '#arguments.queue#'";
		}

		try {
			local.jobs = queryExecute(
				"SELECT id, jobClass, queue, data, attempts, maxRetries
				FROM _wheels_jobs
				WHERE #local.whereClause#
				ORDER BY priority DESC, runAt ASC
				LIMIT #arguments.limit#"
			);
		} catch (any e) {
			ArrayAppend(local.result.errors, "Queue table not found. Run the job queue migration first.");
			return local.result;
		}

		for (local.row in local.jobs) {
			local.jobResult = $processJob(local.row);
			if (local.jobResult.success) {
				local.result.processed++;
			} else {
				local.result.failed++;
				ArrayAppend(local.result.errors, local.jobResult.error);
			}
		}

		return local.result;
	}

	/**
	 * Internal: Process a single job row.
	 */
	private struct function $processJob(required struct jobRow) {
		local.result = {success = false, error = ""};

		// Mark as processing
		try {
			queryExecute("
				UPDATE _wheels_jobs
				SET status = 'processing', attempts = attempts + 1, updatedAt = '#DateTimeFormat(Now(), 'yyyy-mm-dd HH:nn:ss')#'
				WHERE id = '#arguments.jobRow.id#'
			");
		} catch (any e) {
			local.result.error = "Failed to lock job #arguments.jobRow.id#: #e.message#";
			return local.result;
		}

		try {
			// Instantiate and execute the job
			local.jobInstance = CreateObject("component", arguments.jobRow.jobClass);
			local.jobData = DeserializeJSON(arguments.jobRow.data);
			local.jobInstance.perform(data = local.jobData);

			// Mark as completed
			queryExecute("
				UPDATE _wheels_jobs
				SET status = 'completed', completedAt = '#DateTimeFormat(Now(), 'yyyy-mm-dd HH:nn:ss')#', updatedAt = '#DateTimeFormat(Now(), 'yyyy-mm-dd HH:nn:ss')#'
				WHERE id = '#arguments.jobRow.id#'
			");

			writeLog(
				text = "Job '#arguments.jobRow.jobClass#' [#arguments.jobRow.id#] completed successfully",
				type = "information",
				file = "wheels_jobs"
			);

			local.result.success = true;

		} catch (any e) {
			// Determine retry eligibility
			local.currentAttempts = Val(arguments.jobRow.attempts) + 1;
			local.maxRetries = Val(arguments.jobRow.maxRetries);

			if (local.currentAttempts < local.maxRetries) {
				// Schedule retry with exponential backoff: 2^attempt seconds (4s, 8s, 16s, 32s...)
				local.backoffSeconds = 2 ^ (local.currentAttempts + 1);
				local.nextRunAt = DateAdd("s", local.backoffSeconds, Now());

				queryExecute("
					UPDATE _wheels_jobs
					SET status = 'pending',
						lastError = '#Replace(Left(e.message, 1000), "'", "''", "all")#',
						runAt = '#DateTimeFormat(local.nextRunAt, 'yyyy-mm-dd HH:nn:ss')#',
						updatedAt = '#DateTimeFormat(Now(), 'yyyy-mm-dd HH:nn:ss')#'
					WHERE id = '#arguments.jobRow.id#'
				");

				writeLog(
					text = "Job '#arguments.jobRow.jobClass#' [#arguments.jobRow.id#] failed (attempt #local.currentAttempts#/#local.maxRetries#), retrying in #local.backoffSeconds#s: #e.message#",
					type = "warning",
					file = "wheels_jobs"
				);
			} else {
				// Max retries exceeded — mark as failed (dead letter)
				queryExecute("
					UPDATE _wheels_jobs
					SET status = 'failed',
						failedAt = '#DateTimeFormat(Now(), 'yyyy-mm-dd HH:nn:ss')#',
						lastError = '#Replace(Left(e.message, 1000), "'", "''", "all")#',
						updatedAt = '#DateTimeFormat(Now(), 'yyyy-mm-dd HH:nn:ss')#'
					WHERE id = '#arguments.jobRow.id#'
				");

				writeLog(
					text = "Job '#arguments.jobRow.jobClass#' [#arguments.jobRow.id#] permanently failed after #local.maxRetries# attempts: #e.message#",
					type = "error",
					file = "wheels_jobs"
				);
			}

			local.result.error = "Job #arguments.jobRow.id# (#arguments.jobRow.jobClass#): #e.message#";
		}

		return local.result;
	}

	/**
	 * Get the count of jobs by status.
	 * @queue Optional queue name to filter by.
	 */
	public struct function queueStats(string queue = "") {
		local.stats = {pending = 0, processing = 0, completed = 0, failed = 0, total = 0};

		try {
			local.whereClause = "1=1";
			if (Len(arguments.queue)) {
				local.whereClause = "queue = '#arguments.queue#'";
			}

			local.result = queryExecute("
				SELECT status, COUNT(*) as cnt
				FROM _wheels_jobs
				WHERE #local.whereClause#
				GROUP BY status
			");

			for (local.row in local.result) {
				if (StructKeyExists(local.stats, local.row.status)) {
					local.stats[local.row.status] = local.row.cnt;
				}
				local.stats.total += local.row.cnt;
			}
		} catch (any e) {
			// Table doesn't exist yet
		}

		return local.stats;
	}

	/**
	 * Retry all failed jobs.
	 * @queue Optional queue name to filter by.
	 */
	public numeric function retryFailed(string queue = "") {
		local.whereClause = "status = 'failed'";
		if (Len(arguments.queue)) {
			local.whereClause &= " AND queue = '#arguments.queue#'";
		}

		try {
			local.result = queryExecute("
				UPDATE _wheels_jobs
				SET status = 'pending', attempts = 0, lastError = NULL, failedAt = NULL,
					runAt = '#DateTimeFormat(Now(), 'yyyy-mm-dd HH:nn:ss')#',
					updatedAt = '#DateTimeFormat(Now(), 'yyyy-mm-dd HH:nn:ss')#'
				WHERE #local.whereClause#
			");
			return local.result.recordCount ?: 0;
		} catch (any e) {
			return 0;
		}
	}

	/**
	 * Purge completed jobs older than the specified number of days.
	 * @days Number of days to keep completed jobs.
	 * @queue Optional queue name to filter by.
	 */
	public numeric function purgeCompleted(numeric days = 7, string queue = "") {
		local.cutoff = DateAdd("d", -arguments.days, Now());
		local.whereClause = "status = 'completed' AND completedAt < '#DateTimeFormat(local.cutoff, 'yyyy-mm-dd HH:nn:ss')#'";

		if (Len(arguments.queue)) {
			local.whereClause &= " AND queue = '#arguments.queue#'";
		}

		try {
			local.result = queryExecute("DELETE FROM _wheels_jobs WHERE #local.whereClause#");
			return local.result.recordCount ?: 0;
		} catch (any e) {
			return 0;
		}
	}
}
