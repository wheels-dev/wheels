/**
 * Clear application caches
 * 
 * This command clears various types of caches used by Wheels including query, page,
 * partial, action, and SQL caches. Clear specific caches or all at once.
 * 
 * {code:bash}
 * wheels cache:clear
 * wheels cache:clear all --force
 * wheels cache:clear query
 * wheels cache:clear page
 * wheels cache:clear partial
 * wheels cache:clear action
 * wheels cache:clear sql
 * {code}
 **/
component extends="../base" {
	
	property name="FileSystemUtil" inject="FileSystem";
	
	// CommandBox metadata
	this.aliases = [ "clear", "flush" ];
	this.parameters = [
		{ name="name", type="string", required=false, default="all", hint="Cache name to clear (query|page|partial|action|sql|all)" },
		{ name="force", type="boolean", required=false, default=false, hint="Skip confirmation for clearing all caches" }
	];
	
	/**
	 * Clear specific or all application caches
	 * 
	 * This command clears various types of caches used by Wheels:
	 * - query: Database query cache
	 * - page: Full page cache
	 * - partial: Partial/fragment cache
	 * - action: Action cache
	 * - sql: SQL file cache
	 * - all: Clear all caches (default)
	 * 
	 * @name Cache name to clear (query|page|partial|action|sql|all)
	 * @force Skip confirmation for clearing all caches
	 **/
	function run(
		string name = "all",
		boolean force = false
	) {
		if (!isWheelsApp()) {
			error("This command must be run from a Wheels application root directory.");
		}
		
		var validCaches = ["query", "page", "partial", "action", "sql", "all"];
		
		if (!arrayContainsNoCase(validCaches, arguments.name)) {
			print.redLine("Invalid cache name: #arguments.name#");
			print.line("Valid options are: #arrayToList(validCaches, ', ')#");
			return;
		}
		
		print.boldGreenLine("==> Clearing #arguments.name# cache(s)...");
		print.line();
		
		// Warn if clearing all caches
		if (arguments.name == "all" && !arguments.force) {
			print.yellowLine("WARNING: This will clear all application caches.");
			var confirmed = ask("Are you sure you want to continue? [y/N]: ");
			if (lCase(trim(confirmed)) != "y") {
				print.line("Operation cancelled.");
				return;
			}
			print.line();
		}
		
		var clearedCaches = [];
		
		// Clear specific cache or all caches
		if (arguments.name == "all") {
			clearedCaches.append(clearQueryCache());
			clearedCaches.append(clearPageCache());
			clearedCaches.append(clearPartialCache());
			clearedCaches.append(clearActionCache());
			clearedCaches.append(clearSQLCache());
		} else {
			switch(arguments.name) {
				case "query":
					clearedCaches.append(clearQueryCache());
					break;
				case "page":
					clearedCaches.append(clearPageCache());
					break;
				case "partial":
					clearedCaches.append(clearPartialCache());
					break;
				case "action":
					clearedCaches.append(clearActionCache());
					break;
				case "sql":
					clearedCaches.append(clearSQLCache());
					break;
			}
		}
		
		// Try to reload the application to ensure caches are cleared
		try {
			var serverInfo = $getServerInfo();
			var reloadURL = serverInfo.serverURL & "/?reload=true&password=";
			
			print.line("Reloading application to ensure caches are cleared...");
			var http = new Http(url=reloadURL);
			http.send();
			print.greenLine("✓ Application reloaded successfully");
		} catch (any e) {
			print.yellowLine("Note: Could not reload application automatically. You may need to reload manually.");
		}
		
		print.line();
		print.boldGreenLine("==> Cache clearing complete!");
		
		for (var result in clearedCaches) {
			if (result.success) {
				print.greenLine("    ✓ #result.cache# cache cleared (#result.details#)");
			} else {
				print.yellowLine("    ⚠ #result.cache# cache: #result.details#");
			}
		}
	}
	
	/**
	 * Clear query cache
	 */
	private struct function clearQueryCache() {
		var result = {
			cache: "Query",
			success: false,
			details: ""
		};
		
		try {
			// Wheels stores query cache in tmp directory
			var cacheDir = fileSystemUtil.resolvePath("tmp/cache/queries");
			
			if (directoryExists(cacheDir)) {
				var files = directoryList(cacheDir, true, "query", "*.cache");
				var fileCount = 0;
				
				for (var file in files) {
					if (file.type == "File") {
						fileDelete(file.directory & "/" & file.name);
						fileCount++;
					}
				}
				
				result.success = true;
				result.details = "#fileCount# cached queries cleared";
			} else {
				result.success = true;
				result.details = "No query cache directory found";
			}
		} catch (any e) {
			result.details = "Error: #e.message#";
		}
		
		return result;
	}
	
	/**
	 * Clear page cache
	 */
	private struct function clearPageCache() {
		var result = {
			cache: "Page",
			success: false,
			details: ""
		};
		
		try {
			var cacheDir = fileSystemUtil.resolvePath("tmp/cache/pages");
			
			if (directoryExists(cacheDir)) {
				var files = directoryList(cacheDir, true, "query", "*.cache");
				var fileCount = 0;
				var totalSize = 0;
				
				for (var file in files) {
					if (file.type == "File") {
						totalSize += getFileInfo(file.directory & "/" & file.name).size;
						fileDelete(file.directory & "/" & file.name);
						fileCount++;
					}
				}
				
				result.success = true;
				result.details = "#fileCount# pages cleared, #formatFileSize(totalSize)# freed";
			} else {
				result.success = true;
				result.details = "No page cache directory found";
			}
		} catch (any e) {
			result.details = "Error: #e.message#";
		}
		
		return result;
	}
	
	/**
	 * Clear partial cache
	 */
	private struct function clearPartialCache() {
		var result = {
			cache: "Partial",
			success: false,
			details: ""
		};
		
		try {
			var cacheDir = fileSystemUtil.resolvePath("tmp/cache/partials");
			
			if (directoryExists(cacheDir)) {
				var files = directoryList(cacheDir, true, "query", "*.cache");
				var fileCount = 0;
				
				for (var file in files) {
					if (file.type == "File") {
						fileDelete(file.directory & "/" & file.name);
						fileCount++;
					}
				}
				
				result.success = true;
				result.details = "#fileCount# partials cleared";
			} else {
				result.success = true;
				result.details = "No partial cache directory found";
			}
		} catch (any e) {
			result.details = "Error: #e.message#";
		}
		
		return result;
	}
	
	/**
	 * Clear action cache
	 */
	private struct function clearActionCache() {
		var result = {
			cache: "Action",
			success: false,
			details: ""
		};
		
		try {
			var cacheDir = fileSystemUtil.resolvePath("tmp/cache/actions");
			
			if (directoryExists(cacheDir)) {
				var files = directoryList(cacheDir, true, "query", "*.cache");
				var fileCount = 0;
				
				for (var file in files) {
					if (file.type == "File") {
						fileDelete(file.directory & "/" & file.name);
						fileCount++;
					}
				}
				
				result.success = true;
				result.details = "#fileCount# actions cleared";
			} else {
				result.success = true;
				result.details = "No action cache directory found";
			}
		} catch (any e) {
			result.details = "Error: #e.message#";
		}
		
		return result;
	}
	
	/**
	 * Clear SQL file cache
	 */
	private struct function clearSQLCache() {
		var result = {
			cache: "SQL",
			success: false,
			details: ""
		};
		
		try {
			var cacheDir = fileSystemUtil.resolvePath("tmp/cache/sql");
			
			if (directoryExists(cacheDir)) {
				var files = directoryList(cacheDir, true, "query", "*.cache");
				var fileCount = 0;
				
				for (var file in files) {
					if (file.type == "File") {
						fileDelete(file.directory & "/" & file.name);
						fileCount++;
					}
				}
				
				result.success = true;
				result.details = "#fileCount# SQL files cleared";
			} else {
				result.success = true;
				result.details = "No SQL cache directory found";
			}
		} catch (any e) {
			result.details = "Error: #e.message#";
		}
		
		return result;
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