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
		request.$wheelsMigrationOutput = request.$wheelsMigrationOutput & arguments.message & Chr(13);
	}

	public string function $getDBType() {
		local.appKey = $appKey();
		local.info = $dbinfo(
			type = "version",
			datasource = application[local.appKey].dataSourceName,
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
		} else if (local.info.driver_name Contains "PostgreSQL") {
			local.adapterName = "PostgreSQL";
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
		}
		return local.adapterName;
	}

	private string function $getForeignKeys(required string table) {
		local.appKey = $appKey();
		local.foreignKeyList = "";
		local.tables = $dbinfo(
			type = "tables",
			datasource = application[local.appKey].dataSourceName,
			username = application[local.appKey].dataSourceUserName,
			password = application[local.appKey].dataSourcePassword
		);
		if (ListFindNoCase(ValueList(local.tables.table_name), arguments.table)) {
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

	private void function $execute(required string sql) {
		local.appKey = $appKey();
		local.sql = Trim(arguments.sql);
		if (Right(local.sql, 1) neq ";") {
			local.sql = local.sql &= ";";
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
		if (StructKeyExists(request, "$wheelsDebugSQL") && request.$wheelsDebugSQL) {
			if (!StructKeyExists(request, "$wheelsDebugSQLResult")) {
				request.$wheelsDebugSQLResult = [];
			}
			ArrayAppend(request.$wheelsDebugSQLResult, local.sql);
		} else {
			$query(datasource = application[local.appKey].dataSourceName, sql = local.sql);
		}
	}

	public string function $getColumns(required string tableName) {
		local.appKey = $appKey();
		local.columns = $dbinfo(
			datasource = application[local.appKey].dataSourceName,
			username = application[local.appKey].dataSourceUserName,
			password = application[local.appKey].dataSourcePassword,
			type = "columns",
			table = arguments.tableName
		);
		return ValueList(local.columns.COLUMN_NAME);
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
				if (Len(local.columns["COLUMN_DEFAULT_VALUE"][local.i]) == 0) {
					local.columnDefinition = local.columnDefinition & " DEFAULT NULL";
				} else if (ListFindNoCase("char,varchar,binary,varbinary", local.columnType)) {
					local.columnDefinition = local.columnDefinition & " DEFAULT '#local.columns["COLUMN_DEFAULT_VALUE"][local.i]#'";
				} else if (ListFindNoCase("int,bigint,smallint,tinyint,decimal,float,double", local.columnType)) {
					local.columnDefinition = local.columnDefinition & " DEFAULT #local.columns["COLUMN_DEFAULT_VALUE"][local.i]#";
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
