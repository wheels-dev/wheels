/**
 * Recurring job schedules. Schedules live in wheels_job_schedules: code-defined ones come from
 * config/schedules.cfm (synced at application start, source 'code'), and an app may insert its
 * own rows at runtime (source 'db', e.g. from an admin page).
 *
 * Call enqueueDue() regularly — from a scheduled task, or next to your job worker — on one or
 * every server:
 *
 *   new wheels.JobScheduler().enqueueDue();
 *
 * Each due slot is enqueued with uniqueKey "<schedule>:<slot time, UTC ISO>", so any number of
 * servers calling it produce one job per slot.
 */
component {

	public function init() {
		variables.$job = new wheels.Job();
		variables.$cron = new wheels.JobCron();
		variables.$definitions = [];
		variables.$datasource = "";
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "dataSourceName")) {
			variables.$datasource = application.wheels.dataSourceName;
		}
		return this;
	}

	/**
	 * Enqueue every schedule's due slot. For each enabled schedule that is due: the newest slot
	 * not yet enqueued — within its catch-up window ("latest", default 3600s) or only if it is
	 * current ("none") — is enqueued once; older missed slots are skipped, and a slot at or
	 * before the last one enqueued never runs again. A schedule seen for the first time starts
	 * from now: it doesn't fire slots from before it existed.
	 * Returns {checked, enqueued, duplicates, skipped, errors}.
	 * @nowMs The current time in epoch milliseconds (for tests); default: now.
	 */
	public struct function enqueueDue(numeric nowMs = -1) {
		var rv = {checked = 0, enqueued = 0, duplicates = 0, skipped = 0, errors = []};
		local.now = arguments.nowMs >= 0 ? arguments.nowMs : $nowMs();
		if (!$ensureSchedulesTable()) {
			return rv;
		}
		local.rows = queryExecute(
			"SELECT name, jobClass, data, queue, priority, kind, spec, timezone, catchUp, catchUpWindowSeconds, lastEnqueuedFor, lastError
			FROM wheels_job_schedules
			WHERE enabled = 1 AND (nextRunAt IS NULL OR nextRunAt <= :now)",
			{now = $ms(local.now)},
			{datasource = variables.$datasource}
		);
		for (local.row in local.rows) {
			rv.checked++;
			try {
				local.outcome = $runSchedule(row = local.row, now = local.now);
				rv[local.outcome]++;
			} catch (any e) {
				ArrayAppend(rv.errors, "#local.row.name#: #e.message#");
				$recordScheduleError(name = local.row.name, message = e.message, now = local.now, previous = local.row.lastError ?: "");
			}
		}
		return rv;
	}

	/**
	 * DSL for config/schedules.cfm: start a schedule definition.
	 */
	public any function schedule(required string name) {
		local.def = new wheels.JobSchedule(arguments.name);
		ArrayAppend(variables.$definitions, local.def);
		return local.def;
	}

	/**
	 * Internal: the schedules defined so far with schedule() (by a schedules file or a caller).
	 */
	public array function $loadedDefinitions() {
		return variables.$definitions;
	}

	/**
	 * Internal: read config/schedules.cfm (or `template`) and sync it to wheels_job_schedules.
	 * Without the file, code-defined schedules already in the table are disabled.
	 */
	public struct function $syncFromConfig(string template = "/config/schedules.cfm") {
		if (FileExists(ExpandPath(arguments.template))) {
			return $syncDefinitions($loadDefinitions(arguments.template));
		}
		if ($schedulesTableExists()) {
			return $syncDefinitions([]);
		}
		return {synced = 0, disabled = 0, skipped = 0};
	}

	/**
	 * Internal: run a schedules file with schedule() in scope and return its definitions.
	 */
	public array function $loadDefinitions(required string template) {
		variables.$definitions = [];
		// $-prefixed locals so nothing here shadows a variable in the included file.
		local.$template = arguments.template;
		var $scheduleOutput = "";
		savecontent variable="$scheduleOutput" {
			include "#local.$template#";
		}
		return variables.$definitions;
	}

	/**
	 * Internal: make wheels_job_schedules match the code-defined schedules. Each one is
	 * inserted or updated by name (source 'code'); code schedules no longer defined are
	 * disabled, not deleted; rows an app inserted (source 'db') are never changed, and a code
	 * schedule whose name a db row already holds is skipped with a warning.
	 * Throws Wheels.Job.InvalidSchedule for an invalid definition.
	 */
	public struct function $syncDefinitions(required array definitions, numeric nowMs = -1) {
		local.now = arguments.nowMs >= 0 ? arguments.nowMs : $nowMs();
		local.rv = {synced = 0, disabled = 0, skipped = 0};
		local.defs = [];
		for (local.item in arguments.definitions) {
			local.def = local.item.$definition(variables.$cron);
			local.def.jobClass = $resolveJobClass(local.def.jobClass, local.def.name);
			ArrayAppend(local.defs, local.def);
		}
		if (!$ensureSchedulesTable()) {
			return local.rv;
		}
		local.names = [];
		for (local.def in local.defs) {
			ArrayAppend(local.names, local.def.name);
			if ($upsertCodeSchedule(def = local.def, now = local.now)) {
				local.rv.synced++;
			} else {
				local.rv.skipped++;
			}
		}
		local.rv.disabled = $disableRemovedCodeSchedules(local.names);
		return local.rv;
	}

	// ---- one schedule ------------------------------------------------------------------------

	/**
	 * Enqueue one schedule's due slot, if any. Returns the counter to bump: enqueued,
	 * duplicates or skipped.
	 */
	private string function $runSchedule(required struct row, required numeric now) {
		local.name = arguments.row.name;
		local.cron = arguments.row.kind == "cron" ? variables.$cron.parse(arguments.row.spec) : {};
		local.zone = Len(arguments.row.timezone ?: "") ? arguments.row.timezone : "UTC";

		// First sight (a new db row): start from now; don't fire slots from before it existed.
		if (!IsNumeric(arguments.row.lastEnqueuedFor ?: "")) {
			$advance(name = local.name, lastEnqueuedFor = arguments.now, nextRunAt = $nextSlot(arguments.row, local.cron, local.zone, arguments.now), now = arguments.now);
			return "skipped";
		}

		local.last = Val(arguments.row.lastEnqueuedFor);
		local.window = arguments.row.catchUp == "none" ? 60 : Max(60, Val(arguments.row.catchUpWindowSeconds));
		local.floor = arguments.now - local.window * 1000;
		// Walk forward from the later of the last slot enqueued and the window's start; keep
		// the newest slot that is due now. Older missed slots are skipped.
		local.from = Max(local.last, local.floor - 1);
		local.slot = -1;
		local.next = $nextSlot(arguments.row, local.cron, local.zone, local.from);
		local.guard = 0;
		while (local.next > 0 && local.next <= arguments.now && local.guard < 100000) {
			local.slot = local.next;
			local.next = $nextSlot(arguments.row, local.cron, local.zone, local.next);
			local.guard++;
		}

		if (local.slot < 0) {
			// Nothing due. Skipped slots before the window still count as passed.
			$advance(name = local.name, lastEnqueuedFor = Max(local.last, local.floor - 1), nextRunAt = local.next, now = arguments.now);
			return "skipped";
		}

		local.result = $enqueueSlot(row = arguments.row, slot = local.slot);
		$advance(name = local.name, lastEnqueuedFor = local.slot, nextRunAt = local.next, now = arguments.now);
		return local.result.duplicate ? "duplicates" : "enqueued";
	}

	private numeric function $nextSlot(required struct row, required struct cron, required string zone, required numeric afterMs) {
		if (arguments.row.kind == "interval") {
			return variables.$cron.nextInterval(Val(arguments.row.spec), arguments.afterMs);
		}
		return variables.$cron.nextCron(arguments.cron, arguments.afterMs, arguments.zone);
	}

	/**
	 * Enqueue the job for one slot, deduplicated across servers by its slot key.
	 */
	private struct function $enqueueSlot(required struct row, required numeric slot) {
		local.job = variables.$job.$instantiateJobClass(jobClass = arguments.row.jobClass);
		local.args = {
			data = IsJSON(arguments.row.data ?: "") ? DeserializeJSON(arguments.row.data) : {},
			uniqueKey = "#arguments.row.name#:#variables.$cron.isoUtc(arguments.slot)#"
		};
		if (!IsStruct(local.args.data)) {
			local.args.data = {};
		}
		if (Len(arguments.row.queue ?: "")) {
			local.args.queue = arguments.row.queue;
		}
		if (IsNumeric(arguments.row.priority ?: "")) {
			local.args.priority = arguments.row.priority;
		}
		return local.job.enqueue(argumentCollection = local.args);
	}

	/**
	 * Move the schedule forward. lastEnqueuedFor only ever increases (another server may have
	 * moved it further already); nextRunAt is when it is next worth checking.
	 */
	private void function $advance(required string name, required numeric lastEnqueuedFor, required numeric nextRunAt, required numeric now) {
		local.next = arguments.nextRunAt > 0 ? $ms(arguments.nextRunAt) : $ms(arguments.now + 86400000);
		queryExecute(
			"UPDATE wheels_job_schedules
			SET lastEnqueuedFor = :lastEnqueuedFor, nextRunAt = :nextRunAt, lastError = NULL, updatedAt = :updatedAt
			WHERE name = :name AND (lastEnqueuedFor IS NULL OR lastEnqueuedFor < :lastEnqueuedForGuard)",
			{
				lastEnqueuedFor = $ms(arguments.lastEnqueuedFor),
				lastEnqueuedForGuard = $ms(arguments.lastEnqueuedFor),
				nextRunAt = local.next,
				updatedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"},
				name = {value = arguments.name, cfsqltype = "cf_sql_varchar"}
			},
			{datasource = variables.$datasource, result = "local.moved"}
		);
		if (Val(local.moved.recordCount ?: 0) == 0) {
			// Another server is ahead: only keep the check time current.
			queryExecute(
				"UPDATE wheels_job_schedules SET nextRunAt = :nextRunAt WHERE name = :name AND (nextRunAt IS NULL OR nextRunAt < :nextRunAtGuard)",
				{nextRunAt = local.next, nextRunAtGuard = local.next, name = {value = arguments.name, cfsqltype = "cf_sql_varchar"}},
				{datasource = variables.$datasource}
			);
		}
	}

	/**
	 * Record why a schedule couldn't run (a bad cron in a db row, an unknown job class, no
	 * uniqueKey support yet), logged once per message, and check it again in a minute.
	 */
	private void function $recordScheduleError(required string name, required string message, required numeric now, string previous = "") {
		try {
			queryExecute(
				"UPDATE wheels_job_schedules SET lastError = :lastError, nextRunAt = :nextRunAt WHERE name = :name",
				{
					lastError = {value = Left(arguments.message, 1000), cfsqltype = "cf_sql_varchar"},
					nextRunAt = $ms(arguments.now + 60000),
					name = {value = arguments.name, cfsqltype = "cf_sql_varchar"}
				},
				{datasource = variables.$datasource}
			);
		} catch (any e) {
			// The log line below still reports it.
		}
		if (Left(arguments.message, 1000) != arguments.previous) {
			writeLog(text = "Job schedule '#arguments.name#' could not run: #arguments.message#", type = "error", file = "wheels_jobs");
		}
	}

	// ---- sync --------------------------------------------------------------------------------

	/**
	 * Insert or update one code-defined schedule. False when a db row holds the name.
	 */
	private boolean function $upsertCodeSchedule(required struct def, required numeric now) {
		local.existing = queryExecute(
			"SELECT source FROM wheels_job_schedules WHERE name = :name",
			{name = {value = arguments.def.name, cfsqltype = "cf_sql_varchar"}},
			{datasource = variables.$datasource}
		);
		if (local.existing.recordCount && local.existing.source != "code") {
			writeLog(text = "Job schedule '#arguments.def.name#' in config/schedules.cfm was skipped: a schedule the app added at runtime already has that name", type = "warning", file = "wheels_jobs");
			return false;
		}
		local.params = $definitionParams(arguments.def);
		if (local.existing.recordCount) {
			// nextRunAt NULL: check it on the next enqueueDue(), as its timing may have changed.
			queryExecute(
				"UPDATE wheels_job_schedules
				SET jobClass = :jobClass, data = :data, queue = :queue, priority = :priority, kind = :kind, spec = :spec,
					timezone = :timezone, catchUp = :catchUp, catchUpWindowSeconds = :catchUpWindowSeconds, enabled = :enabled,
					nextRunAt = NULL, lastError = NULL, updatedAt = :updatedAt
				WHERE name = :name AND source = 'code'",
				local.params,
				{datasource = variables.$datasource}
			);
			return true;
		}
		local.params.lastEnqueuedFor = $ms(arguments.now);
		try {
			queryExecute(
				"INSERT INTO wheels_job_schedules
				(name, jobClass, data, queue, priority, kind, spec, timezone, catchUp, catchUpWindowSeconds, enabled, source, lastEnqueuedFor, updatedAt)
				VALUES (:name, :jobClass, :data, :queue, :priority, :kind, :spec, :timezone, :catchUp, :catchUpWindowSeconds, :enabled, 'code', :lastEnqueuedFor, :updatedAt)",
				local.params,
				{datasource = variables.$datasource}
			);
		} catch (any e) {
			// Another server inserted it at the same moment: it exists now, which is all we need.
			if (!$scheduleExists(arguments.def.name)) {
				rethrow;
			}
		}
		return true;
	}

	private struct function $definitionParams(required struct def) {
		return {
			name = {value = arguments.def.name, cfsqltype = "cf_sql_varchar"},
			jobClass = {value = arguments.def.jobClass, cfsqltype = "cf_sql_varchar"},
			data = {value = SerializeJSON(arguments.def.data), cfsqltype = "cf_sql_longvarchar"},
			queue = {value = arguments.def.queue, cfsqltype = "cf_sql_varchar", null = !Len(arguments.def.queue)},
			priority = {value = Val(arguments.def.priority), cfsqltype = "cf_sql_integer", null = !IsNumeric(arguments.def.priority)},
			kind = {value = arguments.def.kind, cfsqltype = "cf_sql_varchar"},
			spec = {value = ToString(arguments.def.spec), cfsqltype = "cf_sql_varchar"},
			timezone = {value = arguments.def.timezone, cfsqltype = "cf_sql_varchar"},
			catchUp = {value = arguments.def.catchUp, cfsqltype = "cf_sql_varchar"},
			catchUpWindowSeconds = {value = arguments.def.catchUpWindowSeconds, cfsqltype = "cf_sql_integer"},
			enabled = {value = arguments.def.enabled ? 1 : 0, cfsqltype = "cf_sql_integer"},
			updatedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"}
		};
	}

	/**
	 * Disable code-defined schedules that aren't in `names` any more. Returns how many.
	 */
	private numeric function $disableRemovedCodeSchedules(required array names) {
		local.sql = "UPDATE wheels_job_schedules SET enabled = 0, updatedAt = :updatedAt WHERE source = 'code' AND enabled = 1";
		local.params = {updatedAt = {value = $now(), cfsqltype = "cf_sql_timestamp"}};
		if (ArrayLen(arguments.names)) {
			local.placeholders = [];
			for (local.i = 1; local.i <= ArrayLen(arguments.names); local.i++) {
				ArrayAppend(local.placeholders, ":keep#local.i#");
				local.params["keep#local.i#"] = {value = arguments.names[local.i], cfsqltype = "cf_sql_varchar"};
			}
			local.sql &= " AND name NOT IN (#ArrayToList(local.placeholders)#)";
		}
		queryExecute(local.sql, local.params, {datasource = variables.$datasource, result = "local.disabled"});
		return Val(local.disabled.recordCount ?: 0);
	}

	/**
	 * A schedule's job class as a component path: a full path on the jobs allowlist as is, or a
	 * name under app/jobs ("DigestJob", "billing.InvoiceJob"). Throws Wheels.Job.InvalidSchedule.
	 */
	private string function $resolveJobClass(required string jobClass, required string name) {
		// A dotted component path. A class that doesn't exist is reported when its first slot is
		// enqueued (lastError and the jobs log).
		if (!REFind("^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$", arguments.jobClass)) {
			Throw(
				type = "Wheels.Job.InvalidSchedule",
				message = "Schedule '#arguments.name#': '#arguments.jobClass#' isn't a job class name (use e.g. DigestJob, billing.InvoiceJob, or a full component path)."
			);
		}
		if (variables.$job.$isAllowedJobClass(arguments.jobClass)) {
			return arguments.jobClass;
		}
		local.underAppJobs = "app.jobs." & arguments.jobClass;
		if (variables.$job.$isAllowedJobClass(local.underAppJobs)) {
			return local.underAppJobs;
		}
		Throw(
			type = "Wheels.Job.InvalidSchedule",
			message = "Schedule '#arguments.name#': '#arguments.jobClass#' isn't a job class on the jobs allowlist (app.jobs plus any jobClassPrefixes)."
		);
	}

	// ---- table -------------------------------------------------------------------------------

	/**
	 * Create wheels_job_schedules when it is missing. Never inside an open transaction (DDL
	 * commits the caller's work on MySQL/Oracle). Returns whether the table exists now.
	 */
	public boolean function $ensureSchedulesTable() {
		if ($schedulesTableExists()) {
			return true;
		}
		if (!variables.$job.$jobSchema().autoCreateEnabled()) {
			variables.$job.$warnAuxTableMissingOnce("wheels_job_schedules", "schedules aren't enqueued");
			return false;
		}
		if (Len(variables.$job.$outermostWheelsTransaction())) {
			return false;
		}
		try {
			queryExecute(
				variables.$job.$jobSchema().createTableSql(tableName = "wheels_job_schedules", dbType = variables.$job.$detectDatabaseType()),
				{},
				{datasource = variables.$datasource}
			);
			writeLog(text = "Auto-created wheels_job_schedules table", type = "information", file = "wheels_jobs");
		} catch (any e) {
			if (!$schedulesTableExists()) {
				writeLog(text = "Failed to auto-create wheels_job_schedules table: #e.message#", type = "error", file = "wheels_jobs");
				return false;
			}
		}
		return true;
	}

	public boolean function $schedulesTableExists() {
		try {
			queryExecute("SELECT name FROM wheels_job_schedules WHERE 1=0", {}, {datasource = variables.$datasource});
			return true;
		} catch (any e) {
			return false;
		}
	}

	private boolean function $scheduleExists(required string name) {
		return queryExecute(
			"SELECT name FROM wheels_job_schedules WHERE name = :name",
			{name = {value = arguments.name, cfsqltype = "cf_sql_varchar"}},
			{datasource = variables.$datasource}
		).recordCount > 0;
	}

	// ---- small helpers -----------------------------------------------------------------------

	/** An epoch-ms instant as a query parameter (DECIMAL(15,0) columns). */
	private struct function $ms(required numeric value) {
		return {value = arguments.value, cfsqltype = "cf_sql_bigint"};
	}

	/**
	 * Now in epoch milliseconds: System.currentTimeMillis() where Java is available, else
	 * GetTickCount() (epoch milliseconds on Lucee, Adobe and BoxLang).
	 */
	public numeric function $nowMs() {
		try {
			return CreateObject("java", "java.lang.System").currentTimeMillis();
		} catch (any e) {
			return GetTickCount();
		}
	}

	/** The current time on the jobs clock (wheels.JobClock): UTC, from the database's clock. */
	private date function $now() {
		return variables.$job.$jobClock().utcNow();
	}

}
