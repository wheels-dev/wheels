/**
 * Show migration status
 *
 * {code:bash}
 * wheels db status
 * wheels db status --format=json
 * wheels db status --pending
 * {code}
 */
component extends="../base" {

	/**
	 * @format Output format (table or json, default: table)
	 * @pending Only show pending migrations
	 * @help Show migration status
	 */
	public void function run(
		string format = "table",
		boolean pending = false
	) {
		local.appPath = getCWD();
		
		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		print.line();
		print.boldBlueLine("Database Migration Status");
		print.line();
		
		// Build URL parameters
		local.urlParams = "&command=dbStatus&format=" & arguments.format;
		
		if (arguments.pending) {
			local.urlParams &= "&pending=true";
		}
		
		// Get migration status
		local.result = $sendToCliCommand(urlstring=local.urlParams);
		if(!local.result.success){
			return;
		}
		
		// Display results
		if (StructKeyExists(local.result, "success") && local.result.success) {
			
			// Show current version
			if (StructKeyExists(local.result, "currentVersion")) {
				print.line("Current database version: " & local.result.currentVersion);
				print.line();
			}
			
			// Show migrations based on format
			if (arguments.format == "json") {
				print.line(SerializeJSON(local.result.migrations));
			} else {
				// Table format
				if (StructKeyExists(local.result, "migrations") && IsArray(local.result.migrations) && ArrayLen(local.result.migrations)) {
					
					// Calculate column widths
					local.maxVersionLen = 20;
					local.maxDescLen = 50;
					local.maxStatusLen = 10;
					
					for (local.migration in local.result.migrations) {
						if (Len(local.migration.version) > local.maxVersionLen) {
							local.maxVersionLen = Len(local.migration.version);
						}
						if (StructKeyExists(local.migration, "description") && Len(local.migration.description) > local.maxDescLen) {
							local.maxDescLen = Len(local.migration.description);
						}
					}
					
					// Print header
					local.header = "| " & PadRight("Version", local.maxVersionLen) & " | " & 
									PadRight("Description", local.maxDescLen) & " | " & 
									PadRight("Status", local.maxStatusLen) & " | Applied At         |";
					local.separator = RepeatString("-", Len(local.header));
					
					print.line(local.separator);
					print.line(local.header);
					print.line(local.separator);
					
					// Print migrations
					for (local.migration in local.result.migrations) {
						local.version = PadRight(local.migration.version, local.maxVersionLen);
						local.description = PadRight(local.migration.description ?: "", local.maxDescLen);
						local.status = local.migration.status;
						local.appliedAt = local.migration.appliedAt ?: "Not applied";
						
						// Color code status
						if (local.status == "applied") {
							local.statusDisplay = print.green(PadRight("applied", local.maxStatusLen));
						} else if (local.status == "pending") {
							local.statusDisplay = print.yellow(PadRight("pending", local.maxStatusLen));
						} else {
							local.statusDisplay = PadRight(local.status, local.maxStatusLen);
						}
						
						print.text("| " & local.version & " | " & local.description & " | ");
						print.text(local.statusDisplay, false);
						print.line(" | " & PadRight(local.appliedAt, 18) & " |");
					}
					
					print.line(local.separator);
					
					// Summary
					if (StructKeyExists(local.result, "summary")) {
						print.line();
						print.line("Total migrations: " & local.result.summary.total);
						print.greenLine("Applied: " & local.result.summary.applied);
						print.yellowLine("Pending: " & local.result.summary.pending);
					}
					
				} else {
					print.line("No migrations found.");
				}
			}
			
		} else {
			print.redLine("✗ Failed to get migration status");
			if (StructKeyExists(local.result, "message")) {
				print.redLine(local.result.message);
			}
		}
		
		print.line();
	}

	private string function PadRight(required string text, required numeric length) {
		if (Len(arguments.text) >= arguments.length) {
			return Left(arguments.text, arguments.length);
		}
		return arguments.text & RepeatString(" ", arguments.length - Len(arguments.text));
	}

}