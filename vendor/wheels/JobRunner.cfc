/**
 * Runs background jobs for one host, and controls that host: a per-host concurrency cap, a
 * registry row in wheels_job_hosts, and drain/resume for deploys.
 *
 * Call tick() from a scheduled task (or any loop) on each app server:
 *
 *   new wheels.JobRunner().tick(queues = "default,reports", maxConcurrent = 2);
 *
 * Before a deploy, drain the host so it starts nothing new while its running jobs finish:
 *
 *   new wheels.JobRunner().drain(expiresInSeconds = 600);   // and resume() afterwards
 *
 * "Host" is the name the worker records in wheels_jobs.claimedBy: the machine's host name, or
 * set(jobsHostName = "...") when several app servers share one machine.
 */
component {

	public function init() {
		variables.$job = new wheels.Job();
		return this;
	}

	/**
	 * One round for this host: refresh its registry row, reap the queues it serves, then —
	 * unless it is draining or already running its cap — run up to maxJobs jobs, one after
	 * another, in this request.
	 * @queues Comma-delimited queues to serve. Empty = all queues.
	 * @maxConcurrent Most jobs this host may run at once. -1 (default) = set(jobsMaxConcurrentPerHost); 0 = no cap.
	 * @timeout Seconds a single job may run (as for processNext()).
	 * @maxJobs Most jobs to run in this call.
	 */
	public struct function tick(string queues = "", numeric maxConcurrent = -1, numeric timeout = 300, numeric maxJobs = 1) {
		variables.$job.$ensureJobTable();
		variables.$job.$ensureHostsTable();
		local.host = variables.$job.$jobHostName();
		local.cap = arguments.maxConcurrent >= 0 ? Int(arguments.maxConcurrent) : variables.$job.$jobsMaxConcurrentPerHost();
		local.rv = {host = local.host, processed = 0, failed = 0, fenced = 0, reaped = 0, scheduled = 0, capped = false, draining = false};

		local.worker = new wheels.JobWorker();
		local.worker.maxConcurrentPerHost = local.cap;
		local.rv.reaped = local.worker.checkTimeouts(timeout = arguments.timeout, queues = arguments.queues);
		// Due schedules first, so a slot that is due now can run in this same tick.
		local.rv.scheduled = variables.$job.$enqueueDueSchedules().enqueued;

		local.limit = Max(1, Int(Val(arguments.maxJobs)));
		for (local.i = 1; local.i <= local.limit; local.i++) {
			local.outcome = local.worker.processNext(queues = arguments.queues, timeout = arguments.timeout);
			if (local.outcome.draining) {
				local.rv.draining = true;
				break;
			}
			if (local.outcome.capped) {
				local.rv.capped = true;
				break;
			}
			if (!Len(local.outcome.jobId)) {
				// Nothing ready to run.
				break;
			}
			if (local.outcome.fenced) {
				local.rv.fenced++;
			} else if (local.outcome.success) {
				local.rv.processed++;
			} else {
				local.rv.failed++;
			}
		}

		$touchHost(host = local.host, maxConcurrent = local.cap);
		return local.rv;
	}

	/**
	 * Stop this host from starting new jobs. Jobs already running finish; stale jobs are still
	 * reaped. The drain lifts itself after expiresInSeconds (so a deploy that never calls
	 * resume() doesn't leave the host idle for good); 0 or less means until resume().
	 */
	public struct function drain(numeric expiresInSeconds = 3600) {
		$requireHostsTable();
		local.expiresAt = {value = "", cfsqltype = "wheels_epoch", null = true};
		if (arguments.expiresInSeconds > 0) {
			local.expiresAt = {value = $now() + Int(arguments.expiresInSeconds), cfsqltype = "wheels_epoch"};
		}
		local.host = variables.$job.$jobHostName();
		variables.$job.$writeHostRow(
			host = local.host,
			fields = {
				draining = {value = 1, cfsqltype = "cf_sql_integer"},
				drainExpiresAt = local.expiresAt,
				lastSeenAt = {value = $now(), cfsqltype = "wheels_epoch"}
			}
		);
		writeLog(text = "Jobs host '#local.host#' is draining: no new jobs will start here until it is resumed or the drain expires", type = "information", file = "wheels_jobs");
		return status();
	}

	/**
	 * Let this host start jobs again.
	 */
	public struct function resume() {
		$requireHostsTable();
		local.host = variables.$job.$jobHostName();
		variables.$job.$writeHostRow(
			host = local.host,
			fields = {
				draining = {value = 0, cfsqltype = "cf_sql_integer"},
				drainExpiresAt = {value = "", cfsqltype = "wheels_epoch", null = true},
				lastSeenAt = {value = $now(), cfsqltype = "wheels_epoch"}
			}
		);
		writeLog(text = "Jobs host '#local.host#' resumed", type = "information", file = "wheels_jobs");
		return status();
	}

	/**
	 * This host's state: `host`, `running` (jobs it is running now), `maxConcurrent` (the
	 * configured cap, 0 = none), `draining` (in effect now), `drainExpiresAt`, `lastSeenAt`
	 * and `codeVersion` (the last two from its registry row, "" before it has one).
	 */
	public struct function status() {
		local.host = variables.$job.$jobHostName();
		local.rv = {
			host = local.host,
			running = variables.$job.$runningOnHost(local.host),
			maxConcurrent = variables.$job.$jobsMaxConcurrentPerHost(),
			draining = variables.$job.$hostDraining(local.host),
			drainExpiresAt = "",
			lastSeenAt = "",
			codeVersion = ""
		};
		if (variables.$job.$hostsTableExists()) {
			local.row = $jobsQuery(
				"SELECT " & variables.$job.$jobClock().epochSql("drainExpiresAt") & " AS drainExpiresAt, " & variables.$job.$jobClock().epochSql("lastSeenAt") & " AS lastSeenAt, codeVersion FROM wheels_job_hosts WHERE host = :host",
				{host = {value = local.host, cfsqltype = "cf_sql_varchar"}},
				{datasource = $datasource()}
			);
			if (local.row.recordCount) {
				// Read as epoch seconds on the jobs clock; reported in the app's local time.
				local.clock = variables.$job.$jobClock();
				local.rv.drainExpiresAt = IsNull(local.row.drainExpiresAt[1]) ? "" : local.clock.toLocal(local.row.drainExpiresAt[1]);
				local.rv.lastSeenAt = IsNull(local.row.lastSeenAt[1]) ? "" : local.clock.toLocal(local.row.lastSeenAt[1]);
				local.rv.codeVersion = IsNull(local.row.codeVersion[1]) ? "" : local.row.codeVersion[1];
			}
		}
		return local.rv;
	}

	/**
	 * Refresh this host's registry row: last seen now, its cap, how many jobs it is running,
	 * and the code version it runs.
	 */
	private void function $touchHost(required string host, required numeric maxConcurrent) {
		if (!variables.$job.$hostsTableExists()) {
			return;
		}
		variables.$job.$writeHostRow(
			host = arguments.host,
			fields = {
				lastSeenAt = {value = $now(), cfsqltype = "wheels_epoch"},
				running = {value = variables.$job.$runningOnHost(arguments.host), cfsqltype = "cf_sql_integer"},
				maxConcurrent = {value = arguments.maxConcurrent, cfsqltype = "cf_sql_integer"},
				codeVersion = {value = variables.$job.$jobsCodeVersion(), cfsqltype = "cf_sql_varchar"}
			}
		);
	}

	/**
	 * drain()/resume() need the registry. Inside an open transaction it can't be created (DDL
	 * there commits the caller's work on MySQL/Oracle), so say so rather than fail obscurely.
	 */
	private void function $requireHostsTable() {
		if (!variables.$job.$ensureHostsTable()) {
			Throw(
				type = "Wheels.Job.HostsTableUnavailable",
				message = "The wheels_job_hosts table doesn't exist and couldn't be created here, so this host can't be drained or resumed.",
				extendedInfo = "It is created on first use outside a transaction (a tick() or drain() call outside any model transaction does it). Check the jobs log for a creation error, or create it with the install migration."
			);
		}
	}

	/**
	 * The current time on the jobs clock (wheels.JobClock): UTC epoch seconds, from the database's
	 * clock.
	 */
	private numeric function $now() {
		return variables.$job.$jobClock().nowEpoch();
	}

	/**
	 * Internal: queryExecute() with wheels_epoch timestamp parameters (see wheels.JobClock).
	 */
	private any function $jobsQuery(required string sql, struct params = {}, struct options = {}) {
		return variables.$job.$jobClock().query(arguments.sql, arguments.params, arguments.options);
	}

	private string function $datasource() {
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "dataSourceName")) {
			return application.wheels.dataSourceName;
		}
		return "";
	}

}
