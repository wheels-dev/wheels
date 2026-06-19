component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.cfg = new cli.lucli.services.deploy.config.ConfigLoader()
            .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/with-accessories.yml"));
    }

    function run() {
        describe("AccessoryCommands", () => {

            it("run() emits docker run with service/role labels and port/volume/env", () => {
                var db = variables.cfg.accessory("db");
                var cmd = new cli.lucli.services.deploy.commands.AccessoryCommands(variables.cfg).run(db);
                expect(cmd).toInclude("docker run");
                expect(cmd).toInclude("--name demo-db");
                expect(cmd).toInclude("--network kamal");
                expect(cmd).toInclude("--label service=demo-db");
                expect(cmd).toInclude("--label role=db");
                expect(cmd).toInclude("--publish 5432:5432");
                expect(cmd).toInclude("--volume data:/var/lib/postgresql/data");
                expect(cmd).toInclude("-e 'POSTGRES_USER=demo'");
                expect(cmd).toInclude("postgres:16");
            });

            it("run() escapes env values containing shell metacharacters", () => {
                var tmp = getTempFile(getTempDirectory(), "yml");
                fileWrite(tmp, "service: demo#chr(10)#image: acme/demo#chr(10)#servers: [1.2.3.4]#chr(10)#"
                    & "accessories: {evil: {image: 'alpine:3', host: 1.2.3.5, "
                    & "env: {clear: {GREETING: 'hello $(whoami); rm -rf /'}}}}");
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(tmp);
                var cmd = new cli.lucli.services.deploy.commands.AccessoryCommands(cfg)
                    .run(cfg.accessory("evil"));
                expect(cmd).toInclude("-e 'GREETING=hello $(whoami); rm -rf /'");
                expect(cmd).notToInclude("-e GREETING");
            });

            // env.secret delivery (#2957, Wave 2b) — accessory secrets reach the
            // container via a remote env file (600 perms) referenced by --env-file.

            it("run() references the accessory env file via --env-file when env.secret is declared (##2957)", () => {
                var fullCfg = new cli.lucli.services.deploy.config.ConfigLoader()
                    .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/full.yml"));
                var cmd = new cli.lucli.services.deploy.commands.AccessoryCommands(fullCfg)
                    .run(fullCfg.accessory("mysql"));
                expect(cmd).toInclude("--env-file .kamal/apps/app/env/accessories/mysql.env");
                // The secret NAME must never surface as a -e pair.
                expect(cmd).notToInclude("-e 'MYSQL_ROOT_PASSWORD");
                expect(cmd).notToInclude("-e MYSQL_ROOT_PASSWORD");
            });

            it("run() omits --env-file when the accessory declares no env.secret", () => {
                var db = variables.cfg.accessory("db");
                var cmd = new cli.lucli.services.deploy.commands.AccessoryCommands(variables.cfg).run(db);
                expect(cmd).notToInclude("--env-file");
            });

            it("ensure_env_file() creates the env dir and pre-locks the file to 600 perms (##2957)", () => {
                var fullCfg = new cli.lucli.services.deploy.config.ConfigLoader()
                    .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/full.yml"));
                var cmds = new cli.lucli.services.deploy.commands.AccessoryCommands(fullCfg);
                var cmd = cmds.ensure_env_file(fullCfg.accessory("mysql"));
                expect(cmd).toInclude("mkdir -p '.kamal/apps/app/env/accessories'");
                expect(cmd).toInclude("touch '.kamal/apps/app/env/accessories/mysql.env'");
                expect(cmd).toInclude("chmod 600 '.kamal/apps/app/env/accessories/mysql.env'");
            });

            it("relock_env_file() re-locks the accessory env file to 600 perms after upload (##2957)", () => {
                var fullCfg = new cli.lucli.services.deploy.config.ConfigLoader()
                    .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/full.yml"));
                var cmds = new cli.lucli.services.deploy.commands.AccessoryCommands(fullCfg);
                expect(cmds.relock_env_file(fullCfg.accessory("mysql")))
                    .toBe("chmod 600 '.kamal/apps/app/env/accessories/mysql.env'");
            });

            it("start() starts the accessory container", () => {
                var db = variables.cfg.accessory("db");
                var cmd = new cli.lucli.services.deploy.commands.AccessoryCommands(variables.cfg).start(db);
                expect(cmd).toBe("docker start demo-db");
            });

            it("stop() stops the accessory container", () => {
                var db = variables.cfg.accessory("db");
                var cmd = new cli.lucli.services.deploy.commands.AccessoryCommands(variables.cfg).stop(db);
                expect(cmd).toBe("docker stop demo-db");
            });

            it("restart() restarts the accessory container", () => {
                var db = variables.cfg.accessory("db");
                var cmd = new cli.lucli.services.deploy.commands.AccessoryCommands(variables.cfg).restart(db);
                expect(cmd).toBe("docker restart demo-db");
            });

            it("details() inspects container state", () => {
                var db = variables.cfg.accessory("db");
                var cmd = new cli.lucli.services.deploy.commands.AccessoryCommands(variables.cfg).details(db);
                expect(cmd).toInclude("docker inspect");
                expect(cmd).toInclude("demo-db");
            });

            it("logs() honors tail option", () => {
                var db = variables.cfg.accessory("db");
                var cmd = new cli.lucli.services.deploy.commands.AccessoryCommands(variables.cfg).logs(db, {tail: 42});
                expect(cmd).toInclude("docker logs");
                expect(cmd).toInclude("--tail 42");
                expect(cmd).toInclude("demo-db");
            });

            it("remove() stops then removes the container", () => {
                var db = variables.cfg.accessory("db");
                var cmd = new cli.lucli.services.deploy.commands.AccessoryCommands(variables.cfg).remove(db);
                expect(cmd).toInclude("docker stop demo-db");
                expect(cmd).toInclude("docker rm demo-db");
            });

            it("reboot() chains remove + run", () => {
                var db = variables.cfg.accessory("db");
                var cmd = new cli.lucli.services.deploy.commands.AccessoryCommands(variables.cfg).reboot(db);
                expect(cmd).toInclude("docker stop demo-db");
                expect(cmd).toInclude("docker rm demo-db");
                expect(cmd).toInclude("docker run");
                expect(cmd).toInclude("--name demo-db");
            });
        });
    }
}
