component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.cfg = new modules.wheels.services.deploy.config.ConfigLoader()
            .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/with-accessories.yml"));
    }

    function run() {
        describe("AccessoryCommands", () => {

            it("run() emits docker run with service/role labels and port/volume/env", () => {
                var db = variables.cfg.accessory("db");
                var cmd = new modules.wheels.services.deploy.commands.AccessoryCommands(variables.cfg).run(db);
                expect(cmd).toInclude("docker run");
                expect(cmd).toInclude("--name demo-db");
                expect(cmd).toInclude("--network kamal");
                expect(cmd).toInclude("--label service=demo-db");
                expect(cmd).toInclude("--label role=db");
                expect(cmd).toInclude("--publish 5432:5432");
                expect(cmd).toInclude("--volume data:/var/lib/postgresql/data");
                expect(cmd).toInclude("-e POSTGRES_USER=demo");
                expect(cmd).toInclude("postgres:16");
            });

            it("start() starts the accessory container", () => {
                var db = variables.cfg.accessory("db");
                var cmd = new modules.wheels.services.deploy.commands.AccessoryCommands(variables.cfg).start(db);
                expect(cmd).toBe("docker start demo-db");
            });

            it("stop() stops the accessory container", () => {
                var db = variables.cfg.accessory("db");
                var cmd = new modules.wheels.services.deploy.commands.AccessoryCommands(variables.cfg).stop(db);
                expect(cmd).toBe("docker stop demo-db");
            });

            it("restart() restarts the accessory container", () => {
                var db = variables.cfg.accessory("db");
                var cmd = new modules.wheels.services.deploy.commands.AccessoryCommands(variables.cfg).restart(db);
                expect(cmd).toBe("docker restart demo-db");
            });

            it("details() inspects container state", () => {
                var db = variables.cfg.accessory("db");
                var cmd = new modules.wheels.services.deploy.commands.AccessoryCommands(variables.cfg).details(db);
                expect(cmd).toInclude("docker inspect");
                expect(cmd).toInclude("demo-db");
            });

            it("logs() honors tail option", () => {
                var db = variables.cfg.accessory("db");
                var cmd = new modules.wheels.services.deploy.commands.AccessoryCommands(variables.cfg).logs(db, {tail: 42});
                expect(cmd).toInclude("docker logs");
                expect(cmd).toInclude("--tail 42");
                expect(cmd).toInclude("demo-db");
            });

            it("remove() stops then removes the container", () => {
                var db = variables.cfg.accessory("db");
                var cmd = new modules.wheels.services.deploy.commands.AccessoryCommands(variables.cfg).remove(db);
                expect(cmd).toInclude("docker stop demo-db");
                expect(cmd).toInclude("docker rm demo-db");
            });

            it("reboot() chains remove + run", () => {
                var db = variables.cfg.accessory("db");
                var cmd = new modules.wheels.services.deploy.commands.AccessoryCommands(variables.cfg).reboot(db);
                expect(cmd).toInclude("docker stop demo-db");
                expect(cmd).toInclude("docker rm demo-db");
                expect(cmd).toInclude("docker run");
                expect(cmd).toInclude("--name demo-db");
            });
        });
    }
}
