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

            it("create() emits buildx create with service-scoped builder name", () => {
                var cmd = new cli.lucli.services.deploy.commands.BuilderCommands(variables.cfg)
                    .create();
                expect(cmd).toInclude("docker buildx create");
                expect(cmd).toInclude("--name kamal-demo");
                expect(cmd).toInclude("--driver=docker-container");
            });

            it("remove() emits buildx rm with service-scoped builder name", () => {
                var cmd = new cli.lucli.services.deploy.commands.BuilderCommands(variables.cfg)
                    .remove();
                expect(cmd).toBe("docker buildx rm kamal-demo");
            });

            it("details() emits buildx inspect with service-scoped builder name", () => {
                var cmd = new cli.lucli.services.deploy.commands.BuilderCommands(variables.cfg)
                    .details();
                expect(cmd).toBe("docker buildx inspect kamal-demo");
            });

            it("dev() emits --load buildx build tagged :dirty", () => {
                var cmd = new cli.lucli.services.deploy.commands.BuilderCommands(variables.cfg)
                    .dev();
                expect(cmd).toInclude("docker buildx build");
                expect(cmd).toInclude("--load");
                expect(cmd).toInclude("--tag acme/demo:dirty");
                expect(cmd).notToInclude("--push");
            });

            it("push() and dev() shell-escape the dockerfile and context paths", () => {
                var push = new cli.lucli.services.deploy.commands.BuilderCommands(variables.cfg)
                    .push("v1");
                expect(push).toInclude("--file 'Dockerfile'");
                expect(push).toInclude(" '.'");
                var dev = new cli.lucli.services.deploy.commands.BuilderCommands(variables.cfg)
                    .dev();
                expect(dev).toInclude("--file 'Dockerfile'");
                expect(dev).toInclude(" '.'");
            });

            it("$builderName() prefixes kamal- to the service name", () => {
                var bc = new cli.lucli.services.deploy.commands.BuilderCommands(variables.cfg);
                expect(bc.$builderName()).toBe("kamal-demo");
            });
        });
    }
}
