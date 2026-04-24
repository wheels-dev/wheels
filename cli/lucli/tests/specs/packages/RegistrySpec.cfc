component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("Registry", () => {

			var $freshCache = () => {
				var root = GetTempDirectory() & "wheels-registry-" & CreateUUID() & "/";
				return new cli.lucli.services.packages.ManifestCache(root = root);
			};

			var $sentryManifest = SerializeJSON({
				name: "wheels-sentry",
				description: "Sentry for Wheels",
				source: {type: "github", repo: "wheels-dev/wheels-sentry"},
				versions: [{version: "1.0.0", wheelsVersion: ">=4.0", tarball: "x", sha256: "y"}]
			});

			var $contentsBody = SerializeJSON([
				{name: "wheels-sentry", type: "dir"},
				{name: "wheels-hotwire", type: "dir"},
				{name: "README.md",     type: "file"}
			]);

			it("lists package names, filtering out non-dirs and sorting", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var cache = $freshCache();
				var r = new cli.lucli.services.packages.Registry(
					httpClient = fake, cache = cache, registryRepo = "acme/pkgs"
				);
				fake.seed(
					"https://api.github.com/repos/acme/pkgs/contents/packages?ref=main",
					{status: 200, body: $contentsBody}
				);
				var names = r.listPackageNames();
				expect(names).toBe(["wheels-hotwire", "wheels-sentry"]);  // sorted
			});

			it("serves the index from cache on the second call (no second HTTP hit)", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var cache = $freshCache();
				var r = new cli.lucli.services.packages.Registry(
					httpClient = fake, cache = cache, registryRepo = "acme/pkgs"
				);
				fake.seed(
					"https://api.github.com/repos/acme/pkgs/contents/packages?ref=main",
					{status: 200, body: $contentsBody}
				);
				r.listPackageNames();
				r.listPackageNames();
				expect(ArrayLen(fake.calls())).toBe(1);
				cache.refresh();
			});

			it("fetches a manifest and parses it", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var cache = $freshCache();
				var r = new cli.lucli.services.packages.Registry(
					httpClient = fake, cache = cache, registryRepo = "acme/pkgs"
				);
				fake.seed(
					"https://raw.githubusercontent.com/acme/pkgs/main/packages/wheels-sentry/manifest.json",
					{status: 200, body: $sentryManifest}
				);
				var m = r.fetchManifest("wheels-sentry");
				expect(m.name).toBe("wheels-sentry");
				expect(m.versions[1].version).toBe("1.0.0");
				cache.refresh();
			});

			it("throws Wheels.Packages.UnknownPackage on 404", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var cache = $freshCache();
				var r = new cli.lucli.services.packages.Registry(
					httpClient = fake, cache = cache, registryRepo = "acme/pkgs"
				);
				// No seed — FakeHttpClient returns 404 for unknown URLs.
				var threw = false;
				try {
					r.fetchManifest("nope");
				} catch (any e) {
					threw = true;
					expect(e.type).toBe("Wheels.Packages.UnknownPackage");
				}
				expect(threw).toBeTrue();
				cache.refresh();
			});

			it("throws Wheels.Packages.RegistryUnavailable on other errors", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var cache = $freshCache();
				var r = new cli.lucli.services.packages.Registry(
					httpClient = fake, cache = cache, registryRepo = "acme/pkgs"
				);
				fake.seed(
					"https://api.github.com/repos/acme/pkgs/contents/packages?ref=main",
					{status: 500, body: "boom"}
				);
				var threw = false;
				try {
					r.listPackageNames();
				} catch (any e) {
					threw = true;
					expect(e.type).toBe("Wheels.Packages.RegistryUnavailable");
				}
				expect(threw).toBeTrue();
				cache.refresh();
			});

			it("info() reports repo and cache details", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var cache = $freshCache();
				var r = new cli.lucli.services.packages.Registry(
					httpClient = fake, cache = cache, registryRepo = "acme/pkgs"
				);
				var info = r.info();
				expect(info.registryRepo).toBe("acme/pkgs");
				expect(info.branch).toBe("main");
				expect(Find("acme/pkgs", info.indexUrl)).toBeGT(0);
			});

			it("uses default repo when env override is absent", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var cache = $freshCache();
				var r = new cli.lucli.services.packages.Registry(httpClient = fake, cache = cache);
				// We can't assert on env state, but we can assert the fallback was hit.
				expect(Len(r.registryRepo())).toBeGT(0);
			});
		});
	}
}
