/**
 * Disable maintenance mode for the application
 */
component extends="../base" {

	/**
	 * Turn off maintenance mode
	 *
	 * @force Skip confirmation prompt
	 * @cleanup Remove maintenance check from Application.cfc
	 */
	function run(
		boolean force = false,
		boolean cleanup = false
	) {
		// Ensure we're in a Wheels app directory
		if (!directoryExists(fileSystemUtil.resolvePath("vendor/wheels"))) {
			error("This command must be run from a Wheels application root directory.");
		}

		// Check if maintenance mode is enabled
		var maintenanceFile = fileSystemUtil.resolvePath("config/.maintenance");
		if (!fileExists(maintenanceFile)) {
			print.yellowLine("Maintenance mode is not currently enabled.");
			return;
		}

		// Read current configuration
		var config = deserializeJSON(fileRead(maintenanceFile));
		
		// Show current configuration
		print.line("Current maintenance mode configuration:");
		print.indentedLine("Message: #config.message#");
		if (structKeyExists(config, "allowedIPs") && len(config.allowedIPs)) {
			print.indentedLine("Allowed IPs: #config.allowedIPs#");
		}
		if (structKeyExists(config, "redirectURL") && len(config.redirectURL)) {
			print.indentedLine("Redirect URL: #config.redirectURL#");
		}
		print.indentedLine("Enabled at: #config.enabledAt#");
		if (structKeyExists(config, "enabledBy")) {
			print.indentedLine("Enabled by: #config.enabledBy#");
		}
		
		// Calculate downtime duration
		try {
			var enabledDate = parseDateTime(config.enabledAt);
			var duration = dateDiff("n", enabledDate, now());
			var hours = int(duration / 60);
			var minutes = duration mod 60;
			
			if (hours > 0) {
				print.indentedLine("Duration: #hours# hour(s) and #minutes# minute(s)");
			} else {
				print.indentedLine("Duration: #minutes# minute(s)");
			}
		} catch (any e) {
			// Ignore duration calculation errors
		}
		
		print.line("");

		// Confirm action if not forced
		if (!arguments.force) {
			var proceed = confirm("Are you sure you want to disable maintenance mode? [y/N]");
			if (!proceed) {
				print.line("Maintenance mode was not disabled.");
				return;
			}
		}

		// Delete maintenance file
		fileDelete(maintenanceFile);

		// Clean up Application.cfc if requested
		if (arguments.cleanup) {
			cleanupApplicationCFC();
		}

		print.greenLine("✓ Maintenance mode has been disabled.");
		print.line("");
		print.line("Your application is now accessible to all users.");
		
		if (!arguments.cleanup) {
			print.line("");
			print.line("Note: The maintenance mode check is still in Application.cfc.");
			print.line("To remove it, run: wheels maintenance:off --cleanup");
		}
	}

	/**
	 * Remove maintenance mode check from Application.cfc
	 */
	private function cleanupApplicationCFC() {
		var appCFCPath = fileSystemUtil.resolvePath("Application.cfc");
		if (!fileExists(appCFCPath)) {
			return;
		}

		var appContent = fileRead(appCFCPath);
		
		// Check if maintenance mode check exists
		if (!findNoCase("checkMaintenanceMode", appContent)) {
			return; // No maintenance mode handling to remove
		}

		// Remove checkMaintenanceMode() call from onRequestStart
		appContent = reReplace(
			appContent,
			"\s*checkMaintenanceMode\(\);",
			"",
			"all"
		);

		// Remove the checkMaintenanceMode method
		// This regex handles the method and its comments
		appContent = reReplace(
			appContent,
			"(\s*//\s*Maintenance mode check\s*)?[\r\n\s]*private\s+function\s+checkMaintenanceMode\s*\([^)]*\)\s*\{[^}]*\}",
			"",
			"one"
		);

		// Clean up any empty onRequestStart methods that might remain
		appContent = reReplace(
			appContent,
			"public\s+function\s+onRequestStart\s*\([^)]*\)\s*\{\s*\}",
			"",
			"one"
		);

		// Write updated content
		fileWrite(appCFCPath, appContent);
		
		// Clean up backup if it exists
		var backupPath = appCFCPath & ".bak";
		if (fileExists(backupPath)) {
			fileDelete(backupPath);
		}
		
		print.line("Removed maintenance mode check from Application.cfc.");
	}

}