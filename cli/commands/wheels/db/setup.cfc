/**
 * Setup database (create + migrate + seed)
 *
 * {code:bash}
 * wheels db setup
 * wheels db setup --skip-seed
 * wheels db setup --seed-count=10
 * {code}
 */
component extends="../base" {

	/**
	 * @datasource Optional datasource name (defaults to current datasource setting)
	 * @environment Optional environment (defaults to current environment)
	 * @skipSeed Skip the database seeding step
	 * @seedCount Number of records to generate per model when seeding
	 * @help Setup database by running create, migrate, and seed
	 */
	public void function run(
		string datasource = "",
		string environment = "",
		boolean skipSeed = false,
		numeric seedCount = 5
	) {
		local.appPath = getCWD();
		
		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		print.line();
		print.boldCyanLine("🚀 Wheels Database Setup");
		print.line("This will create the database, run migrations, and seed data.");
		print.line();
		
		try {
			// Step 1: Create database
			print.boldLine("Step 1/3: Creating database...");
			command("wheels db create")
				.params(datasource=arguments.datasource, environment=arguments.environment)
				.run();
			print.line();
			
			// Step 2: Run migrations
			print.boldLine("Step 2/3: Running migrations...");
			command("wheels dbmigrate latest")
				.run();
			print.line();
			
			// Step 3: Seed database (unless skipped)
			if (!arguments.skipSeed) {
				print.boldLine("Step 3/3: Seeding database...");
				command("wheels db seed")
					.params(count=arguments.seedCount)
					.run();
			} else {
				print.yellowLine("Step 3/3: Skipping database seeding (--skip-seed flag used)");
			}
			
			print.line();
			print.boldGreenLine("✓ Database setup completed successfully!");
			print.line();
			
			// Show final status
			print.line("Running 'wheels db status' to show current state:");
			command("wheels db status")
				.run();
			
		} catch (any e) {
			print.line();
			error("Database setup failed: " & e.message);
			if (StructKeyExists(e, "detail") && Len(e.detail)) {
				error("Details: " & e.detail);
			}
			print.line();
			print.yellowLine("You may need to manually fix the issue and run the remaining steps:");
			print.line("  1. wheels db create");
			print.line("  2. wheels dbmigrate latest");
			if (!arguments.skipSeed) {
				print.line("  3. wheels db seed");
			}
		}
	}

}