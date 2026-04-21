component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.cfg = new cli.lucli.services.deploy.config.ConfigLoader()
            .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml"));
    }

    function run() {
        describe("BuilderCommands", () => {

            it("push() builds and pushes with --tag <image:version>", () => {
                var cmd = new cli.lucli.services.deploy.commands.BuilderCommands(variables.cfg)
                    .push("abc123");
                expect(cmd).toInclude("docker buildx build");
                expect(cmd).toInclude("--push");
                expect(cmd).toInclude("--tag acme/demo:abc123");
            });

            it("pull() pulls the versioned image", () => {
                var cmd = new cli.lucli.services.deploy.commands.BuilderCommands(variables.cfg)
                    .pull("v2");
                expect(cmd).toBe("docker pull acme/demo:v2");
            });

            it("tag() creates an alias", () => {
                var cmd = new cli.lucli.services.deploy.commands.BuilderCommands(variables.cfg)
                    .tag("abc123", "latest");
                expect(cmd).toInclude("docker tag");
                expect(cmd).toInclude("acme/demo:abc123");
                expect(cmd).toInclude("acme/demo:latest");
            });
        });
    }
}
