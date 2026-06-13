component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {
        describe("Role", () => {

            // Proxy gating (#2957) — only proxy-fronted roles should receive
            // kamal-proxy boot/deploy commands. Mirrors Kamal's
            // Role#running_proxy?: an explicit role-level `proxy:` boolean
            // wins; otherwise only the default "web" role fronts the proxy.

            it("runningProxy() defaults to true for the web role (##2957)", () => {
                var role = new cli.lucli.services.deploy.config.Role({name: "web", hosts: ["1.2.3.4"]});
                expect(role.runningProxy()).toBeTrue();
            });

            it("runningProxy() defaults to false for non-web roles (##2957)", () => {
                var role = new cli.lucli.services.deploy.config.Role({name: "workers", hosts: ["1.2.3.4"]});
                expect(role.runningProxy()).toBeFalse();
            });

            it("runningProxy() honors an explicit proxy: true on a non-web role (##2957)", () => {
                var role = new cli.lucli.services.deploy.config.Role({name: "api", hosts: [], proxy: true});
                expect(role.runningProxy()).toBeTrue();
            });

            it("runningProxy() honors an explicit proxy: false on the web role (##2957)", () => {
                var role = new cli.lucli.services.deploy.config.Role({name: "web", hosts: [], proxy: false});
                expect(role.runningProxy()).toBeFalse();
            });

            it("Config.roles() forwards the role-level proxy key for struct-shaped servers (##2957)", () => {
                var cfg = new cli.lucli.services.deploy.config.Config({
                    service: "demo",
                    image: "acme/demo",
                    servers: {
                        api: {hosts: ["10.0.0.1"], proxy: true},
                        workers: {hosts: ["10.0.0.2"]}
                    }
                });
                var byName = {};
                for (var role in cfg.roles()) byName[role.name()] = role;
                expect(byName.api.runningProxy()).toBeTrue();
                expect(byName.workers.runningProxy()).toBeFalse();
            });
        });
    }
}
