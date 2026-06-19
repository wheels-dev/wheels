/**
 * Regression guard for #2957 DEP-7 — the flat `wheels deploy bootstrap` /
 * `wheels deploy exec` aliases constructed a bare `new SshPool()` instead of
 * routing through `$deployBuildSshPool(opts.configPath)` like every other
 * deploy verb. A bare pool ignores the deploy.yml `ssh:` block entirely, so
 * any config with a non-root `ssh.user`, custom `ssh.port`, or a `keys:`
 * path got `root@host:22` + ssh-agent instead. The flat aliases are the only
 * CLI-reachable form (LuCLI's picocli root absorbs the nested `server` verb
 * before module dispatch — #2677), so for real CLI users the broken pool was
 * the only pool.
 *
 * Like every other Module.cfc spec, source-level inspection — Module extends
 * `modules.BaseModule`, which is only resolvable at LuCLI runtime, and the
 * constructed pool is buried inside DeployServerCli with no accessor. The
 * config-seeding behavior of `$deployBuildSshPool` itself is pinned by
 * SshPoolFactorySpec; this spec pins that the aliases actually call it.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
	}

	function run() {
		describe("deploy flat aliases honor ssh: config (##2957 DEP-7)", () => {

			it("no deploy CLI is ever constructed with a bare config-less SshPool", () => {
				// Every pool the deploy dispatcher hands to a Deploy*Cli must be
				// seeded from deploy.yml via $deployBuildSshPool. A literal
				// `new modules.wheels.services.deploy.lib.SshPool(` anywhere in
				// Module.cfc means some verb is skipping the ssh: config again.
				expect(find("new modules.wheels.services.deploy.lib.SshPool(", variables.moduleSource))
					.toBe(0);
			});

			it("the flat bootstrap alias builds its pool from the deploy config", () => {
				var body = $caseBody('case "bootstrap":', 'case "exec":');
				expect(body).toInclude("$deployBuildSshPool(opts.configPath)");
			});

			it("the flat exec alias builds its pool from the deploy config", () => {
				var body = $caseBody('case "exec":', 'case "server":');
				expect(body).toInclude("$deployBuildSshPool(opts.configPath)");
			});

		});
	}

	/** Slice of Module.cfc between two case labels (asserts both exist). */
	private string function $caseBody(required string fromLabel, required string toLabel) {
		var startPos = find(arguments.fromLabel, variables.moduleSource);
		var endPos = find(arguments.toLabel, variables.moduleSource, startPos + 1);
		expect(startPos).toBeGT(0, "case label not found: " & arguments.fromLabel);
		expect(endPos).toBeGT(startPos, "case label not found after start: " & arguments.toLabel);
		return mid(variables.moduleSource, startPos, endPos - startPos);
	}
}
