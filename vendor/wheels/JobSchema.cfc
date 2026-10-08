/**
 * The background-job schema, defined once. Auto-create (Job.$ensureJobTable() and the column
 * upgrades) builds its DDL from it, and `wheels jobs install` writes a migration from it, so the
 * two build the same tables, columns and indexes.
 *
 * Each table lists its columns in creation order, as {name, type, limit, precision, nullable,
 * default, primaryKey}, with type one of string, unicodeString (NVARCHAR on SQL Server, whose
 * VARCHAR mangles non-ASCII text), integer, decimal (whole numbers, used for epoch
 * milliseconds), text or datetime, and its indexes as
 * {name, columns, unique, optional}. An optional index is a performance index that auto-create
 * tolerates failing to build; a non-optional one is relied on (the uniqueKey index de-duplicates
 * enqueue). On SQL Server the uniqueKey index is filtered to non-NULL keys, because a SQL Server
 * unique index otherwise admits a single NULL.
 */
component {

	/**
	 * @datasource The datasource the catalog checks run against. Defaults to the app's. A
	 * migration passes the migrator's ($migratorDataSource()), which a TenantMigrator points at
	 * each tenant's database.
	 * @credentials Optional {username, password} for that datasource, as the migrator uses them.
	 */
	public any function init(string datasource = "", struct credentials = {}) {
		variables.datasource = arguments.datasource;
		variables.credentials = arguments.credentials;
		if (!Len(variables.datasource) && StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "dataSourceName")) {
			variables.datasource = application.wheels.dataSourceName;
		}
		return this;
	}

	/**
	 * The job tables, in creation order.
	 */
	public array function tables() {
		return [
			{
				name = "wheels_jobs",
				columns = [
					{name = "id", type = "string", limit = 36, nullable = false, primaryKey = true},
					{name = "jobClass", type = "string", limit = 255, nullable = false},
					{name = "queue", type = "string", limit = 100, nullable = false, default = "default"},
					{name = "data", type = "text", nullable = true},
					{name = "priority", type = "integer", nullable = false, default = 0},
					{name = "status", type = "string", limit = 20, nullable = false, default = "pending"},
					{name = "attempts", type = "integer", nullable = false, default = 0},
					{name = "maxRetries", type = "integer", nullable = false, default = 3},
					{name = "claimTimeout", type = "integer", nullable = true},
					{name = "claimToken", type = "string", limit = 36, nullable = true},
					{name = "claimedBy", type = "string", limit = 128, nullable = true},
					{name = "uniqueKey", type = "string", limit = 255, nullable = true},
					{name = "heartbeatAt", type = "datetime", nullable = true},
					{name = "result", type = "unicodeString", limit = 4000, nullable = true},
					{name = "lastError", type = "text", nullable = true},
					{name = "runAt", type = "datetime", nullable = true},
					{name = "completedAt", type = "datetime", nullable = true},
					{name = "failedAt", type = "datetime", nullable = true},
					{name = "createdAt", type = "datetime", nullable = true},
					{name = "updatedAt", type = "datetime", nullable = true}
				],
				indexes = [
					{name = "idx_wjobs_processing", columns = "status,runAt,priority", unique = false, optional = true},
					{name = "idx_wjobs_queue", columns = "queue,status", unique = false, optional = true},
					{name = "idx_wjobs_cleanup", columns = "status,completedAt", unique = false, optional = true},
					{name = "idx_wjobs_unique_key", columns = "uniqueKey", unique = true, optional = false}
				]
			},
			{
				// One row per server running jobs: its concurrency cap, drain state and last poll.
				name = "wheels_job_hosts",
				columns = [
					{name = "host", type = "string", limit = 128, nullable = false, primaryKey = true},
					{name = "lastSeenAt", type = "datetime", nullable = true},
					{name = "startedAt", type = "datetime", nullable = true},
					{name = "running", type = "integer", nullable = false, default = 0},
					{name = "maxConcurrent", type = "integer", nullable = false, default = 0},
					{name = "draining", type = "integer", nullable = false, default = 0},
					{name = "drainExpiresAt", type = "datetime", nullable = true},
					{name = "codeVersion", type = "string", limit = 64, nullable = true}
				],
				indexes = []
			},
			{
				// Recurring schedules; times are epoch milliseconds.
				name = "wheels_job_schedules",
				columns = [
					{name = "name", type = "string", limit = 100, nullable = false, primaryKey = true},
					{name = "jobClass", type = "string", limit = 255, nullable = false},
					{name = "data", type = "text", nullable = true},
					{name = "queue", type = "string", limit = 100, nullable = true},
					{name = "priority", type = "integer", nullable = true},
					{name = "kind", type = "string", limit = 10, nullable = false},
					{name = "spec", type = "string", limit = 100, nullable = false},
					{name = "timezone", type = "string", limit = 64, nullable = true},
					{name = "catchUp", type = "string", limit = 10, nullable = true},
					{name = "catchUpWindowSeconds", type = "integer", nullable = true},
					{name = "enabled", type = "integer", nullable = false, default = 1},
					{name = "source", type = "string", limit = 10, nullable = false, default = "db"},
					{name = "nextRunAt", type = "decimal", precision = 15, nullable = true},
					{name = "lastEnqueuedFor", type = "decimal", precision = 15, nullable = true},
					{name = "lastError", type = "string", limit = 1000, nullable = true},
					{name = "updatedAt", type = "datetime", nullable = true}
				],
				indexes = []
			},
			{
				// Exclusive-job leases (wheels.LeaseLock); times are epoch milliseconds.
				name = "wheels_job_locks",
				columns = [
					{name = "lockname", type = "string", limit = 100, nullable = false, primaryKey = true},
					{name = "lockowner", type = "string", limit = 64, nullable = false},
					{name = "lockhost", type = "string", limit = 255, nullable = true},
					{name = "acquiredat", type = "decimal", precision = 15, nullable = false},
					{name = "expiresat", type = "decimal", precision = 15, nullable = false}
				],
				indexes = []
			}
		];
	}

	/**
	 * One table's definition.
	 */
	public struct function tableDef(required string name) {
		for (local.t in tables()) {
			if (CompareNoCase(local.t.name, arguments.name) == 0) {
				return local.t;
			}
		}
		Throw(type = "Wheels.JobSchema.UnknownTable", message = "#arguments.name# is not a job table.");
	}

	/**
	 * One column's definition.
	 */
	public struct function columnDef(required string tableName, required string columnName) {
		for (local.c in tableDef(arguments.tableName).columns) {
			if (CompareNoCase(local.c.name, arguments.columnName) == 0) {
				return local.c;
			}
		}
		Throw(type = "Wheels.JobSchema.UnknownColumn", message = "#arguments.tableName#.#arguments.columnName# is not a job column.");
	}

	/**
	 * One index's definition.
	 */
	public struct function indexDef(required string tableName, required string indexName) {
		for (local.i in tableDef(arguments.tableName).indexes) {
			if (CompareNoCase(local.i.name, arguments.indexName) == 0) {
				return local.i;
			}
		}
		Throw(type = "Wheels.JobSchema.UnknownIndex", message = "#arguments.indexName# is not an index on #arguments.tableName#.");
	}

	/**
	 * A column's SQL type on a database: VARCHAR2/CLOB/TIMESTAMP on Oracle, CLOB/TIMESTAMP on H2,
	 * TIMESTAMP on PostgreSQL, and VARCHAR/TEXT/DATETIME elsewhere. Integers are INT everywhere,
	 * which Oracle stores as NUMBER(38); the claimTimeout column added to an older table on Oracle
	 * used to be NUMBER(10), and both hold any timeout.
	 */
	public string function columnType(required struct column, required string dbType) {
		local.varcharType = arguments.dbType == "oracle" ? "VARCHAR2" : "VARCHAR";
		local.textType = ListFindNoCase("oracle,h2", arguments.dbType) ? "CLOB" : "TEXT";
		local.datetimeType = ListFindNoCase("oracle,postgresql,h2", arguments.dbType) ? "TIMESTAMP" : "DATETIME";
		switch (arguments.column.type) {
			case "string":
				return "#local.varcharType#(#arguments.column.limit#)";
			case "unicodeString":
				return arguments.dbType == "sqlserver" ? "NVARCHAR(#arguments.column.limit#)" : "#local.varcharType#(#arguments.column.limit#)";
			case "decimal":
				return "DECIMAL(#arguments.column.precision#,0)";
			case "text":
				return local.textType;
			case "datetime":
				return local.datetimeType;
			default:
				return "INT";
		}
	}

	/**
	 * A column's definition inside CREATE TABLE.
	 */
	public string function columnDefinition(required struct column, required string dbType) {
		local.sql = "#arguments.column.name# #columnType(arguments.column, arguments.dbType)#";
		if (StructKeyExists(arguments.column, "default")) {
			local.sql &= " DEFAULT " & (arguments.column.type == "integer" ? arguments.column.default : "'#arguments.column.default#'");
		}
		if (!arguments.column.nullable) {
			local.sql &= " NOT NULL";
		}
		if (StructKeyExists(arguments.column, "primaryKey") && arguments.column.primaryKey) {
			local.sql &= " PRIMARY KEY";
		}
		return local.sql;
	}

	/**
	 * CREATE TABLE for a job table on a database.
	 */
	public string function createTableSql(required string tableName, required string dbType) {
		local.definitions = [];
		for (local.c in tableDef(arguments.tableName).columns) {
			ArrayAppend(local.definitions, columnDefinition(local.c, arguments.dbType));
		}
		return "CREATE TABLE #arguments.tableName# (" & ArrayToList(local.definitions, ", ") & ")";
	}

	/**
	 * The DDL that adds a (nullable) column to an existing job table. SQL Server has no COLUMN
	 * keyword and Oracle takes a parenthesised column list; everything else accepts ADD COLUMN.
	 */
	public string function addColumnSql(required string tableName, required string columnName, required string dbType) {
		local.c = columnDef(arguments.tableName, arguments.columnName);
		local.definition = "#local.c.name# #columnType(local.c, arguments.dbType)#";
		if (arguments.dbType == "oracle") {
			return "ALTER TABLE #arguments.tableName# ADD (#local.definition#)";
		}
		if (arguments.dbType == "sqlserver") {
			return "ALTER TABLE #arguments.tableName# ADD #local.definition#";
		}
		return "ALTER TABLE #arguments.tableName# ADD COLUMN #local.definition#";
	}

	/**
	 * CREATE INDEX for one of a job table's indexes on a database.
	 */
	public string function indexSql(required string tableName, required string indexName, required string dbType) {
		local.i = indexDef(arguments.tableName, arguments.indexName);
		local.sql = "CREATE " & (local.i.unique ? "UNIQUE " : "") & "INDEX #local.i.name# ON #arguments.tableName# (#Replace(local.i.columns, ",", ", ", "all")#)";
		if (local.i.unique && arguments.dbType == "sqlserver") {
			local.sql &= " WHERE #local.i.columns# IS NOT NULL";
		}
		return local.sql;
	}

	/**
	 * Whether the job tables may be created and upgraded automatically: the jobsAutoCreateTables
	 * setting, true unless an app that installs the schema through a migration turns it off.
	 */
	public boolean function autoCreateEnabled() {
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "jobsAutoCreateTables")) {
			return IsBoolean(application.wheels.jobsAutoCreateTables) ? application.wheels.jobsAutoCreateTables : true;
		}
		return true;
	}

	/**
	 * The message for a job table or column that is missing while auto-create is off.
	 */
	public string function missingSchemaMessage(required string what) {
		return "#arguments.what# is missing and jobsAutoCreateTables is false, so it isn't created automatically. Generate the jobs migration with `wheels jobs install` and run it with `wheels migrate latest`.";
	}

	/**
	 * The database type, as Job.$detectDatabaseType() reports it.
	 */
	public string function databaseType() {
		if (!StructKeyExists(variables, "dbTypeCached")) {
			local.job = new wheels.Job();
			variables.dbTypeCached = local.job.$databaseTypeOf(variables.datasource);
		}
		return variables.dbTypeCached;
	}

	/**
	 * Whether a table exists, from the database's catalog. Never a failing probe query, so it is
	 * safe inside a migration's transaction (a failed statement aborts a PostgreSQL transaction).
	 */
	public boolean function hasTable(required string tableName) {
		local.name = LCase(arguments.tableName);
		switch (databaseType()) {
			case "sqlite":
				return $catalogHasRow("SELECT 1 FROM sqlite_master WHERE type = 'table' AND LOWER(name) = :name", {name = local.name});
			case "oracle":
				return $catalogHasRow("SELECT 1 FROM user_tables WHERE LOWER(table_name) = :name", {name = local.name});
			case "sqlserver":
				return $catalogHasRow("SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE LOWER(TABLE_NAME) = :name AND TABLE_SCHEMA = SCHEMA_NAME()", {name = local.name});
			case "mysql":
				return $catalogHasRow("SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND LOWER(table_name) = :name", {name = local.name});
			case "postgresql":
				return $catalogHasRow("SELECT 1 FROM information_schema.tables WHERE table_schema = current_schema() AND LOWER(table_name) = :name", {name = local.name});
			default:
				return $catalogHasRow("SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE LOWER(TABLE_NAME) = :name", {name = local.name});
		}
	}

	/**
	 * Whether a table has a column, from the database's catalog (see hasTable()).
	 */
	public boolean function hasColumn(required string tableName, required string columnName) {
		local.params = {name = LCase(arguments.tableName), col = LCase(arguments.columnName)};
		switch (databaseType()) {
			case "sqlite":
				return $catalogHasRow("SELECT 1 FROM pragma_table_info('#$safeName(arguments.tableName)#') WHERE LOWER(name) = :col", {col = local.params.col});
			case "oracle":
				return $catalogHasRow("SELECT 1 FROM user_tab_columns WHERE LOWER(table_name) = :name AND LOWER(column_name) = :col", local.params);
			case "sqlserver":
				return $catalogHasRow("SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE LOWER(TABLE_NAME) = :name AND LOWER(COLUMN_NAME) = :col AND TABLE_SCHEMA = SCHEMA_NAME()", local.params);
			case "mysql":
				return $catalogHasRow("SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND LOWER(table_name) = :name AND LOWER(column_name) = :col", local.params);
			case "postgresql":
				return $catalogHasRow("SELECT 1 FROM information_schema.columns WHERE table_schema = current_schema() AND LOWER(table_name) = :name AND LOWER(column_name) = :col", local.params);
			default:
				return $catalogHasRow("SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE LOWER(TABLE_NAME) = :name AND LOWER(COLUMN_NAME) = :col", local.params);
		}
	}

	/**
	 * Whether a table has a named index, from the database's catalog (see hasTable()).
	 */
	public boolean function hasIndex(required string tableName, required string indexName) {
		local.params = {name = LCase(arguments.tableName), idx = LCase(arguments.indexName)};
		switch (databaseType()) {
			case "sqlite":
				return $catalogHasRow("SELECT 1 FROM sqlite_master WHERE type = 'index' AND LOWER(tbl_name) = :name AND LOWER(name) = :idx", local.params);
			case "oracle":
				return $catalogHasRow("SELECT 1 FROM user_indexes WHERE LOWER(table_name) = :name AND LOWER(index_name) = :idx", local.params);
			case "sqlserver":
				return $catalogHasRow("SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(:name) AND LOWER(name) = :idx", local.params);
			case "mysql":
				return $catalogHasRow("SELECT 1 FROM information_schema.statistics WHERE table_schema = DATABASE() AND LOWER(table_name) = :name AND LOWER(index_name) = :idx", local.params);
			case "postgresql":
				return $catalogHasRow("SELECT 1 FROM pg_indexes WHERE schemaname = current_schema() AND LOWER(tablename) = :name AND LOWER(indexname) = :idx", local.params);
			default:
				return $catalogHasRow("SELECT 1 FROM INFORMATION_SCHEMA.INDEXES WHERE LOWER(TABLE_NAME) = :name AND LOWER(INDEX_NAME) = :idx", local.params);
		}
	}

	/**
	 * A table's columns as the database's catalog reports them: lower-cased column name ->
	 * nullable (boolean). Used to check that the install migration and auto-create agree.
	 */
	public struct function catalogColumns(required string tableName) {
		local.name = LCase(arguments.tableName);
		local.params = {name = {value = local.name, cfsqltype = "cf_sql_varchar"}};
		switch (databaseType()) {
			case "sqlite":
				local.sql = "SELECT name AS colname, CASE WHEN ""notnull"" = 1 OR pk = 1 THEN 'NO' ELSE 'YES' END AS nullable FROM pragma_table_info('#$safeName(arguments.tableName)#')";
				local.params = {};
				break;
			case "oracle":
				local.sql = "SELECT column_name AS colname, CASE WHEN nullable = 'Y' THEN 'YES' ELSE 'NO' END AS nullable FROM user_tab_columns WHERE LOWER(table_name) = :name";
				break;
			case "sqlserver":
				local.sql = "SELECT COLUMN_NAME AS colname, IS_NULLABLE AS nullable FROM INFORMATION_SCHEMA.COLUMNS WHERE LOWER(TABLE_NAME) = :name AND TABLE_SCHEMA = SCHEMA_NAME()";
				break;
			case "mysql":
				local.sql = "SELECT column_name AS colname, is_nullable AS nullable FROM information_schema.columns WHERE table_schema = DATABASE() AND LOWER(table_name) = :name";
				break;
			case "postgresql":
				local.sql = "SELECT column_name AS colname, is_nullable AS nullable FROM information_schema.columns WHERE table_schema = current_schema() AND LOWER(table_name) = :name";
				break;
			default:
				local.sql = "SELECT COLUMN_NAME AS colname, IS_NULLABLE AS nullable FROM INFORMATION_SCHEMA.COLUMNS WHERE LOWER(TABLE_NAME) = :name";
		}
		local.rows = QueryExecute(local.sql, local.params, $queryOptions());
		local.rv = {};
		for (local.i = 1; local.i <= local.rows.recordCount; local.i++) {
			local.rv[LCase(local.rows.colname[local.i])] = CompareNoCase(Trim(local.rows.nullable[local.i]), "YES") == 0;
		}
		return local.rv;
	}

	/**
	 * The source of the migration `wheels jobs install` writes: migrator DSL that creates each job
	 * table, or tops up one that auto-create already built (adding only its missing columns and
	 * indexes), so running it on any existing install is safe and running it twice changes nothing.
	 */
	public string function migrationSource() {
		local.nl = Chr(10);
		local.lines = [];
		ArrayAppend(local.lines, "/**");
		ArrayAppend(local.lines, " * The Wheels background-job tables (generated by `wheels jobs install`).");
		ArrayAppend(local.lines, " *");
		ArrayAppend(local.lines, " * Creates each job table, or adds what an existing one is missing: tables that Wheels created");
		ArrayAppend(local.lines, " * automatically are adopted, and running it again changes nothing. With this migration applied,");
		ArrayAppend(local.lines, " * set(jobsAutoCreateTables = false) so servers never change the job tables at startup.");
		ArrayAppend(local.lines, " *");
		ArrayAppend(local.lines, " * down() drops the job tables, including ones this migration adopted rather than created, and");
		ArrayAppend(local.lines, " * every job in them.");
		ArrayAppend(local.lines, " */");
		ArrayAppend(local.lines, "component extends=""wheels.migrator.Migration"" {");
		ArrayAppend(local.lines, "");
		ArrayAppend(local.lines, "	// Runs outside the migrator's per-step transaction: it is idempotent (a partial run is");
		ArrayAppend(local.lines, "	// finished by running it again), and its DDL can't share one transaction everywhere");
		ArrayAppend(local.lines, "	// (CockroachDB under read-committed isolation; MySQL and Oracle commit each statement).");
		ArrayAppend(local.lines, "	this.useTransaction = false;");
		ArrayAppend(local.lines, "");
		ArrayAppend(local.lines, "	function up() {");
		ArrayAppend(local.lines, "		var schema = new wheels.JobSchema(datasource = $migratorDataSource(), credentials = $migratorDataSourceCredentials());");
		for (local.t in tables()) {
			ArrayAppend(local.lines, "");
			ArrayAppend(local.lines, "		if (!schema.hasTable(""#local.t.name#"")) {");
			ArrayAppend(local.lines, "			local.t = createTable(name = ""#local.t.name#"", id = false);");
			for (local.c in local.t.columns) {
				ArrayAppend(local.lines, "			" & $dslColumn(local.c));
			}
			ArrayAppend(local.lines, "			local.t.create();");
			for (local.c in local.t.columns) {
				if (local.c.type == "unicodeString") {
					ArrayAppend(local.lines, "			// SQL Server's VARCHAR mangles non-ASCII text, so the column is NVARCHAR there.");
					ArrayAppend(local.lines, "			if (schema.databaseType() == ""sqlserver"") {");
					ArrayAppend(local.lines, "				execute(""ALTER TABLE #local.t.name# ALTER COLUMN #local.c.name# NVARCHAR(#local.c.limit#)" & (local.c.nullable ? " NULL" : " NOT NULL") & """);");
					ArrayAppend(local.lines, "			}");
				}
			}
			ArrayAppend(local.lines, "		} else {");
			for (local.c in local.t.columns) {
				if (local.c.nullable) {
					ArrayAppend(local.lines, "			if (!schema.hasColumn(""#local.t.name#"", ""#local.c.name#"")) {");
					if (local.c.type == "unicodeString") {
						ArrayAppend(local.lines, "				if (schema.databaseType() == ""sqlserver"") {");
						ArrayAppend(local.lines, "					execute(""ALTER TABLE #local.t.name# ADD #local.c.name# NVARCHAR(#local.c.limit#)"");");
						ArrayAppend(local.lines, "				} else {");
						ArrayAppend(local.lines, "					" & $dslAddColumn(local.t.name, local.c));
						ArrayAppend(local.lines, "				}");
					} else {
						ArrayAppend(local.lines, "				" & $dslAddColumn(local.t.name, local.c));
					}
					if (local.c.name == "uniqueKey") {
						ArrayAppend(local.lines, "				execute(""UPDATE #local.t.name# SET uniqueKey = id WHERE uniqueKey IS NULL"");");
					}
					ArrayAppend(local.lines, "			}");
				}
			}
			ArrayAppend(local.lines, "		}");
			for (local.i in local.t.indexes) {
				ArrayAppend(local.lines, "		if (!schema.hasIndex(""#local.t.name#"", ""#local.i.name#"")) {");
				if (local.i.unique) {
					ArrayAppend(local.lines, "			// SQL Server's unique indexes admit a single NULL, so the index is filtered there.");
					ArrayAppend(local.lines, "			if (schema.databaseType() == ""sqlserver"") {");
					ArrayAppend(local.lines, "				execute(""CREATE UNIQUE INDEX #local.i.name# ON #local.t.name# (#local.i.columns#) WHERE #local.i.columns# IS NOT NULL"");");
					ArrayAppend(local.lines, "			} else {");
					ArrayAppend(local.lines, "				addIndex(table = ""#local.t.name#"", columnNames = ""#local.i.columns#"", unique = true, indexName = ""#local.i.name#"");");
					ArrayAppend(local.lines, "			}");
				} else {
					ArrayAppend(local.lines, "			addIndex(table = ""#local.t.name#"", columnNames = ""#local.i.columns#"", indexName = ""#local.i.name#"");");
				}
				ArrayAppend(local.lines, "		}");
			}
		}
		ArrayAppend(local.lines, "	}");
		ArrayAppend(local.lines, "");
		ArrayAppend(local.lines, "	function down() {");
		ArrayAppend(local.lines, "		var schema = new wheels.JobSchema(datasource = $migratorDataSource(), credentials = $migratorDataSourceCredentials());");
		local.reversed = tables();
		for (local.n = ArrayLen(local.reversed); local.n >= 1; local.n--) {
			ArrayAppend(local.lines, "		if (schema.hasTable(""#local.reversed[local.n].name#"")) {");
			ArrayAppend(local.lines, "			dropTable(""#local.reversed[local.n].name#"");");
			ArrayAppend(local.lines, "		}");
		}
		ArrayAppend(local.lines, "	}");
		ArrayAppend(local.lines, "");
		ArrayAppend(local.lines, "}");
		return ArrayToList(local.lines, local.nl) & local.nl;
	}

	/**
	 * Internal: a column as a TableDefinition call inside createTable().
	 */
	public string function $dslColumn(required struct column) {
		if (StructKeyExists(arguments.column, "primaryKey") && arguments.column.primaryKey) {
			return "local.t.primaryKey(name = ""#arguments.column.name#"", type = ""#arguments.column.type#"", limit = #arguments.column.limit#);";
		}
		return "local.t.#$dslType(arguments.column)#(#$dslOptions(arguments.column)#);";
	}

	/**
	 * Internal: a missing nullable column as an addColumn() call.
	 */
	public string function $dslAddColumn(required string tableName, required struct column) {
		local.call = "addColumn(table = ""#arguments.tableName#"", columnType = ""#$dslType(arguments.column)#"", columnName = ""#arguments.column.name#""";
		if (StructKeyExists(arguments.column, "limit")) {
			local.call &= ", limit = #arguments.column.limit#";
		}
		if (StructKeyExists(arguments.column, "precision")) {
			local.call &= ", precision = #arguments.column.precision#, scale = 0";
		}
		return local.call & ", allowNull = true);";
	}

	/**
	 * Internal: the TableDefinition helper for a column type.
	 */
	public string function $dslType(required struct column) {
		// The column helpers have no unicode string: SQL Server's NVARCHAR is set by execute().
		return arguments.column.type == "unicodeString" ? "string" : arguments.column.type;
	}

	/**
	 * Internal: a column's named arguments for its TableDefinition helper.
	 */
	public string function $dslOptions(required struct column) {
		local.options = ["columnNames = ""#arguments.column.name#"""];
		if (StructKeyExists(arguments.column, "limit")) {
			ArrayAppend(local.options, "limit = #arguments.column.limit#");
		}
		if (StructKeyExists(arguments.column, "precision")) {
			ArrayAppend(local.options, "precision = #arguments.column.precision#, scale = 0");
		}
		if (StructKeyExists(arguments.column, "default")) {
			ArrayAppend(local.options, "default = " & (IsNumeric(arguments.column.default) ? arguments.column.default : """#arguments.column.default#"""));
		}
		ArrayAppend(local.options, "allowNull = " & (arguments.column.nullable ? "true" : "false"));
		return ArrayToList(local.options, ", ");
	}

	/**
	 * A table's columns by type family as the catalog reports them: lower-cased column name ->
	 * string, text, integer or datetime. Families, not exact types: a migration's column helpers
	 * and auto-create may pick different members of a family (NUMBER(10) and NUMBER(38), TEXT and
	 * NVARCHAR(MAX)). SQLite stores both string and text as TEXT, so it reports them as text.
	 */
	public struct function catalogColumnFamilies(required string tableName) {
		local.name = LCase(arguments.tableName);
		local.params = {name = {value = local.name, cfsqltype = "cf_sql_varchar"}};
		local.dbType = databaseType();
		switch (local.dbType) {
			case "sqlite":
				local.sql = "SELECT name AS colname, type AS coltype, 0 AS collength FROM pragma_table_info('#$safeName(arguments.tableName)#')";
				local.params = {};
				break;
			case "oracle":
				local.sql = "SELECT column_name AS colname, data_type AS coltype, char_length AS collength FROM user_tab_columns WHERE LOWER(table_name) = :name";
				break;
			case "sqlserver":
				local.sql = "SELECT COLUMN_NAME AS colname, DATA_TYPE AS coltype, CHARACTER_MAXIMUM_LENGTH AS collength FROM INFORMATION_SCHEMA.COLUMNS WHERE LOWER(TABLE_NAME) = :name AND TABLE_SCHEMA = SCHEMA_NAME()";
				break;
			case "mysql":
				local.sql = "SELECT column_name AS colname, data_type AS coltype, character_maximum_length AS collength FROM information_schema.columns WHERE table_schema = DATABASE() AND LOWER(table_name) = :name";
				break;
			case "postgresql":
				local.sql = "SELECT column_name AS colname, data_type AS coltype, character_maximum_length AS collength FROM information_schema.columns WHERE table_schema = current_schema() AND LOWER(table_name) = :name";
				break;
			default:
				// H2 2.x names the type in DATA_TYPE; H2 1.4 has a JDBC type code there and the
				// name in TYPE_NAME.
				local.sql = "SELECT COLUMN_NAME AS colname, DATA_TYPE AS coltype, CHARACTER_MAXIMUM_LENGTH AS collength FROM INFORMATION_SCHEMA.COLUMNS WHERE LOWER(TABLE_NAME) = :name";
				try {
					local.rows = QueryExecute(
						"SELECT COLUMN_NAME AS colname, TYPE_NAME AS coltype, CHARACTER_MAXIMUM_LENGTH AS collength FROM INFORMATION_SCHEMA.COLUMNS WHERE LOWER(TABLE_NAME) = :name",
						local.params,
						$queryOptions()
					);
				} catch (any e) {
					// H2 2.x: no TYPE_NAME column.
				}
		}
		if (!StructKeyExists(local, "rows")) {
			local.rows = QueryExecute(local.sql, local.params, $queryOptions());
		}
		local.rv = {};
		for (local.i = 1; local.i <= local.rows.recordCount; local.i++) {
			local.length = IsNumeric(local.rows.collength[local.i]) ? Val(local.rows.collength[local.i]) : 0;
			local.family = $typeFamily(type = local.rows.coltype[local.i], length = local.length);
			if (local.dbType == "sqlite" && local.family == "string") {
				local.family = "text";
			}
			local.rv[LCase(local.rows.colname[local.i])] = local.family;
		}
		return local.rv;
	}

	/**
	 * Internal: a catalog type name's family (string, text, integer, datetime), or the lower-cased
	 * name itself when it belongs to none. A character type with no length limit (-1) is text.
	 */
	public string function $typeFamily(required string type, numeric length = 0) {
		local.t = LCase(Trim(arguments.type));
		if (FindNoCase("lob", local.t) || FindNoCase("large object", local.t) || FindNoCase("text", local.t)) {
			return "text";
		}
		if (FindNoCase("char", local.t)) {
			return arguments.length == -1 ? "text" : "string";
		}
		if (FindNoCase("time", local.t) || FindNoCase("date", local.t)) {
			return "datetime";
		}
		if (FindNoCase("int", local.t) || FindNoCase("number", local.t) || FindNoCase("numeric", local.t) || FindNoCase("decimal", local.t)) {
			return "integer";
		}
		return local.t;
	}

	/**
	 * Internal: query options for this schema's datasource, with its credentials when given.
	 */
	public struct function $queryOptions() {
		local.options = {datasource = variables.datasource};
		if (StructKeyExists(variables.credentials, "username") && Len(variables.credentials.username)) {
			local.options.username = variables.credentials.username;
		}
		if (StructKeyExists(variables.credentials, "password") && Len(variables.credentials.password)) {
			local.options.password = variables.credentials.password;
		}
		return local.options;
	}

	/**
	 * Internal: true when a catalog query returns a row.
	 */
	public boolean function $catalogHasRow(required string sql, required struct values) {
		local.params = {};
		for (local.key in arguments.values) {
			local.params[local.key] = {value = arguments.values[local.key], cfsqltype = "cf_sql_varchar"};
		}
		return QueryExecute(arguments.sql, local.params, $queryOptions()).recordCount > 0;
	}

	/**
	 * Internal: a table name safe to inline (letters, digits and underscores only).
	 */
	public string function $safeName(required string name) {
		return REReplace(arguments.name, "[^A-Za-z0-9_]", "", "all");
	}

}
