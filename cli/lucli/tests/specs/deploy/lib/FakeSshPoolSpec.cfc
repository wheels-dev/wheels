component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {
        describe("FakeSshPool", () => {

            it("records onEach invocations", () => {
                var p = new modules.wheels.services.deploy.lib.FakeSshPool();
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
                var p = new modules.wheels.services.deploy.lib.FakeSshPool();
                p.expect("h1", "uname -a", {exitCode: 0, stdout: "Linux", stderr: ""});
                p.onEach(["h1"], function(ssh, host) {
                    var r = ssh.run("uname -a");
                    expect(r.stdout).toBe("Linux");
                });
            });

            it("throws on unexpected command in strict mode", () => {
                var p = new modules.wheels.services.deploy.lib.FakeSshPool({strict: true});
                expect(() => p.onEach(["h1"], function(ssh, host) { ssh.run("rogue"); }))
                    .toThrow();
            });

            it("clears recorded calls via reset()", () => {
                var p = new modules.wheels.services.deploy.lib.FakeSshPool();
                p.onEach(["h1"], function(ssh, host) { ssh.run("x"); });
                p.reset();
                expect(arrayLen(p.calls())).toBe(0);
            });

            it("records upload / uploadString / download calls too", () => {
                var p = new modules.wheels.services.deploy.lib.FakeSshPool();
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
                var p = new modules.wheels.services.deploy.lib.FakeSshPool();
                var hits = 0;
                p.onAny(["h1", "h2", "h3"], function(ssh, host) { hits++; ssh.run("x"); });
                expect(hits).toBe(1);
            });
        });
    }
}
