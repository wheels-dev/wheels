/**
 * generate and destroy must refuse outside a Wheels project (#3909).
 * resolveProjectRoot() falls back to the cwd when no vendor/wheels is found,
 * so without a guard `wheels generate model Foo` in any directory wrote
 * app/models/Foo.cfc and a migration there, and `wheels destroy` could delete
 * a stray app file. The project marker is config/settings.cfm, the same check
 * `wheels start` uses.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("generate/destroy project guard", () => {
			beforeEach(() => {
				variables.tempRoot = getTempDirectory() & "wheels-not-a-project-" & createUUID();
				directoryCreate(variables.tempRoot, true, true);
				variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
			});

			afterEach(() => {
				structDelete(request, "$wheelsGenerateDryRun");
				structDelete(request, "$wheelsDryRunPaths");
				if (directoryExists(variables.tempRoot)) directoryDelete(variables.tempRoot, true);
			});

			it("generate model refuses outside a Wheels project and writes nothing", () => {
				expect(() => {
					mod.generate(arg1 = "model", arg2 = "Foo", arg3 = "name:string");
				}).toThrow("Wheels.NotAWheelsProject");
				expect(directoryExists(variables.tempRoot & "/app")).toBeFalse();
			});

			it("the refusal names the missing project marker", () => {
				var message = "";
				try {
					mod.generate(type = "controller", name = "Foos");
				} catch (any e) {
					message = e.message;
				}
				expect(message).toInclude("not a Wheels project");
				expect(message).toInclude("config/settings.cfm");
			});

			it("generate app is not blocked by the guard", () => {
				var thrownType = "";
				try {
					mod.generate(arg1 = "app", arg2 = "myapp", arg3 = "--dry-run");
				} catch (any e) {
					thrownType = e.type;
				}
				expect(thrownType).notToBe("Wheels.NotAWheelsProject");
			});

			it("destroy refuses outside a Wheels project and leaves a stray app file alone", () => {
				directoryCreate(variables.tempRoot & "/app/models", true, true);
				fileWrite(variables.tempRoot & "/app/models/Stray.cfc", "component {}");
				expect(() => {
					mod.destroy(arg1 = "model", arg2 = "Stray", force = true);
				}).toThrow("Wheels.NotAWheelsProject");
				expect(fileExists(variables.tempRoot & "/app/models/Stray.cfc")).toBeTrue();
			});

			it("generate still works inside a project (config/settings.cfm present)", () => {
				for (var dir in ["vendor/wheels", "app/models", "app/migrator/migrations", "config", "tests/specs"]) {
					directoryCreate(variables.tempRoot & "/" & dir, true, true);
				}
				fileWrite(variables.tempRoot & "/config/settings.cfm", "<cfscript></cfscript>");
				var inProject = new cli.lucli.Module(cwd = variables.tempRoot);
				inProject.generate(arg1 = "model", arg2 = "Foo", arg3 = "name:string");
				expect(fileExists(variables.tempRoot & "/app/models/Foo.cfc")).toBeTrue();
			});
		});
	}

}
