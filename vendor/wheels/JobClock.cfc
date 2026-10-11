/**
 * The background-job clock: UTC, on the database's clock, so every server sharing the job tables
 * reads the same time. A server whose own clock runs ahead or behind can't reap a live job early
 * or pick up a delayed job late.
 *
 * The clock works in UTC epoch seconds and never builds a CFML date: a date held in the JVM's
 * local time zone can't represent every UTC time (in a zone with daylight saving, the hour the
 * clocks skip doesn't exist locally), so a UTC time is only ever turned into a timestamp by the
 * database, from integers.
 * - At most every 60 seconds per application and datasource it reads the database's UTC time as
 *   epoch seconds and keeps skew = that - this server's epoch seconds. nowEpoch() is this
 *   server's epoch seconds plus the skew. Precision is about a second (the read's round trip).
 * - A failed read keeps the last good skew and logs once. With no good read yet the skew is 0
 *   (this server's own clock), and that is logged once too.
 * - H2 (1.4 has no UTC-now expression) and SQLite use this server's clock: both are single-host
 *   databases.
 *
 * A timestamp parameter is {value = <epoch seconds>, cfsqltype = "wheels_epoch"}. prepare() and
 * query() turn each one into the database's expression for that UTC time (timestampSql()), and
 * epochSql() reads a column back as epoch seconds. SQLite's columns hold epoch milliseconds.
 *
 * The CFML-facing API stays in app-local time: fromLocal() converts a local date/time on the way
 * in (enqueueAt()), toLocal() an epoch on the way out (status and queue stats).
 */
