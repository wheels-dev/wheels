/**
 * Regression coverage for issue #2876 — `wheels migrate latest` crashed on
 * PostgreSQL (and its CockroachDB subclass) whenever a migration emitted an
 * inline foreign-key constraint, e.g. any `wheels generate scaffold ...
 * --belongsTo=author`. The reported error:
 *
 *   Component [wheels.databaseAdapters.PostgreSQL.PostgreSQLMigrator]
 *   has no function with name [addForeignKeyOptions]
 *
 * `Abstract.createTable()` assembles the inline FK clause via
 * `ForeignKeyDefinition.toForeignKeySQL()` → `adapter.addForeignKeyOptions(sql, options)`.
 * Every other adapter (MySQL, SQLite, Microsoft SQL Server, Oracle) implements
 * that method; only the PostgreSQL adapter was missing it, so the call failed
 * at runtime. `CockroachDBMigrator` extends `PostgreSQLMigrator` and inherited
 * the same gap — fixed transitively here.
 *
 * The adapters are instantiated directly (not via the active datasource) so the
 * PostgreSQL implementation is exercised on every engine × DB the matrix runs,
 * including the default SQLite local loop — `addForeignKeyOptions` is pure
 * string-building and needs no live PostgreSQL connection. This mirrors how
 * `Migration.cfc` itself builds the adapter (`CreateObject` without `init()`).
 *
 * The reporter's "works on Windows" note lined up with the `wheels new` SQLite
 * default: only a PostgreSQL/CockroachDB datasource ever reached the missing
 * method, so the bug is OS-independent and adapter-specific.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.pgAdapter = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLMigrator");
		variables.crdbAdapter = CreateObject("component", "wheels.databaseAdapters.CockroachDB.CockroachDBMigrator");
	}

	function run() {

		describe("PostgreSQLMigrator.addForeignKeyOptions (issue ##2876)", () => {

			it("defines addForeignKeyOptions on the PostgreSQL adapter", () => {
				expect(StructKeyExists(variables.pgAdapter, "addForeignKeyOptions")).toBeTrue();
			});

			it("emits table-level FOREIGN KEY ... REFERENCES DDL routed through the adapter's identifier quoting", () => {
				var col = variables.pgAdapter.quoteColumnName("authorid");
				var refTable = variables.pgAdapter.quoteTableName("authors");
				var refCol = variables.pgAdapter.quoteColumnName("id");
				var sql = variables.pgAdapter.addForeignKeyOptions(
					sql = "CONSTRAINT FK_posts_authors",
					options = {column: "authorid", referenceTable: "authors", referenceColumn: "id"}
				);
				expect(sql).toInclude("FOREIGN KEY (" & col & ")");
				expect(sql).toInclude("REFERENCES " & refTable);
				expect(sql).toInclude("(" & refCol & ")");
			});

			it("is inherited by the CockroachDB adapter", () => {
				expect(StructKeyExists(variables.crdbAdapter, "addForeignKeyOptions")).toBeTrue();
				var sql = variables.crdbAdapter.addForeignKeyOptions(
					sql = "CONSTRAINT FK_orders_users",
					options = {column: "userid", referenceTable: "users", referenceColumn: "id"}
				);
				expect(sql).toInclude("FOREIGN KEY");
				expect(sql).toInclude("REFERENCES");
				expect(sql).toInclude(variables.crdbAdapter.quoteTableName("users"));
			});

			it("drives ForeignKeyDefinition.toForeignKeySQL() — the exact failing path from the issue", () => {
				var fk = CreateObject("component", "wheels.migrator.ForeignKeyDefinition").init(
					adapter = variables.pgAdapter,
					table = "posts",
					referenceTable = "authors",
					column = "authorid",
					referenceColumn = "id"
				);
				var sql = fk.toForeignKeySQL();
				expect(sql).toInclude("CONSTRAINT");
				expect(sql).toInclude("FOREIGN KEY");
				expect(sql).toInclude("REFERENCES");
				expect(sql).toInclude(variables.pgAdapter.quoteTableName("authors"));
			});
		});
	}

}
