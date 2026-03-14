/**
 * Database-backed pub/sub adapter for multi-server SSE channels.
 *
 * Uses a wheels_events table for event persistence and cross-server
 * communication. Auto-creates the table on first use (same pattern as Job.cfc).
 *
 * Usage:
 *   var adapter = new wheels.channel.DatabaseAdapter();
 *   adapter.publish(channel="user.42", event="notification", data='{"title":"Hello"}');
 *   var events = adapter.poll(channel="user.42", since=dateAdd("n", -5, Now()));
 */
component {

	/**
	 * Initialize the database adapter.
	 * Gets datasource from application.wheels.dataSourceName.
	 */
	public DatabaseAdapter function init() {
		variables.$datasource = "";
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "dataSourceName")) {
			variables.$datasource = application.wheels.dataSourceName;
		}
		variables.tableVerified = false;
		variables.lastCleanup = 0;
		variables.retentionMinutes = 60;
		return this;
	}

	/**
	 * Publish an event to the database.
	 *
	 * @channel The channel name.
	 * @event The event type.
	 * @data The event data (string, typically JSON).
	 * @id Optional event ID. If not provided, a UUID is generated.
	 * @return Struct with {id, channel, event, persisted}.
	 */
	public struct function publish(
		required string channel,
		required string event,
		required string data,
		string id = CreateUUID()
	) {
		$ensureEventsTable();
		$maybeCleanup();

		try {
			queryExecute(
				"INSERT INTO wheels_events (id, channel, event, data, createdAt)
				VALUES (:id, :channel, :event, :data, :createdAt)",
				{
					id: {value: arguments.id, cfsqltype: "cf_sql_varchar"},
					channel: {value: arguments.channel, cfsqltype: "cf_sql_varchar"},
					event: {value: arguments.event, cfsqltype: "cf_sql_varchar"},
					data: {value: arguments.data, cfsqltype: "cf_sql_longvarchar"},
					createdAt: {value: Now(), cfsqltype: "cf_sql_timestamp"}
				},
				{datasource: variables.$datasource}
			);

			return {
				id: arguments.id,
				channel: arguments.channel,
				event: arguments.event,
				persisted: true
			};
		} catch (any e) {
			writeLog(
				text="DatabaseAdapter publish error on [#arguments.channel#]: #e.message#",
				type="error",
				file="wheels_channels"
			);
			return {
				id: arguments.id,
				channel: arguments.channel,
				event: arguments.event,
				persisted: false
			};
		}
	}

	/**
	 * Poll for events on a channel since a given event ID or timestamp.
	 *
	 * @channel The channel name to poll.
	 * @lastEventId If provided, return events after this ID (by createdAt of the referenced event).
	 * @since If provided (and no lastEventId), return events created after this timestamp.
	 * @return Query of events with columns: id, channel, event, data, createdAt.
	 */
	public query function poll(
		required string channel,
		string lastEventId = "",
		date since = DateAdd("n", -5, Now())
	) {
		$ensureEventsTable();

		// If lastEventId is provided, find its timestamp and get events at or after it,
		// excluding the event itself. Uses >= instead of > because MySQL and Oracle
		// DATETIME/TIMESTAMP have only second-level precision — events within the same
		// second would be missed with a strict > comparison.
		if (Len(arguments.lastEventId)) {
			return queryExecute(
				"SELECT e.id, e.channel, e.event, e.data, e.createdAt
				FROM wheels_events e
				WHERE e.channel = :channel
				AND e.id != :lastEventId
				AND e.createdAt >= (
					SELECT COALESCE(MAX(r.createdAt), :fallback)
					FROM wheels_events r
					WHERE r.id = :lastEventId
				)
				ORDER BY e.createdAt ASC",
				{
					channel: {value: arguments.channel, cfsqltype: "cf_sql_varchar"},
					lastEventId: {value: arguments.lastEventId, cfsqltype: "cf_sql_varchar"},
					fallback: {value: arguments.since, cfsqltype: "cf_sql_timestamp"}
				},
				{datasource: variables.$datasource}
			);
		}

		return queryExecute(
			"SELECT id, channel, event, data, createdAt
			FROM wheels_events
			WHERE channel = :channel
			AND createdAt > :since
			ORDER BY createdAt ASC",
			{
				channel: {value: arguments.channel, cfsqltype: "cf_sql_varchar"},
				since: {value: arguments.since, cfsqltype: "cf_sql_timestamp"}
			},
			{datasource: variables.$datasource}
		);
	}

	/**
	 * Delete events older than the specified number of minutes.
	 *
	 * @olderThanMinutes Delete events older than this many minutes (default: retentionMinutes).
	 */
	public void function cleanup(numeric olderThanMinutes = variables.retentionMinutes) {
		$ensureEventsTable();

		try {
			queryExecute(
				"DELETE FROM wheels_events WHERE createdAt < :cutoff",
				{
					cutoff: {value: DateAdd("n", -arguments.olderThanMinutes, Now()), cfsqltype: "cf_sql_timestamp"}
				},
				{datasource: variables.$datasource}
			);
		} catch (any e) {
			writeLog(
				text="DatabaseAdapter cleanup error: #e.message#",
				type="error",
				file="wheels_channels"
			);
		}
	}

	/**
	 * Throttled cleanup — runs at most once every 5 minutes.
	 */
	private void function $maybeCleanup() {
		local.now = GetTickCount() / 1000;
		if (local.now - variables.lastCleanup > 300) {
			variables.lastCleanup = local.now;
			cleanup();
		}
	}

	/**
	 * Auto-create the wheels_events table if it doesn't exist.
	 * Pattern copied from Job.cfc $ensureJobTable().
	 */
	private boolean function $ensureEventsTable() {
		if (variables.tableVerified) {
			return true;
		}

		try {
			queryExecute(
				"SELECT COUNT(*) AS cnt FROM wheels_events WHERE 1=0",
				{},
				{datasource: variables.$datasource}
			);
			variables.tableVerified = true;
			return true;
		} catch (any e) {
			// Table doesn't exist — create it
		}

		try {
			local.dbType = $detectDatabaseType();

			if (local.dbType == "oracle") {
				local.varcharType = "VARCHAR2";
				local.textType = "CLOB";
				local.datetimeType = "TIMESTAMP";
			} else if (local.dbType == "postgresql") {
				local.varcharType = "VARCHAR";
				local.textType = "TEXT";
				local.datetimeType = "TIMESTAMP";
			} else if (local.dbType == "h2") {
				local.varcharType = "VARCHAR";
				local.textType = "CLOB";
				local.datetimeType = "TIMESTAMP";
			} else {
				local.varcharType = "VARCHAR";
				local.textType = "TEXT";
				local.datetimeType = "DATETIME";
			}

			queryExecute("
				CREATE TABLE wheels_events (
					id #local.varcharType#(36) NOT NULL PRIMARY KEY,
					channel #local.varcharType#(255) NOT NULL,
					event #local.varcharType#(255) NOT NULL,
					data #local.textType#,
					createdAt #local.datetimeType# NOT NULL
				)
			", {}, {datasource: variables.$datasource});

			try {
				queryExecute(
					"CREATE INDEX idx_wevents_channel ON wheels_events (channel, createdAt)",
					{},
					{datasource: variables.$datasource}
				);
				queryExecute(
					"CREATE INDEX idx_wevents_cleanup ON wheels_events (createdAt)",
					{},
					{datasource: variables.$datasource}
				);
			} catch (any indexError) {
				// Indexes are optional
			}

			writeLog(text="Auto-created wheels_events table", type="information", file="wheels_channels");
			variables.tableVerified = true;
			return true;
		} catch (any createError) {
			writeLog(
				text="Failed to auto-create wheels_events table: #createError.message#",
				type="error",
				file="wheels_channels"
			);
			return false;
		}
	}

	/**
	 * Detect the database type from the datasource via JDBC metadata.
	 * Returns: "oracle", "postgresql", "h2", "mysql", "sqlserver", "sqlite", or "default".
	 */
	private string function $detectDatabaseType() {
		try {
			cfdbinfo(type="version", datasource="#variables.$datasource#", name="local.info");
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
