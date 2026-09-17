component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("SQLite decimal storage", () => {

			// Guard: the NUMERIC-vs-REAL bind path is SQLite-specific. Other
			// adapters have a native DECIMAL/NUMERIC type and bind via
			// setBigDecimal directly, so they don't share this bug surface.
			var migration = CreateObject("component", "wheels.migrator.Migration").init();
			if (migration.adapter.adapterName() != "SQLite") return;

			it("round-trips 149.99 exactly through the model create/find path", () => {
				transaction action="begin" {
					var rec = g.model("sqltype").create(
						stringVariableType = "decimal-roundtrip",
						textType = "precision check",
						decimalType = 149.99,
						transaction = "none"
					);

					var found = g.model("sqltype").findByKey(rec.id);
					expect(found.decimalType).toBe(149.99);

					transaction action="rollback";
				}
			});

			it("does not bind decimal values through the 32-bit float path", () => {
				transaction action="begin" {
					var rec = g.model("sqltype").create(
						stringVariableType = "decimal-bind",
						textType = "precision check",
						decimalType = 149.99,
						transaction = "none"
					);

					// The old REAL mapping read back 149.990005493164 (32-bit
					// float noise). Guard the exact value, not a fuzzy compare.
					var found = g.model("sqltype").findByKey(rec.id);
					expect(ToString(found.decimalType)).notToBe("149.990005493164");

					transaction action="rollback";
				}
			});
		});
	}
}
