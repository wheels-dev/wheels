/**
 * Show current database schema version
 *
 * {code:bash}
 * wheels db version
 * wheels db version --detailed
 * {code}
 */
component extends="../base" {

	/**
	 * @detailed Show detailed version information
	 * @help Show current database schema version
	 */
	public void function run(
		boolean detailed = false
	) {
		local.appPath = getCWD();
		
		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		// Build URL parameters
		local.urlParams = "&command=dbVersion";
		
		if (arguments.detailed) {
			local.urlParams &= "&detailed=true";
		}
		
		// Get version information
		local.result = $sendToCliCommand(urlstring=local.urlParams);
		
		// Display results
		if (StructKeyExists(local.result, "success") && local.result.success) {
			
			print.line();
			
			// Basic version info
			if (StructKeyExists(local.result, "currentVersion")) {
				print.boldGreenLine("Current database version: " & local.result.currentVersion);
			} else {
				print.yellowLine("No migrations have been applied yet.");
			}
			
			// Detailed information
			if (arguments.detailed && StructKeyExists(local.result, "details")) {
				print.line();
				
				if (StructKeyExists(local.result.details, "lastMigration")) {
					print.line("Last migration:");
					print.line("  Version: " & local.result.details.lastMigration.version);
					if (StructKeyExists(local.result.details.lastMigration, "description")) {
						print.line("  Description: " & local.result.details.lastMigration.description);
					}
					if (StructKeyExists(local.result.details.lastMigration, "appliedAt")) {
						print.line("  Applied at: " & local.result.details.lastMigration.appliedAt);
					}
				}
				
				if (StructKeyExists(local.result.details, "totalMigrations")) {
					print.line();
					print.line("Total migrations: " & local.result.details.totalMigrations);
				}
				
				if (StructKeyExists(local.result.details, "pendingMigrations")) {
					print.line("Pending migrations: " & local.result.details.pendingMigrations);
					
					if (local.result.details.pendingMigrations > 0 && StructKeyExists(local.result.details, "nextMigration")) {
						print.line();
						print.yellowLine("Next migration to apply:");
						print.line("  Version: " & local.result.details.nextMigration.version);
						if (StructKeyExists(local.result.details.nextMigration, "description")) {
							print.line("  Description: " & local.result.details.nextMigration.description);
						}
					}
				}
				
				if (StructKeyExists(local.result.details, "environment")) {
					print.line();
					print.line("Environment: " & local.result.details.environment);
				}
				
				if (StructKeyExists(local.result.details, "datasource")) {
					print.line("Datasource: " & local.result.details.datasource);
				}
			}
			
		} else {
			print.redLine("✗ Failed to get database version");
			if (StructKeyExists(local.result, "message")) {
				print.redLine(local.result.message);
			}
		}
		
		print.line();
	}

}