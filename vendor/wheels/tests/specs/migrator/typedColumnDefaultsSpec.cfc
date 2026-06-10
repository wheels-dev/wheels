/**
 * Spot-check that the per-type outlier parameter defaults survived the
 * $addTypedColumns helper-dedup refactor (#2937 review, #2977).
 *
 * Most typed column helpers declare `string default` / `boolean allowNull`
 * with NO default value; `float()` is the long-standing outlier with
 * `default=""` / `allowNull=true` (preserved for backward compatibility —
 * addColumnOptions renders default="" as DEFAULT NULL). A future cleanup
 * that "harmonizes" the signatures would silently change emitted DDL; this
 * spec pins the divergence on the built column definition itself.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
	}

	function run() {

		describe("TableDefinition typed-column outlier defaults", () => {

			it("float() applies its default='' / allowNull=true outlier defaults", () => {
				var t = variables.migration.createTable(name = "dbm_typed_defaults_test", force = true);
				t.float(columnNames = "ratio");

				expect(ArrayLen(t.columns)).toBe(1);
				expect(t.columns[1].type).toBe("float");
				expect(t.columns[1]).toHaveKey("default");
				expect(t.columns[1]["default"]).toBe("");
				expect(t.columns[1].allowNull).toBeTrue();
			});

			it("integer() does not inherit float()'s outlier defaults", () => {
				var t = variables.migration.createTable(name = "dbm_typed_defaults_test2", force = true);
				t.integer(columnNames = "age");

				expect(ArrayLen(t.columns)).toBe(1);
				expect(t.columns[1].type).toBe("integer");
			});

		});

	}

}
