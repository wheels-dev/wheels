/**
 * Remove all compiled assets
 *
 * Completely removes all compiled assets, manifest files, and build output.
 * Handles both Vite build output (public/build/) and legacy compiled
 * assets (public/assets/compiled/).
 *
 * {code:bash}
 * wheels assets:clobber
 * wheels assets:clobber --force
 * {code}
 **/
component aliases="clobber" extends="../base" {

	property name="FileSystemUtil" inject="FileSystem";
	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * Remove all compiled assets and reset the asset pipeline
	 *
	 * Removes both Vite build output and legacy compiled assets.
	 * Use with caution as this will require full asset recompilation.
	 *
	 * @force Skip confirmation prompt
	 **/
	function run(boolean force = false) {
		requireWheelsApp(getCWD());
		arguments = reconstructArgs(argStruct=arguments);

		var viteBuildDir = fileSystemUtil.resolvePath("public/build");
		var legacyCompiledDir = fileSystemUtil.resolvePath("public/assets/compiled");

		var hasVite = directoryExists(viteBuildDir);
		var hasLegacy = directoryExists(legacyCompiledDir);

		if (!hasVite && !hasLegacy) {
			print.yellowLine("No compiled assets directory found. Nothing to clobber.").toConsole();
			return;
		}

		// Count files to be deleted across both directories
		var fileCount = 0;
		var totalSize = 0;

		if (hasVite) {
			var viteFiles = directoryList(viteBuildDir, true, "query");
			for (var file in viteFiles) {
				if (file.type == "File") {
					fileCount++;
					totalSize += getFileInfo(file.directory & "/" & file.name).size;
				}
			}
		}

		if (hasLegacy) {
			var legacyFiles = directoryList(legacyCompiledDir, true, "query");
			for (var file in legacyFiles) {
				if (file.type == "File") {
					fileCount++;
					totalSize += getFileInfo(file.directory & "/" & file.name).size;
				}
			}
		}

		if (fileCount == 0) {
			print.yellowLine("No compiled assets found. Nothing to clobber.").toConsole();
			return;
		}

		detailOutput.line();
		detailOutput.statusWarning("This will permanently delete:");
		detailOutput.output("  - #fileCount# compiled asset files");
		detailOutput.output("  - #formatFileSize(totalSize)# of disk space");
		if (hasVite) {
			detailOutput.output("  - Vite build output (public/build/)");
		}
		if (hasLegacy) {
			detailOutput.output("  - Legacy compiled assets (public/assets/compiled/)");
		}
		detailOutput.line();
		print.yellowLine("You will need to run 'wheels assets:precompile' to regenerate assets.").toConsole();
		detailOutput.line();

		// Confirm unless forced
		if (!arguments.force) {
			var confirmed = ask("Are you sure you want to delete all compiled assets? [y/N]: ");
			if (lCase(trim(confirmed)) != "y") {
				detailOutput.output("Operation cancelled.");
				return;
			}
		}

		detailOutput.line();
		print.boldLine("Removing compiled assets...").toConsole();

		try {
			if (hasVite) {
				directoryDelete(viteBuildDir, true);
				print.greenLine("Removed Vite build output: public/build/").toConsole();
			}

			if (hasLegacy) {
				directoryDelete(legacyCompiledDir, true);
				directoryCreate(legacyCompiledDir);
				print.greenLine("Removed legacy compiled assets: public/assets/compiled/").toConsole();
			}

			detailOutput.line();
			detailOutput.statusSuccess("Asset clobber complete!");
			print.greenLine("Deleted #fileCount# files").toConsole();
			print.greenLine("Freed #formatFileSize(totalSize)# of disk space").toConsole();
			detailOutput.line();
			print.yellowLine("Run 'wheels assets:precompile' before deploying to production.").toConsole();
		} catch (any e) {
			detailOutput.statusFailed("Failed to clobber assets");
			detailOutput.error("Error removing compiled assets: #e.message#");
			return;
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
