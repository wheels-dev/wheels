/**
 * databaseAdapters Hardener S1–S18.
 * S2/S6/S8/S12/S13/S14/S15 stay HELD. S16 proves last-resort only.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("S2 HOLD $executeQuery string null after IS", () => {

			it("binds the string null after IS and IS NOT", () => {
				var sql = g.model("post").$whereClause(where = "averagerating IS NULL");
				sql = g.model("post").$addWhereClauseParameters(sql = sql, where = "averagerating IS NULL");
				var bound = "";
				for (var part in sql) {
					if (IsStruct(part) && StructKeyExists(part, "value") && LCase(ToString(part.value)) == "null") {
						bound = part.value;
					}
				}
				expect(LCase(bound)).toBe("null");
				expect(IsSimpleValue(bound)).toBeTrue();

				sql = g.model("post").$whereClause(where = "averagerating IS NOT NULL");
				sql = g.model("post").$addWhereClauseParameters(sql = sql, where = "averagerating IS NOT NULL");
				bound = "";
				for (part in sql) {
					if (IsStruct(part) && StructKeyExists(part, "value") && LCase(ToString(part.value)) == "null") {
						bound = part.value;
					}
				}
				expect(LCase(bound)).toBe("null");
			});

			it("still converts that string to SQL NULL in $executeQuery", () => {
				var src = FileRead(ExpandPath("/wheels/databaseAdapters/Base.cfc"));
				expect(src).toInclude('part.value == "null"');
				expect(src).toInclude('right(prev, 2) == "IS"');
				expect(src).toInclude('right(prev, 6) == "IS NOT"');
				expect(src).toInclude('writeOutput("NULL")');
			});

		});

		describe("S3 $getColumns cache catch(any) fall-through", () => {

			it("falls through to a fresh catalog lookup when the cache read throws", () => {
				var state = {hadCache = false, cache = {}};
				if (StructKeyExists(application.wheels, "schemaColumnCache")) {
					state.hadCache = true;
					state.cache = Duplicate(application.wheels.schemaColumnCache);
				}
				var probe = CreateObject("component", "wheels.tests._assets.adapters.ColumnsCacheProbe");
				probe.$init(dataSource = "wheels_hardener_s3", username = "", password = "");
				StructDelete(application.wheels, "schemaColumnCache");
				try {
					var cols = probe.$getColumns("authors");
					expect(probe.columnInfoCalls).toBe(1);
					expect(cols.column_name[1]).toBe("fresh_id");
				} finally {
					if (state.hadCache) {
						application.wheels.schemaColumnCache = state.cache;
					} else {
						StructDelete(application.wheels, "schemaColumnCache");
					}
				}
			});

			it("keeps catch(any) on the cache read", () => {
				var src = FileRead(ExpandPath("/wheels/databaseAdapters/Base.cfc"));
				var start = Find("public query function $getColumns", src);
				var body = Mid(src, start, 1800);
				expect(Find("catch (any e)", body)).toBeGT(0);
			});

		});

		describe("S5 Oracle $identitySequenceName catch(any)", () => {

			it("returns empty string when the catalog query throws", () => {
				var probe = CreateObject("component", "wheels.tests._assets.adapters.OracleProbe");
				probe.throwOnQuery = true;
				expect(
					probe.$identitySequenceName(
						tableName = "users",
						columnName = "id",
						queryAttributes = {}
					)
				).toBe("");
			});

			it("keeps catch(any) around the catalog lookup", () => {
				var src = FileRead(ExpandPath("/wheels/databaseAdapters/Oracle/OracleModel.cfc"));
				var start = Find("public string function $identitySequenceName", src);
				var body = Mid(src, start, 1600);
				expect(Find("catch (any e)", body)).toBeGT(0);
			});

		});

		describe("S6 HOLD MySQL optionsIncludeDefault vs Abstract", () => {

			it("MySQL drops DEFAULT for text and float", () => {
				var mysql = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLMigrator");
				expect(mysql.optionsIncludeDefault(type = "text", default = "long body")).toBeFalse();
				expect(mysql.optionsIncludeDefault(type = "float", default = "1.25")).toBeFalse();
				expect(mysql.optionsIncludeDefault(type = "string", default = "hello")).toBeTrue();
				var sql = mysql.addColumnOptions(
					sql = "",
					options = {type: "text", default: "long body", allowNull: true}
				);
				expect(sql).notToInclude("DEFAULT");
			});

			it("Abstract optionsIncludeDefault stays always true", () => {
				var abstract = CreateObject("component", "wheels.databaseAdapters.Abstract");
				expect(abstract.optionsIncludeDefault(type = "text", default = "long body")).toBeTrue();
				expect(abstract.optionsIncludeDefault(type = "float", default = "1.25")).toBeTrue();
				expect(abstract.optionsIncludeDefault()).toBeTrue();
			});

		});

		describe("S9 addColumnOptions quotes AFTER", () => {

			it("Abstract quotes a hostile afterColumn", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.Abstract");
				var hostile = "id; DROP TABLE t";
				var sql = adapter.addColumnOptions(
					sql = "name VARCHAR(255)",
					options = {afterColumn: hostile}
				);
				expect(sql).toBe("name VARCHAR(255) AFTER " & adapter.quoteColumnName(hostile));
				expect(sql).notToInclude("AFTER id; DROP TABLE t");
			});

			it("MySQL quotes AFTER with backticks", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLMigrator");
				var sql = adapter.addColumnOptions(
					sql = "name VARCHAR(255)",
					options = {afterColumn: "created_at"}
				);
				expect(sql).toInclude("AFTER `created_at`");
			});

			it("PostgreSQL AFTER uses quoteColumnName", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLMigrator");
				var sql = adapter.addColumnOptions(
					sql = "name VARCHAR(255)",
					options = {type: "string", afterColumn: "created_at"}
				);
				expect(sql).toInclude("AFTER " & adapter.quoteColumnName("created_at"));
			});

		});

		describe("S12 HOLD SQLite advisory locks stay no-op true", () => {

			it("reports support and acquire does not throw", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteModel");
				expect(adapter.$supportsAdvisoryLocks()).toBeTrue();
				adapter.$acquireAdvisoryLock(name = "hardener_s12", timeout = 1);
				adapter.$releaseAdvisoryLock(name = "hardener_s12");
			});

		});

		describe("S13 HOLD foreignKeySQL unknown action is CASCADE", () => {

			it("maps restrict and other unknown values to CASCADE", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.Abstract");
				var sql = adapter.foreignKeySQL(
					name = "fk_posts_users",
					table = "posts",
					referenceTable = "users",
					column = "userid",
					referenceColumn = "id",
					onUpdate = "restrict",
					onDelete = "set default"
				);
				expect(sql).toInclude("ON UPDATE CASCADE");
				expect(sql).toInclude("ON DELETE CASCADE");
				expect(sql).notToInclude("RESTRICT");
				expect(sql).notToInclude("SET DEFAULT");
			});

			it("still maps none and null", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.Abstract");
				var sql = adapter.foreignKeySQL(
					name = "fk_posts_users",
					table = "posts",
					referenceTable = "users",
					column = "userid",
					referenceColumn = "id",
					onUpdate = "none",
					onDelete = "null"
				);
				expect(sql).toInclude("ON UPDATE NO ACTION");
				expect(sql).toInclude("ON DELETE SET NULL");
			});

		});

		describe("S14 HOLD Abstract vs PG empty string default", () => {

			it("Abstract omits DEFAULT for string default empty", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.Abstract");
				var sql = adapter.addColumnOptions(
					sql = "",
					options = {type: "string", default: "", allowNull: true}
				);
				expect(sql).notToInclude("DEFAULT");
			});

			it("PostgreSQL emits DEFAULT empty string for string default empty", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLMigrator");
				var sql = adapter.addColumnOptions(
					sql = "",
					options = {type: "string", default: "", allowNull: true}
				);
				expect(sql).toInclude("DEFAULT ''");
			});

		});

		describe("S15 HOLD unmapped $getType", () => {

			it("PostgreSQL throws Wheels.UnknownColumnType", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLModel");
				expect(function() {
					adapter.$getType(type = "definitely_not_a_type");
				}).toThrow("Wheels.UnknownColumnType");
			});

			it("SQLite falls back to cf_sql_varchar", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteModel");
				expect(adapter.$getType(type = "definitely_not_a_type")).toBe("cf_sql_varchar");
			});

			it("MySQL errors without Wheels.UnknownColumnType", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLModel");
				var state = {type = ""};
				try {
					adapter.$getType(type = "definitely_not_a_type");
				} catch (any e) {
					state.type = e.type;
				}
				expect(Len(state.type)).toBeGT(0);
				expect(state.type).notToBe("Wheels.UnknownColumnType");
			});

		});

		describe("S16 HOLD last-resort identity stays", () => {

			it("Oracle still emits MAX(ROWID) when no sequence is found", () => {
				var probe = CreateObject("component", "wheels.tests._assets.adapters.OracleProbe");
				ArrayAppend(probe.queryResults, QueryNew("sequence_name", "varchar", []));
				ArrayAppend(probe.queryResults, QueryNew("lastId", "integer", [{lastId: 9}]));
				var rv = probe.$identitySelect(
					queryAttributes = {},
					result = {sql: "INSERT INTO users (firstname) VALUES ('x')"},
					primaryKey = "id",
					returningIdentity = ""
				);
				expect(rv.lastId).toBe(9);
				expect(probe.capturedSql[2]).toInclude("MAX(ROWID)");
			});

			it("MSSQL still emits @@IDENTITY when the batch has no resultset", () => {
				var probe = CreateObject("component", "wheels.tests._assets.adapters.MSSQLProbe");
				ArrayAppend(probe.queryResults, QueryNew("lastId", "integer", [{lastId: 7}]));
				var rv = probe.$identitySelect(
					queryAttributes = {},
					result = {sql: "INSERT INTO users (firstname) VALUES ('x')"},
					primaryKey = "id",
					returningIdentity = QueryNew("lastId", "varchar", [])
				);
				expect(rv.identitycol).toBe(7);
				expect(probe.capturedSql[1]).toInclude("@@IDENTITY");
			});

			it("does not remove the last-resort SQL from the adapters", () => {
				var oracleSrc = FileRead(ExpandPath("/wheels/databaseAdapters/Oracle/OracleModel.cfc"));
				var mssqlSrc = FileRead(ExpandPath("/wheels/databaseAdapters/MicrosoftSQLServer/MicrosoftSQLServerModel.cfc"));
				expect(oracleSrc).toInclude("MAX(ROWID)");
				expect(mssqlSrc).toInclude("@@IDENTITY");
			});

		});

		describe("S17 MSSQL quoteTableName is bracket-only", () => {

			it("quotes schema.table as [schema].[table]", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerMigrator");
				var dotted = adapter.quoteTableName("dbo.users");
				expect(dotted).toInclude("].[");
				expect(dotted).notToInclude("`");
				expect(Left(dotted, 1)).toBe("[");
				expect(Right(dotted, 1)).toBe("]");
				var bare = adapter.quoteTableName("users");
				expect(bare).toInclude("users");
				expect(bare).notToInclude("`");
				expect(Left(bare, 1)).toBe("[");
				expect(Right(bare, 1)).toBe("]");
			});

		});

		describe("S18 Oracle createTable scopes col and fk", () => {

			it("emits columns and foreign keys from scoped loop variables", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.Oracle.OracleMigrator");
				var pk1 = CreateObject("component", "wheels.migrator.ColumnDefinition").init(
					adapter = adapter,
					name = "firstId",
					type = "integer"
				);
				var pk2 = CreateObject("component", "wheels.migrator.ColumnDefinition").init(
					adapter = adapter,
					name = "secondId",
					type = "integer"
				);
				var col = CreateObject("component", "wheels.migrator.ColumnDefinition").init(
					adapter = adapter,
					name = "title",
					type = "string"
				);
				var fk = CreateObject("component", "wheels.migrator.ForeignKeyDefinition").init(
					adapter = adapter,
					table = "posts",
					referenceTable = "users",
					column = "userid",
					referenceColumn = "id"
				);
				var sql = adapter.createTable(
					name = "posts",
					columns = [col],
					primaryKeys = [pk1, pk2],
					foreignKeys = [fk]
				);
				expect(sql).toInclude("CREATE TABLE posts");
				expect(sql).toInclude("title");
				expect(sql).toInclude("firstId");
				expect(sql).toInclude("FOREIGN KEY");
			});

			it("does not call unscoped col or fk in createTable", () => {
				var src = FileRead(ExpandPath("/wheels/databaseAdapters/Oracle/OracleMigrator.cfc"));
				expect(src).notToInclude("arrayAppend(local.lines, col.toSQL())");
				expect(src).toInclude("arrayAppend(local.lines, local.col.toSQL())");
				expect(src).notToInclude("arrayAppend(local.lines, fk.toForeignKeySQL())");
				expect(src).toInclude("arrayAppend(local.lines, local.fk.toForeignKeySQL())");
			});

		});

	}

}
