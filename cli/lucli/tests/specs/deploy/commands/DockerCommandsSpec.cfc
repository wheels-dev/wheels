component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.cfg = new cli.lucli.services.deploy.config.ConfigLoader()
            .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml"));
    }

    function run() {
        describe("DockerCommands", () => {

            it("create_network() emits docker network create", () => {
                var cmd = new cli.lucli.services.deploy.commands.DockerCommands(variables.cfg)
                    .create_network("kamal");
                expect(cmd).toBe("docker network create kamal");
            });

            // #2957 DEP-5c — `docker network create` exits nonzero when the
            // network already exists, so the deploy/setup flows need an
            // idempotent guard (inspect probe || create) to be re-runnable.
            it("ensure_network() guards create with an inspect probe so reruns are idempotent (##2957)", () => {
                var cmd = new cli.lucli.services.deploy.commands.DockerCommands(variables.cfg)
                    .ensure_network("kamal");
                expect(cmd).toInclude("docker network inspect kamal");
                expect(cmd).toInclude(" || docker network create kamal");
            });
        });
    }
}
