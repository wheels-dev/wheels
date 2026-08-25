/**
 * Regression coverage for addColumnOptions default handling.
 *
 * S14 fail-loud contract: `default=""` on string/text/char throws
 * `Wheels.InvalidDefault` on every adapter (Abstract and PostgreSQL).
 * The old F17 asymmetry (Abstract omitted DEFAULT, PG emitted DEFAULT '')
 * is gone so the two adapters cannot silently diverge.
 *
 * S6: MySQL emits DEFAULT for TEXT-family and FLOAT instead of dropping it.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.adapter = createObject("component", "wheels.migrator.Migration").init().adapter;
		var name = variables.adapter.adapterName();
		variables.isPostgresFamily = (name == "PostgreSQL" || name == "CockroachDB");
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

		describe("addColumnOptions — default handling for string-like types", () => {

			it("string with default='' throws Wheels.InvalidDefault", () => {
				var state = {adapter = variables.adapter, type = ""};
				try {
					state.adapter.addColumnOptions(
						sql = "",
						options = {type: "string", default: "", allowNull: true}
					);
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels.InvalidDefault");
			});

			it("text with default='' throws Wheels.InvalidDefault", () => {
				var state = {adapter = variables.adapter, type = ""};
				try {
					state.adapter.addColumnOptions(
						sql = "",
						options = {type: "text", default: "", allowNull: true}
					);
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels.InvalidDefault");
			});

			it("char with default='' throws Wheels.InvalidDefault", () => {
				var state = {adapter = variables.adapter, type = ""};
				try {
					state.adapter.addColumnOptions(
						sql = "",
						options = {type: "char", default: "", allowNull: true}
					);
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels.InvalidDefault");
			});

			it("string with a real default (non-empty) still emits DEFAULT", () => {
				var sql = buildOptions(type = "string", default = "hello");
				expect(sql).toInclude("DEFAULT");
				expect(sql).toInclude("'hello'");
			});

			it("text with a real default (non-empty) emits DEFAULT", () => {
				var sql = buildOptions(type = "text", default = "long body");
				expect(sql).toInclude("DEFAULT");
				expect(sql).toInclude("'long body'");
			});

			it("integer with default='' becomes DEFAULT NULL across adapters", () => {
				var sql = buildOptions(type = "integer", default = "");
				expect(sql).toInclude("DEFAULT NULL");
			});

			it("boolean with default=true emits the adapter's true literal", () => {
				var sql = buildOptions(type = "boolean", default = true);
				if (variables.isPostgresFamily) {
					expect(sql).toInclude("DEFAULT true");
				} else {
					expect(sql).toInclude("DEFAULT 1");
				}
			});
		});
	}
}
