/**
 * Coverage for the consistency-sweep changes to Migration.cfc command-version
 * helpers (the standalone counterparts to TableDefinition's t.X() builders).
 *
 * Follow-up to #2781 (PR #2802). The TableDefinition layer was fixed in PR1
 * and PR1's review iterations also added DB-roundtrip coverage for the
 * `Migration.cfc::addReference()` and `Migration.cfc::removeColumn(referenceName=)`
 * suffix-flag behavior — those live in `migrationSpec.cfc` and are not
 * duplicated here. This spec covers what PR2 uniquely contributes:
 *
 *   - `addColumn` / `changeColumn` / `removeColumn` accept the plural
 *     `columnNames` as an alias for the legacy singular `columnName`,
 *     matching the convention every helper in `TableDefinition.cfc` already
 *     follows via `$combineArguments`.
 *
 * `addReference` / `dropReference` `columnName`/`columnNames` aliases for
 * the legacy `referenceName` are exercised at the unit level by the
 * `$combineArguments` calls themselves (any regression would surface as
 * IncorrectArguments errors in the existing migrator suite).
 */
component extends="wheels.WheelsTest" {

	include "helperFunctions.cfm";

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
	}

	function run() {

		describe("Migration.cfc — argument aliases via integration", () => {

			it("addColumn accepts columnNames alias and actually adds the column", () => {
				if (!isDbCompatible()) return;
				var t = variables.migration.createTable(name = "dbm_cmd_addcol_test", force = true);
				t.string(columnNames = "placeholder");
				t.create();
				variables.migration.addColumn(
					table = "dbm_cmd_addcol_test",
					columnNames = "age",
					columnType = "integer"
				);
				expect(ListFindNoCase(variables.migration.$getColumns("dbm_cmd_addcol_test"), "age")).toBeGT(0);
				variables.migration.dropTable("dbm_cmd_addcol_test");
			});

			it("changeColumn accepts columnNames alias directly (not via addColumn delegation)", () => {
				if (!isDbCompatible()) return;
				// Direct changeColumn call — guards against a future refactor of
				// addColumn that stops delegating and would silently lose the
				// columnNames alias path inside changeColumn itself.
				var t = variables.migration.createTable(name = "dbm_cmd_changecol_test", force = true);
				t.integer(columnNames = "age");
				t.create();
				variables.migration.changeColumn(
					table = "dbm_cmd_changecol_test",
					columnNames = "age",
					columnType = "integer"
				);
				expect(ListFindNoCase(variables.migration.$getColumns("dbm_cmd_changecol_test"), "age")).toBeGT(0);
				variables.migration.dropTable("dbm_cmd_changecol_test");
			});

			it("removeColumn accepts columnNames alias and actually drops the column", () => {
				if (!isDbCompatible()) return;
				var t = variables.migration.createTable(name = "dbm_cmd_rmcol_test", force = true);
				t.integer(columnNames = "age");
				t.create();
				expect(ListFindNoCase(variables.migration.$getColumns("dbm_cmd_rmcol_test"), "age")).toBeGT(0);
				variables.migration.removeColumn(
					table = "dbm_cmd_rmcol_test",
					columnNames = "age"
				);
				expect(ListFindNoCase(variables.migration.$getColumns("dbm_cmd_rmcol_test"), "age")).toBe(0);
				variables.migration.dropTable("dbm_cmd_rmcol_test");
			});

			it("addForeignKey accepts columnName alias for the legacy column parameter", () => {
				// SQLite doesn't support altering CONSTRAINTS, so addForeignKey
				// fires a SQL error there. We only need to verify the alias
				// resolved (no IncorrectArguments thrown); the downstream SQL
				// failure on SQLite is irrelevant to the alias contract.
				var t = variables.migration.createTable(name = "dbm_cmd_addfk_alias_test", force = true);
				t.integer(columnNames = "userid");
				t.create();
				var aliasAccepted = true;
				try {
					variables.migration.addForeignKey(
						table = "dbm_cmd_addfk_alias_test",
						referenceTable = "users",
						columnName = "userid",
						referenceColumn = "id"
					);
				} catch (Wheels.IncorrectArguments e) {
					aliasAccepted = false;
				} catch (any e) {}
				variables.migration.dropTable("dbm_cmd_addfk_alias_test");
				expect(aliasAccepted).toBeTrue();
			});

			it("dropReference accepts columnName alias for the legacy referenceName parameter", () => {
				// dropReference resolves to dropForeignKey by name pattern
				// (FK_<table>_<pluralized-reference>). If no such FK exists,
				// dropForeignKey errors at the SQL layer — that's fine here;
				// we only care that the alias resolved before SQL ran.
				var aliasAccepted = true;
				try {
					variables.migration.dropReference(
						table = "dbm_cmd_dropref_alias_table",
						columnName = "user"
					);
				} catch (Wheels.IncorrectArguments e) {
					aliasAccepted = false;
				} catch (any e) {}
				expect(aliasAccepted).toBeTrue();
			});

		});

		describe("Migration.cfc — required-arg regression guards", () => {

			it("addColumn throws Wheels.IncorrectArguments when neither columnName nor columnNames is provided (non-reference)", () => {
				// Prior to PR2 the original `required string columnName = ""`
				// signature enforced param presence at the CFML level. The
				// widened signature uses $combineArguments(required=true) to
				// restore equivalent enforcement for non-reference column types.
				var threwIncorrectArgs = false;
				try {
					variables.migration.addColumn(
						table = "dbm_cmd_reqcheck_test",
						columnType = "integer"
					);
				} catch (Wheels.IncorrectArguments e) {
					threwIncorrectArgs = true;
				} catch (any e) {}
				expect(threwIncorrectArgs).toBeTrue();
			});

			it("changeColumn throws Wheels.IncorrectArguments when neither columnName nor columnNames is provided (non-reference)", () => {
				var threwIncorrectArgs = false;
				try {
					variables.migration.changeColumn(
						table = "dbm_cmd_reqcheck_test",
						columnType = "integer"
					);
				} catch (Wheels.IncorrectArguments e) {
					threwIncorrectArgs = true;
				} catch (any e) {}
				expect(threwIncorrectArgs).toBeTrue();
			});

			it("addColumn does NOT require columnName for columnType='reference' (referenceName takes its place)", () => {
				// Reference-type column construction relies on referenceName,
				// not columnName. The conditional required check must skip
				// this branch.
				var threwIncorrectArgs = false;
				try {
					variables.migration.addColumn(
						table = "dbm_cmd_refcheck_test",
						columnType = "reference",
						referenceName = "user"
					);
				} catch (Wheels.IncorrectArguments e) {
					threwIncorrectArgs = true;
				} catch (any e) {}
				expect(threwIncorrectArgs).toBeFalse();
			});

		});

	}

}
