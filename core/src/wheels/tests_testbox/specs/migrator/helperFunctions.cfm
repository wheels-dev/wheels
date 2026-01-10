<cfscript>

	public void function deleteMigratorVersions(required numeric levelId) {
		queryExecute(
			"DELETE FROM c_o_r_e_migrator_versions WHERE core_level = :levelId",
			{
				levelId = {
					value      = arguments.levelId,
					cfsqltype  = "cf_sql_integer"
				}
        	},
			{ datasource = application.wheels.dataSourceName }
		);
	}

	public any function $cleanSqlDirectory() {
		local.path = migrator.paths.sql;
		if (DirectoryExists(local.path)) {
			DirectoryDelete(local.path, true);
		}
	}

	// helper functions
	private boolean function isDbCompatibleFor_SQLServer() {
		switch (migration.adapter.adapterName()) {
			case "MicrosoftSQLServer":
				return true
			default:
				return false
		}
	}

	private boolean function isDbCompatibleFor_H2_MySQL() {
		switch (migration.adapter.adapterName()) {
			case "H2":
			case "MySQL":
				return true
			default:
				return false
		}
	}

	private boolean function isDbCompatible() {
		switch (migration.adapter.adapterName()) {
			case "H2":
			case "MicrosoftSQLServer":
			case "MySQL":
			case "PostgreSQL":
			case "SQLite":
				return true;
			default:
				return false;
		}
	}

	private string function getBigIntegerType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
				return "BIGINT"
			case "MySQL":
				return "BIGINT UNSIGNED"
			default:
				return "`addbiginteger()` not supported for " & migration.adapter.adapterName()
		}
	}

	private array function getBinaryType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
				return ["BINARY LARGE OBJECT", "blob"];
			case "MySQL":
				return ["BLOB"];
			case "MicrosoftSQLServer":
				return ["IMAGE"];
			case "PostgreSQL":
				return ["BYTEA"];
			case "SQLite":
				return ["BLOB"];
			default:
				return "`addbinary()` not supported for " & migration.adapter.adapterName();
		}
	}

	private string function getBooleanType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
				return "TINYINT";
			case "MicrosoftSQLServer":
				return "BIT";
			case "MySQL":
				return "BIT,TINYINT";
			case "PostgreSQL":
				return "BOOLEAN";
			case "SQLite":
				return "INTEGER";
			default:
				return "`addboolean()` not supported for " & migration.adapter.adapterName();
		}
	}

	private string function getCharType() {
		switch (migration.adapter.adapterName()) {
			case "MicrosoftSQLServer":
				return "CHAR";
			default:
				return "`addchar()` not supported for " & migration.adapter.adapterName();
		}
	}

	private string function getDateType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
			case "MySQL":
			case "PostgreSQL":
				return "DATE";
			case "MicrosoftSQLServer":
				return "date";
			case "SQLite":
				return "TEXT";
			default:
				return "`adddate()` not supported for " & migration.adapter.adapterName();
		}
	}

	private string function getDatetimeType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
				return "TIMESTAMP";
			case "MicrosoftSQLServer":
			case "MySQL":
				return "DATETIME";
			case "PostgreSQL":
				return "TIMESTAMP";
			case "SQLite":
				return "TEXT";
			default:
				return "`adddatetime()` not supported for " & migration.adapter.adapterName();
		}
	}

	private string function getDecimalType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
			case "MicrosoftSQLServer":
			case "MySQL":
				return "DECIMAL";
			case "PostgreSQL":
				return "NUMERIC";
			case "SQLite":
				return "REAL";
			default:
				return "`adddecimal()` not supported for " & migration.adapter.adapterName();
		}
	}

	private string function getFloatType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
				return "DOUBLE,DOUBLE PRECISION";
			case "MicrosoftSQLServer":
			case "MySQL":
			case "PostgreSQL":
				return "FLOAT,float8"; // depends on db engine/drivers
			case "SQLite":
				return "REAL";
			default:
				return "`addfloat()` not supported for " & migration.adapter.adapterName();
		}
	}

	private string function getIntegerType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
			case "SQLite":
				return "INTEGER";
			case "MicrosoftSQLServer":
			case "MySQL":
				return "INT";
			case "PostgreSQL":
				return "INTEGER,INT4"; // depends on db engine/drivers
			default:
				return "`addinteger()` not supported for " & migration.adapter.adapterName();
		}
	}

	private array function getStringType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
			case "MicrosoftSQLServer":
			case "MySQL":
			case "PostgreSQL":
				return ["VARCHAR", "CHARACTER VARYING"];
			case "SQLite":
				return ["TEXT"];
			default:
				return "`addstring()` not supported for " & migration.adapter.adapterName();
		}
	}

	private array function getTextType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
				return ["CLOB", "CHARACTER LARGE OBJECT"];
			case "MySQL":
			case "PostgreSQL":
				return ["TEXT"];
			case "MicrosoftSQLServer":
				return ["NVARCHAR", "NVARCHAR(MAX)"];
			case "SQLite":
				return ["TEXT"];
			default:
				return "`addtext()` not supported for " & migration.adapter.adapterName();
		}
	}

	private string function getTimeType() {
		switch (migration.adapter.adapterName()) {
			case "MicrosoftSQLServer":
				return "time";
			case "MySQL":
			case "H2":
			case "PostgreSQL":
				return "TIME";
			case "SQLite":
				return "TEXT";
			default:
				return "`addtime()` not supported for " & migration.adapter.adapterName();
		}
	}

	private string function getTimestampType() {
		switch (migration.adapter.adapterName()) {
			case "MicrosoftSQLServer":
				return "DATETIME";
			case "H2":
				return "TIMESTAMP";
			case "MySQL":
				return "DATETIME";
			case "PostgreSQL":
				return "TIMESTAMP";
			case "SQLite":
				return "TEXT";
			default:
				return "`addtimestamp()` not supported for " & migration.adapter.adapterName();
		}
	}

	private string function getUniqueIdentifierType() {
		switch (migration.adapter.adapterName()) {
			case "MicrosoftSQLServer":
				return "UNIQUEIDENTIFIER";
			default:
				return "`adduniqueidentifier()` not supported for " & migration.adapter.adapterName();
		}
	}
</cfscript>