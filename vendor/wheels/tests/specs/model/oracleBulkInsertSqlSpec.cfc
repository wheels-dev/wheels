component extends="wheels.WheelsTest" {

	function run() {

		// Adapter-level SQL-builder coverage so the Oracle bulk-insert path is
		// verified on every engine/DB combo, not only the (currently soft-fail)
		// boxlang/oracle slot in the compat matrix. The actual end-to-end behavior
		// against a live Oracle datasource is covered by bulkOperationsSpec.cfc;
		// this spec pins the contract the model layer relies on.
		//
		// See #2745 — BoxLang+Oracle errors:
		//   "returning clause is not allowed with INSERT and Table Value Constructor"
		// caused by bulk INSERT emitting multi-row VALUES (?,?), (?,?) plus
		// JDBC RETURN_GENERATED_KEYS handling on Oracle 23.

		describe("OracleModel.$bulkInsertSQL", () => {

			beforeEach(() => {
				oracle = new wheels.databaseAdapters.Oracle.OracleModel();
				propertyInfo = {
					firstName: {column: "firstName", type: "cf_sql_varchar", dataType: "varchar", scale: 0, nullable: true},
					lastName:  {column: "lastName",  type: "cf_sql_varchar", dataType: "varchar", scale: 0, nullable: true}
				};
				records = [
					{firstName: "Alice", lastName: "Anderson"},
					{firstName: "Bob",   lastName: "Brown"},
					{firstName: "Carol", lastName: "Clark"}
				];
			});

			it("emits INSERT ALL ... SELECT 1 FROM dual instead of multi-row VALUES", () => {
				var sql = oracle.$bulkInsertSQL(
					tableName       = """AUTHORS""",
					columns         = ["firstName", "lastName"],
					validProperties = ["firstName", "lastName"],
					records         = records,
					batchStart      = 1,
					batchEnd        = 3,
					propertyInfo    = propertyInfo
				);

				expect(IsArray(sql)).toBeTrue();

				var text = "";
				for (var part in sql) {
					if (IsSimpleValue(part)) {
						text &= part;
					}
				}
				var collapsed = ReReplace(text, "[[:space:]]+", " ", "all");

				// Oracle-idiomatic shape — avoids the table-value-constructor +
				// RETURNING incompatibility on Oracle 23.
				expect(collapsed).toInclude("INSERT ALL");
				expect(collapsed).toInclude(" INTO ""AUTHORS"" ");
				expect(collapsed).toInclude("SELECT 1 FROM dual");

				// And must NOT contain the multi-row VALUES tuple-list shape that
				// Oracle JDBC rejects when RETURN_GENERATED_KEYS is requested.
				expect(collapsed).notToMatch("VALUES \(.+\), ?\(");
			});

			it("emits one INTO clause per record in the batch", () => {
				var sql = oracle.$bulkInsertSQL(
					tableName       = """AUTHORS""",
					columns         = ["firstName", "lastName"],
					validProperties = ["firstName", "lastName"],
					records         = records,
					batchStart      = 1,
					batchEnd        = 3,
					propertyInfo    = propertyInfo
				);

				var text = "";
				for (var part in sql) {
					if (IsSimpleValue(part)) {
						text &= part;
					}
				}

				// Three records → three INTO clauses.
				var intoCount = ArrayLen(ReMatch("(?i)INTO\s+""AUTHORS""", text));
				expect(intoCount).toBe(3);
			});

			it("parameterizes values via $buildBulkParam structs (no inline interpolation)", () => {
				var sql = oracle.$bulkInsertSQL(
					tableName       = """AUTHORS""",
					columns         = ["firstName", "lastName"],
					validProperties = ["firstName", "lastName"],
					records         = records,
					batchStart      = 1,
					batchEnd        = 3,
					propertyInfo    = propertyInfo
				);

				var paramCount = 0;
				for (var part in sql) {
					if (IsStruct(part) && StructKeyExists(part, "value") && StructKeyExists(part, "type")) {
						paramCount++;
					}
				}

				// 3 records × 2 columns = 6 parameter structs.
				expect(paramCount).toBe(6);

				// And the literal record values must NOT appear in the concatenated
				// string parts — confirms values flow through $buildBulkParam.
				var text = "";
				for (var part in sql) {
					if (IsSimpleValue(part)) {
						text &= part;
					}
				}
				expect(text).notToInclude("Alice");
				expect(text).notToInclude("Anderson");
			});

			it("handles a single-row batch without falling back to multi-row VALUES", () => {
				var sql = oracle.$bulkInsertSQL(
					tableName       = """AUTHORS""",
					columns         = ["firstName", "lastName"],
					validProperties = ["firstName", "lastName"],
					records         = [{firstName: "Solo", lastName: "Single"}],
					batchStart      = 1,
					batchEnd        = 1,
					propertyInfo    = propertyInfo
				);

				var text = "";
				for (var part in sql) {
					if (IsSimpleValue(part)) {
						text &= part;
					}
				}
				var collapsed = ReReplace(text, "[[:space:]]+", " ", "all");

				expect(collapsed).toInclude("INSERT ALL");
				expect(collapsed).toInclude("SELECT 1 FROM dual");
			});

		});

		describe("Base adapter $bulkInsertSQL (multi-row VALUES default)", () => {

			it("non-Oracle adapters keep the standard multi-row VALUES shape", () => {
				// SQLite is the safest non-Oracle adapter to instantiate without
				// touching the configured datasource — it has no $init side effects
				// for SQL building.
				var sqlite = new wheels.databaseAdapters.SQLite.SQLiteModel();
				var propertyInfo = {
					firstName: {column: "firstName", type: "cf_sql_varchar", dataType: "varchar", scale: 0, nullable: true},
					lastName:  {column: "lastName",  type: "cf_sql_varchar", dataType: "varchar", scale: 0, nullable: true}
				};

				var sql = sqlite.$bulkInsertSQL(
					tableName       = """authors""",
					columns         = ["firstName", "lastName"],
					validProperties = ["firstName", "lastName"],
					records         = [
						{firstName: "Alice", lastName: "Anderson"},
						{firstName: "Bob",   lastName: "Brown"}
					],
					batchStart      = 1,
					batchEnd        = 2,
					propertyInfo    = propertyInfo
				);

				var text = "";
				for (var part in sql) {
					if (IsSimpleValue(part)) {
						text &= part;
					}
				}
				var collapsed = ReReplace(text, "[[:space:]]+", " ", "all");

				expect(collapsed).toInclude("INSERT INTO");
				expect(collapsed).toInclude("VALUES");
				expect(collapsed).notToInclude("INSERT ALL");
			});

		});

	}

}
