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

			it("declares DATE, DATETIME, TIME and TIMESTAMP", () => {
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
				expect(declared.stampedAt).toBe("TIMESTAMP");
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
					"SELECT typeof(startsOn) AS d, typeof(startsAt) AS dt, typeof(alarmAt) AS t, typeof(stampedAt) AS ts, startsOn, alarmAt FROM #variables.newTable#",
					[],
					{datasource = variables.ds}
				);
				expect(stored.d).toBe("text", "date storage class");
				expect(stored.dt).toBe("text", "datetime storage class");
				expect(stored.t).toBe("text", "time storage class");
				expect(stored.ts).toBe("text", "timestamp storage class");
				expect(Left(stored.startsOn, 10)).toBe("2026-10-02");
				expect(stored.alarmAt).toInclude("09:30:00");
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

		});
	}

}
