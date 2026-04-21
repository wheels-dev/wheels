component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {
        describe("LastPassAdapter", () => {

            it("reports its name as 'lastpass'", () => {
                var adapter = new cli.lucli.services.deploy.secrets.LastPassAdapter();
                expect(adapter.name()).toBe("lastpass");
            });

            it("builds `lpass show -p <key>`", () => {
                var adapter = new cli.lucli.tests.specs.deploy.secrets._stubs.StubLastPassAdapter();
                var result = adapter.fetch({keys: ["MYKEY"]});
                expect(result[1]).toBe("MYKEY=lpass-MYKEY");
                expect(adapter.lastArgs[1]).toBe("lpass");
                expect(adapter.lastArgs[2]).toBe("show");
                expect(adapter.lastArgs[3]).toBe("-p");
                expect(adapter.lastArgs[4]).toBe("MYKEY");
            });

            it("handles multiple keys", () => {
                var adapter = new cli.lucli.tests.specs.deploy.secrets._stubs.StubLastPassAdapter();
                var result = adapter.fetch({keys: ["X", "Y"]});
                expect(arrayLen(result)).toBe(2);
            });
        });
    }
}
