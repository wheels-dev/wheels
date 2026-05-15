component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {
        describe("Ssh — `ssh:` block accessors", () => {

            it("defaults to root@22 with no keys when the block is empty", () => {
                var s = new cli.lucli.services.deploy.config.Ssh({});
                expect(s.user()).toBe("root");
                expect(s.port()).toBe(22);
                expect(s.proxy()).toBe("");
                expect(s.keys()).toBeArray();
                expect(arrayLen(s.keys())).toBe(0);
                expect(s.keysOnly()).toBeFalse();
            });

            it("propagates user, port, proxy, keys, keys_only from the raw block", () => {
                var s = new cli.lucli.services.deploy.config.Ssh({
                    user: "admin",
                    port: 2222,
                    proxy: "bastion.example.com",
                    keys: ["~/.ssh/deploy_key"],
                    keys_only: true
                });
                expect(s.user()).toBe("admin");
                expect(s.port()).toBe(2222);
                expect(s.proxy()).toBe("bastion.example.com");
                expect(s.keys()).toBe(["~/.ssh/deploy_key"]);
                expect(s.keysOnly()).toBeTrue();
            });

            it("keys() returns an empty array when the raw key isn't an array", () => {
                // Defensive — Validator should reject this shape, but the
                // accessor still needs to not blow up if someone bypasses it.
                var s = new cli.lucli.services.deploy.config.Ssh({keys: "not-an-array"});
                expect(s.keys()).toBeArray();
                expect(arrayLen(s.keys())).toBe(0);
            });

        });

        describe("Ssh.$expandHome — sshj-compatible tilde expansion", () => {

            // CFML closures can't access plain `var` declarations from the
            // outer describe scope on Adobe CF — bundle the shared
            // references into a struct so every `it` sees them through a
            // proper variable lookup.
            var ctx = {
                home: createObject("java", "java.lang.System").getProperty("user.home"),
                s: new cli.lucli.services.deploy.config.Ssh({})
            };

            it("expands `~/foo/bar` to `<home>/foo/bar`", () => {
                expect(ctx.s.$expandHome("~/.ssh/deploy_key")).toBe(ctx.home & "/.ssh/deploy_key");
            });

            it("expands bare `~` to <home>", () => {
                expect(ctx.s.$expandHome("~")).toBe(ctx.home);
            });

            it("returns absolute paths unchanged", () => {
                expect(ctx.s.$expandHome("/tmp/deploy_key")).toBe("/tmp/deploy_key");
            });

            it("returns relative paths unchanged (no implicit `./` expansion)", () => {
                expect(ctx.s.$expandHome("keys/deploy_key")).toBe("keys/deploy_key");
            });

            it("only treats a leading `~/` as the home shortcut", () => {
                // Embedded `~` mid-string is preserved (no `~user` lookup
                // either — that's a shell feature we don't replicate).
                expect(ctx.s.$expandHome("/tmp/~/x")).toBe("/tmp/~/x");
            });

        });
    }
}
