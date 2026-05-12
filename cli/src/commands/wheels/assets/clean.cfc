/**
 * Remove old compiled assets
 *
 * Cleans up old asset files from previous compilations while keeping
 * the most recent versions. Handles both Vite build output (public/build/)
 * and legacy compiled assets (public/assets/compiled/).
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
	 * Detects whether the project uses Vite (public/build/) or legacy
	 * (public/assets/compiled/) asset pipeline and cleans accordingly.
	 *
	 * @keep Number of versions to keep for each asset (default: 3)
	 * @dryRun Show what would be deleted without actually deleting
	 **/
	function run(
		numeric keep = 3,
		boolean dryRun = false
	) {
		try {
			requireWheelsApp(getCWD());
			arguments = reconstructArgs(
				argStruct=arguments,
				numericRanges={
					keep:{min:1, max:100}
				}
			);

			var viteBuildDir = fileSystemUtil.resolvePath("public/build");
			var legacyCompiledDir = fileSystemUtil.resolvePath("public/assets/compiled");
			var cleaned = false;

			// Clean Vite build assets if present
			if (directoryExists(viteBuildDir & "/assets")) {
				cleaned = true;
				cleanViteAssets(viteBuildDir & "/assets", arguments.keep, arguments.dryRun);
			}

			// Clean legacy compiled assets if present
			if (directoryExists(legacyCompiledDir)) {
				cleaned = true;
				cleanLegacyAssets(legacyCompiledDir, arguments.keep, arguments.dryRun);
			}

			if (!cleaned) {
				print.yellowLine("No compiled assets directory found. Nothing to clean.").toConsole();
			}

		} catch (any e) {
			detailOutput.error("#e.message#");
			setExitCode(1);
		}
	}

	/**
	 * Clean Vite build assets directory, keeping recent versions of fingerprinted files
	 */
	private void function cleanViteAssets(
		required string assetsDir,
		required numeric keep,
		required boolean dryRun
	) {
		detailOutput.line();
		if (!arguments.dryRun) {
			print.greenBoldLine("Cleaning Vite build assets...").toConsole();
		} else {
			print.cyanBoldLine("Dry run: Vite build assets...").toConsole();
		}
		detailOutput.line();

		var fileGroups = {};
		var files = directoryList(arguments.assetsDir, false, "query", "*.*");

		for (var file in files) {
			if (file.type == "File") {
				var baseName = extractViteBaseName(file.name);
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

		for (var baseName in fileGroups) {
			var group = fileGroups[baseName];

			arraySort(group, function(a, b) {
				return dateCompare(b.dateLastModified, a.dateLastModified);
			});

			if (arrayLen(group) > arguments.keep) {
				if (arguments.dryRun) {
					print.boldLine("Analyzing #baseName#...").toConsole();
				} else {
					print.boldLine("Cleaning #baseName#...").toConsole();
				}

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

		printCleanSummary(deletedCount, freedSpace, arguments.dryRun);
	}

	/**
	 * Clean legacy compiled assets directory
	 */
	private void function cleanLegacyAssets(
		required string compiledDir,
		required numeric keep,
		required boolean dryRun
	) {
		detailOutput.line();
		if (!arguments.dryRun) {
			print.greenBoldLine("Cleaning legacy compiled assets...").toConsole();
		} else {
			print.cyanBoldLine("Dry run: legacy compiled assets...").toConsole();
		}
		detailOutput.line();

		// Read current manifest
		var manifestPath = arguments.compiledDir & "/manifest.json";
		if (fileExists(manifestPath)) {
			try {
				deserializeJSON(fileRead(manifestPath));
			} catch (any e) {
				detailOutput.error("Error reading manifest file: #e.message#");
				return;
			}
		}

		var fileGroups = {};
		var files = directoryList(arguments.compiledDir, false, "query", "*.*");

		for (var file in files) {
			if (file.type == "File" && file.name != "manifest.json") {
				var baseName = extractLegacyBaseName(file.name);
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

		for (var baseName in fileGroups) {
			var group = fileGroups[baseName];

			arraySort(group, function(a, b) {
				return dateCompare(b.dateLastModified, a.dateLastModified);
			});

			if (arrayLen(group) > arguments.keep) {
				if (arguments.dryRun) {
					print.boldLine("Analyzing #baseName#...").toConsole();
				} else {
					print.boldLine("Cleaning #baseName#...").toConsole();
				}

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

		printCleanSummary(deletedCount, freedSpace, arguments.dryRun);
	}

	/**
	 * Print clean operation summary
	 */
	private void function printCleanSummary(
		required numeric deletedCount,
		required numeric freedSpace,
		required boolean dryRun
	) {
		detailOutput.line();

		if (arguments.dryRun) {
			print.yellowLine("Dry run complete. No files were deleted.").toConsole();
			detailOutput.output("Would delete #arguments.deletedCount# files");
			detailOutput.output("Would free #formatFileSize(arguments.freedSpace)# of disk space");
		} else if (arguments.deletedCount > 0) {
			detailOutput.success("Asset cleaning complete!");
			print.greenLine("Deleted #arguments.deletedCount# old asset files").toConsole();
			print.greenLine("Freed #formatFileSize(arguments.freedSpace)# of disk space").toConsole();
		} else {
			detailOutput.statusWarning("No old assets found to clean.");
		}
	}

	/**
	 * Extract base name from a Vite-generated asset filename
	 * Vite uses the pattern: name-HASH.ext (e.g. "main-BRBhM4rY.js")
	 */
	private string function extractViteBaseName(required string fileName) {
		var name = arguments.fileName;
		// Remove extension
		name = reReplace(name, "\.[^.]+$", "", "one");
		// Remove Vite hash (dash followed by alphanumeric hash)
		name = reReplace(name, "-[A-Za-z0-9_-]{7,}$", "", "one");
		return name;
	}

	/**
	 * Extract base name from a legacy compiled asset filename
	 * Legacy uses the pattern: name-MD5HASH.min.ext (e.g. "app-a1b2c3d4.min.js")
	 */
	private string function extractLegacyBaseName(required string fileName) {
		var name = arguments.fileName;
		name = reReplace(name, "\.(min\.)?(js|css)$", "", "one");
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
