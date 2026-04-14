/**
 * Compile assets for production
 *
 * When a Vite config is detected (vite.config.js/ts/mjs), runs `npx vite build` to produce
 * fingerprinted assets and a manifest for the viteAsset() view helper. Falls back to the
 * legacy pipeline (regex minification + MD5 fingerprinting) when Vite is not configured.
 *
 * {code:bash}
 * wheels assets:precompile
 * wheels assets:precompile --mode=production
 * wheels assets:precompile --legacy
 * wheels assets:precompile --force --environment=staging
 * {code}
 **/
component extends="../base" {

	property name="FileSystemUtil" inject="FileSystem";
	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	// CommandBox metadata
	this.aliases = [ "precompile" ];
	this.parameters = [
		{ name="force", type="boolean", required=false, default=false, hint="Force recompilation of all assets" },
		{ name="environment", type="string", required=false, default="production", hint="Target environment for compilation" },
		{ name="mode", type="string", required=false, default="production", hint="Vite build mode (production, development, staging)" },
		{ name="legacy", type="boolean", required=false, default=false, hint="Force legacy pipeline even if Vite is configured" }
	];

	/**
	 * Compile and optimize assets for production deployment
	 *
	 * When a Vite config file is present, runs Vite build to produce optimized,
	 * fingerprinted assets with a manifest. Without Vite, falls back to the legacy
	 * pipeline that minifies JS/CSS and generates cache-busted filenames.
	 *
	 * @force Force recompilation of all assets, even if unchanged
	 * @environment Target environment (production, staging, development, test, maintenance, or aliases like prod, dev, stage)
	 * @mode Vite build mode passed to --mode flag (default: production)
	 * @legacy Force the legacy minification pipeline even when a Vite config exists
	 **/
	function run(
		boolean force = false,
		string environment = "production",
		string mode = "production",
		boolean legacy = false
	) {
		try {
			requireWheelsApp(getCWD());
			arguments = reconstructArgs(
				argStruct = arguments,
				allowedValues = {
					environment: ["production", "staging", "development", "test", "maintenance", "prod", "dev", "stage"]
				}
			);

			arguments.environment = normalizeEnvironment(arguments.environment);

			var appPath = fileSystemUtil.resolvePath("");

			// Determine pipeline: Vite or legacy
			if (!arguments.legacy && hasViteConfig(appPath)) {
				runViteBuild(appPath, arguments.mode, arguments.force);
			} else {
				if (!arguments.legacy) {
					detailOutput.output("No Vite config found, using legacy asset pipeline.");
					detailOutput.line();
				}
				runLegacyPipeline(appPath, arguments.force, arguments.environment);
			}

		} catch (any e) {
			detailOutput.error("#e.message#");
			setExitCode(1);
		}
	}

	// ─── Vite Pipeline ──────────────────────────────────────────────────────

	/**
	 * Check if a Vite config file exists in the project root
	 */
	private boolean function hasViteConfig(required string appPath) {
		var configFiles = ["vite.config.js", "vite.config.ts", "vite.config.mjs"];
		for (var cf in configFiles) {
			if (fileExists(arguments.appPath & cf)) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Find the Vite config filename
	 */
	private string function getViteConfigFile(required string appPath) {
		var configFiles = ["vite.config.js", "vite.config.ts", "vite.config.mjs"];
		for (var cf in configFiles) {
			if (fileExists(arguments.appPath & cf)) {
				return cf;
			}
		}
		return "";
	}

	/**
	 * Run the Vite build pipeline
	 */
	private void function runViteBuild(
		required string appPath,
		required string mode,
		required boolean force
	) {
		var configFile = getViteConfigFile(arguments.appPath);
		detailOutput.output("Vite asset pipeline");
		detailOutput.output("Config: #configFile#");
		detailOutput.output("Mode:   #arguments.mode#");
		detailOutput.line();

		// Verify node_modules exists
		if (!directoryExists(arguments.appPath & "node_modules")) {
			detailOutput.error("node_modules not found. Run 'npm install' first.");
			setExitCode(1);
			return;
		}

		// Clean previous build if forcing
		if (arguments.force) {
			var buildDir = arguments.appPath & "public/build";
			if (directoryExists(buildDir)) {
				directoryDelete(buildDir, true);
				detailOutput.output("Cleaned previous build output.");
			}
		}

		// Build the vite command
		var viteCmd = resolveViteBin(arguments.appPath) & " build --mode " & arguments.mode;

		detailOutput.output("Running: #viteCmd#");
		detailOutput.line();

		// Execute via ProcessBuilder to stream output
		var result = runShellCommand(viteCmd, arguments.appPath);

		if (!result.success) {
			detailOutput.line();
			detailOutput.error("Vite build failed (exit code #result.exitCode#)");
			if (len(result.error)) {
				detailOutput.error(result.error);
			}
			setExitCode(1);
			return;
		}

		// Print build output
		if (len(result.output)) {
			print.line(result.output).toConsole();
		}

		// Validate manifest was generated
		var manifestPath = arguments.appPath & "public/build/.vite/manifest.json";
		if (!fileExists(manifestPath)) {
			// Try legacy manifest location
			manifestPath = arguments.appPath & "public/build/manifest.json";
		}

		if (!fileExists(manifestPath)) {
			detailOutput.line();
			detailOutput.error("Vite build completed but no manifest found.");
			detailOutput.error("Expected at: public/build/.vite/manifest.json");
			detailOutput.output("Ensure your vite.config has build.manifest enabled.");
			setExitCode(1);
			return;
		}

		// Read and report manifest contents
		var manifest = deserializeJSON(fileRead(manifestPath));
		var entrypoints = [];
		var totalFiles = structCount(manifest);

		for (var key in manifest) {
			if (structKeyExists(manifest[key], "isEntry") && manifest[key].isEntry) {
				arrayAppend(entrypoints, key);
			}
		}

		detailOutput.line();
		detailOutput.statusSuccess("Vite build complete!");
		detailOutput.output("Manifest: #manifestPath#", true);
		detailOutput.output("Assets:   #totalFiles# files in manifest", true);

		if (arrayLen(entrypoints)) {
			detailOutput.line();
			detailOutput.output("Entrypoints:");
			for (var ep in entrypoints) {
				var entry = manifest[ep];
				print.greenLine("  #ep# -> #entry.file#").toConsole();
				if (structKeyExists(entry, "css") && isArray(entry.css)) {
					for (var cssFile in entry.css) {
						print.cyanLine("    CSS: #cssFile#").toConsole();
					}
				}
			}
		}

		detailOutput.line();
		detailOutput.output("Assets are ready for deployment.");
		detailOutput.output("Use viteScriptTag() and viteStyleTag() in views to reference built assets.", true);
	}

	/**
	 * Resolve the path to the vite binary. Prefers local node_modules/.bin/vite,
	 * falls back to npx.
	 */
	private string function resolveViteBin(required string appPath) {
		var localBin = arguments.appPath & "node_modules/.bin/vite";
		if (fileExists(localBin)) {
			return localBin;
		}
		return "npx vite";
	}

	/**
	 * Execute a shell command and capture output
	 */
	private struct function runShellCommand(required string command, required string workDir) {
		try {
			var pb = CreateObject("java", "java.lang.ProcessBuilder");
			var cmdArray = ["sh", "-c", arguments.command];
			pb.init(cmdArray);
			pb.directory(CreateObject("java", "java.io.File").init(arguments.workDir));
			pb.redirectErrorStream(false);

			var process = pb.start();

			// Read stdout
			var stdoutReader = CreateObject("java", "java.io.BufferedReader").init(
				CreateObject("java", "java.io.InputStreamReader").init(process.getInputStream())
			);
			var stderrReader = CreateObject("java", "java.io.BufferedReader").init(
				CreateObject("java", "java.io.InputStreamReader").init(process.getErrorStream())
			);

			var outputLines = [];
			var errorLines = [];
			var line = stdoutReader.readLine();
			while (!isNull(line)) {
				arrayAppend(outputLines, line);
				line = stdoutReader.readLine();
			}
			line = stderrReader.readLine();
			while (!isNull(line)) {
				arrayAppend(errorLines, line);
				line = stderrReader.readLine();
			}

			var exitCode = process.waitFor();

			return {
				success: exitCode == 0,
				exitCode: exitCode,
				output: arrayToList(outputLines, chr(10)),
				error: arrayToList(errorLines, chr(10))
			};
		} catch (any e) {
			return {
				success: false,
				exitCode: -1,
				output: "",
				error: e.message
			};
		}
	}

	// ─── Legacy Pipeline ────────────────────────────────────────────────────

	/**
	 * Run the legacy minification pipeline for projects without Vite
	 */
	private void function runLegacyPipeline(
		required string appPath,
		required boolean force,
		required string environment
	) {
		detailOutput.output("Precompiling assets for #arguments.environment# (legacy pipeline)...");
		detailOutput.line();

		var publicDir = arguments.appPath & "public/";
		var jsDir = publicDir & "javascripts";
		var cssDir = publicDir & "stylesheets";
		var imagesDir = publicDir & "images";

		// Create compiled assets directory
		var compiledDir = publicDir & "assets/compiled";
		if (!directoryExists(compiledDir)) {
			directoryCreate(compiledDir);
			detailOutput.output("Created compiled assets directory: #compiledDir#");
		}

		var manifest = {};
		var processedCount = 0;

		// Process JavaScript files
		if (directoryExists(jsDir)) {
			detailOutput.output("Processing JavaScript files...");
			var jsFiles = directoryList(jsDir, true, "query", "*.js");
			for (var file in jsFiles) {
				if (file.type == "File" && !findNoCase(".min.js", file.name)) {
					processedCount += processJavaScriptFile(
						source = file.directory & "/" & file.name,
						target = compiledDir,
						manifest = manifest,
						force = arguments.force,
						environment = arguments.environment
					);
				}
			}
		}

		// Process CSS files
		if (directoryExists(cssDir)) {
			detailOutput.output("Processing CSS files...");
			var cssFiles = directoryList(cssDir, true, "query", "*.css");
			for (var file in cssFiles) {
				if (file.type == "File" && !findNoCase(".min.css", file.name)) {
					processedCount += processCSSFile(
						source = file.directory & "/" & file.name,
						target = compiledDir,
						manifest = manifest,
						force = arguments.force,
						environment = arguments.environment
					);
				}
			}
		}

		// Process image files
		if (directoryExists(imagesDir)) {
			detailOutput.output("Processing image files...");
			var imageFiles = directoryList(imagesDir, true, "query");
			for (var file in imageFiles) {
				if (file.type == "File" && isImageFile(file.name)) {
					processedCount += processImageFile(
						source = file.directory & "/" & file.name,
						target = compiledDir,
						manifest = manifest,
						force = arguments.force
					);
				}
			}
		}

		// Write manifest file
		var manifestPath = compiledDir & "/manifest.json";
		fileWrite(manifestPath, serializeJSON(manifest));
		detailOutput.output("Asset manifest written to: #manifestPath#");

		detailOutput.line();
		detailOutput.statusSuccess("Asset precompilation complete!");
		detailOutput.output("Processed #processedCount# files", true);
		detailOutput.output("Compiled assets location: #compiledDir#", true);
	}

	/**
	 * Process a JavaScript file (legacy pipeline)
	 */
	private numeric function processJavaScriptFile(
		required string source,
		required string target,
		required struct manifest,
		required boolean force,
		required string environment
	) {
		var fileName = getFileFromPath(arguments.source);
		var content = fileRead(arguments.source);
		var hash = hash(content, "MD5");
		var targetFileName = replaceNoCase(fileName, ".js", "-#hash#.min.js");
		var targetPath = arguments.target & "/" & targetFileName;

		if (!arguments.force && fileExists(targetPath)) {
			detailOutput.output("#fileName# (unchanged)");
			arguments.manifest[fileName] = targetFileName;
			return 0;
		}

		content = minifyJavaScript(content, arguments.environment);

		fileWrite(targetPath, content);
		arguments.manifest[fileName] = targetFileName;

		var processType = getProcessingDescription(arguments.environment);
		print.greenLine("#fileName# -> #targetFileName# (#processType#)").toConsole();
		return 1;
	}

	/**
	 * Process a CSS file (legacy pipeline)
	 */
	private numeric function processCSSFile(
		required string source,
		required string target,
		required struct manifest,
		required boolean force,
		required string environment
	) {
		var fileName = getFileFromPath(arguments.source);
		var content = fileRead(arguments.source);
		var hash = hash(content, "MD5");
		var targetFileName = replaceNoCase(fileName, ".css", "-#hash#.min.css");
		var targetPath = arguments.target & "/" & targetFileName;

		if (!arguments.force && fileExists(targetPath)) {
			detailOutput.output("#fileName# (unchanged)");
			arguments.manifest[fileName] = targetFileName;
			return 0;
		}

		content = minifyCSS(content, arguments.environment);

		fileWrite(targetPath, content);
		arguments.manifest[fileName] = targetFileName;

		var processType = getProcessingDescription(arguments.environment);
		print.greenLine("#fileName# -> #targetFileName# (#processType#)").toConsole();
		return 1;
	}

	/**
	 * Process an image file (legacy pipeline)
	 */
	private numeric function processImageFile(
		required string source,
		required string target,
		required struct manifest,
		required boolean force
	) {
		var fileName = getFileFromPath(arguments.source);
		var content = fileReadBinary(arguments.source);
		var hash = hash(toString(toBinary(toBase64(content))), "MD5");
		var extension = listLast(fileName, ".");
		var baseName = listFirst(fileName, ".");
		var targetFileName = "#baseName#-#hash#.#extension#";
		var targetPath = arguments.target & "/" & targetFileName;

		if (!arguments.force && fileExists(targetPath)) {
			detailOutput.output("#fileName# (unchanged)");
			arguments.manifest[fileName] = targetFileName;
			return 0;
		}

		fileCopy(arguments.source, targetPath);
		arguments.manifest[fileName] = targetFileName;

		print.greenLine("#fileName# -> #targetFileName#").toConsole();
		return 1;
	}

	/**
	 * Check if a file is an image
	 */
	private boolean function isImageFile(required string fileName) {
		var imageExtensions = ["jpg", "jpeg", "png", "gif", "svg", "webp", "ico"];
		var extension = lCase(listLast(arguments.fileName, "."));
		return arrayContainsNoCase(imageExtensions, extension);
	}

	/**
	 * Minify JavaScript content based on environment
	 */
	private string function minifyJavaScript(required string content, required string environment) {
		switch(lCase(arguments.environment)) {
			case "development":
				return arguments.content;

			case "staging":
			case "test":
			case "maintenance":
				var result = arguments.content;
				result = reReplace(result, "/\*[\s\S]*?\*/", "", "all");
				result = reReplace(result, "//[^\r\n]*", "", "all");
				result = reReplace(result, "[\r\n]{2,}", chr(10), "all");
				return trim(result);

			case "production":
			default:
				var result = arguments.content;
				result = reReplace(result, "/\*[\s\S]*?\*/", "", "all");
				result = reReplace(result, "//[^\r\n]*", "", "all");
				result = reReplace(result, "[\r\n]+", chr(10), "all");
				result = reReplace(result, "\s+", " ", "all");
				result = reReplace(result, ";\s*}", "}", "all");
				result = reReplace(result, "\s*([{}();,])\s*", "\1", "all");
				return trim(result);
		}
	}

	/**
	 * Minify CSS content based on environment
	 */
	private string function minifyCSS(required string content, required string environment) {
		switch(lCase(arguments.environment)) {
			case "development":
				return arguments.content;

			case "staging":
			case "test":
			case "maintenance":
				var result = arguments.content;
				result = reReplace(result, "/\*[\s\S]*?\*/", "", "all");
				result = reReplace(result, "[\r\n]{2,}", chr(10), "all");
				result = reReplace(result, "\s+", " ", "all");
				return trim(result);

			case "production":
			default:
				var result = arguments.content;
				result = reReplace(result, "/\*[\s\S]*?\*/", "", "all");
				result = reReplace(result, "[\r\n]+", " ", "all");
				result = reReplace(result, "\s+", " ", "all");
				result = reReplace(result, ";\s*}", "}", "all");
				result = reReplace(result, ":\s+", ":", "all");
				result = reReplace(result, "\s*{\s*", "{", "all");
				result = reReplace(result, "\s*}\s*", "}", "all");
				result = reReplace(result, "\s*;\s*", ";", "all");
				result = reReplace(result, "\s*,\s*", ",", "all");
				return trim(result);
		}
	}

	/**
	 * Get processing description for display
	 */
	private string function getProcessingDescription(required string environment) {
		switch(lCase(arguments.environment)) {
			case "development":
				return "unminified";
			case "staging":
			case "test":
			case "maintenance":
				return "lightly minified";
			case "production":
			default:
				return "fully minified";
		}
	}

	/**
	 * Normalize environment aliases to standard names
	 */
	private string function normalizeEnvironment(required string environment) {
		switch(lCase(trim(arguments.environment))) {
			case "dev":
			case "development":
				return "development";
			case "test":
			case "testing":
				return "test";
			case "stage":
			case "staging":
			case "stag":
				return "staging";
			case "maintenance":
			case "maintainance":
				return "maintenance";
			case "prod":
			case "production":
			default:
				return "production";
		}
	}

}
