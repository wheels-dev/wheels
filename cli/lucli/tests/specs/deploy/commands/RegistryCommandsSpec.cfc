component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.cfg = new modules.wheels.services.deploy.config.ConfigLoader()
            .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml"));
    }

    function run() {
        describe("RegistryCommands", () => {

            it("login() emits docker login with user and password", () => {
                var cmd = new modules.wheels.services.deploy.commands.RegistryCommands(variables.cfg)
                    .login({password: "s3cr3t"});
                expect(cmd).toInclude("docker login");
                expect(cmd).toInclude("-u demo");
                expect(cmd).toInclude("-p s3cr3t");
            });

            it("login() targets the configured server", () => {
                // minimal.yml has no explicit server, defaults to docker.io
                var cmd = new modules.wheels.services.deploy.commands.RegistryCommands(variables.cfg)
                    .login({password: "x"});
                expect(cmd).toInclude("docker.io");
            });

            it("logout() logs out of the configured server", () => {
                var cmd = new modules.wheels.services.deploy.commands.RegistryCommands(variables.cfg).logout();
                expect(cmd).toInclude("docker logout");
                expect(cmd).toInclude("docker.io");
            });
        });
    }
}
