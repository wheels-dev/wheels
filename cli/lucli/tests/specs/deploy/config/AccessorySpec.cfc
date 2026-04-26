component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/with-accessories.yml");
        variables.cfg = new modules.wheels.services.deploy.config.ConfigLoader().load(variables.fixture);
    }

    function run() {
        describe("Config.accessories / Config.accessory", () => {

            it("accessories() returns all accessories as Accessory instances", () => {
                var list = variables.cfg.accessories();
                expect(arrayLen(list)).toBe(2);
                var names = [];
                for (var a in list) arrayAppend(names, a.name());
                expect(arrayContainsNoCase(names, "db")).toBeTrue();
                expect(arrayContainsNoCase(names, "redis")).toBeTrue();
            });

            it("accessory(name) returns the named accessory", () => {
                var db = variables.cfg.accessory("db");
                expect(db.name()).toBe("db");
                expect(db.image()).toBe("postgres:16");
            });

            it("accessory(name) throws DeployConfigError for unknown name", () => {
                var thrown = false;
                try {
                    variables.cfg.accessory("nope");
                } catch (DeployConfigError e) {
                    thrown = true;
                    expect(e.message).toInclude("Unknown accessory: nope");
                }
                expect(thrown).toBeTrue();
            });
        });

        describe("Accessory accessors", () => {

            it("hosts() normalizes scalar host to array", () => {
                var db = variables.cfg.accessory("db");
                var hs = db.hosts();
                expect(isArray(hs)).toBeTrue();
                expect(arrayLen(hs)).toBe(1);
                expect(hs[1]).toBe("1.2.3.5");
            });

            it("port() returns the port mapping string", () => {
                expect(variables.cfg.accessory("db").port()).toBe("5432:5432");
                expect(variables.cfg.accessory("redis").port()).toBe("6379:6379");
            });

            it("volumes() accepts directories: as canonical accessory form", () => {
                var vols = variables.cfg.accessory("db").volumes();
                expect(arrayLen(vols)).toBe(1);
                expect(vols[1]).toBe("data:/var/lib/postgresql/data");
                // redis has no directories/volumes
                expect(arrayLen(variables.cfg.accessory("redis").volumes())).toBe(0);
            });

            it("containerName() is <service>-<accessory_name>", () => {
                expect(variables.cfg.accessory("db").containerName()).toBe("demo-db");
                expect(variables.cfg.accessory("redis").containerName()).toBe("demo-redis");
            });

            it("labelService() is <service>-<accessory_name>", () => {
                expect(variables.cfg.accessory("db").labelService()).toBe("demo-db");
            });
        });
    }
}
