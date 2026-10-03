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
		variables.isBoxLang = application.wo.$engineAdapter().isBoxLang();
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

	function seedOdbcDates(required array values) {
		QueryExecute("DROP TABLE IF EXISTS c_o_r_e_sqliteodbcdates", [], {datasource = variables.ds});
		QueryExecute("CREATE TABLE c_o_r_e_sqliteodbcdates (id INTEGER PRIMARY KEY AUTOINCREMENT, created TEXT)", [], {datasource = variables.ds});
		for (var v in arguments.values) {
			QueryExecute("INSERT INTO c_o_r_e_sqliteodbcdates (created) VALUES (?)", [{value = v, cfsqltype = "cf_sql_varchar"}], {datasource = variables.ds});
		}
	}

	function odbcRawValues() {
		var q = QueryExecute("SELECT created || '' AS raw FROM c_o_r_e_sqliteodbcdates ORDER BY id", [], {datasource = variables.ds});
		var out = [];
		for (var row in q) {
			ArrayAppend(out, row.raw);
		}
		return out;
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

		// updateAll() built its SET params itself and skipped the ISO-8601 formatting save() applies,
		// so a date object was stored as CFML's "{ts '...'}" text, which a DATETIME column then
		// fails to read back (##4147).
		describe("Updating SQLite date columns", () => {

			afterEach(() => {
				if (variables.applies) {
					QueryExecute("DELETE FROM #variables.newTable#", [], {datasource = variables.ds});
				}
			});

			var paths = ["updateAll", "updateAll with instantiate", "updateByKey", "updateOne"];
			for (var path in paths) {
				it("stores ISO-8601 text and reads it back through #path#", (data) => {
					if (!variables.applies) {
						skip("SQLite only.");
					}
					var rec = model("SqliteDateCol").create(startsAt = "2026-01-01 00:00:00");
					var when = CreateDateTime(2026, 10, 3, 4, 29, 57);
					switch (data.path) {
						case "updateAll":
							model("SqliteDateCol").updateAll(where = "id = #rec.key()#", startsAt = when, callbacks = false);
							break;
						case "updateAll with instantiate":
							model("SqliteDateCol").updateAll(where = "id = #rec.key()#", startsAt = when, instantiate = true);
							break;
						case "updateByKey":
							model("SqliteDateCol").updateByKey(key = rec.key(), startsAt = when);
							break;
						case "updateOne":
							model("SqliteDateCol").updateOne(where = "id = #rec.key()#", startsAt = when);
							break;
					}
					var stored = QueryExecute("SELECT startsAt || '' AS raw FROM #variables.newTable# WHERE id = #rec.key()#", [], {datasource = variables.ds});
					expect(stored.raw).notToInclude("{ts");
					expect(stored.raw).toBe("2026-10-03 04:29:57");
					var reloaded = model("SqliteDateCol").findByKey(rec.key());
					expect(DateFormat(reloaded.startsAt, "yyyy-mm-dd") & " " & TimeFormat(reloaded.startsAt, "HH:mm:ss")).toBe("2026-10-03 04:29:57");
				}, [], false, {path = path});
			}

		});

		describe("SQLite DATE / TIME columns written before ##4093", () => {

			// Before #4093, SQLiteModel bound a declared DATE as cf_sql_date and TIME as cf_sql_time,
			// and the driver stored them as epoch milliseconds. Such columns exist only if created by
			// raw SQL or another tool. Writes now store ISO text, so the upgrade note gives a recipe to
			// convert the old integers first; this pins that the recipe works.
			// What happens to a record whose old epoch-millisecond values haven't been converted yet.
			// On BoxLang the integers read back as numbers, fail the date check, and block every save.
			// On Lucee and Adobe they read back as dates, and Wheels updates only the columns that
			// changed: an unrelated save works and leaves the integers, and writing a date column
			// stores ISO text, which mixes formats until the recipe runs. Either way: convert first.
			it("handles a record with unconverted legacy values per engine (BoxLang rejects the save)", () => {
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
					var rec = model("SqliteLegacyDateRow").findByKey(1);
					rec.label = "after";
					if (variables.isBoxLang) {
						// BoxLang: the save is rejected on the date columns the user never touched.
						expect(rec.save(transaction = "commit")).toBeFalse("BoxLang saved a record with unconverted legacy values");
						expect(ArrayLen(rec.errorsOn("d"))).toBeGT(0, "no error on d");
						expect(ArrayLen(rec.errorsOn("t"))).toBeGT(0, "no error on t");
						return;
					}
					// Lucee / Adobe 1. An unrelated change saves, and the old integers stay as they are.
					expect(rec.save(transaction = "commit")).toBeTrue("save failed: " & SerializeJSON(rec.allErrors()));
					var stored = QueryExecute("SELECT typeof(d) AS dk, typeof(t) AS tk, label FROM #legacy#", [], {datasource = variables.ds});
					expect(stored.label).toBe("after");
					expect(stored.dk).toBe("integer", "an unrelated save must not rewrite the date column");
					expect(stored.tk).toBe("integer", "an unrelated save must not rewrite the time column");
					// Lucee / Adobe 2. Writing the date column stores ISO text, so the column now mixes formats.
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

		// Earlier versions' updateAll() could store a date as a CFML ODBC literal ({ts '...'};
		// {d '...'} and {t '...'} are the other shapes CFML produces). A DATETIME column fails to
		// read those, so the upgrade note gives a repair query and changeColumn() converts them (##4147).
		// Earlier versions' updateAll() could store a date as a CFML ODBC literal ({ts '...'};
		// {d '...'} and {t '...'} are the other shapes CFML produces). A DATETIME column fails to
		// read those, so the upgrade note gives a repair query and changeColumn() converts them (##4147).
		describe("SQLite TEXT date columns holding ODBC date literals", () => {

			afterEach(() => {
				if (variables.applies) {
					QueryExecute("DROP TABLE IF EXISTS c_o_r_e_sqliteodbcdates", [], {datasource = variables.ds});
					StructDelete(application.wheels.models, "SqliteOdbcDate");
				}
			});

			// The exact check and repair the 4.1 to 4.2 upgrade note documents, then the documented
			// changeColumn(), then a read through a model.
			it("are found and repaired by the documented queries, and read back as dates", () => {
				if (!variables.applies) {
					skip("SQLite only.");
				}
				seedOdbcDates([
					"{ts '2026-10-03 04:29:57'}",
					"{ts '2026-10-03 04:29:57.123'}",
					"{d '2026-10-02'}",
					"{t '09:30:00'}",
					"2026-01-05 10:00:00",
					"{x 'not a date literal'}"
				]);
				var found = QueryExecute("SELECT COUNT(*) AS n FROM c_o_r_e_sqliteodbcdates WHERE created LIKE char(123) || 'ts ''%''' || char(125) OR created LIKE char(123) || 'd ''%''' || char(125) OR created LIKE char(123) || 't ''%''' || char(125)", [], {datasource = variables.ds});
				expect(found.n).toBe(4);
				QueryExecute("UPDATE c_o_r_e_sqliteodbcdates SET created = CASE WHEN created LIKE char(123) || 'ts ''%''' || char(125) THEN substr(created, instr(created, '''') + 1, length(created) - instr(created, '''') - 2) WHEN created LIKE char(123) || 'd ''%''' || char(125) THEN substr(created, instr(created, '''') + 1, length(created) - instr(created, '''') - 2) || ' 00:00:00' WHEN created LIKE char(123) || 't ''%''' || char(125) THEN '1899-12-30 ' || substr(created, instr(created, '''') + 1, length(created) - instr(created, '''') - 2) ELSE created END WHERE created LIKE char(123) || 'ts ''%''' || char(125) OR created LIKE char(123) || 'd ''%''' || char(125) OR created LIKE char(123) || 't ''%''' || char(125)", [], {datasource = variables.ds});
				expect(odbcRawValues()).toBe([
					"2026-10-03 04:29:57",
					"2026-10-03 04:29:57.123",
					"2026-10-02 00:00:00",
					"1899-12-30 09:30:00",
					"2026-01-05 10:00:00",
					"{x 'not a date literal'}"
				]);
				// A value that is no date at all is the app's to fix; drop it before converting.
				QueryExecute("DELETE FROM c_o_r_e_sqliteodbcdates WHERE created LIKE char(123) || 'x%'", [], {datasource = variables.ds});
				variables.migration.changeColumn(table = "c_o_r_e_sqliteodbcdates", columnName = "created", columnType = "datetime");
				StructDelete(application.wheels.models, "SqliteOdbcDate");
				var rows = model("SqliteOdbcDate").findAll(order = "id");
				var read = [];
				for (var row in rows) {
					ArrayAppend(read, DateFormat(row.created, "yyyy-mm-dd") & " " & TimeFormat(row.created, "HH:mm:ss"));
				}
				expect(read).toBe([
					"2026-10-03 04:29:57",
					"2026-10-03 04:29:57",
					"2026-10-02 00:00:00",
					"1899-12-30 09:30:00",
					"2026-01-05 10:00:00"
				]);
			});

			it("are converted by changeColumn() to datetime, which then reads every row", () => {
				if (!variables.applies) {
					skip("SQLite only.");
				}
				seedOdbcDates([
					"{ts '2026-10-03 04:29:57'}",
					"{ts '2026-10-03 04:29:57.123'}",
					"2026-01-05 10:00:00"
				]);
				variables.migration.changeColumn(table = "c_o_r_e_sqliteodbcdates", columnName = "created", columnType = "datetime");
				expect(odbcRawValues()).toBe([
					"2026-10-03 04:29:57",
					"2026-10-03 04:29:57.123",
					"2026-01-05 10:00:00"
				]);
				StructDelete(application.wheels.models, "SqliteOdbcDate");
				var rows = model("SqliteOdbcDate").findAll(order = "id");
				expect(rows.recordCount).toBe(3);
				expect(DateFormat(rows.created[2], "yyyy-mm-dd") & " " & TimeFormat(rows.created[2], "HH:mm:ss")).toBe("2026-10-03 04:29:57");
			});

			it("are converted by changeColumn() to date, including bare date-only text", () => {
				if (!variables.applies) {
					skip("SQLite only.");
				}
				seedOdbcDates(["{d '2026-10-02'}", "2026-01-05"]);
				variables.migration.changeColumn(table = "c_o_r_e_sqliteodbcdates", columnName = "created", columnType = "date");
				expect(odbcRawValues()).toBe(["2026-10-02 00:00:00", "2026-01-05 00:00:00"]);
				StructDelete(application.wheels.models, "SqliteOdbcDate");
				var rows = model("SqliteOdbcDate").findAll(order = "id");
				expect(DateFormat(rows.created[1], "yyyy-mm-dd")).toBe("2026-10-02");
				expect(DateFormat(rows.created[2], "yyyy-mm-dd")).toBe("2026-01-05");
			});

		});
	}

}
