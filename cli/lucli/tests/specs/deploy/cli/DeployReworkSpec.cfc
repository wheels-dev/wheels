/**
 * Kamal-parity fixes for `wheels deploy` (dry-run only; no real hosts):
 *   C-1  kamal-proxy gets --host, --tls and the health-check interval
 *   C-2  deploy/setup log in to the registry, build and push, then pull
 *   C-3  rollback cuts the proxy over on proxy roles only and stops other versions
 *   C-4  a --destination without its deploy.<name>.yml is an error
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("deploy rework", () => {

			var $project = () => {
				var root = getTempDirectory() & "wheels-deploy-rework-" & createUUID();
				directoryCreate(root & "/config", true, true);
				directoryCreate(root & "/.kamal", true, true);
				fileWrite(root & "/config/deploy.yml",
					"service: demo" & chr(10)
					& "image: acme/demo" & chr(10)
					& "servers:" & chr(10)
					& "  web:" & chr(10) & "    - 1.2.3.4" & chr(10)
					& "  workers:" & chr(10) & "    - 1.2.3.5" & chr(10)
					& "registry:" & chr(10)
					& "  server: registry.example.com" & chr(10)
					& "  username: demo" & chr(10)
					& "  password:" & chr(10) & "    - REGISTRY_PASSWORD" & chr(10)
					& "proxy:" & chr(10)
					& "  host: app.example.com" & chr(10)
					& "  ssl: true" & chr(10)
					& "  healthcheck:" & chr(10) & "    interval: 3" & chr(10) & "    timeout: 20" & chr(10));
				fileWrite(root & "/.kamal/secrets", "REGISTRY_PASSWORD=""reg-pass-1234""" & chr(10));
				return root;
			};

			var $cli = (root) => new cli.lucli.services.deploy.cli.DeployMainCli(
				new cli.lucli.services.deploy.lib.FakeSshPool(), {projectRoot: root});

			// Module.deploy() resets the registry per command; specs call the CLIs
			// directly in one request, so reset here to keep warnings per spec.
			beforeEach(() => {
				new cli.lucli.services.deploy.lib.SecretRedaction().reset();
			});

			var $lines = (out) => listToArray(out, chr(10));

			var $indexOf = (lines, needle) => {
				for (var i = 1; i <= arrayLen(lines); i++) {
					if (find(needle, lines[i])) return i;
				}
				return 0;
			};

			describe("C-4 destination overlay", () => {
				it("fails when the destination's deploy.<name>.yml does not exist", () => {
					var root = $project();
					try {
						var thrown = {type = "", message = ""};
						try {
							new cli.lucli.services.deploy.config.ConfigLoader().load(root & "/config/deploy.yml", {destination: "prodution"});
						} catch (any e) {
							thrown.type = e.type;
							thrown.message = e.message;
						}
						expect(thrown.type).toBe("DeployConfigError");
						expect(thrown.message).toInclude("deploy.prodution.yml");
					} finally {
						directoryDelete(root, true);
					}
				});

				it("still applies an existing destination overlay", () => {
					var root = $project();
					try {
						fileWrite(root & "/config/deploy.staging.yml", "servers:" & chr(10) & "  web:" & chr(10) & "    - 9.9.9.9" & chr(10));
						var cfg = new cli.lucli.services.deploy.config.ConfigLoader().load(root & "/config/deploy.yml", {destination: "staging"});
						expect(cfg.destination()).toBe("staging");
					} finally {
						directoryDelete(root, true);
					}
				});
			});

			describe("C-1 kamal-proxy options", () => {
				it("passes --host, --tls and the health-check interval and timeout as durations", () => {
					var root = $project();
					try {
						var out = $cli(root).deploy({configPath: root & "/config/deploy.yml", version: "v1", dryRun: true});
						var line = $lines(out)[$indexOf($lines(out), "kamal-proxy deploy")];
						expect(line).toInclude("--host 'app.example.com'");
						expect(line).toInclude("--tls");
						expect(line).toInclude("--health-check-interval 3s");
						expect(line).toInclude("--health-check-timeout 20s");
					} finally {
						directoryDelete(root, true);
					}
				});

				it("omits --host and --tls when the proxy has neither", () => {
					var cfg = new cli.lucli.services.deploy.config.Config({service: "demo", image: "acme/demo", servers: ["1.2.3.4"]});
					var line = new cli.lucli.services.deploy.commands.ProxyCommands(cfg).deploy(cfg.roles()[1], "demo-web-v1:80");
					expect(line).notToInclude("--host");
					expect(line).notToInclude("--tls");
					expect(line).toInclude("--health-check-timeout 30s");
				});
			});

			describe("C-2 registry login, build and push before pull", () => {
				it("logs in locally and on every host, builds and pushes, then pulls", () => {
					var root = $project();
					try {
						var lines = $lines($cli(root).deploy({configPath: root & "/config/deploy.yml", version: "v1", dryRun: true}));
						var localLogin = $indexOf(lines, "[local] docker login registry.example.com -u demo --password-stdin");
						var hostLogin = $indexOf(lines, "[1.2.3.4] docker login 'registry.example.com' -u 'demo' --password-stdin");
						var push = $indexOf(lines, "[local] docker buildx build --push --tag 'registry.example.com/acme/demo:v1'");
						var pull = $indexOf(lines, "[1.2.3.4] docker pull 'registry.example.com/acme/demo:v1'");
						expect(localLogin).toBeGT(0);
						expect(hostLogin).toBeGT(0);
						expect($indexOf(lines, "[1.2.3.5] docker login")).toBeGT(0);
						expect(push).toBeGT(localLogin);
						expect(pull).toBeGT(push);
						expect(pull).toBeGT(hostLogin);
						expect(arrayToList(lines, chr(10))).notToInclude("reg-pass-1234");
					} finally {
						directoryDelete(root, true);
					}
				});

				it("does the same for setup", () => {
					var root = $project();
					try {
						var out = $cli(root).setup({configPath: root & "/config/deploy.yml", version: "v1", dryRun: true});
						expect(out).toInclude("[local] docker buildx build --push");
						expect(out).toInclude("docker login registry.example.com");
					} finally {
						directoryDelete(root, true);
					}
				});

				it("skips the build and push with skipPush but still logs in and pulls", () => {
					var root = $project();
					try {
						var out = $cli(root).deploy({configPath: root & "/config/deploy.yml", version: "v1", dryRun: true, skipPush: true});
						expect(out).notToInclude("buildx build --push");
						expect(out).toInclude("docker login registry.example.com");
						expect(out).toInclude("docker pull 'registry.example.com/acme/demo:v1'");
					} finally {
						directoryDelete(root, true);
					}
				});
			});

			describe("C-2 real run (fake pool)", () => {
				it("sends the registry password only on stdin, locally and to every host", () => {
					var root = $project();
					try {
						var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
						var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake, {projectRoot: root});
						dc.deploy({configPath: root & "/config/deploy.yml", version: "v1"});
						var logins = {local = 0, remote = 0};
						for (var c in fake.calls()) {
							expect(c.cmd ?: "").notToInclude("reg-pass-1234");
							if (findNoCase("docker login", c.cmd ?: "")) {
								expect(c.opts.stdin).toBe("reg-pass-1234");
								if (c.host == "local") logins.local++; else logins.remote++;
							}
						}
						expect(logins.local).toBe(1);
						expect(logins.remote).toBe(2);
						var pushed = false;
						for (var c in fake.calls()) if (c.host == "local" && find("buildx build --push", c.cmd)) pushed = true;
						expect(pushed).toBeTrue();
					} finally {
						directoryDelete(root, true);
					}
				});

				it("warns and skips docker login when no registry password resolves", () => {
					var root = $project();
					try {
						fileWrite(root & "/.kamal/secrets", "UNRELATED=placeholder" & chr(10));
						var out = $cli(root).deploy({configPath: root & "/config/deploy.yml", version: "v1", dryRun: true});
						expect(out).toInclude("WARNING: registry.username is set but no registry.password key resolves");
						// No dispatched login line (the warning text itself names docker login).
						expect(out).notToInclude("] docker login");
						expect(out).toInclude("docker pull");
					} finally {
						directoryDelete(root, true);
					}
				});
			});

			describe("registry fields with shell characters", () => {
				it("runs the local login as argv and quotes the remote login", () => {
					var root = $project();
					try {
						var yml = fileRead(root & "/config/deploy.yml");
						yml = replace(yml, "  username: demo", "  username: robot$ci");
						fileWrite(root & "/config/deploy.yml", yml);
						var fake = new cli.lucli.services.deploy.lib.FakeSshPool();
						var dc = new cli.lucli.services.deploy.cli.DeployMainCli(fake, {projectRoot: root});
						dc.deploy({configPath: root & "/config/deploy.yml", version: "v1"});
						var localArgv = [];
						var remoteCmd = "";
						for (var c in fake.calls()) {
							if (c.host == "local" && isArray(c.argv ?: "") && arrayLen(c.argv) > 1 && c.argv[2] == "login") localArgv = c.argv;
							if (c.host == "1.2.3.4" && findNoCase("docker login", c.cmd ?: "")) remoteCmd = c.cmd;
						}
						expect(localArgv).toBe(["docker", "login", "registry.example.com", "-u", "robot$ci", "--password-stdin"]);
						expect(remoteCmd).toInclude("-u 'robot$ci'");
						expect(remoteCmd).toInclude("login 'registry.example.com'");
					} finally {
						directoryDelete(root, true);
					}
				});
			});

			describe("proxy config", () => {
				it("rejects ssl without a host at config load", () => {
					var thrown = {type = ""};
					try {
						new cli.lucli.services.deploy.config.Validator().validate(
							{service: "demo", image: "acme/demo", servers: ["1.2.3.4"], proxy: {ssl: true}}, "deploy.yml");
					} catch (any e) {
						thrown.type = e.type;
					}
					expect(thrown.type).toBe("DeployConfigError");
				});

				it("accepts fractional seconds and Go durations, rejects malformed ones", () => {
					var mk = (hc) => new cli.lucli.services.deploy.commands.ProxyCommands(
						new cli.lucli.services.deploy.config.Config({service: "demo", image: "acme/demo", servers: ["1.2.3.4"], proxy: {healthcheck: hc}}));
					var role = new cli.lucli.services.deploy.config.Config({service: "demo", image: "acme/demo", servers: ["1.2.3.4"]}).roles()[1];
					expect(mk({interval: 0.5}).deploy(role, "t:80")).toInclude("--health-check-interval 0.5s");
					expect(mk({interval: "500ms"}).deploy(role, "t:80")).toInclude("--health-check-interval 500ms");
					for (var bad in ["1.2.3s", "..s", "5x", "-1"]) {
						expect(() => mk({interval: bad}).deploy(role, "t:80")).toThrow("DeployConfigError");
					}
				});
			});

			describe("C-3 rollback", () => {
				it("cuts the proxy over only on proxy roles and stops the other versions everywhere", () => {
					var root = $project();
					try {
						var out = $cli(root).rollback({configPath: root & "/config/deploy.yml", version: "v1", dryRun: true});
						expect(out).toInclude("[1.2.3.4] docker exec kamal-proxy kamal-proxy deploy");
						expect(out).notToInclude("[1.2.3.5] docker exec kamal-proxy");
						expect(out).toInclude("[1.2.3.5] docker start 'demo-workers-v1'");
						expect(out).toInclude("[1.2.3.4] docker ps --filter 'label=service=demo' --filter 'label=role=web'");
						expect(out).toInclude("[1.2.3.5] docker ps --filter 'label=service=demo' --filter 'label=role=workers'");
					} finally {
						directoryDelete(root, true);
					}
				});
			});
		});
	}
}
