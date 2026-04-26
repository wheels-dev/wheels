component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.cfg = new modules.wheels.services.deploy.config.ConfigLoader()
            .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml"));
    }

    function run() {
        describe("AuditorCommands", () => {

            it("record() appends to /tmp/kamal-audit.log with a timestamp and event", () => {
                var cmd = new modules.wheels.services.deploy.commands.AuditorCommands(variables.cfg)
                    .record("deployed v1");
                expect(cmd).toInclude("/tmp/kamal-audit.log");
                expect(cmd).toInclude("deployed v1");
                expect(cmd).toInclude(">>");
            });

            it("record() includes the service name in the log line", () => {
                var cmd = new modules.wheels.services.deploy.commands.AuditorCommands(variables.cfg)
                    .record("rolled back");
                expect(cmd).toInclude("demo");
            });
        });
    }
}
