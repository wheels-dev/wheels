/**
 * Oracle migrator DROP TABLE / DROP VIEW compatibility with Oracle < 23c.
 *
 * Oracle only added the `IF EXISTS` DDL modifier in 23c; on 19c/21c
 * `DROP TABLE IF EXISTS ...` is a hard parse error (ORA-00933), and the
 * `remove-table` migration template re-throws on error, so the whole
 * migration fails. The version-agnostic Oracle idiom is a PL/SQL block that
 * runs the bare DROP and swallows ORA-00942 ("table or view does not exist"),
 * preserving "drop if exists" semantics on every supported Oracle version.
 *
 * These assertions inspect the generated SQL string only — no live Oracle is
 * required, so they run on every engine in CI. Real-Oracle execution is
 * covered by the (soft-fail) Oracle compat-matrix job.
 *
 * Sibling bug fixed in the demo-app test populate by #2864
 * (wheels-dev/wheels). This spec guards the framework-side adapter.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("OracleMigrator drop statements (Oracle <23c IF EXISTS compatibility)", () => {

			it("dropTable does not emit the Oracle-<23-incompatible IF EXISTS clause", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleMigrator");
				var sql = adapter.dropTable("users");
				expect(FindNoCase("IF EXISTS", sql)).toBe(0);
			});

			it("dropTable wraps the drop in a PL/SQL block that swallows ORA-00942", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleMigrator");
				var sql = adapter.dropTable("users");
				expect(FindNoCase("EXECUTE IMMEDIATE", sql) > 0).toBeTrue();
				expect(FindNoCase("CASCADE CONSTRAINTS", sql) > 0).toBeTrue();
				expect(FindNoCase("-942", sql) > 0).toBeTrue();
			});

			it("dropTable still issues a DROP for the requested table", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleMigrator");
				var sql = adapter.dropTable("users");
				expect(FindNoCase("DROP TABLE", sql) > 0).toBeTrue();
				expect(FindNoCase("users", sql) > 0).toBeTrue();
			});

			it("dropView is also Oracle-<23 safe (no IF EXISTS, wrapped drop)", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleMigrator");
				var sql = adapter.dropView("user_summaries");
				expect(FindNoCase("IF EXISTS", sql)).toBe(0);
				expect(FindNoCase("EXECUTE IMMEDIATE", sql) > 0).toBeTrue();
				expect(FindNoCase("DROP VIEW", sql) > 0).toBeTrue();
			});

		});
	}

}
