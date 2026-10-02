/**
 * #4018, part 2: volume host paths are passed to Docker as written (since
 * #4048 quotes them), so a leading `~` or `$VAR`, which a shell used to
 * expand, is refused with a clear message; a literal `$` later in a path is
 * still fine. `deploy init` points a SQLite app at `volumes:`, and
 * `deploy config` prints the volumes.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {

        describe("volume host paths that a shell used to expand", () => {

            it("rejects an app volume whose host path starts with ~", () => {
                expect($validationError({service: "demo", image: "a/b", servers: ["1.2.3.4"], volumes: ["~/data:/var/www/db"]}))
                    .toInclude("absolute host path");
            });

            it("rejects an app volume whose host path starts with $", () => {
                expect($validationError({service: "demo", image: "a/b", servers: ["1.2.3.4"], volumes: ["$HOME/data:/var/www/db"]}))
                    .toInclude("absolute host path");
            });

            it("still accepts a $ later in the path", () => {
                expect($validationError({service: "demo", image: "a/b", servers: ["1.2.3.4"], volumes: ["/srv/a$b/db:/var/www/db"]})).toBe("");
            });

            it("rejects accessory volumes and directories that start with ~ or $", () => {
                var base = {service: "demo", image: "a/b", servers: ["1.2.3.4"]};
                var v = duplicate(base);
                v.accessories = {db: {image: "postgres:16", host: "1.2.3.5", volumes: ["~/pg:/var/lib/postgresql/data"]}};
                expect($validationError(v)).toInclude("accessory db");
                var d = duplicate(base);
                d.accessories = {cache: {image: "redis:7", host: "1.2.3.5", directories: ["${HOME}/redis:/data"]}};
                expect($validationError(d)).toInclude("accessory cache");
            });

            it("still accepts accessory paths with spaces and a later $", () => {
                var v = {service: "demo", image: "a/b", servers: ["1.2.3.4"],
                    accessories: {db: {image: "postgres:16", host: "1.2.3.5", volumes: ["/data/my pg$1:/var/lib/postgresql/data"]}}};
                expect($validationError(v)).toBe("");
            });
        });

        describe("deploy init and deploy config", () => {

            it("points a SQLite app at volumes:", () => {
                var tmpCwd = getTempDirectory() & "/wheels-deploy-vol2-" & createUUID();
                directoryCreate(tmpCwd & "/config", true, true);
                fileWrite(tmpCwd & "/config/app.cfm", "this.datasources[""app""] = {class: ""org.sqlite.JDBC""};");
                var out = new cli.lucli.services.deploy.cli.DeployMainCli(new cli.lucli.services.deploy.lib.FakeSshPool())
                    .init_stub({cwd: tmpCwd, service: "myapp", image: "acme/myapp"});
                directoryDelete(tmpCwd, true);
                expect(out).toInclude("volumes:");
                expect(out).toInclude("/var/www/db");
            });

            it("deploy config prints the app volumes", () => {
                var root = getTempDirectory() & "/wheels-deploy-vol2-" & createUUID();
                directoryCreate(root & "/config", true, true);
                fileWrite(root & "/config/deploy.yml", "service: demo#chr(10)#image: acme/demo#chr(10)#servers: [1.2.3.4]#chr(10)#volumes: ['/var/lib/demo/db:/var/www/db']#chr(10)#");
                var out = new cli.lucli.services.deploy.cli.DeployMainCli(new cli.lucli.services.deploy.lib.FakeSshPool())
                    .config({configPath: root & "/config/deploy.yml"});
                expect(out).toInclude("/var/lib/demo/db:/var/www/db");
            });
        });
    }

    /** The DeployConfigError message, or "" when the config validates. */
    private string function $validationError(required struct parsed) {
        var state = {message: ""};
        try {
            new cli.lucli.services.deploy.config.Validator().validate(arguments.parsed, "test.yml");
        } catch (DeployConfigError e) {
            state.message = e.message;
        }
        return state.message;
    }
}
