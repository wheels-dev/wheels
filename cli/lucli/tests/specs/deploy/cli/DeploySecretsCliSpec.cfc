component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {
        describe("DeploySecretsCli", () => {

            it("throws when adapter name is unknown", () => {
                var cli = new modules.wheels.services.deploy.cli.DeploySecretsCli();
                try {
                    cli.fetch({adapter: "nope", keys: ["K"]});
                    expect(false).toBeTrue();  // should not reach
                } catch (any e) {
                    expect(e.type).toBe("DeploySecretsCli.UnknownAdapter");
                }
            });

            it("throws when no keys are given", () => {
                var cli = new modules.wheels.services.deploy.cli.DeploySecretsCli();
                cli.setAdapter("op", new cli.lucli.tests.specs.deploy.secrets._stubs.StubOnePasswordAdapter());
                try {
                    cli.fetch({adapter: "op", keys: []});
                    expect(false).toBeTrue();
                } catch (any e) {
                    expect(e.type).toBe("DeploySecretsCli.NoKeys");
                }
            });

            it("fetch returns KEY=VALUE lines via the adapter", () => {
                var cli = new modules.wheels.services.deploy.cli.DeploySecretsCli();
                cli.setAdapter("bw", new cli.lucli.tests.specs.deploy.secrets._stubs.StubBitwardenAdapter());
                var out = cli.fetch({adapter: "bw", keys: ["A", "B"]});
                expect(out).toInclude("A=bw-A");
                expect(out).toInclude("B=bw-B");
            });

            it("fetch joins multi-line output with \n", () => {
                var cli = new modules.wheels.services.deploy.cli.DeploySecretsCli();
                cli.setAdapter("bw", new cli.lucli.tests.specs.deploy.secrets._stubs.StubBitwardenAdapter());
                var out = cli.fetch({adapter: "bw", keys: ["X", "Y"]});
                expect(find(chr(10), out)).toBeGT(0);
            });

            it("extract pulls a single key's value from a KEY=VALUE block", () => {
                var cli = new modules.wheels.services.deploy.cli.DeploySecretsCli();
                var block = "FOO=bar" & chr(10) & "BAZ=qux";
                expect(cli.extract({key: "BAZ", from: block})).toBe("qux");
                expect(cli.extract({key: "FOO", from: block})).toBe("bar");
            });

            it("extract returns empty string for a missing key", () => {
                var cli = new modules.wheels.services.deploy.cli.DeploySecretsCli();
                expect(cli.extract({key: "NOPE", from: "FOO=bar"})).toBe("");
            });

            it("extract returns empty string when key is empty", () => {
                var cli = new modules.wheels.services.deploy.cli.DeploySecretsCli();
                expect(cli.extract({key: "", from: "FOO=bar"})).toBe("");
            });

            it("resolves 1password and op as the same adapter", () => {
                var cli = new modules.wheels.services.deploy.cli.DeploySecretsCli();
                var stub = new cli.lucli.tests.specs.deploy.secrets._stubs.StubOnePasswordAdapter();
                cli.setAdapter("op", stub);
                cli.setAdapter("1password", stub);
                var out1 = cli.fetch({adapter: "op", keys: ["K"]});
                var out2 = cli.fetch({adapter: "1password", keys: ["K"]});
                expect(out1).toBe(out2);
            });

            it("print emits empty string when .kamal/secrets is missing", () => {
                var tmp = getTempDirectory() & "secrets-test-" & createUUID() & "/";
                directoryCreate(tmp);
                try {
                    var cli = new modules.wheels.services.deploy.cli.DeploySecretsCli();
                    var out = cli.print({projectRoot: tmp});
                    expect(out).toBe("");
                } finally {
                    directoryDelete(tmp, true);
                }
            });

            it("fetch forwards account/from through to the adapter", () => {
                var cli = new modules.wheels.services.deploy.cli.DeploySecretsCli();
                var stub = new cli.lucli.tests.specs.deploy.secrets._stubs.StubOnePasswordAdapter();
                cli.setAdapter("op", stub);
                cli.fetch({adapter: "op", account: "me@example.com", from: "Prod", keys: ["K"]});
                // Stub captures args — check the op:// URI includes "Prod".
                var found = false;
                for (var a in stub.lastArgs) {
                    if (left(a, 5) == "op://" && findNoCase("Prod", a)) found = true;
                }
                expect(found).toBeTrue();
            });
        });
    }
}
