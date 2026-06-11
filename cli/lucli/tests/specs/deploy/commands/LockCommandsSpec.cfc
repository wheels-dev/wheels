component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.cfg = new cli.lucli.services.deploy.config.ConfigLoader()
            .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml"));
        variables.lock = new cli.lucli.services.deploy.commands.LockCommands(variables.cfg);
    }

    function run() {
        describe("LockCommands", () => {

            it("acquire() creates a symlink at the Kamal lock path", () => {
                var cmd = variables.lock.acquire({user: "deploy", message: "deploying v1"});
                expect(cmd).toInclude("ln -s");
                expect(cmd).toInclude("/tmp/kamal_deploy_lock_demo");
            });

            it("acquire() embeds the user + message in the symlink target", () => {
                var cmd = variables.lock.acquire({user: "deploy", message: "deploying v1"});
                expect(cmd).toInclude("deploy");
                expect(cmd).toInclude("deploying v1");
            });

            it("release() removes the lock path", () => {
                var cmd = variables.lock.release();
                expect(cmd).toInclude("rm -f");
                expect(cmd).toInclude("/tmp/kamal_deploy_lock_demo");
            });

            it("status() readlinks the lock path", () => {
                var cmd = variables.lock.status();
                expect(cmd).toInclude("readlink");
                expect(cmd).toInclude("/tmp/kamal_deploy_lock_demo");
            });

            it("lockPath() exposes the service-scoped path", () => {
                expect(variables.lock.lockPath()).toBe("/tmp/kamal_deploy_lock_demo");
            });

            it("acquire() escapes single quotes in the user", () => {
                var cmd = variables.lock.acquire({user: "o'brien", message: "x"});
                expect(cmd).toInclude("ln -s");
                expect(cmd).toInclude("o'\''brien");
                expect(cmd).toInclude("/tmp/kamal_deploy_lock_demo");
            });

            it("acquire() without a message is still valid (defaults to empty)", () => {
                var cmd = variables.lock.acquire({user: "deploy"});
                expect(cmd).toInclude("ln -s");
                expect(cmd).toInclude("/tmp/kamal_deploy_lock_demo");
            });
        });
    }
}
