component {
	
	/**
	 * Get database shell command for different database types
	 */
	public struct function getShellCommand(required string databaseType, required struct connectionInfo) {
		local.result = {
			success = false,
			command = "",
			message = "",
			requiresPassword = true
		};
		
		switch(arguments.databaseType) {
			case "MySQL":
			case "MariaDB":
				local.result.command = "mysql";
				if (structKeyExists(arguments.connectionInfo, "host")) {
					local.result.command &= " -h " & arguments.connectionInfo.host;
				}
				if (structKeyExists(arguments.connectionInfo, "port")) {
					local.result.command &= " -P " & arguments.connectionInfo.port;
				}
				if (structKeyExists(arguments.connectionInfo, "username")) {
					local.result.command &= " -u " & arguments.connectionInfo.username;
				}
				if (structKeyExists(arguments.connectionInfo, "database")) {
					local.result.command &= " " & arguments.connectionInfo.database;
				}
				local.result.command &= " -p";
				local.result.success = true;
				break;
				
			case "PostgreSQL":
				local.result.command = "psql";
				if (structKeyExists(arguments.connectionInfo, "host")) {
					local.result.command &= " -h " & arguments.connectionInfo.host;
				}
				if (structKeyExists(arguments.connectionInfo, "port")) {
					local.result.command &= " -p " & arguments.connectionInfo.port;
				}
				if (structKeyExists(arguments.connectionInfo, "username")) {
					local.result.command &= " -U " & arguments.connectionInfo.username;
				}
				if (structKeyExists(arguments.connectionInfo, "database")) {
					local.result.command &= " -d " & arguments.connectionInfo.database;
				}
				local.result.success = true;
				break;
				
			case "SQLServer":
			case "MSSQL":
				local.result.command = "sqlcmd";
				if (structKeyExists(arguments.connectionInfo, "host")) {
					local.server = arguments.connectionInfo.host;
					if (structKeyExists(arguments.connectionInfo, "port")) {
						local.server &= "," & arguments.connectionInfo.port;
					}
					local.result.command &= " -S " & local.server;
				}
				if (structKeyExists(arguments.connectionInfo, "username")) {
					local.result.command &= " -U " & arguments.connectionInfo.username;
				}
				if (structKeyExists(arguments.connectionInfo, "database")) {
					local.result.command &= " -d " & arguments.connectionInfo.database;
				}
				local.result.success = true;
				break;
				
			case "H2":
				// For H2, we can provide both shell and web options
				local.result.command = "java -cp /path/to/h2*.jar org.h2.tools.Shell";
				local.result.webConsole = "http://localhost:8082/"; // Default H2 console port
				local.result.message = "H2 can be accessed via web console or command line shell";
				local.result.requiresPassword = false;
				local.result.success = true;
				break;
				
			default:
				local.result.message = "Unsupported database type: " & arguments.databaseType;
		}
		
		return local.result;
	}
	
	/**
	 * Get dump command for different database types
	 */
	public struct function getDumpCommand(required string databaseType, required struct connectionInfo, string outputFile = "backup.sql") {
		local.result = {
			success = false,
			command = "",
			message = ""
		};
		
		switch(arguments.databaseType) {
			case "MySQL":
			case "MariaDB":
				local.result.command = "mysqldump";
				if (structKeyExists(arguments.connectionInfo, "host")) {
					local.result.command &= " -h " & arguments.connectionInfo.host;
				}
				if (structKeyExists(arguments.connectionInfo, "port")) {
					local.result.command &= " -P " & arguments.connectionInfo.port;
				}
				if (structKeyExists(arguments.connectionInfo, "username")) {
					local.result.command &= " -u " & arguments.connectionInfo.username;
				}
				local.result.command &= " -p";
				if (structKeyExists(arguments.connectionInfo, "database")) {
					local.result.command &= " " & arguments.connectionInfo.database;
				}
				local.result.command &= " > " & arguments.outputFile;
				local.result.success = true;
				break;
				
			case "PostgreSQL":
				local.result.command = "pg_dump";
				if (structKeyExists(arguments.connectionInfo, "host")) {
					local.result.command &= " -h " & arguments.connectionInfo.host;
				}
				if (structKeyExists(arguments.connectionInfo, "port")) {
					local.result.command &= " -p " & arguments.connectionInfo.port;
				}
				if (structKeyExists(arguments.connectionInfo, "username")) {
					local.result.command &= " -U " & arguments.connectionInfo.username;
				}
				if (structKeyExists(arguments.connectionInfo, "database")) {
					local.result.command &= " " & arguments.connectionInfo.database;
				}
				local.result.command &= " > " & arguments.outputFile;
				local.result.success = true;
				break;
				
			case "SQLServer":
			case "MSSQL":
				local.result.command = "sqlcmd";
				if (structKeyExists(arguments.connectionInfo, "host")) {
					local.server = arguments.connectionInfo.host;
					if (structKeyExists(arguments.connectionInfo, "port")) {
						local.server &= "," & arguments.connectionInfo.port;
					}
					local.result.command &= " -S " & local.server;
				}
				if (structKeyExists(arguments.connectionInfo, "username")) {
					local.result.command &= " -U " & arguments.connectionInfo.username;
				}
				if (structKeyExists(arguments.connectionInfo, "database")) {
					local.result.command &= " -d " & arguments.connectionInfo.database;
				}
				local.result.command &= " -Q ""BACKUP DATABASE [" & arguments.connectionInfo.database & "] TO DISK='" & arguments.outputFile & "'""";
				local.result.success = true;
				break;
				
			case "H2":
				local.result.command = "SCRIPT TO '" & arguments.outputFile & "'";
				local.result.message = "Execute this command in H2 console or use the dbDump CLI command";
				local.result.success = true;
				break;
				
			default:
				local.result.message = "Unsupported database type: " & arguments.databaseType;
		}
		
		return local.result;
	}
	
	/**
	 * Get restore command for different database types
	 */
	public struct function getRestoreCommand(required string databaseType, required struct connectionInfo, string inputFile = "backup.sql") {
		local.result = {
			success = false,
			command = "",
			message = ""
		};
		
		switch(arguments.databaseType) {
			case "MySQL":
			case "MariaDB":
				local.result.command = "mysql";
				if (structKeyExists(arguments.connectionInfo, "host")) {
					local.result.command &= " -h " & arguments.connectionInfo.host;
				}
				if (structKeyExists(arguments.connectionInfo, "port")) {
					local.result.command &= " -P " & arguments.connectionInfo.port;
				}
				if (structKeyExists(arguments.connectionInfo, "username")) {
					local.result.command &= " -u " & arguments.connectionInfo.username;
				}
				local.result.command &= " -p";
				if (structKeyExists(arguments.connectionInfo, "database")) {
					local.result.command &= " " & arguments.connectionInfo.database;
				}
				local.result.command &= " < " & arguments.inputFile;
				local.result.success = true;
				break;
				
			case "PostgreSQL":
				local.result.command = "psql";
				if (structKeyExists(arguments.connectionInfo, "host")) {
					local.result.command &= " -h " & arguments.connectionInfo.host;
				}
				if (structKeyExists(arguments.connectionInfo, "port")) {
					local.result.command &= " -p " & arguments.connectionInfo.port;
				}
				if (structKeyExists(arguments.connectionInfo, "username")) {
					local.result.command &= " -U " & arguments.connectionInfo.username;
				}
				if (structKeyExists(arguments.connectionInfo, "database")) {
					local.result.command &= " -d " & arguments.connectionInfo.database;
				}
				local.result.command &= " < " & arguments.inputFile;
				local.result.success = true;
				break;
				
			case "SQLServer":
			case "MSSQL":
				local.result.command = "sqlcmd";
				if (structKeyExists(arguments.connectionInfo, "host")) {
					local.server = arguments.connectionInfo.host;
					if (structKeyExists(arguments.connectionInfo, "port")) {
						local.server &= "," & arguments.connectionInfo.port;
					}
					local.result.command &= " -S " & local.server;
				}
				if (structKeyExists(arguments.connectionInfo, "username")) {
					local.result.command &= " -U " & arguments.connectionInfo.username;
				}
				if (structKeyExists(arguments.connectionInfo, "database")) {
					local.result.command &= " -d " & arguments.connectionInfo.database;
				}
				local.result.command &= " -i " & arguments.inputFile;
				local.result.success = true;
				break;
				
			case "H2":
				local.result.command = "RUNSCRIPT FROM '" & arguments.inputFile & "'";
				local.result.message = "Execute this command in H2 console";
				local.result.success = true;
				break;
				
			default:
				local.result.message = "Unsupported database type: " & arguments.databaseType;
		}
		
		return local.result;
	}
	
}