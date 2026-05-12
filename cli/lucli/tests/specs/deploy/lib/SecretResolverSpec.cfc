component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.tempRoot = getTempDirectory() & "/wheels-deploy-secret-test-" & createUUID();
        directoryCreate(variables.tempRoot & "/.kamal", true, true);
    }

    function afterAll() {
        if (directoryExists(variables.tempRoot)) {
            directoryDelete(variables.tempRoot, true);
        }
    }

    function run() {
        describe("SecretResolver", () => {

            it("resolves plain KEY=value lines", () => {
                fileWrite(variables.tempRoot & "/.kamal/secrets",
                    "FOO=bar" & chr(10) & "BAZ=qux");
                var r = new cli.lucli.services.deploy.lib.SecretResolver({
                    projectRoot: variables.tempRoot
                });
                expect(r.get("FOO")).toBe("bar");
                expect(r.get("BAZ")).toBe("qux");
            });

            it("expands $(cmd) substitutions via bash", () => {
                fileWrite(variables.tempRoot & "/.kamal/secrets",
                    "GREET=$(echo hello)");
                var r = new cli.lucli.services.deploy.lib.SecretResolver({
                    projectRoot: variables.tempRoot
                });
                expect(r.get("GREET")).toBe("hello");
            });

            it("destination overlay overrides base keys", () => {
                fileWrite(variables.tempRoot & "/.kamal/secrets", "FOO=base-value");
                fileWrite(variables.tempRoot & "/.kamal/secrets.production", "FOO=prod-value");
                var r = new cli.lucli.services.deploy.lib.SecretResolver({
                    projectRoot: variables.tempRoot,
                    destination: "production"
                });
                expect(r.get("FOO")).toBe("prod-value");
            });

            it("returns empty string for unknown keys", () => {
                fileWrite(variables.tempRoot & "/.kamal/secrets", "FOO=bar");
                var r = new cli.lucli.services.deploy.lib.SecretResolver({
                    projectRoot: variables.tempRoot
                });
                expect(r.get("UNDEFINED_KEY")).toBe("");
            });

            it("is a no-op when no .kamal/secrets file exists", () => {
                var emptyRoot = getTempDirectory() & "/wheels-deploy-empty-" & createUUID();
                directoryCreate(emptyRoot, true, true);
                var r = new cli.lucli.services.deploy.lib.SecretResolver({projectRoot: emptyRoot});
                expect(r.get("FOO")).toBe("");
                directoryDelete(emptyRoot, true);
            });

            it("has() distinguishes present-but-empty from missing", () => {
                fileWrite(variables.tempRoot & "/.kamal/secrets", "PRESENT=" & chr(10) & "FOO=bar");
                var r = new cli.lucli.services.deploy.lib.SecretResolver({
                    projectRoot: variables.tempRoot
                });
                expect(r.has("PRESENT")).toBeTrue();
                expect(r.has("MISSING")).toBeFalse();
            });
        });
    }
}
