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

            it("resolves keys that also exist in the parent environment", () => {
                // HOME is always set in the parent env; the old baseline
                // subtraction dropped such keys, yielding "" for them.
                fileWrite(variables.tempRoot & "/.kamal/secrets", "HOME=/tmp/wheels-secret-override");
                var r = new cli.lucli.services.deploy.lib.SecretResolver({
                    projectRoot: variables.tempRoot
                });
                expect(r.get("HOME")).toBe("/tmp/wheels-secret-override");
            });

            it("preserves multi-line quoted values like certificates", () => {
                var cert = "-----BEGIN CERTIFICATE-----" & chr(10)
                    & "dGVzdA==" & chr(10)
                    & "-----END CERTIFICATE-----";
                fileWrite(variables.tempRoot & "/.kamal/secrets", 'CERT="' & cert & '"');
                var r = new cli.lucli.services.deploy.lib.SecretResolver({
                    projectRoot: variables.tempRoot
                });
                expect(r.get("CERT")).toBe(cert);
                // base64 continuation lines must not be misparsed as keys
                expect(r.has("dGVzdA")).toBeFalse();
            });

            it("preserves values whose continuation lines begin with '='", () => {
                // A continuation line starting with '=' previously reached
                // left(line, 0), which crashes Lucee 7 (Cross-Engine Invariant 8).
                fileWrite(variables.tempRoot & "/.kamal/secrets",
                    'WEIRD="line1' & chr(10) & '=line2"');
                var r = new cli.lucli.services.deploy.lib.SecretResolver({
                    projectRoot: variables.tempRoot
                });
                expect(r.get("WEIRD")).toBe("line1" & chr(10) & "=line2");
            });

            it("supports export-prefixed declarations", () => {
                fileWrite(variables.tempRoot & "/.kamal/secrets", "export TOKEN=abc123");
                var r = new cli.lucli.services.deploy.lib.SecretResolver({
                    projectRoot: variables.tempRoot
                });
                expect(r.get("TOKEN")).toBe("abc123");
            });

            it("throws ResolutionFailed when a $(cmd) substitution fails", () => {
                // A failing credential-manager command (op not signed in,
                // bw locked, …) must abort resolution, not silently export
                // an empty value for the key.
                fileWrite(variables.tempRoot & "/.kamal/secrets", "BROKEN=$(exit 1)");
                expect(() => {
                    new cli.lucli.services.deploy.lib.SecretResolver({
                        projectRoot: variables.tempRoot
                    });
                }).toThrow(type="SecretResolver.ResolutionFailed");
            });

            it("throws ResolutionFailed when the failing command is mid-file", () => {
                // Without errexit, bash only reports the LAST statement's
                // status, so a mid-file failure followed by a good line
                // would slip through.
                fileWrite(variables.tempRoot & "/.kamal/secrets",
                    "BROKEN=$(exit 1)" & chr(10) & "GOOD=ok");
                expect(() => {
                    new cli.lucli.services.deploy.lib.SecretResolver({
                        projectRoot: variables.tempRoot
                    });
                }).toThrow(type="SecretResolver.ResolutionFailed");
            });

            // #2957 — $runBash had an unbounded proc.waitFor()/stdout read, so a
            // secrets command blocking on interactive input (op/bw prompting for
            // sign-in) hung the deploy thread forever. Resolution is now bounded
            // by opts.timeoutSeconds (default 60); on expiry the bash process is
            // killed and a clear ResolutionFailed surfaces.
            it("throws ResolutionFailed when a secrets command hangs past the timeout (##2957)", () => {
                fileWrite(variables.tempRoot & "/.kamal/secrets", "SLOW=$(sleep 30)");
                var startedAt = getTickCount();
                expect(() => {
                    new cli.lucli.services.deploy.lib.SecretResolver({
                        projectRoot: variables.tempRoot,
                        timeoutSeconds: 1
                    });
                }).toThrow(type="SecretResolver.ResolutionFailed", regex="timed out");
                // The hang must be cut at the deadline, not ridden out to the
                // command's own 30s completion.
                expect(getTickCount() - startedAt).toBeLT(10000);
            });

            it("throws BashUnavailable when bash cannot be launched", () => {
                fileWrite(variables.tempRoot & "/.kamal/secrets", "FOO=bar");
                expect(() => {
                    new cli.lucli.services.deploy.lib.SecretResolver({
                        projectRoot: variables.tempRoot,
                        bashCmd: "/nonexistent/wheels-no-bash-" & createUUID()
                    });
                }).toThrow(type="SecretResolver.BashUnavailable");
            });
        });
    }
}
