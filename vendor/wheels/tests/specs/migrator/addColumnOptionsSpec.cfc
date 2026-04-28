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
 * After the fix in Abstract.addColumnOptions, all three string-like types
 * with `default=""` produce the same DDL (no DEFAULT clause). That lines
 * the validatesPresenceOf skip up consistently.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.adapter = createObject("component", "wheels.migrator.Migration").init().adapter;
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

			it("string with default='' omits the DEFAULT clause", () => {
				var sql = buildOptions(type = "string", default = "");
				expect(sql).notToInclude("DEFAULT");
			});

			it("text with default='' omits the DEFAULT clause (regression for F17)", () => {
				var sql = buildOptions(type = "text", default = "");
				expect(sql).notToInclude("DEFAULT");
			});

			it("char with default='' omits the DEFAULT clause (regression for F17)", () => {
				var sql = buildOptions(type = "char", default = "");
				expect(sql).notToInclude("DEFAULT");
			});

			it("string with a real default (non-empty) still emits DEFAULT", () => {
				var sql = buildOptions(type = "string", default = "hello");
				expect(sql).toInclude("DEFAULT");
				expect(sql).toInclude("'hello'");
			});

			it("text with a real default (non-empty) still emits DEFAULT", () => {
				var sql = buildOptions(type = "text", default = "long body");
				expect(sql).toInclude("DEFAULT");
				expect(sql).toInclude("'long body'");
			});

			it("integer with default='' becomes DEFAULT NULL (unchanged behavior)", () => {
				var sql = buildOptions(type = "integer", default = "");
				expect(sql).toInclude("DEFAULT NULL");
			});

			it("boolean with default=true emits DEFAULT 1 (unchanged behavior)", () => {
				var sql = buildOptions(type = "boolean", default = true);
				expect(sql).toInclude("DEFAULT 1");
			});
		});
	}
}
