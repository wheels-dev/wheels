/**
 * Package names become filesystem paths (vendor/<name>/, the manifest cache)
 * and registry URLs, and `remove` deletes vendor/<name>/ recursively. A name
 * must be a single plain path segment, and every resolved target must be a
 * direct child of vendor/.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("Package name safety", () => {

			var $scratch = () => {
				var root = GetTempDirectory() & "wheels-proj-" & CreateUUID() & "/";
				DirectoryCreate(root & "vendor", true);
				// A root package.json, as any project that also uses npm has.
				FileWrite(root & "package.json", '{"name":"my-app"}');
				FileWrite(root & "KEEP.txt", "user data");
				return root;
			};

			var $expectBadInput = (fn) => {
				var threwType = "";
				try {
					fn();
				} catch (any e) {
					threwType = e.type;
				}
				expect(threwType).toBe("Wheels.Packages.BadInput");
			};

			describe("Installer", () => {

				it("refuses to uninstall '..' and leaves the project untouched", () => {
					var proj = $scratch();
					var installer = new cli.lucli.services.packages.Installer(projectRoot = proj);
					$expectBadInput(() => installer.uninstall(".."));
					expect(FileExists(proj & "KEEP.txt")).toBeTrue();
					expect(DirectoryExists(proj & "vendor")).toBeTrue();
					DirectoryDelete(proj, true);
				});

				it("refuses names that are paths, not a single segment", () => {
					var proj = $scratch();
					var installer = new cli.lucli.services.packages.Installer(projectRoot = proj);
					for (var bad in ["../x", "a/b", "a\b", ".", "/etc", "", " x", "wheels-sentry" & chr(10), "wheels-sentry" & chr(13), "wheels-sentry" & chr(9)]) {
						$expectBadInput(() => installer.uninstall(bad));
					}
					DirectoryDelete(proj, true);
				});

				it("refuses to install under a traversal name before touching anything", () => {
					var proj = $scratch();
					var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
					var installer = new cli.lucli.services.packages.Installer(httpClient = fake, projectRoot = proj);
					$expectBadInput(() => installer.install("..", {version: "1.0.0", tarball: "https://example/x.tgz", sha256: "00"}, true));
					expect(FileExists(proj & "KEEP.txt")).toBeTrue();
					DirectoryDelete(proj, true);
				});

				it("still removes an ordinary installed package", () => {
					var proj = $scratch();
					DirectoryCreate(proj & "vendor/wheels-sentry", true);
					FileWrite(proj & "vendor/wheels-sentry/package.json", '{"name":"wheels-sentry","version":"1.2.0"}');
					new cli.lucli.services.packages.Installer(projectRoot = proj).uninstall("wheels-sentry");
					expect(DirectoryExists(proj & "vendor/wheels-sentry")).toBeFalse();
					expect(FileExists(proj & "KEEP.txt")).toBeTrue();
					DirectoryDelete(proj, true);
				});
			});

			describe("ManifestCache and Registry", () => {

				it("refuses to read or write a cached manifest outside the cache", () => {
					var cache = new cli.lucli.services.packages.ManifestCache(root = GetTempDirectory() & "wheels-cache-" & CreateUUID() & "/");
					$expectBadInput(() => cache.writeManifest("../../escape", {name: "x", versions: []}));
					$expectBadInput(() => cache.readManifest("../escape"));
				});

				it("refuses to build a registry URL from a traversal name", () => {
					var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
					var registry = new cli.lucli.services.packages.Registry(
						httpClient = fake,
						cache = new cli.lucli.services.packages.ManifestCache(root = GetTempDirectory() & "wheels-cache-" & CreateUUID() & "/"),
						registryRepo = "test/reg"
					);
					$expectBadInput(() => registry.fetchManifest("../../../../other/repo/main"));
				});
			});

			describe("wheels packages remove", () => {

				it("requires --yes before deleting a package", () => {
					var proj = $scratch();
					DirectoryCreate(proj & "vendor/wheels-sentry", true);
					FileWrite(proj & "vendor/wheels-sentry/package.json", '{"name":"wheels-sentry"}');
					var cli = new cli.lucli.services.packages.PackagesMainCli(
						installer = new cli.lucli.services.packages.Installer(projectRoot = proj),
						runtimeVersion = "4.1.2"
					);
					var threwType = "";
					try {
						cli.remove({target: "wheels-sentry"});
					} catch (any e) {
						threwType = e.type;
					}
					expect(threwType).toBe("Wheels.Packages.ConfirmationRequired");
					expect(DirectoryExists(proj & "vendor/wheels-sentry")).toBeTrue();
					cli.remove({target: "wheels-sentry", yes: true});
					expect(DirectoryExists(proj & "vendor/wheels-sentry")).toBeFalse();
					DirectoryDelete(proj, true);
				});
			});
		});
	}
}
