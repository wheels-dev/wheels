/**
 * Migration failures must reach the CLI exit code (issue #3081).
 *
 * The seeder got an honesty fix in #2973/#2987 (partial failure →
 * success=false + non-zero exit). The migrate surface had the same class of
 * bug: a failed up()/down() printed "Error migrating to <version>." yet
 * exited 0, `db reset --force` exited 0 on a ServerNotRunning refusal, and
 * forget/pretend refusals exited 0 — all indistinguishable from success in
 * a `wheels migrate latest && ...` CI gate.
 *
 * These specs cover the CLI-side reporting-honesty seams: the failure
 * detection helpers and the `db reset --force` rethrow. Transaction/rollback
 * behaviour is already correct and is not exercised here.
 *
 * Module instantiation mirrors DbCommandSpec/MigrateCommandSpec — the CLI
 * test runner loads the module against a scaffolded temp project; server-
 * dependent paths throw "No running Wheels server detected" because the
 * temp project has no bound server, which is exactly what gap 2 relies on.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));

		// Create vendor/wheels stub
		directoryCreate(tempRoot & "/vendor/wheels", true, true);

		// scaffoldTempProject() copies the repo's lucee.json (which carries a
		// `port`) into the temp project. Strip the port so detectServerPort()
		// can never resolve a live server for this project — the gap-2 case
		// must deterministically take the ServerNotRunning refusal path
		// (requireProjectConfig=true refuses the common-port fallback), and we
		// must never accidentally POST a real `reset` at a server that happens
		// to be bound to the configured port.
		fileWrite(tempRoot & "/lucee.json", "{}");

		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("migration failure → CLI exit code (##3081)", () => {

			describe("$migrationOutputIndicatesFailure — swallowed-step detection (gap 1)", () => {

				it("flags a failed up() step that migrateTo() folded into its return string", () => {
					var output = "Migrating from 0 up to 20260101000000." & chr(10)
						& "-------- 20260101000000_create_widgets --------" & chr(10)
						& "Error migrating to 20260101000000." & chr(10)
						& "[SQLITE_ERROR] SQL error or missing database (no such function: NOW)";
					expect(mod.$migrationOutputIndicatesFailure(output)).toBeTrue();
				});

				it("flags an IrreversibleMigration down() failure", () => {
					var output = "Migrating from 20260101000000 down to 0." & chr(10)
						& "Error migrating to 20260101000000." & chr(10)
						& "Cannot reverse this migration (IrreversibleMigration).";
					expect(mod.$migrationOutputIndicatesFailure(output)).toBeTrue();
				});

				it("does not flag normal successful migration output", () => {
					var output = "Migrating from 0 up to 20260101000000." & chr(10)
						& "-------- 20260101000000_create_widgets --------" & chr(10)
						& "CREATE TABLE widgets (id INTEGER PRIMARY KEY)";
					expect(mod.$migrationOutputIndicatesFailure(output)).toBeFalse();
				});

				it("does not flag the no-op 'No pending migrations' message", () => {
					expect(
						mod.$migrationOutputIndicatesFailure("No pending migrations. Database is at version 20260101000000.")
					).toBeFalse();
				});

			});

			describe("$cliMigrationResponseFailed — bridge response honesty", () => {

				it("treats success:true carrying a failed-step message as a failure (gap 1)", () => {
					expect(
						mod.$cliMigrationResponseFailed({
							success: true,
							message: "Error migrating to 20260101000000." & chr(10) & "[SQLITE_ERROR] no such function: NOW"
						})
					).toBeTrue();
				});

				it("treats an explicit success:false refusal as a failure (gap 3)", () => {
					expect(
						mod.$cliMigrationResponseFailed({
							success: false,
							message: "Version 20260101000000 was not found in the tracking table."
						})
					).toBeTrue();
				});

				it("treats a clean success response as not-failed", () => {
					expect(
						mod.$cliMigrationResponseFailed({
							success: true,
							message: "Migrating from 0 up to 20260101000000." & chr(10) & "CREATE TABLE widgets (...)"
						})
					).toBeFalse();
				});

			});

			describe("db reset --force refusal honesty (gap 2)", () => {

				it("rethrows the ServerNotRunning refusal instead of swallowing it (exit non-zero)", () => {
					// No server is bound to the scaffolded temp project, so
					// runMigration("latest") -> $requireRunningServer throws.
					// The pre-fix dbReset catch printed red and returned ""
					// (exit 0); the fix rethrows so the refusal reaches $?.
					//
					// arg1=/arg2= exercises the callerArgs path through
					// structuredArgs() — the same mechanism DbCommandSpec's
					// throwing spec uses. The instance-level `__arguments`
					// stash is NOT reliable here: set externally it lands in
					// the component's `this` scope, but structuredArgs()'s
					// unscoped read resolves the variables scope in the
					// in-server suite, so db() would see zero args and print
					// usage help instead of dispatching reset.
					expect(() => mod.db(arg1 = "reset", arg2 = "--force"))
						.toThrow(type = "Wheels.ServerNotRunning");
				});

			});

		});

	}

}
