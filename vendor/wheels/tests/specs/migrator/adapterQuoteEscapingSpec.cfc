/**
 * Regression coverage for db-adapters review findings DA10 / SEC-24 —
 * `Abstract.quote()` (the only quote() implementation, inherited by every
 * adapter) escaped only the FIRST embedded single quote in migration DEFAULT
 * values because `ReplaceNoCase()` defaults to scope "one", so
 * `default="O'Brien's"` produced unbalanced DDL. The date/datetime/binary
 * branch did no escaping at all.
 *
 * These specs run at the adapter unit layer — the Abstract adapter is
 * instantiated directly so the assertions are independent of the
 * currently-configured test datasource (the postgreSQLForeignKeyOptionsSpec
 * pattern).
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.adapter = CreateObject("component", "wheels.databaseAdapters.Abstract");
	}

	function run() {

		describe("Abstract.quote() single-quote escaping (DA10 / SEC-24)", () => {

			it("escapes every embedded single quote for string types", () => {
				expect(variables.adapter.quote(value = "O'Brien's", options = {type: "string"})).toBe("'O''Brien''s'");
			});

			it("escapes every embedded single quote for text types", () => {
				expect(variables.adapter.quote(value = "it's a 'quoted' default", options = {type: "text"})).toBe(
					"'it''s a ''quoted'' default'"
				);
			});

			it("escapes embedded single quotes in the date/datetime branch", () => {
				expect(variables.adapter.quote(value = "o'clock", options = {type: "date"})).toBe("'o''clock'");
				expect(variables.adapter.quote(value = "12 o'clock's chime", options = {type: "datetime"})).toBe(
					"'12 o''clock''s chime'"
				);
			});

			it("still quotes plain date values without altering them", () => {
				expect(variables.adapter.quote(value = "2026-01-01 12:00:00", options = {type: "datetime"})).toBe(
					"'2026-01-01 12:00:00'"
				);
			});

			it("still passes CURRENT_TIMESTAMP through unquoted", () => {
				expect(variables.adapter.quote(value = "CURRENT_TIMESTAMP", options = {type: "datetime"})).toBe(
					"CURRENT_TIMESTAMP"
				);
			});

			it("leaves untyped values unquoted", () => {
				expect(variables.adapter.quote(value = "42")).toBe("42");
			});

		});

	}

}
