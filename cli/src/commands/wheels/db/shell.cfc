/**
 * Launch interactive database shell
 *
 * {code:bash}
 * wheels db shell
 * wheels db shell web=true
 * wheels db shell datasource=myapp_dev
 * {code}
 */
component extends="../base" {

	/**
	 * @datasource Optional datasource name (defaults to current datasource setting)
	 * @environment Optional environment (defaults to current environment)
	 * @web Launch web-based console instead of CLI (H2 only)
	 * @command Custom command to execute in shell
	 * @help Launch interactive database shell
	 */
	public void function run(
		string datasource = "",
		string environment = "",
		boolean web = false,
		string command = ""
	) {
		local.appPath = getCWD();
		
		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		try {
			// Determine environment
			if (!Len(arguments.environment)) {
				arguments.environment = getEnvironment(local.appPath);
			}
			
			// Get datasource name if not provided
			if (!Len(arguments.datasource)) {
				arguments.datasource = getDataSourceName(local.appPath, arguments.environment);
			}
			
			if (!Len(arguments.datasource)) {
				error("No datasource configured. Use datasource= parameter or set dataSourceName in settings.");
				return;
			}
			
			print.line();
			print.boldCyanLine("Database Shell");
			print.line("Datasource: " & arguments.datasource);
			print.line("Environment: " & arguments.environment);
			print.line();
			
			// Get datasource configuration
			local.dsInfo = getDatasourceInfo(arguments.datasource, arguments.environment);
			
			if (StructIsEmpty(local.dsInfo)) {
				// Try to get from Wheels configuration
				local.dsInfo = getWheelsDatasourceInfo(local.appPath, arguments.datasource, arguments.environment);
			}
			
			if (StructIsEmpty(local.dsInfo)) {
				error("Unable to retrieve datasource configuration for '" & arguments.datasource & "'");
				return;
			}
			
			// Launch shell based on database type
			local.dbType = local.dsInfo.driver ?: detectDatabaseType(local.dsInfo);
			
			print.line("Database Type: " & local.dbType);
			print.line();
			
			switch (local.dbType) {
				case "H2":
					launchH2Shell(local.dsInfo, arguments.web, arguments.command);
					break;
				case "MySQL":
				case "MySQL5":
					launchMySQLShell(local.dsInfo, arguments.command);
					break;
				case "PostgreSQL":
					launchPostgreSQLShell(local.dsInfo, arguments.command);
					break;
				case "MSSQLServer":
				case "MSSQL":
					launchSQLServerShell(local.dsInfo, arguments.command);
					break;
				default:
					error("Database shell not supported for driver: " & local.dbType);
					print.line("Supported databases: H2, MySQL, PostgreSQL, SQL Server");
			}
			
		} catch (any e) {
			error("Error launching database shell: " & e.message);
			if (StructKeyExists(e, "detail") && Len(e.detail)) {
				error("Details: " & e.detail);
			}
		}
	}

	private void function launchH2Shell(required struct dsInfo, required boolean web, required string command) {
		if (arguments.web) {
			// Launch H2 Web Console
			print.line("Launching H2 Web Console...");
			
			try {
				// Try to create and start H2 Console
				local.h2Console = CreateObject("java", "org.h2.tools.Console");
				
				// Build arguments for console
				local.args = ["-web", "-browser"];
				
				// Add connection URL if available
				if (StructKeyExists(arguments.dsInfo, "url")) {
					ArrayAppend(local.args, "-url");
					ArrayAppend(local.args, arguments.dsInfo.url);
				} else if (StructKeyExists(arguments.dsInfo, "database")) {
					local.url = "jdbc:h2:" & arguments.dsInfo.database;
					ArrayAppend(local.args, "-url");
					ArrayAppend(local.args, local.url);
				}
				
				// Add user if available
				if (StructKeyExists(arguments.dsInfo, "username") && Len(arguments.dsInfo.username)) {
					ArrayAppend(local.args, "-user");
					ArrayAppend(local.args, arguments.dsInfo.username);
				}
				
				print.line("Starting H2 Console with parameters:");
				print.line("URL: " & (local.url ?: arguments.dsInfo.url ?: "default"));
				print.line();
				print.yellowLine("The H2 Console will open in your browser.");
				print.yellowLine("Press Ctrl+C to stop the console when done.");
				print.line();
				
				// Start console (this will block until closed)
				local.h2Console.main(local.args);
				
			} catch (any e) {
				// Fallback: try to find H2 JAR and launch via command line
				local.h2Jar = findH2Jar();
				if (Len(local.h2Jar)) {
					print.line("Using H2 JAR: " & GetFileFromPath(local.h2Jar));

					// Build command as array to avoid shell injection
					if (FindNoCase("org.lucee.h2", local.h2Jar)) {
						local.cmdArray = ["java", "-jar", local.h2Jar];
					} else {
						local.cmdArray = ["java", "-cp", local.h2Jar, "org.h2.tools.Console"];
					}

					ArrayAppend(local.cmdArray, "-web");
					ArrayAppend(local.cmdArray, "-browser");

					if (StructKeyExists(arguments.dsInfo, "url")) {
						ArrayAppend(local.cmdArray, "-url");
						ArrayAppend(local.cmdArray, arguments.dsInfo.url);
					} else if (StructKeyExists(arguments.dsInfo, "database")) {
						ArrayAppend(local.cmdArray, "-url");
						ArrayAppend(local.cmdArray, "jdbc:h2:" & arguments.dsInfo.database);
					}

					if (StructKeyExists(arguments.dsInfo, "username") && Len(arguments.dsInfo.username)) {
						ArrayAppend(local.cmdArray, "-user");
						ArrayAppend(local.cmdArray, arguments.dsInfo.username);
					}

					print.line("Launching H2 Console via command line...");
					print.line();
					print.yellowLine("The H2 Console will open in your browser.");
					print.yellowLine("Press Ctrl+C to stop the console when done.");

					$runInteractiveCommand(local.cmdArray);
				} else {
					error("H2 JAR not found. Make sure H2 database is installed.");
					print.line("H2 is typically included with Lucee as org.lucee.h2-*.jar");
				}
			}
		} else {
			// Launch H2 Shell (CLI)
			print.line("Launching H2 Shell...");
			
			try {
				// Build JDBC URL
				local.url = "";
				if (StructKeyExists(arguments.dsInfo, "url")) {
					local.url = arguments.dsInfo.url;
				} else if (StructKeyExists(arguments.dsInfo, "database")) {
					local.url = "jdbc:h2:" & arguments.dsInfo.database;
				}
				
				// Try to use H2 Shell class
				local.h2Shell = CreateObject("java", "org.h2.tools.Shell");
				
				local.args = [];
				if (Len(local.url)) {
					ArrayAppend(local.args, "-url");
					ArrayAppend(local.args, local.url);
				}
				if (StructKeyExists(arguments.dsInfo, "username") && Len(arguments.dsInfo.username)) {
					ArrayAppend(local.args, "-user");
					ArrayAppend(local.args, arguments.dsInfo.username);
				}
				if (StructKeyExists(arguments.dsInfo, "password") && Len(arguments.dsInfo.password)) {
					ArrayAppend(local.args, "-password");
					ArrayAppend(local.args, arguments.dsInfo.password);
				}
				
				if (Len(arguments.command)) {
					ArrayAppend(local.args, "-sql");
					ArrayAppend(local.args, arguments.command);
				}
				
				print.greenLine("Connected to H2 database: " & local.url);
				print.line("Type 'help' for commands, 'exit' to quit");
				print.line();
				
				local.h2Shell.main(local.args);
				
			} catch (any e) {
				// Fallback to command line
				local.h2Jar = findH2Jar();
				if (Len(local.h2Jar)) {
					print.line("Using H2 JAR: " & GetFileFromPath(local.h2Jar));

					// Build command as array to avoid shell injection
					local.cmdArray = ["java", "-cp", local.h2Jar, "org.h2.tools.Shell"];
					if (Len(local.url)) {
						ArrayAppend(local.cmdArray, "-url");
						ArrayAppend(local.cmdArray, local.url);
					}
					if (StructKeyExists(arguments.dsInfo, "username") && Len(arguments.dsInfo.username)) {
						ArrayAppend(local.cmdArray, "-user");
						ArrayAppend(local.cmdArray, arguments.dsInfo.username);
					}
					if (StructKeyExists(arguments.dsInfo, "password") && Len(arguments.dsInfo.password)) {
						ArrayAppend(local.cmdArray, "-password");
						ArrayAppend(local.cmdArray, arguments.dsInfo.password);
					}
					if (Len(arguments.command)) {
						ArrayAppend(local.cmdArray, "-sql");
						ArrayAppend(local.cmdArray, arguments.command);
					}

					print.line("Launching H2 Shell...");
					print.line();
					$runInteractiveCommand(local.cmdArray);
				} else {
					error("H2 JAR not found. Make sure H2 database is installed.");
					print.line("You can also try the web console with: wheels db shell web=true");
				}
			}
		}
	}

	private void function launchMySQLShell(required struct dsInfo, required string command) {
		local.host = arguments.dsInfo.host ?: "localhost";
		local.port = arguments.dsInfo.port ?: "3306";
		local.database = arguments.dsInfo.database ?: "";
		local.username = arguments.dsInfo.username ?: "";
		local.password = arguments.dsInfo.password ?: "";

		// Build mysql command as array to avoid shell injection
		local.cmdArray = ["mysql", "-h", local.host, "-P", local.port];
		if (Len(local.username)) {
			ArrayAppend(local.cmdArray, "-u");
			ArrayAppend(local.cmdArray, local.username);
		}
		if (Len(local.database)) {
			ArrayAppend(local.cmdArray, local.database);
		}

		// Pass password via MYSQL_PWD environment variable instead of command line
		local.envVars = {};
		if (Len(local.password)) {
			local.envVars["MYSQL_PWD"] = local.password;
		}

		if (Len(arguments.command)) {
			ArrayAppend(local.cmdArray, "-e");
			ArrayAppend(local.cmdArray, arguments.command);
			print.line("Executing command: " & arguments.command);
			$runCommand(local.cmdArray, local.envVars);
		} else {
			print.greenLine("Connecting to MySQL database...");
			print.line("Host: " & local.host & ":" & local.port);
			print.line("Database: " & (Len(local.database) ? local.database : "(none selected)"));
			print.line();
			print.line("Type 'help' for MySQL commands, 'exit' to quit");
			print.line();

			$runInteractiveCommand(local.cmdArray, local.envVars);
		}
	}

	private void function launchPostgreSQLShell(required struct dsInfo, required string command) {
		local.host = arguments.dsInfo.host ?: "localhost";
		local.port = arguments.dsInfo.port ?: "5432";
		local.database = arguments.dsInfo.database ?: "postgres";
		local.username = arguments.dsInfo.username ?: "";

		// Build psql command as array to avoid shell injection
		local.cmdArray = ["psql", "-h", local.host, "-p", local.port, "-d", local.database];
		if (Len(local.username)) {
			ArrayAppend(local.cmdArray, "-U");
			ArrayAppend(local.cmdArray, local.username);
		}

		// Pass password via PGPASSWORD environment variable (never on command line)
		local.envVars = {};
		if (StructKeyExists(arguments.dsInfo, "password") && Len(arguments.dsInfo.password)) {
			local.envVars["PGPASSWORD"] = arguments.dsInfo.password;
		}

		if (Len(arguments.command)) {
			ArrayAppend(local.cmdArray, "-c");
			ArrayAppend(local.cmdArray, arguments.command);
			print.line("Executing command: " & arguments.command);
			$runCommand(local.cmdArray, local.envVars);
		} else {
			print.greenLine("Connecting to PostgreSQL database...");
			print.line("Host: " & local.host & ":" & local.port);
			print.line("Database: " & local.database);
			print.line();
			print.line("Type \h for help, \q to quit");
			print.line();

			$runInteractiveCommand(local.cmdArray, local.envVars);
		}
	}

	private void function launchSQLServerShell(required struct dsInfo, required string command) {
		local.host = arguments.dsInfo.host ?: "localhost";
		local.port = arguments.dsInfo.port ?: "1433";
		local.database = arguments.dsInfo.database ?: "master";
		local.username = arguments.dsInfo.username ?: "";
		local.password = arguments.dsInfo.password ?: "";

		local.server = local.host;
		if (local.port != "1433") {
			local.server &= "," & local.port;
		}

		// Build sqlcmd command as array to avoid shell injection
		local.cmdArray = ["sqlcmd", "-S", local.server, "-d", local.database];
		local.envVars = {};

		if (Len(local.username)) {
			ArrayAppend(local.cmdArray, "-U");
			ArrayAppend(local.cmdArray, local.username);
			// Pass password via SQLCMDPASSWORD environment variable instead of command line
			if (Len(local.password)) {
				local.envVars["SQLCMDPASSWORD"] = local.password;
			}
		} else {
			// Use Windows authentication
			ArrayAppend(local.cmdArray, "-E");
		}

		if (Len(arguments.command)) {
			ArrayAppend(local.cmdArray, "-Q");
			ArrayAppend(local.cmdArray, arguments.command);
			print.line("Executing command: " & arguments.command);
			$runCommand(local.cmdArray, local.envVars);
		} else {
			print.greenLine("Connecting to SQL Server database...");
			print.line("Host: " & local.host & ":" & local.port);
			print.line("Database: " & local.database);
			print.line();
			print.line("Type :help for commands, :quit to exit");
			print.line();

			$runInteractiveCommand(local.cmdArray, local.envVars);
		}
	}

	private string function findH2Jar() {
		// Look for H2 JAR in common locations
		local.paths = [
			ExpandPath("/lucee/lib/ext/"),
			ExpandPath("/lucee-server/bundles/"),
			ExpandPath("/lucee-server/context/lib/"),
			ExpandPath("/WEB-INF/lucee/lib/"),
			ExpandPath("/WEB-INF/lib/"),
			ExpandPath("/lib/"),
			ExpandPath("./lib/"),
			// CommandBox/Lucee paths
			ExpandPath("~/.CommandBox/server/*/lucee-*/WEB-INF/lucee/bundles/"),
			ExpandPath("~/.CommandBox/lib/")
		];
		
		// Look for Lucee H2 bundle specifically
		local.patterns = [
			"org.lucee.h2-*.jar",
			"h2-*.jar",
			"*h2*.jar"
		];
		
		for (local.path in local.paths) {
			if (DirectoryExists(local.path)) {
				for (local.pattern in local.patterns) {
					local.files = DirectoryList(local.path, false, "path", local.pattern);
					if (ArrayLen(local.files)) {
						// Prefer Lucee's H2 bundle
						for (local.file in local.files) {
							if (FindNoCase("org.lucee.h2", local.file)) {
								return local.file;
							}
						}
						// Return first match if no Lucee bundle found
						return local.files[1];
					}
				}
			}
		}
		
		return "";
	}

	private struct function getWheelsDatasourceInfo(required string appPath, required string datasource, required string environment) {
		local.info = {};
		
		// Try to get from .env file or environment-specific config
		local.envFile = arguments.appPath & "/.env";
		if (FileExists(local.envFile)) {
			local.envContent = FileRead(local.envFile);
			
			// Look for H2 database path
			local.h2Match = REFind("(?m)^H2_DB_PATH\s*=\s*(.+)$", local.envContent, 1, true);
			if (local.h2Match.pos[1] > 0) {
				local.dbPath = Trim(Mid(local.envContent, local.h2Match.pos[2], local.h2Match.len[2]));
				local.info.database = local.dbPath;
				local.info.driver = "H2";
				local.info.url = "jdbc:h2:" & local.dbPath;
			}
		}
		
		// Check for H2 database files
		if (StructIsEmpty(local.info)) {
			local.h2Paths = [
				arguments.appPath & "/db/h2/" & arguments.datasource,
				arguments.appPath & "/db/" & arguments.datasource,
				arguments.appPath & "/" & arguments.datasource
			];
			
			for (local.path in local.h2Paths) {
				if (FileExists(local.path & ".mv.db") || FileExists(local.path & ".h2.db")) {
					local.info.database = local.path;
					local.info.driver = "H2";
					local.info.url = "jdbc:h2:file:" & local.path;
					break;
				}
			}
		}
		
		return local.info;
	}

	private string function detectDatabaseType(required struct dsInfo) {
		if (StructKeyExists(arguments.dsInfo, "url")) {
			local.url = LCase(arguments.dsInfo.url);
			if (Find("jdbc:h2:", local.url)) return "H2";
			if (Find("jdbc:mysql:", local.url)) return "MySQL";
			if (Find("jdbc:postgresql:", local.url)) return "PostgreSQL";
			if (Find("jdbc:sqlserver:", local.url) || Find("jdbc:jtds:sqlserver:", local.url)) return "MSSQL";
		}
		
		if (StructKeyExists(arguments.dsInfo, "class")) {
			local.class = LCase(arguments.dsInfo.class);
			if (Find("h2", local.class)) return "H2";
			if (Find("mysql", local.class)) return "MySQL";
			if (Find("postgresql", local.class)) return "PostgreSQL";
			if (Find("sqlserver", local.class) || Find("jtds", local.class)) return "MSSQL";
		}
		
		return "Unknown";
	}

	/**
	 * Create a ProcessBuilder from a command array with optional environment variables.
	 * Centralizes array-to-ArrayList conversion and env var injection.
	 */
	private any function $createProcessBuilder(required any commandArgs, struct envVars = {}) {
		if (IsArray(arguments.commandArgs)) {
			local.commandArray = arguments.commandArgs;
		} else {
			local.commandArray = ListToArray(arguments.commandArgs, " ");
		}

		local.javaList = CreateObject("java", "java.util.ArrayList");
		for (local.item in local.commandArray) {
			local.javaList.add(JavaCast("string", local.item));
		}

		local.pb = CreateObject("java", "java.lang.ProcessBuilder").init(local.javaList);

		if (!StructIsEmpty(arguments.envVars)) {
			local.env = local.pb.environment();
			for (local.key in arguments.envVars) {
				local.env.put(local.key, arguments.envVars[local.key]);
			}
		}

		return local.pb;
	}

	/**
	 * Run a command interactively with inherited IO.
	 * Accepts a pre-built array of command arguments to avoid shell injection.
	 */
	private void function $runInteractiveCommand(required any commandArgs, struct envVars = {}) {
		try {
			local.pb = $createProcessBuilder(arguments.commandArgs, arguments.envVars);
			local.pb.inheritIO();

			local.process = local.pb.start();
			local.exitCode = local.process.waitFor();

			if (local.exitCode != 0) {
				print.line();
				print.yellowLine("Database shell exited with code: " & local.exitCode);
			}

		} catch (any e) {
			// Fallback to cfexecute
			try {
				if (IsArray(arguments.commandArgs)) {
					local.exe = arguments.commandArgs[1];
					local.argStr = "";
					if (ArrayLen(arguments.commandArgs) > 1) {
						local.parts = [];
						for (local.i = 2; local.i <= ArrayLen(arguments.commandArgs); local.i++) {
							local.val = arguments.commandArgs[local.i];
							if (Find(" ", local.val)) {
								ArrayAppend(local.parts, '"' & local.val & '"');
							} else {
								ArrayAppend(local.parts, local.val);
							}
						}
						local.argStr = ArrayToList(local.parts, " ");
					}
				} else {
					local.exe = ListFirst(arguments.commandArgs, " ");
					local.argStr = ListRest(arguments.commandArgs, " ");
				}
				cfexecute(
					name=local.exe,
					arguments=local.argStr,
					timeout=0
				);
			} catch (any e2) {
				error("Failed to launch database shell. Make sure the database client is installed.");
			}
		}
	}

	/**
	 * Run a command and capture its output.
	 * Accepts a pre-built array of command arguments to avoid shell injection.
	 */
	private void function $runCommand(required any commandArgs, struct envVars = {}) {
		try {
			local.pb = $createProcessBuilder(arguments.commandArgs, arguments.envVars);
			local.pb.redirectErrorStream(true);

			local.process = local.pb.start();

			local.reader = CreateObject("java", "java.io.BufferedReader").init(
				CreateObject("java", "java.io.InputStreamReader").init(local.process.getInputStream())
			);

			local.line = local.reader.readLine();
			while (!IsNull(local.line)) {
				print.line(local.line);
				local.line = local.reader.readLine();
			}

			local.exitCode = local.process.waitFor();

			if (local.exitCode != 0) {
				print.yellowLine("Command exited with code: " & local.exitCode);
			}

		} catch (any e) {
			error("Command execution failed: " & e.message);
		}
	}

	private string function getEnvironment(required string appPath) {
		local.environment = "";
		
		local.envFile = arguments.appPath & "/.env";
		if (FileExists(local.envFile)) {
			local.envContent = FileRead(local.envFile);
			local.envMatch = REFind("(?m)^WHEELS_ENV\s*=\s*(.+)$", local.envContent, 1, true);
			if (local.envMatch.pos[1] > 0) {
				local.environment = Trim(Mid(local.envContent, local.envMatch.pos[2], local.envMatch.len[2]));
			}
		}
		
		if (!Len(local.environment)) {
			local.sysEnv = CreateObject("java", "java.lang.System");
			local.wheelsEnv = local.sysEnv.getenv("WHEELS_ENV");
			if (!IsNull(local.wheelsEnv) && Len(local.wheelsEnv)) {
				local.environment = local.wheelsEnv;
			}
		}
		
		if (!Len(local.environment)) {
			local.environment = "development";
		}
		
		return local.environment;
	}

	private string function getDataSourceName(required string appPath, required string environment) {
		local.envSettingsFile = arguments.appPath & "/config/" & arguments.environment & "/settings.cfm";
		if (FileExists(local.envSettingsFile)) {
			local.dsName = extractDataSourceName(FileRead(local.envSettingsFile));
			if (Len(local.dsName)) return local.dsName;
		}
		
		local.settingsFile = arguments.appPath & "/config/settings.cfm";
		if (FileExists(local.settingsFile)) {
			local.dsName = extractDataSourceName(FileRead(local.settingsFile));
			if (Len(local.dsName)) return local.dsName;
		}
		
		return "";
	}

	private string function extractDataSourceName(required string content) {
		// Step 1: Remove multi-line block comments: /* ... */
		local.cleaned = REReplace(arguments.content, "/\*[\s\S]*?\*/", "", "all");

		// Step 2: Remove single-line comments: // ... until end of line
		local.cleaned = REReplace(local.cleaned, "//.*", "", "all");

		// Step 3: Match set(dataSourceName="...")
		local.pattern = "set\s*\(\s*dataSourceName\s*=\s*[""']([^""']+)[""']";
		local.match = REFind(local.pattern, local.cleaned, 1, true);

		if (arrayLen(local.match.pos) >= 2 && local.match.pos[2] > 0) {
			return Mid(local.cleaned, local.match.pos[2], local.match.len[2]);
		}
		return "";
	}

}