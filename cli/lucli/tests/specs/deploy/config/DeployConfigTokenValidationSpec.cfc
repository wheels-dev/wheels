/**
 * The app image, accessory images and every host are interpolated into local
 * (bash -c) and remote shell commands. Config load rejects values outside the
 * shapes those fields actually take, and the build/pull commands quote the
 * image as well.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("Deploy config token validation", () => {

			var $config = (overrides) => {
				var c = {service: "demo", image: "acme/demo", servers: ["1.2.3.4"]};
				for (var k in overrides) c[k] = overrides[k];
				return c;
			};

			var $error = (parsed) => {
				try {
					new cli.lucli.services.deploy.config.Validator().validate(parsed, "deploy.yml");
				} catch (any e) {
					return e.type;
				}
				return "";
			};

			describe("app image", () => {
				it("accepts registry, path and port forms", () => {
					for (var img in ["acme/demo", "ghcr.io/org/app", "registry.example.com:5000/team/app", "app"]) {
						expect($error($config({image: img}))).toBe("", img);
					}
				});
				it("rejects shell metacharacters, whitespace and line endings", () => {
					for (var img in ["a/b; touch /tmp/pwn", "a/b$(id)", "a/b`id`", "a/b c", "acme/demo" & chr(10), "-acme/demo"]) {
						expect($error($config({image: img}))).toBe("DeployConfigError", img);
					}
				});
			});

			describe("hosts", () => {
				it("accepts host names, IPs, user@host:port and bracketed IPv6", () => {
					for (var h in ["app.example.com", "10.0.0.5", "deploy@10.0.0.5:2222", "[::1]:22"]) {
						expect($error($config({servers: [h]}))).toBe("", h);
					}
				});
				it("rejects a host with shell metacharacters or a line ending", () => {
					for (var h in ["192.0.2.10;id", "host$(id)", "host id", "10.0.0.5" & chr(10), "-oProxyCommand=x"]) {
						expect($error($config({servers: [h]}))).toBe("DeployConfigError", h);
						expect($error($config({servers: {web: {hosts: [h]}}}))).toBe("DeployConfigError", h);
					}
				});
			});

			describe("accessories", () => {
				it("accepts tagged and digest-pinned images", () => {
					var acc = {db: {image: "postgres:16@sha256:0123456789abcdef", host: "10.0.0.6"}};
					expect($error($config({accessories: acc}))).toBe("");
				});
				it("rejects an injected accessory image or host", () => {
					expect($error($config({accessories: {db: {image: "mysql:8.0; id", host: "10.0.0.6"}}}))).toBe("DeployConfigError");
					expect($error($config({accessories: {db: {image: "mysql:8.0", host: "10.0.0.6;id"}}}))).toBe("DeployConfigError");
					expect($error($config({accessories: {db: {image: "mysql:8.0", hosts: ["ok.example", "x$(id)"]}}}))).toBe("DeployConfigError");
				});
			});

			describe("service, role and accessory names", () => {
				it("reject a trailing line feed", () => {
					expect($error($config({service: "demo" & chr(10)}))).toBe("DeployConfigError");
					expect($error($config({servers: {("web" & chr(10)): ["1.2.3.4"]}}))).toBe("DeployConfigError");
					expect($error($config({accessories: {("db" & chr(10)): {image: "mysql:8.0", host: "10.0.0.6"}}}))).toBe("DeployConfigError");
				});
			});

			describe("build and pull commands", () => {
				it("quote the image on the local build and the remote pull", () => {
					var cfg = new cli.lucli.services.deploy.config.Config($config({}));
					var builder = new cli.lucli.services.deploy.commands.BuilderCommands(cfg);
					expect(builder.push("v1")).toInclude("--tag 'acme/demo:v1'");
					expect(builder.pull("v1")).toInclude("docker pull 'acme/demo:v1'");
				});
				it("refuse an injected version on both paths", () => {
					var cfg = new cli.lucli.services.deploy.config.Config($config({}));
					var builder = new cli.lucli.services.deploy.commands.BuilderCommands(cfg);
					for (var v in ["v1;id", "v1$(id)"]) {
						expect(() => builder.push(v)).toThrow("Wheels.Deploy.InvalidInput");
						expect(() => builder.pull(v)).toThrow("Wheels.Deploy.InvalidInput");
					}
				});
			});
		});
	}
}
