component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {
        describe("DopplerAdapter", () => {

            it("reports its name as 'doppler'", () => {
                var adapter = new cli.lucli.services.deploy.secrets.DopplerAdapter();
                expect(adapter.name()).toBe("doppler");
            });

            it("builds `doppler secrets get <key> --plain` with no project", () => {
                var adapter = new cli.lucli.tests.specs.deploy.secrets._stubs.StubDopplerAdapter();
                adapter.fetch({keys: ["TOKEN"]});
                expect(adapter.lastArgs[1]).toBe("doppler");
                expect(adapter.lastArgs[2]).toBe("secrets");
                expect(adapter.lastArgs[3]).toBe("get");
                expect(adapter.lastArgs[4]).toBe("TOKEN");
                expect(adapter.lastArgs[5]).toBe("--plain");
                // No --project tail.
                expect(arrayLen(adapter.lastArgs)).toBe(5);
            });

            it("appends --project when from is set", () => {
                var adapter = new cli.lucli.tests.specs.deploy.secrets._stubs.StubDopplerAdapter();
                adapter.fetch({from: "myproj", keys: ["TOKEN"]});
                expect(arrayLen(adapter.lastArgs)).toBe(7);
                expect(adapter.lastArgs[6]).toBe("--project");
                expect(adapter.lastArgs[7]).toBe("myproj");
            });

            it("returns KEY=VALUE", () => {
                var adapter = new cli.lucli.tests.specs.deploy.secrets._stubs.StubDopplerAdapter();
                var result = adapter.fetch({keys: ["A"]});
                expect(result[1]).toBe("A=doppler-A");
            });
        });
    }
}
