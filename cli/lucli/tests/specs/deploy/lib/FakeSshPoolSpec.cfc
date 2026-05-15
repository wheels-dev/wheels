component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {
        describe("FakeSshPool", () => {

            it("records onEach invocations", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                p.onEach(["h1", "h2"], function(ssh, host) {
                    ssh.run("uname -a");
                });
                var calls = p.calls();
                expect(arrayLen(calls)).toBe(2);
                expect(calls[1].host).toBe("h1");
                expect(calls[1].cmd).toBe("uname -a");
                expect(calls[2].host).toBe("h2");
            });

            it("returns scripted results per host", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                p.expect("h1", "uname -a", {exitCode: 0, stdout: "Linux", stderr: ""});
                p.onEach(["h1"], function(ssh, host) {
                    var r = ssh.run("uname -a");
                    expect(r.stdout).toBe("Linux");
                });
            });

            it("throws on unexpected command in strict mode", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool({strict: true});
                expect(() => p.onEach(["h1"], function(ssh, host) { ssh.run("rogue"); }))
                    .toThrow();
            });

            it("clears recorded calls via reset()", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                p.onEach(["h1"], function(ssh, host) { ssh.run("x"); });
                p.reset();
                expect(arrayLen(p.calls())).toBe(0);
            });

            it("records upload / uploadString / download calls too", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                p.onEach(["h1"], function(ssh, host) {
                    ssh.uploadString("hi", "/tmp/x");
                    ssh.upload("/local", "/remote");
                    ssh.download("/remote", "/local2");
                });
                var kinds = [];
                for (var c in p.calls()) arrayAppend(kinds, c.kind);
                expect(kinds).toInclude("uploadString");
                expect(kinds).toInclude("upload");
                expect(kinds).toInclude("download");
            });

            it("onAny only invokes callback for the first host", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                var hits = 0;
                p.onAny(["h1", "h2", "h3"], function(ssh, host) { hits++; ssh.run("x"); });
                expect(hits).toBe(1);
            });

            // Regression for #2696 — deploy verbs used to swallow nonzero remote
            // exit codes because the SSH callback discarded ssh.run()'s result.
            // The fix adds opts.raise so the caller can opt into a strict throw.
            // FakeSshPool's inline run must mirror that contract.

            it("inline run with opts.raise=true throws Wheels.Deploy.RemoteExecutionFailed on nonzero exit", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                p.expect("h1", "boom", {exitCode: 1, stdout: "", stderr: "kaboom"});
                expect(() => p.onEach(["h1"], function(ssh, host) {
                    ssh.run("boom", {raise: true});
                })).toThrow(type="Wheels.Deploy.RemoteExecutionFailed", regex="exit 1");
            });

            it("inline run with opts.raise=true names the host, exit code, and command summary", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                p.expect("host-a.example.com", "docker pull acme/demo:v1", {
                    exitCode: 125, stdout: "", stderr: "denied: requested access is denied"
                });
                try {
                    p.onEach(["host-a.example.com"], function(ssh, host) {
                        ssh.run("docker pull acme/demo:v1", {raise: true});
                    });
                    fail("expected onEach to throw");
                } catch (any e) {
                    expect(e.type).toBe("Wheels.Deploy.RemoteExecutionFailed");
                    expect(e.message).toInclude("host-a.example.com");
                    expect(e.message).toInclude("125");
                    expect(e.message).toInclude("docker pull");
                    expect(e.detail).toInclude("denied");
                }
            });

            it("inline run with opts.raise=true returns the result on exitCode 0", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                p.expect("h1", "echo ok", {exitCode: 0, stdout: "ok", stderr: ""});
                p.onEach(["h1"], function(ssh, host) {
                    var r = ssh.run("echo ok", {raise: true});
                    expect(r.exitCode).toBe(0);
                    expect(r.stdout).toBe("ok");
                });
            });

            it("inline run without opts.raise stays tolerant of nonzero exit (no throw)", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                p.expect("h1", "boom", {exitCode: 1, stdout: "", stderr: "kaboom"});
                var threw = false;
                try {
                    p.onEach(["h1"], function(ssh, host) {
                        ssh.run("boom");
                    });
                } catch (any e) {
                    threw = true;
                }
                expect(threw).toBeFalse();
            });

            it("inline run with opts.raise=false stays tolerant of nonzero exit (explicit opt-out)", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                p.expect("h1", "boom", {exitCode: 1, stdout: "", stderr: "kaboom"});
                var threw = false;
                try {
                    p.onEach(["h1"], function(ssh, host) {
                        ssh.run("boom", {raise: false});
                    });
                } catch (any e) {
                    threw = true;
                }
                expect(threw).toBeFalse();
            });

            it("inline run trims very long stderr in the thrown error detail", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                var longErr = repeatString("x", 800);
                p.expect("h1", "boom", {exitCode: 1, stdout: "", stderr: longErr});
                try {
                    p.onEach(["h1"], function(ssh, host) {
                        ssh.run("boom", {raise: true});
                    });
                    fail("expected throw");
                } catch (any e) {
                    // Trimmed to 500 chars plus an ellipsis marker.
                    expect(len(e.detail)).toBeLT(len(longErr));
                    expect(e.detail).toInclude("xxxx");
                }
            });
        });
    }
}
