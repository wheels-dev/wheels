/**
 * `wheels migrate` and `wheels create` forward to their own argv parsers, so
 * the MCP call shape needs normalizing before that hand-off (#2963).
 *
 * LuCLI's MCP server passes every tools/call argument as a named key. The old
 * path rebuilt argv with ArgSpec.toArgv(), which emits named keys in struct
 * order: `{action: "info", "dry-run": false}` could become
 * `["--no-dry-run", "--action=info"]`, and migrate read argv[1] as the action.
 * `$migrateArgv()` / `$createArgs()` bind the positionals first (a typed token
 * wins, else the named key), then append the remaining flags.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		// A closed port, so server-dependent actions deterministically throw
		// Wheels.ServerNotRunning — proof the action was dispatched.
		fileWrite(tempRoot & "/.env", "PORT=1" & chr(10));
		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("$migrateArgv — positionals first, whatever the key order (##2963)", () => {

			it("puts a named action first even when a flag is also named", () => {
				var argv = mod.$migrateArgv({"dry-run": false, "action": "info"});
				expect(argv[1]).toBe("info");
			});

			it("defaults the action to latest when only flags are passed", () => {
				var argv = mod.$migrateArgv({"offline": true});
				expect(argv[1]).toBe("latest");
				expect(arrayContains(argv, "--offline")).toBeTrue();
			});

			it("places a named forget version in the version slot", () => {
				var argv = mod.$migrateArgv({"yes": true, "version": "20240101120000", "action": "forget"});
				expect(argv[1]).toBe("forget");
				expect(argv[2]).toBe("20240101120000");
				expect(arrayContains(argv, "--yes")).toBeTrue();
			});

			it("places a named diff model in the model slot", () => {
				var argv = mod.$migrateArgv({"write": true, "name": "sync_users", "model": "User", "action": "diff"});
				expect(argv[1]).toBe("diff");
				expect(argv[2]).toBe("User");
				expect(arrayContains(argv, "--write")).toBeTrue();
				expect(arrayContains(argv, "--name=sync_users")).toBeTrue();
			});

			it("does not put a diff model into a forget version slot, or vice versa", () => {
				expect(mod.$migrateArgv({"action": "forget", "model": "User"})).toBe(["forget"]);
				expect(mod.$migrateArgv({"action": "diff", "version": "20240101120000"})).toBe(["diff"]);
			});

			it("keeps typed CLI tokens exactly as before", () => {
				expect(mod.$migrateArgv({"arg1": "forget", "arg2": "20240101120000", "yes": "true"})).toBe(["forget", "20240101120000", "--yes"]);
				expect(mod.$migrateArgv({"arg1": "diff", "arg2": "User"})).toBe(["diff", "User"]);
				expect(mod.$migrateArgv({})).toBe(["latest"]);
			});

			it("prefers a typed action token over a named action", () => {
				expect(mod.$migrateArgv({"arg1": "down", "action": "up"})[1]).toBe("down");
			});

		});

		describe("wheels migrate — named arguments take effect (##2963)", () => {

			it("dispatches a named action with a flag alongside it", () => {
				expect(() => mod.migrate(action = "info", "dry-run" = false)).toThrow(type = "Wheels.ServerNotRunning");
			});

			it("rejects action=true instead of falling back to latest and running migrations", () => {
				// Must fail on the arguments, before any server step: reaching
				// Wheels.ServerNotRunning means it would have migrated.
				expect(() => mod.migrate(action = "true")).toThrow(type = "Wheels.InvalidArguments");
				expect(() => mod.migrate(action = true)).toThrow(type = "Wheels.InvalidArguments");
			});

			it("rejects an unknown named action instead of running latest", () => {
				expect(() => mod.migrate(action = "bogus")).toThrow(type = "Wheels.InvalidArguments");
			});

		});

		describe("$createArgs — type and name by token or by name (##2963)", () => {

			it("binds named type and name regardless of key order", () => {
				var parsed = mod.$createArgs({"name": "blog", "type": "app"});
				expect(parsed.type).toBe("app");
				expect(parsed.remaining).toBe(["blog"]);
			});

			it("keeps typed tokens and forwards the remaining options to new", () => {
				var parsed = mod.$createArgs({"arg1": "app", "arg2": "blog", "port": "3000"});
				expect(parsed.type).toBe("app");
				expect(parsed.remaining).toBe(["blog", "--port=3000"]);
			});

			it("forwards extra positional tokens after the name", () => {
				var parsed = mod.$createArgs({"arg1": "app", "arg2": "blog", "arg3": "extra"});
				expect(parsed.remaining).toBe(["blog", "extra"]);
			});

			it("returns an empty type when nothing was passed", () => {
				var parsed = mod.$createArgs({});
				expect(parsed.type).toBe("");
				expect(parsed.remaining).toBe([]);
			});

			it("matches the positional names create advertises over MCP", () => {
				// $createArgs binds by these names, so the schema must use them.
				var props = mod.mcpToolSpecs().create.properties;
				expect(props).toHaveKey("type");
				expect(props).toHaveKey("name");
			});

		});

		describe("wheels create — named arguments take effect (##2963)", () => {

			it("reports an unknown named type, not a mangled --name= token", () => {
				var state = {message: ""};
				try {
					mod.create(name = "x", type = "bogus");
				} catch (any e) {
					state.message = e.message;
				}
				expect(state.message).toBe("Unknown create type: bogus");
			});

		});

	}

}
