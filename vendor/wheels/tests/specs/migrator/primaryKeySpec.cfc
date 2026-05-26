/**
 * Coverage for vendor/wheels/migrator/TableDefinition.cfc::primaryKey() —
 * the `columnName` / `columnNames` aliases added in #2803.
 *
 * The PK helper was the lone outlier among column-shaped helpers in this file:
 * every sibling (`integer`, `string`, `references`, etc.) accepts `columnNames`
 * via $combineArguments, but `primaryKey()` historically required `name` and
 * only `name`. Users and AI tooling learning the convention from one helper
 * would consistently mis-call `primaryKey(columnName=...)` and hit
 * "required argument missing." Same shape as #2781 for `t.references()`.
 *
 * These specs run at the TableDefinition layer — they assert on `t.primaryKeys`
 * directly and never call `t.create()`. That keeps them fast and adapter-
 * independent: the DB roundtrip is already covered by the existing migrator
 * suite (the `id` PK added by every `createTable()` call exercises the same
 * code path on every adapter in CI).
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
	}

	function run() {

		describe("TableDefinition.primaryKey() — argument aliases", () => {

			it("accepts the legacy name parameter", () => {
				// createTable(id=false) suppresses the conventional `id` PK so we
				// can assert against just the one we add explicitly.
				var t = variables.migration.createTable(name = "dbm_pk_legacy_name_test", id = false, force = true);
				t.primaryKey(name = "userId");
				expect(ArrayLen(t.primaryKeys)).toBe(1);
				expect(t.primaryKeys[1].name).toBe("userId");
			});

			it("accepts columnName as a singular alias for name", () => {
				var t = variables.migration.createTable(name = "dbm_pk_column_name_test", id = false, force = true);
				t.primaryKey(columnName = "userId");
				expect(ArrayLen(t.primaryKeys)).toBe(1);
				expect(t.primaryKeys[1].name).toBe("userId");
			});

			it("accepts columnNames as a plural alias for name", () => {
				var t = variables.migration.createTable(name = "dbm_pk_column_names_test", id = false, force = true);
				t.primaryKey(columnNames = "userId");
				expect(ArrayLen(t.primaryKeys)).toBe(1);
				expect(t.primaryKeys[1].name).toBe("userId");
			});

			it("does not iterate a comma-separated columnNames — PK name is the literal string", () => {
				// Unlike sibling helpers (t.string, t.integer, …) that ListToArray
				// the plural argument and create one column per entry, primaryKey()
				// always creates exactly one PK column. A comma-separated value is
				// passed through as the literal column name. For composite PKs,
				// call t.primaryKey() once per column.
				var t = variables.migration.createTable(name = "dbm_pk_no_list_test", id = false, force = true);
				t.primaryKey(columnNames = "a,b");
				expect(ArrayLen(t.primaryKeys)).toBe(1);
				expect(t.primaryKeys[1].name).toBe("a,b");
			});

		});

		describe("TableDefinition.primaryKey() — alias precedence", () => {

			it("plural columnNames wins when both columnName and columnNames are supplied", () => {
				// Mirrors the precedence documented on addReference() /
				// dropReference() — the later $combineArguments call wins, so
				// columnNames overrides columnName.
				var t = variables.migration.createTable(name = "dbm_pk_precedence_test", id = false, force = true);
				t.primaryKey(columnName = "singularLoses", columnNames = "pluralWins");
				expect(t.primaryKeys[1].name).toBe("pluralWins");
			});

			it("columnName overrides legacy name when both are supplied", () => {
				// Same $combineArguments shape: alias wins over the canonical
				// resolved form when both are passed.
				var t = variables.migration.createTable(name = "dbm_pk_legacy_vs_alias_test", id = false, force = true);
				t.primaryKey(name = "legacyLoses", columnName = "aliasWins");
				expect(t.primaryKeys[1].name).toBe("aliasWins");
			});

		});

		describe("TableDefinition.primaryKey() — required enforcement", () => {

			it("throws when none of name, columnName, or columnNames is supplied", () => {
				// $combineArguments(required=true) only throws when
				// showErrorInformation is on — match the wiring used elsewhere
				// in the suite (see paginationHelpersSpec.cfc).
				var _origShowErr = application.wheels.showErrorInformation;
				application.wheels.showErrorInformation = true;
				try {
					var t = variables.migration.createTable(name = "dbm_pk_required_test", id = false, force = true);
					expect(() => {
						t.primaryKey(type = "integer");
					}).toThrow();
				} finally {
					application.wheels.showErrorInformation = _origShowErr;
				}
			});

		});

		describe("TableDefinition.primaryKey() — other args still flow through", () => {

			it("preserves type, autoIncrement, and limit when using columnName alias", () => {
				var t = variables.migration.createTable(name = "dbm_pk_args_flow_test", id = false, force = true);
				t.primaryKey(columnName = "uuidPk", type = "uniqueidentifier", autoIncrement = false);
				expect(t.primaryKeys[1].name).toBe("uuidPk");
				expect(t.primaryKeys[1].type).toBe("uniqueidentifier");
				expect(t.primaryKeys[1].autoIncrement).toBe(false);
			});

		});

	}

}
