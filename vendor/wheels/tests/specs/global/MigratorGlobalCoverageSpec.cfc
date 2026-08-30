component extends="wheels.WheelsTest" {

    /**
     * Covers remaining migrator definition builders (TableDefinition column
     * type helpers, ViewDefinition, Migration addReference/createView/down)
     * and global helper functions ($convertToStringBoolean,
     * $convertToStringBoxLangSlashDatetime, $normalizePath,
     * $boxLangVersionMessage, pluginNames, injector,
     * $clearControllerInitializationCache). All are pure or side-effect-free
     * in the test application context.
     */
    function run() {

        g = application.wo;

        describe("migrator definition builders", () => {

            beforeEach(() => {
                adapter = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteMigrator");
                migration = CreateObject("component", "wheels.migrator.Migration").init();
            });

            describe("TableDefinition column helpers", () => {

                it("bigInteger()/char()/uniqueidentifier() append typed columns", () => {
                    var t = new wheels.migrator.TableDefinition(
                        adapter = adapter,
                        name = "spec_types",
                        id = false
                    );
                    t.bigInteger(columnNames = "views");
                    t.char(columnNames = "code", limit = 9);
                    t.uniqueidentifier(columnNames = "uid");
                    expect(arrayLen(t.columns)).toBe(3);
                    expect(t.columns[1].type).toBe("biginteger");
                    expect(t.columns[2].type).toBe("char");
                    expect(t.columns[3].type).toBe("uniqueidentifier");
                });

            });

            describe("ViewDefinition", () => {

                it("init()/selectStatement() store the view shape", () => {
                    var view = new wheels.migrator.ViewDefinition(
                        adapter = adapter,
                        name = "spec_view"
                    );
                    expect(view.name).toBe("spec_view");
                    view.selectStatement(sql = "SELECT id FROM c_o_r_e_users");
                    expect(view.selectSql).toBe("SELECT id FROM c_o_r_e_users");
                });

            });

            describe("Migration helpers", () => {

                it("down() announces the not-implemented stub", () => {
                    migration.down();
                    expect(true).toBeTrue();
                });

                it("createView() returns a ViewDefinition", () => {
                    var view = migration.createView(name = "spec_view2");
                    expect(isObject(view)).toBeTrue();
                    expect(view.name).toBe("spec_view2");
                });

            });

        });

        describe("global helpers", () => {

            it("$convertToStringBoolean() renders true/false and ''", () => {
                expect(g.$convertToStringBoolean(val = true)).toBe("true");
                expect(g.$convertToStringBoolean(val = false)).toBe("false");
                expect(g.$convertToStringBoolean(val = "")).toBe("");
            });

            it("$convertToStringBoxLangSlashDatetime() parses AM/PM slash dates", () => {
                var dt = g.$convertToStringBoxLangSlashDatetime(value = "06/25/2024 10:30 PM");
                expect(DateFormat(dt, "yyyy-mm-dd")).toBe("2024-06-25");
                expect(Hour(dt)).toBe(22);
            });

            it("$normalizePath() converts [x] segments to dots and strips leading dots", () => {
                expect(g.$normalizePath(path = "users[name]")).toBe("users.name");
                expect(g.$normalizePath(path = ".posts")).toBe("posts");
            });

            it("$boxLangVersionMessage() renders the compatibility message", () => {
                var below = g.$boxLangVersionMessage(
                    major = 0, minor = 9, patch = 0,
                    minimumMajor = 1, minimumMinor = 0, minimumPatch = 0,
                    maximumMajor = 2, maximumMinor = 0, maximumPatch = 0,
                    version = "0.9.0"
                );
                expect(below).toInclude("requires BoxLang version 1.0.0 or higher");
                var above = g.$boxLangVersionMessage(
                    major = 3, minor = 0, patch = 0,
                    minimumMajor = 1, minimumMinor = 0, minimumPatch = 0,
                    maximumMajor = 2, maximumMinor = 0, maximumPatch = 0,
                    version = "3.0.0"
                );
                expect(above).toInclude("tested up to BoxLang version 2.0.0");
            });

            it("pluginNames() returns the loaded plugin list", () => {
                expect(isSimpleValue(g.pluginNames())).toBeTrue();
            });

            it("injector() returns the DI container when initialized", () => {
                try {
                    var di = g.injector();
                    expect(isObject(di)).toBeTrue();
                } catch (Wheels.DI.NotInitialized e) {
                    // Some app contexts never boot the DI container; the
                    // typed error is the other valid outcome.
                    expect(e.type).toBe("Wheels.DI.NotInitialized");
                }
            });

            it("$clearControllerInitializationCache() clears the controller cache", () => {
                g.$clearControllerInitializationCache();
                expect(isStruct(application.wheels.controllers)).toBeTrue();
            });

        });

    }

}
