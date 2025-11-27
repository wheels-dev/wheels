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
component aliases="clean" extends="../base" {

	property name="FileSystemUtil" inject="FileSystem";
	property name="detailOutput" inject="DetailOutputService@wheels-cli";

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
		requireWheelsApp(getCWD());
		arguments = reconstructArgs(
			argStruct=arguments,
			numericRanges={
				keep:{min:1, max:100}
			}
		);
		detailOutput.line();
		if(!dryRun){
			print.greenBoldLine("Cleaning old compiled assets...").toConsole();
		}else{
			print.cyanBoldLine("Dry Running old compiled assets...").toConsole();
		}
		detailOutput.line();

		var compiledDir = fileSystemUtil.resolvePath("public/assets/compiled");

		if (!directoryExists(compiledDir)) {
			print.yellowLine("No compiled assets directory found. Nothing to clean.").toConsole();
			return;
		}
		
		// Read current manifest
		var manifestPath = compiledDir & "/manifest.json";
		var currentManifest = {};
		
		if (fileExists(manifestPath)) {
			try {
				currentManifest = deserializeJSON(fileRead(manifestPath));
			} catch (any e) {
				detailOutput.error("Error reading manifest file: #e.message#");
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
			
			// Keep the specified number of versions (array is sorted newest first)
			// Delete from the end of the array (oldest files)
			if (arrayLen(group) > arguments.keep) {
				if (arguments.dryRun) {
					print.boldLine("Analyzing #baseName#...").toConsole();
				} else {
					print.boldLine("Cleaning #baseName#...").toConsole();
				}

				// Delete from the end (oldest) since array is sorted newest first
				for (var i = arrayLen(group); i > arguments.keep; i--) {
					var fileInfo = group[i];
					var fileSize = getFileInfo(fileInfo.path).size;

					if (arguments.dryRun) {
						detailOutput.output("Would delete: #fileInfo.name# (#formatFileSize(fileSize)#)");
						deletedCount++;
						freedSpace += fileSize;
					} else {
						try {
							fileDelete(fileInfo.path);
							print.redLine("Deleted: #fileInfo.name# (#formatFileSize(fileSize)#)").toConsole();
							deletedCount++;
							freedSpace += fileSize;
						} catch (any e) {
							detailOutput.error("Error deleting #fileInfo.name#: #e.message#");
						}
					}
				}
			}
		}


		detailOutput.line();

		if (arguments.dryRun) {
			print.yellowLine("Dry run complete. No files were deleted.").toConsole();
			detailOutput.output("Would delete #deletedCount# files");
			detailOutput.output("Would free #formatFileSize(freedSpace)# of disk space");
		} else if (deletedCount > 0) {
			detailOutput.success("Asset cleaning complete!");
			print.greenLine("Deleted #deletedCount# old asset files").toConsole();
			print.greenLine("Freed #formatFileSize(freedSpace)# of disk space").toConsole();
		} else {
		detailOutput.statusWarning("No old assets found to clean.");
		}
	}
	
	/**
	 * Extract base name from a compiled asset filename
	 * e.g., "app-a1b2c3d4.min.js" returns "app"
	 * e.g., "style-ABC12345.min.css" returns "style"
	 * e.g., "script-DEF67890.js" returns "script"
	 */
	private string function extractBaseName(required string fileName) {
		var name = arguments.fileName;

		// Remove file extension (.js, .css, .min.js, .min.css)
		name = reReplace(name, "\.(min\.)?(js|css)$", "", "one");

		// Remove hash pattern (dash followed by 8+ character hex string, case-insensitive)
		// Examples: "app-a1b2c3d4" → "app", "style-ABC12345" → "style"
		name = reReplaceNoCase(name, "-[a-f0-9]{8,}$", "", "one");

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