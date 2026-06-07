/**
 * Regression coverage for #2876 — `wheels migrate latest` failed on Linux
 * whenever a migration ran `t.references()` against PostgreSQL with the
 * error:
 *
 *   Component [wheels.databaseAdapters.PostgreSQL.PostgreSQLMigrator]
 *   has no function with name [addForeignKeyOptions]
 *
 * `Abstract.createTable()` builds the inline FK clause via
 * `foreignKeys[i].toForeignKeySQL()` → `ForeignKeyDefinition.cfc` →
 * `adapter.addForeignKeyOptions(sql, options)`. Every other adapter
 * implements that method (MySQL, SQLite, MSSQL, Oracle); only PostgreSQL
 * was missing it, so any scaffold that produced an FK column blew up at
 * migrate time. CockroachDB extends PostgreSQLMigrator and inherited the
 * same gap.
 *
 * These specs run at the adapter unit layer — the adapter is instantiated
 * directly and `addForeignKeyOptions` is called with the same option
 * struct shape that `ForeignKeyDefinition::addForeignKeyOptions` builds
 * (`column`, `referenceTable`, `referenceColumn`). That keeps the
 * assertions adapter-independent of the currently-configured test
 * datasource — exactly the pattern referencesSpec.cfc uses for
 * TableDefinition-layer plumbing.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.pgAdapter = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLMigrator");
		variables.cockroachAdapter = CreateObject("component", "wheels.databaseAdapters.CockroachDB.CockroachDBMigrator");
	}

	function run() {

		describe("PostgreSQLMigrator.addForeignKeyOptions()", () => {

			it("exists as a public method on the adapter", () => {
				var fns = getMetaData(variables.pgAdapter).functions;
				var found = false;
				for (var fn in fns) {
					if (fn.name == "addForeignKeyOptions") {
						found = true;
						break;
					}
				}
				expect(found).toBeTrue();
			});

			it("appends FOREIGN KEY (col) REFERENCES table (refCol) to the constraint sql", () => {
				var sql = variables.pgAdapter.addForeignKeyOptions(
					sql = "CONSTRAINT FK_posts_users",
					options = {
						column: "userid",
						referenceTable: "users",
						referenceColumn: "id"
					}
				);
				expect(sql).toInclude("FOREIGN KEY");
				expect(sql).toInclude("userid");
				expect(sql).toInclude("REFERENCES");
				expect(sql).toInclude("users");
				expect(sql).toInclude("id");
			});

		});

		describe("CockroachDBMigrator inherits the PostgreSQL fix", () => {

			it("exposes addForeignKeyOptions via PostgreSQLMigrator inheritance", () => {
				var sql = variables.cockroachAdapter.addForeignKeyOptions(
					sql = "CONSTRAINT FK_posts_users",
					options = {
						column: "userid",
						referenceTable: "users",
						referenceColumn: "id"
					}
				);
				expect(sql).toInclude("FOREIGN KEY");
				expect(sql).toInclude("REFERENCES");
			});

		});

		describe("ForeignKeyDefinition.toForeignKeySQL() integrates with PostgreSQLMigrator", () => {

			it("does not throw when toForeignKeySQL() walks through the PG adapter", () => {
				var fk = CreateObject("component", "wheels.migrator.ForeignKeyDefinition").init(
					adapter = variables.pgAdapter,
					table = "posts",
					referenceTable = "users",
					column = "userid",
					referenceColumn = "id"
				);
				var sql = fk.toForeignKeySQL();
				expect(sql).toInclude("CONSTRAINT");
				expect(sql).toInclude("FOREIGN KEY");
				expect(sql).toInclude("REFERENCES");
			});

		});

	}

}
