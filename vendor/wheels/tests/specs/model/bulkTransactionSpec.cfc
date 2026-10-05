/**
 * insertAll() and upsertAll() honour their `transaction` argument like save(): with "commit" every
 * batch of 1000 rows commits or rolls back together, with "rollback" nothing is kept, and with
 * "none" each batch stands on its own. The core test runner sets transactionMode = "none", so each
 * spec passes `transaction` explicitly. Row 1001 repeats row 1's unique code, so the second batch
 * fails after the first one has run.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.g = application.wo;
	}

	function deleteBulkRows() {
		QueryExecute("DELETE FROM c_o_r_e_bulkitems WHERE code LIKE 'BULKTXN-%'", [], {datasource = variables.g.get("dataSourceName")});
	}

	function rowsLike(required string prefix) {
		return QueryExecute(
			"SELECT COUNT(*) AS n FROM c_o_r_e_bulkitems WHERE code LIKE :p",
			{p = arguments.prefix & "%"},
			{datasource = variables.g.get("dataSourceName")}
		).n;
	}

	// 1000 rows with unique codes, then one that repeats the first code.
	function failingSecondBatch(required string prefix) {
		var rv = [];
		for (var i = 1; i <= 1000; i++) {
			ArrayAppend(rv, {code = arguments.prefix & NumberFormat(i, "0000"), name = "row #i#", quantity = i});
		}
		ArrayAppend(rv, {code = arguments.prefix & "0001", name = "duplicate", quantity = 0});
		return rv;
	}

	function errorOf(required any callback) {
		var state = {type = ""};
		var target = arguments.callback;
		try {
			target();
		} catch (any e) {
			state.type = e.type;
		}
		return state.type;
	}

	// Bulk SQL for `rowCount` rows of `columnCount` varchar columns, from one adapter.
	function bulkSQL(required any adapter, required numeric rowCount, required numeric columnCount, boolean upsert = false) {
		var columns = [];
		var propertyInfo = {};
		var records = [];
		for (var c = 1; c <= arguments.columnCount; c++) {
			ArrayAppend(columns, "col#c#");
			propertyInfo["col#c#"] = {type = "cf_sql_varchar", dataType = "varchar", scale = "", nullable = false};
		}
		for (var r = 1; r <= arguments.rowCount; r++) {
			var record = {};
			for (var column in columns) {
				record[column] = "v";
			}
			ArrayAppend(records, record);
		}
		var args = {
			tableName = "bulkitems",
			columns = columns,
			validProperties = columns,
			records = records,
			batchStart = 1,
			batchEnd = arguments.rowCount,
			propertyInfo = propertyInfo
		};
		if (arguments.upsert) {
			args.uniqueBy = [columns[1]];
			args.updateColumns = arguments.columnCount > 1 ? [columns[2]] : [];
			return arguments.adapter.$upsertSQL(argumentCollection = args);
		}
		return arguments.adapter.$bulkInsertSQL(argumentCollection = args);
	}

	function run() {

		describe("Bulk transactions", () => {

			afterEach(() => {
				deleteBulkRows();
			});

			describe("insertAll() with a transaction", () => {

				it("rolls back every batch when a later batch fails, with transaction = commit", () => {
					var records = failingSecondBatch("BULKTXN-C-");
					expect(errorOf(() => variables.g.model("bulkItem").insertAll(records = records, transaction = "commit"))).notToBe("");
					expect(rowsLike("BULKTXN-C-")).toBe(0);
				});

				it("keeps nothing with transaction = rollback", () => {
					var result = variables.g.model("bulkItem").insertAll(
						records = [{code = "BULKTXN-R-1", name = "a", quantity = 1}, {code = "BULKTXN-R-2", name = "b", quantity = 2}],
						transaction = "rollback"
					);
					expect(result.insertedCount).toBe(2);
					expect(rowsLike("BULKTXN-R-")).toBe(0);
				});

				it("keeps the batches that ran with transaction = none", () => {
					var records = failingSecondBatch("BULKTXN-N-");
					expect(errorOf(() => variables.g.model("bulkItem").insertAll(records = records, transaction = "none"))).notToBe("");
					// the batches before the failing one were committed (how many rows depends on the batch
					// size, which is smaller where the database limits parameters per statement)
					expect(rowsLike("BULKTXN-N-")).toBeGT(0);
				});

				it("joins an open transaction, so the outer rollback removes its rows", () => {
					var records = [{code = "BULKTXN-J-1", name = "a", quantity = 1}, {code = "BULKTXN-J-2", name = "b", quantity = 2}];
					variables.g.model("bulkItem").invokeWithTransaction(method = "insertAllInside", transaction = "rollback", records = records);
					expect(rowsLike("BULKTXN-J-")).toBe(0);
					variables.g.model("bulkItem").invokeWithTransaction(method = "insertAllInside", transaction = "commit", records = records);
					expect(rowsLike("BULKTXN-J-")).toBe(2);
				});

				it("commits normally with transaction = commit", () => {
					var result = variables.g.model("bulkItem").insertAll(
						records = [{code = "BULKTXN-OK-1", name = "a", quantity = 1}, {code = "BULKTXN-OK-2", name = "b", quantity = 2}],
						transaction = "commit"
					);
					expect(result.insertedCount).toBe(2);
					expect(rowsLike("BULKTXN-OK-")).toBe(2);
				});

			});

			describe("insertAll() and upsertAll() batch sizes", () => {

				it("keep every statement within the database's parameter limit", () => {
					// 500 rows x 5 columns is 2500 parameters, more than SQL Server accepts in one statement.
					var records = [];
					for (var i = 1; i <= 500; i++) {
						ArrayAppend(records, {code = "BULKTXN-P-" & NumberFormat(i, "0000"), name = "row #i#", quantity = i});
					}
					expect(variables.g.model("bulkItem").insertAll(records = records, transaction = "commit").insertedCount).toBe(500);
					expect(rowsLike("BULKTXN-P-")).toBe(500);
					for (var r in records) {
						r.quantity += 1;
					}
					expect(variables.g.model("bulkItem").upsertAll(records = records, uniqueBy = "code", transaction = "commit").upsertedCount).toBe(500);
					expect(rowsLike("BULKTXN-P-")).toBe(500);
				});

			});

			describe("Bulk batch size arithmetic", () => {

				it("fits as many rows as the parameter limit allows, at least one, at most 1000", () => {
					var m = variables.g.model("bulkItem");
					expect(m.$bulkBatchSize(columnCount = 5, limit = 2097)).toBe(419);
					expect(m.$bulkBatchSize(columnCount = 1500, limit = 2097)).toBe(1);
					expect(m.$bulkBatchSize(columnCount = 3000, limit = 2097)).toBe(1);
					expect(m.$bulkBatchSize(columnCount = 2, limit = 2097)).toBe(1000);
					expect(m.$bulkBatchSize(columnCount = 5, limit = 0)).toBe(1000);
					expect(m.$bulkBatchSize(columnCount = 5, parameterize = false, limit = 2097)).toBe(1000);
				});

				it("binds exactly one parameter per column per row, on every adapter", () => {
					// The batch size divides the limit by the column count, so no adapter may bind more.
					var adapters = ["H2", "MicrosoftSQLServer", "MySQL", "Oracle", "PostgreSQL", "SQLite"];
					var counts = {};
					for (var name in adapters) {
						var adapter = CreateObject("component", "wheels.databaseAdapters.#name#.#name#Model");
						counts[name & " insert"] = adapter.$boundParameterCount(bulkSQL(adapter, 3, 4));
						counts[name & " upsert"] = adapter.$boundParameterCount(bulkSQL(adapter, 3, 4, true));
					}
					for (var key in counts) {
						expect(counts[key]).toBe(12, key);
					}
				});

				it("refuses a row wider than the limit before running it", () => {
					// 3000 columns gives one row per statement, which SQL Server still can't bind.
					var mssql = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerModel");
					var insertSQL = bulkSQL(mssql, 1, 3000);
					var upsertSQL = bulkSQL(mssql, 1, 3000, true);
					expect(errorOf(() => mssql.$assertBoundParameterCount(sql = insertSQL, parameterize = true))).toBe("Wheels.TooManyParameters");
					expect(errorOf(() => mssql.$assertBoundParameterCount(sql = upsertSQL, parameterize = true))).toBe("Wheels.TooManyParameters");
				});

			});

			describe("upsertAll() with a transaction", () => {

				it("keeps nothing with transaction = rollback", () => {
					variables.g.model("bulkItem").upsertAll(
						records = [{code = "BULKTXN-UR-1", name = "a", quantity = 1}],
						uniqueBy = "code",
						transaction = "rollback"
					);
					expect(rowsLike("BULKTXN-UR-")).toBe(0);
				});

				it("rolls back an earlier batch when a later batch fails, with transaction = commit", () => {
					// 1001 rows, so two batches. The last row's quantity is an array, which no engine can bind
					// as a query parameter, so only the second batch fails. (A non-numeric string isn't enough:
					// some engines bind it to an integer column without error.)
					var records = [];
					for (var i = 1; i <= 1001; i++) {
						ArrayAppend(records, {code = "BULKTXN-UC-" & NumberFormat(i, "0000"), name = "row #i#", quantity = i});
					}
					records[1001].quantity = ["not", "a", "number"];
					expect(errorOf(() => variables.g.model("bulkItem").upsertAll(records = records, uniqueBy = "code", transaction = "commit"))).notToBe("");
					expect(rowsLike("BULKTXN-UC-")).toBe(0);
				});

			});


		});

	}

}
