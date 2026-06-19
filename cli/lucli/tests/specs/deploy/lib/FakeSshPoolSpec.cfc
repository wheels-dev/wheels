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

            // Secret redaction in the command summary — #3159 (deferred from
            // #3008). env.clear values interpolated from ${SECRET} tokens ride
            // as `docker run ... -e KEY=value`, so the raw value would leak into
            // the RemoteExecutionFailed message and CI logs. $setSecretValues
            // registers the resolved-secret set; $raiseRemoteFailure replaces
            // every occurrence with [REDACTED] BEFORE the 200-char trim.

            it("redacts a secret-interpolated env value from the command summary", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                var secret = "s3cr3t-DB-pa55word";
                var cmd = "docker run -d -e 'DATABASE_PASSWORD=" & secret & "' acme/demo:v1";
                p.$setSecretValues([secret]);
                p.expect("h1", cmd, {exitCode: 125, stdout: "", stderr: "boom"});
                try {
                    p.onEach(["h1"], function(ssh, host) { ssh.run(cmd, {raise: true}); });
                    fail("expected throw");
                } catch (any e) {
                    expect(e.message).notToInclude(secret);
                    expect(e.message).toInclude("[REDACTED]");
                    expect(e.message).toInclude("DATABASE_PASSWORD=");
                }
            });

            it("redacts every occurrence of a repeated secret across multiple -e flags", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                var secret = "repeated-secret-value-123";
                var cmd = "docker run -e 'A=" & secret & "' -e 'B=" & secret & "' img";
                p.$setSecretValues([secret]);
                p.expect("h1", cmd, {exitCode: 1, stdout: "", stderr: "fail"});
                try {
                    p.onEach(["h1"], function(ssh, host) { ssh.run(cmd, {raise: true}); });
                    fail("expected throw");
                } catch (any e) {
                    expect(e.message).notToInclude(secret);
                    expect(reMatchNoCase("\[REDACTED\]", e.message).len()).toBe(2);
                }
            });

            it("leaves a command with no secrets unchanged", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                p.$setSecretValues(["a-secret-never-present"]);
                p.expect("h1", "docker pull acme/demo:v1", {exitCode: 125, stdout: "", stderr: "denied"});
                try {
                    p.onEach(["h1"], function(ssh, host) { ssh.run("docker pull acme/demo:v1", {raise: true}); });
                    fail("expected throw");
                } catch (any e) {
                    expect(e.message).toInclude("docker pull acme/demo:v1");
                    expect(e.message).notToInclude("[REDACTED]");
                }
            });

            it("does not redact empty or trivially short secret values into unrelated text", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                // Empty string + a 1-char value must never mangle the summary.
                p.$setSecretValues(["", "x"]);
                var cmd = "docker run -e 'EXAMPLE=value' acme/demo:v1";
                p.expect("h1", cmd, {exitCode: 1, stdout: "", stderr: "boom"});
                try {
                    p.onEach(["h1"], function(ssh, host) { ssh.run(cmd, {raise: true}); });
                    fail("expected throw");
                } catch (any e) {
                    expect(e.message).toInclude("docker run -e 'EXAMPLE=value' acme/demo:v1");
                    expect(e.message).notToInclude("[REDACTED]");
                }
            });

            it("redacts a secret sitting on the 200-char trim boundary before truncating", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                var secret = "boundary-secret-VALUE-9876";
                // Pad so the secret straddles the 200-char boundary: a partial
                // leak would slip through if the trim ran before redaction.
                var pad = repeatString("a", 190);
                var cmd = pad & secret & " tail";
                p.$setSecretValues([secret]);
                p.expect("h1", cmd, {exitCode: 1, stdout: "", stderr: "boom"});
                try {
                    p.onEach(["h1"], function(ssh, host) { ssh.run(cmd, {raise: true}); });
                    fail("expected throw");
                } catch (any e) {
                    // No prefix of the secret long enough to be identifiable leaks.
                    expect(e.message).notToInclude(left(secret, 10));
                    expect(e.message).toInclude("[REDACTED]");
                }
            });
        });
    }
}
