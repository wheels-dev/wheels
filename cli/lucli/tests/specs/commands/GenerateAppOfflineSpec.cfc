/**
 * `wheels generate app <name> --offline` delegates to `wheels new`. generate
 * consumed --offline itself and did not forward it, so new()'s own
 * $consumeOfflineFlag() reset the offline state and the update check ran
 * anyway (rev1-r2 LOW on #3674).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("generate app forwards --offline to new", () => {

			it("new() receives offline and is still offline inside", () => {
				var mod = new cli.lucli.tests._fixtures.commands.NewCaptureModule(cwd = expandPath("/"));
				mod.generate(arg1 = "app", arg2 = "offapp", offline = true);
				var forwarded = mod.capturedNewArgs();
				expect(forwarded).toHaveKey("offline");
				expect(forwarded.offline).toBe("true");
				expect(mod.wasOfflineInsideNew()).toBeTrue();
				mod.$consumeOfflineFlag([]);
			});

			it("does not forward offline when it was not passed (no sticky state)", () => {
				if (len(server.system.environment.WHEELS_OFFLINE ?: "")) {
					return; // offline forced by the environment for this run
				}
				var mod = new cli.lucli.tests._fixtures.commands.NewCaptureModule(cwd = expandPath("/"));
				mod.$consumeOfflineFlag(["--offline"]); // left over from an earlier call
				mod.generate(arg1 = "app", arg2 = "onlineapp");
				expect(mod.capturedNewArgs()).notToHaveKey("offline");
				expect(mod.wasOfflineInsideNew()).toBeFalse();
			});

		});

	}

}
