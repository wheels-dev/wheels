/**
 * `wheels deploy build push` honours builder.arch, builder.args and builder.remote (4415), and
 * `app logs` without --container and `prune images` emit docker commands that work (4416).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		var loader = new cli.lucli.services.deploy.config.ConfigLoader();
		variables.options = loader.load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/builder-options.yml"));
		variables.minimal = new cli.lucli.services.deploy.config.ConfigLoader()
			.load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml"));
	}

	function run() {

		describe("deploy build push with builder options", () => {

			it("builds for every configured arch", () => {
				var cmd = new cli.lucli.services.deploy.commands.BuilderCommands(variables.options).push("v3");
				expect(cmd).toInclude("--platform linux/amd64,linux/arm64");
			});

			it("builds for amd64 by default", () => {
				var cmd = new cli.lucli.services.deploy.commands.BuilderCommands(variables.minimal).push("v3");
				expect(cmd).toInclude("--platform linux/amd64");
			});

			it("passes each builder arg as --build-arg, values shell-escaped", () => {
				var cmd = new cli.lucli.services.deploy.commands.BuilderCommands(variables.options).push("v3");
				expect(cmd).toInclude("--build-arg 'RUBY_VERSION=3.3'");
				expect(cmd).toInclude("--build-arg 'APP_ENV=production'");
			});

			it("builds on the remote builder when builder.remote is set, and creates it there", () => {
				var cmds = new cli.lucli.services.deploy.commands.BuilderCommands(variables.options);
				expect(cmds.push("v3")).toInclude("--builder kamal-demo");
				expect(cmds.create()).toInclude("'ssh://deploy@builder.example.com'");
			});

			it("uses the default builder when no remote is set", () => {
				var cmds = new cli.lucli.services.deploy.commands.BuilderCommands(variables.minimal);
				expect(cmds.push("v3")).notToInclude("--builder");
				expect(cmds.create()).notToInclude("ssh://");
			});

			it("takes a comma-separated arch string as several platforms", () => {
				var cfg = new cli.lucli.services.deploy.config.Config({service: "demo", image: "acme/demo", servers: ["1.2.3.4"], builder: {arch: "amd64, arm64"}});
				expect(new cli.lucli.services.deploy.commands.BuilderCommands(cfg).push("v3")).toInclude("--platform linux/amd64,linux/arm64");
			});

			it("refuses an arch that isn't a plain platform name, before it reaches the shell", () => {
				var bad = ["amd64; rm -rf /", "amd64 $(id)", "linux/amd64`id`", "arm64 --push"];
				for (var arch in bad) {
					var cfg = new cli.lucli.services.deploy.config.Config({service: "demo", image: "acme/demo", servers: ["1.2.3.4"], builder: {arch: [arch]}});
					var state = {type = "", message = ""};
					try {
						new cli.lucli.services.deploy.commands.BuilderCommands(cfg).push("v3");
					} catch (any e) {
						state.type = e.type;
						state.message = e.message;
					}
					expect(state.type).toBe("Wheels.Deploy.InvalidInput", "arch [" & arch & "]");
					expect(state.message).toInclude("builder.arch");
				}
			});

			it("labels the image with its service, so prune images can find it", () => {
				var cmd = new cli.lucli.services.deploy.commands.BuilderCommands(variables.minimal).push("v3");
				expect(cmd).toInclude("--label 'service=demo'");
			});

		});

		describe("deploy app logs and prune images", () => {

			it("logs without --container tails the role's newest running container", () => {
				var cmd = new cli.lucli.services.deploy.commands.AppCommands(variables.minimal)
					.logs({tail: 100}, variables.minimal.roles()[1]);
				expect(cmd).toInclude("docker ps --latest --quiet");
				expect(cmd).toInclude("label=service=demo");
				expect(cmd).toInclude("label=role=web");
				expect(cmd).toInclude("| xargs -r docker logs --tail 100");
			});

			it("logs with --container tails that container", () => {
				var cmd = new cli.lucli.services.deploy.commands.AppCommands(variables.minimal)
					.logs({tail: 50, container: "demo-web-abc"}, variables.minimal.roles()[1]);
				expect(cmd).toBe("docker logs --tail 50 'demo-web-abc'");
			});

			it("prune images removes every unused image of the service, not only dangling ones", () => {
				var cmd = new cli.lucli.services.deploy.commands.PruneCommands(variables.minimal).images();
				expect(cmd).toInclude("docker image prune --all --force");
				expect(cmd).toInclude("label=service=demo");
			});

		});

	}

}
