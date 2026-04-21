component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {
        describe("Module.deploy() dispatch", () => {

            it("deploy version returns the pinned Kamal version string", () => {
                var mod = $newModule();
                var out = mod.deploy("version");
                expect(out).toInclude("kamal 2.4.0");
            });

            it("deploy config --configPath returns YAML output", () => {
                var mod = $newModule();
                var out = mod.deploy(
                    "config",
                    "--configPath=" & expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml")
                );
                expect(out).toInclude("service: demo");
            });

            it("deploy --dry-run returns the host-prefixed plan lines", () => {
                var mod = $newModule();
                var out = mod.deploy(
                    "--dry-run",
                    "--configPath=" & expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml"),
                    "--version=v1"
                );
                expect(out).toInclude("[1.2.3.4]");
                expect(out).toInclude("docker pull acme/demo:v1");
            });

            it("deploy rollback <version> dry-run includes start + proxy deploy", () => {
                var mod = $newModule();
                var out = mod.deploy(
                    "rollback",
                    "v-old",
                    "--dry-run",
                    "--configPath=" & expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml")
                );
                expect(out).toInclude("docker start demo-web-v-old");
                expect(out).toInclude("kamal-proxy deploy demo");
            });

            it("deploy rollback without version throws", () => {
                var mod = $newModule();
                expect(() => mod.deploy(
                    "rollback",
                    "--dry-run",
                    "--configPath=" & expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml")
                )).toThrow();
            });
        });
    }

    private any function $newModule() {
        return new cli.lucli.Module();
    }
}
