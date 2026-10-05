/**
 * `wheels migrate unlock [--force]` (#4209). Plain `unlock` is read-only: it
 * reads the migrator lock's status over the bridge (GET), exits 0 when nothing
 * live holds it, and refuses non-zero when an instance does, naming
 * `--force`. `--force` POSTs migrationUnlock, which removes the lease row, and
 * prints what it removed. `--yes` is not an alias, so an MCP client that
 * confirms out of habit never removes a live lock. The framework half (the status and
 * the delete) is covered by the core suite's MigrationLockSpec.
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

	// A Module that talks to canned bridge responses instead of a server.
	private any function unlockModule(required struct statusLock, struct releaseResult = {}) {
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		m.$("out");
		m.$(method = "$requireRunningServer", returns = 61999);
		m.$(method = "$requireOwnRunningServer", returns = 61999);
		m.$("makeHttpRequest", serializeJSON({success: true, lock: arguments.statusLock}));
		var released = structIsEmpty(arguments.releaseResult) ? {success: true, released: false, lock: arguments.statusLock} : arguments.releaseResult;
		m.$("makeBridgePost", serializeJSON(released));
		return m;
	}

	private struct function liveLock() {
		return {held: true, expired: false, owner: "abc123", host: "web-1", heldForSeconds: 120, expiresInSeconds: 3480};
	}

	private struct function noLock() {
		return {held: false, expired: false, owner: "", host: "", heldForSeconds: 0, expiresInSeconds: 0};
	}

	private string function printed(required any m) {
		var said = "";
		for (var call in arguments.m.$callLog().out) {
			said &= call[1] & chr(10);
		}
		return said;
	}

	private string function thrownType(required any fn) {
		var state = {type: ""};
		try {
			arguments.fn();
		} catch (any e) {
			state.type = e.type;
		}
		return state.type;
	}

	function run() {

		describe("wheels migrate unlock (##4209)", () => {

			it("reports no lock and exits 0 when nothing holds it", () => {
				var m = unlockModule(noLock());
				m.migrate(arg1 = "unlock");
				expect(printed(m)).toInclude("No migration lock is held");
				expect(m.$count("makeBridgePost")).toBe(0);
				expect(m.$callLog().makeHttpRequest[1][1]).toInclude("command=migrationLockStatus");
			});

			it("refuses non-zero for a live lock, naming the holder and --force, and leaves it", () => {
				var m = unlockModule(liveLock());
				expect(thrownType(() => m.migrate(arg1 = "unlock"))).toBe("Wheels.MigrationLocked");
				var said = printed(m);
				expect(said).toInclude("web-1");
				expect(said).toInclude("abc123");
				expect(said).toInclude("120 seconds");
				expect(said).toInclude("3480 seconds");
				expect(said).toInclude("wheels migrate unlock --force");
				expect(m.$count("makeBridgePost")).toBe(0);
			});

			it("reports an expired lease and exits 0, since the next migration takes it over", () => {
				var lock = liveLock();
				lock.expired = true;
				lock.expiresInSeconds = -30;
				var m = unlockModule(lock);
				m.migrate(arg1 = "unlock");
				var said = printed(m);
				expect(said).toInclude("expired 30 seconds ago");
				expect(m.$count("makeBridgePost")).toBe(0);
			});

			it("removes the lock with --force and prints what it removed", () => {
				var m = unlockModule(liveLock(), {success: true, released: true, lock: liveLock()});
				m.migrate(arg1 = "unlock", force = true);
				expect(m.$count("makeBridgePost")).toBe(1);
				var postUrl = m.$callLog().makeBridgePost[1][1];
				expect(postUrl).toInclude("command=migrationUnlock");
				expect(postUrl).toInclude("force=true");
				var said = printed(m);
				expect(said).toInclude("Removed the migration lock");
				expect(said).toInclude("web-1");
				expect(said).toInclude("abc123");
			});

			it("doesn't treat --yes as --force", () => {
				var m = unlockModule(liveLock());
				expect(thrownType(() => m.migrate(arg1 = "unlock", yes = true))).toBe("Wheels.MigrationLocked");
				expect(m.$count("makeBridgePost")).toBe(0);
			});

			it("fails non-zero, naming the new holder, when the lock changed hands", () => {
				var m = unlockModule(liveLock(), {success: true, released: false, heldBy: "def456", lock: liveLock()});
				var state = {type: "", message: ""};
				try {
					m.migrate(arg1 = "unlock", force = true);
				} catch (any e) {
					state.type = e.type;
					state.message = e.message;
				}
				expect(state.type).toBe("MigrationError");
				expect(state.message).toInclude("changed hands");
				expect(state.message).toInclude("def456");
				expect(printed(m)).notToInclude("Removed the migration lock");
			});

			it("says so when --force finds nothing to remove", () => {
				var m = unlockModule(noLock());
				m.migrate(arg1 = "unlock", force = true);
				expect(printed(m)).toInclude("No migration lock was held");
			});

			it("fails non-zero when the bridge reports a failure", () => {
				var m = unlockModule(noLock(), {success: false, message: "boom"});
				expect(thrownType(() => m.migrate(arg1 = "unlock", force = true))).toBe("MigrationError");
			});

		});

		describe("migrate unlock over MCP (##4209)", () => {

			it("advertises unlock as a migrate action and force as a boolean", () => {
				var schema = mod.mcpToolSpecs().migrate;
				expect(arrayContainsNoCase(schema.properties.action["enum"], "unlock")).toBeGT(0);
				expect(schema.properties).toHaveKey("force");
				expect(schema.properties.force.type).toBe("boolean");
			});

			it("is read-only without force: a named action alone never POSTs", () => {
				var m = unlockModule(liveLock());
				expect(thrownType(() => m.migrate(action = "unlock"))).toBe("Wheels.MigrationLocked");
				expect(m.$count("makeBridgePost")).toBe(0);
			});

			it("doesn't remove the lock for yes=true without force", () => {
				var m = unlockModule(liveLock());
				expect(thrownType(() => m.migrate(action = "unlock", yes = true))).toBe("Wheels.MigrationLocked");
				expect(m.$count("makeBridgePost")).toBe(0);
			});

			it("removes the lock with force=true", () => {
				var m = unlockModule(liveLock(), {success: true, released: true, lock: liveLock()});
				m.migrate(action = "unlock", force = true);
				expect(m.$count("makeBridgePost")).toBe(1);
			});

			it("puts force after the action in argv", () => {
				expect(mod.$migrateArgv({"force": true, "action": "unlock"})).toBe(["unlock", "--force"]);
			});

		});

	}

}
