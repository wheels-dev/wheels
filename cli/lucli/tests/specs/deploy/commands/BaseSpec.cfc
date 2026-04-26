component extends="wheels.wheelstest.system.BaseSpec" {
    function run() {
        describe("Commands.Base", () => {
            var base = new modules.wheels.services.deploy.commands.Base();

            it("docker() joins args with spaces", () => {
                expect(base.docker("run", "-d", "alpine")).toBe("docker run -d alpine");
            });

            it("docker() flattens array args", () => {
                expect(base.docker("run", ["-d", "--rm"], "alpine")).toBe("docker run -d --rm alpine");
            });

            it("docker() skips empty strings silently", () => {
                expect(base.docker("run", "", "alpine")).toBe("docker run alpine");
            });

            it("chain() joins with &&", () => {
                expect(base.chain(["docker stop x", "docker rm x"])).toBe("docker stop x && docker rm x");
            });

            it("pipe() joins with |", () => {
                expect(base.pipe(["docker ps", "grep kamal"])).toBe("docker ps | grep kamal");
            });

            it("appendIf() gates inclusion", () => {
                expect(base.appendIf(true, ["--force"])).toBe("--force");
                expect(base.appendIf(false, ["--force"])).toBe("");
            });
        });
    }
}
