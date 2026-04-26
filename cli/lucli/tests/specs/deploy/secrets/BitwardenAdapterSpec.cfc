component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {
        describe("BitwardenAdapter", () => {

            it("reports its name as 'bitwarden'", () => {
                var adapter = new modules.wheels.services.deploy.secrets.BitwardenAdapter();
                expect(adapter.name()).toBe("bitwarden");
            });

            it("builds `bw get password <key>` for each key", () => {
                var adapter = new cli.lucli.tests.specs.deploy.secrets._stubs.StubBitwardenAdapter();
                var result = adapter.fetch({keys: ["SECRET"]});
                expect(arrayLen(result)).toBe(1);
                expect(result[1]).toBe("SECRET=bw-SECRET");
                // Confirm arg shape: ["bw", "get", "password", "SECRET"]
                expect(arrayLen(adapter.lastArgs)).toBe(4);
                expect(adapter.lastArgs[1]).toBe("bw");
                expect(adapter.lastArgs[2]).toBe("get");
                expect(adapter.lastArgs[3]).toBe("password");
                expect(adapter.lastArgs[4]).toBe("SECRET");
            });

            it("handles multiple keys", () => {
                var adapter = new cli.lucli.tests.specs.deploy.secrets._stubs.StubBitwardenAdapter();
                var result = adapter.fetch({keys: ["A", "B"]});
                expect(arrayLen(result)).toBe(2);
                expect(result[1]).toBe("A=bw-A");
                expect(result[2]).toBe("B=bw-B");
            });
        });
    }
}
