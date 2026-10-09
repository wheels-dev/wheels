/**
 * The background-job clock: UTC, on the database's clock, so every server sharing the job tables
 * reads the same time. A server whose own clock runs ahead or behind can't reap a live job early
 * or pick up a delayed job late.
 *
 * At most every 60 seconds per application and datasource it reads the database's UTC time once
 * and keeps skew = database UTC - the app's own UTC (whole seconds). utcNow() is the app's UTC
 * plus that skew, truncated to whole seconds. Precision is about a second (the read's round trip).
 * - A failed read keeps the last good skew and logs once. With no good read yet the skew is 0, so
 *   the jobs code runs on the app's own UTC clock, and that is logged once too.
 * - H2 (1.4 has no UTC-now expression) and SQLite use the app's own UTC clock: both are
 *   single-host databases.
 * The skew is kept against the app's UTC rather than its local time, so a daylight-saving change
 * never leaves a cached offset an hour out.
 *
 * The CFML-facing API stays in app-local time: toUtc() converts a local date/time on the way in
 * (enqueueAt()), toLocal() a stored one on the way out (status and queue stats).
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
	 * The current time in UTC on the database's clock, in whole seconds (MySQL/H2 DATETIME round
	 * fractional seconds >= 0.5 up, which would put a just-written runAt in the future).
	 */
	public date function utcNow() {
		return DateAdd("s", skewSeconds(), $appUtc(Now()));
	}

	/**
	 * A date/time in app-local time as the jobs clock's UTC.
	 */
	public date function toUtc(required date localDateTime) {
		return DateAdd("s", skewSeconds(), $appUtc(arguments.localDateTime));
	}

	/**
	 * A timestamp read from a job table as app-local time. Values that aren't a date/time (a
	 * NULL read as "", or a driver shape that can't be normalised) come back unchanged.
	 */
	public any function toLocal(required any storedValue) {
		local.value = $normalize(arguments.storedValue);
		if (!IsDate(local.value)) {
			return arguments.storedValue;
		}
		return $utcToLocal(DateAdd("s", -skewSeconds(), local.value));
	}

	/**
	 * Seconds the database's UTC clock is ahead of the app's (negative when behind), read again
	 * once the cached value is older than 60 seconds.
	 */
	public numeric function skewSeconds() {
		local.entry = $cacheEntry();
		if (StructKeyExists(local.entry, "checkedTick") && GetTickCount() - local.entry.checkedTick < $refreshSeconds() * 1000) {
			return local.entry.skew;
		}
		return refresh();
	}

	/**
	 * Reads the database's UTC clock now and caches the skew. Returns it.
	 */
	public numeric function refresh() {
		local.previous = $cacheEntry();
		local.entry = {
			skew = StructKeyExists(local.previous, "skew") ? local.previous.skew : 0,
			anchored = StructKeyExists(local.previous, "anchored") && local.previous.anchored,
			failureLogged = StructKeyExists(local.previous, "failureLogged") && local.previous.failureLogged,
			dbType = StructKeyExists(local.previous, "dbType") ? local.previous.dbType : "",
			checkedTick = GetTickCount()
		};
		if (!Len(local.entry.dbType)) {
			local.entry.dbType = variables.$job.$databaseTypeOf(variables.$datasource);
		}
		local.sql = utcNowSql(local.entry.dbType);
		if (!Len(local.sql)) {
			// Single-host databases: the app's own UTC clock.
			local.entry.skew = 0;
		} else {
			try {
				local.row = queryExecute(local.sql, {}, {datasource = variables.$datasource});
				local.dbUtc = $normalize(local.row.utcNow[1]);
				if (!IsDate(local.dbUtc)) {
					Throw(type = "Wheels.Job.ClockUnreadable", message = "the database returned a value that isn't a date/time");
				}
				local.entry.skew = DateDiff("s", $appUtc(Now()), $wholeSeconds(local.dbUtc));
				local.entry.anchored = true;
				local.entry.failureLogged = false;
			} catch (any e) {
				if (!local.entry.failureLogged) {
					local.entry.failureLogged = true;
					writeLog(
						text = local.entry.anchored
							? "Couldn't read the database clock for background jobs (#e.message#); keeping the last good offset of #local.entry.skew# second(s)."
							: "Couldn't read the database clock for background jobs (#e.message#); the jobs clock runs on this server's own UTC time until a read succeeds, so it isn't shared with other servers yet.",
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
	 * The SELECT that returns the database's current UTC time as `utcNow`, or "" for a database
	 * that runs the jobs on the app's own UTC clock (H2, SQLite, unknown).
	 */
	public string function utcNowSql(required string dbType) {
		switch (arguments.dbType) {
			case "sqlserver":
				return "SELECT SYSUTCDATETIME() AS utcNow";
			case "mysql":
				return "SELECT UTC_TIMESTAMP(3) AS utcNow";
			case "postgresql":
				// clock_timestamp(), not now(): now() is the transaction's start time.
				return "SELECT (clock_timestamp() AT TIME ZONE 'UTC') AS utcNow";
			case "oracle":
				return "SELECT SYS_EXTRACT_UTC(SYSTIMESTAMP) AS utcNow FROM dual";
		}
		return "";
	}

	/**
	 * Internal: how long a read of the database clock is reused.
	 */
	public numeric function $refreshSeconds() {
		return 60;
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

	public any function $normalize(required any value) {
		if (IsDate(arguments.value)) {
			return arguments.value;
		}
		try {
			return application.wo.$normalizeDbTimestamp(arguments.value);
		} catch (any e) {
			return arguments.value;
		}
	}

	/**
	 * Internal: a local date/time as this server's UTC, as a plain date/time in whole seconds.
	 * Adobe CF and BoxLang return DateConvert()'s result as a value that still carries its zone,
	 * so DateDiff() against it, or binding it, sees the original instant: the fields are copied
	 * into a plain date/time, which is what Lucee returns and what the job tables store.
	 */
	public date function $appUtc(required date localDateTime) {
		return $wholeSeconds(DateConvert("local2utc", arguments.localDateTime));
	}

	/**
	 * Internal: a UTC date/time (a plain value holding UTC's wall time) as local time, as a plain
	 * date/time in whole seconds. Built from local2utc alone: BoxLang's DateConvert("utc2local")
	 * leaves a plain value's wall time unchanged. The local time L is the one whose UTC is the
	 * given value, L = U - offset(L); the offset is taken at U first and then at that first guess,
	 * so a daylight-saving change between the two still lands on the right hour.
	 */
	public date function $utcToLocal(required date utcDateTime) {
		local.u = $wholeSeconds(arguments.utcDateTime);
		local.guess = DateAdd("s", -$utcOffsetSeconds(local.u), local.u);
		return DateAdd("s", -$utcOffsetSeconds(local.guess), local.u);
	}

	/**
	 * Internal: seconds UTC is ahead of local time at a local date/time.
	 */
	public numeric function $utcOffsetSeconds(required date localDateTime) {
		return DateDiff("s", $wholeSeconds(arguments.localDateTime), $appUtc(arguments.localDateTime));
	}

	public date function $wholeSeconds(required date value) {
		return CreateDateTime(Year(arguments.value), Month(arguments.value), Day(arguments.value), Hour(arguments.value), Minute(arguments.value), Second(arguments.value));
	}

}
