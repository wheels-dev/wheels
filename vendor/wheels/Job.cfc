/**
 * Base Job class for Wheels framework.
 * Provides background job processing with database-backed persistence,
 * retry logic with exponential backoff, and priority queue support.
 *
 * The wheels_jobs table is auto-created on first use — no migration needed.
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
 *       // model() works here; sendEmail() is a controller function, so send through a mailer
 *       user = model("User").findByKey(arguments.data.userId);
 *       new app.mailers.UserMailer().sendWelcome(user);
 *     }
 *   }
 *
 *   // Enqueue from a controller:
 *   job = new app.jobs.SendWelcomeEmailJob();
 *   job.enqueue(data={userId: user.id});
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
	// false: write the job after the outermost Wheels transaction resolves, on commit or
	// rollback alike, so it survives a rollback (failure notices, audit records).
	this.transactional = true;
	// true: after a reap (its worker stopped heartbeating or died), the job is retried —
	// at-least-once, so perform() must be idempotent. false: it is not re-run; the reaped
	// attempt ends 'interrupted' (at-most-once).
	this.idempotent = true;
	// true: never two runs of this job class at once, on any server (a lease in wheels_job_locks).
	// A job can instead set this.concurrencyKey = "...", or define concurrencyKeyFor(struct data)
	// (which wins), to share one lease among the jobs with the same key. See $jobLeaseName().
	this.exclusive = false;

	/**
	 * Constructor
	 */
	public function init() {
		config();
		variables.$datasource = "";
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "dataSourceName")) {
			variables.$datasource = application.wheels.dataSourceName;
		}
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
	 * Tell the queue this job is still running. Call it from a long perform() more often than
	 * the job's timeout: the stale-job reaper measures from the latest heartbeat, so a job that
	 * heartbeats on time is never reaped and run a second time. Throws Wheels.Job.Fenced when
	 * the job's claim is gone (it was reaped and claimed again): stop working and return, since
	 * another attempt now owns the job and this one's result will be discarded. Outside a
	 * worker (perform() called directly) it does nothing. For an exclusive job (this.exclusive
	 * or a concurrency key) it also extends the run's lease, so a run that keeps heartbeating
	 * keeps its lease.
	 */
	public void function heartbeat() {
		if (!StructKeyExists(variables, "$claim") || !Len(variables.$claim.jobId)) {
			return;
		}
		local.params = {
			beatAt = {value = $now(), cfsqltype = "cf_sql_timestamp"},
			id = {value = variables.$claim.jobId, cfsqltype = "cf_sql_varchar"}
		};
		local.guard = $claimTokenGuard(claimToken = variables.$claim.claimToken, params = local.params);
		// Without the heartbeatAt column (an ALTER-blocked table), updatedAt keeps it alive instead.
		local.column = $heartbeatColumnAvailable() ? "heartbeatAt" : "updatedAt";
		queryExecute(
			"UPDATE wheels_jobs SET #local.column# = :beatAt WHERE id = :id AND status = 'processing'" & local.guard,
			local.params,
			{datasource = variables.$datasource, result = "local.beat"}
		);
		if (Val(local.beat.recordCount ?: 0) == 0) {
			$logFencedAttempt(jobId = variables.$claim.jobId, jobClass = GetMetadata(this).name, outcome = "heartbeat");
			Throw(
				type = "Wheels.Job.Fenced",
				message = "Job [#variables.$claim.jobId#] no longer holds its claim: it was reaped and claimed again while it ran.",
				extendedInfo = "Stop working and return from perform(): another attempt owns this job now, and this attempt's result will be discarded."
			);
		}
		// An exclusive run's lease lives as long as its heartbeats do.
		$renewJobLease();
	}

	/**
	 * Internal: which queue row and claim this instance is executing, so heartbeat() can renew
	 * it. Set by the worker (and processQueue) before perform() runs.
	 */
	public void function $setClaimContext(required string jobId, string claimToken = "") {
		variables.$claim = {jobId = arguments.jobId, claimToken = arguments.claimToken};
	}

	/**
	 * Internal: the exclusive lease this instance's run holds (this.exclusive or a concurrency
	 * key), so heartbeat() extends it too. Set by $runPerformExclusively() once the lease is taken.
	 */
	public void function $setLeaseContext(required string name, required string owner, required numeric windowSeconds) {
		variables.$lease = {name = arguments.name, owner = arguments.owner, windowSeconds = arguments.windowSeconds};
	}

	/**
	 * Internal: extends this run's exclusive lease by its window from now. A lease that is no
	 * longer this run's (it expired and another run took it) is logged once and left alone; the
	 * end of the run reports it as a lost lease.
	 */
	public void function $renewJobLease() {
		if (!StructKeyExists(variables, "$lease")) {
			return;
		}
		var leaseState = {renewed = true};
		try {
			local.leaseLock = $jobLeaseLock();
			leaseState.renewed = local.leaseLock.renew(
				name = variables.$lease.name,
				owner = variables.$lease.owner,
				expiresAt = local.leaseLock.nowMs() + variables.$lease.windowSeconds * 1000
			);
		} catch (any e) {
			writeLog(text = "Job lease '#variables.$lease.name#' could not be renewed: #e.message#", type = "error", file = "wheels_jobs");
			return;
		}
		if (!leaseState.renewed && !StructKeyExists(variables.$lease, "lostLogged")) {
			variables.$lease.lostLogged = true;
			writeLog(
				text = "Job lease '#variables.$lease.name#' was lost before a heartbeat could renew it: another run may be running at the same time.",
				type = "warning",
				file = "wheels_jobs"
			);
		}
	}

	/**
	 * Returns a model class object, so perform() can call model("User") as a controller does.
	 * Delegates to application.wo.model(); a job extends no controller or model base class.
	 * @name Name of the model, e.g. "User".
	 */
	public any function model(required string name) {
		return application.wo.model(name = arguments.name);
	}

	/**
	 * Enqueue this job for immediate processing.
	 * @data Job data to pass to perform().
	 * @queue Override the default queue name.
	 * @priority Override the default priority (higher = processed first).
 * @transactional `false` writes the job after the outermost Wheels-managed transaction resolves, on commit or rollback alike, so it survives a rollback. Defaults to the job's `this.transactional` (`true`).
 * @uniqueKey At most one job is written per key (up to 255 characters): an enqueue whose key is already taken returns `{enqueued: false, duplicate: true}` with the existing job's `id`. A key stays taken while its row exists, whatever its status, until it is purged. Without a key the job's own `id` is its key.
	 */
	public struct function enqueue(
		struct data = {},
		string queue = this.queue,
		numeric priority = this.priority,
		any transactional = "",
		string uniqueKey = ""
	) {
		return $enqueueJob(
			jobClass = $persistableJobClass(),
			data = arguments.data,
			queue = arguments.queue,
			priority = arguments.priority,
			runAt = $now(),
			transactional = $resolveTransactional(arguments.transactional),
			uniqueKey = arguments.uniqueKey
		);
	}

	/**
	 * Enqueue this job for processing after a delay.
	 * @seconds Number of seconds to wait before processing.
	 * @data Job data to pass to perform().
	 * @queue Override the default queue name.
	 * @priority Override the default priority.
 * @transactional [see:enqueue].
 * @uniqueKey [see:enqueue].
	 */
	public struct function enqueueIn(
		required numeric seconds,
		struct data = {},
		string queue = this.queue,
		numeric priority = this.priority,
		any transactional = "",
		string uniqueKey = ""
	) {
		return $enqueueJob(
			jobClass = $persistableJobClass(),
			data = arguments.data,
			queue = arguments.queue,
			priority = arguments.priority,
			runAt = DateAdd("s", arguments.seconds, $now()),
			transactional = $resolveTransactional(arguments.transactional),
			uniqueKey = arguments.uniqueKey
		);
	}

	/**
	 * Enqueue this job for processing at a specific time.
	 * @runAt Date/time when the job should be processed.
	 * @data Job data to pass to perform().
	 * @queue Override the default queue name.
	 * @priority Override the default priority.
 * @transactional [see:enqueue].
 * @uniqueKey [see:enqueue].
	 */
	public struct function enqueueAt(
		required date runAt,
		struct data = {},
		string queue = this.queue,
		numeric priority = this.priority,
		any transactional = "",
		string uniqueKey = ""
	) {
		return $enqueueJob(
			jobClass = $persistableJobClass(),
			data = arguments.data,
			queue = arguments.queue,
			priority = arguments.priority,
			runAt = arguments.runAt,
			transactional = $resolveTransactional(arguments.transactional),
			uniqueKey = arguments.uniqueKey
		);
	}

	/**
	 * Internal: The component path `enqueue()` persists to `wheels_jobs.jobClass`.
	 *
	 * `GetMetadata(this).name` is not safe to persist verbatim. On a case-insensitive
	 * filesystem (macOS, Windows, or a macOS checkout bind-mounted into Docker) a miscased
	 * `new app.jobs.sendwelcomeemailjob()` resolves, and Adobe CF reports the metadata name
	 * with the caller's casing rather than the file's. A row enqueued that way names a class a
	 * case-sensitive Linux worker cannot resolve (issue #3731). Canonicalize against the
	 * directory listing so the persisted string always carries the on-disk casing.
	 */
	public string function $persistableJobClass() {
		local.meta = GetMetadata(this);
		return $canonicalJobClass(name = local.meta.name, path = StructKeyExists(local.meta, "path") ? local.meta.path : "");
	}

	/**
	 * Internal: Rewrite a dotted component name so every segment that maps to a component of
	 * `path` carries that entry's casing as it exists on disk.
	 *
	 * Walks the name from its last segment (the .cfc file) up through its package directories,
	 * pairing each with the matching trailing component of `path`. For each pair, the parent
	 * directory is listed and the entry that matches case-insensitively supplies the casing (an
	 * exact match wins, so a case-sensitive filesystem holding both `Foo.cfc` and `foo.cfc` is
	 * left alone). The walk stops at the first segment that does not name its path component —
	 * a mapping whose name differs from its directory — so mapping roots are never rewritten.
	 * Any failure keeps the segment as given: this must never break an enqueue.
	 *
	 * @name The dotted component name, e.g. from `GetMetadata(obj).name`.
	 * @path The component's absolute file path, e.g. from `GetMetadata(obj).path`.
	 */
	public string function $canonicalJobClass(required string name, string path = "") {
		local.segments = ListToArray(arguments.name, ".");
		local.current = Replace(arguments.path, "\", "/", "all");
		local.segmentCount = ArrayLen(local.segments);
		if (!local.segmentCount || Right(local.current, 4) != ".cfc") {
			return arguments.name;
		}
		for (local.i = local.segmentCount; local.i >= 1; local.i--) {
			local.entryName = ListLast(local.current, "/");
			local.isLeaf = local.i == local.segmentCount;
			local.expected = local.isLeaf ? local.segments[local.i] & ".cfc" : local.segments[local.i];
			if (!Len(local.entryName) || CompareNoCase(local.entryName, local.expected) != 0) {
				break;
			}
			local.parentLength = Len(local.current) - Len(local.entryName) - 1;
			if (local.parentLength <= 0) {
				break;
			}
			local.parentDir = Left(local.current, local.parentLength);
			local.onDisk = $onDiskEntryName(directory = local.parentDir, entryName = local.entryName);
			if (Len(local.onDisk)) {
				local.segments[local.i] = local.isLeaf ? Left(local.onDisk, Len(local.onDisk) - 4) : local.onDisk;
			}
			local.current = local.parentDir;
		}
		return ArrayToList(local.segments, ".");
	}

	/**
	 * Internal: The name `entryName` has in `directory`'s listing — itself when an exact match
	 * exists, the single case-insensitive match otherwise, and "" when neither is unambiguous
	 * or the directory cannot be listed.
	 */
	public string function $onDiskEntryName(required string directory, required string entryName) {
		local.rv = "";
		local.matches = 0;
		try {
			// Iterate only: BoxLang returns a fixed-size array (cross-engine invariant 20).
			for (local.candidate in DirectoryList(arguments.directory, false, "name")) {
				if (Compare(local.candidate, arguments.entryName) == 0) {
					return local.candidate;
				}
				if (CompareNoCase(local.candidate, arguments.entryName) == 0) {
					local.matches++;
					local.rv = local.candidate;
				}
			}
		} catch (any e) {
			return "";
		}
		return local.matches == 1 ? local.rv : "";
	}

	/**
	 * Internal: A job that could not be written to the job store is an error, never a
	 * silent loss: the caller gets Wheels.Job.EnqueueFailed. A common cause is enqueueing
	 * inside a transaction on another datasource (a tenant's), which some engines refuse.
	 */
	public void function $throwEnqueueFailed(required string jobClass, required any error) {
		writeLog(text = "Job '#arguments.jobClass#' could not be persisted: #arguments.error.message#", type = "error", file = "wheels_jobs");
		Throw(
			type = "Wheels.Job.EnqueueFailed",
			message = "Job '#arguments.jobClass#' could not be written to the job store (datasource '#variables.$datasource#'): #arguments.error.message#",
			extendedInfo = "The job was not enqueued. Inside a model save or invokeWithTransaction() on another datasource (a tenant's, or a model's own dataSource()), the job is written when that transaction commits, so this error comes after the commit. A raw transaction {} block isn't tracked, and some engines refuse a second datasource inside it: enqueue after the block ends, or do the work through a model save or invokeWithTransaction(). If an enqueue is best-effort, catch Wheels.Job.EnqueueFailed."
		);
	}

	/**
	 * Internal: Writes a job row to the job store, creating the table on first use. Returns
	 * `{persisted, duplicate, id}`: when the row carries an explicit uniqueKey that another job
	 * already holds, nothing is written and `id` is that job's. Throws Wheels.Job.EnqueueFailed
	 * when the row can't be written, and Wheels.Job.UniqueKeyUnavailable when it asks for a
	 * uniqueKey on a table that can't enforce one.
	 */
	public struct function $persistJobRow(required struct row) {
		local.explicitKey = StructKeyExists(arguments.row, "explicitUniqueKey") && arguments.row.explicitUniqueKey;
		if (local.explicitKey) {
			$requireUniqueKey(jobClass = arguments.row.jobClass);
			// Checked before the INSERT so a duplicate normally never raises an INSERT error,
			// which would abort an enclosing PostgreSQL transaction.
			local.existingId = $findJobIdByUniqueKey(arguments.row.uniqueKey);
			if (Len(local.existingId)) {
				return $duplicateJobRow(row = arguments.row, existingId = local.existingId);
			}
		}
		try {
			$insertJobRow(argumentCollection = arguments.row, withUniqueKey = $uniqueKeyColumnAvailable());
			return {persisted = true, duplicate = false, id = arguments.row.id};
		} catch (any e) {
			// Lost a race to a concurrent enqueue with the same key: its row now holds the key.
			if (local.explicitKey && Len($findJobIdByUniqueKeySafely(arguments.row.uniqueKey))) {
				return $duplicateJobRow(row = arguments.row, existingId = $findJobIdByUniqueKeySafely(arguments.row.uniqueKey));
			}
			// Auto-create table on first use (or pick up a column added since) and retry
			if ($ensureJobTable()) {
				StructDelete(variables, "$uniqueKeyColumnPresent");
				try {
					$insertJobRow(argumentCollection = arguments.row, withUniqueKey = $uniqueKeyColumnAvailable());
					return {persisted = true, duplicate = false, id = arguments.row.id};
				} catch (any e2) {
					if (local.explicitKey && Len($findJobIdByUniqueKeySafely(arguments.row.uniqueKey))) {
						return $duplicateJobRow(row = arguments.row, existingId = $findJobIdByUniqueKeySafely(arguments.row.uniqueKey));
					}
					$throwEnqueueFailed(jobClass = arguments.row.jobClass, error = e2);
				}
			} else {
				$throwEnqueueFailed(jobClass = arguments.row.jobClass, error = e);
			}
		}
	}

	/**
	 * Internal: the outcome for a row whose uniqueKey another job already holds, logged so a
	 * deferred enqueue (written when its transaction resolves) still leaves a trace.
	 */
	public struct function $duplicateJobRow(required struct row, required string existingId) {
		writeLog(
			text = "Job '#arguments.row.jobClass#' was not enqueued: uniqueKey '#arguments.row.uniqueKey#' is already held by job [#arguments.existingId#]",
			type = "information",
			file = "wheels_jobs"
		);
		return {persisted = false, duplicate = true, id = arguments.existingId};
	}

	/**
	 * Internal: the duplicate check made before the INSERT — the id of the job holding
	 * `uniqueKey`, or "" when none does.
	 */
	public string function $findJobIdByUniqueKey(required string uniqueKey) {
		return $selectJobIdByUniqueKey(arguments.uniqueKey);
	}

	/**
	 * Internal: reads which job holds `uniqueKey` ("" when none does).
	 */
	public string function $selectJobIdByUniqueKey(required string uniqueKey) {
		local.rows = queryExecute(
			"SELECT id FROM wheels_jobs WHERE uniqueKey = :uniqueKey",
			{uniqueKey = {value = arguments.uniqueKey, cfsqltype = "cf_sql_varchar"}},
			{datasource = variables.$datasource}
		);
		return local.rows.recordCount ? local.rows.id : "";
	}

	/**
	 * Internal: re-reads the key after a failed INSERT to tell a lost race (another job now holds
	 * the key) from a real failure. The lookup itself can fail there (an aborted PostgreSQL
	 * transaction, a missing table); it returns "" then, so the INSERT's own error is reported.
	 */
	public string function $findJobIdByUniqueKeySafely(required string uniqueKey) {
		try {
			return $selectJobIdByUniqueKey(arguments.uniqueKey);
		} catch (any e) {
			return "";
		}
	}

	/**
	 * Internal: makes sure the table can de-duplicate on uniqueKey (creating or upgrading it if
	 * need be), or throws Wheels.Job.UniqueKeyUnavailable. Enqueuing a keyed job without the
	 * index would silently write duplicates, which is what the caller asked to prevent.
	 */
	public void function $requireUniqueKey(required string jobClass) {
		if ($uniqueKeyColumnAvailable() && $uniqueKeyIndexVerified()) {
			return;
		}
		// Inside a transaction this only looks: $ensureUniqueKeyColumn() never runs its DDL there.
		$ensureJobTable();
		StructDelete(variables, "$uniqueKeyColumnPresent");
		if ($uniqueKeyColumnAvailable() && ($uniqueKeyIndexVerified() || $jobTableHasUniqueKeyIndex())) {
			return;
		}
		writeLog(
			text = "Job '#arguments.jobClass#' was not enqueued: it has a uniqueKey and wheels_jobs has no uniqueKey column and index yet",
			type = "error",
			file = "wheels_jobs"
		);
		Throw(
			type = "Wheels.Job.UniqueKeyUnavailable",
			message = "Job '#arguments.jobClass#' was enqueued with a uniqueKey, but wheels_jobs can't enforce one yet, so it was not enqueued.",
			extendedInfo = ($jobSchema().autoCreateEnabled() ? "" : $jobSchema().missingSchemaMessage("The wheels_jobs uniqueKey column or index") & " ") & "wheels_jobs needs a uniqueKey column (VARCHAR(255), nullable) with a unique index. The framework adds them on a worker poll or an enqueue(uniqueKey=...) made outside a transaction, unless the database user can't ALTER the table or another instance is upgrading it right now. " & $uniqueKeyLastProblem() & $uniqueKeyManualFix()
		);
	}

	/**
	 * Internal: the `transactional` argument as a boolean; an empty value means the job's
	 * `this.transactional` default.
	 */
	public boolean function $resolveTransactional(any transactional = "") {
		if (IsBoolean(arguments.transactional)) {
			return arguments.transactional;
		}
		return !StructKeyExists(this, "transactional") || !IsBoolean(this.transactional) || this.transactional;
	}

	/**
	 * Internal: the callback-queue key of the outermost open Wheels-managed transaction (the first
	 * real owner on the owner stack), or "" when none is open. It resolves last, so a job queued on
	 * it is written after every nested transaction has resolved too.
	 */
	public string function $outermostWheelsTransaction() {
		if (
			!StructKeyExists(request, "wheels")
			|| !StructKeyExists(request.wheels, "$txnOwnerStack")
			|| !StructKeyExists(request.wheels, "$txnCallbacks")
		) {
			return "";
		}
		for (local.key in request.wheels.$txnOwnerStack) {
			if (
				StructKeyExists(request.wheels.$txnCallbacks, local.key)
				&& IsStruct(request.wheels.$txnCallbacks[local.key])
				&& StructKeyExists(request.wheels.$txnCallbacks[local.key], "real")
				&& request.wheels.$txnCallbacks[local.key].real
			) {
				return local.key;
			}
		}
		return "";
	}

	/**
	 * Internal: When the innermost open Wheels-managed transaction writes to a datasource
	 * other than the job store's (a tenant's, for a model that isn't shared), its
	 * callback-queue key; otherwise "". Only then is an enqueue deferred to the commit: a
	 * transaction on the job store's own datasource is joined. A raw transaction {} is not
	 * tracked by Wheels, so it is not covered.
	 */
	public string function $crossDatasourceTransaction() {
		if (
			!StructKeyExists(request, "wheels")
			|| !StructKeyExists(request.wheels, "$txnOwnerStack")
			|| !StructKeyExists(request.wheels, "$txnCallbacks")
		) {
			return "";
		}
		local.stack = request.wheels.$txnOwnerStack;
		for (local.i = ArrayLen(local.stack); local.i >= 1; local.i--) {
			local.key = local.stack[local.i];
			if (!StructKeyExists(request.wheels.$txnCallbacks, local.key)) {
				continue;
			}
			local.store = request.wheels.$txnCallbacks[local.key];
			if (IsStruct(local.store) && StructKeyExists(local.store, "real") && local.store.real && StructKeyExists(local.store, "dataSource")) {
				return CompareNoCase(local.store.dataSource, variables.$datasource) == 0 ? "" : local.key;
			}
		}
		return "";
	}

	/**
	 * Internal: Persist a job to the queue table.
	 */
	private struct function $enqueueJob(
		required string jobClass,
		required struct data,
		required string queue,
		required numeric priority,
		required date runAt,
		boolean transactional = true,
		string uniqueKey = ""
	) {
		if (Len(arguments.uniqueKey) > 255) {
			Throw(
				type = "Wheels.Job.InvalidUniqueKey",
				message = "A job's uniqueKey can be at most 255 characters; this one has #Len(arguments.uniqueKey)#.",
				extendedInfo = "The key is stored in wheels_jobs.uniqueKey (VARCHAR(255)) under a unique index. Hash a longer natural key, for example Hash(longKey, ""SHA-256"")."
			);
		}
		local.id = CreateUUID();

		// Work on a copy so the internal keys below are never added to the caller's
		// struct — CFML passes structs by reference, so mutating arguments.data would
		// mutate what the caller passed to enqueue() / enqueueIn() / enqueueAt() (#3887).
		// StructCopy (shallow) is enough because only top-level keys are added, and it
		// avoids Duplicate's deep copy of payload values (engine-picky with Java objects).
		arguments.data = StructCopy(arguments.data);
		arguments.data["$wheelsJobTimeout"] = this.timeout;

		// Capture tenant context so jobs run against the correct tenant datasource.
		// Persist id + dataSource only — never dump tenant.config into the queue row.
		if (
			IsDefined("request.wheels.tenant.dataSource")
			&& Len(request.wheels.tenant.dataSource)
		) {
			arguments.data["$wheelsTenantContext"] = {
				id = StructKeyExists(request.wheels.tenant, "id") ? request.wheels.tenant.id : "",
				dataSource = request.wheels.tenant.dataSource
			};
		}

		local.serializedData = SerializeJSON(arguments.data);
		local.now = $now();

		local.row = {
			id = local.id,
			jobClass = arguments.jobClass,
			queue = arguments.queue,
			serializedData = local.serializedData,
			priority = arguments.priority,
			runAt = arguments.runAt,
			enqueuedAt = local.now,
			// Without a key the job's own id is its key, so it never collides.
			uniqueKey = Len(arguments.uniqueKey) ? arguments.uniqueKey : local.id,
			explicitUniqueKey = Len(arguments.uniqueKey) > 0
		};

		// transactional = false: write the job after the outermost Wheels-managed transaction
		// resolves, on commit or rollback alike. With no such transaction it's written now.
		if (!arguments.transactional) {
			local.outermost = $outermostWheelsTransaction();
			if (Len(local.outermost)) {
				ArrayAppend(
					request.wheels.$txnCallbacks[local.outermost].queue,
					{object = new wheels.JobDeferredEnqueue(job = this, row = local.row, durable = true), operation = "enqueue", durable = true}
				);
				writeLog(
					text = "Job '#arguments.jobClass#' [#local.id#] for queue '#arguments.queue#' will be enqueued when the open transaction ends, whether it commits or rolls back",
					type = "information",
					file = "wheels_jobs"
				);
				return {id = local.id, jobClass = arguments.jobClass, status = "deferred", persisted = false, deferred = true, enqueued = true, duplicate = false};
			}
			return $enqueueResult(row = local.row, outcome = $persistJobRow(local.row));
		}

		// Inside a Wheels-managed transaction on another datasource (a tenant's), the job
		// is written when that transaction commits and dropped if it rolls back, so the job
		// store is never written inside a transaction on a different datasource.
		local.deferTo = $crossDatasourceTransaction();
		if (Len(local.deferTo)) {
			ArrayAppend(
				request.wheels.$txnCallbacks[local.deferTo].queue,
				{object = new wheels.JobDeferredEnqueue(job = this, row = local.row), operation = "enqueue"}
			);
			writeLog(
				text = "Job '#arguments.jobClass#' [#local.id#] for queue '#arguments.queue#' will be enqueued when the open transaction commits",
				type = "information",
				file = "wheels_jobs"
			);
			return {id = local.id, jobClass = arguments.jobClass, status = "deferred", persisted = false, deferred = true, enqueued = true, duplicate = false};
		}

		local.outcome = $persistJobRow(local.row);
		if (!local.outcome.duplicate) {
			writeLog(
				text = "Job '#arguments.jobClass#' [#local.id#] enqueued to queue '#arguments.queue#' with priority #arguments.priority#",
				type = "information",
				file = "wheels_jobs"
			);
		}
		return $enqueueResult(row = local.row, outcome = local.outcome);
	}

	/**
	 * Internal: what enqueue() returns for a row written now — the new job, or, when its
	 * uniqueKey was already taken, the existing job's id with `enqueued: false, duplicate: true`.
	 */
	public struct function $enqueueResult(required struct row, required struct outcome) {
		if (arguments.outcome.duplicate) {
			return {id = arguments.outcome.id, jobClass = arguments.row.jobClass, status = "duplicate", persisted = false, enqueued = false, duplicate = true};
		}
		return {id = arguments.row.id, jobClass = arguments.row.jobClass, status = "pending", persisted = true, enqueued = true, duplicate = false};
	}

	/**
	 * Internal: Execute the wheels_jobs INSERT for a new pending job.
	 * Shared by the first-attempt and table-create-retry paths in $enqueueJob.
	 */
	private void function $insertJobRow(
		required string id,
		required string jobClass,
		required string queue,
		required string serializedData,
		required numeric priority,
		required date runAt,
		required date enqueuedAt,
		string uniqueKey = "",
		boolean withUniqueKey = false
	) {
		local.keyColumn = arguments.withUniqueKey ? ", uniqueKey" : "";
		local.keyValue = arguments.withUniqueKey ? ", :uniqueKey" : "";
		local.params = {
			id = {value = arguments.id, cfsqltype = "cf_sql_varchar"},
			jobClass = {value = arguments.jobClass, cfsqltype = "cf_sql_varchar"},
			queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"},
			data = {value = arguments.serializedData, cfsqltype = "cf_sql_longvarchar"},
			priority = {value = arguments.priority, cfsqltype = "cf_sql_integer"},
			maxRetries = {value = this.maxRetries, cfsqltype = "cf_sql_integer"},
			runAt = {value = arguments.runAt, cfsqltype = "cf_sql_timestamp"},
			createdAt = {value = arguments.enqueuedAt, cfsqltype = "cf_sql_timestamp"},
			updatedAt = {value = arguments.enqueuedAt, cfsqltype = "cf_sql_timestamp"}
		};
		if (arguments.withUniqueKey) {
			local.params.uniqueKey = {value = Len(arguments.uniqueKey) ? arguments.uniqueKey : arguments.id, cfsqltype = "cf_sql_varchar"};
		}
		queryExecute(
			"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt" & local.keyColumn & ")
			VALUES (:id, :jobClass, :queue, :data, :priority, 'pending', 0, :maxRetries, :runAt, :createdAt, :updatedAt" & local.keyValue & ")",
			local.params,
			{datasource = variables.$datasource}
		);
	}

	/**
	 * Process pending jobs from the queue. Call this from a scheduled task or controller action.
	 * It runs through the job worker, like `wheels jobs work`: every call first reaps jobs left
	 * in 'processing' by a worker that died, and each job is claimed and run with its own
	 * class's timeout, recorded on the row so no other server reaps it early.
	 * @queue Queue name(s) to process, comma-delimited. Default processes all queues.
	 * @limit Maximum number of jobs to process in this batch. `0` (or less) means no limit: every due job is processed.
	 * @timeout Optional cap, in seconds, on each job's own timeout. `0` (default) uses each job's own.
	 */
	public struct function processQueue(string queue = "", numeric limit = 10, numeric timeout = 0) {
		local.result = {processed = 0, failed = 0, skipped = 0, fenced = 0, leasesLost = 0, errors = []};
		local.worker = new wheels.JobWorker();
		local.worker.perJobTimeout = true;
		local.worker.timeoutCap = Val(arguments.timeout) > 0 ? Val(arguments.timeout) : 0;
		// The poll's own timeout: the reap window for rows that recorded none, and the timeout
		// for a job whose class can't be loaded.
		local.pollTimeout = local.worker.timeoutCap > 0 ? local.worker.timeoutCap : this.timeout;
		// A row that recorded no claimTimeout may still be running under its own (longer)
		// timeout, so it is never reaped inside this job's timeout, whatever the cap.
		local.worker.legacyReapTimeout = Max(local.worker.timeoutCap, this.timeout);
		local.max = Val(arguments.limit) > 0 ? Int(Val(arguments.limit)) : 0;
		local.lastJobId = "";
		while (local.max == 0 || local.result.processed + local.result.failed + local.result.fenced < local.max) {
			local.outcome = local.worker.processNext(queues = arguments.queue, timeout = local.pollTimeout);
			if (!Len(local.outcome.jobId)) {
				// Nothing ready (or a database error before any job was claimed).
				if (Len(local.outcome.error)) {
					ArrayAppend(local.result.errors, local.outcome.error);
				}
				break;
			}
			if (local.outcome.jobId == local.lastJobId) {
				// The same job again (its claim keeps failing): stop rather than loop.
				break;
			}
			local.lastJobId = local.outcome.jobId;
			if (local.outcome.leaseLost) {
				local.result.leasesLost++;
			}
			if (local.outcome.deferred) {
				// Another run holds its lease: put back as pending without using an attempt.
				local.result.skipped++;
			} else if (local.outcome.fenced) {
				local.result.fenced++;
			} else if (local.outcome.success) {
				local.result.processed++;
			} else {
				local.result.failed++;
				ArrayAppend(local.result.errors, "Job #local.outcome.jobId# (#local.outcome.jobClass#): #local.outcome.error#");
			}
		}
		return local.result;
	}

	/**
	 * Internal: Turn a persisted `jobClass` string back into a job instance.
	 *
	 * `jobClass` is written on enqueue by `$persistableJobClass()` and read back here as a
	 * component path, so the round trip depends on that string still resolving — including its
	 * casing, on a case-sensitive filesystem. Lucee derives the metadata name from the file, but
	 * Adobe echoes a miscased caller's path when the filesystem lets it resolve (#3731), so the
	 * enqueue side canonicalizes against the directory listing; JobClassRoundTripSpec pins it.
	 *
	 * When it does not resolve, the raw engine error is `component not found` for a class that
	 * plainly exists on disk, which sends people to look at mappings and deployment. Name the
	 * real shape of the problem instead: a string read out of a queue row (issue #3351).
	 *
	 * @jobClass The component path as persisted in wheels_jobs.
	 * @jobId The queue row's id, for the error message. Optional.
	 */
	public any function $instantiateJobClass(required string jobClass, string jobId = "") {
		local.rowLabel = Len(arguments.jobId) ? " named by queue row [#arguments.jobId#]" : "";
		if (!$isAllowedJobClass(arguments.jobClass)) {
			Throw(
				type = "Wheels.JobClassNotAllowed",
				message = "The job class `#arguments.jobClass#`#local.rowLabel# is not on an allowed jobs path.",
				extendedInfo = "CreateObject is restricted to `app.jobs` (and any `jobClassPrefixes` you configure). A `perform()` method is not enough."
			);
		}
		try {
			local.rv = CreateObject("component", arguments.jobClass);
		} catch (any e) {
			Throw(
				type = "Wheels.JobClassNotFound",
				message = "The job class `#arguments.jobClass#`#local.rowLabel# could not be instantiated: #e.message#",
				extendedInfo = "This path was persisted to `wheels_jobs.jobClass` when the job was enqueued and is resolved as a component path now. If the file exists, compare its name and directories to the string above CHARACTER BY CHARACTER — component paths are case-sensitive on Linux but not on macOS or Windows, so a casing mismatch resolves in development and fails in production. It also fails if the job class was renamed, moved, or deleted while rows referencing it were still queued."
			);
		}
		// A job row names something to instantiate and then call perform() on. Anything without
		// perform() is not a job, and failing here says so rather than failing later inside the
		// job's own execution where it reads as a job bug. Note this narrows but does not close
		// the database-string-to-CreateObject shape the issue flags: the actual guarantee is that
		// only $enqueueJob writes this column.
		if (!StructKeyExists(local.rv, "perform")) {
			Throw(
				type = "Wheels.InvalidJobClass",
				message = "The component `#arguments.jobClass#`#local.rowLabel# is not a job — it has no `perform()` method.",
				extendedInfo = "`wheels_jobs.jobClass` must name a component extending `wheels.Job`. Only the framework writes this column; a value that names something else means the row was written by something other than `enqueue()`."
			);
		}
		if (StructKeyExists(local.rv, "init")) {
			local.rv.init();
		}
		return local.rv;
	}

	/**
	 * Internal: Process a single job row.
	 */
	private struct function $processJob(required struct jobRow) {
		local.result = {success = false, skipped = false, fenced = false, leaseLost = false, error = ""};
		// The retry/fail UPDATEs run inside a catch, where a local. write doesn't survive on
		// BoxLang, so a fenced outcome there is carried out through this struct.
		var fence = {lost = false};
		// The failure the hooks report, filled in by the same catch (so not through local.).
		var failure = {recorded = false, isFinal = false, attempt = 0, type = "", message = "", detail = ""};

		// Each claim writes a fresh token; this attempt may only complete, retry or fail the
		// job while the row still carries it (a reaped-and-re-claimed row carries another).
		local.claimToken = $claimTokenColumnsAvailable() ? $newClaimToken() : "";

		// Mark as processing using optimistic locking: the status guard ensures only
		// one concurrent worker can claim the job. Use the result option to get the
		// affected-row count from the same connection that executed the UPDATE. A
		// separate verification SELECT can fail on BoxLang + PostgreSQL when the
		// connection pool hands out a different connection that cannot see the
		// uncommitted UPDATE.
		local.claimParams = {
			updatedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"},
			id = {value = arguments.jobRow.id, cfsqltype = "cf_sql_varchar"}
		};
		// A new claim starts with no heartbeat, so an earlier attempt's can't make it look stale.
		local.setClaim = $heartbeatColumnAvailable() ? ", heartbeatAt = NULL" : "";
		if (Len(local.claimToken)) {
			local.setClaim &= ", claimToken = :claimToken, claimedBy = :claimedBy";
			local.claimParams.claimToken = {value = local.claimToken, cfsqltype = "cf_sql_varchar"};
			local.claimParams.claimedBy = {value = $jobHostName(), cfsqltype = "cf_sql_varchar"};
		}
		try {
			queryExecute(
				"UPDATE wheels_jobs
				SET status = 'processing', attempts = attempts + 1, updatedAt = :updatedAt" & local.setClaim & "
				WHERE id = :id AND status = 'pending'",
				local.claimParams,
				{datasource = variables.$datasource, result = "local.updateResult"}
			);
			if ((local.updateResult.recordCount ?: 0) == 0) {
				// Another worker already claimed this job — skip without executing
				local.result.skipped = true;
				return local.result;
			}
		} catch (any e) {
			local.result.error = "Failed to lock job #arguments.jobRow.id#: #e.message#";
			return local.result;
		}

		// Initialized before the try: the catch below also handles instantiation and
		// deserialization failures, and the tenant cleanup after it must not read an
		// undefined variable (which would escape $processJob and abort the whole batch,
		// masking the real job failure).
		local.hasTenantContext = false;

		// Backoff settings for retry scheduling. Defaults come from this processing
		// instance; overridden from the failing job's own class once it instantiates,
		// mirroring JobWorker.$scheduleRetry so both paths share one retry schedule.
		local.backoff = $backoffSettings(this);

		try {
			// Instantiate and execute the job
			local.jobInstance = $instantiateJobClass(jobClass = arguments.jobRow.jobClass, jobId = arguments.jobRow.id);
			local.jobInstance.$setClaimContext(jobId = arguments.jobRow.id, claimToken = local.claimToken);
			local.backoff = $backoffSettings(local.jobInstance);
			local.jobData = DeserializeJSON(arguments.jobRow.data);

			// Restore tenant context if the job was enqueued within a tenant scope and
			// strip the internal $wheelsTenantContext key before passing data to perform()
			local.hasTenantContext = $restoreTenantContext(local.jobData);
			local.timeoutSeconds = $takeJobTimeout(local.jobData, local.jobInstance.timeout ?: 300);
			local.performOutcome = $runPerformExclusively(
				jobInstance = local.jobInstance,
				jobData = local.jobData,
				timeoutSeconds = local.timeoutSeconds,
				jobId = arguments.jobRow.id,
				jobClass = arguments.jobRow.jobClass,
				claimToken = local.claimToken,
				claimTimeout = local.timeoutSeconds
			);
			if (local.performOutcome.busy) {
				// Another run holds the job's lease: wait for it without using up an attempt.
				$deferBusyRun(jobRow = arguments.jobRow, claimToken = local.claimToken, performOutcome = local.performOutcome, clearTenant = local.hasTenantContext);
				local.result.skipped = true;
				return local.result;
			}
			local.result.leaseLost = local.performOutcome.leaseLost;
			if (local.performOutcome.timedOut) {
				throw(type = "Wheels.JobTimeout", message = local.performOutcome.error);
			}
			if (!local.performOutcome.success) {
				failure.type = local.performOutcome.errorType;
				failure.detail = local.performOutcome.errorDetail;
				throw(type = "Wheels.JobFailed", message = local.performOutcome.error);
			}

			// Mark as completed — only while the row is still this attempt's claim
			local.doneParams = {
				completedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"},
				updatedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"},
				id = {value = arguments.jobRow.id, cfsqltype = "cf_sql_varchar"}
			};
			local.doneGuard = $claimTokenGuard(claimToken = local.claimToken, params = local.doneParams);
			local.resultSet = $resultAssignment(performOutcome = local.performOutcome, params = local.doneParams);
			queryExecute(
				"UPDATE wheels_jobs
				SET status = 'completed', completedAt = :completedAt, updatedAt = :updatedAt" & local.resultSet & "
				WHERE id = :id AND status = 'processing'" & local.doneGuard,
				local.doneParams,
				{datasource = variables.$datasource, result = "local.doneResult"}
			);

			if (Len(local.claimToken) && Val(local.doneResult.recordCount ?: 0) == 0) {
				$logFencedAttempt(jobId = arguments.jobRow.id, jobClass = arguments.jobRow.jobClass, outcome = "completed");
				local.result.fenced = true;
				local.result.error = "Job #arguments.jobRow.id# (#arguments.jobRow.jobClass#): Wheels.Job.Fenced, its claim was reaped before it completed";
			} else {
				writeLog(
					text = "Job '#arguments.jobRow.jobClass#' [#arguments.jobRow.id#] completed successfully",
					type = "information",
					file = "wheels_jobs"
				);
				local.result.success = true;
				$fireJobSuccess(
					jobInstance = local.jobInstance,
					performOutcome = local.performOutcome,
					jobId = arguments.jobRow.id,
					jobClass = arguments.jobRow.jobClass
				);
			}

		} catch (any e) {
			// Determine retry eligibility
			local.currentAttempts = Val(arguments.jobRow.attempts) + 1;
			local.maxRetries = Val(arguments.jobRow.maxRetries);
			failure.attempt = local.currentAttempts;
			failure.message = e.message;
			if (!Len(failure.type)) {
				failure.type = e.type;
			}

			if (local.currentAttempts <= local.maxRetries) {
				// Schedule retry with configurable exponential backoff, capped at maxDelay.
				// Settings were captured from the failing job's class above so subclass
				// overrides apply (the base instance defaults are only the fallback).
				local.backoffSeconds = $backoffDelay(
					attempts = local.currentAttempts,
					baseDelay = local.backoff.baseDelay,
					maxDelay = local.backoff.maxDelay,
					retryBackoff = local.backoff.retryBackoff
				);
				local.nextRunAt = DateAdd("s", local.backoffSeconds, $now());

				local.retryParams = {
					lastError = {value = Left(e.message, 1000), cfsqltype = "cf_sql_longvarchar"},
					runAt = {value = local.nextRunAt, cfsqltype = "cf_sql_timestamp"},
					updatedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"},
					id = {value = arguments.jobRow.id, cfsqltype = "cf_sql_varchar"}
				};
				local.retryGuard = $claimTokenGuard(claimToken = local.claimToken, params = local.retryParams);
				// A requeued row is nobody's claim: drop the token with it.
				local.clearToken = Len(local.claimToken) ? ", claimToken = NULL" : "";
				queryExecute(
					"UPDATE wheels_jobs
					SET status = 'pending',
						lastError = :lastError,
						runAt = :runAt,
						updatedAt = :updatedAt" & local.clearToken & "
					WHERE id = :id AND status = 'processing'" & local.retryGuard,
					local.retryParams,
					{datasource = variables.$datasource, result = "local.retryResult"}
				);
				if (Len(local.claimToken) && Val(local.retryResult.recordCount ?: 0) == 0) {
					fence.lost = true;
					$logFencedAttempt(jobId = arguments.jobRow.id, jobClass = arguments.jobRow.jobClass, outcome = "failed, retry");
				} else {
					failure.recorded = true;
				}

				writeLog(
					text = "Job '#arguments.jobRow.jobClass#' [#arguments.jobRow.id#] failed (attempt #local.currentAttempts#/#local.maxRetries#), retrying in #local.backoffSeconds#s: #e.message#",
					type = "warning",
					file = "wheels_jobs"
				);
			} else {
				// Max retries exceeded — mark as failed (dead letter)
				local.failParams = {
					failedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"},
					lastError = {value = Left(e.message, 1000), cfsqltype = "cf_sql_longvarchar"},
					updatedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"},
					id = {value = arguments.jobRow.id, cfsqltype = "cf_sql_varchar"}
				};
				local.failGuard = $claimTokenGuard(claimToken = local.claimToken, params = local.failParams);
				queryExecute(
					"UPDATE wheels_jobs
					SET status = 'failed',
						failedAt = :failedAt,
						lastError = :lastError,
						updatedAt = :updatedAt
					WHERE id = :id AND status = 'processing'" & local.failGuard,
					local.failParams,
					{datasource = variables.$datasource, result = "local.failResult"}
				);
				if (Len(local.claimToken) && Val(local.failResult.recordCount ?: 0) == 0) {
					fence.lost = true;
					$logFencedAttempt(jobId = arguments.jobRow.id, jobClass = arguments.jobRow.jobClass, outcome = "failed");
				} else {
					failure.recorded = true;
					failure.isFinal = true;
				}

				writeLog(
					text = "Job '#arguments.jobRow.jobClass#' [#arguments.jobRow.id#] permanently failed after #local.currentAttempts# attempts (#local.maxRetries# retries): #e.message#",
					type = "error",
					file = "wheels_jobs"
				);
			}

			local.result.error = "Job #arguments.jobRow.id# (#arguments.jobRow.jobClass#): #e.message#";
		}

		if (fence.lost) {
			local.result.fenced = true;
		}
		if (failure.recorded) {
			$fireJobFailure(
				jobInstance = StructKeyExists(local, "jobInstance") ? local.jobInstance : "",
				jobId = arguments.jobRow.id,
				jobClass = arguments.jobRow.jobClass,
				queue = StructKeyExists(arguments.jobRow, "queue") ? arguments.jobRow.queue : "",
				error = $jobError(type = failure.type, message = failure.message, detail = failure.detail),
				attempt = failure.attempt,
				maxRetries = Val(arguments.jobRow.maxRetries),
				isFinal = failure.isFinal
			);
		}

		// Clean up tenant context after job execution
		if (local.hasTenantContext) {
			$clearTenantContext();
		}

		return local.result;
	}

	/**
	 * Internal: a job's retry backoff settings (baseDelay, maxDelay, retryBackoff), so a failing
	 * job's own class overrides apply to its retry schedule.
	 */
	public struct function $backoffSettings(required any jobInstance) {
		return {
			baseDelay = StructKeyExists(arguments.jobInstance, "baseDelay") ? arguments.jobInstance.baseDelay : this.baseDelay,
			maxDelay = StructKeyExists(arguments.jobInstance, "maxDelay") ? arguments.jobInstance.maxDelay : this.maxDelay,
			retryBackoff = StructKeyExists(arguments.jobInstance, "retryBackoff") ? arguments.jobInstance.retryBackoff : this.retryBackoff
		};
	}

	/**
	 * Internal: puts back a run whose lease another run holds ($deferJobForLease), and clears the
	 * tenant context it restored, since perform() never ran.
	 */
	public void function $deferBusyRun(required struct jobRow, required string claimToken, required struct performOutcome, required boolean clearTenant) {
		$deferJobForLease(
			jobId = arguments.jobRow.id,
			jobClass = arguments.jobRow.jobClass,
			claimToken = arguments.claimToken,
			delaySeconds = arguments.performOutcome.retryInSeconds,
			leaseName = arguments.performOutcome.leaseName
		);
		if (arguments.clearTenant) {
			$clearTenantContext();
		}
	}

	/**
	 * Restore tenant context from job data when the job was enqueued within a tenant
	 * scope, and strip the internal $wheelsTenantContext key from the passed data
	 * struct (by reference) before it reaches perform(). Returns true when a tenant
	 * context was restored — the caller must $clearTenantContext() after execution.
	 * Public with $ prefix so JobWorker's worker path shares the exact same logic.
	 */
	public boolean function $restoreTenantContext(required struct jobData) {
		local.restored = false;
		if (StructKeyExists(arguments.jobData, "$wheelsTenantContext") && IsStruct(arguments.jobData["$wheelsTenantContext"])) {
			local.tenantCtx = arguments.jobData["$wheelsTenantContext"];
			local.ds = StructKeyExists(local.tenantCtx, "dataSource") ? ToString(local.tenantCtx.dataSource) : "";
			if (Len(local.ds) && $isAllowedJobDataSource(local.ds)) {
				if (!StructKeyExists(request, "wheels")) {
					request.wheels = {};
				}
				request.wheels.tenant = {
					id = StructKeyExists(local.tenantCtx, "id") ? local.tenantCtx.id : "",
					dataSource = local.ds
				};
				local.restored = true;
			}
			StructDelete(arguments.jobData, "$wheelsTenantContext");
		}
		return local.restored;
	}

	/**
	 * Remove a previously restored tenant context from the request scope.
	 */
	public void function $clearTenantContext() {
		if (StructKeyExists(request, "wheels")) {
			StructDelete(request.wheels, "tenant");
		}
	}

	/**
	 * Get the count of jobs by status.
	 * @queue Optional queue name to filter by.
	 */
	public struct function queueStats(string queue = "") {
		local.stats = {pending = 0, processing = 0, completed = 0, failed = 0, interrupted = 0, total = 0};

		try {
			local.sql = "SELECT status, COUNT(*) as cnt FROM wheels_jobs";
			local.params = {};

			if (Len(arguments.queue)) {
				local.sql &= " WHERE queue = :queue";
				local.params.queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"};
			}

			local.sql &= " GROUP BY status";
			local.result = queryExecute(local.sql, local.params, {datasource = variables.$datasource});

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
		local.sql = "UPDATE wheels_jobs
			SET status = 'pending', attempts = 0, lastError = NULL, failedAt = NULL,
				runAt = :runAt, updatedAt = :updatedAt
			WHERE status = 'failed'";
		local.params = {
			runAt = {value = $now(), cfsqltype = "cf_sql_timestamp"},
			updatedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"}
		};

		if (Len(arguments.queue)) {
			local.sql &= " AND queue = :queue";
			local.params.queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"};
		}

		try {
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
	 * Purge completed jobs older than the specified number of days.
	 * @days Number of days to keep completed jobs.
	 * @queue Optional queue name to filter by.
	 */
	public numeric function purgeCompleted(numeric days = 7, string queue = "") {
		local.cutoff = DateAdd("d", -arguments.days, $now());
		local.sql = "DELETE FROM wheels_jobs WHERE status = 'completed' AND completedAt < :cutoff";
		local.params = {
			cutoff = {value = local.cutoff, cfsqltype = "cf_sql_timestamp"}
		};

		if (Len(arguments.queue)) {
			local.sql &= " AND queue = :queue";
			local.params.queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"};
		}

		try {
			local.countSql = "SELECT COUNT(*) AS cnt FROM wheels_jobs WHERE status = 'completed' AND completedAt < :cutoff";
			local.countParams = {cutoff = {value = local.cutoff, cfsqltype = "cf_sql_timestamp"}};
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
	 * Auto-create the wheels_jobs table if it doesn't exist.
	 * Uses database-agnostic SQL compatible with MySQL, PostgreSQL, SQL Server, H2, and SQLite.
	 * Returns true if the table was created or already exists, false if creation failed.
	 * Public with $ prefix so JobWorker can bootstrap the table on a fresh database.
	 */
	public boolean function $ensureJobTable() {
		try {
			// Check if table already exists by querying it
			queryExecute("SELECT COUNT(*) AS cnt FROM wheels_jobs WHERE 1=0", {}, {datasource = variables.$datasource});
			// With auto-create off the schema is the app's (its `wheels jobs install` migration):
			// no column upgrades run here.
			if (!$jobSchema().autoCreateEnabled()) {
				return true;
			}
			// Table exists — make sure the claimTimeout column exists too (#3989). Probed on
			// every call and never cached: a shared or rebuilt dev DB can lose it (see #2780).
			$ensureClaimTimeoutColumn();
			$ensureClaimTokenColumns();
			$ensureUniqueKeyColumn();
			$ensureHeartbeatColumn();
			$ensureResultColumn();
			return true;
		} catch (any e) {
			// Table doesn't exist — create it
		}

		if (!$jobSchema().autoCreateEnabled()) {
			// The probe can fail for reasons other than a missing table (a lost connection, a
			// permission). Only the catalog's answer makes it a missing schema; otherwise run the
			// probe again here, so its own error is what the caller sees.
			if (!$jobSchema().hasTable("wheels_jobs")) {
				$throwJobSchemaMissing("The wheels_jobs table");
			}
			queryExecute("SELECT COUNT(*) AS cnt FROM wheels_jobs WHERE 1=0", {}, {datasource = variables.$datasource});
			return true;
		}

		try {
			// Detect actual database type from the datasource via JDBC metadata.
			// We query the datasource directly rather than using application.wheels.adapterName
			// because the adapter may have been detected from a different datasource.
			local.dbType = $detectDatabaseType();
			local.schema = $jobSchema();
			queryExecute(local.schema.createTableSql(tableName = "wheels_jobs", dbType = local.dbType), {}, {datasource = variables.$datasource});

			// Indexes for efficient queue processing are optional: don't fail if one can't be
			// created. The uniqueKey index is not optional: it is what de-duplicates
			// enqueue(uniqueKey=). If it can't be built now, the next $ensureJobTable() retries it
			// (the column is there, the index isn't), and enqueue(uniqueKey=) refuses to run without it.
			for (local.index in local.schema.tableDef("wheels_jobs").indexes) {
				try {
					queryExecute(local.schema.indexSql(tableName = "wheels_jobs", indexName = local.index.name, dbType = local.dbType), {}, {datasource = variables.$datasource});
					if (local.index.name == "idx_wjobs_unique_key") {
						$recordUniqueKeyIndexVerified();
					}
				} catch (any indexError) {
					if (!local.index.optional) {
						writeLog(text = "Could not create the wheels_jobs index #local.index.name#: #indexError.message#", type = "error", file = "wheels_jobs");
					}
				}
			}

			writeLog(text = "Auto-created wheels_jobs table", type = "information", file = "wheels_jobs");
			return true;
		} catch (any createError) {
			writeLog(text = "Failed to auto-create wheels_jobs table: #createError.message#", type = "error", file = "wheels_jobs");
			return false;
		}
	}

	/**
	 * Add the claimTimeout column to an existing wheels_jobs table when it is missing, so a
	 * table created before #3989 is upgraded in place. Probed every call (no cached flag);
	 * if the ALTER can't run (permissions, race, unsupported) it logs once and the reaper
	 * falls back to the poller's timeout — a missing/NULL claimTimeout is always tolerated.
	 */
	public void function $ensureClaimTimeoutColumn() {
		// DDL inside an open transaction makes MySQL and Oracle commit the caller's work, so the
		// column is never added there (an INSERT failure's table-ensure runs inside the caller's
		// transaction). A worker poll or a call outside a transaction adds it.
		if (!$jobSchema().autoCreateEnabled()) {
			return;
		}
		if (Len($outermostWheelsTransaction())) {
			return;
		}
		if ($jobTableHasClaimTimeout()) {
			// Column present (possibly added out of band): forget any past ALTER failure.
			$clearClaimTimeoutAlterMemo();
			return;
		}
		// CliBridge builds a fresh JobWorker per poll, so the per-instance ensure runs every
		// poll. A DB user without ALTER privilege would otherwise re-fire the failing DDL each
		// poll. After a failed ALTER, back off for a bounded window before re-attempting. This
		// is TIME-BOUNDED, never a permanent "gave up" flag: the probe above still runs every
		// call, and the ALTER is retried once the window elapses (a later GRANT or manual ALTER
		// is then picked up) — consistent with #2780's re-probe rule (#4071).
		if ($claimTimeoutAlterInBackoff()) {
			return;
		}
		try {
			queryExecute($claimTimeoutAlterSql(), {}, {datasource = variables.$datasource});
			$clearClaimTimeoutAlterMemo();
		} catch (any e) {
			$recordClaimTimeoutAlterFailure();
			$warnClaimTimeoutAlterFailedOnce(e.message);
		}
	}

	/**
	 * Seconds to wait before retrying a failed claimTimeout ALTER. Bounded on purpose so a
	 * DB user without ALTER privilege re-attempts periodically instead of firing the DDL on
	 * every poll.
	 */
	public numeric function $claimTimeoutAlterBackoffWindow() {
		return 300;
	}

	/**
	 * True when a claimTimeout ALTER failed within the back-off window. App-scoped (shared
	 * across the per-poll JobWorker instances) and TIME-BOUNDED — never a permanent flag.
	 */
	public boolean function $claimTimeoutAlterInBackoff(string memoKey = "$claimTimeoutAlterFailedAt") {
		if (!StructKeyExists(application, "wheels") || !StructKeyExists(application.wheels, arguments.memoKey)) {
			return false;
		}
		return DateDiff("s", application.wheels[arguments.memoKey], $now()) < $claimTimeoutAlterBackoffWindow();
	}

	/**
	 * Record that the claimTimeout ALTER just failed, so the next polls back off rather than
	 * re-firing the DDL. Safe to call from a catch (writes the application scope, not local).
	 */
	public void function $recordClaimTimeoutAlterFailure(string memoKey = "$claimTimeoutAlterFailedAt") {
		if (StructKeyExists(application, "wheels")) {
			application.wheels[arguments.memoKey] = $now();
		}
	}

	/**
	 * Forget any recorded claimTimeout ALTER failure (the column now exists, or the ALTER
	 * just succeeded), so a later missing-column situation is re-attempted immediately.
	 */
	public void function $clearClaimTimeoutAlterMemo(string memoKey = "$claimTimeoutAlterFailedAt") {
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, arguments.memoKey)) {
			StructDelete(application.wheels, arguments.memoKey);
		}
	}

	/**
	 * True when wheels_jobs already has a claimTimeout column. A zero-row SELECT of the
	 * column is the most portable probe: it succeeds when the column exists and throws
	 * otherwise, with no dependency on cfdbinfo column-metadata shapes across engines.
	 */
	public boolean function $jobTableHasClaimTimeout() {
		try {
			queryExecute("SELECT claimTimeout FROM wheels_jobs WHERE 1=0", {}, {datasource = variables.$datasource});
			return true;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * The per-database "ADD claimTimeout column" DDL. SQL Server has no COLUMN keyword and
	 * Oracle takes a parenthesised column list; everything else accepts ADD COLUMN.
	 */
	public string function $claimTimeoutAlterSql() {
		return $jobSchema().addColumnSql(tableName = "wheels_jobs", columnName = "claimTimeout", dbType = $detectDatabaseType());
	}

	/**
	 * Log the claimTimeout ALTER failure once per application so the log isn't spammed by the
	 * every-call probe. This throttles only the log line; the ALTER decision itself is never
	 * cached (it is re-probed every ensure call).
	 */
	public void function $warnClaimTimeoutAlterFailedOnce(required string reason) {
		if (StructKeyExists(application, "wheels") && !StructKeyExists(application.wheels, "$claimTimeoutAlterWarned")) {
			application.wheels.$claimTimeoutAlterWarned = true;
			writeLog(
				text = "Could not add the wheels_jobs.claimTimeout column (#arguments.reason#). The stale-job "
					& "reaper will fall back to the polling worker's timeout. Add the column manually "
					& "(ALTER TABLE wheels_jobs ADD claimTimeout INT) to enable per-worker reap timeouts.",
				type = "warning",
				file = "wheels_jobs"
			);
		}
	}

	/**
	 * Add the claimToken / claimedBy columns to an existing wheels_jobs table when they are
	 * missing, so a table created before claim fencing is upgraded in place. Same contract as
	 * $ensureClaimTimeoutColumn: probed every call, a failed ALTER backs off for a bounded
	 * window and logs once, and the missing columns are tolerated — claims then run unfenced,
	 * exactly as they did before fencing existed.
	 */
	public void function $ensureClaimTokenColumns() {
		// DDL inside an open transaction makes MySQL and Oracle commit the caller's work, so the
		// columns are never added there (an INSERT failure's table-ensure runs inside the caller's
		// transaction). A worker poll or a call outside a transaction adds them.
		if (!$jobSchema().autoCreateEnabled()) {
			return;
		}
		if (Len($outermostWheelsTransaction())) {
			return;
		}
		if ($jobTableHasClaimToken()) {
			$clearClaimTimeoutAlterMemo(memoKey = "$claimTokenAlterFailedAt");
			return;
		}
		if ($claimTimeoutAlterInBackoff(memoKey = "$claimTokenAlterFailedAt")) {
			return;
		}
		try {
			if (!$jobTableHasColumn("claimToken")) {
				queryExecute($claimTokenAlterSql(columnName = "claimToken", size = 36), {}, {datasource = variables.$datasource});
			}
			if (!$jobTableHasColumn("claimedBy")) {
				queryExecute($claimTokenAlterSql(columnName = "claimedBy", size = 128), {}, {datasource = variables.$datasource});
			}
			$clearClaimTimeoutAlterMemo(memoKey = "$claimTokenAlterFailedAt");
		} catch (any e) {
			$recordClaimTimeoutAlterFailure(memoKey = "$claimTokenAlterFailedAt");
			$warnClaimTokenAlterFailedOnce(e.message);
		}
	}

	/**
	 * True when wheels_jobs has both claim-fencing columns (claimToken and claimedBy).
	 */
	public boolean function $jobTableHasClaimToken() {
		return $jobTableHasColumn("claimToken") && $jobTableHasColumn("claimedBy");
	}

	/**
	 * True when wheels_jobs has the named column — the same zero-row SELECT probe as
	 * $jobTableHasClaimTimeout. Only ever called with framework-owned column names.
	 */
	public boolean function $jobTableHasColumn(required string columnName) {
		try {
			queryExecute("SELECT #arguments.columnName# FROM wheels_jobs WHERE 1=0", {}, {datasource = variables.$datasource});
			return true;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * The per-database "ADD <column> VARCHAR(n)" DDL for a claim-fencing column.
	 */
	public string function $claimTokenAlterSql(required string columnName, required numeric size) {
		return $jobSchema().addColumnSql(tableName = "wheels_jobs", columnName = arguments.columnName, dbType = $detectDatabaseType());
	}

	/**
	 * Log the claim-fencing ALTER failure once per application.
	 */
	public void function $warnClaimTokenAlterFailedOnce(required string reason) {
		if (StructKeyExists(application, "wheels") && !StructKeyExists(application.wheels, "$claimTokenAlterWarned")) {
			application.wheels.$claimTokenAlterWarned = true;
			writeLog(
				text = "Could not add the wheels_jobs.claimToken/claimedBy columns (#arguments.reason#). Jobs "
					& "will be claimed without per-attempt fencing, so a reaped attempt that finishes late can "
					& "still overwrite the attempt that replaced it. Add the columns manually "
					& "(claimToken VARCHAR(36), claimedBy VARCHAR(128)) to enable fencing.",
				type = "warning",
				file = "wheels_jobs"
			);
		}
	}

	/**
	 * Whether this instance can fence its claims. Memoised per instance; the first call also
	 * runs the column ensure, so the processQueue() path upgrades an existing table too (it
	 * only reaches $ensureJobTable when its SELECT fails). Re-run by each new instance (#2780).
	 */
	public boolean function $claimTokenColumnsAvailable() {
		if (!StructKeyExists(variables, "$claimTokenColumnsPresent")) {
			try {
				$ensureClaimTokenColumns();
				variables.$claimTokenColumnsPresent = $jobTableHasClaimToken();
			} catch (any e) {
				variables.$claimTokenColumnsPresent = false;
			}
		}
		return variables.$claimTokenColumnsPresent;
	}

	/**
	 * Add the result column (perform()'s return value) to an existing wheels_jobs table. Never
	 * inside a Wheels transaction (DDL there commits the caller's work on MySQL and Oracle);
	 * a failed ALTER backs off and logs once, and jobs then run without storing their result.
	 */
	public void function $ensureResultColumn() {
		if (!$jobSchema().autoCreateEnabled()) {
			return;
		}
		if (Len($outermostWheelsTransaction())) {
			return;
		}
		if ($jobTableHasColumn("result")) {
			$clearClaimTimeoutAlterMemo(memoKey = "$resultAlterFailedAt");
			return;
		}
		if ($claimTimeoutAlterInBackoff(memoKey = "$resultAlterFailedAt")) {
			return;
		}
		try {
			queryExecute($resultAlterSql(), {}, {datasource = variables.$datasource});
			$clearClaimTimeoutAlterMemo(memoKey = "$resultAlterFailedAt");
		} catch (any e) {
			$recordClaimTimeoutAlterFailure(memoKey = "$resultAlterFailedAt");
			if (StructKeyExists(application, "wheels") && !StructKeyExists(application.wheels, "$resultAlterWarned")) {
				application.wheels.$resultAlterWarned = true;
				writeLog(
					text = "Could not add the wheels_jobs.result column (#e.message#). Jobs run as before but "
						& "their return values aren't stored. Add it manually (result VARCHAR(4000)) to store them.",
					type = "warning",
					file = "wheels_jobs"
				);
			}
		}
	}

	/**
	 * Whether this instance can store results. Memoised per instance; the first call also runs
	 * the column ensure, like $claimTokenColumnsAvailable().
	 */
	public boolean function $resultColumnAvailable() {
		if (!StructKeyExists(variables, "$resultColumnPresent")) {
			try {
				$ensureResultColumn();
				variables.$resultColumnPresent = $jobTableHasColumn("result");
			} catch (any e) {
				variables.$resultColumnPresent = false;
			}
		}
		return variables.$resultColumnPresent;
	}

	/**
	 * The result column's type: NVARCHAR(4000) on SQL Server, whose VARCHAR silently mangles
	 * non-ASCII text, and VARCHAR(4000) (VARCHAR2 on Oracle) elsewhere.
	 */
	public string function $resultColumnType(required string dbType) {
		return $jobSchema().columnType(column = $jobSchema().columnDef("wheels_jobs", "result"), dbType = arguments.dbType);
	}

	/**
	 * The per-database "ADD result" DDL.
	 */
	public string function $resultAlterSql() {
		return $jobSchema().addColumnSql(tableName = "wheels_jobs", columnName = "result", dbType = $detectDatabaseType());
	}

	/**
	 * The completion UPDATE's result assignment and parameter: perform()'s return value, or NULL
	 * when it returned nothing (or the column isn't there, when the fragment is empty). An empty
	 * string is stored as NULL too: Oracle can't tell the two apart.
	 */
	public string function $resultAssignment(required struct performOutcome, required struct params) {
		if (!$resultColumnAvailable()) {
			return "";
		}
		// Detected once per instance: this runs on every completion.
		if (!StructKeyExists(variables, "$resultDbType")) {
			variables.$resultDbType = $detectDatabaseType();
		}
		local.dbType = variables.$resultDbType;
		local.text = arguments.performOutcome.hasResult ? $serializeJobResult(value = arguments.performOutcome.result, dbType = local.dbType) : "";
		arguments.params.result = {
			value = local.text,
			cfsqltype = local.dbType == "sqlserver" ? "cf_sql_nvarchar" : "cf_sql_varchar",
			null = !Len(local.text)
		};
		return ", result = :result";
	}

	/**
	 * perform()'s return value as stored text: a simple value as-is, anything else as JSON. A value
	 * over the column's limit is cut short and ends with a visible marker. The limit is what the
	 * column counts: 4000 characters (UTF-16 code units) for SQL Server's NVARCHAR, and 4000 UTF-8
	 * bytes elsewhere (Oracle's VARCHAR2 counts bytes; for the databases that count characters,
	 * bytes is the safe bound). The trim loop only runs for a value over the limit.
	 */
	public string function $serializeJobResult(any value, string dbType = "") {
		if (IsNull(arguments.value)) {
			return "";
		}
		local.text = IsSimpleValue(arguments.value) ? ToString(arguments.value) : SerializeJSON(arguments.value);
		local.limit = 4000;
		local.countChars = arguments.dbType == "sqlserver";
		if ($resultSize(local.text, local.countChars) <= local.limit) {
			return local.text;
		}
		local.marker = "...[truncated]";
		local.keep = local.limit - Len(local.marker);
		local.text = Left(local.text, local.keep);
		while (Len(local.text) > 0 && $resultSize(local.text, local.countChars) > local.keep) {
			local.text = Left(local.text, Len(local.text) - 1);
		}
		return local.text & local.marker;
	}

	/**
	 * Internal: a text's size as a result column counts it, in characters or UTF-8 bytes.
	 */
	public numeric function $resultSize(required string text, required boolean countChars) {
		return arguments.countChars ? Len(arguments.text) : Len(CharsetDecode(arguments.text, "utf-8"));
	}

	/**
	 * Calls the job's onSuccess(result) after its completion was recorded. Best-effort: a throw
	 * is logged and never changes the job's outcome.
	 */
	public void function $fireJobSuccess(required any jobInstance, required struct performOutcome, required string jobId, required string jobClass) {
		if (!IsObject(arguments.jobInstance) || !StructKeyExists(arguments.jobInstance, "onSuccess")) {
			return;
		}
		try {
			if (arguments.performOutcome.hasResult) {
				arguments.jobInstance.onSuccess(arguments.performOutcome.result);
			} else {
				arguments.jobInstance.onSuccess();
			}
		} catch (any e) {
			writeLog(text = "Job '#arguments.jobClass#' [#arguments.jobId#] onSuccess() failed: #e.message#", type = "error", file = "wheels_jobs");
		}
	}

	/**
	 * Calls the job's onFailure(error, attempt, isFinal), then the app's jobsOnFailure hook, after a
	 * failed attempt was recorded. `isFinal` is true when the job won't be tried again. Both are
	 * best-effort: a throw is logged and never changes the job's outcome. `jobInstance` may be ""
	 * when the job class couldn't be loaded; the global hook still runs.
	 */
	public void function $fireJobFailure(
		required any jobInstance,
		required string jobId,
		required string jobClass,
		required string queue,
		required struct error,
		required numeric attempt,
		required numeric maxRetries,
		required boolean isFinal
	) {
		if (IsObject(arguments.jobInstance) && StructKeyExists(arguments.jobInstance, "onFailure")) {
			try {
				// Positional, so the hook may name its parameters freely (`final` itself isn't a
				// valid parameter name on Adobe CF).
				arguments.jobInstance.onFailure(arguments.error, arguments.attempt, arguments.isFinal);
			} catch (any e) {
				writeLog(text = "Job '#arguments.jobClass#' [#arguments.jobId#] onFailure() failed: #e.message#", type = "error", file = "wheels_jobs");
			}
		}
		local.event = {};
		local.event["jobId"] = arguments.jobId;
		local.event["jobClass"] = arguments.jobClass;
		local.event["queue"] = arguments.queue;
		local.event["attempt"] = arguments.attempt;
		local.event["maxRetries"] = arguments.maxRetries;
		local.event["isFinal"] = arguments.isFinal;
		local.event["error"] = arguments.error;
		$callJobsOnFailure(local.event);
	}

	/**
	 * Calls the app's global failure hook, set(jobsOnFailure = "component.path.method"), with one
	 * struct describing the failure ({jobId, jobClass, queue, attempt, maxRetries, isFinal, error}) (no job data: it can hold secrets). The method receives it as
	 * its `event` argument. Best-effort; a hook that can't be called is logged once per app.
	 */
	public void function $callJobsOnFailure(required struct event) {
		if (!StructKeyExists(application, "wheels") || !StructKeyExists(application.wheels, "jobsOnFailure")) {
			return;
		}
		local.target = Trim(application.wheels.jobsOnFailure);
		if (ListLen(local.target, ".") < 2) {
			return;
		}
		local.method = ListLast(local.target, ".");
		local.path = Left(local.target, Len(local.target) - Len(local.method) - 1);
		try {
			local.hook = CreateObject("component", local.path);
			Invoke(local.hook, local.method, {event = arguments.event});
		} catch (any e) {
			if (!StructKeyExists(application.wheels, "$jobsOnFailureWarned")) {
				application.wheels.$jobsOnFailureWarned = true;
				writeLog(text = "The jobsOnFailure hook '#local.target#' failed: #e.message#", type = "error", file = "wheels_jobs");
			}
		}
	}

	/**
	 * The error struct the failure hooks receive.
	 */
	public struct function $jobError(string type = "", string message = "", string detail = "") {
		return {type = Len(arguments.type) ? arguments.type : "Wheels.JobFailed", message = arguments.message, detail = arguments.detail};
	}

	/**
	 * Throws Wheels.Job.SchemaMissing: a job table or column is missing while jobsAutoCreateTables
	 * is false, so the framework won't create it. Logged once per application as well, because a
	 * worker hits this on every poll until the migration runs.
	 */
	public void function $throwJobSchemaMissing(required string what) {
		local.message = $jobSchema().missingSchemaMessage(arguments.what);
		if (StructKeyExists(application, "wheels") && !StructKeyExists(application.wheels, "$jobsSchemaMissingLogged")) {
			application.wheels.$jobsSchemaMissingLogged = true;
			writeLog(text = local.message, type = "error", file = "wheels_jobs");
		}
		Throw(type = "Wheels.Job.SchemaMissing", message = local.message);
	}

	/**
	 * The job schema (wheels.JobSchema) for this instance's datasource, memoised per instance.
	 */
	public any function $jobSchema() {
		if (!StructKeyExists(variables, "$jobSchemaInstance")) {
			variables.$jobSchemaInstance = new wheels.JobSchema(datasource = variables.$datasource);
		}
		return variables.$jobSchemaInstance;
	}

	/**
	 * A fresh, unique token for one claim of one job.
	 */
	public string function $newClaimToken() {
		return CreateUUID();
	}

	/**
	 * The name recorded in claimedBy: this machine's host name (CGI.SERVER_NAME is the same on
	 * every host behind a load balancer). Cached per application — the lookup can block on DNS.
	 */
	public string function $jobHostName() {
		// set(jobsHostName = "...") names this app server explicitly: needed when several app
		// servers (JVMs) share one machine, or they share one per-host cap and drain flag.
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "jobsHostName") && Len(Trim(application.wheels.jobsHostName))) {
			return Left(Trim(application.wheels.jobsHostName), 128);
		}
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "$jobHostName")) {
			return application.wheels.$jobHostName;
		}
		var host = {name = ""};
		try {
			host.name = CreateObject("java", "java.net.InetAddress").getLocalHost().getHostName();
		} catch (any e) {
			host.name = Len(CGI.SERVER_NAME) ? CGI.SERVER_NAME : "unknown";
		}
		host.name = Left(host.name, 128);
		if (StructKeyExists(application, "wheels")) {
			application.wheels.$jobHostName = host.name;
		}
		return host.name;
	}

	/**
	 * Fence a terminal UPDATE to the attempt that owns the claim: adds the claimToken guard
	 * (and its parameter) when the attempt holds a token, and nothing when it doesn't (a
	 * column-less table, or a caller that never claimed).
	 */
	public string function $claimTokenGuard(required string claimToken, required struct params) {
		if (!Len(arguments.claimToken)) {
			return "";
		}
		arguments.params.claimToken = {value = arguments.claimToken, cfsqltype = "cf_sql_varchar"};
		return " AND claimToken = :claimToken";
	}

	/**
	 * Record that an attempt's completion/retry/fail was rejected because the job is no longer
	 * its claim: it was reaped and requeued (or re-claimed by another worker) while it ran. The
	 * work itself ran; only its outcome was discarded, so jobs must stay idempotent.
	 */
	public void function $logFencedAttempt(required string jobId, required string jobClass, required string outcome) {
		writeLog(
			text = "Wheels.Job.Fenced: job '#arguments.jobClass#' [#arguments.jobId#] finished (#arguments.outcome#) "
				& "after its claim was reaped; the result was discarded so it cannot overwrite the attempt that replaced it.",
			type = "warning",
			file = "wheels_jobs"
		);
	}

	/**
	 * Bring an existing wheels_jobs table up to de-duplicated enqueue: add a nullable uniqueKey
	 * column, backfill it from id, and build its unique index. Nullable on purpose — hosts still
	 * on an older version insert without a key during a rolling upgrade, and NULL keys never
	 * collide (SQL Server, which allows one NULL in a unique index, gets a filtered index).
	 * Probed every call like the claimTimeout column; only the "index verified" result is
	 * remembered per datasource, and it is dropped whenever the column is found missing.
	 * The DDL runs under the Migrator's cross-process lock taken try-once: when another instance
	 * holds it, this round is skipped instead of waiting inside an enqueue or a poll.
	 */
	public void function $ensureUniqueKeyColumn() {
		// DDL inside an open transaction makes MySQL and Oracle commit the caller's work, so the
		// upgrade never runs there, whoever calls this (a keyed enqueue, or the table-ensure an
		// INSERT failure triggers). A worker poll or an enqueue outside a transaction does it.
		if (!$jobSchema().autoCreateEnabled()) {
			return;
		}
		if (Len($outermostWheelsTransaction())) {
			return;
		}
		local.hasColumn = $jobTableHasUniqueKey();
		if (!local.hasColumn) {
			$clearUniqueKeyIndexVerified();
		} else if ($uniqueKeyIndexVerified()) {
			return;
		} else if ($jobTableHasUniqueKeyIndex()) {
			$recordUniqueKeyIndexVerified();
			$clearClaimTimeoutAlterMemo(memoKey = "$uniqueKeyAlterFailedAt");
			return;
		}
		if ($claimTimeoutAlterInBackoff(memoKey = "$uniqueKeyAlterFailedAt")) {
			return;
		}
		local.schemaLock = $tryJobSchemaLock();
		if (!local.schemaLock.taken) {
			return;
		}
		// Nested rather than try/catch/finally: on BoxLang a finally that shares a try with a catch
		// is skipped when the request ends with abort, and the lock must always be released.
		var progress = {step = ""};
		try {
			try {
				$upgradeUniqueKeyColumn(progress = progress);
				$clearClaimTimeoutAlterMemo(memoKey = "$uniqueKeyAlterFailedAt");
				$clearUniqueKeyUpgradeProblem();
			} catch (any e) {
				$recordClaimTimeoutAlterFailure(memoKey = "$uniqueKeyAlterFailedAt");
				$recordUniqueKeyUpgradeProblem(step = progress.step, reason = e.message);
				$warnUniqueKeyUpgradeFailedOnce(reason = e.message, step = progress.step);
			}
		} finally {
			$releaseJobSchemaLock(local.schemaLock);
		}
	}

	/**
	 * The upgrade steps. Each re-probes after a failure, so an instance that upgraded the table a
	 * moment earlier (without the lock, where none is available) counts as success, not an error.
	 * `progress.step` names the step under way (column, backfill, index), so a failure can say
	 * which one failed.
	 */
	public void function $upgradeUniqueKeyColumn(struct progress = {}) {
		arguments.progress.step = "column";
		if (!$jobTableHasUniqueKey()) {
			try {
				queryExecute($uniqueKeyAlterSql(), {}, {datasource = variables.$datasource});
			} catch (any e) {
				if (!$jobTableHasUniqueKey()) {
					rethrow;
				}
			}
		}
		arguments.progress.step = "backfill";
		queryExecute("UPDATE wheels_jobs SET uniqueKey = id WHERE uniqueKey IS NULL", {}, {datasource = variables.$datasource});
		arguments.progress.step = "index";
		if (!$jobTableHasUniqueKeyIndex()) {
			try {
				queryExecute($uniqueKeyIndexSql(), {}, {datasource = variables.$datasource});
			} catch (any e) {
				if (!$jobTableHasUniqueKeyIndex()) {
					rethrow;
				}
			}
		}
		$recordUniqueKeyIndexVerified();
	}

	/**
	 * True when wheels_jobs has a uniqueKey column (the same zero-row probe as claimTimeout).
	 */
	public boolean function $jobTableHasUniqueKey() {
		try {
			queryExecute("SELECT uniqueKey FROM wheels_jobs WHERE 1=0", {}, {datasource = variables.$datasource});
			return true;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * True when wheels_jobs has the uniqueKey unique index. Asked of the database's own catalog,
	 * because driver index metadata isn't reliable everywhere: BoxLang's cfdbinfo reports no
	 * indexes for this table on Oracle, SQL Server and CockroachDB. Falls back to cfdbinfo for an
	 * unknown database or a catalog query that fails. Oracle and H2 report unquoted names
	 * upper-cased, so names are compared case-insensitively.
	 */
	public boolean function $jobTableHasUniqueKeyIndex() {
		local.catalogSql = $uniqueKeyIndexCatalogSql();
		if (Len(local.catalogSql)) {
			try {
				return queryExecute(local.catalogSql, {}, {datasource = variables.$datasource}).recordCount > 0;
			} catch (any e) {
				// Fall back to the driver metadata below.
			}
		}
		local.indexes = $jobTableIndexes("wheels_jobs");
		if (!local.indexes.recordCount) {
			local.indexes = $jobTableIndexes("WHEELS_JOBS");
		}
		for (local.i = 1; local.i <= local.indexes.recordCount; local.i++) {
			if (CompareNoCase(local.indexes.index_name[local.i], "idx_wjobs_unique_key") == 0) {
				return true;
			}
		}
		return false;
	}

	/**
	 * The catalog query that finds the uniqueKey index on this database ("" for an unknown one).
	 */
	public string function $uniqueKeyIndexCatalogSql() {
		local.dbType = $detectDatabaseType();
		if (local.dbType == "postgresql") {
			return "SELECT 1 FROM pg_indexes WHERE schemaname = current_schema() AND LOWER(tablename) = 'wheels_jobs' AND LOWER(indexname) = 'idx_wjobs_unique_key'";
		}
		if (local.dbType == "mysql") {
			return "SELECT 1 FROM information_schema.statistics WHERE table_schema = DATABASE() AND LOWER(table_name) = 'wheels_jobs' AND LOWER(index_name) = 'idx_wjobs_unique_key'";
		}
		if (local.dbType == "sqlserver") {
			return "SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('wheels_jobs') AND LOWER(name) = 'idx_wjobs_unique_key'";
		}
		if (local.dbType == "oracle") {
			return "SELECT 1 FROM user_indexes WHERE UPPER(table_name) = 'WHEELS_JOBS' AND UPPER(index_name) = 'IDX_WJOBS_UNIQUE_KEY'";
		}
		if (local.dbType == "h2") {
			return "SELECT 1 FROM INFORMATION_SCHEMA.INDEXES WHERE UPPER(TABLE_NAME) = 'WHEELS_JOBS' AND UPPER(INDEX_NAME) = 'IDX_WJOBS_UNIQUE_KEY'";
		}
		if (local.dbType == "sqlite") {
			return "SELECT 1 FROM sqlite_master WHERE type = 'index' AND LOWER(tbl_name) = 'wheels_jobs' AND LOWER(name) = 'idx_wjobs_unique_key'";
		}
		return "";
	}

	/**
	 * The table's index metadata, or an empty query when it can't be read.
	 */
	public query function $jobTableIndexes(required string tableName) {
		try {
			cfdbinfo(type = "index", table = "#arguments.tableName#", datasource = "#variables.$datasource#", name = "local.indexes");
			return local.indexes;
		} catch (any e) {
			return QueryNew("index_name");
		}
	}

	/**
	 * Whether this instance's inserts can write uniqueKey. Memoised per instance (one probe per
	 * job object, like the worker's claimTimeout memo); $persistJobRow re-probes after a failure.
	 */
	public boolean function $uniqueKeyColumnAvailable() {
		if (!StructKeyExists(variables, "$uniqueKeyColumnPresent")) {
			variables.$uniqueKeyColumnPresent = $jobTableHasUniqueKey();
		}
		return variables.$uniqueKeyColumnPresent;
	}

	/**
	 * Whether the uniqueKey index was verified on this datasource since the application started.
	 */
	public boolean function $uniqueKeyIndexVerified() {
		return StructKeyExists(application, "wheels")
			&& StructKeyExists(application.wheels, "$jobsUniqueKeyIndexVerified")
			&& StructKeyExists(application.wheels.$jobsUniqueKeyIndexVerified, variables.$datasource);
	}

	public void function $recordUniqueKeyIndexVerified() {
		if (!StructKeyExists(application, "wheels")) {
			return;
		}
		if (!StructKeyExists(application.wheels, "$jobsUniqueKeyIndexVerified")) {
			application.wheels.$jobsUniqueKeyIndexVerified = {};
		}
		application.wheels.$jobsUniqueKeyIndexVerified[variables.$datasource] = true;
	}

	public void function $clearUniqueKeyIndexVerified() {
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "$jobsUniqueKeyIndexVerified")) {
			StructDelete(application.wheels.$jobsUniqueKeyIndexVerified, variables.$datasource);
		}
	}

	/**
	 * The per-database "ADD uniqueKey" DDL (nullable).
	 */
	public string function $uniqueKeyAlterSql() {
		return $jobSchema().addColumnSql(tableName = "wheels_jobs", columnName = "uniqueKey", dbType = $detectDatabaseType());
	}

	/**
	 * The uniqueKey unique index: plain everywhere except SQL Server, whose unique indexes allow a
	 * single NULL, so it is filtered to the non-NULL keys there.
	 */
	public string function $uniqueKeyIndexSql() {
		return $jobSchema().indexSql(tableName = "wheels_jobs", indexName = "idx_wjobs_unique_key", dbType = $detectDatabaseType());
	}

	/**
	 * One attempt at the Migrator's cross-process lock for jobs-table DDL. `taken` is true when
	 * this instance holds it — or when no lock is available at all (no migrator, or no lock table
	 * that may be created), where the DDL steps' own re-probing keeps concurrent instances safe.
	 */
	public struct function $tryJobSchemaLock() {
		var lockState = {taken = true, migrationLock = {}, migrator = ""};
		if (!StructKeyExists(application, "wheels") || !StructKeyExists(application.wheels, "migrator")) {
			return lockState;
		}
		try {
			var migrator = application.wheels.migrator;
			var lockDataSource = migrator.$migratorDataSource();
			if (!migrator.$migrationLockAvailable(lockDataSource)) {
				return lockState;
			}
			var owner = Replace(CreateUUID(), "-", "", "all");
			lockState.migrationLock = {key = lockDataSource & "|jobs-schema-" & owner, dataSource = lockDataSource, active = true, reentered = false, depth = 1, owner = owner};
			lockState.migrator = migrator;
			lockState.taken = migrator.$tryTakeMigrationLock(lockState.migrationLock);
			if (!lockState.taken) {
				lockState.migrationLock.active = false;
			}
		} catch (any e) {
			lockState.taken = true;
			lockState.migrationLock = {};
		}
		return lockState;
	}

	public void function $releaseJobSchemaLock(required struct lockState) {
		if (
			IsObject(arguments.lockState.migrator)
			&& StructKeyExists(arguments.lockState.migrationLock, "active")
			&& arguments.lockState.migrationLock.active
		) {
			arguments.lockState.migrator.$releaseMigrationLock(arguments.lockState.migrationLock);
		}
	}

	/**
	 * Log a failed uniqueKey upgrade once per application.
	 */
	public void function $warnUniqueKeyUpgradeFailedOnce(required string reason, string step = "") {
		if (StructKeyExists(application, "wheels") && !StructKeyExists(application.wheels, "$uniqueKeyAlterWarned")) {
			application.wheels.$uniqueKeyAlterWarned = true;
			writeLog(text = $uniqueKeyUpgradeFailureText(reason = arguments.reason, step = arguments.step), type = "warning", file = "wheels_jobs");
		}
	}

	/**
	 * The message for a failed uniqueKey upgrade: which step failed and why, what still works,
	 * and the manual fix for this database.
	 */
	public string function $uniqueKeyUpgradeFailureText(required string reason, string step = "") {
		local.steps = {
			column = "add the wheels_jobs.uniqueKey column",
			backfill = "backfill wheels_jobs.uniqueKey from id",
			index = "build the unique index idx_wjobs_unique_key on wheels_jobs.uniqueKey"
		};
		local.what = StructKeyExists(local.steps, arguments.step) ? local.steps[arguments.step] : "add the wheels_jobs.uniqueKey column and index";
		return "Could not #local.what# (#arguments.reason#). Jobs enqueued without a uniqueKey are unaffected; "
			& "enqueue(uniqueKey=...) throws Wheels.Job.UniqueKeyUnavailable until it is done. " & $uniqueKeyManualFix();
	}

	/**
	 * How to finish the uniqueKey upgrade by hand on this database. On SQL Server the index is
	 * filtered to non-NULL keys, which needs database compatibility level 100 or higher; below
	 * that the advice names the level and the real options rather than a statement that fails
	 * the same way.
	 */
	public string function $uniqueKeyManualFix() {
		local.dbType = $detectDatabaseType();
		local.column = local.dbType == "oracle" ? "ALTER TABLE wheels_jobs ADD (uniqueKey VARCHAR2(255))" : "ALTER TABLE wheels_jobs ADD uniqueKey VARCHAR(255)";
		local.steps = "#local.column#; UPDATE wheels_jobs SET uniqueKey = id WHERE uniqueKey IS NULL; ";
		local.plainIndex = "CREATE UNIQUE INDEX idx_wjobs_unique_key ON wheels_jobs (uniqueKey)";
		if (local.dbType != "sqlserver") {
			return "To do it by hand: #local.steps##local.plainIndex#.";
		}
		local.level = $sqlServerCompatibilityLevel();
		if (local.level > 0 && local.level < 100) {
			return "This SQL Server database runs at compatibility level #local.level#, and the filtered unique index "
				& "Wheels uses on SQL Server (WHERE ... IS NOT NULL) needs level 100 or higher. Either raise it "
				& "(ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 100, or higher) and the framework retries the upgrade, "
				& "or, once every server runs Wheels 4.2 or later, create a plain unique index yourself: #local.steps##local.plainIndex#. "
				& "A plain unique index allows only one NULL key, so a server still on 4.1 would fail its second enqueue.";
		}
		return "To do it by hand: #local.steps##local.plainIndex# WHERE uniqueKey IS NOT NULL.";
	}

	/**
	 * This SQL Server database's compatibility level, or 0 when it can't be read.
	 */
	public numeric function $sqlServerCompatibilityLevel() {
		try {
			local.rows = queryExecute(
				"SELECT compatibility_level AS lvl FROM sys.databases WHERE name = DB_NAME()",
				{},
				{datasource = variables.$datasource}
			);
			return local.rows.recordCount ? Val(local.rows.lvl) : 0;
		} catch (any e) {
			return 0;
		}
	}

	/**
	 * Remember the last failed upgrade step (app-wide), so UniqueKeyUnavailable can repeat it.
	 */
	public void function $recordUniqueKeyUpgradeProblem(required string step, required string reason) {
		if (StructKeyExists(application, "wheels")) {
			application.wheels.$uniqueKeyUpgradeProblem = {step = arguments.step, reason = arguments.reason};
		}
	}

	public void function $clearUniqueKeyUpgradeProblem() {
		if (StructKeyExists(application, "wheels")) {
			StructDelete(application.wheels, "$uniqueKeyUpgradeProblem");
		}
	}

	/**
	 * "The last attempt (step: ...) failed: <reason>. " or "" when none is recorded.
	 */
	public string function $uniqueKeyLastProblem() {
		if (!StructKeyExists(application, "wheels") || !StructKeyExists(application.wheels, "$uniqueKeyUpgradeProblem")) {
			return "";
		}
		local.p = application.wheels.$uniqueKeyUpgradeProblem;
		return "The last attempt (step: #local.p.step#) failed: #local.p.reason#. ";
	}

	/**
	 * The per-host concurrency cap from set(jobsMaxConcurrentPerHost = n); 0 (the default)
	 * means no cap.
	 */
	public numeric function $jobsMaxConcurrentPerHost() {
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "jobsMaxConcurrentPerHost")) {
			return Max(0, Int(Val(application.wheels.jobsMaxConcurrentPerHost)));
		}
		return 0;
	}

	/**
	 * What this deployment reports as its code version in wheels_job_hosts:
	 * set(jobsCodeVersion = ...) (e.g. a git SHA), else the Wheels version.
	 */
	public string function $jobsCodeVersion() {
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "jobsCodeVersion") && Len(application.wheels.jobsCodeVersion)) {
			return Left(application.wheels.jobsCodeVersion, 64);
		}
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "version")) {
			return Left(application.wheels.version, 64);
		}
		return "unknown";
	}

	/**
	 * Create the wheels_job_hosts registry when it is missing. Never inside an open transaction
	 * (DDL commits the caller's work on MySQL/Oracle). Returns whether the table exists now.
	 */
	public boolean function $ensureHostsTable() {
		if ($hostsTableExists()) {
			return true;
		}
		if (!$jobSchema().autoCreateEnabled()) {
			$warnAuxTableMissingOnce("wheels_job_hosts", "this server's drain/resume and its host record in jobs status are unavailable (the per-host cap still works)");
			return false;
		}
		if (Len($outermostWheelsTransaction())) {
			return false;
		}
		try {
			queryExecute($jobSchema().createTableSql(tableName = "wheels_job_hosts", dbType = $detectDatabaseType()), {}, {datasource = variables.$datasource});
			writeLog(text = "Auto-created wheels_job_hosts table", type = "information", file = "wheels_jobs");
		} catch (any e) {
			// Another instance may have created it at the same moment; only a still-missing
			// table is a failure.
			if (!$hostsTableExists()) {
				writeLog(text = "Failed to auto-create wheels_job_hosts table: #e.message#", type = "error", file = "wheels_jobs");
				return false;
			}
		}
		return true;
	}

	/**
	 * Internal: logs once per application that a job table is missing and, with
	 * jobsAutoCreateTables = false, won't be created, naming what doesn't work without it.
	 */
	public void function $warnAuxTableMissingOnce(required string tableName, required string effect) {
		if (!StructKeyExists(application, "wheels")) {
			return;
		}
		local.key = "$jobsAuxMissingLogged_" & arguments.tableName;
		if (StructKeyExists(application.wheels, local.key)) {
			return;
		}
		application.wheels[local.key] = true;
		writeLog(text = $jobSchema().missingSchemaMessage("The #arguments.tableName# table") & " Until it exists, #arguments.effect#.", type = "error", file = "wheels_jobs");
	}

	public boolean function $hostsTableExists() {
		try {
			queryExecute("SELECT host FROM wheels_job_hosts WHERE 1=0", {}, {datasource = variables.$datasource});
			return true;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Whether `host` is draining right now: its drain flag is set and has not expired. A missing
	 * registry (nothing ever drained) means not draining. Any other failure is logged and
	 * rethrown: treating a broken registry as "not draining" would let a drained host start jobs
	 * mid-deploy. Compared SQL-side, on the same clock the drain was written with.
	 */
	public boolean function $hostDraining(required string host) {
		try {
			local.rows = queryExecute(
				"SELECT COUNT(*) AS cnt FROM wheels_job_hosts
				WHERE host = :host AND draining = 1 AND (drainExpiresAt IS NULL OR drainExpiresAt > :now)",
				{
					host = {value = arguments.host, cfsqltype = "cf_sql_varchar"},
					now = {value = $now(), cfsqltype = "cf_sql_timestamp"}
				},
				{datasource = variables.$datasource}
			);
			return Val(local.rows.cnt) > 0;
		} catch (any e) {
			if (!$hostsTableExists()) {
				return false;
			}
			writeLog(text = "Could not read the drain state of jobs host '#arguments.host#' from wheels_job_hosts (no job will start on this host until it can): #e.message#", type = "error", file = "wheels_jobs");
			rethrow;
		}
	}

	/**
	 * How many jobs `host` is running now: processing rows it claimed (claimedBy). Without the
	 * claimedBy column (an ALTER-blocked table) the count can't be taken: 0, logged once, so
	 * the cap degrades to none rather than blocking every job.
	 */
	public numeric function $runningOnHost(required string host) {
		try {
			local.rows = queryExecute(
				"SELECT COUNT(*) AS cnt FROM wheels_jobs WHERE status = 'processing' AND claimedBy = :host",
				{host = {value = arguments.host, cfsqltype = "cf_sql_varchar"}},
				{datasource = variables.$datasource}
			);
			return Val(local.rows.cnt);
		} catch (any e) {
			if (StructKeyExists(application, "wheels") && !StructKeyExists(application.wheels, "$jobsHostCapWarned")) {
				application.wheels.$jobsHostCapWarned = true;
				writeLog(
					text = "Could not count this host's running jobs (#e.message#): wheels_jobs.claimedBy is missing, so jobsMaxConcurrentPerHost is not enforced.",
					type = "warning",
					file = "wheels_jobs"
				);
			}
			return 0;
		}
	}

	/**
	 * Write `fields` (column => struct param) to this host's registry row, creating it on first
	 * sight. UPDATE first, INSERT when there was no row, and UPDATE again if another instance
	 * inserted it in between: no engine-specific upsert syntax.
	 */
	public void function $writeHostRow(required string host, required struct fields) {
		local.sets = [];
		local.params = {host = {value = arguments.host, cfsqltype = "cf_sql_varchar"}};
		for (local.column in arguments.fields) {
			ArrayAppend(local.sets, "#local.column# = :#local.column#");
			local.params[local.column] = arguments.fields[local.column];
		}
		local.updateSql = "UPDATE wheels_job_hosts SET #ArrayToList(local.sets, ", ")# WHERE host = :host";
		queryExecute(local.updateSql, local.params, {datasource = variables.$datasource, result = "local.updated"});
		if (Val(local.updated.recordCount ?: 0) > 0) {
			return;
		}
		local.columns = "host, startedAt";
		local.values = ":host, :startedAt";
		local.insertParams = Duplicate(local.params);
		local.insertParams.startedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"};
		for (local.column in arguments.fields) {
			local.columns &= ", #local.column#";
			local.values &= ", :#local.column#";
		}
		try {
			queryExecute("INSERT INTO wheels_job_hosts (#local.columns#) VALUES (#local.values#)", local.insertParams, {datasource = variables.$datasource});
		} catch (any e) {
			// Lost the race to insert it: the row exists now, so update it.
			queryExecute(local.updateSql, local.params, {datasource = variables.$datasource});
		}
	}

	/**
	 * Add the heartbeatAt column to an existing wheels_jobs table when it is missing. Same
	 * contract as the other job columns: probed every call, never inside an open transaction
	 * (DDL commits the caller's work on MySQL/Oracle), a failed ALTER backs off and logs once.
	 * Without it, heartbeat() renews updatedAt instead, so jobs still stay alive.
	 */
	public void function $ensureHeartbeatColumn() {
		if (!$jobSchema().autoCreateEnabled()) {
			return;
		}
		if (Len($outermostWheelsTransaction())) {
			return;
		}
		if ($jobTableHasColumn("heartbeatAt")) {
			$clearClaimTimeoutAlterMemo(memoKey = "$heartbeatAlterFailedAt");
			return;
		}
		if ($claimTimeoutAlterInBackoff(memoKey = "$heartbeatAlterFailedAt")) {
			return;
		}
		try {
			queryExecute($heartbeatAlterSql(), {}, {datasource = variables.$datasource});
			$clearClaimTimeoutAlterMemo(memoKey = "$heartbeatAlterFailedAt");
		} catch (any e) {
			$recordClaimTimeoutAlterFailure(memoKey = "$heartbeatAlterFailedAt");
			$warnHeartbeatAlterFailedOnce(e.message);
		}
	}

	/**
	 * The per-database "ADD heartbeatAt" DDL, typed like the table's other timestamps.
	 */
	public string function $heartbeatAlterSql() {
		return $jobSchema().addColumnSql(tableName = "wheels_jobs", columnName = "heartbeatAt", dbType = $detectDatabaseType());
	}

	/**
	 * Whether this instance can write heartbeatAt. Memoised per instance, probe only (no DDL:
	 * it is read from inside perform(), possibly within the job's own transaction).
	 */
	public boolean function $heartbeatColumnAvailable() {
		if (!StructKeyExists(variables, "$heartbeatColumnPresent")) {
			variables.$heartbeatColumnPresent = $jobTableHasColumn("heartbeatAt");
		}
		return variables.$heartbeatColumnPresent;
	}

	/**
	 * Log the heartbeatAt ALTER failure once per application.
	 */
	public void function $warnHeartbeatAlterFailedOnce(required string reason) {
		if (StructKeyExists(application, "wheels") && !StructKeyExists(application.wheels, "$heartbeatAlterWarned")) {
			application.wheels.$heartbeatAlterWarned = true;
			writeLog(
				text = "Could not add the wheels_jobs.heartbeatAt column (#arguments.reason#). heartbeat() renews "
					& "updatedAt instead, so jobs still stay alive. Add the column manually "
					& "(heartbeatAt DATETIME, or TIMESTAMP on PostgreSQL/Oracle/H2).",
				type = "warning",
				file = "wheels_jobs"
			);
		}
	}

	public boolean function $isAllowedJobClass(required string jobClass) {
		local.name = Replace(Replace(Trim(arguments.jobClass), "/", ".", "all"), "\", ".", "all");
		local.prefixes = ListToArray($jobClassPrefixes());
		for (local.prefix in local.prefixes) {
			local.prefix = Trim(local.prefix);
			if (!Len(local.prefix)) {
				continue;
			}
			if (CompareNoCase(local.name, local.prefix) == 0) {
				return true;
			}
			if (Len(local.name) > Len(local.prefix) && CompareNoCase(Left(local.name, Len(local.prefix) + 1), local.prefix & ".") == 0) {
				return true;
			}
		}
		return false;
	}

	public string function $jobClassPrefixes() {
		local.prefixes = "app.jobs";
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "jobClassPrefixes") && Len(application.wheels.jobClassPrefixes)) {
			local.prefixes = ListAppend(local.prefixes, application.wheels.jobClassPrefixes);
		}
		if (
			!StructKeyExists(application, "wheels")
			|| !StructKeyExists(application.wheels, "environment")
			|| CompareNoCase(application.wheels.environment, "production") != 0
		) {
			local.prefixes = ListAppend(local.prefixes, "wheels.tests._assets.jobs");
		}
		return local.prefixes;
	}

	public boolean function $isAllowedJobDataSource(required string dataSource) {
		return ListFindNoCase($allowedJobDataSources(), arguments.dataSource) > 0;
	}

	public string function $allowedJobDataSources() {
		local.names = "";
		if (StructKeyExists(application, "wheels")) {
			if (StructKeyExists(application.wheels, "dataSourceName") && Len(application.wheels.dataSourceName)) {
				local.names = ListAppend(local.names, application.wheels.dataSourceName);
			}
			if (StructKeyExists(application.wheels, "coreTestDataSourceName") && Len(application.wheels.coreTestDataSourceName)) {
				local.names = ListAppend(local.names, application.wheels.coreTestDataSourceName);
			}
			if (StructKeyExists(application.wheels, "tenantDataSources")) {
				if (IsArray(application.wheels.tenantDataSources)) {
					local.names = ListAppend(local.names, ArrayToList(application.wheels.tenantDataSources));
				} else if (Len(application.wheels.tenantDataSources)) {
					local.names = ListAppend(local.names, application.wheels.tenantDataSources);
				}
			}
		}
		try {
			local.meta = GetApplicationMetaData();
			if (IsStruct(local.meta) && StructKeyExists(local.meta, "datasources") && IsStruct(local.meta.datasources)) {
				for (local.dsName in local.meta.datasources) {
					local.names = ListAppend(local.names, local.dsName);
				}
			}
		} catch (any e) {
		}
		return local.names;
	}

	public numeric function $takeJobTimeout(required struct jobData, numeric fallback = 300) {
		local.timeout = arguments.fallback;
		if (StructKeyExists(arguments.jobData, "$wheelsJobTimeout") && IsNumeric(arguments.jobData["$wheelsJobTimeout"])) {
			local.timeout = Val(arguments.jobData["$wheelsJobTimeout"]);
		}
		StructDelete(arguments.jobData, "$wheelsJobTimeout");
		if (!IsNumeric(local.timeout) || local.timeout <= 0) {
			return 300;
		}
		return local.timeout;
	}

	public struct function $runPerformWithTimeout(
		required any jobInstance,
		required struct jobData,
		required numeric timeoutSeconds
	) {
		local.rv = {success = false, error = "", timedOut = false, hasResult = false, result = "", errorType = "", errorDetail = ""};
		local.timeoutMs = Max(1, Int(arguments.timeoutSeconds)) * 1000;
		local.threadName = "wheelsJob" & Replace(CreateUUID(), "-", "", "all");
		local.box = {instance = arguments.jobInstance, data = arguments.jobData, ok = false, err = ""};

		try {
			thread name="#local.threadName#" action="run" box="#local.box#" {
				try {
					// beforePerform/afterPerform are part of the work: they run under the same
					// timeout, and a throw from either fails the attempt.
					if (StructKeyExists(attributes.box.instance, "beforePerform")) {
						attributes.box.instance.beforePerform(data = attributes.box.data);
					}
					performResult = attributes.box.instance.perform(data = attributes.box.data);
					thread.hasResult = !IsNull(performResult);
					if (thread.hasResult) {
						thread.result = performResult;
					}
					if (StructKeyExists(attributes.box.instance, "afterPerform")) {
						if (thread.hasResult) {
							attributes.box.instance.afterPerform(data = attributes.box.data, result = performResult);
						} else {
							attributes.box.instance.afterPerform(data = attributes.box.data);
						}
					}
					thread.ok = true;
					thread.err = "";
				} catch (any e) {
					thread.ok = false;
					thread.err = e.message;
					thread.errType = e.type;
					thread.errDetail = e.detail;
				}
			}
			thread action="join" name="#local.threadName#" timeout="#local.timeoutMs#";
			local.meta = cfthread[local.threadName];
			local.status = StructKeyExists(local.meta, "status") ? ToString(local.meta.status) : "";
			if (CompareNoCase(local.status, "COMPLETED") != 0 && CompareNoCase(local.status, "TERMINATED") != 0) {
				try {
					thread action="terminate" name="#local.threadName#";
				} catch (any termErr) {
				}
				local.rv.timedOut = true;
				local.rv.error = "Job timed out after #arguments.timeoutSeconds# seconds";
				return local.rv;
			}
			if (StructKeyExists(local.meta, "ok") && local.meta.ok) {
				local.rv.success = true;
				if (StructKeyExists(local.meta, "hasResult") && local.meta.hasResult && StructKeyExists(local.meta, "result")) {
					local.rv.hasResult = true;
					local.rv.result = local.meta.result;
				}
				return local.rv;
			}
			local.rv.error = (StructKeyExists(local.meta, "err") && Len(local.meta.err)) ? local.meta.err : "Job failed";
			local.rv.errorType = StructKeyExists(local.meta, "errType") ? local.meta.errType : "";
			local.rv.errorDetail = StructKeyExists(local.meta, "errDetail") ? local.meta.errDetail : "";
			return local.rv;
		} catch (any threadErr) {
			// Fail closed. Inline perform() would hang until the job finished.
			local.rv.timedOut = true;
			local.rv.error = "Job timed out after #arguments.timeoutSeconds# seconds";
			return local.rv;
		}
	}

	/**
	 * Internal: runs perform() like $runPerformWithTimeout(), under the job's lease when it is
	 * exclusive or has a concurrency key. When another run holds the lease, perform() does not
	 * run: the outcome is `busy`, with `retryInSeconds` until the job should be tried again.
	 * The lease is released afterwards, except after a timeout: perform() may still be running
	 * in its thread then, so the lease is left to expire. `leaseLost` is true when the lease had
	 * already been taken over by the time the job finished.
	 */
	public struct function $runPerformExclusively(
		required any jobInstance,
		required struct jobData,
		required numeric timeoutSeconds,
		required string jobId,
		required string jobClass,
		required string claimToken,
		required numeric claimTimeout
	) {
		local.lease = $acquireJobLease(
			jobInstance = arguments.jobInstance,
			jobData = arguments.jobData,
			jobClass = arguments.jobClass,
			claimToken = arguments.claimToken,
			claimTimeout = arguments.claimTimeout
		);
		if (local.lease.busy) {
			return {success = false, error = "", timedOut = false, busy = true, retryInSeconds = local.lease.retryInSeconds, leaseName = local.lease.name, leaseLost = false};
		}
		if (local.lease.held) {
			// So heartbeat() inside perform() renews the lease as well as the claim.
			arguments.jobInstance.$setLeaseContext(name = local.lease.name, owner = local.lease.owner, windowSeconds = local.lease.windowSeconds);
		}
		local.outcome = $runPerformWithTimeout(
			jobInstance = arguments.jobInstance,
			jobData = arguments.jobData,
			timeoutSeconds = arguments.timeoutSeconds
		);
		local.outcome.busy = false;
		local.outcome.retryInSeconds = 0;
		local.outcome.leaseName = local.lease.name;
		local.outcome.leaseLost = false;
		if (local.lease.held && !local.outcome.timedOut) {
			local.outcome.leaseLost = !$releaseJobLease(lease = local.lease, jobId = arguments.jobId, jobClass = arguments.jobClass);
		}
		return local.outcome;
	}

	/**
	 * Internal: the lease a job run must hold, or "" when it needs none. A concurrency key (the
	 * job's concurrencyKeyFor(data) method, or else its this.concurrencyKey) names a lease shared
	 * by every job with that key; otherwise this.exclusive = true leases the job class. A name that
	 * would not fit the lock table is hashed.
	 */
	public string function $jobLeaseName(required any jobInstance, required struct jobData, required string jobClass) {
		local.key = "";
		if (StructKeyExists(arguments.jobInstance, "concurrencyKeyFor") && !IsSimpleValue(arguments.jobInstance.concurrencyKeyFor)) {
			local.key = arguments.jobInstance.concurrencyKeyFor(arguments.jobData);
		} else if (StructKeyExists(arguments.jobInstance, "concurrencyKey") && IsSimpleValue(arguments.jobInstance.concurrencyKey)) {
			local.key = arguments.jobInstance.concurrencyKey;
		}
		if (Len(Trim(local.key))) {
			return $fitLeaseName(prefix = "key:", value = Trim(local.key));
		}
		if (StructKeyExists(arguments.jobInstance, "exclusive") && IsBoolean(arguments.jobInstance.exclusive) && arguments.jobInstance.exclusive) {
			return $fitLeaseName(prefix = "job:", value = arguments.jobClass);
		}
		return "";
	}

	/**
	 * Internal: prefix & value, or prefix & the value's SHA-256 when that is longer than the lock
	 * table's 100-character name.
	 */
	public string function $fitLeaseName(required string prefix, required string value) {
		if (Len(arguments.prefix & arguments.value) <= 100) {
			return arguments.prefix & arguments.value;
		}
		return arguments.prefix & LCase(Hash(arguments.value, "SHA-256"));
	}

	/**
	 * Internal: takes the job's lease for this attempt, if it needs one. The owner is the
	 * attempt's claim token, and the lease lasts as long as the claim does before the row itself
	 * can be reaped (claimTimeout + Max(60, claimTimeout)), so it never ends inside the claim
	 * timeout. Returns `held`, `busy` (another run holds it), `retryInSeconds`, `name` and `owner`.
	 */
	public struct function $acquireJobLease(
		required any jobInstance,
		required struct jobData,
		required string jobClass,
		required string claimToken,
		required numeric claimTimeout
	) {
		local.rv = {held = false, busy = false, retryInSeconds = 0, name = "", owner = "", windowSeconds = 0};
		local.rv.name = $jobLeaseName(jobInstance = arguments.jobInstance, jobData = arguments.jobData, jobClass = arguments.jobClass);
		if (!Len(local.rv.name)) {
			return local.rv;
		}
		local.rv.owner = Len(arguments.claimToken) ? arguments.claimToken : CreateUUID();
		local.leaseLock = $jobLeaseLock();
		local.claimSeconds = Val(arguments.claimTimeout) > 0 ? Val(arguments.claimTimeout) : 300;
		local.now = local.leaseLock.nowMs();
		local.rv.windowSeconds = local.claimSeconds + Max(60, local.claimSeconds);
		local.expiresAt = local.now + local.rv.windowSeconds * 1000;
		if (local.leaseLock.tryAcquire(name = local.rv.name, owner = local.rv.owner, host = $jobHostName(), now = local.now, expiresAt = local.expiresAt)) {
			local.rv.held = true;
			return local.rv;
		}
		// Try again once the holder's lease runs out, but at least every 30 seconds: the holder
		// usually finishes and releases it well before then.
		local.holder = local.leaseLock.read(local.rv.name);
		local.remaining = local.holder.held ? Ceiling((local.holder.expiresAt - local.now) / 1000) : 1;
		local.rv.busy = true;
		local.rv.retryInSeconds = Min(30, Max(1, local.remaining));
		return local.rv;
	}

	/**
	 * Internal: releases a held job lease. False, with a warning logged, when the lease had
	 * already expired and been taken over (or removed): exclusivity is only as strong as the
	 * lease, and a run that outlives it may have overlapped another.
	 */
	public boolean function $releaseJobLease(required struct lease, required string jobId, required string jobClass) {
		var state = {released = false};
		try {
			state.released = $jobLeaseLock().release(name = arguments.lease.name, owner = arguments.lease.owner);
		} catch (any e) {
			WriteLog(type = "error", file = "wheels_jobs", text = "Job '#arguments.jobClass#' [#arguments.jobId#] could not release its lease '#arguments.lease.name#': #e.message#. It expires on its own.");
			return true;
		}
		if (!state.released) {
			WriteLog(
				type = "warning",
				file = "wheels_jobs",
				text = "Job '#arguments.jobClass#' [#arguments.jobId#] finished after losing its lease '#arguments.lease.name#': the lease expired while it ran, so another run may have overlapped it."
			);
		}
		return state.released;
	}

	/**
	 * Internal: puts a job whose lease is busy back to 'pending' to run in `delaySeconds`, and
	 * gives back the attempt its claim counted, so waiting on a busy lease never uses up retries.
	 * Fenced on the claim token like the other end-of-attempt UPDATEs. Returns the rows changed.
	 */
	public numeric function $deferJobForLease(
		required string jobId,
		required string jobClass,
		required string claimToken,
		required numeric delaySeconds,
		required string leaseName
	) {
		local.params = {
			runAt = {value = DateAdd("s", arguments.delaySeconds, $now()), cfsqltype = "cf_sql_timestamp"},
			updatedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"},
			id = {value = arguments.jobId, cfsqltype = "cf_sql_varchar"}
		};
		local.guard = $claimTokenGuard(claimToken = arguments.claimToken, params = local.params);
		local.clearToken = Len(arguments.claimToken) ? ", claimToken = NULL" : "";
		queryExecute(
			"UPDATE wheels_jobs
			SET status = 'pending', attempts = attempts - 1, runAt = :runAt, updatedAt = :updatedAt" & local.clearToken & "
			WHERE id = :id AND status = 'processing' AND attempts > 0" & local.guard,
			local.params,
			{datasource = variables.$datasource, result = "local.deferResult"}
		);
		WriteLog(
			type = "information",
			file = "wheels_jobs",
			text = "Job '#arguments.jobClass#' [#arguments.jobId#] waits #arguments.delaySeconds#s: another run holds its lease '#arguments.leaseName#'"
		);
		return Val(local.deferResult.recordCount ?: 0);
	}

	/**
	 * Internal: the lease lock over wheels_job_locks, creating the table on first use. Not inside
	 * a Wheels transaction: DDL there commits the open transaction on MySQL and Oracle, so the
	 * job fails with the reason instead and is retried outside it.
	 */
	public any function $jobLeaseLock() {
		if (!StructKeyExists(variables, "$jobLeaseLockInstance")) {
			local.leaseLock = new wheels.LeaseLock(table = "wheels_job_locks", datasource = variables.$datasource);
			$ensureJobLockTable(local.leaseLock);
			variables.$jobLeaseLockInstance = local.leaseLock;
		}
		return variables.$jobLeaseLockInstance;
	}

	/**
	 * Internal: creates wheels_job_locks when it is missing.
	 */
	public void function $ensureJobLockTable(required any leaseLock) {
		if ($jobLockTableExists()) {
			return;
		}
		if (!$jobSchema().autoCreateEnabled()) {
			$throwJobSchemaMissing("The wheels_job_locks table (needed by exclusive jobs)");
		}
		if (Len($outermostWheelsTransaction())) {
			Throw(
				type = "Wheels.JobLockTableMissing",
				message = "wheels_job_locks doesn't exist yet, and it can't be created inside a transaction. Run the job outside a transaction once, or create it with `wheels jobs install`."
			);
		}
		try {
			queryExecute($jobSchema().createTableSql(tableName = "wheels_job_locks", dbType = $detectDatabaseType()), {}, {datasource = variables.$datasource});
		} catch (any e) {
			// Tolerate "already exists" from another server creating it at the same time.
			if (!$jobLockTableExists()) {
				rethrow;
			}
		}
	}

	/**
	 * Internal: whether wheels_job_locks exists, asked of the database's catalog. A failing probe
	 * query would abort an enclosing PostgreSQL transaction, so one only runs outside a
	 * transaction, for a database without a known catalog query.
	 */
	public boolean function $jobLockTableExists() {
		local.catalogSql = $jobLockTableCatalogSql();
		if (Len(local.catalogSql)) {
			try {
				return queryExecute(local.catalogSql, {}, {datasource = variables.$datasource}).recordCount > 0;
			} catch (any e) {
				// Fall back to the probe below.
			}
		}
		if (Len($outermostWheelsTransaction())) {
			return false;
		}
		try {
			queryExecute("SELECT COUNT(*) AS cnt FROM wheels_job_locks WHERE 1=0", {}, {datasource = variables.$datasource});
			return true;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Internal: the catalog query that finds wheels_job_locks ("" for an unknown database).
	 */
	public string function $jobLockTableCatalogSql() {
		switch ($detectDatabaseType()) {
			case "postgresql":
				return "SELECT 1 FROM information_schema.tables WHERE table_schema = current_schema() AND LOWER(table_name) = 'wheels_job_locks'";
			case "mysql":
				return "SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND LOWER(table_name) = 'wheels_job_locks'";
			case "sqlserver":
				return "SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE LOWER(TABLE_NAME) = 'wheels_job_locks' AND TABLE_SCHEMA = SCHEMA_NAME()";
			case "oracle":
				return "SELECT 1 FROM user_tables WHERE UPPER(table_name) = 'WHEELS_JOB_LOCKS'";
			case "h2":
				return "SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE UPPER(TABLE_NAME) = 'WHEELS_JOB_LOCKS'";
			case "sqlite":
				return "SELECT 1 FROM sqlite_master WHERE type = 'table' AND LOWER(name) = 'wheels_job_locks'";
			default:
				return "";
		}
	}

	/**
	 * Retry delay in seconds. `retryBackoff=exponential` is the live schedule
	 * (`baseDelay * 2^attempts`, capped at `maxDelay`). `linear` is a reserved
	 * no-op and keeps that same formula.
	 */
	public numeric function $backoffDelay(
		required numeric attempts,
		numeric baseDelay = this.baseDelay,
		numeric maxDelay = this.maxDelay,
		string retryBackoff = this.retryBackoff
	) {
		if (CompareNoCase(arguments.retryBackoff, "linear") == 0) {
			// reserved no-op — exponential remains the schedule
		}
		return Min(arguments.baseDelay * (2 ^ arguments.attempts), arguments.maxDelay);
	}

	/**
	 * Returns Now() truncated to whole seconds.
	 * Prevents MySQL/H2 DATETIME rounding: when fractional seconds >= 0.5,
	 * these databases round UP to the next second, making runAt appear in the future.
	 */
	private date function $now() {
		local.n = Now();
		return CreateDateTime(Year(local.n), Month(local.n), Day(local.n), Hour(local.n), Minute(local.n), Second(local.n));
	}

	/**
	 * Detect the database type from the actual datasource via JDBC metadata.
	 * Returns: "oracle", "postgresql", "h2", "mysql", "sqlserver", "sqlite", or "default".
	 * Public with $ prefix so JobWorker can pick database-appropriate SQL syntax.
	 */
	public string function $detectDatabaseType() {
		return $databaseTypeOf(variables.$datasource);
	}

	/**
	 * The database type behind a datasource, as $detectDatabaseType() reports it. Separate so
	 * wheels.JobSchema can ask about the migrator's datasource, which may not be the app's.
	 */
	public string function $databaseTypeOf(required string datasourceName) {
		try {
			cfdbinfo(type = "version", datasource = "#arguments.datasourceName#", name = "local.info");
			local.product = local.info.database_productname;
			if (FindNoCase("oracle", local.product)) return "oracle";
			if (FindNoCase("postgre", local.product)) return "postgresql";
			if (FindNoCase("h2", local.product)) return "h2";
			if (FindNoCase("mysql", local.product) || FindNoCase("mariadb", local.product)) return "mysql";
			if (FindNoCase("sql server", local.product)) return "sqlserver";
			if (FindNoCase("sqlite", local.product)) return "sqlite";
		} catch (any e) {
			// cfdbinfo not available — fall through to default
		}
		return "default";
	}
}
