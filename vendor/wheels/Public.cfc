component output="false" displayName="Internal GUI" extends="wheels.Global" {

	/**
	 * Internal function.
	 */
	public struct function $init() {
		include "/wheels/public/helpers.cfm";
		return this;
	}

	/**
	 * Returns true when the current application environment is `production`.
	 *
	 * The public GUI exposes routes, env info, a CFML REPL, test runners, and
	 * a migration UI. Even if a developer overrides `enablePublicComponent` to
	 * true in production (documented historical behavior for ad-hoc
	 * debugging), these surfaces must stay gated. See issue #2233.
	 */
	public boolean function $shouldBlockInProduction() {
		return StructKeyExists(application, "wheels")
		&& StructKeyExists(application.wheels, "environment")
		&& application.wheels.environment == "production";
	}

	/**
	 * Defense-in-depth: if the current environment is production, short-circuit
	 * the handler with a 404 response before any view is included. Called as
	 * the first statement of every non-`index` handler in this component.
	 */
	public void function $blockInProduction() {
		if ($shouldBlockInProduction()) {
			cfheader(statuscode = 404);
			cfcontent(type = "text/plain");
			WriteOutput("Not Found");
			abort;
		}
	}

	/**
	 * Returns a struct { packages: [...], error: "" } populated from the
	 * wheels-packages registry. Short-circuits in production (defense in
	 * depth — the handler is already $blockInProduction()-gated). Captures
	 * any registry error into the `error` field so the view can render a
	 * friendly banner instead of a stack trace.
	 *
	 * The optional `registry` argument is for tests; normal callers pass
	 * nothing and get a memoized application-scope Registry instance.
	 */
	public struct function $loadRegistryPackages(any registry = "") {
		if ($shouldBlockInProduction()) {
			return {packages = [], error = ""};
		}
		local.reg = IsObject(arguments.registry) ? arguments.registry : $getRegistryClient();
		try {
			return {packages = local.reg.listAll(), error = ""};
		} catch ("Wheels.Packages.RegistryUnavailable" e) {
			return {packages = [], error = "Registry lookup failed: " & e.message};
		} catch ("Wheels.Packages.RegistryMalformed" e) {
			return {packages = [], error = "Registry lookup failed: " & e.message};
		} catch ("Wheels.Packages.UnknownPackage" e) {
			return {packages = [], error = "Registry lookup failed: " & e.message};
		}
	}

	/**
	 * Lazy, app-scope memo of the framework's Registry component.
	 *
	 * Lives at `vendor/wheels/services/packages/` so it ships with every
	 * generated app — the framework's debug panel can surface registry
	 * packages without any CLI dependency on disk. Issue #2530.
	 */
	private any function $getRegistryClient() {
		if (!StructKeyExists(application.wheels, "$packageRegistry")) {
			application.wheels.$packageRegistry = new wheels.services.packages.Registry();
		}
		return application.wheels.$packageRegistry;
	}

	/*
	This is just a proof of concept
	*/
	function index() {
		include "/wheels/public/views/congratulations.cfm";
		return "";
	}
	function info() {
		$blockInProduction();
		include "/wheels/public/views/info.cfm";
		return "";
	}
	function routes() {
		$blockInProduction();
		include "/wheels/public/views/routes.cfm";
		return "";
	}
	function routetester(verb, path) {
		$blockInProduction();
		include "/wheels/public/views/routetester.cfm";
		return "";
	}
	function routetesterprocess(verb, path) {
		$blockInProduction();
		include "views/routetesterprocess.cfm";
		return "";
	}
	function api() {
		$blockInProduction();
		include "/wheels/public/views/api.cfm";
		return "";
	}
	function runner() {
		$blockInProduction();
		include "/wheels/public/views/runner.cfm";
		return "";
	}

	function testbox() {
		$blockInProduction();
		// Prefer the project's own runner if it exists (advanced users who
		// scaffolded a custom tests/runner.cfm). Otherwise fall back to a
		// built-in app-test runner that scans tests.specs/ via TestBox and
		// emits the same JSON shape as the framework's core runner. Without
		// this fallback, fresh apps got "Page [/tests/runner.cfm] not found"
		// because `wheels new` doesn't scaffold one.
		var projectRunner = ExpandPath("/tests/runner.cfm");
		if (FileExists(projectRunner)) {
			include "/tests/runner.cfm";
			return;
		}
		include "/wheels/tests/app-runner.cfm";
	}

	public function tests_testbox() {
		$blockInProduction();
		// Delegate to RocketUnit if testFramework setting says so
		if (
			StructKeyExists(application, "wheels")
			&& StructKeyExists(application.wheels, "testFramework")
			&& application.wheels.testFramework == "rocketunit"
		) {
			include "/wheels/public/views/tests.cfm";
			return "";
		}

		// Set proper HTTP status first
		cfheader(statuscode = "200");

		// Simple test to ensure the endpoint works
		if (StructKeyExists(url, "test") && url.test == "simple") {
			cfcontent(type = "application/json");
			WriteOutput('{"success":true,"message":"TestBox endpoint is working"}');
			abort;
		}

		// Set content type based on format
		if (StructKeyExists(url, "format") && url.format == "json") {
			cfcontent(type = "application/json");
		} else if (StructKeyExists(url, "format") && url.format == "txt") {
			cfcontent(type = "text/plain");
		}

		// Include the TestBox runner
		include "/wheels/tests/runner.cfm";

		// Ensure we abort to prevent any further processing
		abort;
	}
	public function clitests() {
		$blockInProduction();
		include "/wheels/public/views/clitests.cfm";
		abort;
	}

	function packages() {
		$blockInProduction();
		include "/wheels/public/views/packages.cfm";
		return "";
	}
	function tests() {
		$blockInProduction();
		include "/wheels/public/views/tests.cfm";
		return "";
	}
	function migrator() {
		$blockInProduction();
		include "/wheels/public/views/migrator.cfm";
		return "";
	}
	function migratortemplates() {
		$blockInProduction();
		include "/wheels/public/views/templating.cfm";
		return "";
	}
	function migratortemplatescreate() {
		$blockInProduction();
		include "/wheels/public/migrator/templating.cfm";
		return "";
	}
	function migratorcommand() {
		$blockInProduction();
		include "/wheels/public/migrator/command.cfm";
		return "";
	}
	function migratorsql() {
		$blockInProduction();
		include "/wheels/public/migrator/sql.cfm";
		return "";
	}
	function consoleeval() {
		$blockInProduction();
		include "/wheels/public/views/consoleeval.cfm";
		return "";
	}
	function cli() {
		$blockInProduction();
		include "/wheels/public/views/cli.cfm";
		return "";
	}
	function packagelist() {
		$blockInProduction();
		include "/wheels/public/views/packagelist.cfm";
		return "";
	}
	function packageentry() {
		$blockInProduction();
		include "/wheels/public/views/packageentry.cfm";
		return "";
	}
	function plugins() {
		$blockInProduction();
		include "/wheels/public/views/plugins.cfm";
		return "";
	}
	function pluginentry() {
		$blockInProduction();
		include "/wheels/public/views/pluginentry.cfm";
		return "";
	}
	function build() {
		$blockInProduction();
		setting requestTimeout=10000 showDebugOutput=false;
		zipPath = $buildReleaseZip();
		$header(name = "Content-disposition", value = "inline; filename=#GetFileFromPath(zipPath)#");
		$content(file = zipPath, type = "application/zip", deletefile = true);
		return "";
	}

	/*
		Check for legacy urls and params
		Example Strings to test against
		?controller=wheels&action=wheels&
			view=routes
			view=docs
			view=build
			view=migrate
			view=cli

			// Packages
			view=packages&type=core
			view=packages&type=app
			view=packages&type=[PLUGIN]

			// Test Runnner
			view=tests&type=core
			view=tests&type=app
			view=tests&type=[PLUGIN]
		*/
	function wheels() {
		$blockInProduction();
		local.action = StructKeyExists(request.wheels.params, "action") ? request.wheels.params.action : "";
		local.view = StructKeyExists(request.wheels.params, "view") ? request.wheels.params.view : "";
		local.type = StructKeyExists(request.wheels.params, "type") ? request.wheels.params.type : "";

		switch (local.view) {
			case "routes":
			case "docs":
			case "cli":
			case "tests":
			case "runner":
				include "/wheels/public/views/#local.view#.cfm";
				break;
			case "testbox":
				// Handle testbox specifically
				return tests_testbox();
			case "packages":
				include "/wheels/public/views/packages.cfm";
				break;
			case "migrate":
				include "/wheels/public/views/migrator.cfm";
				break;
			default:
				include "/wheels/public/views/congratulations.cfm";
				break;
		}
		return "";
	}

	function legacy() {
		$blockInProduction();
		// Handle legacy ?controller=wheels&action=wheels&view=xxx URLs
		return wheels();
	}

	function guides() {
		$blockInProduction();
		include "/wheels/public/views/guides.cfm";
		return "";
	}

	function ai() {
		$blockInProduction();
		include "/wheels/public/views/ai.cfm";
		return "";
	}

	function guideImage() {
		$blockInProduction();
		var file = StructKeyExists(request.wheels.params, "file") ? request.wheels.params.file : "";

		file = GetFileFromPath(file);
		if (!Len(file) || Find("..", file) || ReFind("[/\\]", file)) {
			cfheader(statusCode = 404);
			WriteOutput("Image not found");
			return;
		}

		var assetsDir = ExpandPath("/wheels/docs/src/.gitbook/assets/");
		var assetPath = assetsDir & file;

		try {
			var canonicalAssets = CreateObject("java", "java.io.File").init(assetsDir).getCanonicalPath();
			var canonicalPath = CreateObject("java", "java.io.File").init(assetPath).getCanonicalPath();
		} catch (any e) {
			cfheader(statusCode = 404);
			WriteOutput("Image not found");
			return;
		}
		if (!FileExists(assetPath) || CompareNoCase(Left(canonicalPath, Len(canonicalAssets)), canonicalAssets) != 0) {
			cfheader(statusCode = 404);
			WriteOutput("Image not found");
			return;
		}

		var ext = LCase(ListLast(file, "."));
		var mime = "application/octet-stream";
		switch (ext) {
			case "png":
				mime = "image/png";
				break;
			case "jpg":
			case "jpeg":
				mime = "image/jpeg";
				break;
			case "gif":
				mime = "image/gif";
				break;
			case "svg":
				mime = "image/svg+xml";
				break;
			case "webp":
				mime = "image/webp";
				break;
		}
		cfheader(name = "Content-Type", value = mime);
		cffile(action = "readBinary", file = assetPath, variable = "imgData");
		cfcontent(type = mime, variable = imgData);
	}

	function mcp() {
		$blockInProduction();
		include "/wheels/public/views/mcp.cfm";
		return "";
	}

}
