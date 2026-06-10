/**
 * Regression coverage for wheels-legacy-adapter registry resolution.
 *
 * `wheels upgrade check` points users with breaking 3.x findings at
 * `wheels packages add wheels-legacy-adapter` as the soft-landing path
 * (it shims renderPage()/renderPageToString() while they migrate). Nothing
 * previously pinned that the packages Registry + VersionResolver actually
 * resolve that package name end-to-end — manifest URL construction against
 * the default wheels-dev/wheels-packages repo, manifest parsing, and a
 * 4.x-compatible version pick — so the recommendation could silently rot.
 *
 * Uses FakeHttpClient (no network), mirroring RegistrySpec.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("wheels-legacy-adapter registry resolution", () => {

			var $freshCache = () => {
				var root = GetTempDirectory() & "wheels-registry-" & CreateUUID() & "/";
				return new cli.lucli.services.packages.ManifestCache(root = root);
			};

			var $adapterManifest = SerializeJSON({
				name: "wheels-legacy-adapter",
				description: "3.x -> 4.x compatibility shims",
				source: {type: "github", repo: "wheels-dev/wheels-legacy-adapter"},
				versions: [
					{version: "1.0.0", wheelsVersion: ">=4.0", tarball: "x", sha256: "a"},
					{version: "1.1.0", wheelsVersion: ">=4.0", tarball: "x", sha256: "b"}
				]
			});

			it("fetches and parses the adapter manifest from the canonical registry repo", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var cache = $freshCache();
				var r = new cli.lucli.services.packages.Registry(
					httpClient = fake, cache = cache, registryRepo = "wheels-dev/wheels-packages"
				);
				fake.seed(
					"https://raw.githubusercontent.com/wheels-dev/wheels-packages/main/packages/wheels-legacy-adapter/manifest.json",
					{status: 200, body: $adapterManifest}
				);
				var m = r.fetchManifest("wheels-legacy-adapter");
				expect(m.name).toBe("wheels-legacy-adapter");
				expect(ArrayLen(m.versions)).toBe(2);
				cache.refresh();
			});

			it("appears in the registry index listing (hyphenated name survives)", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var cache = $freshCache();
				var r = new cli.lucli.services.packages.Registry(
					httpClient = fake, cache = cache, registryRepo = "wheels-dev/wheels-packages"
				);
				fake.seed(
					"https://api.github.com/repos/wheels-dev/wheels-packages/contents/packages?ref=main",
					{status: 200, body: SerializeJSON([
						{name: "wheels-legacy-adapter", type: "dir"},
						{name: "wheels-sentry", type: "dir"}
					])}
				);
				expect(r.listPackageNames()).toInclude("wheels-legacy-adapter");
				cache.refresh();
			});

			it("VersionResolver picks the highest 4.x-compatible adapter version", () => {
				var manifest = DeserializeJSON($adapterManifest);
				var picked = new cli.lucli.services.packages.VersionResolver().pick(
					manifest, "4.0.2"
				);
				expect(picked.version).toBe("1.1.0");
			});

		});
	}

}
