/**
 * `wheels deploy init` scaffolds .kamal/secrets. The file must be readable by
 * its owner only, kept out of git, and the template must steer users to
 * $(cmd) / ${VAR} lookups instead of literal values. An existing secrets file
 * is never overwritten.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("deploy init secrets file", () => {

			var $cwd = () => {
				var dir = getTempDirectory() & "wheels-init-secrets-" & createUUID();
				directoryCreate(dir, true, true);
				return dir;
			};

			var $init = (cwd, force = false) => {
				var cli = new cli.lucli.services.deploy.cli.DeployMainCli(new cli.lucli.services.deploy.lib.FakeSshPool());
				return cli.init_stub({cwd: cwd, service: "demo", image: "acme/demo", force: force});
			};

			var $mode = (path) => {
				var files = createObject("java", "java.nio.file.Files");
				var perms = files.getPosixFilePermissions(createObject("java", "java.nio.file.Paths").get(path, []), []);
				return createObject("java", "java.nio.file.attribute.PosixFilePermissions").toString(perms);
			};

			it("writes .kamal/secrets readable by its owner only", () => {
				var cwd = $cwd();
				try {
					$init(cwd);
					expect($mode(cwd & "/.kamal/secrets")).toBe("rw-------");
				} finally {
					directoryDelete(cwd, true);
				}
			});

			it("creates a .gitignore that lists .kamal/secrets", () => {
				var cwd = $cwd();
				try {
					$init(cwd);
					var lines = listToArray(fileRead(cwd & "/.gitignore"), chr(10));
					expect(arrayFind(lines, "/.kamal/secrets")).toBeGT(0);
				} finally {
					directoryDelete(cwd, true);
				}
			});

			it("appends to an existing .gitignore without a missing newline or a duplicate", () => {
				var cwd = $cwd();
				try {
					fileWrite(cwd & "/.gitignore", "node_modules/" & chr(10) & "db/*.sqlite");
					$init(cwd);
					$init(cwd, true);
					var content = fileRead(cwd & "/.gitignore");
					var lines = listToArray(content, chr(10));
					expect(arrayFind(lines, "node_modules/")).toBeGT(0);
					expect(arrayFind(lines, "db/*.sqlite")).toBeGT(0);
					var count = 0;
					for (var l in lines) if (trim(l) == "/.kamal/secrets") count++;
					expect(count).toBe(1);
				} finally {
					directoryDelete(cwd, true);
				}
			});

			it("keeps an existing .gitignore entry such as /.kamal/secrets without adding another", () => {
				var cwd = $cwd();
				try {
					fileWrite(cwd & "/.gitignore", "/.kamal/secrets" & chr(10));
					$init(cwd);
					var lines = listToArray(fileRead(cwd & "/.gitignore"), chr(10));
					expect(arrayLen(lines)).toBe(1);
				} finally {
					directoryDelete(cwd, true);
				}
			});

			it("appends the rule when a later negation un-ignores the secrets file", () => {
				var cwd = $cwd();
				try {
					fileWrite(cwd & "/.gitignore", ".kamal/secrets" & chr(10) & "!.kamal/secrets" & chr(10));
					$init(cwd);
					var lines = listToArray(fileRead(cwd & "/.gitignore"), chr(10));
					expect(lines[arrayLen(lines)]).toBe("/.kamal/secrets");
				} finally {
					directoryDelete(cwd, true);
				}
			});

			it("appends the rule after a later wildcard negation that could un-ignore the file", () => {
				for (var negation in ["!.kamal/*", "!**/secrets", "!.kamal/sec*"]) {
					var cwd = $cwd();
					try {
						fileWrite(cwd & "/.gitignore", ".kamal/secrets" & chr(10) & negation & chr(10));
						$init(cwd);
						var lines = listToArray(fileRead(cwd & "/.gitignore"), chr(10));
						expect(lines[arrayLen(lines)]).toBe("/.kamal/secrets", negation);
					} finally {
						directoryDelete(cwd, true);
					}
				}
			});

			it("does not treat a differently cased entry as ignoring the file", () => {
				var cwd = $cwd();
				try {
					fileWrite(cwd & "/.gitignore", ".KAMAL/SECRETS" & chr(10));
					$init(cwd);
					var lines = listToArray(fileRead(cwd & "/.gitignore"), chr(10));
					expect(arrayFind(lines, "/.kamal/secrets")).toBeGT(0);
				} finally {
					directoryDelete(cwd, true);
				}
			});

			it("fails before writing content when the new secrets file cannot be made owner-only", () => {
				var cwd = $cwd();
				try {
					var failing = {ownerOnly: function(path) { throw(type = "Probe.ChmodFailed", message = "chmod refused"); }};
					var cli = new cli.lucli.services.deploy.cli.DeployMainCli(
						new cli.lucli.services.deploy.lib.FakeSshPool(), {fileModes: failing});
					var thrown = {type = "", message = ""};
					try {
						cli.init_stub({cwd: cwd, service: "demo", image: "acme/demo"});
					} catch (any e) {
						thrown.type = e.type;
						thrown.message = e.message;
					}
					expect(thrown.type).toBe("DeployMainCli.SecretsPermission");
					expect(thrown.message).notToInclude("0600)");
					expect(fileExists(cwd & "/.kamal/secrets") ? fileRead(cwd & "/.kamal/secrets") : "").notToInclude("KAMAL_REGISTRY_PASSWORD");
				} finally {
					directoryDelete(cwd, true);
				}
			});

			it("fails loudly when an existing secrets file cannot be made owner-only, leaving its content", () => {
				var cwd = $cwd();
				try {
					directoryCreate(cwd & "/.kamal", true, true);
					fileWrite(cwd & "/.kamal/secrets", "TOKEN=$(op read op://a/b/c)" & chr(10));
					var failing = {ownerOnly: function(path) { throw(type = "Probe.ChmodFailed", message = "chmod refused"); }};
					var cli = new cli.lucli.services.deploy.cli.DeployMainCli(
						new cli.lucli.services.deploy.lib.FakeSshPool(), {fileModes: failing});
					var thrown = {type = ""};
					try {
						cli.init_stub({cwd: cwd, service: "demo", image: "acme/demo", force: true});
					} catch (any e) {
						thrown.type = e.type;
					}
					expect(thrown.type).toBe("DeployMainCli.SecretsPermission");
					expect(fileRead(cwd & "/.kamal/secrets")).toInclude("op://a/b/c");
				} finally {
					directoryDelete(cwd, true);
				}
			});

			it("lets git decide inside a repository: a wildcard rule git honours needs no new line", () => {
				var cwd = $cwd();
				try {
					cfexecute(name = "git", arguments = ["-C", cwd, "init", "-q"], timeout = 20);
					fileWrite(cwd & "/.gitignore", ".kamal/*" & chr(10));
					$init(cwd);
					expect(fileRead(cwd & "/.gitignore")).toBe(".kamal/*" & chr(10));
				} finally {
					directoryDelete(cwd, true);
				}
			});

			it("inside a repository, appends the rule when git says a later negation glob un-ignores the file", () => {
				var cwd = $cwd();
				try {
					cfexecute(name = "git", arguments = ["-C", cwd, "init", "-q"], timeout = 20);
					fileWrite(cwd & "/.gitignore", ".kamal/secrets" & chr(10) & "!.kamal/*" & chr(10));
					$init(cwd);
					var lines = listToArray(fileRead(cwd & "/.gitignore"), chr(10));
					expect(lines[arrayLen(lines)]).toBe("/.kamal/secrets");
					var probe = {exit = -1};
					cfexecute(name = "git", arguments = ["-C", cwd, "check-ignore", "-q", ".kamal/secrets"], timeout = 20, variable = "local.ignoredOut", result = "local.r");
					probe.exit = local.r.exitCode ?: -1;
					expect(probe.exit).toBe(0);
				} finally {
					directoryDelete(cwd, true);
				}
			});

			it("treats a final rooted rule in a different case as not ignoring the file", () => {
				var cwd = $cwd();
				try {
					fileWrite(cwd & "/.gitignore", "/.KAMAL/SECRETS" & chr(10));
					$init(cwd);
					var lines = listToArray(fileRead(cwd & "/.gitignore"), chr(10));
					expect(compare(lines[arrayLen(lines)], "/.kamal/secrets")).toBe(0);
				} finally {
					directoryDelete(cwd, true);
				}
			});

			it("warns when .kamal/secrets is already tracked by git", () => {
				var cwd = $cwd();
				try {
					cfexecute(name = "git", arguments = ["-C", cwd, "init", "-q"], timeout = 20);
					directoryCreate(cwd & "/.kamal", true, true);
					fileWrite(cwd & "/.kamal/secrets", "TOKEN=$(op read op://a/b/c)" & chr(10));
					cfexecute(name = "git", arguments = ["-C", cwd, "add", ".kamal/secrets"], timeout = 20);
					var msg = $init(cwd);
					expect(msg).toInclude("already tracked by git");
					expect(msg).toInclude("git rm --cached .kamal/secrets");
				} finally {
					directoryDelete(cwd, true);
				}
			});

			it("recommends $(cmd) and ${VAR} lookups instead of literal values", () => {
				var cwd = $cwd();
				try {
					$init(cwd);
					var tpl = fileRead(cwd & "/.kamal/secrets");
					expect(tpl).toInclude("$(");
					expect(tpl).toInclude("${");
					expect(tpl).notToInclude("set them directly");
				} finally {
					directoryDelete(cwd, true);
				}
			});

			it("never overwrites an existing secrets file, and tightens its permissions", () => {
				var cwd = $cwd();
				try {
					directoryCreate(cwd & "/.kamal", true, true);
					fileWrite(cwd & "/.kamal/secrets", "KAMAL_REGISTRY_PASSWORD=$(op read op://x/y/z)" & chr(10));
					var msg = $init(cwd, true);
					expect(fileRead(cwd & "/.kamal/secrets")).toInclude("op://x/y/z");
					expect($mode(cwd & "/.kamal/secrets")).toBe("rw-------");
					expect(msg).toInclude("preserved existing .kamal/secrets");
				} finally {
					directoryDelete(cwd, true);
				}
			});
		});
	}
}
