/**
 * Coverage for vendor/wheels/migrator/TableDefinition.cfc::references() — the
 * `columnNames` alias and the `useUnderscoreReferenceColumns` suffix flag.
 *
 * Sibling Migration.cfc helpers (`addReference`, `removeColumn(referenceName=)`)
 * also honor the same flag; their DB-roundtrip coverage lives in
 * migrationSpec.cfc rather than here.
 *
 * Issue #2781 surfaced two long-standing quirks in `t.references()`:
 *   1. The argument is `referenceNames` — every sibling column helper accepts
 *      `columnNames` / `columnName` via $combineArguments.
 *   2. The generated column name is `<x>id` (no underscore), which doesn't
 *      match Wheels model `belongsTo` defaults that expect `<x>_id`.
 *
 * These specs run at the TableDefinition layer — they assert on `t.columns`
 * and `t.foreignKeys` directly and never call `t.create()`. That keeps them
 * fast and adapter-independent: the DB roundtrip is already covered by the
 * existing migrator suite.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		// Capture the live setting so each test can scope its flip and the suite
		// leaves the global in its original state regardless of which order
		// TestBox runs the specs in.
		variables.originalUseUnderscore = application.wheels.useUnderscoreReferenceColumns ?: false;
	}

	function afterAll() {
		application.wheels.useUnderscoreReferenceColumns = variables.originalUseUnderscore;
	}

	function run() {

		describe("TableDefinition.references() — argument aliases", () => {

			it("accepts columnNames as an alias for referenceNames", () => {
				application.wheels.useUnderscoreReferenceColumns = false;
				var t = variables.migration.createTable(name = "dbm_refs_alias_test", force = true);
				t.references(columnNames = "user");
				expect(ArrayLen(t.columns)).toBe(1);
				expect(t.columns[1].name).toBe("userid");
			});

			it("still accepts the legacy referenceNames parameter", () => {
				application.wheels.useUnderscoreReferenceColumns = false;
				var t = variables.migration.createTable(name = "dbm_refs_legacy_param_test", force = true);
				t.references(referenceNames = "user");
				expect(ArrayLen(t.columns)).toBe(1);
				expect(t.columns[1].name).toBe("userid");
			});

		});

		describe("TableDefinition.references() — column suffix flag", () => {

			it("produces legacy <name>id suffix when useUnderscoreReferenceColumns is false (default)", () => {
				application.wheels.useUnderscoreReferenceColumns = false;
				var t = variables.migration.createTable(name = "dbm_refs_legacy_test", force = true);
				t.references(columnNames = "user");
				expect(t.columns[1].name).toBe("userid");
				expect(t.foreignKeys[1].column).toBe("userid");
			});

			it("produces <name>_id suffix when useUnderscoreReferenceColumns is true", () => {
				application.wheels.useUnderscoreReferenceColumns = true;
				var t = variables.migration.createTable(name = "dbm_refs_underscore_test", force = true);
				t.references(columnNames = "user");
				expect(t.columns[1].name).toBe("user_id");
				expect(t.foreignKeys[1].column).toBe("user_id");
			});

		});

		describe("TableDefinition.references() — polymorphic suffix follows the flag", () => {

			it("produces <name>id + <name>type when flag is false (legacy)", () => {
				application.wheels.useUnderscoreReferenceColumns = false;
				var t = variables.migration.createTable(name = "dbm_refs_poly_legacy_test", force = true);
				t.references(columnNames = "commentable", polymorphic = true);
				expect(ArrayLen(t.columns)).toBe(2);
				expect(t.columns[1].name).toBe("commentableid");
				expect(t.columns[2].name).toBe("commentabletype");
				// polymorphic=true skips the foreign-key constraint by design
				expect(ArrayLen(t.foreignKeys)).toBe(0);
			});

			it("produces <name>_id + <name>_type when flag is true", () => {
				application.wheels.useUnderscoreReferenceColumns = true;
				var t = variables.migration.createTable(name = "dbm_refs_poly_underscore_test", force = true);
				t.references(columnNames = "commentable", polymorphic = true);
				expect(ArrayLen(t.columns)).toBe(2);
				expect(t.columns[1].name).toBe("commentable_id");
				expect(t.columns[2].name).toBe("commentable_type");
				expect(ArrayLen(t.foreignKeys)).toBe(0);
			});

		});

	}

}