component {

	/**
	 * @datasource The datasource holding the job tables.
	 * @job A wheels.Job, asked once for the datasource's database type.
	 */
	public any function init(required string datasource, required any job) {
		variables.$datasource = arguments.datasource;
		variables.$job = arguments.job;
		return this;
	}

	/**
	 * The current time in UTC epoch seconds on the database's clock.
	 */
	public numeric function nowEpoch() {
		return $appEpoch() + skewSeconds();
	}

	/**
	 * A date/time in app-local time as epoch seconds on the jobs clock.
	 */
	public numeric function fromLocal(required date localDateTime) {
		return $floorDiv(arguments.localDateTime.getTime(), 1000) + skewSeconds();
	}

	/**
	 * Epoch seconds on the jobs clock as an app-local date/time. Anything that isn't a number (a
	 * NULL read as "") comes back unchanged.
	 */
	public any function toLocal(required any epochSeconds) {
		if (IsSimpleValue(arguments.epochSeconds) && !Len(arguments.epochSeconds)) {
			return "";
		}
		if (!IsNumeric(arguments.epochSeconds)) {
			// An unrecognised database's column, read as it is (epochSql()).
			return IsDate(arguments.epochSeconds) ? arguments.epochSeconds : application.wo.$normalizeDbTimestamp(arguments.epochSeconds);
		}
		return application.wo.$normalizeDbTimestamp((arguments.epochSeconds - skewSeconds()) * 1000);
	}

	/**
	 * Runs a query whose wheels_epoch parameters are turned into timestamps (see prepare()).
	 * Callers that need the `result` option call prepare() and queryExecute() themselves.
	 */
	public any function query(required string sql, struct params = {}, struct options = {}) {
		local.prepared = prepare(arguments.sql, arguments.params);
		local.options = Duplicate(arguments.options);
		if (!StructKeyExists(local.options, "datasource")) {
			local.options.datasource = variables.$datasource;
		}
		return queryExecute(local.prepared.sql, local.prepared.params, local.options);
	}

	/**
	 * Replaces each :name whose parameter is {value = <epoch seconds>, cfsqltype = "wheels_epoch"}
	 * with timestampSql() (NULL for a null parameter) and returns {sql, params}. Other parameters
	 * pass through unchanged.
	 */
	public struct function prepare(required string sql, struct params = {}) {
		local.rv = {sql = arguments.sql, params = {}};
		for (local.name in arguments.params) {
			local.param = arguments.params[local.name];
			if (!IsStruct(local.param) || !StructKeyExists(local.param, "cfsqltype") || local.param.cfsqltype != "wheels_epoch") {
				local.rv.params[local.name] = local.param;
				continue;
			}
			if (StructKeyExists(local.param, "null") && local.param.null == true) {
				local.fragment = "NULL";
			} else {
				local.fragment = timestampSql(name = local.name, epochSeconds = local.param.value, params = local.rv.params);
			}
			local.rv.sql = ReReplaceNoCase(local.rv.sql, ":#local.name#(?![A-Za-z0-9_])", local.fragment, "all");
		}
		return local.rv;
	}

	/**
	 * The database's expression for a UTC time, adding the parameters it binds to `params`. The
	 * time is bound as whole days and seconds since 1970-01-01, two small integers, so no engine
	 * builds a local date from it and SQL Server's integer DATEADD() has no 2038 limit. SQLite's
	 * columns hold epoch milliseconds, so it binds that directly.
	 * @name The parameter's name; the bound parameters are <name>_d and <name>_s.
	 */
	public string function timestampSql(required string name, required numeric epochSeconds, required struct params, string dbType = $dbType()) {
		if (arguments.dbType == "sqlite") {
			// cf_sql_double, not cf_sql_bigint: BoxLang binds cf_sql_bigint to SQLite as TEXT. A bare
			// column converts it back (numeric affinity), but an expression such as
			// COALESCE(heartbeatAt, updatedAt) has no affinity, and SQLite sorts every INTEGER before
			// any TEXT, so every row would look older than the reaper's cutoff. A double holds whole
			// milliseconds exactly, and the column's numeric affinity stores them as an INTEGER.
			arguments.params[arguments.name] = {value = arguments.epochSeconds * 1000, cfsqltype = "cf_sql_double"};
			return ":#arguments.name#";
		}
		local.days = $floorDiv(arguments.epochSeconds, 86400);
		local.d = arguments.name & "_d";
		local.s = arguments.name & "_s";
		arguments.params[local.d] = {value = JavaCast("int", local.days), cfsqltype = "cf_sql_integer"};
		arguments.params[local.s] = {value = JavaCast("int", arguments.epochSeconds - local.days * 86400), cfsqltype = "cf_sql_integer"};
		switch (arguments.dbType) {
			case "sqlserver":
				return "DATEADD(second, :#local.s#, DATEADD(day, :#local.d#, CAST('1970-01-01' AS DATETIME)))";
			case "mysql":
				return "DATE_ADD(DATE_ADD(CAST('1970-01-01 00:00:00' AS DATETIME), INTERVAL :#local.d# DAY), INTERVAL :#local.s# SECOND)";
			case "postgresql":
				return "(TIMESTAMP '1970-01-01 00:00:00' + :#local.d# * INTERVAL '1 day' + :#local.s# * INTERVAL '1 second')";
			case "oracle":
				return "(TIMESTAMP '1970-01-01 00:00:00' + NUMTODSINTERVAL(:#local.d#, 'DAY') + NUMTODSINTERVAL(:#local.s#, 'SECOND'))";
			case "h2":
				return "DATEADD('SECOND', :#local.s#, DATEADD('DAY', :#local.d#, TIMESTAMP '1970-01-01 00:00:00'))";
		}
		// An unrecognised database: bind the instant as a date, in this server's time zone.
		StructDelete(arguments.params, local.d);
		StructDelete(arguments.params, local.s);
		arguments.params[arguments.name] = {value = application.wo.$normalizeDbTimestamp(arguments.epochSeconds * 1000), cfsqltype = "cf_sql_timestamp"};
		return ":#arguments.name#";
	}

	/**
	 * A timestamp column (or expression) read as UTC epoch seconds, in the database's SQL.
	 */
	public string function epochSql(required string column, string dbType = $dbType()) {
		switch (arguments.dbType) {
			case "sqlserver":
				return "(CAST(DATEDIFF(day, '1970-01-01', #arguments.column#) AS BIGINT) * 86400 + DATEDIFF(second, CAST(#arguments.column# AS DATE), #arguments.column#))";
			case "mysql":
				return "TIMESTAMPDIFF(SECOND, '1970-01-01 00:00:00', #arguments.column#)";
			case "postgresql":
				return "CAST(FLOOR(EXTRACT(EPOCH FROM #arguments.column#)) AS BIGINT)";
			case "oracle":
				return "ROUND((CAST(#arguments.column# AS DATE) - DATE '1970-01-01') * 86400)";
			case "h2":
				return "DATEDIFF('SECOND', TIMESTAMP '1970-01-01 00:00:00', #arguments.column#)";
			case "sqlite":
				return "(#arguments.column# / 1000)";
		}
		// An unrecognised database stores this server's local time (see timestampSql()); toLocal()
		// takes the value as it is.
		return arguments.column;
	}

	/**
	 * Seconds the database's clock is ahead of this server's (negative when behind), read again
	 * once the cached value is older than 60 seconds.
	 */
	public numeric function skewSeconds() {
		local.entry = $cacheEntry();
		if (StructKeyExists(local.entry, "checkedTick") && $appMillis() - local.entry.checkedTick < $refreshSeconds() * 1000) {
			return local.entry.skew;
		}
		return refresh();
	}

	/**
	 * Reads the database's clock now and caches the skew. Returns it.
	 */
	public numeric function refresh() {
		local.previous = $cacheEntry();
		local.entry = {
			skew = StructKeyExists(local.previous, "skew") ? local.previous.skew : 0,
			anchored = StructKeyExists(local.previous, "anchored") && local.previous.anchored,
			failureLogged = StructKeyExists(local.previous, "failureLogged") && local.previous.failureLogged,
			dbType = $dbType(),
			checkedTick = $appMillis()
		};
		local.sql = utcNowSql(local.entry.dbType);
		if (!Len(local.sql)) {
			// Single-host databases: this server's own clock.
			local.entry.skew = 0;
		} else {
			try {
				local.row = queryExecute(local.sql, {}, {datasource = variables.$datasource});
				if (!IsNumeric(local.row.epochNow[1])) {
					Throw(type = "Wheels.Job.ClockUnreadable", message = "the database returned a value that isn't a number");
				}
				local.entry.skew = local.row.epochNow[1] - $appEpoch();
				local.entry.anchored = true;
				local.entry.failureLogged = false;
			} catch (any e) {
				if (!local.entry.failureLogged) {
					local.entry.failureLogged = true;
					writeLog(
						text = local.entry.anchored
							? "Couldn't read the database clock for background jobs (#e.message#); keeping the last good offset of #local.entry.skew# second(s)."
							: "Couldn't read the database clock for background jobs (#e.message#); the jobs clock runs on this server's own clock until a read succeeds, so it isn't shared with other servers yet.",
						type = "error",
						file = "wheels_jobs"
					);
				}
			}
		}
		$storeCacheEntry(local.entry);
		return local.entry.skew;
	}

	/**
	 * The SELECT that returns the database's current UTC time as epoch seconds (`epochNow`), or ""
	 * for a database that runs the jobs on this server's clock (H2, SQLite, unknown).
	 */
	public string function utcNowSql(required string dbType) {
		switch (arguments.dbType) {
			case "sqlserver":
				return "SELECT " & epochSql("t", "sqlserver") & " AS epochNow FROM (SELECT SYSUTCDATETIME() AS t) clock";
			case "mysql":
				return "SELECT TIMESTAMPDIFF(SECOND, '1970-01-01 00:00:00', UTC_TIMESTAMP()) AS epochNow";
			case "postgresql":
				// clock_timestamp(), not now(): now() is the transaction's start time.
				return "SELECT CAST(FLOOR(EXTRACT(EPOCH FROM clock_timestamp())) AS BIGINT) AS epochNow";
			case "oracle":
				return "SELECT ROUND((CAST(SYS_EXTRACT_UTC(SYSTIMESTAMP) AS DATE) - DATE '1970-01-01') * 86400) AS epochNow FROM dual";
		}
		return "";
	}

	/**
	 * Internal: the datasource's database type, detected once per application.
	 */
	public string function $dbType() {
		local.entry = $cacheEntry();
		if (StructKeyExists(local.entry, "dbType") && Len(local.entry.dbType)) {
			return local.entry.dbType;
		}
		local.entry.dbType = variables.$job.$databaseTypeOf(variables.$datasource);
		$storeCacheEntry(local.entry);
		return local.entry.dbType;
	}

	/**
	 * Internal: how long a read of the database clock is reused.
	 */
	public numeric function $refreshSeconds() {
		return 60;
	}

	/**
	 * Internal: this server's epoch milliseconds, never passed through Int() (Lucee truncates it
	 * to 32 bits).
	 */
	public numeric function $appMillis() {
		try {
			return CreateObject("java", "java.lang.System").currentTimeMillis();
		} catch (any e) {
			return GetTickCount();
		}
	}

	public numeric function $appEpoch() {
		return $floorDiv($appMillis(), 1000);
	}

	/**
	 * Internal: Floor(a / b) for whole numbers past 32 bits (Int() and \ truncate on Lucee).
	 */
	public numeric function $floorDiv(required numeric a, required numeric b) {
		local.q = Round(arguments.a / arguments.b);
		if (local.q * arguments.b > arguments.a) {
			local.q = local.q - 1;
		}
		return local.q;
	}

	public struct function $cacheEntry() {
		if (
			StructKeyExists(application, "wheels")
			&& StructKeyExists(application.wheels, "$jobsClock")
			&& StructKeyExists(application.wheels["$jobsClock"], variables.$datasource)
		) {
			return application.wheels["$jobsClock"][variables.$datasource];
		}
		return {};
	}

	public void function $storeCacheEntry(required struct entry) {
		if (!StructKeyExists(application, "wheels")) {
			return;
		}
		if (!StructKeyExists(application.wheels, "$jobsClock")) {
			application.wheels["$jobsClock"] = {};
		}
		application.wheels["$jobsClock"][variables.$datasource] = arguments.entry;
	}

}
