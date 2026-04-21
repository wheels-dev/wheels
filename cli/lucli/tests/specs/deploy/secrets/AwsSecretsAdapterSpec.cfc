component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {
        describe("AwsSecretsAdapter", () => {

            it("reports its name as 'aws'", () => {
                var adapter = new cli.lucli.services.deploy.secrets.AwsSecretsAdapter();
                expect(adapter.name()).toBe("aws");
            });

            it("defaults region to us-east-1 when from is empty", () => {
                var adapter = new cli.lucli.tests.specs.deploy.secrets._stubs.StubAwsSecretsAdapter();
                adapter.fetch({keys: ["mykey"]});
                var idx = 0;
                for (var i = 1; i <= arrayLen(adapter.lastArgs); i++) {
                    if (adapter.lastArgs[i] == "--region") { idx = i + 1; break; }
                }
                expect(idx).toBeGT(0);
                expect(adapter.lastArgs[idx]).toBe("us-east-1");
            });

            it("uses 'from' as region when provided", () => {
                var adapter = new cli.lucli.tests.specs.deploy.secrets._stubs.StubAwsSecretsAdapter();
                adapter.fetch({from: "eu-west-2", keys: ["mykey"]});
                var idx = 0;
                for (var i = 1; i <= arrayLen(adapter.lastArgs); i++) {
                    if (adapter.lastArgs[i] == "--region") { idx = i + 1; break; }
                }
                expect(adapter.lastArgs[idx]).toBe("eu-west-2");
            });

            it("returns KEY=VALUE", () => {
                var adapter = new cli.lucli.tests.specs.deploy.secrets._stubs.StubAwsSecretsAdapter();
                var result = adapter.fetch({keys: ["API_KEY"]});
                expect(result[1]).toBe("API_KEY=aws-API_KEY");
            });
        });
    }
}
