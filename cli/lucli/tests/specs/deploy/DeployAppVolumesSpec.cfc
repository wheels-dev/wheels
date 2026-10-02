/**
 * #4018: a top-level `volumes:` list (Kamal-compatible) is mounted on every
 * app container, so a SQLite app's database can live on the host and survive
 * a redeploy. Entries are format-validated and shell-escaped.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {

        describe("deploy volumes: validation", () => {

            it("accepts host-path and named-volume mounts, with an optional :ro/:rw", () => {
                expect($validationError({service: "demo", image: "a/b", servers: ["1.2.3.4"], volumes: [
                    "/var/lib/demo/db:/var/www/db",
                    "demo_uploads:/var/www/public/uploads",
                    "/etc/demo/config.json:/var/www/config/extra.json:ro"
                ]})).toBe("");
            });

            it("rejects a volumes value that isn't a list", () => {
                expect($validationError({service: "demo", image: "a/b", servers: ["1.2.3.4"], volumes: "/a:/b"})).toInclude("volumes must be a list");
            });

            it("rejects an entry that isn't host:container", () => {
                expect($validationError({service: "demo", image: "a/b", servers: ["1.2.3.4"], volumes: ["/only-one-path"]})).toInclude("volumes[1]");
            });

            it("rejects an entry whose container path isn't absolute", () => {
                expect($validationError({service: "demo", image: "a/b", servers: ["1.2.3.4"], volumes: ["/var/lib/demo:db"]})).toInclude("volumes[1]");
            });

            it("rejects an unknown mount mode", () => {
                expect($validationError({service: "demo", image: "a/b", servers: ["1.2.3.4"], volumes: ["/a:/b:rwx"]})).toInclude("volumes[1]");
            });
        });

        describe("accessory volumes and directories are quoted", () => {

            it("quotes a path with a space and a shell metacharacter", () => {
                var cfg = $config("accessories: {db: {image: 'postgres:16', host: 1.2.3.5, volumes: ['/data/my pg$1;x:/var/lib/postgresql/data']}, cache: {image: 'redis:7', host: 1.2.3.5, directories: ['/data/redis dir:/data']}}");
                var accCmds = new cli.lucli.services.deploy.commands.AccessoryCommands(cfg);
                var db = cfg.accessory("db");
                var cache = cfg.accessory("cache");
                expect(accCmds.run(db)).toInclude("--volume '/data/my pg$1;x:/var/lib/postgresql/data'");
                expect(accCmds.run(cache)).toInclude("--volume '/data/redis dir:/data'");
            });
        });

        describe("deploy volumes: app containers", () => {

            it("mounts every volume on the app container", () => {
                var cfg = $config("volumes: ['/var/lib/demo/db:/var/www/db', 'demo_uploads:/var/www/public/uploads:ro']");
                var cmd = new cli.lucli.services.deploy.commands.AppCommands(cfg).run(cfg.roles()[1], "v1");
                expect(cmd).toInclude("--volume '/var/lib/demo/db:/var/www/db'");
                expect(cmd).toInclude("--volume 'demo_uploads:/var/www/public/uploads:ro'");
            });

            it("quotes a path with a space and a shell metacharacter", () => {
                var cfg = $config("volumes: ['/srv/demo data/db$x;1:/var/www/db']");
                var cmd = new cli.lucli.services.deploy.commands.AppCommands(cfg).run(cfg.roles()[1], "v1");
                expect(cmd).toInclude("--volume '/srv/demo data/db$x;1:/var/www/db'");
            });

            it("adds no --volume without a volumes list", () => {
                var cfg = $config("");
                var cmd = new cli.lucli.services.deploy.commands.AppCommands(cfg).run(cfg.roles()[1], "v1");
                expect(cmd).notToInclude("--volume");
            });

            it("a deploy dry run boots the app with the volume", () => {
                var path = $writeConfig("volumes: ['/var/lib/demo/db:/var/www/db']");
                var out = new cli.lucli.services.deploy.cli.DeployMainCli(new cli.lucli.services.deploy.lib.FakeSshPool())
                    .deploy({configPath: path, version: "v1", dryRun: true, skipPush: true});
                expect(out).toInclude("--volume '/var/lib/demo/db:/var/www/db'");
            });
        });
    }

    private string function $writeConfig(required string extraYaml) {
        var root = getTempDirectory() & "/wheels-deploy-volumes-" & createUUID();
        directoryCreate(root & "/config", true, true);
        fileWrite(
            root & "/config/deploy.yml",
            "service: demo#chr(10)#image: acme/demo#chr(10)#servers: [1.2.3.4]#chr(10)#"
                & "registry: {username: u, password: [REGISTRY_PASSWORD]}#chr(10)#"
                & arguments.extraYaml & chr(10)
        );
        return root & "/config/deploy.yml";
    }

    private any function $config(required string extraYaml) {
        return new cli.lucli.services.deploy.config.ConfigLoader().load($writeConfig(arguments.extraYaml));
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
