/**
 * Initialize Vite asset pipeline for a Wheels application
 *
 * Sets up Vite as the asset bundler with Hot Module Replacement (HMR) and
 * a dev server proxy for seamless development alongside CommandBox/Lucee.
 *
 * Creates:
 *   - vite.config.js      — Build settings and dev server proxy
 *   - package.json        — Node dependencies (Vite)
 *   - src/main.js         — JavaScript entry point
 *   - src/main.css        — CSS entry point
 *
 * {code:bash}
 * wheels assets:init
 * wheels assets:init --serverPort=3000
 * wheels assets:init --vitePort=3001
 * wheels assets:init --force
 * {code}
 **/
component extends="../base" {

	property name="FileSystemUtil" inject="FileSystem";
	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * Initialize Vite asset pipeline
	 *
	 * @serverPort The port your CommandBox/Lucee server runs on (default: auto-detect from server.json, fallback 8080)
	 * @vitePort The port for the Vite dev server (default: 5173)
	 * @force Overwrite existing files without prompting
	 * @skipInstall Skip running npm install after setup
	 **/
	function run(
		numeric serverPort = 0,
		numeric vitePort = 5173,
		boolean force = false,
		boolean skipInstall = false
	) {
		try {
			requireWheelsApp(getCWD());
			arguments = reconstructArgs(
				argStruct = arguments,
				numericRanges = {
					serverPort: {min: 0, max: 65535},
					vitePort: {min: 1, max: 65535}
				}
			);

			detailOutput.header("Initializing Vite Asset Pipeline");

			// Auto-detect server port from server.json if not specified
			if (arguments.serverPort == 0) {
				arguments.serverPort = detectServerPort();
			}

			var appRoot = getCWD();
			var filesCreated = 0;

			// Create vite.config.js
			filesCreated += writeConfigFile(
				source = "ViteConfig.txt",
				target = appRoot & "vite.config.js",
				replacements = {
					"|vitePort|": arguments.vitePort,
					"|serverPort|": arguments.serverPort
				},
				force = arguments.force
			);

			// Create package.json (only if it doesn't exist — don't overwrite user's deps)
			var packageJsonPath = appRoot & "package.json";
			if (!fileExists(packageJsonPath) || arguments.force) {
				filesCreated += writeConfigFile(
					source = "VitePackageJSON.txt",
					target = packageJsonPath,
					force = arguments.force
				);
			} else {
				// package.json exists — check if vite is already a dependency
				var existingPkg = deserializeJSON(fileRead(packageJsonPath));
				var hasVite = false;
				if (structKeyExists(existingPkg, "devDependencies") && structKeyExists(existingPkg.devDependencies, "vite")) {
					hasVite = true;
				}
				if (structKeyExists(existingPkg, "dependencies") && structKeyExists(existingPkg.dependencies, "vite")) {
					hasVite = true;
				}
				if (!hasVite) {
					detailOutput.output("package.json exists — adding vite to devDependencies");
					if (!structKeyExists(existingPkg, "devDependencies")) {
						existingPkg.devDependencies = {};
					}
					existingPkg.devDependencies["vite"] = "^6.0.0";
					fileWrite(packageJsonPath, serializeJSON(existingPkg));
					detailOutput.update("package.json", true);
					filesCreated++;
				} else {
					detailOutput.identical("package.json (vite already present)", true);
				}
			}

			// Create src/ directory and entry files
			var srcDir = appRoot & "src/";
			if (!directoryExists(srcDir)) {
				directoryCreate(srcDir);
				detailOutput.create("src/", true);
			}

			filesCreated += writeConfigFile(
				source = "ViteMainJS.txt",
				target = srcDir & "main.js",
				force = arguments.force
			);

			filesCreated += writeConfigFile(
				source = "ViteMainCSS.txt",
				target = srcDir & "main.css",
				force = arguments.force
			);

			// Add build/ to .gitignore if not already there
			addToGitignore(appRoot, "public/build/");

			detailOutput.line();

			if (filesCreated == 0) {
				detailOutput.statusWarning("Vite is already configured. Use --force to overwrite.");
				return;
			}

			detailOutput.success("Vite asset pipeline initialized! (#filesCreated# files created)");
			detailOutput.line();

			// Run npm install if not skipped
			if (!arguments.skipInstall) {
				detailOutput.output("Installing Node dependencies...");
				detailOutput.line();
				command("!npm install").run();
				detailOutput.line();
			}

			// Show next steps
			var nextSteps = [];
			if (arguments.skipInstall) {
				arrayAppend(nextSteps, "Install dependencies: npm install");
			}
			arrayAppend(nextSteps, "Start CommandBox server: server start");
			arrayAppend(nextSteps, "Start Vite dev server: npm run dev");
			arrayAppend(nextSteps, "Add to your layout (app/views/layout.cfm):");
			arrayAppend(nextSteps, "  ##viteScriptTag(""src/main.js"")##");
			arrayAppend(nextSteps, "Build for production: npm run build");

			detailOutput.nextSteps(nextSteps);

			detailOutput.line();
			detailOutput.output("Development workflow:");
			detailOutput.output("  Option A: Open http://localhost:#arguments.serverPort# (CommandBox serves pages, Vite serves assets)", true);
			detailOutput.output("  Option B: Open http://localhost:#arguments.vitePort# (Vite proxies everything — single URL)", true);

		} catch (any e) {
			detailOutput.error("#e.message#");
			setExitCode(1);
		}
	}

	/**
	 * Detect the CommandBox server port from server.json
	 */
	private numeric function detectServerPort() {
		var serverJsonPath = getCWD() & "server.json";
		if (fileExists(serverJsonPath)) {
			try {
				var serverConfig = deserializeJSON(fileRead(serverJsonPath));
				// Check web.http.port (standard location)
				if (
					structKeyExists(serverConfig, "web")
					&& structKeyExists(serverConfig.web, "http")
					&& structKeyExists(serverConfig.web.http, "port")
				) {
					var port = val(serverConfig.web.http.port);
					if (port > 0) {
						detailOutput.output("Detected CommandBox port #port# from server.json");
						return port;
					}
				}
				// Check web.port (alternative location)
				if (
					structKeyExists(serverConfig, "web")
					&& structKeyExists(serverConfig.web, "port")
				) {
					var port = val(serverConfig.web.port);
					if (port > 0) {
						detailOutput.output("Detected CommandBox port #port# from server.json");
						return port;
					}
				}
			} catch (any e) {
				// Ignore parse errors, fall through to default
			}
		}
		detailOutput.output("Using default CommandBox port 8080");
		return 8080;
	}

	/**
	 * Write a template file to the target path
	 */
	private numeric function writeConfigFile(
		required string source,
		required string target,
		struct replacements = {},
		required boolean force
	) {
		if (fileExists(arguments.target) && !arguments.force) {
			detailOutput.identical(getFileFromPath(arguments.target), true);
			return 0;
		}

		var content = fileRead(getTemplate("/" & arguments.source));

		// Apply token replacements
		for (var token in arguments.replacements) {
			content = replaceNoCase(content, token, arguments.replacements[token], "all");
		}

		fileWrite(arguments.target, content);
		detailOutput.create(getFileFromPath(arguments.target), true);
		return 1;
	}

	/**
	 * Add an entry to .gitignore if not already present
	 */
	private void function addToGitignore(required string appRoot, required string entry) {
		var gitignorePath = arguments.appRoot & ".gitignore";
		var content = "";

		if (fileExists(gitignorePath)) {
			content = fileRead(gitignorePath);
			// Check if entry already exists
			if (findNoCase(arguments.entry, content)) {
				return;
			}
		}

		// Append entry with proper spacing
		if (len(content) && right(content, 1) != chr(10)) {
			content &= chr(10);
		}
		content &= chr(10) & "# Vite build output" & chr(10);
		content &= arguments.entry & chr(10);
		fileWrite(gitignorePath, content);
		detailOutput.update(".gitignore", true);
	}

}
