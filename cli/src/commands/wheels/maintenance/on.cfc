/**
 * Enable maintenance mode for the application
 */
component extends="../base" {

	/**
	 * Turn on maintenance mode
	 *
	 * @message Optional custom maintenance message
	 * @allowedIPs Comma-separated list of IP addresses that can bypass maintenance mode
	 * @redirectURL Optional URL to redirect to during maintenance
	 * @force Skip confirmation prompt
	 */
	function run(
		string message = "The application is currently undergoing maintenance. Please check back soon.",
		string allowedIPs = "",
		string redirectURL = "",
		boolean force = false
	) {
		// Ensure we're in a Wheels app directory
		if (!directoryExists(fileSystemUtil.resolvePath("vendor/wheels"))) {
			error("This command must be run from a Wheels application root directory.");
		}

		// Check if maintenance mode is already on
		var maintenanceFile = fileSystemUtil.resolvePath("config/.maintenance");
		if (fileExists(maintenanceFile)) {
			print.yellowLine("Maintenance mode is already enabled.");
			
			// Show current configuration
			var config = deserializeJSON(fileRead(maintenanceFile));
			print.line("Current configuration:");
			print.indentedLine("Message: #config.message#");
			if (len(config.allowedIPs)) {
				print.indentedLine("Allowed IPs: #config.allowedIPs#");
			}
			if (len(config.redirectURL)) {
				print.indentedLine("Redirect URL: #config.redirectURL#");
			}
			print.indentedLine("Enabled at: #config.enabledAt#");
			
			if (!arguments.force) {
				var overwrite = confirm("Do you want to update the maintenance configuration? [y/N]");
				if (!overwrite) {
					return;
				}
			}
		}

		// Confirm action if not forced
		if (!arguments.force && !fileExists(maintenanceFile)) {
			print.line("This will enable maintenance mode for your application.");
			print.yellowLine("All requests will see the maintenance message unless their IP is in the allowed list.");
			
			var proceed = confirm("Are you sure you want to enable maintenance mode? [y/N]");
			if (!proceed) {
				print.line("Maintenance mode was not enabled.");
				return;
			}
		}

		// Create maintenance configuration
		var maintenanceConfig = {
			"enabled": true,
			"message": arguments.message,
			"allowedIPs": arguments.allowedIPs,
			"redirectURL": arguments.redirectURL,
			"enabledAt": now().toString(),
			"enabledBy": createObject("java", "java.lang.System").getProperty("user.name")
		};

		// Ensure config directory exists
		if (!directoryExists(fileSystemUtil.resolvePath("config"))) {
			directoryCreate(fileSystemUtil.resolvePath("config"));
		}

		// Write maintenance file
		fileWrite(maintenanceFile, serializeJSON(maintenanceConfig));

		// Create maintenance mode handler in Application.cfc if it doesn't exist
		updateApplicationCFC();

		print.greenLine("✓ Maintenance mode has been enabled.");
		print.line("");
		print.line("Configuration:");
		print.indentedLine("Message: #arguments.message#");
		if (len(arguments.allowedIPs)) {
			print.indentedLine("Allowed IPs: #arguments.allowedIPs#");
		}
		if (len(arguments.redirectURL)) {
			print.indentedLine("Redirect URL: #arguments.redirectURL#");
		}
		print.line("");
		print.line("To disable maintenance mode, run: wheels maintenance:off");
	}

	/**
	 * Update Application.cfc to handle maintenance mode
	 */
	private function updateApplicationCFC() {
		var appCFCPath = fileSystemUtil.resolvePath("Application.cfc");
		if (!fileExists(appCFCPath)) {
			print.yellowLine("Warning: Application.cfc not found. Maintenance mode check will not be added.");
			return;
		}

		var appContent = fileRead(appCFCPath);
		
		// Check if maintenance mode check already exists
		if (findNoCase("checkMaintenanceMode", appContent)) {
			return; // Already has maintenance mode handling
		}

		// Add maintenance mode check to onRequestStart
		var maintenanceCheck = '
	// Maintenance mode check
	private function checkMaintenanceMode() {
		var maintenanceFile = expandPath("/config/.maintenance");
		if (fileExists(maintenanceFile)) {
			var config = deserializeJSON(fileRead(maintenanceFile));
			if (config.enabled) {
				// Check if current IP is allowed
				var clientIP = cgi.remote_addr;
				if (len(config.allowedIPs) && listFindNoCase(config.allowedIPs, clientIP)) {
					return; // Allow access
				}
				
				// Handle redirect
				if (len(config.redirectURL)) {
					location(url=config.redirectURL, addtoken=false);
				}
				
				// Show maintenance message
				writeOutput("<!DOCTYPE html><html><head><title>Maintenance Mode</title><style>body{font-family:Arial,sans-serif;text-align:center;padding:50px;}h1{color:##333;}.message{background:##f0f0f0;padding:20px;border-radius:5px;max-width:600px;margin:0 auto;}</style></head><body><h1>Maintenance Mode</h1><div class=""message"">##config.message##</div></body></html>");
				abort;
			}
		}
	}';

		// Find onRequestStart or add it
		if (findNoCase("function onRequestStart", appContent)) {
			// Add check at the beginning of onRequestStart
			appContent = reReplace(
				appContent,
				"(function\s+onRequestStart[^{]*{)",
				"\1#chr(10)##chr(9)##chr(9)#checkMaintenanceMode();",
				"one"
			);
		} else {
			// Add onRequestStart with maintenance check
			var onRequestStartMethod = '
	public function onRequestStart() {
		checkMaintenanceMode();
	}';
			
			// Insert before the closing component tag
			appContent = reReplace(
				appContent,
				"(<\/cfcomponent>|})(\s*)$",
				"#onRequestStartMethod##chr(10)#\1\2",
				"one"
			);
		}

		// Add the checkMaintenanceMode method before the closing tag
		appContent = reReplace(
			appContent,
			"(<\/cfcomponent>|})(\s*)$",
			"#maintenanceCheck##chr(10)#\1\2",
			"one"
		);

		// Backup original file
		fileCopy(appCFCPath, appCFCPath & ".bak");
		
		// Write updated content
		fileWrite(appCFCPath, appContent);
		
		print.line("Updated Application.cfc with maintenance mode check.");
	}

}