component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.helper = new cli.lucli.tests._helpers.DeployShellHelper();
		variables.helper.sshdUp();
		variables.fixtureDir = expandPath("/cli/lucli/tests/_fixtures/deploy/sshd");
	}

	function afterAll() {
		variables.helper.sshdDown();
	}

	function run() {
		describe("SshPool", () => {

			it("runs a command on every host via onEach", () => {
				var pool = makePool();
				// Shared struct so closure mutations are visible to the outer thread.
				var results = {};
				pool.onEach(["localhost:22022", "localhost:22023"], function(ssh, host) {
					results[host] = trim(ssh.run("hostname").stdout);
				});
				expect(structCount(results)).toBe(2);
				expect(structKeyExists(results, "localhost:22022")).toBeTrue();
				expect(structKeyExists(results, "localhost:22023")).toBeTrue();
				pool.close();
			});

			it("onEach runs hosts in parallel (faster than serial)", () => {
				var pool = makePool();
				var start = getTickCount();
				pool.onEach(["localhost:22022", "localhost:22023"], function(ssh, host) {
					ssh.run("sleep 2");
				});
				var elapsed = getTickCount() - start;
				// Parallel: ~2s + overhead. Serial would be >4s. Threshold is
				// slack enough to survive a busy CI host.
				expect(elapsed).toBeLT(3500);
				pool.close();
			});

			it("sequential preserves ordering", () => {
				var pool = makePool();
				var order = [];
				pool.sequential(["localhost:22022", "localhost:22023"], function(ssh, host) {
					arrayAppend(order, host);
				});
				expect(order[1]).toBe("localhost:22022");
				expect(order[2]).toBe("localhost:22023");
				pool.close();
			});

			it("reuses connections across calls to the same host", () => {
				var pool = makePool();
				var first = pool.getConnection("localhost:22022");
				var second = pool.getConnection("localhost:22022");
				// Same object reference — connection cache hit.
				expect(first).toBe(second);
				pool.close();
			});

		});
	}

	private any function makePool() {
		return new cli.lucli.services.deploy.lib.SshPool({
			user: "deploy",
			privateKey: variables.fixtureDir & "/test_key",
			strictHostKeyChecking: false
		});
	}

}
