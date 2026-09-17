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

		describe("CliBridge migration handler branches (fake migrator)", () => {

			beforeEach(() => {
				bridge = new wheels.public.CliBridge();
			});

			it("createMigration forwards the migrationPrefix when supplied", () => {
				var fakeMigrator = {
					createMigration = function() { return StructCount(arguments); }
				};
				var rv = bridge.dispatch(
					command = "createMigration",
					context = {migrator = fakeMigrator},
					params = {migrationName = "AddFoo", templateName = "create", migrationPrefix = "20260101000000"}
				);
				expect(rv.message).toBe(3);
			});

			it("createMigration omits the migrationPrefix when not supplied", () => {
				var fakeMigrator = {
					createMigration = function() { return StructCount(arguments); }
				};
				var rv = bridge.dispatch(
					command = "createMigration",
					context = {migrator = fakeMigrator},
					params = {migrationName = "AddFoo", templateName = "create"}
				);
				expect(rv.message).toBe(2);
			});

			it("migrateTo forwards the requested version", () => {
				var fakeMigrator = {migrateTo = (version) => "Migrated to " & version};
				var rv = bridge.dispatch(
					command = "migrateTo",
					context = {migrator = fakeMigrator},
					params = {version = "20260102000000"}
				);
				expect(rv.message).toBe("Migrated to 20260102000000");
			});

			it("migrateTo returns an empty result when no version is supplied", () => {
				var fakeMigrator = {migrateTo = (version) => "Migrated to " & version};
				var rv = bridge.dispatch(
					command = "migrateTo",
					context = {migrator = fakeMigrator},
					params = {}
				);
				expect(StructKeyExists(rv, "message")).toBeFalse();
			});

			it("migrateUp migrates to the first pending version", () => {
				var fakeMigrator = {migrateTo = (version) => "Migrated to " & version};
				var rv = bridge.dispatch(
					command = "migrateUp",
					context = {
						currentVersion = "20260101000000",
						migrations = [
							{version = "20260101000000", status = "migrated"},
							{version = "20260102000000", status = "pending"}
						],
						migrator = fakeMigrator
					},
					params = {}
				);
				expect(rv.message).toBe("Migrated to 20260102000000");
			});

			it("migrateUp reports no pending migrations", () => {
				var fakeMigrator = {migrateTo = (version) => "Migrated to " & version};
				var rv = bridge.dispatch(
					command = "migrateUp",
					context = {
						currentVersion = "20260101000000",
						migrations = [
							{version = "20260101000000", status = "migrated"}
						],
						migrator = fakeMigrator
					},
					params = {}
				);
				expect(rv.message).toInclude("No pending migrations");
			});

			it("migrateDown migrates to the version immediately below current", () => {
				var fakeMigrator = {migrateTo = (version) => "Migrated to " & version};
				var rv = bridge.dispatch(
					command = "migrateDown",
					context = {
						currentVersion = "20260102000000",
						migrations = [
							{version = "20260101000000", status = "migrated"},
							{version = "20260102000000", status = "migrated"}
						],
						migrator = fakeMigrator
					},
					params = {}
				);
				expect(rv.message).toBe("Migrated to 20260101000000");
			});

			it("migrateDown reports nothing to roll back at version 0", () => {
				var fakeMigrator = {migrateTo = (version) => "Migrated to " & version};
				var rv = bridge.dispatch(
					command = "migrateDown",
					context = {
						currentVersion = "0",
						migrations = [],
						migrator = fakeMigrator
					},
					params = {}
				);
				expect(rv.message).toInclude("nothing to roll back");
			});

			it("renameSystemTables surfaces a skipped message", () => {
				var fakeMigrator = {
					renameSystemTables = function(dryRun) {
						return {success = true, skipped = "No legacy tables", renamed = [], sql = []};
					}
				};
				var rv = bridge.dispatch(
					command = "renameSystemTables",
					context = {migrator = fakeMigrator},
					params = {}
				);
				expect(rv.success).toBeTrue();
				expect(rv.message).toBe("No legacy tables");
			});

			it("renameSystemTables lists renamed tables", () => {
				var fakeMigrator = {
					renameSystemTables = function(dryRun) {
						return {success = true, skipped = "", renamed = ["core_users", "core_posts"], sql = []};
					}
				};
				var rv = bridge.dispatch(
					command = "renameSystemTables",
					context = {migrator = fakeMigrator},
					params = {}
				);
				expect(rv.message).toInclude("Renamed:");
				expect(rv.message).toInclude("core_users");
			});

			it("renameSystemTables dry-run lists the SQL that would execute", () => {
				var fakeMigrator = {
					renameSystemTables = function(dryRun) {
						return {success = true, skipped = "", renamed = [], sql = ["ALTER TABLE core_users RENAME TO users"]};
					}
				};
				var rv = bridge.dispatch(
					command = "renameSystemTables",
					context = {migrator = fakeMigrator},
					params = {dryRun = "true"}
				);
				expect(rv.message).toInclude("Dry run");
				expect(rv.message).toInclude("ALTER TABLE core_users");
			});

			it("redoMigration uses the requested version", () => {
				var fakeMigrator = {redoMigration = (version) => "Redone " & version};
				var rv = bridge.dispatch(
					command = "redoMigration",
					context = {lastVersion = "20260101000000", migrator = fakeMigrator},
					params = {version = "20260102000000"}
				);
				expect(rv.message).toBe("Redone 20260102000000");
			});

			it("redoMigration falls back to lastVersion", () => {
				var fakeMigrator = {redoMigration = (version) => "Redone " & version};
				var rv = bridge.dispatch(
					command = "redoMigration",
					context = {lastVersion = "20260101000000", migrator = fakeMigrator},
					params = {}
				);
				expect(rv.message).toBe("Redone 20260101000000");
			});

			it("info renders datasource, type, and migrator output", () => {
				var fakeMigrator = {$buildInfoOutput = function() { return ["line1", "line2"]; }};
				var rv = bridge.dispatch(
					command = "info",
					context = {datasource = "myds", databaseType = "SQLite", migrator = fakeMigrator},
					params = {}
				);
				expect(rv.message).toInclude("Datasource: myds");
				expect(rv.message).toInclude("Database type: SQLite");
				expect(rv.message).toInclude("line1");
				expect(rv.message).toInclude("line2");
			});

			it("doctor surfaces report details including orphans and pending", () => {
				var fakeMigrator = {
					doctor = function() {
						return {
							healthy = true,
							currentVersion = "20260102000000",
							orphans = ["20250101000000"],
							orphansWithMeta = [{version = "20250101000000", name = "CreateUsers", appliedAt = "2025-01-01"}],
							pending = ["20260103000000"],
							summary = {total = 4, applied = 2, pending = 1, orphan = 1},
							message = "Health check"
						};
					}
				};
				var rv = bridge.dispatch(
					command = "doctor",
					context = {datasource = "myds", databaseType = "SQLite", migrator = fakeMigrator},
					params = {}
				);
				expect(rv.healthy).toBeTrue();
				expect(rv.currentVersion).toBe("20260102000000");
				expect(rv.message).toInclude("Datasource: myds");
				expect(rv.message).toInclude("orphan:");
				expect(rv.message).toInclude("CreateUsers");
				expect(rv.message).toInclude("20260103000000");
			});

			it("doctor renders an empty report without orphan/pending sections", () => {
				var fakeMigrator = {
					doctor = function() {
						return {
							healthy = false,
							currentVersion = "0",
							orphans = [],
							orphansWithMeta = [],
							pending = [],
							summary = {total = 0, applied = 0, pending = 0, orphan = 0},
							message = "Nothing to report"
						};
					}
				};
				var rv = bridge.dispatch(
					command = "doctor",
					context = {datasource = "myds", databaseType = "SQLite", migrator = fakeMigrator},
					params = {}
				);
				expect(rv.healthy).toBeFalse();
				expect(rv.message).toInclude("Current version: 0");
				expect(rv.message).toInclude("Total migrations: 0");
			});

			it("forgetVersion forwards a version to the migrator", () => {
				var fakeMigrator = {
					forgetVersion = function(version) {
						return {success = true, removed = 1, message = "Forgot " & version};
					}
				};
				var rv = bridge.dispatch(
					command = "forgetVersion",
					context = {migrator = fakeMigrator},
					params = {version = "20250101000000"}
				);
				expect(rv.success).toBeTrue();
				expect(rv.removed).toBe(1);
				expect(rv.message).toBe("Forgot 20250101000000");
			});

			it("pretendVersion forwards a version to the migrator", () => {
				var fakeMigrator = {
					pretendVersion = function(version) {
						return {success = true, recorded = 1, message = "Recorded " & version};
					}
				};
				var rv = bridge.dispatch(
					command = "pretendVersion",
					context = {migrator = fakeMigrator},
					params = {version = "20260103000000"}
				);
				expect(rv.success).toBeTrue();
				expect(rv.recorded).toBe(1);
				expect(rv.message).toBe("Recorded 20260103000000");
			});

		});

		describe("CliBridge database handler branches (fakes)", () => {

			beforeEach(() => {
				bridge = new wheels.public.CliBridge();
			});

			it("dbStatus formats migration status through the host", () => {
				var fakeHost = {
					$cliFormatMigrationStatus = function(migrations) {
						return {
							migrations = migrations,
							summary = {total = ArrayLen(migrations), applied = 0, pending = ArrayLen(migrations)}
						};
					}
				};
				var migrations = [
					{version = "20260101000000", status = "migrated"},
					{version = "20260102000000", status = "pending"}
				];
				var rv = bridge.dispatch(
					command = "dbStatus",
					context = {host = fakeHost, migrations = migrations},
					params = {}
				);
				expect(rv.success).toBeTrue();
				expect(rv.summary.total).toBe(2);
			});

			it("dbRollback rolls back a single step by default", () => {
				var fakeMigrator = {migrateTo = (version) => "Migrated to " & version};
				var rv = bridge.dispatch(
					command = "dbRollback",
					context = {
						migrations = [
							{version = "20260101000000", status = "migrated"},
							{version = "20260102000000", status = "migrated"},
							{version = "20260103000000", status = "migrated"}
						],
						migrator = fakeMigrator
					},
					params = {}
				);
				expect(rv.success).toBeTrue();
				expect(rv.message).toBe("Migrated to 20260102000000");
			});

			it("dbRollback rolls back to version 0 when steps equal the applied count", () => {
				var fakeMigrator = {migrateTo = (version) => "Migrated to " & version};
				var rv = bridge.dispatch(
					command = "dbRollback",
					context = {
						migrations = [
							{version = "20260101000000", status = "migrated"},
							{version = "20260102000000", status = "migrated"},
							{version = "20260103000000", status = "migrated"}
						],
						migrator = fakeMigrator
					},
					params = {steps = 3}
				);
				expect(rv.success).toBeTrue();
				expect(rv.message).toBe("Migrated to 0");
			});

			it("dbRollback reports no migrations to rollback", () => {
				var fakeMigrator = {migrateTo = (version) => "Migrated to " & version};
				var rv = bridge.dispatch(
					command = "dbRollback",
					context = {
						migrations = [
							{version = "20260101000000", status = "pending"}
						],
						migrator = fakeMigrator
					},
					params = {}
				);
				expect(rv.success).toBeFalse();
				expect(rv.message).toInclude("No migrations to rollback");
			});

			it("dbCreate prints MySQL DDL guidance", () => {
				var rv = bridge.dispatch(
					command = "dbCreate",
					context = {databaseType = "MySQL"},
					params = {}
				);
				expect(rv.message).toInclude("CREATE DATABASE dbname CHARACTER SET utf8mb4");
			});

			it("dbCreate prints PostgreSQL DDL guidance", () => {
				var rv = bridge.dispatch(
					command = "dbCreate",
					context = {databaseType = "PostgreSQL"},
					params = {}
				);
				expect(rv.message).toInclude("PostgreSQL: CREATE DATABASE dbname");
			});

			it("dbDrop refuses to drop the database", () => {
				var rv = bridge.dispatch(command = "dbDrop", context = {}, params = {});
				expect(rv.success).toBeFalse();
				expect(rv.message).toInclude("Database dropping must be done");
			});

			it("dbSetup migrates to latest when no seed is requested", () => {
				var fakeMigrator = {migrateToLatest = function() { return "Migrated to latest."; }};
				var rv = bridge.dispatch(
					command = "dbSetup",
					context = {migrator = fakeMigrator},
					params = {}
				);
				expect(rv.success).toBeTrue();
				expect(rv.message).toInclude("Migrations completed.");
			});

			it("dbRestore prints MySQL restore guidance", () => {
				var rv = bridge.dispatch(
					command = "dbRestore",
					context = {databaseType = "MySQL"},
					params = {}
				);
				expect(rv.success).toBeFalse();
				expect(rv.message).toInclude("mysql -u");
			});

			it("dbRestore prints H2 RUNSCRIPT guidance", () => {
				var rv = bridge.dispatch(
					command = "dbRestore",
					context = {databaseType = "H2"},
					params = {}
				);
				expect(rv.message).toInclude("RUNSCRIPT");
			});

			it("dbShell prints MySQL shell guidance", () => {
				var rv = bridge.dispatch(
					command = "dbShell",
					context = {databaseType = "MySQL"},
					params = {}
				);
				expect(rv.message).toInclude("mysql -u");
			});

			it("routes returns the application route list", () => {
				var rv = bridge.dispatch(command = "routes", context = {}, params = {});
				expect(rv.success).toBeTrue();
				expect(IsArray(rv.routes)).toBeTrue();
			});

			it("introspect builds column and association metadata for a model", () => {
				var fakeHost = {
					model = function(modelName) {
						return {
							$classData = function() {
								return {
									tableName = "authors",
									keys = "id",
									properties = {
										id = {type = "integer"},
										name = {type = "string", maxLength = 100},
										authorId = {type = "integer"}
									},
									associations = {
										posts = {type = "hasMany", modelName = "post"}
									}
								};
							}
						};
					}
				};
				var rv = bridge.dispatch(
					command = "introspect",
					context = {host = fakeHost},
					params = {model = "Author"}
				);
				expect(rv.success).toBeTrue();
				expect(rv.tableName).toBe("authors");
				expect(rv.primaryKey).toBe("id");
				expect(ArrayLen(rv.columns)).toBe(3);
				expect(ArrayLen(rv.associations)).toBe(1);

				// Struct iteration order is not guaranteed cross-engine, so
				// resolve columns by name rather than position.
				var idColumn = {};
				var nameColumn = {};
				var authorColumn = {};
				for (var col in rv.columns) {
					if (col.name == "id") { idColumn = col; }
					if (col.name == "name") { nameColumn = col; }
					if (col.name == "authorId") { authorColumn = col; }
				}
				expect(idColumn.primaryKey).toBeTrue();
				expect(nameColumn.maxLength).toBe(100);
				expect(authorColumn.foreignKey).toBeTrue();
				expect(authorColumn.referencedModel).toBe("Author");

				expect(rv.associations[1].type).toBe("hasMany");
				expect(rv.associations[1].modelName).toBe("Post");
			});

		});

	}

}
