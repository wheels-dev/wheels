component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.cfg = new cli.lucli.services.deploy.config.ConfigLoader()
            .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml"));
    }

    function run() {
        describe("RegistryCommands", () => {

            it("login() emits --password-stdin and never embeds a password", () => {
                var cmd = new cli.lucli.services.deploy.commands.RegistryCommands(variables.cfg)
                    .login();
                expect(cmd).toInclude("docker login");
                expect(cmd).toInclude("-u demo");
                expect(cmd).toInclude("--password-stdin");
                expect(cmd).notToInclude("s3cr3t");
                expect(cmd).notToInclude("-p ");
            });

            it("login() targets the configured server", () => {
                // minimal.yml has no explicit server, defaults to docker.io
                var cmd = new cli.lucli.services.deploy.commands.RegistryCommands(variables.cfg)
                    .login();
                expect(cmd).toInclude("docker.io");
            });

            it("logout() logs out of the configured server", () => {
                var cmd = new cli.lucli.services.deploy.commands.RegistryCommands(variables.cfg).logout();
                expect(cmd).toInclude("docker logout");
                expect(cmd).toInclude("docker.io");
            });
        });
    }
}
