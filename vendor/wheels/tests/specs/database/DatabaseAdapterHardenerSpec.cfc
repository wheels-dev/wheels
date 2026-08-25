/**
 * databaseAdapters Hardener S1–S18.
 * Former HOLDs S2/S6/S8/S12/S13/S14/S15/S16 are flipped to the fail-loud contracts.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("S2 $executeQuery keeps bound string null after IS", () => {

			it("keeps the quoted string null as a bound parameter after IS and IS NOT", () => {
				var sql = g.model("post").$whereClause(where = "title IS 'null'");
				sql = g.model("post").$addWhereClauseParameters(sql = sql, where = "title IS 'null'");
				var found = {value = "", flaggedNull = false};
				for (var part in sql) {
					if (IsStruct(part) && StructKeyExists(part, "value") && LCase(ToString(part.value)) == "null") {
						found.value = part.value;
						if (StructKeyExists(part, "null") && part.null) {
							found.flaggedNull = true;
						}
					}
				}
				expect(LCase(found.value)).toBe("null");
				expect(IsSimpleValue(found.value)).toBeTrue();
				expect(found.flaggedNull).toBeFalse();

				sql = g.model("post").$whereClause(where = "title IS NOT 'null'");
				sql = g.model("post").$addWhereClauseParameters(sql = sql, where = "title IS NOT 'null'");
				found = {value = "", flaggedNull = false};
				for (part in sql) {
					if (IsStruct(part) && StructKeyExists(part, "value") && LCase(ToString(part.value)) == "null") {
						found.value = part.value;
						if (StructKeyExists(part, "null") && part.null) {
							found.flaggedNull = true;
						}
					}
				}
				expect(LCase(found.value)).toBe("null");
				expect(found.flaggedNull).toBeFalse();
			});

			it("marks the unquoted NULL keyword as SQL NULL", () => {
				var sql = g.model("post").$whereClause(where = "averagerating IS NULL");
				sql = g.model("post").$addWhereClauseParameters(sql = sql, where = "averagerating IS NULL");
				var found = {flaggedNull = false};
				for (var part in sql) {
					if (IsStruct(part) && StructKeyExists(part, "null") && part.null) {
						found.flaggedNull = true;
					}
				}
				expect(found.flaggedNull).toBeTrue();

				sql = g.model("post").$whereClause(where = "averagerating IS NOT NULL");
				sql = g.model("post").$addWhereClauseParameters(sql = sql, where = "averagerating IS NOT NULL");
				found = {flaggedNull = false};
				for (part in sql) {
					if (IsStruct(part) && StructKeyExists(part, "null") && part.null) {
						found.flaggedNull = true;
					}
				}
				expect(found.flaggedNull).toBeTrue();
			});

			it("does not coerce the literal string null after IS in $executeQuery", () => {
				var src = FileRead(ExpandPath("/wheels/databaseAdapters/Base.cfc"));
				var start = Find("public struct function $executeQuery", src);
				var body = Mid(src, start, 2800);
				expect(body).notToInclude('part.value == "null"');
				expect(body).notToInclude('right(prev, 2) == "IS"');
				expect(body).notToInclude('right(prev, 6) == "IS NOT"');
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

		describe("S6 MySQL optionsIncludeDefault keeps DEFAULT", () => {

			it("MySQL emits DEFAULT for text and float", () => {
				var mysql = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLMigrator");
				expect(mysql.optionsIncludeDefault(type = "text", default = "long body")).toBeTrue();
				expect(mysql.optionsIncludeDefault(type = "float", default = "1.25")).toBeTrue();
				expect(mysql.optionsIncludeDefault(type = "string", default = "hello")).toBeTrue();
				var sql = mysql.addColumnOptions(
					sql = "",
					options = {type: "text", default: "long body", allowNull: true}
				);
				expect(sql).toInclude("DEFAULT");
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

		describe("S12 SQLite advisory locks are unsupported", () => {

			it("reports no support so acquire is unused", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteModel");
				expect(adapter.$supportsAdvisoryLocks()).toBeFalse();
				adapter.$acquireAdvisoryLock(name = "hardener_s12", timeout = 1);
				adapter.$releaseAdvisoryLock(name = "hardener_s12");
			});

		});

		describe("S13 foreignKeySQL unknown action throws", () => {

			it("throws Wheels.InvalidReferentialAction for restrict and set default", () => {
				var state = {adapter = CreateObject("component", "wheels.databaseAdapters.Abstract"), type = ""};
				try {
					state.adapter.foreignKeySQL(
						name = "fk_posts_users",
						table = "posts",
						referenceTable = "users",
						column = "userid",
						referenceColumn = "id",
						onUpdate = "restrict",
						onDelete = "set default"
					);
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels.InvalidReferentialAction");
			});

			it("still maps none, null, cascade, and true", () => {
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
				sql = adapter.foreignKeySQL(
					name = "fk_posts_users",
					table = "posts",
					referenceTable = "users",
					column = "userid",
					referenceColumn = "id",
					onUpdate = "cascade",
					onDelete = "true"
				);
				expect(sql).toInclude("ON UPDATE CASCADE");
				expect(sql).toInclude("ON DELETE CASCADE");
			});

		});

		describe("S14 empty string default throws Wheels.InvalidDefault", () => {

			it("Abstract throws Wheels.InvalidDefault for string default empty", () => {
				var state = {adapter = CreateObject("component", "wheels.databaseAdapters.Abstract"), type = ""};
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

			it("PostgreSQL throws Wheels.InvalidDefault for string default empty", () => {
				var state = {
					adapter = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLMigrator"),
					type = ""
				};
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

		});

		describe("S15 unmapped $getType throws Wheels.UnknownColumnType", () => {

			it("PostgreSQL throws Wheels.UnknownColumnType", () => {
				var state = {
					adapter = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLModel"),
					type = ""
				};
				try {
					state.adapter.$getType(type = "definitely_not_a_type");
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels.UnknownColumnType");
			});

			it("SQLite throws Wheels.UnknownColumnType", () => {
				var state = {
					adapter = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteModel"),
					type = ""
				};
				try {
					state.adapter.$getType(type = "definitely_not_a_type");
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels.UnknownColumnType");
			});

			it("MySQL, H2, Oracle, and MSSQL throw Wheels.UnknownColumnType", () => {
				var paths = [
					"wheels.databaseAdapters.MySQL.MySQLModel",
					"wheels.databaseAdapters.H2.H2Model",
					"wheels.databaseAdapters.Oracle.OracleModel",
					"wheels.databaseAdapters.MicrosoftSQLServer.MicrosoftSQLServerModel"
				];
				for (var path in paths) {
					var state = {adapter = CreateObject("component", path), type = ""};
					try {
						state.adapter.$getType(type = "definitely_not_a_type");
					} catch (any e) {
						state.type = e.type;
					}
					expect(state.type).toBe("Wheels.UnknownColumnType");
				}
			});

		});

		describe("S16 last-resort identity is gone", () => {

			it("Oracle throws Wheels.IdentityNotFound when no sequence is found", () => {
				var probe = CreateObject("component", "wheels.tests._assets.adapters.OracleProbe");
				ArrayAppend(probe.queryResults, QueryNew("sequence_name", "varchar", []));
				var state = {type = ""};
				try {
					probe.$identitySelect(
						queryAttributes = {},
						result = {sql: "INSERT INTO users (firstname) VALUES ('x')"},
						primaryKey = "id",
						returningIdentity = ""
					);
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels.IdentityNotFound");
				expect(ArrayToList(probe.capturedSql, " ")).notToInclude("MAX(ROWID)");
			});

			it("MSSQL throws Wheels.IdentityNotFound when the batch has no resultset", () => {
				var probe = CreateObject("component", "wheels.tests._assets.adapters.MSSQLProbe");
				var state = {type = ""};
				try {
					probe.$identitySelect(
						queryAttributes = {},
						result = {sql: "INSERT INTO users (firstname) VALUES ('x')"},
						primaryKey = "id",
						returningIdentity = QueryNew("lastId", "varchar", [])
					);
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels.IdentityNotFound");
				expect(ArrayToList(probe.capturedSql, " ")).notToInclude("@@IDENTITY");
			});

			it("does not keep last-resort SQL in the adapters", () => {
				var oracleSrc = FileRead(ExpandPath("/wheels/databaseAdapters/Oracle/OracleModel.cfc"));
				var mssqlSrc = FileRead(ExpandPath("/wheels/databaseAdapters/MicrosoftSQLServer/MicrosoftSQLServerModel.cfc"));
				expect(oracleSrc).notToInclude("MAX(ROWID)");
				expect(mssqlSrc).notToInclude("@@IDENTITY");
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
