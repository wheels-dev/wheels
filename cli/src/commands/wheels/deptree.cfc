/**
 * Show dependency tree for the Wheels application
 *
 * {code:bash}
 * wheels deptree
 * wheels deptree depth=2
 * wheels deptree production=true
 * {code}
 */
component extends="base" {

	property name="packageService" inject="PackageService";

	/**
	 * @depth Maximum depth to traverse (default: 3)
	 * @production Only show production dependencies
	 * @format Output format (tree or list)
	 * @help Display the dependency tree for your application
	 */
	public void function run(
		numeric depth = 3,
		boolean production = false,
		string format = "tree"
	) {
		local.appPath = getCWD();
		
		// Check for box.json
		local.boxJsonPath = local.appPath & "/box.json";
		if (!FileExists(local.boxJsonPath)) {
			error("No box.json found. This command requires a box.json file.");
			return;
		}
		
		try {
			local.boxJson = DeserializeJSON(FileRead(local.boxJsonPath));
			
			print.line();
			print.boldGreenLine("Application Dependencies");
			print.line(RepeatString("=", 70));
			
			// Display app info
			print.greenLine("Project: " & (local.boxJson.name ?: "Unknown"));
			if (StructKeyExists(local.boxJson, "version")) {
				print.greenLine("Version: " & local.boxJson.version);
			}
			print.line();
			
			// Get dependencies
			local.dependencies = {};
			
			if (!arguments.production) {
				// Include both dependencies and devDependencies
				if (StructKeyExists(local.boxJson, "dependencies")) {
					StructAppend(local.dependencies, local.boxJson.dependencies);
				}
				if (StructKeyExists(local.boxJson, "devDependencies")) {
					StructAppend(local.dependencies, local.boxJson.devDependencies);
				}
			} else {
				// Only production dependencies
				if (StructKeyExists(local.boxJson, "dependencies")) {
					local.dependencies = local.boxJson.dependencies;
				}
			}
			
			if (StructIsEmpty(local.dependencies)) {
				print.yellowLine("No dependencies found.");
				return;
			}
			
			// Display dependencies based on format
			if (arguments.format == "tree") {
				displayDependencyTree(local.dependencies, arguments.depth, local.appPath);
			} else {
				displayDependencyList(local.dependencies, local.appPath);
			}
			
			// Summary
			print.line();
			print.line(RepeatString("=", 70));
			
			local.prodCount = StructKeyExists(local.boxJson, "dependencies") ? StructCount(local.boxJson.dependencies) : 0;
			local.devCount = StructKeyExists(local.boxJson, "devDependencies") ? StructCount(local.boxJson.devDependencies) : 0;
			
			print.greenLine("Total: " & local.prodCount & " production, " & local.devCount & " development dependencies");
			
			// Check for outdated packages
			checkOutdatedPackages(local.dependencies);
			
		} catch (any e) {
			error("Error reading dependencies: " & e.message);
			if (StructKeyExists(e, "detail") && Len(e.detail)) {
				error("Details: " & e.detail);
			}
		}
	}

	private void function displayDependencyTree(
		required struct dependencies,
		required numeric maxDepth,
		required string appPath,
		numeric currentDepth = 0,
		string prefix = ""
	) {
		local.depNames = StructKeyArray(arguments.dependencies);
		ArraySort(local.depNames, "textnocase");
		
		for (local.i = 1; local.i <= ArrayLen(local.depNames); local.i++) {
			local.depName = local.depNames[local.i];
			local.version = arguments.dependencies[local.depName];
			local.isLast = (local.i == ArrayLen(local.depNames));
			
			// Display the dependency
			local.branch = local.isLast ? "└── " : "├── ";
			local.info = getDependencyInfo(local.depName, local.version, arguments.appPath);
			
			print.text(arguments.prefix & local.branch);
			print.boldText(local.depName);
			print.text(" @ " & local.version);
			
			if (local.info.installed) {
				print.greenText(" [installed");
				if (Len(local.info.installedVersion)) {
					print.greenText(": " & local.info.installedVersion);
				}
				print.greenText("]");
			} else {
				print.redText(" [not installed]");
			}
			
			print.line("");
			
			// Display sub-dependencies if within depth limit
			if (arguments.currentDepth < arguments.maxDepth - 1 && local.info.installed && !StructIsEmpty(local.info.dependencies)) {
				local.newPrefix = arguments.prefix & (local.isLast ? "    " : "│   ");
				displayDependencyTree(
					local.info.dependencies,
					arguments.maxDepth,
					arguments.appPath,
					arguments.currentDepth + 1,
					local.newPrefix
				);
			}
		}
	}

	private void function displayDependencyList(
		required struct dependencies,
		required string appPath
	) {
		// Header
		print.text(PadRight("Package", 30));
		print.text(PadRight("Required", 15));
		print.text(PadRight("Installed", 15));
		print.line("Status");
		print.line(RepeatString("-", 75));
		
		local.depNames = StructKeyArray(arguments.dependencies);
		ArraySort(local.depNames, "textnocase");
		
		for (local.depName in local.depNames) {
			local.version = arguments.dependencies[local.depName];
			local.info = getDependencyInfo(local.depName, local.version, arguments.appPath);
			
			print.text(PadRight(local.depName, 30));
			print.text(PadRight(local.version, 15));
			print.text(PadRight(local.info.installedVersion ?: "N/A", 15));
			
			if (local.info.installed) {
				print.greenLine("Installed");
			} else {
				print.redLine("Missing");
			}
		}
	}

	private struct function getDependencyInfo(
		required string name,
		required string version,
		required string appPath
	) {
		local.info = {
			installed = false,
			installedVersion = "",
			dependencies = {}
		};
		
		// Check if module is installed
		local.modulePath = arguments.appPath & "/modules/" & arguments.name;
		if (DirectoryExists(local.modulePath)) {
			local.info.installed = true;
			
			// Try to get installed version
			local.moduleBoxJson = local.modulePath & "/box.json";
			if (FileExists(local.moduleBoxJson)) {
				try {
					local.moduleJson = DeserializeJSON(FileRead(local.moduleBoxJson));
					if (StructKeyExists(local.moduleJson, "version")) {
						local.info.installedVersion = local.moduleJson.version;
					}
					
					// Get sub-dependencies
					if (StructKeyExists(local.moduleJson, "dependencies")) {
						local.info.dependencies = local.moduleJson.dependencies;
					}
				} catch (any e) {
					// Continue
				}
			}
		}
		
		return local.info;
	}

	private void function checkOutdatedPackages(required struct dependencies) {
		local.outdated = [];
		
		for (local.depName in arguments.dependencies) {
			local.required = arguments.dependencies[local.depName];
			
			// Skip if it's a specific version or local path
			if (Left(local.required, 1) == "^" || Left(local.required, 1) == "~" || Find("*", local.required)) {
				// Could check ForgeBox for newer versions, but that would require API calls
				// For now, just note that we could check
			}
		}
		
		if (ArrayLen(local.outdated)) {
			print.line();
			print.yellowLine("Outdated packages found:");
			for (local.pkg in local.outdated) {
				print.yellowLine("  • " & local.pkg);
			}
			print.line();
			print.cyanLine("Run 'box update' to update packages");
		}
	}

	private string function PadRight(required string text, required numeric width) {
		if (Len(arguments.text) >= arguments.width) {
			return Left(arguments.text, arguments.width - 1) & " ";
		}
		return arguments.text & RepeatString(" ", arguments.width - Len(arguments.text));
	}

}