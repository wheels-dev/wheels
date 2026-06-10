component extends="wheels.Global"{

	/**
	 * Used internally by Migrator to provide feedback to the GUI and CLI about completed DB operations
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 */
	public function announce(required string message) {
		param name="request.$wheelsMigrationOutput" default="";
		request.$wheelsMigrationOutput = request.$wheelsMigrationOutput & arguments.message & Chr(13) & Chr(10);
	}

	public string function $getDBType(string dataSource = "") {
		local.appKey = $appKey();
		local.dsName = Len(arguments.dataSource) ? arguments.dataSource : application[local.appKey].dataSourceName;

		// Memoize the resolved adapter name per datasource: engine identity is
		// stable for the life of the application, and discovery paths (e.g.
		// Migrator.getAvailableMigrations()) instantiate every migration CFC —
		// without this cache each init() triggers a fresh $dbinfo(version)
		// round-trip (plus a SELECT version() on PostgreSQL).
		if (
			StructKeyExists(application[local.appKey], "$migratorAdapterNames")
			&& StructKeyExists(application[local.appKey].$migratorAdapterNames, local.dsName)
		) {
			return application[local.appKey].$migratorAdapterNames[local.dsName];
		}

		local.info = $dbinfo(
			type = "version",
			datasource = local.dsName,
			username = application[local.appKey].dataSourceUserName,
			password = application[local.appKey].dataSourcePassword
		);
		local.adapterName = "";
		if (
			local.info.driver_name Contains "SQLServer"
			|| local.info.driver_name Contains "Microsoft SQL Server"
			|| local.info.driver_name Contains "MS SQL Server"
			|| local.info.database_productname Contains "Microsoft SQL Server"
		) {
			local.adapterName = "MicrosoftSQLServer";
		} else if (local.info.driver_name Contains "MySQL") {
			local.adapterName = "MySQL";
		} else if (local.info.database_productname Contains "CockroachDB") {
			local.adapterName = "CockroachDB";
		} else if (local.info.driver_name Contains "PostgreSQL") {
			// The PostgreSQL JDBC driver reports "PostgreSQL" as product name even
			// when connected to CockroachDB. Query version() to distinguish.
			try {
				local.versionQuery = queryExecute(
					"SELECT version() AS v",
					[],
					{datasource: local.dsName}
				);
				if (IsQuery(local.versionQuery) && FindNoCase("CockroachDB", local.versionQuery.v)) {
					local.adapterName = "CockroachDB";
				} else {
					local.adapterName = "PostgreSQL";
				}
			} catch (any e) {
				local.adapterName = "PostgreSQL";
			}
			// NB: using mySQL adapter for H2 as the cli defaults to this for development
		} else if (local.info.driver_name Contains "H2") {
			// determine the emulation mode
			/*
		if (StructKeyExists(server, "lucee")) {
			local.connectionString = GetApplicationMetaData().datasources[application[local.appKey].dataSourceName].connectionString;
		} else {
			// TODO: use the coldfusion class to dig out dsn info
			local.connectionString = "";
		}
		if (local.connectionString Contains "mode=SQLServer" || local.connectionString Contains "mode=Microsoft SQL Server" || local.connectionString Contains "mode=MS SQL Server" || local.connectionString Contains "mode=Microsoft SQL Server") {
			local.adapterName = "MicrosoftSQLServer";
		} else if (local.connectionString Contains "mode=MySQL") {
			local.adapterName = "MySQL";
		} else if (local.connectionString Contains "mode=PostgreSQL") {
			local.adapterName = "PostgreSQL";
		} else {
			local.adapterName = "MySQL";
		}
		*/
			local.adapterName = "H2";
		} else if (local.info.driver_name Contains "Oracle") {
			local.adapterName = "Oracle";
		} else if (local.info.driver_name Contains "SQLite") {
			local.adapterName = "SQLite";
		}
		// Only cache successful detection — an empty string means the engine
		// could not be identified and callers surface their own errors.
		if (Len(local.adapterName)) {
			if (!StructKeyExists(application[local.appKey], "$migratorAdapterNames")) {
				application[local.appKey].$migratorAdapterNames = {};
			}
			application[local.appKey].$migratorAdapterNames[local.dsName] = local.adapterName;
		}
		return local.adapterName;
	}

	private string function $getForeignKeys(required string table) {
		local.appKey = $appKey();
		local.foreignKeyList = "";
		// Probe the single table for existence instead of listing every table
		// in the schema — a failed zero-row SELECT means the table doesn't
		// exist, so there are no foreign keys to report. (Mutate a struct field
		// rather than assigning a bare local inside catch: BoxLang discards
		// `local.X = ...` assignments made in a catch body.)
		local.state = {tableExists = true};
		local.quotedTable = StructKeyExists(this, "adapter") ? this.adapter.quoteTableName(arguments.table) : arguments.table;
		try {
			$query(
				datasource = application[local.appKey].dataSourceName,
				sql = "SELECT 1 FROM #local.quotedTable# WHERE 1=0"
			);
		} catch (any e) {
			local.state.tableExists = false;
		}
		if (local.state.tableExists) {
			local.foreignKeys = $dbinfo(
				type = "foreignkeys",
				table = arguments.table,
				datasource = application[local.appKey].dataSourceName,
				username = application[local.appKey].dataSourceUserName,
				password = application[local.appKey].dataSourcePassword
			);
			local.foreignKeyList = ValueList(local.foreignKeys.FKCOLUMN_NAME);
		}
		return local.foreignKeyList;
	}

	private void function $execute(required any sql, string dataSource = "") {
		// Adapters may return an array of statements for multi-step DDL
		// (notably SQLite's recreate-table pattern for changeColumnInTable).
		if (IsArray(arguments.sql)) {
			for (local.stmt in arguments.sql) {
				if (Len(Trim(local.stmt))) {
					$execute(sql = local.stmt, dataSource = arguments.dataSource);
				}
			}
			return;
		}
		local.appKey = $appKey();
		local.dsName = Len(arguments.dataSource) ? arguments.dataSource : application[local.appKey].dataSourceName;
		// Executed statements may change the schema — drop the request-scoped
		// column cache so the next $getColumns() re-probes.
		StructDelete(request, "$wheelsMigratorColumns");
		local.prepared = $prepareMigrationSql(sql = arguments.sql, dsName = local.dsName);
		if (!local.prepared.captured) {
			$query(datasource = local.dsName, sql = local.prepared.sql);
		}
	}

	/**
	 * Executes a parameterized SQL statement for safe data operations.
	 */
	private void function $executeWithParams(required string sql, required array params, string dataSource = "") {
		local.appKey = $appKey();
		local.dsName = Len(arguments.dataSource) ? arguments.dataSource : application[local.appKey].dataSourceName;
		local.prepared = $prepareMigrationSql(sql = arguments.sql, dsName = local.dsName);
		if (!local.prepared.captured) {
			queryExecute(local.prepared.sql, arguments.params, {datasource: local.dsName});
		}
	}

	/**
	 * Shared pre-execution pipeline for $execute()/$executeWithParams(): trims
	 * the statement, appends the ";" terminator (except on Oracle — resolved
	 * via the memoized $getDBType() rather than a per-statement $dbinfo
	 * round-trip), appends to the migration SQL file when enabled, and captures
	 * the statement on request.$wheelsDebugSQLResult in dry-run mode.
	 * Returns {sql, captured}; captured=true means the caller must not execute
	 * the statement.
	 */
	private struct function $prepareMigrationSql(required string sql, required string dsName) {
		local.appKey = $appKey();
		local.sql = Trim(arguments.sql);
		if (Right(local.sql, 1) neq ";" && $getDBType(arguments.dsName) != "Oracle") {
			local.sql &= ";";
		}
		if (StructKeyExists(request, "$wheelsMigrationSQLFile") && application[local.appKey].writeMigratorSQLFiles) {
			$file(
				action = "append",
				file = request.$wheelsMigrationSQLFile,
				output = "#local.sql#",
				addNewLine = "yes",
				fixNewLine = "yes"
			);
		}
		local.captured = StructKeyExists(request, "$wheelsDebugSQL") && request.$wheelsDebugSQL;
		if (local.captured) {
			if (!StructKeyExists(request, "$wheelsDebugSQLResult")) {
				request.$wheelsDebugSQLResult = [];
			}
			ArrayAppend(request.$wheelsDebugSQLResult, local.sql);
		}
		return {sql: local.sql, captured: local.captured};
	}

	public string function $getColumns(required string tableName) {
		local.appKey = $appKey();
		// Request-scoped cache: addRecord()/updateRecord() consult the column
		// list for every inserted/updated row, so a multi-row seed migration
		// would otherwise issue a full table-metadata round-trip per row.
		// $execute() drops the cache whenever a statement runs, so DDL in the
		// same request (addColumn() etc.) is reflected on the next read.
		local.cacheKey = LCase(application[local.appKey].dataSourceName & "|" & arguments.tableName);
		if (
			StructKeyExists(request, "$wheelsMigratorColumns")
			&& StructKeyExists(request.$wheelsMigratorColumns, local.cacheKey)
		) {
			return request.$wheelsMigratorColumns[local.cacheKey];
		}
		local.columns = $dbinfo(
			datasource = application[local.appKey].dataSourceName,
			username = application[local.appKey].dataSourceUserName,
			password = application[local.appKey].dataSourcePassword,
			type = "columns",
			table = arguments.tableName
		);
		local.columnList = ValueList(local.columns.COLUMN_NAME);
		if (!StructKeyExists(request, "$wheelsMigratorColumns")) {
			request.$wheelsMigratorColumns = {};
		}
		request.$wheelsMigratorColumns[local.cacheKey] = local.columnList;
		return local.columnList;
	}

	/**
	 * Helper function to get column default value with BoxLang compatibility
	 * Different CFML engines return different column names for default values
	 */
	private string function $getColumnDefaultValue(required query columns, required numeric index) {
		local.rv = "";
		// Try different column names used by different CFML engines
		if (ListFindNoCase(arguments.columns.columnList, "COLUMN_DEFAULT_VALUE")) {
			local.rv = arguments.columns["COLUMN_DEFAULT_VALUE"][arguments.index];
		} else if (ListFindNoCase(arguments.columns.columnList, "column_default")) {
			local.rv = arguments.columns["column_default"][arguments.index];
		} else if (ListFindNoCase(arguments.columns.columnList, "default_value")) {
			local.rv = arguments.columns["default_value"][arguments.index];
		} else if (ListFindNoCase(arguments.columns.columnList, "COLUMN_DEF")) {
			// Standard JDBC column name used by BoxLang
			local.rv = arguments.columns["COLUMN_DEF"][arguments.index];
		}
		if (IsArray(local.rv)) {
			if (ArrayLen(local.rv) > 0) {
				local.rv = local.rv[1];
			} else {
				local.rv = "";
			}
		}
		if (!IsSimpleValue(local.rv)) {
			local.rv = "";
		}
		return local.rv;
	}

	private string function $getColumnDefinition(required string tableName, required string columnName) {
		local.appKey = $appKey();
		local.columns = $dbinfo(
			datasource = application[local.appKey].dataSourceName,
			username = application[local.appKey].dataSourceUserName,
			password = application[local.appKey].dataSourcePassword,
			type = "columns",
			table = arguments.tableName
		);
		local.columnDefinition = "";
		local.iEnd = local.columns.RecordCount;
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			if (local.columns["COLUMN_NAME"][local.i] == arguments.columnName) {
				local.columnType = local.columns["TYPE_NAME"][local.i];
				local.columnDefinition = local.columnType;
				if (ListFindNoCase("char,varchar,int,bigint,smallint,tinyint,binary,varbinary", local.columnType)) {
					local.columnDefinition = local.columnDefinition & "(#local.columns["COLUMN_SIZE"][local.i]#)";
				} else if (ListFindNoCase("decimal,float,double", local.columnType)) {
					local.columnDefinition = local.columnDefinition & "(#local.columns["COLUMN_SIZE"][local.i]#,#local.columns["DECIMAL_DIGITS"][local.i]#)";
				}
				if (local.columns["IS_NULLABLE"][local.i]) {
					local.columnDefinition = local.columnDefinition & " NULL";
				} else {
					local.columnDefinition = local.columnDefinition & " NOT NULL";
				}
				
				// Get column default value with CFML engine compatibility
				local.defaultValue = $getColumnDefaultValue(local.columns, local.i);
				
				if (Len(local.defaultValue) == 0) {
					local.columnDefinition = local.columnDefinition & " DEFAULT NULL";
				} else if (ListFindNoCase("char,varchar,binary,varbinary", local.columnType)) {
					local.columnDefinition = local.columnDefinition & " DEFAULT '#local.defaultValue#'";
				} else if (ListFindNoCase("int,bigint,smallint,tinyint,decimal,float,double", local.columnType)) {
					local.columnDefinition = local.columnDefinition & " DEFAULT #local.defaultValue#";
				}
				break;
			}
		}
		return local.columnDefinition;
	}

	/**
	 * Applies case to database objects according to settings
	 * Note: some db engines use only lower case, TODO: perhaps add certain adapters to these conditions?
	 */
	private string function objectCase(required string name) {
		local.appKey = $appKey();
		if (application[local.appKey].migratorObjectCase eq "lower") {
			return LCase(arguments.name);
		} else if (application[local.appKey].migratorObjectCase eq "upper") {
			return UCase(arguments.name);
		} else {
			// use the object name unmolested
			return arguments.name;
		}
	}

}
