/**
 * Version and destination values are interpolated into shell commands that run
 * on every deploy host (and locally for builds). They must be restricted to a
 * safe token shape at the point they are used, and free-text audit events must
 * reach the remote shell quoted.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.fixture = expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml");
        variables.cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(variables.fixture);
    }

    function run() {
        describe("Deploy input validation", () => {

            describe("version tokens", () => {

                it("accepts ordinary release, tag and sha versions", () => {
                    var app = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg);
                    var role = variables.cfg.roles()[1];
                    expect(app.container_name(role, "v1.2.3")).toBe("demo-web-v1.2.3");
                    expect(app.container_name(role, "abc1234")).toBe("demo-web-abc1234");
                    expect(app.container_name(role, "feature_x-2")).toBe("demo-web-feature_x-2");
                    expect(variables.cfg.absoluteImage("v1.2.3")).toInclude(":v1.2.3");
                });

                it("rejects a version carrying command substitution in the container name", () => {
                    var app = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg);
                    expect(() => app.container_name(variables.cfg.roles()[1], "feat$(id)"))
                        .toThrow("Wheels.Deploy.InvalidInput");
                });

                it("rejects a version carrying a command separator", () => {
                    var app = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg);
                    expect(() => app.start(variables.cfg.roles()[1], "v1;id"))
                        .toThrow("Wheels.Deploy.InvalidInput");
                });

                it("rejects a version with shell metacharacters in the image tag", () => {
                    expect(() => variables.cfg.absoluteImage("v1`id`"))
                        .toThrow("Wheels.Deploy.InvalidInput");
                    expect(() => variables.cfg.absoluteImage("v1 --privileged"))
                        .toThrow("Wheels.Deploy.InvalidInput");
                });

                it("rejects an empty or oversized version", () => {
                    expect(() => variables.cfg.absoluteImage("")).toThrow("Wheels.Deploy.InvalidInput");
                    expect(() => variables.cfg.absoluteImage(repeatString("a", 129)))
                        .toThrow("Wheels.Deploy.InvalidInput");
                });

                it("rejects a version ending in a line feed, carriage return or tab", () => {
                    var app = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg);
                    for (var ending in [chr(10), chr(13), chr(9)]) {
                        var bad = "v1.2.3" & ending;
                        expect(() => app.container_name(variables.cfg.roles()[1], bad)).toThrow("Wheels.Deploy.InvalidInput");
                        expect(() => variables.cfg.absoluteImage(bad)).toThrow("Wheels.Deploy.InvalidInput");
                    }
                });

                it("rejects an unsafe version in docker run labels", () => {
                    var app = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg);
                    expect(() => app.run(variables.cfg.roles()[1], "x|id"))
                        .toThrow("Wheels.Deploy.InvalidInput");
                });
            });

            describe("destination", () => {

                it("accepts an ordinary destination and an empty one", () => {
                    var loader = new cli.lucli.services.deploy.config.ConfigLoader();
                    expect(loader.load(variables.fixture, {destination: ""}).destination()).toBe("");
                });

                it("rejects a destination carrying shell metacharacters", () => {
                    expect(() => new cli.lucli.services.deploy.config.Config({service: "demo"}, {destination: "prod;id"}))
                        .toThrow("Wheels.Deploy.InvalidInput");
                    expect(() => new cli.lucli.services.deploy.config.Config({service: "demo"}, {destination: "p$(id)"}))
                        .toThrow("Wheels.Deploy.InvalidInput");
                });
            });

            describe("destination line endings", () => {

                it("rejects a destination ending in a line feed, carriage return or tab", () => {
                    for (var ending in [chr(10), chr(13), chr(9)]) {
                        var bad = "prod" & ending;
                        expect(() => new cli.lucli.services.deploy.config.Config({service: "demo"}, {destination: bad}))
                            .toThrow("Wheels.Deploy.InvalidInput");
                    }
                });
            });

            describe("audit events", () => {

                it("keeps command substitution in the event inert when the shell runs it", () => {
                    var scratch = getTempDirectory() & "wheels-audit-" & createUUID();
                    directoryCreate(scratch);
                    var marker = scratch & "/executed";
                    var cmd = new cli.lucli.services.deploy.commands.AuditorCommands(variables.cfg)
                        .record("started deploy of version feat$(touch " & marker & ")");
                    // Run exactly what the deploy host's shell would, with only
                    // the log path pointed into the scratch directory.
                    var localCmd = replace(cmd, "/tmp/kamal-audit.log", scratch & "/audit.log");
                    cfexecute(name = "bash", arguments = ["-c", localCmd], timeout = 20, variable = "local.out");
                    var logged = fileRead(scratch & "/audit.log");
                    var executed = fileExists(marker);
                    directoryDelete(scratch, true);
                    expect(executed).toBeFalse();
                    expect(logged).toInclude("feat$(touch");
                    expect(logged).toInclude("demo started deploy of version");
                });

                it("still stamps the event with a shell-evaluated timestamp", () => {
                    var cmd = new cli.lucli.services.deploy.commands.AuditorCommands(variables.cfg).record("deployed v1");
                    expect(cmd).toInclude("$(date --iso-8601=seconds)");
                    expect(cmd).toInclude(">> /tmp/kamal-audit.log");
                });
            });
        });
    }
}
