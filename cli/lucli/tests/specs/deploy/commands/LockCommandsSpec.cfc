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

            // Regression suite for #2957 DEP-10 — the whole symlink target used
            // to be single-quoted, which suppressed command substitution: lock
            // metadata recorded the LITERAL "$(hostname)/$(date ...)" text.
            // The fixed target concatenates three shell words — single-quoted
            // user, double-quoted substitution segment, single-quoted message —
            // so the metadata expands while hostile chars stay inert.

            it("acquire() exposes $(hostname)/$(date) in a double-quoted segment so the remote shell expands them (##2957 DEP-10)", () => {
                var cmd = variables.lock.acquire({user: "deploy", message: "deploying v1"});
                expect(cmd).toInclude('"@$(hostname)/$(date --iso-8601=seconds)/"');
            });

            it("acquire() keeps shell metacharacters in the message inert via single quotes (##2957 DEP-10)", () => {
                var cmd = variables.lock.acquire({user: "deploy", message: "pwn$(touch /tmp/pwned)"});
                expect(cmd).toInclude("'pwn$(touch /tmp/pwned)'");
            });

            it("acquire() keeps shell metacharacters in the user inert via single quotes (##2957 DEP-10)", () => {
                var cmd = variables.lock.acquire({user: "$(whoami)", message: "x"});
                expect(cmd).toInclude("'$(whoami)'");
            });
        });
    }
}
