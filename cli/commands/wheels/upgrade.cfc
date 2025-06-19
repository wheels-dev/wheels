/**
 * Interactive Wheels framework upgrade wizard
 *
 * This command helps you upgrade your Wheels application to a newer version
 * by analyzing your current setup and guiding you through the upgrade process.
 *
 * {code:bash}
 * wheels upgrade
 * wheels upgrade --to=3.0.0
 * wheels upgrade --check
 * {code}
 **/
component extends="base" {

	/**
	 * @to Target version to upgrade to
	 * @check Check if upgrade is available without performing it
	 * @force Skip confirmation prompts
	 * @backup Create backup before upgrading (default: true)
	 **/
	function run(
		string to = "",
		boolean check = false,
		boolean force = false,
		boolean backup = true
	) {
		// Ensure we're in a Wheels app directory
		if (!directoryExists(fileSystemUtil.resolvePath("vendor/wheels"))) {
			error("This command must be run from the root of a Wheels application.");
		}

		// Get current version
		local.currentVersion = $getWheelsVersion();
		print.line("Current Wheels version: " & local.currentVersion).line();

		// Get available versions from ForgeBox
		local.availableVersions = getAvailableVersions();
		
		if (arguments.check) {
			// Just check for available upgrades
			local.latestVersion = local.availableVersions[1];
			if (compareVersions(local.latestVersion, local.currentVersion) > 0) {
				print.greenLine("Upgrade available: " & local.latestVersion);
				print.line("Run 'wheels upgrade' to start the upgrade process.");
			} else {
				print.yellowLine("You are already on the latest version.");
			}
			return;
		}

		// Determine target version
		if (len(arguments.to)) {
			local.targetVersion = arguments.to;
			// Validate the target version exists
			if (!arrayFindNoCase(local.availableVersions, local.targetVersion)) {
				error("Version " & local.targetVersion & " is not available. Use 'wheels upgrade --check' to see available versions.");
			}
		} else {
			// Show version selection menu
			print.line("Available Wheels versions:");
			local.versionChoices = [];
			for (local.version in local.availableVersions) {
				if (compareVersions(local.version, local.currentVersion) > 0) {
					arrayAppend(local.versionChoices, local.version);
				}
			}
			
			if (arrayLen(local.versionChoices) == 0) {
				print.yellowLine("You are already on the latest version.");
				return;
			}

			local.targetVersion = ask(
				message = "Select version to upgrade to: ",
				options = local.versionChoices
			);
		}

		// Show upgrade plan
		print.line().boldLine("Upgrade Plan:");
		print.line("From: " & local.currentVersion);
		print.line("To: " & local.targetVersion);
		print.line();

		// Check for breaking changes
		local.breakingChanges = checkBreakingChanges(local.currentVersion, local.targetVersion);
		if (arrayLen(local.breakingChanges)) {
			print.yellowLine("⚠️  Breaking Changes Detected:");
			for (local.change in local.breakingChanges) {
				print.line("  • " & local.change);
			}
			print.line();
		}

		// Show upgrade steps
		local.upgradeSteps = getUpgradeSteps(local.currentVersion, local.targetVersion);
		print.boldLine("Upgrade Steps:");
		for (local.i = 1; local.i <= arrayLen(local.upgradeSteps); local.i++) {
			print.line(local.i & ". " & local.upgradeSteps[local.i]);
		}
		print.line();

		// Confirm upgrade
		if (!arguments.force) {
			if (!confirm("Do you want to proceed with the upgrade?")) {
				print.line("Upgrade cancelled.");
				return;
			}
		}

		// Create backup if requested
		if (arguments.backup) {
			print.line().line("Creating backup...");
			local.backupPath = createBackup();
			print.greenLine("✓ Backup created at: " & local.backupPath);
		}

		// Perform upgrade
		print.line().boldLine("Starting upgrade...");
		
		try {
			// Step 1: Update box.json
			print.line("Updating dependencies...");
			updateBoxJSON(local.targetVersion);
			
			// Step 2: Run box install to get new version
			print.line("Installing new version...");
			command("install").params(force = true).run();
			
			// Step 3: Run any migration scripts
			if (fileExists(fileSystemUtil.resolvePath("vendor/wheels/upgrade/" & local.targetVersion & ".cfm"))) {
				print.line("Running upgrade script...");
				runUpgradeScript(local.targetVersion);
			}
			
			// Step 4: Clear caches
			print.line("Clearing caches...");
			if (directoryExists(fileSystemUtil.resolvePath("app/cache"))) {
				directoryDelete(fileSystemUtil.resolvePath("app/cache"), true);
			}
			
			// Step 5: Reload application
			print.line("Reloading application...");
			command("wheels reload").run();
			
			print.line().greenBoldLine("✓ Upgrade completed successfully!");
			print.line("Your application is now running Wheels " & local.targetVersion);
			
			// Show post-upgrade recommendations
			local.recommendations = getPostUpgradeRecommendations(local.targetVersion);
			if (arrayLen(local.recommendations)) {
				print.line().boldLine("Post-Upgrade Recommendations:");
				for (local.rec in local.recommendations) {
					print.line("  • " & local.rec);
				}
			}
			
		} catch (any e) {
			print.line().redBoldLine("✗ Upgrade failed!");
			print.redLine(e.message);
			
			if (arguments.backup) {
				print.line().yellowLine("You can restore from backup at: " & local.backupPath);
			}
			
			rethrow;
		}
	}

	/**
	 * Get available Wheels versions from ForgeBox
	 */
	private array function getAvailableVersions() {
		// In a real implementation, this would query ForgeBox API
		// For now, return a static list
		return [
			"3.0.0",
			"2.5.0", 
			"2.4.1",
			"2.4.0",
			"2.3.0",
			"2.2.0",
			"2.1.0",
			"2.0.2",
			"2.0.1",
			"2.0.0"
		];
	}

	/**
	 * Compare two version strings
	 * Returns: 1 if v1 > v2, -1 if v1 < v2, 0 if equal
	 */
	private numeric function compareVersions(required string v1, required string v2) {
		local.v1Parts = listToArray(arguments.v1, ".");
		local.v2Parts = listToArray(arguments.v2, ".");
		
		for (local.i = 1; local.i <= max(arrayLen(local.v1Parts), arrayLen(local.v2Parts)); local.i++) {
			local.part1 = (local.i <= arrayLen(local.v1Parts)) ? val(local.v1Parts[local.i]) : 0;
			local.part2 = (local.i <= arrayLen(local.v2Parts)) ? val(local.v2Parts[local.i]) : 0;
			
			if (local.part1 > local.part2) return 1;
			if (local.part1 < local.part2) return -1;
		}
		
		return 0;
	}

	/**
	 * Check for breaking changes between versions
	 */
	private array function checkBreakingChanges(required string fromVersion, required string toVersion) {
		local.changes = [];
		
		// Major version upgrade
		if (listFirst(arguments.fromVersion, ".") != listFirst(arguments.toVersion, ".")) {
			arrayAppend(local.changes, "Major version upgrade - review changelog for breaking changes");
		}
		
		// Specific known breaking changes
		if (arguments.fromVersion contains "1." && arguments.toVersion contains "2.") {
			arrayAppend(local.changes, "Wheels 2.x requires ColdFusion 11+ or Lucee 5+");
			arrayAppend(local.changes, "Plugin structure has changed");
			arrayAppend(local.changes, "Some deprecated functions have been removed");
		}
		
		if (arguments.fromVersion contains "2." && arguments.toVersion contains "3.") {
			arrayAppend(local.changes, "Wheels 3.x uses CommandBox modules");
			arrayAppend(local.changes, "New routing engine with different syntax");
			arrayAppend(local.changes, "Updated model callback names");
		}
		
		return local.changes;
	}

	/**
	 * Get upgrade steps for the version jump
	 */
	private array function getUpgradeSteps(required string fromVersion, required string toVersion) {
		local.steps = [
			"Back up your application and database",
			"Update box.json dependencies", 
			"Run 'box install --force' to get new version",
			"Review and apply any necessary code changes",
			"Run database migrations if needed",
			"Clear all caches",
			"Test thoroughly in development",
			"Deploy to staging for further testing"
		];
		
		return local.steps;
	}

	/**
	 * Create a backup of the current application
	 */
	private string function createBackup() {
		local.timestamp = dateTimeFormat(now(), "yyyymmdd-HHnnss");
		local.backupDir = fileSystemUtil.resolvePath("backups/upgrade-" & local.timestamp);
		
		// Create backup directory
		directoryCreate(local.backupDir, true);
		
		// Copy important directories
		local.dirsToBackup = ["app", "config", "vendor/wheels"];
		for (local.dir in local.dirsToBackup) {
			if (directoryExists(fileSystemUtil.resolvePath(local.dir))) {
				directoryCopy(
					fileSystemUtil.resolvePath(local.dir),
					local.backupDir & "/" & local.dir,
					true
				);
			}
		}
		
		// Copy important files
		local.filesToBackup = ["box.json", "server.json", ".env"];
		for (local.file in local.filesToBackup) {
			if (fileExists(fileSystemUtil.resolvePath(local.file))) {
				fileCopy(
					fileSystemUtil.resolvePath(local.file),
					local.backupDir & "/" & local.file
				);
			}
		}
		
		return local.backupDir;
	}

	/**
	 * Update box.json with new Wheels version
	 */
	private void function updateBoxJSON(required string version) {
		local.boxJSON = packageService.readPackageDescriptor(getCWD());
		
		// Update wheels-core dependency
		if (!structKeyExists(local.boxJSON.dependencies, "wheels-core")) {
			local.boxJSON.dependencies["wheels-core"] = "";
		}
		local.boxJSON.dependencies["wheels-core"] = "^" & arguments.version;
		
		// Write updated box.json
		packageService.writePackageDescriptor(local.boxJSON, getCWD());
	}

	/**
	 * Run version-specific upgrade script
	 */
	private void function runUpgradeScript(required string version) {
		local.scriptPath = fileSystemUtil.resolvePath("vendor/wheels/upgrade/" & arguments.version & ".cfm");
		if (fileExists(local.scriptPath)) {
			include template="#local.scriptPath#";
		}
	}

	/**
	 * Get post-upgrade recommendations
	 */
	private array function getPostUpgradeRecommendations(required string version) {
		local.recommendations = [
			"Run your test suite to ensure everything works",
			"Check the upgrade guide at https://guides.cfwheels.org/upgrading",
			"Review deprecated features that may be removed in future versions",
			"Update your plugins to compatible versions"
		];
		
		return local.recommendations;
	}

}