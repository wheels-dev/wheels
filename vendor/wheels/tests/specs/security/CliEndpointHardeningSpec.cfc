/**
 * Hardens the /wheels/cli bridge endpoint (2026-06-09 framework review,
 * public-cli-endpoint package):
 *
 * - SEC-4/P7: state-changing commands (dbReset drops every table) were
 *   reachable over unauthenticated GET — CSRF-fireable from any page a
 *   developer visits. $cliCommandIsMutating() classifies the commands and
 *   $cliMutationGateCheck() enforces POST + loopback + reload password.
 * - SEC-5/P8: dbDump wrote its output through a raw expandPath(), so ../
 *   traversal escaped the application root. $cliResolveDumpPath()
 *   canonicalizes and confines to the web root (guideImage pattern).
 * - P3: dbStatus replaced the migrator's real status field with a
 *   version-comparison heuristic that misclassified out-of-sequence
 *   pending migrations as applied. $cliFormatMigrationStatus() maps the
 *   real field instead.
 * - P10: $cliDatabaseType() memoizes the $dbinfo-backed adapter probe so
 *   polled commands do not re-probe on every request.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("/wheels/cli endpoint hardening", () => {

			// Shared struct (not bare locals) so the beforeEach/afterEach/it
			// closures reliably see the same state on every engine.
			var state = {publicCfc = "", originalReloadPassword = "", hadReloadPassword = false};

			beforeEach(() => {
				state.publicCfc = createObject("component", "wheels.Public").$init();
				state.hadReloadPassword = StructKeyExists(application.wheels, "reloadPassword");
				if (state.hadReloadPassword) {
					state.originalReloadPassword = application.wheels.reloadPassword;
				}
			});

			afterEach(() => {
				if (state.hadReloadPassword) {
					application.wheels.reloadPassword = state.originalReloadPassword;
				} else {
					StructDelete(application.wheels, "reloadPassword");
				}
				StructDelete(application.wheels, "$cliDbTypeCache");
			});

			describe("$cliCommandIsMutating() classification", () => {

				it("classifies destructive and state-changing commands as mutating", () => {
					var mutating = [
						"dbReset",
						"dbSetup",
						"dbSeed",
						"dbCreate",
						"dbDump",
						"dbRollback",
						"migrateTo",
						"migrateToLatest",
						"migrateUp",
						"migrateDown",
						"redoMigration",
						"createMigration",
						"renameSystemTables",
						"forgetVersion",
						"pretendVersion",
						"jobsProcessNext",
						"jobsRetry",
						"jobsPurge"
					];
					for (var name in mutating) {
						expect(state.publicCfc.$cliCommandIsMutating(name)).toBeTrue("expected #name# to be mutating");
					}
				});

				it("leaves read-only commands reachable without the gate", () => {
					var readOnly = [
						"info",
						"doctor",
						"dbStatus",
						"dbVersion",
						"dbSchema",
						"dbShell",
						// dbDrop and dbRestore are currently STUBS that return
						// "use your database tools" messages (cli.cfm), so the
						// read-only classification is deliberate. If either is
						// ever implemented, it must move to the mutating list
						// and pass $cliMutationGateCheck (#2947 review, #2977).
						"dbDrop",
						"dbRestore",
						"routes",
						"introspect",
						"jobsStatus",
						"jobsMonitor"
					];
					for (var name in readOnly) {
						expect(state.publicCfc.$cliCommandIsMutating(name)).toBeFalse("expected #name# to be read-only");
					}
				});

				it("treats diff as read-only analysis unless it writes migration files", () => {
					expect(state.publicCfc.$cliCommandIsMutating("diff")).toBeFalse();
					expect(state.publicCfc.$cliCommandIsMutating("diff", false)).toBeFalse();
					expect(state.publicCfc.$cliCommandIsMutating("diff", true)).toBeTrue();
				});

				it("matches command names case-insensitively like the dispatch switch", () => {
					expect(state.publicCfc.$cliCommandIsMutating("DBRESET")).toBeTrue();
					expect(state.publicCfc.$cliCommandIsMutating("migratetolatest")).toBeTrue();
				});

			});

			describe("$cliMutationGateCheck() policy", () => {

				beforeEach(() => {
					application.wheels.reloadPassword = "test-secret-123";
				});

				it("rejects GET requests with a 405", () => {
					var gate = state.publicCfc.$cliMutationGateCheck(
						requestMethod = "GET",
						remoteAddr = "127.0.0.1",
						password = "test-secret-123"
					);
					expect(gate.allowed).toBeFalse();
					expect(gate.statusCode).toBe(405);
				});

				it("rejects POST from a non-loopback address", () => {
					var gate = state.publicCfc.$cliMutationGateCheck(
						requestMethod = "POST",
						remoteAddr = "8.8.8.8",
						password = "test-secret-123"
					);
					expect(gate.allowed).toBeFalse();
					expect(gate.statusCode).toBe(403);
				});

				it("rejects a non-loopback X-Forwarded-For hop (proxy bypass)", () => {
					var gate = state.publicCfc.$cliMutationGateCheck(
						requestMethod = "POST",
						remoteAddr = "127.0.0.1",
						forwardedFor = "127.0.0.1, 8.8.8.8",
						password = "test-secret-123"
					);
					expect(gate.allowed).toBeFalse();
					expect(gate.statusCode).toBe(403);
				});

				it("fails closed when the configured reload password is empty", () => {
					application.wheels.reloadPassword = "";
					var gate = state.publicCfc.$cliMutationGateCheck(
						requestMethod = "POST",
						remoteAddr = "127.0.0.1",
						password = ""
					);
					expect(gate.allowed).toBeFalse();
					expect(gate.statusCode).toBe(403);
				});

				it("fails closed when the reload password key is missing entirely", () => {
					StructDelete(application.wheels, "reloadPassword");
					var gate = state.publicCfc.$cliMutationGateCheck(
						requestMethod = "POST",
						remoteAddr = "127.0.0.1",
						password = "anything"
					);
					expect(gate.allowed).toBeFalse();
					expect(gate.statusCode).toBe(403);
				});

				it("rejects a wrong reload password", () => {
					var gate = state.publicCfc.$cliMutationGateCheck(
						requestMethod = "POST",
						remoteAddr = "127.0.0.1",
						password = "wrong-password"
					);
					expect(gate.allowed).toBeFalse();
					expect(gate.statusCode).toBe(403);
				});

				it("allows POST from IPv4 loopback with the correct password", () => {
					var gate = state.publicCfc.$cliMutationGateCheck(
						requestMethod = "POST",
						remoteAddr = "127.0.0.1",
						password = "test-secret-123"
					);
					expect(gate.allowed).toBeTrue();
					expect(gate.error).toBe("");
				});

				it("allows POST from IPv6 loopback with the correct password", () => {
					var gate = state.publicCfc.$cliMutationGateCheck(
						requestMethod = "POST",
						remoteAddr = "::1",
						password = "test-secret-123"
					);
					expect(gate.allowed).toBeTrue();
				});

				it("allows loopback-only X-Forwarded-For chains", () => {
					var gate = state.publicCfc.$cliMutationGateCheck(
						requestMethod = "POST",
						remoteAddr = "127.0.0.1",
						forwardedFor = "127.0.0.1, ::1",
						password = "test-secret-123"
					);
					expect(gate.allowed).toBeTrue();
				});

				it("treats an empty remote address as non-loopback (fail closed)", () => {
					var gate = state.publicCfc.$cliMutationGateCheck(
						requestMethod = "POST",
						remoteAddr = "",
						password = "test-secret-123"
					);
					expect(gate.allowed).toBeFalse();
				});

			});

			describe("$cliResolveDumpPath() containment (SEC-5)", () => {

				it("resolves a relative filename inside the web root", () => {
					var resolved = state.publicCfc.$cliResolveDumpPath("backup.sql");
					expect(Len(resolved)).toBeGT(0);
					expect(resolved).toInclude("backup.sql");
				});

				it("resolves a nested relative path inside the web root", () => {
					var resolved = state.publicCfc.$cliResolveDumpPath("db/dumps/backup.sql");
					expect(Len(resolved)).toBeGT(0);
					expect(resolved).toInclude("backup.sql");
				});

				it("rejects traversal that escapes the web root", () => {
					expect(state.publicCfc.$cliResolveDumpPath("../../../../../../tmp/evil.sql")).toBe("");
				});

				it("rejects traversal hidden behind a legitimate prefix", () => {
					expect(state.publicCfc.$cliResolveDumpPath("db/../../../../../../../tmp/evil.sql")).toBe("");
				});

				it("rejects an empty output path", () => {
					expect(state.publicCfc.$cliResolveDumpPath("")).toBe("");
					expect(state.publicCfc.$cliResolveDumpPath("   ")).toBe("");
				});

			});

			describe("$cliFormatMigrationStatus() real-status mapping (P3)", () => {

				it("reports out-of-sequence pending migrations as pending, not applied", () => {
					// A peer applied 0003 but this branch's 0002 has not run —
					// the exact shared-dev-DB drift `migrate doctor` surfaces.
					// The old `version <= currentVersion` heuristic called
					// 0002 "applied" because the DB sat at version 0003.
					var report = state.publicCfc.$cliFormatMigrationStatus([
						{version = "20240101000001", name = "create_users", status = "migrated"},
						{version = "20240101000002", name = "branch_only_migration", status = ""},
						{version = "20240101000003", name = "create_orders", status = "migrated"}
					]);
					expect(report.migrations[1].status).toBe("applied");
					expect(report.migrations[2].status).toBe("pending");
					expect(report.migrations[3].status).toBe("applied");
				});

				it("summarizes counts from the migrator's own status field", () => {
					var report = state.publicCfc.$cliFormatMigrationStatus([
						{version = "001", name = "a", status = "migrated"},
						{version = "002", name = "b", status = ""},
						{version = "003", name = "c", status = "migrated"}
					]);
					expect(report.summary.total).toBe(3);
					expect(report.summary.applied).toBe(2);
					expect(report.summary.pending).toBe(1);
				});

				it("keeps the appliedAt key (empty) and maps name to description", () => {
					var report = state.publicCfc.$cliFormatMigrationStatus([
						{version = "001", name = "create_users", status = "migrated"}
					]);
					expect(StructKeyExists(report.migrations[1], "appliedAt")).toBeTrue();
					expect(report.migrations[1].appliedAt).toBe("");
					expect(report.migrations[1].description).toBe("create_users");
				});

				it("returns an empty report for an empty discovery list", () => {
					var report = state.publicCfc.$cliFormatMigrationStatus([]);
					expect(ArrayLen(report.migrations)).toBe(0);
					expect(report.summary.total).toBe(0);
				});

			});

			describe("$cliDatabaseType() memoization (P10)", () => {

				it("probes the adapter name for the application datasource", () => {
					var dbType = state.publicCfc.$cliDatabaseType();
					expect(Len(dbType)).toBeGT(0);
				});

				it("returns the cached value on subsequent calls instead of re-probing", () => {
					application.wheels["$cliDbTypeCache"] = {};
					application.wheels.$cliDbTypeCache[application.wheels.dataSourceName] = "MemoizedSentinel";
					expect(state.publicCfc.$cliDatabaseType()).toBe("MemoizedSentinel");
				});

			});

		});

	}

}
