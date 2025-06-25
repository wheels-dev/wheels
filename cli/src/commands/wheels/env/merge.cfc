/**
 * Merges multiple .env files together
 * 
 * Examples:
 * {code:bash}
 * wheels env merge .env.defaults .env.local --output=.env
 * wheels env merge .env .env.production --output=.env.merged
 * wheels env merge base.env override.env --dry-run
 * {code}
 */
component extends="commandbox.modules.wheels-cli.commands.wheels.base" {

	/**
	 * @source.hint Source .env files to merge (in order of precedence)
	 * @output.hint Output file name (defaults to .env.merged)
	 * @dry-run.hint Show what would be merged without writing
	 **/
	function run(
		required string source,
		string output = ".env.merged",
		boolean dryRun = false
	) {

		// Collect all source files from arguments
		local.sourceFiles = [];
		
		// Add the required source parameter
		ArrayAppend(local.sourceFiles, arguments.source);
		
		// Check for additional positional arguments
		local.i = 2;
		while (StructKeyExists(arguments, local.i)) {
			if (!Find("--", arguments[local.i])) {
				ArrayAppend(local.sourceFiles, arguments[local.i]);
			}
			local.i++;
		}

		if (ArrayLen(local.sourceFiles) < 2) {
			error("At least two source files are required. Usage: wheels env merge file1 file2 [file3...] --output=merged.env");
		}

		// Validate all source files exist
		for (local.file in local.sourceFiles) {
			if (!FileExists(ResolvePath(local.file))) {
				error("Source file not found: #local.file#");
			}
		}

		print.line();
		print.boldLine("Merging environment files:");
		for (local.i = 1; local.i <= ArrayLen(local.sourceFiles); local.i++) {
			print.line("  #local.i#. #local.sourceFiles[local.i]#");
		}
		print.line();

		// Merge the files
		local.merged = mergeEnvFiles(local.sourceFiles);

		// Display the result
		if (arguments.dryRun) {
			displayMergedResult(local.merged, true);
		} else {
			// Write the merged file
			writeMergedFile(arguments.output, local.merged);
			print.line();
			print.greenLine("✓ Merged #ArrayLen(local.sourceFiles)# files into #arguments.output#");
			print.line("  Total variables: #StructCount(local.merged.vars)#");
			
			// Show conflicts if any
			if (ArrayLen(local.merged.conflicts)) {
				print.line();
				print.yellowLine("Conflicts resolved (later files take precedence):");
				for (local.conflict in local.merged.conflicts) {
					print.line("  #local.conflict#");
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
					if (Len(local.trimmedLine) && Left(local.trimmedLine, 1) != "##" && Find("=", local.trimmedLine)) {
						local.key = Trim(ListFirst(local.trimmedLine, "="));
						local.value = Trim(ListRest(local.trimmedLine, "="));
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
							"#local.key#: '#local.result.vars[local.key]#' (#local.result.sources[local.key]#) → '#local.fileVars[local.key]#' (#local.file#)"
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
		print.boldLine("Merged result (#arguments.dryRun ? 'DRY RUN' : ''#):");
		print.line();

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

		// Display grouped variables
		for (local.prefix in local.grouped) {
			print.boldLine("#local.prefix# Variables:");
			for (local.var in local.grouped[local.prefix]) {
				local.displayValue = local.var.value;
				// Mask sensitive values
				if (FindNoCase("password", local.var.key) || FindNoCase("secret", local.var.key) || 
					FindNoCase("key", local.var.key) || FindNoCase("token", local.var.key)) {
					local.displayValue = "***MASKED***";
				}
				print.line("  #local.var.key# = #local.displayValue# (from #local.var.source#)");
			}
			print.line();
		}

		// Display ungrouped variables
		if (ArrayLen(local.ungrouped)) {
			print.boldLine("Other Variables:");
			for (local.var in local.ungrouped) {
				local.displayValue = local.var.value;
				// Mask sensitive values
				if (FindNoCase("password", local.var.key) || FindNoCase("secret", local.var.key) || 
					FindNoCase("key", local.var.key) || FindNoCase("token", local.var.key)) {
					local.displayValue = "***MASKED***";
				}
				print.line("  #local.var.key# = #local.displayValue# (from #local.var.source#)");
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
		} catch (any e) {
			error("Failed to write merged file: #e.message#");
		}
	}

}