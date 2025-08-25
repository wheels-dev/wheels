component output="false" displayName="Internal GUI" extends="wheels.Global" {

	/**
	 * Internal function.
	 */
	public struct function $init() {
		return this;
	}

	/*
	This is just a proof of concept
	*/
	function index() {
		include "/wheels/public/views/congratulations.cfm";
		return "";
	}
	function info() {
		include "/wheels/public/views/info.cfm";
		return "";
	}
	function routes() {
		include "/wheels/public/views/routes.cfm";
		return "";
	}
	function routetester(verb, path) {
		include "/wheels/public/helpers.cfm";
		include "/wheels/public/views/routetester.cfm";
		return "";
	}
	function routetesterprocess(verb, path) {
		include "views/routetesterprocess.cfm";
		return "";
	}
	function api() {
		include "/wheels/public/helpers.cfm";
		include "/wheels/public/views/api.cfm";
		return "";
	}
	function runner(){
		include "/wheels/public/views/runner.cfm";
		return "";
	}

	function testbox(){
		include "/tests/runner.cfm";
	}
	
	public function tests_testbox(){
		// Set proper HTTP status first
		cfheader(statuscode="200", statustext="OK");
		
		// Simple test to ensure the endpoint works
		if (structKeyExists(url, "test") && url.test == "simple") {
			cfcontent(type="application/json");
			writeOutput('{"success":true,"message":"TestBox endpoint is working"}');
			abort;
		}
		
		// Set content type based on format
		if (structKeyExists(url, "format") && url.format == "json") {
			cfcontent(type="application/json");
		} else if (structKeyExists(url, "format") && url.format == "txt") {
			cfcontent(type="text/plain");
		}
		
		// Include the TestBox runner directly without buffering
		include "/wheels/tests_testbox/runner.cfm";
		
		// Ensure we abort to prevent any further processing
		abort;
	}
	function packages() {
		include "/wheels/public/views/packages.cfm";
		return "";
	}
	function tests() {
		include "/wheels/public/views/tests.cfm";
		return "";
	}
	function migrator() {
		include "/wheels/public/views/migrator.cfm";
		return "";
	}
	function migratortemplates() {
		include "/wheels/public/views/templating.cfm";
		return "";
	}
	function migratortemplatescreate() {
		include "/wheels/public/migrator/templating.cfm";
		return "";
	}
	function migratorcommand() {
		include "/wheels/public/migrator/command.cfm";
		return "";
	}
	function migratorsql() {
		include "/wheels/public/migrator/sql.cfm";
		return "";
	}
	function cli() {
		include "/wheels/public/views/cli.cfm";
		return "";
	}
	function plugins() {
		include "/wheels/public/views/plugins.cfm";
		return "";
	}
	function pluginentry() {
		include "/wheels/public/views/pluginentry.cfm";
		return "";
	}
	function build() {
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
		// Handle legacy ?controller=wheels&action=wheels&view=xxx URLs
		return wheels();
	}

	function guides() {
		include "/wheels/public/helpers.cfm";
		include "/wheels/public/views/guides.cfm";
		return "";
	}

	function guideImage() {
		var file = StructKeyExists(request.wheels.params, "file") ? request.wheels.params.file : "";
		var assetPath = expandPath("/wheels/docs/src/.gitbook/assets/" & file);

		if (fileExists(assetPath)) {
			var ext = lcase(listLast(file, "."));
			var mime = "application/octet-stream";
			switch (ext) {
				case "png": mime = "image/png"; break;
				case "jpg":
				case "jpeg": mime = "image/jpeg"; break;
				case "gif": mime = "image/gif"; break;
				case "svg": mime = "image/svg+xml"; break;
				case "webp": mime = "image/webp"; break;
			}
			cfheader(name="Content-Type", value=mime);
			cffile(action="readBinary", file=assetPath, variable="imgData");
			cfcontent(type=mime, variable=imgData);
		} else {
			cfheader(statusCode=404, statusText="Not Found");
			writeOutput("Image not found");
		}
	}
}
