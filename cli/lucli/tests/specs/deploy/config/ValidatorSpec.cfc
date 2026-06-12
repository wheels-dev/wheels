component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {
        describe("Deploy config Validator", () => {

            it("accepts docker-compliant service, role, and accessory names", () => {
                var v = new cli.lucli.services.deploy.config.Validator();
                v.validate({
                    service: "demo-app_1.2",
                    image: "a/b",
                    servers: {web: ["1.2.3.4"]},
                    accessories: {db: {image: "postgres:16"}}
                }, "test.yml");
                v.validate({service: "demo", image: "a/b", servers: ["1.2.3.4"]}, "test.yml");
                expect(true).toBeTrue();
            });

            it("rejects a service name with shell metacharacters", () => {
                var v = new cli.lucli.services.deploy.config.Validator();
                var state = {threw: false, message: ""};
                try {
                    v.validate({service: "demo; rm -rf /", image: "a/b", servers: ["1.2.3.4"]}, "test.yml");
                } catch (DeployConfigError e) {
                    state.threw = true;
                    state.message = e.message;
                }
                expect(state.threw).toBeTrue();
                expect(state.message).toInclude("service");
            });

            it("rejects a role name that is not docker-compliant", () => {
                var v = new cli.lucli.services.deploy.config.Validator();
                var state = {threw: false, message: ""};
                try {
                    v.validate({service: "demo", image: "a/b", servers: {"web app": ["1.2.3.4"]}}, "test.yml");
                } catch (DeployConfigError e) {
                    state.threw = true;
                    state.message = e.message;
                }
                expect(state.threw).toBeTrue();
                expect(state.message).toInclude("role");
            });

            it("rejects an accessory name that is not docker-compliant", () => {
                var v = new cli.lucli.services.deploy.config.Validator();
                var state = {threw: false, message: ""};
                try {
                    v.validate({
                        service: "demo",
                        image: "a/b",
                        servers: ["1.2.3.4"],
                        accessories: {"db$x": {image: "redis:7"}}
                    }, "test.yml");
                } catch (DeployConfigError e) {
                    state.threw = true;
                    state.message = e.message;
                }
                expect(state.threw).toBeTrue();
                expect(state.message).toInclude("accessory");
            });

            it("rejects a name with a leading separator character", () => {
                var v = new cli.lucli.services.deploy.config.Validator();
                var state = {threw: false};
                try {
                    v.validate({service: "-demo", image: "a/b", servers: ["1.2.3.4"]}, "test.yml");
                } catch (DeployConfigError e) {
                    state.threw = true;
                }
                expect(state.threw).toBeTrue();
            });

            // ##3086 — adjacent colons must not be under-counted. listToArray with
            // includeEmptyFields=false collapsed '::1:22' to ['1','22'] and let it pass.
            it("rejects unbracketed multi-colon hosts, including adjacent colons", () => {
                var v = new cli.lucli.services.deploy.config.Validator();
                var rejects = ["::1:22", ":a:b", "a::b", "h:1:2"];
                for (var host in rejects) {
                    var state = {threw: false, message: ""};
                    try {
                        v.validate({service: "demo", image: "a/b", servers: [host]}, "test.yml");
                    } catch (DeployConfigError e) {
                        state.threw = true;
                        state.message = e.message;
                    }
                    expect(state.threw).toBeTrue("expected '#host#' to be rejected");
                    expect(state.message).toInclude("invalid host");
                }
            });

            it("still accepts bracketed IPv6 hosts and single-colon host:port", () => {
                var v = new cli.lucli.services.deploy.config.Validator();
                v.validate({service: "demo", image: "a/b", servers: ["[::1]:22"]}, "test.yml");
                v.validate({service: "demo", image: "a/b", servers: ["deploy@1.2.3.4:2222"]}, "test.yml");
                v.validate({service: "demo", image: "a/b", servers: ["host.example.com"]}, "test.yml");
                expect(true).toBeTrue();
            });

            // ##3088 — keys the runtime never reads must fail validation loudly
            // instead of being accepted-and-ignored.
            it("rejects allowlisted-but-unimplemented top-level keys", () => {
                var v = new cli.lucli.services.deploy.config.Validator();
                var deadKeys = [
                    "boot", "healthcheck", "hooks", "volumes", "labels", "logging",
                    "retain_containers", "minimum_version", "asset_path",
                    "require_destination", "allow_empty_roles", "run_directory",
                    "readiness_delay"
                ];
                for (var deadKey in deadKeys) {
                    var parsed = {service: "demo", image: "a/b", servers: ["1.2.3.4"]};
                    parsed[deadKey] = "x";
                    var state = {threw: false, message: ""};
                    try {
                        v.validate(parsed, "test.yml");
                    } catch (DeployConfigError e) {
                        state.threw = true;
                        state.message = e.message;
                    }
                    expect(state.threw).toBeTrue("expected top-level key '#deadKey#' to be rejected");
                    expect(state.message).toInclude("unknown top-level key");
                    expect(state.message).toInclude(deadKey);
                }
            });

            it("accepts a config that uses every implemented top-level key", () => {
                var v = new cli.lucli.services.deploy.config.Validator();
                v.validate({
                    service: "demo",
                    image: "a/b",
                    servers: {web: ["1.2.3.4"]},
                    registry: {username: "u", password: ["KAMAL_REGISTRY_PASSWORD"]},
                    builder: {context: ".", dockerfile: "Dockerfile"},
                    env: {clear: {A: "1"}},
                    ssh: {user: "deploy"},
                    proxy: {host: "app.example.com"},
                    accessories: {db: {image: "postgres:16"}}
                }, "test.yml");
                expect(true).toBeTrue();
            });

            it("lists the allowed keys in the unknown-key error", () => {
                var v = new cli.lucli.services.deploy.config.Validator();
                var state = {threw: false, message: ""};
                try {
                    v.validate({service: "demo", image: "a/b", servers: ["1.2.3.4"], boot: {limit: 1}}, "test.yml");
                } catch (DeployConfigError e) {
                    state.threw = true;
                    state.message = e.message;
                }
                expect(state.threw).toBeTrue();
                expect(state.message).toInclude("allowed keys:");
                expect(state.message).toInclude("accessories");
            });
        });
    }
}
