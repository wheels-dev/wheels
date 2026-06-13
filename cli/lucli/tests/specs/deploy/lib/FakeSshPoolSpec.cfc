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

            // Transport-failure modeling — mirrors the REAL pool's semantics so
            // specs can exercise unreachable-host paths (##2957 review follow-up):
            //   - onEach pre-resolves every connection first, so one dead host
            //     aborts the whole fan-out with zero commands executed;
            //   - sequential resolves lazily, so earlier hosts already ran;
            //   - onAny catches per host and falls through to the next;
            //   - a scripted `transportError` result throws from run() itself,
            //     regardless of {raise: false} (dead cached connection).

            it("failConnection makes onEach abort wholesale before any command runs (mirrors real pre-resolve)", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                p.failConnection("h2");
                expect(() => p.onEach(["h1", "h2"], function(ssh, host) { ssh.run("x"); }))
                    .toThrow(type="FakeSshPool.ConnectionFailure");
                expect(arrayLen(p.calls())).toBe(0);
            });

            it("failConnection makes sequential fail at that host after earlier hosts ran", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                p.failConnection("h2", "No route to host");
                var state = {threw = false, errMsg = ""};
                try {
                    p.sequential(["h1", "h2", "h3"], function(ssh, host) { ssh.run("x"); });
                } catch (any e) {
                    state.threw = true;
                    state.errMsg = e.message;
                }
                expect(state.threw).toBeTrue();
                expect(state.errMsg).toInclude("No route to host");
                expect(arrayLen(p.calls())).toBe(1);
                expect(p.calls()[1].host).toBe("h1");
            });

            it("failConnection makes onAny skip to the next host", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                p.failConnection("h1");
                p.onAny(["h1", "h2"], function(ssh, host) { ssh.run("x"); });
                expect(arrayLen(p.calls())).toBe(1);
                expect(p.calls()[1].host).toBe("h2");
            });

            it("onAny rethrows the last error when every host is unreachable", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                p.failConnection("h1");
                p.failConnection("h2", "last one");
                var state = {threw = false, errMsg = ""};
                try {
                    p.onAny(["h1", "h2"], function(ssh, host) { ssh.run("x"); });
                } catch (any e) {
                    state.threw = true;
                    state.errMsg = e.message;
                }
                expect(state.threw).toBeTrue();
                expect(state.errMsg).toInclude("last one");
            });

            it("a scripted transportError throws from run regardless of raise=false", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                p.expect("h1", "rm -f /lock", {transportError: "Broken pipe"});
                expect(() => p.onEach(["h1"], function(ssh, host) {
                    ssh.run("rm -f /lock", {raise: false});
                })).toThrow(type="FakeSshPool.TransportFailure", regex="Broken pipe");
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
