/**
 * Mirror-parity coverage for SshClient.$raiseRemoteFailure secret redaction
 * (#3159). SshClientSpec proper needs a live sshd (the DeployShellHelper
 * fixture), which isn't available in every CI lane; these cases exercise the
 * pure throw helper directly on a deferred-open (unconnected) client, so they
 * run everywhere and pin the SOURCE-OF-TRUTH side of the FakeSshPool mirror.
 *
 * `new SshClient()` with no host is a documented no-op that returns `this`
 * without opening a connection, so $setSecretValues + $raiseRemoteFailure can
 * be invoked without any network or sshd.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {
        describe("SshClient.$raiseRemoteFailure secret redaction (issue 3159)", () => {

            it("redacts a registered secret value from the command summary", () => {
                var ssh = new cli.lucli.services.deploy.lib.SshClient();
                var secret = "s3cr3t-DB-pa55word";
                var cmd = "docker run -d -e 'DATABASE_PASSWORD=" & secret & "' acme/demo:v1";
                ssh.$setSecretValues([secret]);
                expect(() => ssh.$raiseRemoteFailure("h1", cmd, {exitCode: 125, stderr: "boom"}))
                    .toThrow(type="Wheels.Deploy.RemoteExecutionFailed");
                try {
                    ssh.$raiseRemoteFailure("h1", cmd, {exitCode: 125, stderr: "boom"});
                } catch (any e) {
                    expect(e.message).notToInclude(secret);
                    expect(e.message).toInclude("[REDACTED]");
                    expect(e.message).toInclude("DATABASE_PASSWORD=");
                }
            });

            it("matches the FakeSshPool mirror byte-for-byte for a redacted message", () => {
                var ssh = new cli.lucli.services.deploy.lib.SshClient();
                var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
                var secret = "mirror-parity-SECRET-42";
                var cmd = "docker run -e 'TOKEN=" & secret & "' img";
                ssh.$setSecretValues([secret]);
                fake.$setSecretValues([secret]);
                var fromClient = "";
                var fromFake = "";
                try { ssh.$raiseRemoteFailure("h", cmd, {exitCode: 9, stderr: "x"}); }
                catch (any e) { fromClient = e.message; }
                try { fake.$raiseRemoteFailure("h", cmd, {exitCode: 9, stderr: "x"}); }
                catch (any e) { fromFake = e.message; }
                expect(fromClient).toBe(fromFake);
                expect(fromClient).notToInclude(secret);
            });

            it("leaves a no-secret command unchanged and skips empty/short values", () => {
                var ssh = new cli.lucli.services.deploy.lib.SshClient();
                ssh.$setSecretValues(["", "x"]);
                var cmd = "docker pull acme/demo:v1";
                try {
                    ssh.$raiseRemoteFailure("h1", cmd, {exitCode: 125, stderr: "denied"});
                    fail("expected throw");
                } catch (any e) {
                    expect(e.message).toInclude("docker pull acme/demo:v1");
                    expect(e.message).notToInclude("[REDACTED]");
                }
            });

            it("redacts before the 200-char trim so a boundary secret can't partially leak", () => {
                var ssh = new cli.lucli.services.deploy.lib.SshClient();
                var secret = "boundary-secret-VALUE-9876";
                var cmd = repeatString("a", 190) & secret & " tail";
                ssh.$setSecretValues([secret]);
                try {
                    ssh.$raiseRemoteFailure("h1", cmd, {exitCode: 1, stderr: "boom"});
                    fail("expected throw");
                } catch (any e) {
                    expect(e.message).notToInclude(left(secret, 10));
                    expect(e.message).toInclude("[REDACTED]");
                }
            });
        });
    }
}
