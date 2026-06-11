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
        });
    }
}
