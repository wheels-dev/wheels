/**
 * SQLite date columns created by the migrator (#4093).
 *
 * The SQLite migrator used to declare date, datetime, time and timestamp columns as TEXT, so the
 * model saw a string and automatic validations added no date check: "not a date" passed. The
 * migrator now declares DATE / DATETIME / TIME / TIMESTAMP, and the model treats those declared
 * types as dates for validation.
 *
 * Those declared names give the column NUMERIC affinity in SQLite. Wheels writes full ISO-8601
 * strings, which aren't numeric, so SQLite must still store them as TEXT; the storage-class
 * block pins that for every type, including a date-only and a time-only value.
 *
 * Existing apps keep their TEXT date columns until a migration changes them. Those still use
 * the column-name heuristic in Model.cfc, pinned by the last block.
 *
 * SQLite only: the other adapters already declare real date types.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		variables.applies = variables.migration.adapter.adapterName() == "SQLite";
		variables.newTable = "c_o_r_e_sqlitedatecols";
		variables.textTable = "c_o_r_e_sqlitetextdatecols";
		variables.ds = application.wo.get("dataSourceName");
		if (!variables.applies) {
			return;
		}
		var t = variables.migration.createTable(name = variables.newTable, force = true);
		t.date(columnNames = "startsOn");
		t.datetime(columnNames = "startsAt");
		t.time(columnNames = "alarmAt");
		t.timestamp(columnNames = "stampedAt");
		t.create();
		// Columns as a pre-#4093 SQLite app has them: plain TEXT.
		QueryExecute("DROP TABLE IF EXISTS #variables.textTable#", [], {datasource = variables.ds});
		QueryExecute(
			"CREATE TABLE #variables.textTable# (id INTEGER PRIMARY KEY AUTOINCREMENT, created TEXT, notes TEXT)",
			[],
			{datasource = variables.ds}
		);
		StructDelete(application.wheels.models, "SqliteDateCol");
		StructDelete(application.wheels.models, "SqliteTextDateCol");
	}

	function afterAll() {
		if (variables.applies) {
			variables.migration.dropTable(variables.newTable);
			QueryExecute("DROP TABLE IF EXISTS #variables.textTable#", [], {datasource = variables.ds});
		}
		StructDelete(application.wheels.models, "SqliteDateCol");
		StructDelete(application.wheels.models, "SqliteTextDateCol");
	}

	function run() {

		describe("SQLite migrator date columns", () => {

			afterEach(() => {
				if (variables.applies) {
					QueryExecute("DELETE FROM #variables.newTable#", [], {datasource = variables.ds});
					QueryExecute("DELETE FROM #variables.textTable#", [], {datasource = variables.ds});
				}
			});

			it("declares DATE, DATETIME and TIME (t.timestamp() is DATETIME)", () => {
				if (!variables.applies) {
					skip("SQLite only.");
				}
				var info = QueryExecute("PRAGMA table_info(#variables.newTable#)", [], {datasource = variables.ds});
				var declared = {};
				for (var row in info) {
					declared[row.name] = UCase(row.type);
				}
				expect(declared.startsOn).toBe("DATE");
				expect(declared.startsAt).toBe("DATETIME");
				expect(declared.alarmAt).toBe("TIME");
				// t.timestamp() defaults to columnType="datetime" on every adapter.
				expect(declared.stampedAt).toBe("DATETIME");
			});

			it("gives every date column the datetime validation type", () => {
				if (!variables.applies) {
					skip("SQLite only.");
				}
				var props = model("SqliteDateCol").$classData().properties;
				for (var col in ["startsOn", "startsAt", "alarmAt", "stampedAt"]) {
					expect(props[col].validationtype).toBe("datetime", "#col# validation type");
				}
			});

			it("rejects a non-date in each date column", () => {
				if (!variables.applies) {
					skip("SQLite only.");
				}
				for (var col in ["startsOn", "startsAt", "stampedAt"]) {
					var props = {};
					props[col] = "not a date";
					var rec = model("SqliteDateCol").new(props);
					expect(rec.valid()).toBeFalse("#col# accepted 'not a date'");
					expect(ArrayLen(rec.errorsOn(col))).toBeGT(0, "no error on #col#");
				}
			});

			it("stores every value as TEXT, including date-only and time-only values", () => {
				if (!variables.applies) {
					skip("SQLite only.");
				}
				var rec = model("SqliteDateCol").new(
					startsOn = "2026-10-02",
					startsAt = "2026-10-02 09:30:00",
					alarmAt = "09:30:00",
					stampedAt = CreateDateTime(2026, 10, 2, 9, 30, 0)
				);
				expect(rec.save(transaction = "commit")).toBeTrue("save failed: " & SerializeJSON(rec.allErrors()));
				var stored = QueryExecute(
					"SELECT typeof(startsOn) AS d, typeof(startsAt) AS dt, typeof(alarmAt) AS t, typeof(stampedAt) AS ts, startsOn || '' AS rawDate, alarmAt || '' AS rawTime, startsOn, alarmAt FROM #variables.newTable#",
					[],
					{datasource = variables.ds}
				);
				expect(stored.d).toBe("text", "date storage class");
				expect(stored.dt).toBe("text", "datetime storage class");
				expect(stored.t).toBe("text", "time storage class");
				expect(stored.ts).toBe("text", "timestamp storage class");
				// The stored text keeps the values; reading the typed column returns a date.
				expect(Left(stored.rawDate, 10)).toBe("2026-10-02");
				expect(stored.rawTime).toInclude("09:30:00");
				expect(DateFormat(stored.startsOn, "yyyy-mm-dd")).toBe("2026-10-02");
				expect(TimeFormat(stored.alarmAt, "HH:mm:ss")).toBe("09:30:00");
			});

		});

		describe("SQLite DATE / TIME columns written before ##4093", () => {

			// Before #4093, SQLiteModel bound a declared DATE as cf_sql_date and TIME as cf_sql_time,
			// and the driver stored them as epoch milliseconds. Such columns exist only if created by
			// raw SQL or another tool. Writes now store ISO text, so the upgrade note gives a recipe to
			// convert the old integers first; this pins that the recipe works.
			// What happens to a record whose old epoch-millisecond values haven't been converted yet.
			// Wheels updates only the columns that changed, so an unrelated save works and leaves the
			// old integers alone; writing a new value to a date column stores ISO text, which is what
			// mixes formats in the column until the recipe runs.
			it("saves a record with unconverted legacy values, leaving them as integers until a date column is written", () => {
				if (!variables.applies) {
					skip("SQLite only.");
				}
				var legacy = "c_o_r_e_sqlitelegacyrows";
				QueryExecute("DROP TABLE IF EXISTS #legacy#", [], {datasource = variables.ds});
				QueryExecute("CREATE TABLE #legacy# (id INTEGER PRIMARY KEY, label TEXT, d DATE, t TIME)", [], {datasource = variables.ds});
				try {
					// What the pre-#4093 binding wrote.
					QueryExecute(
						"INSERT INTO #legacy# (id, label, d, t) VALUES (1, 'before', ?, ?)",
						[{value = CreateDate(2026, 10, 2), cfsqltype = "cf_sql_date"}, {value = CreateTime(9, 30, 0), cfsqltype = "cf_sql_time"}],
						{datasource = variables.ds}
					);
					var before = QueryExecute("SELECT typeof(d) AS dk FROM #legacy#", [], {datasource = variables.ds});
					if (before.dk != "integer") {
						skip("This engine and driver stored the old DATE binding as #before.dk#, not epoch milliseconds.");
					}
					StructDelete(application.wheels.models, "SqliteLegacyDateRow");
					// 1. An unrelated change saves, and the old integers stay as they are.
					var rec = model("SqliteLegacyDateRow").findByKey(1);
					rec.label = "after";
					expect(rec.save(transaction = "commit")).toBeTrue("save failed: " & SerializeJSON(rec.allErrors()));
					var stored = QueryExecute("SELECT typeof(d) AS dk, typeof(t) AS tk, label FROM #legacy#", [], {datasource = variables.ds});
					expect(stored.label).toBe("after");
					expect(stored.dk).toBe("integer", "an unrelated save must not rewrite the date column");
					expect(stored.tk).toBe("integer", "an unrelated save must not rewrite the time column");
					// 2. Writing the date column stores ISO text, so the column now mixes formats.
					rec = model("SqliteLegacyDateRow").findByKey(1);
					rec.d = "2026-10-03";
					expect(rec.save(transaction = "commit")).toBeTrue("save failed: " & SerializeJSON(rec.allErrors()));
					stored = QueryExecute("SELECT typeof(d) AS dk, d || '' AS d FROM #legacy#", [], {datasource = variables.ds});
					expect(stored.dk).toBe("text");
					expect(Left(stored.d, 10)).toBe("2026-10-03");
				} finally {
					QueryExecute("DROP TABLE IF EXISTS #legacy#", [], {datasource = variables.ds});
					StructDelete(application.wheels.models, "SqliteLegacyDateRow");
				}
			});

			it("converts legacy epoch-millisecond DATE and TIME values with the documented recipe", () => {
				if (!variables.applies) {
					skip("SQLite only.");
				}
				var legacy = "c_o_r_e_sqlitelegacydates";
				QueryExecute("DROP TABLE IF EXISTS #legacy#", [], {datasource = variables.ds});
				QueryExecute("CREATE TABLE #legacy# (id INTEGER PRIMARY KEY, d DATE, t TIME)", [], {datasource = variables.ds});
				try {
					// What the old binding wrote.
					QueryExecute(
						"INSERT INTO #legacy# (id, d, t) VALUES (1, ?, ?)",
						[{value = CreateDate(2026, 10, 2), cfsqltype = "cf_sql_date"}, {value = CreateTime(9, 30, 0), cfsqltype = "cf_sql_time"}],
						{datasource = variables.ds}
					);
					var before = QueryExecute("SELECT typeof(d) AS dk, typeof(t) AS tk FROM #legacy#", [], {datasource = variables.ds});
					if (before.dk != "integer") {
						skip("This engine and driver stored the old DATE binding as #before.dk#, not epoch milliseconds; nothing to convert.");
					}
					// The recipe from the upgrade note.
					QueryExecute(
						"UPDATE #legacy# SET d = strftime('%Y-%m-%d', d / 1000, 'unixepoch', 'localtime') WHERE typeof(d) = 'integer'",
						[],
						{datasource = variables.ds}
					);
					QueryExecute(
						"UPDATE #legacy# SET t = strftime('%H:%M:%S', t / 1000, 'unixepoch', 'localtime') WHERE typeof(t) = 'integer'",
						[],
						{datasource = variables.ds}
					);
					var after = QueryExecute(
						"SELECT typeof(d) AS dk, typeof(t) AS tk, d || '' AS d, t || '' AS t FROM #legacy#",
						[],
						{datasource = variables.ds}
					);
					expect(after.dk).toBe("text");
					expect(after.d).toBe("2026-10-02");
					if (before.tk == "integer") {
						expect(after.tk).toBe("text");
						expect(after.t).toBe("09:30:00");
					}
				} finally {
					QueryExecute("DROP TABLE IF EXISTS #legacy#", [], {datasource = variables.ds});
				}
			});

		});

		describe("SQLite TEXT date columns from before ##4093", () => {

			it("keeps the column-name heuristic: a TEXT column named 'created' is a date", () => {
				if (!variables.applies) {
					skip("SQLite only.");
				}
				var props = model("SqliteTextDateCol").$classData().properties;
				expect(props.created.validationtype).toBe("datetime");
				expect(props.notes.validationtype).toBe("string");
			});

			// The upgrade note tells apps to convert an existing TEXT column with changeColumn().
			it("converts a TEXT date column with changeColumn, keeping its value", () => {
				if (!variables.applies) {
					skip("SQLite only.");
				}
				QueryExecute(
					"INSERT INTO #variables.textTable# (created, notes) VALUES ('2026-10-02 09:30:00', 'kept')",
					[],
					{datasource = variables.ds}
				);
				variables.migration.changeColumn(table = variables.textTable, columnName = "created", columnType = "datetime");
				var info = QueryExecute("PRAGMA table_info(#variables.textTable#)", [], {datasource = variables.ds});
				var declared = "";
				for (var row in info) {
					if (row.name == "created") {
						declared = UCase(row.type);
					}
				}
				expect(declared).toBe("DATETIME");
				var stored = QueryExecute(
					"SELECT typeof(created) AS kind, created || '' AS raw FROM #variables.textTable#",
					[],
					{datasource = variables.ds}
				);
				expect(stored.kind).toBe("text");
				expect(stored.raw).toBe("2026-10-02 09:30:00");
				StructDelete(application.wheels.models, "SqliteTextDateCol");
				expect(model("SqliteTextDateCol").$classData().properties.created.validationtype).toBe("datetime");
			});

		});
	}

}
