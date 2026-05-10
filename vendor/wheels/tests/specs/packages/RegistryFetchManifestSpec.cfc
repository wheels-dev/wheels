component extends="wheels.WheelsTest" {

	function run() {
		describe("Registry.fetchManifest validation", () => {
			var $freshCache = () => {
				var root = GetTempDirectory() & "wheels-registry-" & CreateUUID() & "/";
				return new wheels.services.packages.ManifestCache(root = root);
			};

			var $newRegistry = (fake, cache) => {
				return new wheels.services.packages.Registry(
					httpClient = arguments.fake,
					cache = arguments.cache,
					registryRepo = "acme/pkgs"
				);
			};

			var $manifestUrl = "https://raw.githubusercontent.com/acme/pkgs/main/packages/wheels-x/manifest.json";

			// Regression: listAll() reads .versions[ArrayLen(.versions)]. If
			// fetchManifest accepts a manifest without a versions array, the
			// per-package skip-on-malformed catch in listAll() is bypassed
			// and an Expression-level error escapes to $loadRegistryPackages,
			// crashing the Tools → Packages page. Verify the fetchManifest
			// guard fires for every shape that would break the array access.
			it("rejects a manifest with no versions key", () => {
				var fake = new wheels.tests._assets.packages.FakeHttpClient();
				var cache = $freshCache();
				var r = $newRegistry(fake, cache);
				fake.seed($manifestUrl, {status = 200, body = SerializeJSON({name = "wheels-x"})});
				var threw = "";
				try {
					r.fetchManifest("wheels-x");
				} catch ("Wheels.Packages.RegistryMalformed" e) {
					threw = e.message;
				}
				expect(threw contains "versions").toBeTrue(
					"Expected a RegistryMalformed throw mentioning the missing versions key, got: " & threw
				);
				cache.refresh();
			});

			it("rejects a manifest where versions is not an array", () => {
				var fake = new wheels.tests._assets.packages.FakeHttpClient();
				var cache = $freshCache();
				var r = $newRegistry(fake, cache);
				fake.seed($manifestUrl, {status = 200, body = SerializeJSON({name = "wheels-x", versions = "1.0.0"})});
				var threw = "";
				try {
					r.fetchManifest("wheels-x");
				} catch ("Wheels.Packages.RegistryMalformed" e) {
					threw = e.message;
				}
				expect(threw contains "versions").toBeTrue();
				cache.refresh();
			});

			it("rejects a manifest with an empty versions array", () => {
				var fake = new wheels.tests._assets.packages.FakeHttpClient();
				var cache = $freshCache();
				var r = $newRegistry(fake, cache);
				fake.seed($manifestUrl, {status = 200, body = SerializeJSON({name = "wheels-x", versions = []})});
				var threw = "";
				try {
					r.fetchManifest("wheels-x");
				} catch ("Wheels.Packages.RegistryMalformed" e) {
					threw = e.message;
				}
				expect(threw contains "versions").toBeTrue();
				cache.refresh();
			});

			it("listAll() skips a malformed manifest instead of crashing", () => {
				// End-to-end: a malformed manifest in the registry list must
				// not propagate an Expression error to the Tools → Packages
				// page. listAll() must continue past the bad entry and
				// return the well-formed ones.
				var fake = new wheels.tests._assets.packages.FakeHttpClient();
				var cache = $freshCache();
				var r = $newRegistry(fake, cache);
				fake.seed(
					"https://api.github.com/repos/acme/pkgs/contents/packages?ref=main",
					{
						status = 200,
						body = SerializeJSON([{name = "wheels-good", type = "dir"}, {name = "wheels-bad", type = "dir"}])
					}
				);
				fake.seed(
					"https://raw.githubusercontent.com/acme/pkgs/main/packages/wheels-good/manifest.json",
					{
						status = 200,
						body = SerializeJSON({name = "wheels-good", description = "ok", versions = [{version = "1.0.0"}]})
					}
				);
				fake.seed(
					"https://raw.githubusercontent.com/acme/pkgs/main/packages/wheels-bad/manifest.json",
					{status = 200, body = SerializeJSON({name = "wheels-bad"})} // no versions
				);
				var pkgs = r.listAll();
				expect(ArrayLen(pkgs)).toBe(1);
				expect(pkgs[1].name).toBe("wheels-good");
				cache.refresh();
			});
		});
	}

}
