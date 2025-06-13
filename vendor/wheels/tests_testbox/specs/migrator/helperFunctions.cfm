<cfscript>

	public void function deleteMigratorVersions(required numeric levelId) {
		queryExecute(
			"DELETE FROM migratorversions WHERE level_id = :levelId",
			{ levelId = arguments.levelId },
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

	private string function getBinaryType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
			case "MySQL":
				return "BLOB";
			case "MicrosoftSQLServer":
				return "IMAGE";
			case "PostgreSQL":
				return "BYTEA";
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
			default:
				return "`adddecimal()` not supported for " & migration.adapter.adapterName();
		}
	}

	private string function getFloatType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
				return "DOUBLE";
			case "MicrosoftSQLServer":
			case "MySQL":
			case "PostgreSQL":
				return "FLOAT,float8"; // depends on db engine/drivers
			default:
				return "`addfloat()` not supported for " & migration.adapter.adapterName();
		}
	}

	private string function getIntegerType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
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

	private string function getStringType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
			case "MicrosoftSQLServer":
			case "MySQL":
			case "PostgreSQL":
				return "VARCHAR";
			default:
				return "`addstring()` not supported for " & migration.adapter.adapterName();
		}
	}

	private array function getTextType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
				return ["CLOB"];
			case "MySQL":
			case "PostgreSQL":
				return ["TEXT"];
			case "MicrosoftSQLServer":
				return ["NVARCHAR", "NVARCHAR(MAX)"];
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