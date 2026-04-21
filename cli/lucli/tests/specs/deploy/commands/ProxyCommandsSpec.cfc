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
        });
    }
}
