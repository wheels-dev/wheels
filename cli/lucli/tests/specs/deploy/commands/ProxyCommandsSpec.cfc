component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.cfg = new cli.lucli.services.deploy.config.ConfigLoader()
            .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml"));
    }

    function run() {
        describe("ProxyCommands", () => {

            it("boot() runs the pinned kamal-proxy image", () => {
                var cmd = new cli.lucli.services.deploy.commands.ProxyCommands(variables.cfg).boot();
                expect(cmd).toInclude("docker run");
                expect(cmd).toInclude("--name kamal-proxy");
                expect(cmd).toInclude("basecamp/kamal-proxy:v0.8.6");
                expect(cmd).toInclude("--publish 80:80");
            });

            it("deploy() produces the hand-off to kamal-proxy CLI", () => {
                var cmd = new cli.lucli.services.deploy.commands.ProxyCommands(variables.cfg)
                    .deploy(variables.cfg.roles()[1], "demo-web-v1:3000");
                expect(cmd).toInclude("docker exec kamal-proxy");
                expect(cmd).toInclude("kamal-proxy deploy demo");
                expect(cmd).toInclude("--target demo-web-v1:3000");
                expect(cmd).toInclude("--health-check-path /up");
            });

            it("remove() stops and removes the proxy container", () => {
                var cmd = new cli.lucli.services.deploy.commands.ProxyCommands(variables.cfg).remove();
                expect(cmd).toInclude("docker stop kamal-proxy");
                expect(cmd).toInclude("docker rm kamal-proxy");
            });

            it("details() filters ps to the proxy container", () => {
                var cmd = new cli.lucli.services.deploy.commands.ProxyCommands(variables.cfg).details();
                expect(cmd).toInclude("docker ps");
                expect(cmd).toInclude("name=kamal-proxy");
            });

            it("logs() honors tail option", () => {
                var cmd = new cli.lucli.services.deploy.commands.ProxyCommands(variables.cfg)
                    .logs({tail: 42});
                expect(cmd).toInclude("docker logs");
                expect(cmd).toInclude("--tail 42");
                expect(cmd).toInclude("kamal-proxy");
            });

            it("reboot() chains remove + boot", () => {
                var cmd = new cli.lucli.services.deploy.commands.ProxyCommands(variables.cfg).reboot();
                expect(cmd).toInclude("docker stop kamal-proxy");
                expect(cmd).toInclude("docker rm kamal-proxy");
                expect(cmd).toInclude("docker run");
            });

            it("start() starts the kamal-proxy container", () => {
                var cmd = new cli.lucli.services.deploy.commands.ProxyCommands(variables.cfg).start();
                expect(cmd).toBe("docker start kamal-proxy");
            });

            it("stop() stops the kamal-proxy container", () => {
                var cmd = new cli.lucli.services.deploy.commands.ProxyCommands(variables.cfg).stop();
                expect(cmd).toBe("docker stop kamal-proxy");
            });

            it("restart() restarts the kamal-proxy container", () => {
                var cmd = new cli.lucli.services.deploy.commands.ProxyCommands(variables.cfg).restart();
                expect(cmd).toBe("docker restart kamal-proxy");
            });

            // #2957 DEP-5a — the old fresh-host guard was `details() || boot()`,
            // but details() is `docker ps --filter ...` which exits 0 whether or
            // not the proxy exists, so boot() was unreachable. Kamal's
            // Proxy#start_or_run (`docker start kamal-proxy || docker run ...`)
            // is the correct shape: start succeeds when the container exists
            // (running or stopped), run fires only on a truly fresh host.
            it("start_or_run() falls back from docker start to a full docker run (##2957)", () => {
                var px = new cli.lucli.services.deploy.commands.ProxyCommands(variables.cfg);
                var cmd = px.start_or_run();
                expect(cmd).toBe(px.start() & " || " & px.boot());
                expect(cmd).toInclude("docker start kamal-proxy || docker run");
                expect(cmd).notToInclude("docker ps");
            });

            // #2957 DEP-11c — boot() hardcoded the config volume to
            // /home/<ssh user>, but the DEFAULT ssh user is root, whose home
            // is /root. The mount path must derive the real remote home from
            // the ssh user instead of assuming the /home/<user> layout.
            it("boot() mounts /root for the default root ssh user (##2957 DEP-11c)", () => {
                var cmd = new cli.lucli.services.deploy.commands.ProxyCommands(variables.cfg).boot();
                expect(cmd).toInclude("--volume /root/.config/kamal-proxy:/home/kamal-proxy/.config/kamal-proxy");
                expect(cmd).notToInclude("/home/root");
            });

            it("boot() mounts /home/<user> for a non-root ssh user (##2957 DEP-11c)", () => {
                var sshCfg = new cli.lucli.services.deploy.config.ConfigLoader()
                    .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/with-ssh.yml"));
                var cmd = new cli.lucli.services.deploy.commands.ProxyCommands(sshCfg).boot();
                expect(cmd).toInclude("--volume /home/admin/.config/kamal-proxy:/home/kamal-proxy/.config/kamal-proxy");
            });
        });
    }
}
