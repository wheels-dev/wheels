/**
 * Compile assets for production
 * 
 * This command processes JavaScript, CSS, and image assets for production deployment.
 * It minifies files, generates cache-busted filenames, and creates a manifest for asset mapping.
 * 
 * {code:bash}
 * wheels assets:precompile
 * wheels assets:precompile force=true
 * wheels assets:precompile environment=staging
 * {code}
 **/
component extends="../base" {
	
	property name="FileSystemUtil" inject="FileSystem";
	
	// CommandBox metadata
	this.aliases = [ "precompile" ];
	this.parameters = [
		{ name="force", type="boolean", required=false, default=false, hint="Force recompilation of all assets" },
		{ name="environment", type="string", required=false, default="production", hint="Target environment for compilation" }
	];
	
	/**
	 * Compile and optimize assets for production deployment
	 * 
	 * This command processes JavaScript, CSS, and image assets:
	 * - Minifies JavaScript and CSS files
	 * - Optimizes images (if image optimization tools are available)
	 * - Generates cache-busted filenames
	 * - Creates a manifest file for asset mapping
	 * 
	 * @force Force recompilation of all assets, even if unchanged
	 * @environment Target environment (production, staging, development, test, maintenance, or aliases like prod, dev, stage)
	 **/
	function run(
		boolean force = false,
		string environment = "production"
	) {
		// Reconstruct arguments for handling --prefixed options
		arguments = reconstructArgs(
			argStruct = arguments,
            allowedValues = {
                environment: ["production", "staging", "development", "test", "maintenance", "prod", "dev", "stage"]
            }
		);

		// Normalize environment aliases
		arguments.environment = normalizeEnvironment(arguments.environment);

		if (!isWheelsApp()) {
			error("This command must be run from a Wheels application root directory.");
		}
		
		print.boldGreenLine("==> Precompiling assets for #arguments.environment#...");
		print.line();
		
		// Define asset directories		
		var publicDir = fileSystemUtil.resolvePath("public");

		var assetsDir = publicDir & "assets";
		var jsDir = publicDir & "javascripts";
		var cssDir = publicDir & "stylesheets";
		var imagesDir = publicDir & "images";
		
		// Create compiled assets directory
		var compiledDir = assetsDir & "/compiled";
		if (!directoryExists(compiledDir)) {
			directoryCreate(compiledDir);
			print.line("Created compiled assets directory: #compiledDir#");
		}
		
		// Initialize manifest
		var manifest = {};
		var processedCount = 0;
		
		// Process JavaScript files
		if (directoryExists(jsDir)) {
			print.boldLine("Processing JavaScript files...");
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
			print.boldLine("Processing CSS files...");
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
			print.boldLine("Processing image files...");
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
		print.line("Asset manifest written to: #manifestPath#");
		
		print.line();
		print.boldGreenLine("==> Asset precompilation complete!");
		print.greenLine("    Processed #processedCount# files");
		print.line("    Compiled assets location: #compiledDir#");
		
		// Provide instructions for production
		print.line();
		print.yellowLine("To use precompiled assets in production:");
		print.line("1. Configure your web server to serve static files from /public/assets/compiled");
		print.line("2. Update your application to use the asset manifest for cache-busted URLs");
		print.line("3. Set wheels.assetManifest = true in your production environment");
	}
	
	/**
	 * Process a JavaScript file
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

		// Check if file already exists and hasn't changed
		if (!arguments.force && fileExists(targetPath)) {
			print.line("#fileName# (unchanged)");
			arguments.manifest[fileName] = targetFileName;
			return 0;
		}

		// Apply environment-specific minification
		content = minifyJavaScript(content, arguments.environment);

		// Write processed file
		fileWrite(targetPath, content);
		arguments.manifest[fileName] = targetFileName;

		var processType = getProcessingDescription(arguments.environment);
		print.greenLine("#fileName# -> #targetFileName# (#processType#)");
		return 1;
	}
	
	/**
	 * Process a CSS file
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

		// Check if file already exists and hasn't changed
		if (!arguments.force && fileExists(targetPath)) {
			print.line("#fileName# (unchanged)");
			arguments.manifest[fileName] = targetFileName;
			return 0;
		}

		// Apply environment-specific minification
		content = minifyCSS(content, arguments.environment);

		// Write processed file
		fileWrite(targetPath, content);
		arguments.manifest[fileName] = targetFileName;

		var processType = getProcessingDescription(arguments.environment);
		print.greenLine("#fileName# -> #targetFileName# (#processType#)");
		return 1;
	}
	
	/**
	 * Process an image file
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
		
		// Check if file already exists
		if (!arguments.force && fileExists(targetPath)) {
			print.line("#fileName# (unchanged)");
			arguments.manifest[fileName] = targetFileName;
			return 0;
		}
		
		// Copy image with cache-busted filename
		fileCopy(arguments.source, targetPath);
		arguments.manifest[fileName] = targetFileName;
		
		print.greenLine("#fileName# -> #targetFileName#");
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
				// No minification for development - keep code readable for debugging
				return arguments.content;

			case "staging":
			case "test":
			case "maintenance":
				// Light minification - remove comments but preserve formatting
				var result = arguments.content;
				result = reReplace(result, "/\*[\s\S]*?\*/", "", "all"); // Remove block comments
				result = reReplace(result, "//[^\r\n]*", "", "all"); // Remove line comments
				result = reReplace(result, "[\r\n]{2,}", chr(10), "all"); // Remove excessive line breaks
				return trim(result);

			case "production":
			default:
				// Full minification - aggressive optimization
				var result = arguments.content;
				result = reReplace(result, "/\*[\s\S]*?\*/", "", "all"); // Remove block comments
				result = reReplace(result, "//[^\r\n]*", "", "all"); // Remove line comments
				result = reReplace(result, "[\r\n]+", chr(10), "all"); // Normalize line endings
				result = reReplace(result, "\s+", " ", "all"); // Collapse whitespace
				result = reReplace(result, ";\s*}", "}", "all"); // Remove unnecessary semicolons
				result = reReplace(result, "\s*([{}();,])\s*", "\1", "all"); // Remove spaces around operators
				return trim(result);
		}
	}

	/**
	 * Minify CSS content based on environment
	 */
	private string function minifyCSS(required string content, required string environment) {
		switch(lCase(arguments.environment)) {
			case "development":
				// No minification for development - keep CSS readable
				return arguments.content;

			case "staging":
			case "test":
			case "maintenance":
				// Light minification - remove comments and excessive whitespace
				var result = arguments.content;
				result = reReplace(result, "/\*[\s\S]*?\*/", "", "all"); // Remove comments
				result = reReplace(result, "[\r\n]{2,}", chr(10), "all"); // Remove excessive line breaks
				result = reReplace(result, "\s+", " ", "all"); // Collapse whitespace
				return trim(result);

			case "production":
			default:
				// Full minification - maximum compression
				var result = arguments.content;
				result = reReplace(result, "/\*[\s\S]*?\*/", "", "all"); // Remove comments
				result = reReplace(result, "[\r\n]+", " ", "all"); // Remove line breaks
				result = reReplace(result, "\s+", " ", "all"); // Collapse whitespace
				result = reReplace(result, ";\s*}", "}", "all"); // Remove last semicolon
				result = reReplace(result, ":\s+", ":", "all"); // Remove space after colon
				result = reReplace(result, "\s*{\s*", "{", "all"); // Remove space around braces
				result = reReplace(result, "\s*}\s*", "}", "all");
				result = reReplace(result, "\s*;\s*", ";", "all"); // Remove space around semicolon
				result = reReplace(result, "\s*,\s*", ",", "all"); // Remove space around commas
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
			// Development aliases
			case "dev":
			case "development":
				return "development";

			// Testing aliases
			case "test":
			case "testing":
				return "test";

			// Staging aliases
			case "stage":
			case "staging":
			case "stag":
				return "staging";

			// Maintenance aliases
			case "maintenance":
			case "maintainance": // Handle common misspelling
				return "maintenance";

			// Production aliases (default)
			case "prod":
			case "production":
			default:
				return "production";
		}
	}

}