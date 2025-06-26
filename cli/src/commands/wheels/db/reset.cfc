/**
 * Reset database (drop + create + migrate + seed)
 *
 * {code:bash}
 * wheels db reset
 * wheels db reset force=true
 * wheels db reset skipSeed=true
 * {code}
 */
component extends="../base" {

	/**
	 * @datasource Optional datasource name (defaults to current datasource setting)
	 * @environment Optional environment (defaults to current environment)
	 * @force Skip confirmation prompt
	 * @skipSeed Skip the database seeding step
	 * @seedCount Number of records to generate per model when seeding
	 * @help Reset database by dropping, recreating, migrating, and seeding
	 */
	public void function run(
		string datasource = "",
		string environment = "",
		boolean force = false,
		boolean skipSeed = false,
		numeric seedCount = 5
	) {
		local.appPath = getCWD();
		
		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		print.line();
		print.boldRedLine("⚠️  Database Reset Warning");
		print.line("This will completely destroy and rebuild your database!");
		print.line("All existing data will be permanently lost.");
		print.line();
		
		// Determine environment
		if (!Len(arguments.environment)) {
			arguments.environment = getEnvironment(local.appPath);
		}
		
		print.line("Environment: " & arguments.environment);
		
		// Confirm unless forced
		if (!arguments.force) {
			if (arguments.environment == "production") {
				print.line();
				print.boldRedLine("🚨 PRODUCTION ENVIRONMENT DETECTED! 🚨");
				print.line("Are you ABSOLUTELY sure you want to reset the PRODUCTION database?");
				local.confirm = ask("Type 'reset production database' to confirm: ");
				if (local.confirm != "reset production database") {
					print.yellowLine("Database reset cancelled.");
					return;
				}
			} else {
				local.confirm = ask("Are you sure you want to reset the database? Type 'yes' to confirm: ");
				if (local.confirm != "yes") {
					print.yellowLine("Database reset cancelled.");
					return;
				}
			}
		}
		
		print.line();
		
		try {
			// Step 1: Drop database
			print.boldLine("Step 1/4: Dropping existing database...");
			command("wheels db drop")
				.params(datasource=arguments.datasource, environment=arguments.environment, force=true)
				.run();
			print.line();
			
			// Step 2: Create database
			print.boldLine("Step 2/4: Creating new database...");
			command("wheels db create")
				.params(datasource=arguments.datasource, environment=arguments.environment)
				.run();
			print.line();
			
			// Step 3: Run migrations
			print.boldLine("Step 3/4: Running migrations...");
			command("wheels dbmigrate latest")
				.run();
			print.line();
			
			// Step 4: Seed database (unless skipped)
			if (!arguments.skipSeed) {
				print.boldLine("Step 4/4: Seeding database...");
				command("wheels db seed")
					.params(count=arguments.seedCount)
					.run();
			} else {
				print.yellowLine("Step 4/4: Skipping database seeding (skipSeed=true flag used)");
			}
			
			print.line();
			print.boldGreenLine("✓ Database reset completed successfully!");
			print.line();
			
			// Show final status
			print.line("Running 'wheels db status' to show current state:");
			command("wheels db status")
				.run();
			
		} catch (any e) {
			print.line();
			error("Database reset failed: " & e.message);
			if (StructKeyExists(e, "detail") && Len(e.detail)) {
				error("Details: " & e.detail);
			}
			print.line();
			print.yellowLine("The database may be in an inconsistent state.");
			print.yellowLine("You may need to manually fix the issue and run the remaining steps:");
			print.line("  1. wheels db drop --force");
			print.line("  2. wheels db create");
			print.line("  3. wheels dbmigrate latest");
			if (!arguments.skipSeed) {
				print.line("  4. wheels db seed");
			}
		}
	}

	private string function getEnvironment(required string appPath) {
		// Same logic as get environment command
		local.environment = "";
		
		// Check .env file
		local.envFile = arguments.appPath & "/.env";
		if (FileExists(local.envFile)) {
			local.envContent = FileRead(local.envFile);
			local.envMatch = REFind("(?m)^WHEELS_ENV\s*=\s*(.+)$", local.envContent, 1, true);
			if (local.envMatch.pos[1] > 0) {
				local.environment = Trim(Mid(local.envContent, local.envMatch.pos[2], local.envMatch.len[2]));
			}
		}
		
		// Check environment variable
		if (!Len(local.environment)) {
			local.sysEnv = CreateObject("java", "java.lang.System");
			local.wheelsEnv = local.sysEnv.getenv("WHEELS_ENV");
			if (!IsNull(local.wheelsEnv) && Len(local.wheelsEnv)) {
				local.environment = local.wheelsEnv;
			}
		}
		
		// Default to development
		if (!Len(local.environment)) {
			local.environment = "development";
		}
		
		return local.environment;
	}

}