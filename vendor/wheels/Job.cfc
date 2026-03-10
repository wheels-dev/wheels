/**
 * Base Job class for Wheels framework.
 * Provides background job processing with database-backed persistence,
 * retry logic with exponential backoff, and priority queue support.
 *
 * The _wheels_jobs table is auto-created on first use — no migration needed.
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
	this.baseDelay = 2;
	this.maxDelay = 3600;

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
			queryExecute(
				"INSERT INTO _wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
				VALUES (:id, :jobClass, :queue, :data, :priority, 'pending', 0, :maxRetries, :runAt, :createdAt, :updatedAt)",
				{
					id = {value = local.id, cfsqltype = "cf_sql_varchar"},
					jobClass = {value = arguments.jobClass, cfsqltype = "cf_sql_varchar"},
					queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"},
					data = {value = local.serializedData, cfsqltype = "cf_sql_longvarchar"},
					priority = {value = arguments.priority, cfsqltype = "cf_sql_integer"},
					maxRetries = {value = this.maxRetries, cfsqltype = "cf_sql_integer"},
					runAt = {value = arguments.runAt, cfsqltype = "cf_sql_timestamp"},
					createdAt = {value = local.now, cfsqltype = "cf_sql_timestamp"},
					updatedAt = {value = local.now, cfsqltype = "cf_sql_timestamp"}
				}
			);
		} catch (any e) {
			// Auto-create table on first use and retry
			if ($ensureJobTable()) {
				try {
					queryExecute(
						"INSERT INTO _wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
						VALUES (:id, :jobClass, :queue, :data, :priority, 'pending', 0, :maxRetries, :runAt, :createdAt, :updatedAt)",
						{
							id = {value = local.id, cfsqltype = "cf_sql_varchar"},
							jobClass = {value = arguments.jobClass, cfsqltype = "cf_sql_varchar"},
							queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"},
							data = {value = local.serializedData, cfsqltype = "cf_sql_longvarchar"},
							priority = {value = arguments.priority, cfsqltype = "cf_sql_integer"},
							maxRetries = {value = this.maxRetries, cfsqltype = "cf_sql_integer"},
							runAt = {value = arguments.runAt, cfsqltype = "cf_sql_timestamp"},
							createdAt = {value = local.now, cfsqltype = "cf_sql_timestamp"},
							updatedAt = {value = local.now, cfsqltype = "cf_sql_timestamp"}
						}
					);
				} catch (any e2) {
					writeLog(text = "Job enqueue failed after table creation: #e2.message#", type = "error", file = "wheels_jobs");
					return {id = local.id, jobClass = arguments.jobClass, status = "pending", persisted = false};
				}
			} else {
				writeLog(text = "Job '#arguments.jobClass#' could not be persisted: #e.message#", type = "warning", file = "wheels_jobs");
				return {id = local.id, jobClass = arguments.jobClass, status = "pending", persisted = false};
			}
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
		local.params = {
			runAt = {value = Now(), cfsqltype = "cf_sql_timestamp"},
			limit = {value = arguments.limit, cfsqltype = "cf_sql_integer"}
		};

		local.sql = "SELECT id, jobClass, queue, data, attempts, maxRetries
			FROM _wheels_jobs
			WHERE status = 'pending' AND runAt <= :runAt";

		if (Len(arguments.queue)) {
			local.sql &= " AND queue = :queue";
			local.params.queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"};
		}

		local.sql &= " ORDER BY priority DESC, runAt ASC LIMIT :limit";

		try {
			local.jobs = queryExecute(local.sql, local.params);
		} catch (any e) {
			// Auto-create table and return empty result (no jobs to process yet)
			$ensureJobTable();
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
			queryExecute(
				"UPDATE _wheels_jobs
				SET status = 'processing', attempts = attempts + 1, updatedAt = :updatedAt
				WHERE id = :id",
				{
					updatedAt = {value = Now(), cfsqltype = "cf_sql_timestamp"},
					id = {value = arguments.jobRow.id, cfsqltype = "cf_sql_varchar"}
				}
			);
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
			queryExecute(
				"UPDATE _wheels_jobs
				SET status = 'completed', completedAt = :completedAt, updatedAt = :updatedAt
				WHERE id = :id",
				{
					completedAt = {value = Now(), cfsqltype = "cf_sql_timestamp"},
					updatedAt = {value = Now(), cfsqltype = "cf_sql_timestamp"},
					id = {value = arguments.jobRow.id, cfsqltype = "cf_sql_varchar"}
				}
			);

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
				// Schedule retry with configurable exponential backoff, capped at maxDelay
				local.backoffSeconds = Min(this.baseDelay * (2 ^ local.currentAttempts), this.maxDelay);
				local.nextRunAt = DateAdd("s", local.backoffSeconds, Now());

				queryExecute(
					"UPDATE _wheels_jobs
					SET status = 'pending',
						lastError = :lastError,
						runAt = :runAt,
						updatedAt = :updatedAt
					WHERE id = :id",
					{
						lastError = {value = Left(e.message, 1000), cfsqltype = "cf_sql_longvarchar"},
						runAt = {value = local.nextRunAt, cfsqltype = "cf_sql_timestamp"},
						updatedAt = {value = Now(), cfsqltype = "cf_sql_timestamp"},
						id = {value = arguments.jobRow.id, cfsqltype = "cf_sql_varchar"}
					}
				);

				writeLog(
					text = "Job '#arguments.jobRow.jobClass#' [#arguments.jobRow.id#] failed (attempt #local.currentAttempts#/#local.maxRetries#), retrying in #local.backoffSeconds#s: #e.message#",
					type = "warning",
					file = "wheels_jobs"
				);
			} else {
				// Max retries exceeded — mark as failed (dead letter)
				queryExecute(
					"UPDATE _wheels_jobs
					SET status = 'failed',
						failedAt = :failedAt,
						lastError = :lastError,
						updatedAt = :updatedAt
					WHERE id = :id",
					{
						failedAt = {value = Now(), cfsqltype = "cf_sql_timestamp"},
						lastError = {value = Left(e.message, 1000), cfsqltype = "cf_sql_longvarchar"},
						updatedAt = {value = Now(), cfsqltype = "cf_sql_timestamp"},
						id = {value = arguments.jobRow.id, cfsqltype = "cf_sql_varchar"}
					}
				);

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
			local.sql = "SELECT status, COUNT(*) as cnt FROM _wheels_jobs";
			local.params = {};

			if (Len(arguments.queue)) {
				local.sql &= " WHERE queue = :queue";
				local.params.queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"};
			}

			local.sql &= " GROUP BY status";
			local.result = queryExecute(local.sql, local.params);

			for (local.row in local.result) {
				if (StructKeyExists(local.stats, local.row.status)) {
					local.stats[local.row.status] = local.row.cnt;
				}
				local.stats.total += local.row.cnt;
			}
		} catch (any e) {
			// Table doesn't exist yet — auto-create for next time
			$ensureJobTable();
		}

		return local.stats;
	}

	/**
	 * Retry all failed jobs.
	 * @queue Optional queue name to filter by.
	 */
	public numeric function retryFailed(string queue = "") {
		local.sql = "UPDATE _wheels_jobs
			SET status = 'pending', attempts = 0, lastError = NULL, failedAt = NULL,
				runAt = :runAt, updatedAt = :updatedAt
			WHERE status = 'failed'";
		local.params = {
			runAt = {value = Now(), cfsqltype = "cf_sql_timestamp"},
			updatedAt = {value = Now(), cfsqltype = "cf_sql_timestamp"}
		};

		if (Len(arguments.queue)) {
			local.sql &= " AND queue = :queue";
			local.params.queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"};
		}

		try {
			local.result = queryExecute(local.sql, local.params);
			return local.result.recordCount ?: 0;
		} catch (any e) {
			$ensureJobTable();
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
		local.sql = "DELETE FROM _wheels_jobs WHERE status = 'completed' AND completedAt < :cutoff";
		local.params = {
			cutoff = {value = local.cutoff, cfsqltype = "cf_sql_timestamp"}
		};

		if (Len(arguments.queue)) {
			local.sql &= " AND queue = :queue";
			local.params.queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"};
		}

		try {
			local.result = queryExecute(local.sql, local.params);
			return local.result.recordCount ?: 0;
		} catch (any e) {
			$ensureJobTable();
			return 0;
		}
	}

	/**
	 * Auto-create the _wheels_jobs table if it doesn't exist.
	 * Uses database-agnostic SQL compatible with MySQL, PostgreSQL, SQL Server, H2, and SQLite.
	 * Returns true if the table was created or already exists, false if creation failed.
	 */
	private boolean function $ensureJobTable() {
		try {
			// Check if table already exists by querying it
			queryExecute("SELECT COUNT(*) AS cnt FROM _wheels_jobs WHERE 1=0");
			return true;
		} catch (any e) {
			// Table doesn't exist — create it
		}

		try {
			queryExecute("
				CREATE TABLE _wheels_jobs (
					id VARCHAR(36) NOT NULL PRIMARY KEY,
					jobClass VARCHAR(255) NOT NULL,
					queue VARCHAR(100) NOT NULL DEFAULT 'default',
					data TEXT,
					priority INT NOT NULL DEFAULT 0,
					status VARCHAR(20) NOT NULL DEFAULT 'pending',
					attempts INT NOT NULL DEFAULT 0,
					maxRetries INT NOT NULL DEFAULT 3,
					lastError TEXT,
					runAt DATETIME,
					completedAt DATETIME,
					failedAt DATETIME,
					createdAt DATETIME,
					updatedAt DATETIME
				)
			");

			// Add indexes for efficient queue processing
			try {
				queryExecute("CREATE INDEX idx_wheels_jobs_processing ON _wheels_jobs (status, runAt, priority)");
				queryExecute("CREATE INDEX idx_wheels_jobs_queue ON _wheels_jobs (queue, status)");
				queryExecute("CREATE INDEX idx_wheels_jobs_cleanup ON _wheels_jobs (status, completedAt)");
			} catch (any indexError) {
				// Indexes are optional — don't fail if they can't be created
			}

			writeLog(text = "Auto-created _wheels_jobs table", type = "information", file = "wheels_jobs");
			return true;
		} catch (any createError) {
			writeLog(text = "Failed to auto-create _wheels_jobs table: #createError.message#", type = "error", file = "wheels_jobs");
			return false;
		}
	}
}
