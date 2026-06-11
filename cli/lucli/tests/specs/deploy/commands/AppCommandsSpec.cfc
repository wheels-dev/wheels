component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.cfg = new cli.lucli.services.deploy.config.ConfigLoader()
            .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml"));
    }

    function run() {
        describe("AppCommands", () => {

            it("run() produces expected docker-run string", () => {
                var cmd = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg)
                    .run(variables.cfg.roles()[1], "abc1234");
                expect(cmd).toInclude("docker run");
                expect(cmd).toInclude("--detach");
                expect(cmd).toInclude("--restart unless-stopped");
                expect(cmd).toInclude("--name demo-web-abc1234");
                expect(cmd).toInclude("--network kamal");
                expect(cmd).toInclude("--label service=demo");
                expect(cmd).toInclude("--label role=web");
                expect(cmd).toInclude("--label version=abc1234");
                expect(cmd).toInclude("acme/demo:abc1234");
            });

            it("container_name follows service-role-version convention", () => {
                var cmds = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg);
                expect(cmds.container_name(variables.cfg.roles()[1], "v1")).toBe("demo-web-v1");
            });

            it("containers() filters by service label", () => {
                var cmd = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg).containers();
                expect(cmd).toInclude("docker ps");
                expect(cmd).toInclude("--filter label=service=demo");
            });

            it("stop() targets the versioned container", () => {
                var cmd = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg)
                    .stop(variables.cfg.roles()[1], "v9");
                expect(cmd).toInclude("docker stop");
                expect(cmd).toInclude("demo-web-v9");
            });

            it("start() targets the versioned container", () => {
                var cmd = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg)
                    .start(variables.cfg.roles()[1], "v9");
                expect(cmd).toInclude("docker start");
                expect(cmd).toInclude("demo-web-v9");
            });

            it("logs() includes --tail and --follow flags when requested", () => {
                var cmds = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg);
                var cmd = cmds.logs({tail: 50, follow: true, container: "demo-web-abc"});
                expect(cmd).toInclude("docker logs");
                expect(cmd).toInclude("--tail 50");
                expect(cmd).toInclude("--follow");
                expect(cmd).toInclude("demo-web-abc");
            });

            it("maintenance() touches the marker file", () => {
                var cmd = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg)
                    .maintenance(variables.cfg.roles()[1], "v1");
                expect(cmd).toInclude("touch /tmp/kamal-maintenance-demo");
            });

            it("live() removes the marker file", () => {
                var cmd = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg)
                    .live(variables.cfg.roles()[1], "v1");
                expect(cmd).toInclude("rm -f /tmp/kamal-maintenance-demo");
            });

            it("run() escapes env values containing spaces and metacharacters", () => {
                var tmp = getTempFile(getTempDirectory(), "yml");
                fileWrite(tmp, "service: demo#chr(10)#image: acme/demo#chr(10)#servers: [1.2.3.4]#chr(10)#"
                    & "env: {clear: {GREETING: 'hello world; $(whoami)'}}");
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(tmp);
                var cmd = new cli.lucli.services.deploy.commands.AppCommands(cfg)
                    .run(cfg.roles()[1], "v1");
                expect(cmd).toInclude("-e 'GREETING=hello world; $(whoami)'");
                expect(cmd).notToInclude("-e GREETING");
            });

            it("run() rejects env.secret with a clear error instead of silently dropping it", () => {
                var tmp = getTempFile(getTempDirectory(), "yml");
                fileWrite(tmp, "service: demo#chr(10)#image: acme/demo#chr(10)#servers: [1.2.3.4]#chr(10)#"
                    & "env: {secret: [DATABASE_PASSWORD]}");
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(tmp);
                var state = {threw: false, message: ""};
                try {
                    new cli.lucli.services.deploy.commands.AppCommands(cfg)
                        .run(cfg.roles()[1], "v1");
                } catch (Wheels.Deploy.EnvSecretUnsupported e) {
                    state.threw = true;
                    state.message = e.message;
                }
                expect(state.threw).toBeTrue();
                expect(state.message).toInclude("DATABASE_PASSWORD");
            });

            it("remove() chains docker stop and docker rm", () => {
                var cmd = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg)
                    .remove(variables.cfg.roles()[1], "v9");
                expect(cmd).toInclude("docker stop demo-web-v9");
                expect(cmd).toInclude("docker rm demo-web-v9");
                expect(cmd).toInclude("&&");
            });
        });
    }
}
