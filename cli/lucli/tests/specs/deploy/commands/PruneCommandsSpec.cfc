component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.cfg = new modules.wheels.services.deploy.config.ConfigLoader()
            .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml"));
        variables.prune = new modules.wheels.services.deploy.commands.PruneCommands(variables.cfg);
    }

    function run() {
        describe("PruneCommands", () => {

            it("images() emits docker image prune with service label filter", () => {
                var cmd = variables.prune.images();
                expect(cmd).toInclude("docker image prune");
                expect(cmd).toInclude("label=service=demo");
            });

            it("containers() keeps the last 5 by default", () => {
                var cmd = variables.prune.containers();
                expect(cmd).toInclude("docker ps -a");
                expect(cmd).toInclude("status=exited");
                expect(cmd).toInclude("tail -n +6");
                expect(cmd).toInclude("xargs -r docker rm");
            });

            it("containers(keep) respects the explicit keep count", () => {
                var cmd = variables.prune.containers(10);
                expect(cmd).toInclude("tail -n +11");
            });

            it("all() chains containers and images", () => {
                var cmd = variables.prune.all();
                expect(cmd).toInclude("docker ps -a");
                expect(cmd).toInclude("docker image prune");
                expect(cmd).toInclude("&&");
            });
        });
    }
}
