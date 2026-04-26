component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {
        describe("OnePasswordAdapter", () => {

            it("reports its name as 'op'", () => {
                var adapter = new modules.wheels.services.deploy.secrets.OnePasswordAdapter();
                expect(adapter.name()).toBe("op");
            });

            it("fetches a single key with default 'Deploy' vault", () => {
                var adapter = new cli.lucli.tests.specs.deploy.secrets._stubs.StubOnePasswordAdapter();
                var result = adapter.fetch({keys: ["MYKEY"]});
                expect(arrayLen(result)).toBe(1);
                // The stub echoes back the op:// path so we can confirm args built correctly.
                expect(result[1]).toBe("MYKEY=op://Deploy/MYKEY/password");
            });

            it("uses a custom 'from' vault when provided", () => {
                var adapter = new cli.lucli.tests.specs.deploy.secrets._stubs.StubOnePasswordAdapter();
                var result = adapter.fetch({from: "Production", keys: ["DB_PASS"]});
                expect(result[1]).toBe("DB_PASS=op://Production/DB_PASS/password");
            });

            it("injects --account flag when account is provided", () => {
                var adapter = new cli.lucli.tests.specs.deploy.secrets._stubs.StubOnePasswordAdapter();
                adapter.captureArgs = true;
                adapter.fetch({account: "my.1password.com", from: "Deploy", keys: ["KEY"]});
                // Stub records last args — expect --account to be present.
                expect(arrayContains(adapter.lastArgs, "--account")).toBeGT(0);
                expect(arrayContains(adapter.lastArgs, "my.1password.com")).toBeGT(0);
            });

            it("fetches multiple keys in order", () => {
                var adapter = new cli.lucli.tests.specs.deploy.secrets._stubs.StubOnePasswordAdapter();
                var result = adapter.fetch({keys: ["A", "B", "C"]});
                expect(arrayLen(result)).toBe(3);
                expect(result[1]).toInclude("A=");
                expect(result[3]).toInclude("C=");
            });
        });
    }
}
