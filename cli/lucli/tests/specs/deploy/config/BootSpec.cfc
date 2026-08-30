component extends="wheels.wheelstest.system.BaseSpec" {

    function run() {
        describe("Boot — `boot:` block accessors", () => {

            it("defaults to limit 10 / wait 5 when the block is empty", () => {
                var b = new cli.lucli.services.deploy.config.Boot({});
                expect(b.limit()).toBe(10);
                expect(b.wait()).toBe(5);
            });

            it("propagates limit and wait from the raw block", () => {
                var b = new cli.lucli.services.deploy.config.Boot({limit: 3, wait: 15});
                expect(b.limit()).toBe(3);
                expect(b.wait()).toBe(15);
            });

            it("parses Kamal's percentage limit form", () => {
                var b = new cli.lucli.services.deploy.config.Boot({limit: "25%"});
                expect(b.limit()).toBe(25);
            });

            it("coerces string-typed numerics", () => {
                var b = new cli.lucli.services.deploy.config.Boot({limit: "2", wait: "8"});
                expect(b.limit()).toBe(2);
                expect(b.wait()).toBe(8);
            });

            it("degrades invalid shapes to the defaults", () => {
                var b = new cli.lucli.services.deploy.config.Boot({limit: "all", wait: "soon"});
                expect(b.limit()).toBe(10);
                expect(b.wait()).toBe(5);
            });

            it("preserves an explicit zero instead of the default", () => {
                var b = new cli.lucli.services.deploy.config.Boot({limit: 0, wait: 0});
                expect(b.limit()).toBe(0);
                expect(b.wait()).toBe(0);
            });

        });

        describe("Config.boot()", () => {

            it("returns a Boot accessor for the boot block", () => {
                var cfg = new cli.lucli.services.deploy.config.Config({
                    service: "demo",
                    image: "a/b",
                    servers: ["1.2.3.4"],
                    boot: {limit: 20, wait: 30}
                });
                var b = cfg.boot();
                expect(b.limit()).toBe(20);
                expect(b.wait()).toBe(30);
            });

            it("returns defaults when no boot block is present", () => {
                var cfg = new cli.lucli.services.deploy.config.Config({
                    service: "demo",
                    image: "a/b",
                    servers: ["1.2.3.4"]
                });
                var b = cfg.boot();
                expect(b.limit()).toBe(10);
                expect(b.wait()).toBe(5);
            });

        });
    }
}
