/**
 * Rollback database migrations
 *
 * {code:bash}
 * wheels db rollback
 * wheels db rollback --steps=3
 * wheels db rollback --target=20231201120000
 * {code}
 */
component extends="../base" {

	/**
	 * @steps Number of migrations to rollback (default: 1)
	 * @target Rollback to a specific migration version
	 * @force Skip confirmation prompt
	 * @help Rollback database migrations
	 */
	public void function run(
		numeric steps = 1,
		string target = "",
		boolean force = false
	) {
		local.appPath = getCWD();
		
		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		print.line();
		print.boldYellowLine("Rolling back database migrations");
		print.line();
		
		// Build URL parameters
		local.urlParams = "&command=dbRollback";
		
		if (Len(arguments.target)) {
			local.urlParams &= "&target=" & arguments.target;
			print.line("Target version: " & arguments.target);
		} else {
			local.urlParams &= "&steps=" & arguments.steps;
			print.line("Steps to rollback: " & arguments.steps);
		}
		
		// Confirm unless forced
		if (!arguments.force) {
			local.confirmMsg = "Are you sure you want to rollback ";
			if (Len(arguments.target)) {
				local.confirmMsg &= "to version " & arguments.target;
			} else {
				local.confirmMsg &= arguments.steps & " migration" & (arguments.steps > 1 ? "s" : "");
			}
			local.confirmMsg &= "? Type 'yes' to confirm: ";
			
			local.confirm = ask(local.confirmMsg);
			if (local.confirm != "yes") {
				print.yellowLine("Rollback cancelled.");
				return;
			}
		}
		
		print.line();
		
		// Send command to rollback migrations
		local.result = $sendToCliCommand(urlstring=local.urlParams);
		
		// Display results
		if (StructKeyExists(local.result, "success") && local.result.success) {
			print.greenLine("✓ Migrations rolled back successfully");
			
			if (StructKeyExists(local.result, "migrationsRolledBack") && IsArray(local.result.migrationsRolledBack)) {
				print.line();
				print.line("Rolled back migrations:");
				for (local.migration in local.result.migrationsRolledBack) {
					print.line(" - " & local.migration);
				}
			}
			
			if (StructKeyExists(local.result, "currentVersion")) {
				print.line();
				print.line("Current database version: " & local.result.currentVersion);
			}
		} else {
			print.redLine("✗ Failed to rollback migrations");
			if (StructKeyExists(local.result, "message")) {
				print.redLine(local.result.message);
			}
		}
		
		print.line();
	}

}