/**
 * Clear log files
 * 
 * This command removes log files from the logs directory. You can filter by
 * environment, age, or clear all logs. Useful for managing disk space.
 * 
 * {code:bash}
 * wheels log:clear
 * wheels log:clear --environment=production
 * wheels log:clear --days=30
 * wheels log:clear --environment=production --days=7 --force
 * {code}
 **/
component extends="../base" {
	
	property name="FileSystemUtil" inject="FileSystem";
	
	// CommandBox metadata
	this.aliases = [ "clear", "clean" ];
	this.parameters = [
		{ name="environment", type="string", required=false, default="all", hint="Environment logs to clear (development|testing|production|all)" },
		{ name="days", type="numeric", required=false, default=0, hint="Only clear logs older than specified days" },
		{ name="force", type="boolean", required=false, default=false, hint="Skip confirmation prompt" }
	];
	
	/**
	 * Clear application log files
	 * 
	 * This command removes log files from the logs directory.
	 * You can specify which environment's logs to clear or clear all logs.
	 * 
	 * @environment Environment logs to clear (development|testing|production|all)
	 * @days Only clear logs older than specified days
	 * @force Skip confirmation prompt
	 **/
	function run(
		string environment = "all",
		numeric days = 0,
		boolean force = false
	) {
		if (!isWheelsApp()) {
			error("This command must be run from a Wheels application root directory.");
		}
		
		print.boldGreenLine("==> Clearing log files...");
		print.line();
		
		var logsDir = fileSystemUtil.resolvePath("logs");
		
		if (!directoryExists(logsDir)) {
			print.yellowLine("No logs directory found. Nothing to clear.");
			return;
		}
		
		// Get list of log files
		var logFiles = directoryList(logsDir, false, "query", "*.log");
		var targetFiles = [];
		var cutoffDate = (arguments.days > 0) ? dateAdd("d", -arguments.days, now()) : createDate(1900, 1, 1);
		
		for (var file in logFiles) {
			if (file.type == "File") {
				var includeFile = false;
				
				// Filter by environment
				if (arguments.environment == "all") {
					includeFile = true;
				} else {
					// Check if filename contains the environment name
					if (findNoCase(arguments.environment, file.name)) {
						includeFile = true;
					}
				}
				
				// Filter by age
				if (includeFile && arguments.days > 0) {
					if (dateCompare(file.dateLastModified, cutoffDate) < 0) {
						includeFile = true;
					} else {
						includeFile = false;
					}
				}
				
				if (includeFile) {
					arrayAppend(targetFiles, {
						name: file.name,
						path: file.directory & "/" & file.name,
						size: getFileInfo(file.directory & "/" & file.name).size,
						dateLastModified: file.dateLastModified
					});
				}
			}
		}
		
		if (arrayLen(targetFiles) == 0) {
			print.yellowLine("No log files found matching criteria.");
			return;
		}
		
		// Calculate total size
		var totalSize = 0;
		for (var file in targetFiles) {
			totalSize += file.size;
		}
		
		// Show what will be deleted
		print.line("Found #arrayLen(targetFiles)# log file(s) to clear:");
		print.line();
		
		for (var file in targetFiles) {
			var ageInDays = dateDiff("d", file.dateLastModified, now());
			print.line("  - #file.name# (#formatFileSize(file.size)#, #ageInDays# days old)");
		}
		
		print.line();
		print.line("Total size: #formatFileSize(totalSize)#");
		print.line();
		
		// Confirm unless forced
		if (!arguments.force) {
			var confirmed = ask("Are you sure you want to delete these log files? [y/N]: ");
			if (lCase(trim(confirmed)) != "y") {
				print.line("Operation cancelled.");
				return;
			}
		}
		
		print.line();
		var deletedCount = 0;
		var freedSpace = 0;
		
		// Delete the files
		for (var file in targetFiles) {
			try {
				fileDelete(file.path);
				print.redLine("  ✗ Deleted: #file.name#");
				deletedCount++;
				freedSpace += file.size;
			} catch (any e) {
				print.redLine("  Error deleting #file.name#: #e.message#");
			}
		}
		
		print.line();
		print.boldGreenLine("==> Log clearing complete!");
		print.greenLine("    Deleted #deletedCount# log files");
		print.greenLine("    Freed #formatFileSize(freedSpace)# of disk space");
		
		// Create new empty log files for current environment if needed
		if (arguments.environment != "all") {
			try {
				var newLogFile = logsDir & "/" & arguments.environment & ".log";
				fileWrite(newLogFile, "");
				print.line();
				print.yellowLine("Created new empty log file: #arguments.environment#.log");
			} catch (any e) {
				// Ignore if we can't create the file
			}
		}
	}
	
	/**
	 * Format file size in human-readable format
	 */
	private string function formatFileSize(required numeric bytes) {
		var units = ["B", "KB", "MB", "GB"];
		var size = arguments.bytes;
		var unitIndex = 1;
		
		while (size >= 1024 && unitIndex < arrayLen(units)) {
			size = size / 1024;
			unitIndex++;
		}
		
		if (unitIndex == 1) {
			return numberFormat(size, "0") & " " & units[unitIndex];
		} else {
			return numberFormat(size, "0.00") & " " & units[unitIndex];
		}
	}
	
}