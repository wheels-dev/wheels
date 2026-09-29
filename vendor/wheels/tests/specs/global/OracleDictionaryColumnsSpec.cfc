/**
 * $dbinfo(type="columns") on Oracle reads the data dictionary on Adobe CF,
 * because cfdbinfo there retains JDBC statements on every call (#3732). The
 * dictionary read must be interchangeable with cfdbinfo: this compares the
 * two, field by field, for the core test tables on every Oracle leg. On Adobe,
 * the only engine that uses it, every field must match exactly. Other engines'
 * cfdbinfo has a different shape, so there a field the engine does not return
 * is skipped and an empty and a 0 decimal_digits count as equal.
 */
component extends="wheels.WheelsTest" {

	// Number shapes the core tables lack. An unconstrained NUMBER must report
	// decimal_digits -127 like ojdbc: a 0 would map t.decimal() columns to
	// cf_sql_integer.
	variables.numbersTable = "c_o_r_e_dict3732_" & Left(LCase(Hash(CreateUUID())), 8);

	function beforeAll() {
		if (application.wheels.adapterName != "OracleModel") return;
		QueryExecute(
			"CREATE TABLE #variables.numbersTable# (
				id NUMBER(10) PRIMARY KEY,
				bare_number NUMBER,
				star_scaled NUMBER(*, 2),
				int_column INTEGER,
				float_column FLOAT(10),
				double_column BINARY_DOUBLE,
				nchar_column NVARCHAR2(20)
			)",
			[],
			{datasource = application.wheels.dataSourceName}
		);
	}

	function afterAll() {
		if (application.wheels.adapterName != "OracleModel") return;
		try {
			QueryExecute("DROP TABLE #variables.numbersTable#", [], {datasource = application.wheels.dataSourceName});
		} catch (any e) {
		}
	}

	function run() {

		describe("Oracle data-dictionary column metadata (##3732)", () => {

			var isOracle = application.wheels.adapterName == "OracleModel";
			var ds = application.wheels.dataSourceName;
			var g = application.wo;
			var tables = [
				"c_o_r_e_sqltypes", "c_o_r_e_authors", "c_o_r_e_posts", "c_o_r_e_combikeys",
				"c_o_r_e_CATEGORIES", "c_o_r_e_uuidrecords", "c_o_r_e_users", variables.numbersTable
			];
			var fields = [
				"type_name", "column_size", "decimal_digits", "is_nullable", "is_primarykey", "column_default_value",
				"is_foreignkey", "referenced_primarykey", "referenced_primarykey_table"
			];
			var strict = g.$engineAdapter().isAdobe();

			it("matches cfdbinfo field by field for the core test tables", () => {
				if (!isOracle) return;
				var mismatches = [];
				for (var t in tables) {
					var viaCfdbinfo = g.$dbinfo(type = "columns", table = t, datasource = ds, $forceCfdbinfo = true);
					var viaDictionary = g.$oracleDictionaryColumns(table = t, datasource = ds);
					var expected = rowsByColumn(viaCfdbinfo, viaDictionary.recordCount ? viaDictionary.table_schem[1] : "");
					var actual = rowsByColumn(viaDictionary, "");
					if (ArrayToList(expected.order) != ArrayToList(actual.order)) {
						ArrayAppend(mismatches, t & " columns: cfdbinfo [" & ArrayToList(expected.order) & "] vs dictionary [" & ArrayToList(actual.order) & "]");
						continue;
					}
					for (var col in expected.order) {
						for (var f in fields) {
							var want = expected.rows[col][f];
							var got = actual.rows[col][f];
							if (!strict && Compare(want, "(absent)") == 0) continue;
							if (
								!strict && f == "decimal_digits"
								&& (!Len(want) || Compare(want, "0") == 0)
								&& (!Len(got) || Compare(got, "0") == 0)
							) continue;
							if (Compare(want, got) != 0) {
								ArrayAppend(mismatches, t & "." & col & "." & f & ": cfdbinfo [" & expected.rows[col][f] & "] vs dictionary [" & actual.rows[col][f] & "]");
							}
						}
					}
				}
				expect(ArrayLen(mismatches)).toBe(0, ArrayToList(mismatches, " | "));
			});

			it("returns the dictionary rows from $dbinfo on Adobe, and cfdbinfo's elsewhere", () => {
				if (!isOracle) return;
				var viaDbinfo = g.$dbinfo(type = "columns", table = "c_o_r_e_authors", datasource = ds);
				var viaDictionary = g.$oracleDictionaryColumns(table = "c_o_r_e_authors", datasource = ds);
				expect(viaDbinfo.recordCount).toBe(viaDictionary.recordCount);
				expect(ValueList(viaDbinfo.column_name)).toBe(ValueList(viaDictionary.column_name));
			});

			it("reports an unconstrained NUMBER's scale as -127, like ojdbc", () => {
				if (!isOracle) return;
				var cols = g.$oracleDictionaryColumns(table = variables.numbersTable, datasource = ds);
				var byName = {};
				for (var i = 1; i <= cols.recordCount; i++) {
					byName[UCase(cols.column_name[i])] = cols.decimal_digits[i];
				}
				expect(byName["BARE_NUMBER"]).toBe(-127);
				expect(byName["STAR_SCALED"]).toBe(2);
				expect(byName["INT_COLUMN"]).toBe(0);
			});

			it("finds nothing for a table it can't see, so $dbinfo falls back to cfdbinfo", () => {
				if (!isOracle) return;
				expect(g.$oracleDictionaryColumns(table = "c_o_r_e_no_such_table_3732", datasource = ds).recordCount).toBe(0);
			});

		});

	}

	/** {order: [COLUMN_NAME...], rows: {COLUMN_NAME: {field: normalised string}}}, optionally one schema only. */
	private struct function rowsByColumn(required query q, required string schema) {
		var rv = {order = [], rows = {}};
		var hasSchem = ListFindNoCase(arguments.q.columnList, "table_schem") > 0;
		for (var i = 1; i <= arguments.q.recordCount; i++) {
			if (Len(arguments.schema) && hasSchem && Compare(arguments.q.table_schem[i], arguments.schema) != 0) {
				continue;
			}
			var name = UCase(arguments.q.column_name[i]);
			var row = {};
			for (var f in [
				"type_name", "column_size", "decimal_digits", "is_nullable", "is_primarykey", "column_default_value",
				"is_foreignkey", "referenced_primarykey", "referenced_primarykey_table"
			]) {
				row[f] = ListFindNoCase(arguments.q.columnList, f) ? normalise(arguments.q[f][i]) : "(absent)";
			}
			ArrayAppend(rv.order, name);
			rv.rows[name] = row;
		}
		return rv;
	}

	private string function normalise(any value) {
		if (IsNull(arguments.value)) return "";
		if (!IsSimpleValue(arguments.value)) return "(complex)";
		var s = Trim(ToString(arguments.value));
		if (IsBoolean(s) && !IsNumeric(s)) return s ? "YES" : "NO";
		if (IsNumeric(s)) return ToString(Val(s));
		return s;
	}

}
