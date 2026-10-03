/**
 * Boot-time migration (#4063).
 *
 * A boolean WHEELS_MIGRATE_ON_BOOT environment variable overrides both
 * settings: true migrates strictly, false never migrates at start. Without it,
 * set(migrateOnBoot=true) migrates strictly and set(autoMigrateDatabase=true)
 * keeps its lenient behaviour. A strict boot migration that leaves any
 * migration pending fails the application start with Wheels.BootMigrationFailed.
 */
component extends="wheels.WheelsTest" {

	private any function newEvents() {
		return CreateObject("component", "wheels.events.onapplicationstart");
	}

	function run() {

		describe("$resolveBootMigration", () => {

			it("does not migrate when nothing asks for it", () => {
				var events = newEvents();
				expect(events.$resolveBootMigration(migrateOnBoot = false, autoMigrateDatabase = false)).toBe("none");
			});

			it("keeps autoMigrateDatabase lenient", () => {
				var events = newEvents();
				expect(events.$resolveBootMigration(migrateOnBoot = false, autoMigrateDatabase = true)).toBe("lenient");
			});

			it("migrates strictly with migrateOnBoot, whatever autoMigrateDatabase says", () => {
				var events = newEvents();
				expect(events.$resolveBootMigration(migrateOnBoot = true, autoMigrateDatabase = false)).toBe("strict");
				expect(events.$resolveBootMigration(migrateOnBoot = true, autoMigrateDatabase = true)).toBe("strict");
			});

			it("lets WHEELS_MIGRATE_ON_BOOT=true force a strict migration", () => {
				var events = newEvents();
				expect(events.$resolveBootMigration(migrateOnBoot = false, autoMigrateDatabase = false, envValue = "true")).toBe("strict");
				expect(events.$resolveBootMigration(migrateOnBoot = false, autoMigrateDatabase = true, envValue = "true")).toBe("strict");
			});

			it("lets WHEELS_MIGRATE_ON_BOOT=false turn off both settings", () => {
				var events = newEvents();
				expect(events.$resolveBootMigration(migrateOnBoot = true, autoMigrateDatabase = true, envValue = "false")).toBe("none");
				expect(events.$resolveBootMigration(migrateOnBoot = false, autoMigrateDatabase = true, envValue = "false")).toBe("none");
			});

			it("accepts the other CFML boolean spellings in the environment variable", () => {
				var events = newEvents();
				expect(events.$resolveBootMigration(migrateOnBoot = false, autoMigrateDatabase = false, envValue = " 1 ")).toBe("strict");
				expect(events.$resolveBootMigration(migrateOnBoot = true, autoMigrateDatabase = false, envValue = "no")).toBe("none");
			});

			it("ignores an empty or non-boolean environment variable", () => {
				var events = newEvents();
				expect(events.$resolveBootMigration(migrateOnBoot = false, autoMigrateDatabase = true, envValue = "")).toBe("lenient");
				expect(events.$resolveBootMigration(migrateOnBoot = true, autoMigrateDatabase = false, envValue = "strict")).toBe("strict");
				expect(events.$resolveBootMigration(migrateOnBoot = false, autoMigrateDatabase = false, envValue = "sometimes")).toBe("none");
			});

		});

		describe("$runStrictBootMigration", () => {

			it("returns the migrator output when every migration is applied", () => {
				var events = newEvents();
				var migrator = new wheels.tests._assets.events.BootMigrationStub(
					output = "Migrating from 0 up to 2.",
					statuses = ["migrated", "migrated"]
				);
				expect(events.$runStrictBootMigration(migrator)).toBe("Migrating from 0 up to 2.");
				expect(migrator.migrateCalls()).toBe(1);
			});

			it("succeeds when there are no migrations at all", () => {
				var events = newEvents();
				var migrator = new wheels.tests._assets.events.BootMigrationStub(output = "", statuses = []);
				expect(events.$runStrictBootMigration(migrator)).toBe("");
			});

			it("fails the start with Wheels.BootMigrationFailed when a migration is still pending", () => {
				var events = newEvents();
				var migrator = new wheels.tests._assets.events.BootMigrationStub(
					output = "Error migrating to 2.",
					statuses = ["migrated", ""]
				);
				var state = {type = "", message = "", detail = ""};
				try {
					events.$runStrictBootMigration(migrator);
				} catch (any e) {
					state.type = e.type;
					state.message = e.message;
					state.detail = e.detail;
				}
				expect(state.type).toBe("Wheels.BootMigrationFailed");
				expect(state.message).toInclude("1 migration(s) still pending (2)");
				expect(state.detail).toInclude("Error migrating to 2.");
			});

		});

		describe("migrateOnBoot setting", () => {

			it("defaults to false", () => {
				expect(application.wheels.migrateOnBoot).toBeFalse();
			});

			it("reads WHEELS_MIGRATE_ON_BOOT as a plain string", () => {
				var events = newEvents();
				expect(IsSimpleValue(events.$bootMigrationEnvValue())).toBeTrue();
			});

		});

	}

}
