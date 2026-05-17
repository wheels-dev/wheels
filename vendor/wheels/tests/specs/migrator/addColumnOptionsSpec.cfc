/**
 * Regression coverage for fresh-VM journal F17 — `addColumnOptions` emitted
 * asymmetric DDL for `default=""` between string-like column types.
 *
 *   t.string(...,default="") → no DEFAULT clause
 *   t.text(...,default="")   → DEFAULT ''
 *   t.char(...,default="")   → DEFAULT ''
 *
 * That asymmetry then interacts with the presence-check skip in
 * validatesPresenceOf (vendor/wheels/model/validations.cfc) — which checks
 * whether the underlying column has a database default — making the user's
 * `validatesPresenceOf` rule fire for `title` (string, no default emitted)
 * but silently skip for `body` (text, DEFAULT '' emitted), even though
 * the user wrote both columns identically. Tutorial chapter 7's model spec
 * `requires a body` failed because of this.
 *
 * The F17 fix lives in `wheels.databaseAdapters.Abstract.addColumnOptions`:
 * after the fix all three string-like types with `default=""` produce the
 * same DDL (no DEFAULT clause) on Abstract-based adapters (MySQL, SQLite,
 * H2, Oracle, Microsoft SQL Server).
 *
 * PostgreSQL and its CockroachDB subclass have their own `addColumnOptions`
 * implementation that intentionally emits `DEFAULT ''` for empty strings,
 * and serializes booleans as `true` / `false` (vs `1` / `0`). Those
 * surface differences are part of those adapters' contract — this spec
 * documents them rather than asserting them away. See #2661 for the cross-
 * adapter triage that motivated this adapter-aware shape.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.adapter = createObject("component", "wheels.migrator.Migration").init().adapter;
		// PostgreSQL and CockroachDB share the PostgreSQLMigrator addColumnOptions
		// implementation, which diverges from Abstract on empty string defaults
		// and boolean serialization. Use the same adapterName() idiom that
		// vendor/wheels/tests/specs/migrator/migrationSpec.cfc already uses
		// for cross-adapter branching.
		var name = variables.adapter.adapterName();
		variables.isPostgresFamily = (name == "PostgreSQL" || name == "CockroachDB");
		// MySQL's optionsIncludeDefault() returns false for text/mediumtext/longtext/float
		// because MySQL forbids DEFAULT on TEXT/BLOB columns pre-8.0.13. So text columns
		// — even with a real non-empty default — emit no DEFAULT clause on MySQL.
		variables.isMySQLFamily = (name == "MySQL");
	}

	private string function buildOptions(string type, string default = "", boolean allowNull = true) {
		var opts = {
			type: arguments.type,
			default: arguments.default,
			allowNull: arguments.allowNull
		};
		return variables.adapter.addColumnOptions(sql = "", options = opts);
	}

	function run() {

		describe("addColumnOptions — symmetric default handling for string-like types (F17)", () => {

			it("string with default='' omits the DEFAULT clause on Abstract-based adapters", () => {
				var sql = buildOptions(type = "string", default = "");
				if (variables.isPostgresFamily) {
					// PG adapter intentionally emits `DEFAULT ''` for empty strings.
					expect(sql).toInclude("DEFAULT");
				} else {
					expect(sql).notToInclude("DEFAULT");
				}
			});

			it("text with default='' omits the DEFAULT clause on Abstract-based adapters (F17)", () => {
				var sql = buildOptions(type = "text", default = "");
				if (variables.isPostgresFamily) {
					expect(sql).toInclude("DEFAULT");
				} else {
					expect(sql).notToInclude("DEFAULT");
				}
			});

			it("char with default='' omits the DEFAULT clause on Abstract-based adapters (F17)", () => {
				var sql = buildOptions(type = "char", default = "");
				if (variables.isPostgresFamily) {
					expect(sql).toInclude("DEFAULT");
				} else {
					expect(sql).notToInclude("DEFAULT");
				}
			});

			it("string with a real default (non-empty) still emits DEFAULT", () => {
				var sql = buildOptions(type = "string", default = "hello");
				expect(sql).toInclude("DEFAULT");
				expect(sql).toInclude("'hello'");
			});

			it("text with a real default: emits DEFAULT except on MySQL (TEXT columns suppressed)", () => {
				var sql = buildOptions(type = "text", default = "long body");
				if (variables.isMySQLFamily) {
					// MySQL adapter suppresses DEFAULT on TEXT columns entirely
					// (MySQLMigrator.optionsIncludeDefault returns false for text).
					expect(sql).notToInclude("DEFAULT");
				} else {
					expect(sql).toInclude("DEFAULT");
					expect(sql).toInclude("'long body'");
				}
			});

			it("integer with default='' becomes DEFAULT NULL across adapters", () => {
				var sql = buildOptions(type = "integer", default = "");
				expect(sql).toInclude("DEFAULT NULL");
			});

			it("boolean with default=true emits the adapter's true literal", () => {
				var sql = buildOptions(type = "boolean", default = true);
				if (variables.isPostgresFamily) {
					// PG adapter serializes booleans as `true` / `false` literals.
					expect(sql).toInclude("DEFAULT true");
				} else {
					// Abstract-based adapters serialize booleans as `1` / `0`.
					expect(sql).toInclude("DEFAULT 1");
				}
			});
		});
	}
}
