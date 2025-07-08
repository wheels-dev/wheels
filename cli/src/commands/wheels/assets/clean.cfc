/**
 * Remove old compiled assets
 * 
 * This command cleans up old asset files from previous compilations while keeping
 * the most recent versions. Useful for freeing disk space after multiple deployments.
 * 
 * {code:bash}
 * wheels assets:clean
 * wheels assets:clean --keep=5
 * wheels assets:clean --dryRun
 * {code}
 **/
component extends="../base" {
	
	property name="FileSystemUtil" inject="FileSystem";
	
	// CommandBox metadata
	this.aliases = [ "clean" ];
	this.parameters = [
		{ name="keep", type="numeric", required=false, default=3, hint="Number of versions to keep for each asset" },
		{ name="dryRun", type="boolean", required=false, default=false, hint="Show what would be deleted without actually deleting" }
	];
	
	/**
	 * Remove old compiled assets while keeping the most recent versions
	 * 
	 * This command cleans up old asset files from previous compilations,
	 * keeping only the most recent version of each asset based on the manifest.
	 * 
	 * @keep Number of versions to keep for each asset (default: 3)
	 * @dryRun Show what would be deleted without actually deleting
	 **/
	function run(
		numeric keep = 3,
		boolean dryRun = false
	) {
		if (!isWheelsApp()) {
			error("This command must be run from a Wheels application root directory.");
		}
		
		print.boldGreenLine("==> Cleaning old compiled assets...");
		print.line();
		
		// var compiledDir = fileSystemUtil.resolvePath("public/assets/compiled");
		var compiledDir = fileSystemUtil.resolvePath("templates/base/src/public/assets/compiled");
		
		if (!directoryExists(compiledDir)) {
			print.yellowLine("No compiled assets directory found. Nothing to clean.");
			return;
		}
		
		// Read current manifest
		var manifestPath = compiledDir & "/manifest.json";
		var currentManifest = {};
		
		if (fileExists(manifestPath)) {
			try {
				currentManifest = deserializeJSON(fileRead(manifestPath));
			} catch (any e) {
				print.redLine("Error reading manifest file: #e.message#");
				return;
			}
		}
		
		// Group files by base name
		var fileGroups = {};
		var files = directoryList(compiledDir, false, "query", "*.*");
		
		for (var file in files) {
			if (file.type == "File" && file.name != "manifest.json") {
				var baseName = extractBaseName(file.name);
				if (!structKeyExists(fileGroups, baseName)) {
					fileGroups[baseName] = [];
				}
				arrayAppend(fileGroups[baseName], {
					name: file.name,
					path: file.directory & "/" & file.name,
					dateLastModified: file.dateLastModified
				});
			}
		}
		
		var deletedCount = 0;
		var freedSpace = 0;
		
		// Process each group
		for (var baseName in fileGroups) {
			var group = fileGroups[baseName];
			
			// Sort by date modified (newest first)
			arraySort(group, function(a, b) {
				return dateCompare(b.dateLastModified, a.dateLastModified);
			});
			
			// Keep the specified number of versions
			if (arrayLen(group) > arguments.keep) {
				print.boldLine("Cleaning #baseName#...");
				
				for (var i = arguments.keep + 1; i <= arrayLen(group); i++) {
					var fileInfo = group[i];
					var fileSize = getFileInfo(fileInfo.path).size;
					
					if (arguments.dryRun) {
						print.line("  Would delete: #fileInfo.name# (#formatFileSize(fileSize)#)");
					} else {
						try {
							fileDelete(fileInfo.path);
							print.redLine("  ✗ Deleted: #fileInfo.name# (#formatFileSize(fileSize)#)");
							deletedCount++;
							freedSpace += fileSize;
						} catch (any e) {
							print.redLine("  Error deleting #fileInfo.name#: #e.message#");
						}
					}
				}
			}
		}
		
		print.line();
		
		if (arguments.dryRun) {
			print.yellowLine("==> Dry run complete. No files were deleted.");
			print.line("    Would delete #deletedCount# files");
			print.line("    Would free #formatFileSize(freedSpace)# of disk space");
		} else if (deletedCount > 0) {
			print.boldGreenLine("==> Asset cleaning complete!");
			print.greenLine("    Deleted #deletedCount# old asset files");
			print.greenLine("    Freed #formatFileSize(freedSpace)# of disk space");
		} else {
			print.yellowLine("No old assets found to clean.");
		}
	}
	
	/**
	 * Extract base name from a compiled asset filename
	 * e.g., "app-a1b2c3d4.min.js" returns "app"
	 */
	private string function extractBaseName(required string fileName) {
		// Remove hash and extension
		var name = arguments.fileName;
		
		// Handle minified files
		name = reReplace(name, "\.min\.(js|css)$", "", "one");
		
		// Remove hash pattern (8+ character hex string)
		name = reReplace(name, "-[a-f0-9]{8,}\.", ".", "one");
		
		// Remove final extension
		name = listDeleteAt(name, listLen(name, "."), ".");
		
		return name;
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