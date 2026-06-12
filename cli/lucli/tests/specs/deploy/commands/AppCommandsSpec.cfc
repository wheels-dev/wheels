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

            // env.secret delivery (#2957, Wave 2b) — secrets reach the container
            // via a remote env file (600 perms) referenced by --env-file, never argv.

            it("run() references the role env file via --env-file when env.secret is declared (##2957)", () => {
                var tmp = getTempFile(getTempDirectory(), "yml");
                fileWrite(tmp, "service: demo#chr(10)#image: acme/demo#chr(10)#servers: [1.2.3.4]#chr(10)#"
                    & "env: {secret: [DATABASE_PASSWORD]}");
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(tmp);
                var cmd = new cli.lucli.services.deploy.commands.AppCommands(cfg)
                    .run(cfg.roles()[1], "v1");
                expect(cmd).toInclude("--env-file .kamal/apps/demo/env/roles/web.env");
                // The secret NAME must never surface as a -e pair.
                expect(cmd).notToInclude("-e 'DATABASE_PASSWORD");
                expect(cmd).notToInclude("-e DATABASE_PASSWORD");
            });

            it("run() omits --env-file when no env.secret is declared", () => {
                var cmd = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg)
                    .run(variables.cfg.roles()[1], "v1");
                expect(cmd).notToInclude("--env-file");
            });

            it("ensure_env_file() creates the env dir and pre-locks the file to 600 perms (##2957)", () => {
                var cmds = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg);
                var cmd = cmds.ensure_env_file(variables.cfg.roles()[1]);
                expect(cmd).toInclude("mkdir -p '.kamal/apps/demo/env/roles'");
                expect(cmd).toInclude("touch '.kamal/apps/demo/env/roles/web.env'");
                expect(cmd).toInclude("chmod 600 '.kamal/apps/demo/env/roles/web.env'");
            });

            it("relock_env_file() re-locks the role env file to 600 perms after upload (##2957)", () => {
                var cmds = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg);
                expect(cmds.relock_env_file(variables.cfg.roles()[1]))
                    .toBe("chmod 600 '.kamal/apps/demo/env/roles/web.env'");
            });

            it("env_file_path() namespaces by destination when one is set", () => {
                var cfg = new cli.lucli.services.deploy.config.Config(
                    {service: "demo", image: "acme/demo", servers: ["1.2.3.4"]},
                    {destination: "staging"}
                );
                var cmds = new cli.lucli.services.deploy.commands.AppCommands(cfg);
                expect(cmds.env_file_path(cfg.roles()[1]))
                    .toBe(".kamal/apps/demo-staging/env/roles/web.env");
            });

            it("env_file_content() renders KEY=value lines from resolved secrets (##2957)", () => {
                var cmds = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg);
                var content = cmds.env_file_content(
                    ["DB_PASSWORD", "API_KEY"],
                    {DB_PASSWORD: "p@ss", API_KEY: "key-1", UNRELATED: "x"}
                );
                expect(content).toInclude("DB_PASSWORD=p@ss");
                expect(content).toInclude("API_KEY=key-1");
                expect(content).notToInclude("UNRELATED");
            });

            it("env_file_content() escapes newlines and backslashes Kamal-style", () => {
                var cmds = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg);
                var content = cmds.env_file_content(
                    ["CERT"],
                    {CERT: "line1" & chr(10) & "line2\with-backslash"}
                );
                // Backslash doubled, literal newline collapsed to \n — one line per key.
                expect(content).toInclude("CERT=line1\nline2\\with-backslash");
            });

            it("env_file_content() throws Wheels.Deploy.EnvSecretMissing naming unresolved keys, values never read (##2957)", () => {
                var cmds = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg);
                var state = {threw: false, message: ""};
                try {
                    cmds.env_file_content(["PRESENT", "ABSENT_ONE"], {PRESENT: "v"});
                } catch (Wheels.Deploy.EnvSecretMissing e) {
                    state.threw = true;
                    state.message = e.message;
                }
                expect(state.threw).toBeTrue();
                expect(state.message).toInclude("ABSENT_ONE");
                // Only the MISSING names are listed — resolvable keys stay out.
                expect(state.message).notToInclude("PRESENT");
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
