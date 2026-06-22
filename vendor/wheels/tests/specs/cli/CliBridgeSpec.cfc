/**
 * Unit specs for the CliBridge service (issue ##2959, P2).
 *
 * The dev-UI dispatcher `vendor/wheels/public/views/cli.cfm` was a ~935-line
 * template with a 44-case switch whose handlers could not be unit-tested
 * because the template only runs under a full HTTP request context. The
 * handlers were extracted into `wheels.public.CliBridge` — a plain,
 * stateless component with one method per command and an explicit
 * command->method allowlist. cli.cfm is now a thin dispatcher that builds a
 * context, checks `handles()`, and calls `dispatch()`.
 *
 * Because CliBridge is a plain component, the dispatch contract and the
 * pure (no-DB) handler branches ARE unit-testable here — the regression net
 * the god-template never had. DB- and worker-backed handlers are
 * behaviour-preserving moves verified by the cross-engine matrix and live
 * endpoint testing.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("CliBridge dispatch contract (issue ##2959)", () => {

			beforeEach(() => {
				bridge = new wheels.public.CliBridge();
			});

			it("handles() returns true for every declared command", () => {
				var declared = "createMigration,migrateTo,migrateToLatest,migrateUp,migrateDown,"
					& "renameSystemTables,diff,redoMigration,info,doctor,forgetVersion,pretendVersion,"
					& "dbStatus,dbVersion,dbRollback,dbSchema,introspect,dbSeed,routes,dbCreate,dbDrop,"
					& "dbReset,dbSetup,dbDump,dbRestore,dbShell,jobsProcessNext,jobsStatus,jobsRetry,"
					& "jobsPurge,jobsMonitor";
				for (var cmd in ListToArray(declared)) {
					expect(bridge.handles(cmd)).toBeTrue("CliBridge should handle '" & cmd & "'");
				}
			});

			it("handles() returns false for unknown or unsafe command names", () => {
				expect(bridge.handles("")).toBeFalse();
				expect(bridge.handles("notACommand")).toBeFalse();
				// Must NOT expose arbitrary component methods as commands.
				expect(bridge.handles("init")).toBeFalse();
				expect(bridge.handles("dispatch")).toBeFalse();
				expect(bridge.handles("handles")).toBeFalse();
			});

			it("dispatch() throws for a command not on the allowlist (defensive guard)", () => {
				var call = () => {
					bridge.dispatch(command = "notACommand", context = {}, params = {});
				};
				expect(call).toThrow("Wheels.UnknownCliCommand");
			});

		});

		describe("CliBridge pure handler branches (issue ##2959)", () => {

			beforeEach(() => {
				bridge = new wheels.public.CliBridge();
			});

			it("dbVersion reports the current version from the context", () => {
				var rv = bridge.dispatch(
					command = "dbVersion",
					context = {currentVersion = "20260101000000"},
					params = {}
				);
				expect(rv.success).toBeTrue();
				expect(rv.version).toBe("20260101000000");
				expect(rv.message).toInclude("20260101000000");
			});

			it("introspect returns a missing-parameter error when no model is given", () => {
				var rv = bridge.dispatch(command = "introspect", context = {}, params = {});
				expect(rv.success).toBeFalse();
				expect(rv.message).toInclude("Missing required parameter: model");
			});

			it("forgetVersion returns a missing-argument error when no version is given", () => {
				var rv = bridge.dispatch(command = "forgetVersion", context = {}, params = {});
				expect(rv.success).toBeFalse();
				expect(rv.message).toInclude("Missing required argument: version");
			});

			it("migrateToLatest delegates to the migrator and returns its message", () => {
				var fakeMigrator = {migrateToLatest = () => "Migrated to 20260101000000."};
				var rv = bridge.dispatch(
					command = "migrateToLatest",
					context = {migrator = fakeMigrator},
					params = {}
				);
				expect(rv.message).toBe("Migrated to 20260101000000.");
			});

		});

	}

}
