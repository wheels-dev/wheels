/**
 * An unknown command must say so plainly (#3890). LuCLI dispatches
 * `wheels <name>` to a Module function of that name, and a missing one surfaced
 * as Lucee's raw "Component [modules.wheels.Module] has no function with name
 * [status]". onMissingMethod now prints a friendly message (with a "did you
 * mean" for near misses) and throws Wheels.UnknownCommand, so the exit stays
 * non-zero.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	private struct function $failure(required string command) {
		var state = {type = "", message = ""};
		try {
			invoke(variables.mod, arguments.command, {});
		} catch (any e) {
			state.type = e.type;
			state.message = e.message;
		}
		return state;
	}

	function run() {
		describe("unknown commands", () => {

			it("throws Wheels.UnknownCommand with a friendly message", () => {
				var f = $failure("status");
				expect(f.type).toBe("Wheels.UnknownCommand");
				expect(f.message).toInclude("Unknown command: status");
				expect(f.message).toInclude("wheels --help");
				expect(f.message).notToInclude("has no function");
			});

			it("suggests the nearest command for a near miss", () => {
				var f = $failure("generat");
				expect(f.type).toBe("Wheels.UnknownCommand");
				expect(f.message).toInclude("Did you mean: wheels generate");
			});

			it("does not suggest anything for a name far from every command", () => {
				var f = $failure("zzqqxxyy");
				expect(f.type).toBe("Wheels.UnknownCommand");
				expect(f.message).notToInclude("Did you mean");
			});

			it("never suggests an internal $-helper or the hook itself", () => {
				var f = $failure("onMissingMethd");
				expect(f.message).notToInclude("Did you mean: wheels onMissingMethod");
			});

			it("keeps onMissingMethod off the MCP tool list", () => {
				expect(arrayFindNoCase(mod.mcpHiddenTools(), "onMissingMethod")).toBeGT(0);
			});
		});
	}

}
