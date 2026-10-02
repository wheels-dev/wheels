/**
 * "Next steps" after generate scaffold / api-resource (#3883). With the
 * project's server already running, "Start server: wheels start" sent people
 * to a 404 on the new route (and a 500 on its form) until they reloaded. When
 * the server is running, the steps say to reload it instead.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("generate Next steps", () => {
			beforeEach(() => {
				variables.tempRoot = getTempDirectory() & "wheels-next-steps-" & createUUID();
				for (var dir in ["vendor/wheels", "app/models", "app/controllers", "app/views", "app/migrator/migrations", "config", "tests/specs"]) {
					directoryCreate(variables.tempRoot & "/" & dir, true, true);
				}
				fileWrite(variables.tempRoot & "/config/routes.cfm", 'mapper().wildcard().end();');
				fileWrite(variables.tempRoot & "/config/settings.cfm", "");
				createObject("java", "java.io.File").init(expandPath("/testbox/system/stubs")).mkdirs();
			});

			afterEach(() => {
				structDelete(request, "$wheelsGenerateDryRun");
				structDelete(request, "$wheelsDryRunPaths");
				if (directoryExists(variables.tempRoot)) directoryDelete(variables.tempRoot, true);
			});

			it("scaffold says to reload when the project's server is running", () => {
				var text = $nextSteps(running = true, type = "scaffold");
				expect(text).toInclude("wheels reload");
				expect(text).notToInclude("Start server: wheels start");
			});

			it("scaffold still says wheels start when no server is running", () => {
				var text = $nextSteps(running = false, type = "scaffold");
				expect(text).toInclude("Start server: wheels start");
				expect(text).notToInclude("wheels reload");
			});

			it("api-resource says to reload when the project's server is running", () => {
				var text = $nextSteps(running = true, type = "api-resource");
				expect(text).toInclude("wheels reload");
				expect(text).notToInclude("Start server: wheels start");
			});

			it("api-resource's curl hint uses the project's pinned port, not a hardcoded 8080", () => {
				fileWrite(variables.tempRoot & "/lucee.json", '{"name":"nextsteps","port":8123}');
				var text = $nextSteps(running = false, type = "api-resource");
				expect(text).toInclude("curl http://localhost:8123/api/widgets.json");
				expect(text).notToInclude("localhost:8080");
			});

			it("api-resource still says wheels start when no server is running", () => {
				var text = $nextSteps(running = false, type = "api-resource");
				expect(text).toInclude("Start server: wheels start");
			});
		});
	}

	private string function $nextSteps(required boolean running, required string type) {
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		m.$(method = "$serverRunningForProject", returns = arguments.running);
		m.generate(type = arguments.type, name = "Widget", attributes = "title:string");
		var lines = [];
		for (var entry in (m.$outLog ?: [])) arrayAppend(lines, toString(entry.message));
		return arrayToList(lines, chr(10));
	}

}
