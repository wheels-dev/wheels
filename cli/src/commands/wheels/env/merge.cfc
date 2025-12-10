/**
 * Merges multiple .env files together
 * 
 * Examples:
 * {code:bash}
 * wheels env merge .env.defaults .env.local --output=.env
 * wheels env merge .env .env.production --output=.env.merged
 * wheels env merge base.env override.env --dryRun
 * {code}
 */
component extends="commandbox.modules.wheels-cli.commands.wheels.base" {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * @source1.hint First source .env file to merge
	 * @source2.hint Second source .env file to merge
	 * @output.hint Output file name
	 * @dryRun.hint Show what would be merged without writing
	 **/
	function run(
		required string source1,
		required string source2,
		string output = ".env.merge",
		boolean dryRun = false
	) {
		requireWheelsApp(getCWD());
		// Reconstruct arguments to handle -- prefixed options
		arguments = reconstructArgs(arguments);
		local.sourceFiles = [arguments.source1, arguments.source2];
		
		// Check for additional positional arguments (source3, source4, etc.)
		local.i = 3;
		while (StructKeyExists(arguments, "source" & local.i)) {
			ArrayAppend(local.sourceFiles, arguments["source" & local.i]);
			local.i++;
		}

		if (ArrayLen(local.sourceFiles) < 2) {
			detailOutput.error("At least two source files are required. Usage: wheels env merge file1 file2 [--output=filename] [--dryRun]");
			return;
		}

		// Validate all source files exist
		for (local.file in local.sourceFiles) {
			if (!FileExists(ResolvePath(local.file))) {
				detailOutput.error("Source file not found: #local.file#");
				return;
			}
		}

		print.line("Merging environment files...").toConsole();
		detailOutput.line();
		detailOutput.subHeader("Source Files");
		for (local.i = 1; local.i <= ArrayLen(local.sourceFiles); local.i++) {
			detailOutput.metric("#local.i#.", local.sourceFiles[local.i]);
		}
		detailOutput.line();

		// Merge the files
		local.merged = mergeEnvFiles(local.sourceFiles);

		// Display the result
		if (arguments.dryRun) {
			displayMergedResult(local.merged, true);
		} else {
			// Write the merged file
			writeMergedFile(arguments.output, local.merged);
			detailOutput.separator();
			detailOutput.statusSuccess("Merged #ArrayLen(local.sourceFiles)# files into #arguments.output#");
			detailOutput.metric("Total variables", "#StructCount(local.merged.vars)#");
			
			// Show conflicts if any
			if (ArrayLen(local.merged.conflicts)) {
				detailOutput.line();
				detailOutput.statusWarning("Conflicts resolved (later files take precedence):");
				for (local.conflict in local.merged.conflicts) {
					detailOutput.output("  - #local.conflict#", true);
				}
			}
		}
	}

	private struct function mergeEnvFiles(required array files) {
		local.result = {
			vars: {},
			conflicts: [],
			sources: {}
		};

		// Process each file in order
		for (local.i = 1; local.i <= ArrayLen(arguments.files); local.i++) {
			local.file = arguments.files[local.i];
			local.content = FileRead(ResolvePath(local.file));
			local.fileVars = {};

			// Parse the file
			if (IsJSON(local.content)) {
				local.fileVars = DeserializeJSON(local.content);
			} else {
				// Parse as properties file
				local.lines = ListToArray(local.content, Chr(10));
				for (local.line in local.lines) {
					local.trimmedLine = Trim(local.line);
					// Skip empty lines and comments
					if (Len(local.trimmedLine) && Left(local.trimmedLine, 1) != "##" && Find("=", local.trimmedLine)) {
						local.key = Trim(ListFirst(local.trimmedLine, "="));
						local.value = Trim(ListRest(local.trimmedLine, "="));
						// Handle values that might contain = signs
						if (local.value == "") {
							local.value = ListRest(local.line, "=");
						}
						local.fileVars[local.key] = local.value;
					}
				}
			}

			// Merge variables
			for (local.key in local.fileVars) {
				// Check for conflicts
				if (StructKeyExists(local.result.vars, local.key)) {
					if (local.result.vars[local.key] != local.fileVars[local.key]) {
						ArrayAppend(local.result.conflicts, 
							"#local.key#: '#local.result.vars[local.key]#' (#local.result.sources[local.key]#) -> '#local.fileVars[local.key]#' (#local.file#)"
						);
					}
				}
				
				// Set or update the value
				local.result.vars[local.key] = local.fileVars[local.key];
				local.result.sources[local.key] = local.file;
			}
		}

		return local.result;
	}

	private void function displayMergedResult(required struct merged, required boolean dryRun) {
		detailOutput.header("Merged Result #arguments.dryRun ? '(DRY RUN)' : ''#");
		detailOutput.metric("Total variables", "#StructCount(arguments.merged.vars)#");
		if (ArrayLen(arguments.merged.conflicts)) {
			detailOutput.metric("Conflicts resolved", "#ArrayLen(arguments.merged.conflicts)#");
		}
		detailOutput.line();

		// Group variables by prefix
		local.grouped = {};
		local.ungrouped = [];
		
		for (local.key in arguments.merged.vars) {
			if (Find("_", local.key)) {
				local.prefix = ListFirst(local.key, "_");
				if (!StructKeyExists(local.grouped, local.prefix)) {
					local.grouped[local.prefix] = [];
				}
				ArrayAppend(local.grouped[local.prefix], {
					key: local.key,
					value: arguments.merged.vars[local.key],
					source: arguments.merged.sources[local.key]
				});
			} else {
				ArrayAppend(local.ungrouped, {
					key: local.key,
					value: arguments.merged.vars[local.key],
					source: arguments.merged.sources[local.key]
				});
			}
		}

		// Sort and display grouped variables
		local.prefixes = StructKeyArray(local.grouped);
		ArraySort(local.prefixes, "textnocase");
		
		for (local.prefix in local.prefixes) {
			detailOutput.subHeader("#local.prefix# Variables");
			// Sort variables within group
			ArraySort(local.grouped[local.prefix], function(a, b) {
				return CompareNoCase(a.key, b.key);
			});
			
			for (local.var in local.grouped[local.prefix]) {
				local.displayValue = local.var.value;
				// Mask sensitive values
				if (FindNoCase("password", local.var.key) || FindNoCase("secret", local.var.key) || 
					FindNoCase("key", local.var.key) || FindNoCase("token", local.var.key)) {
					local.displayValue = "***MASKED***";
				}
				detailOutput.metric(local.var.key, local.displayValue);
				detailOutput.output("  (from #local.var.source#)", true);
			}
			detailOutput.line();
		}

		// Display ungrouped variables
		if (ArrayLen(local.ungrouped)) {
			detailOutput.subHeader("Other Variables");
			// Sort ungrouped variables
			ArraySort(local.ungrouped, function(a, b) {
				return CompareNoCase(a.key, b.key);
			});
			
			for (local.var in local.ungrouped) {
				local.displayValue = local.var.value;
				// Mask sensitive values
				if (FindNoCase("password", local.var.key) || FindNoCase("secret", local.var.key) || 
					FindNoCase("key", local.var.key) || FindNoCase("token", local.var.key)) {
					local.displayValue = "***MASKED***";
				}
				detailOutput.metric(local.var.key, local.displayValue);
				detailOutput.output("  (from #local.var.source#)", true);
			}
		}
		
		// Show conflicts if any
		if (ArrayLen(arguments.merged.conflicts)) {
			detailOutput.line();
			detailOutput.statusWarning("Conflict Resolution Details:");
			for (local.conflict in arguments.merged.conflicts) {
				detailOutput.output("  - #local.conflict#", true);
			}
		}
	}

	private void function writeMergedFile(required string filename, required struct merged) {
		local.lines = [
			"## Merged Environment Configuration",
			"## Generated by wheels env merge command",
			"## Date: #DateTimeFormat(Now(), 'yyyy-mm-dd HH:nn:ss')#",
			""
		];

		// Group variables by prefix for better organization
		local.grouped = {};
		local.ungrouped = [];
		
		for (local.key in arguments.merged.vars) {
			if (Find("_", local.key)) {
				local.prefix = ListFirst(local.key, "_");
				if (!StructKeyExists(local.grouped, local.prefix)) {
					local.grouped[local.prefix] = [];
				}
				ArrayAppend(local.grouped[local.prefix], local.key);
			} else {
				ArrayAppend(local.ungrouped, local.key);
			}
		}

		// Sort keys within each group
		for (local.prefix in local.grouped) {
			ArraySort(local.grouped[local.prefix], "textnocase");
		}
		ArraySort(local.ungrouped, "textnocase");

		// Write grouped variables
		local.prefixes = StructKeyArray(local.grouped);
		ArraySort(local.prefixes, "textnocase");
		
		for (local.prefix in local.prefixes) {
			ArrayAppend(local.lines, "## #local.prefix# Configuration");
			for (local.key in local.grouped[local.prefix]) {
				ArrayAppend(local.lines, "#local.key#=#arguments.merged.vars[local.key]#");
			}
			ArrayAppend(local.lines, "");
		}

		// Write ungrouped variables
		if (ArrayLen(local.ungrouped)) {
			ArrayAppend(local.lines, "## Other Configuration");
			for (local.key in local.ungrouped) {
				ArrayAppend(local.lines, "#local.key#=#arguments.merged.vars[local.key]#");
			}
		}

		// Write the file
		try {
			FileWrite(ResolvePath(arguments.filename), ArrayToList(local.lines, Chr(10)));
			detailOutput.create("merged environment file: #arguments.filename#");
		} catch (any e) {
			detailOutput.error("Failed to write merged file: #e.message#");
			throw(type="FileWriteError", message="Failed to write merged file: #e.message#");
		}
	}

}