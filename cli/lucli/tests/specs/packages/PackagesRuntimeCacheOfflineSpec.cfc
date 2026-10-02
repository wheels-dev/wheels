/**
 * #3911: `wheels packages` resolves compatibility against the app's own
 * framework version (a dev CLI is permissive), keys the manifest cache by
 * registry under the CLI home, and offline mode serves whatever is cached
 * or says plainly that nothing is.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("packages: runtime version for compatibility", () => {

			var $project = (string version = "") => {
				var root = GetTempDirectory() & "wheels-proj-" & CreateUUID() & "/";
				DirectoryCreate(root & "vendor/wheels", true);
				if (Len(version)) {
					FileWrite(root & "vendor/wheels/wheels.json", SerializeJSON({name: "wheels-core", version: version}));
				}
				return root;
			};

			it("uses the project's vendor/wheels version, not the CLI's", () => {
				var root = $project("4.1.2");
				var cli = new cli.lucli.services.packages.PackagesMainCli(projectRoot = root);
				expect(cli.runtimeVersion()).toBe("4.1.2");
				DirectoryDelete(root, true);
			});

			it("falls back to the CLI version when vendor/wheels carries an unstamped build token", () => {
				var root = $project("@build.version@");
				var cli = new cli.lucli.services.packages.PackagesMainCli(projectRoot = root);
				expect(cli.runtimeVersion()).notToInclude("@");
				expect(Len(cli.runtimeVersion())).toBeGT(0);
				DirectoryDelete(root, true);
			});

			it("an explicit runtimeVersion still wins", () => {
				var root = $project("4.1.2");
				var cli = new cli.lucli.services.packages.PackagesMainCli(projectRoot = root, runtimeVersion = "4.0.0");
				expect(cli.runtimeVersion()).toBe("4.0.0");
				DirectoryDelete(root, true);
			});

			it("treats a dev runtime as compatible with every wheelsVersion range", () => {
				var resolver = new cli.lucli.services.packages.VersionResolver();
				var manifest = {name: "wheels-x", versions: [
					{version: "1.0.0", wheelsVersion: ">=4.0"},
					{version: "2.0.0", wheelsVersion: ">=4.1 <5.0"}
				]};
				expect(resolver.pick(manifest, "0.0.0-dev").version).toBe("2.0.0");
				expect(ArrayLen(resolver.compatibleVersions(manifest, "0.0.0-dev"))).toBe(2);
			});

			it("still gates a released runtime", () => {
				var resolver = new cli.lucli.services.packages.VersionResolver();
				var manifest = {name: "wheels-x", versions: [
					{version: "1.0.0", wheelsVersion: ">=4.0"},
					{version: "2.0.0", wheelsVersion: ">=4.1 <5.0"}
				]};
				expect(resolver.pick(manifest, "4.0.3").version).toBe("1.0.0");
			});
		});

		describe("packages: manifest cache location", () => {

			it("roots the default cache under the CLI home", () => {
				var sys = CreateObject("java", "java.lang.System");
				var saved = sys.getProperty("lucli.home");
				var home = GetTempDirectory() & "wheels-home-" & CreateUUID();
				try {
					sys.setProperty("lucli.home", home);
					var root = new cli.lucli.services.packages.ManifestCache().root();
				} finally {
					if (IsNull(saved)) {
						sys.clearProperty("lucli.home");
					} else {
						sys.setProperty("lucli.home", saved);
					}
				}
				expect(root).toBe(home & "/cache/packages");
			});

			it("keeps the default registry at the shared root and namespaces any other registry", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var standard = new cli.lucli.services.packages.Registry(httpClient = fake, registryRepo = "wheels-dev/wheels-packages");
				var forkA = new cli.lucli.services.packages.Registry(httpClient = fake, registryRepo = "acme/pkgs");
				var forkB = new cli.lucli.services.packages.Registry(httpClient = fake, registryRepo = "other/pkgs");
				var forkBranch = new cli.lucli.services.packages.Registry(httpClient = fake, registryRepo = "acme/pkgs", branch = "next");
				var base = new cli.lucli.services.packages.ManifestCache().root();
				expect(standard.cache().root()).toBe(base);
				expect(forkA.cache().root()).toInclude(base & "/registries/");
				expect(forkA.cache().root()).notToBe(forkB.cache().root());
				expect(forkA.cache().root()).notToBe(forkBranch.cache().root());
			});
		});

		describe("packages: offline with an empty or stale cache", () => {

			var $cache = (numeric ttl = 0) => {
				return new cli.lucli.services.packages.ManifestCache(
					root = GetTempDirectory() & "wheels-cache-" & CreateUUID() & "/",
					ttlSeconds = ttl
				);
			};

			beforeEach(() => {
				request.$wheelsOffline = true;
			});

			afterEach(() => {
				StructDelete(request, "$wheelsOffline");
			});

			it("says no cached data exists when the index was never fetched", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var r = new cli.lucli.services.packages.Registry(httpClient = fake, cache = $cache(), registryRepo = "acme/pkgs");
				var thrown = {type = "", message = ""};
				try {
					r.listPackageNames();
				} catch (any e) {
					thrown.type = e.type;
					thrown.message = e.message;
				}
				expect(thrown.type).toBe("Wheels.Packages.Offline");
				expect(thrown.message).toInclude("No cached registry data");
				expect(thrown.message).notToInclude("still available");
				expect(ArrayLen(fake.calls())).toBe(0);
			});

			it("says no cached manifest exists when the package was never fetched", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var r = new cli.lucli.services.packages.Registry(httpClient = fake, cache = $cache(), registryRepo = "acme/pkgs");
				var thrown = {type = "", message = ""};
				try {
					r.fetchManifest("wheels-sentry");
				} catch (any e) {
					thrown.type = e.type;
					thrown.message = e.message;
				}
				expect(thrown.type).toBe("Wheels.Packages.Offline");
				expect(thrown.message).toInclude("No cached registry data");
				expect(ArrayLen(fake.calls())).toBe(0);
			});

			it("serves an expired cache instead of refusing", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var cache = $cache(1);
				cache.writeIndex(["wheels-sentry"]);
				cache.writeManifest("wheels-sentry", {name: "wheels-sentry", versions: [{version: "1.0.0"}]});
				sleep(1100);
				expect(cache.hasFreshIndex()).toBeFalse();
				var r = new cli.lucli.services.packages.Registry(httpClient = fake, cache = cache, registryRepo = "acme/pkgs");
				expect(r.listPackageNames()).toBe(["wheels-sentry"]);
				expect(r.fetchManifest("wheels-sentry").versions[1].version).toBe("1.0.0");
				expect(ArrayLen(fake.calls())).toBe(0);
				cache.refresh();
			});
		});
	}
}
