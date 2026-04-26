component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("Registry.listAll", () => {

			var $freshCache = () => {
				var root = GetTempDirectory() & "wheels-registry-" & CreateUUID() & "/";
				return new modules.wheels.services.packages.ManifestCache(root = root);
			};

			var $manifest = (name, versions = [{version: "1.0.0", wheelsVersion: ">=4.0", tarball: "x", sha256: "y"}]) => {
				return SerializeJSON({
					name: name,
					description: name & " description",
					homepage: "https://github.com/wheels-dev/" & name,
					tags: ["utility"],
					source: {type: "github", repo: "wheels-dev/" & name},
					versions: versions
				});
			};

			var $contentsBody = SerializeJSON([
				{name: "wheels-sentry",  type: "dir"},
				{name: "wheels-hotwire", type: "dir"},
				{name: "README.md",      type: "file"}
			]);

			it("returns enriched summaries for every package in the registry", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var r = new modules.wheels.services.packages.Registry(
					httpClient = fake, cache = $freshCache(), registryRepo = "acme/pkgs"
				);
				fake.seed(
					"https://api.github.com/repos/acme/pkgs/contents/packages?ref=main",
					{status: 200, body: $contentsBody}
				);
				fake.seed(
					"https://raw.githubusercontent.com/acme/pkgs/main/packages/wheels-sentry/manifest.json",
					{status: 200, body: $manifest("wheels-sentry")}
				);
				fake.seed(
					"https://raw.githubusercontent.com/acme/pkgs/main/packages/wheels-hotwire/manifest.json",
					{status: 200, body: $manifest("wheels-hotwire", [
						{version: "1.0.0", wheelsVersion: ">=4.0", tarball: "x", sha256: "y"},
						{version: "1.1.0", wheelsVersion: ">=4.0", tarball: "x", sha256: "y"}
					])}
				);

				var result = r.listAll();

				expect(ArrayLen(result)).toBe(2);
				expect(result[1].name).toBe("wheels-hotwire");     // sorted
				expect(result[1].latestVersion).toBe("1.1.0");     // last version entry wins
				expect(result[1].homepage).toBe("https://github.com/wheels-dev/wheels-hotwire");
				expect(result[1].tags).toBe(["utility"]);
				expect(result[2].name).toBe("wheels-sentry");
				expect(result[2].latestVersion).toBe("1.0.0");
			});

			it("skips a package whose manifest is malformed and continues", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var r = new modules.wheels.services.packages.Registry(
					httpClient = fake, cache = $freshCache(), registryRepo = "acme/pkgs"
				);
				fake.seed(
					"https://api.github.com/repos/acme/pkgs/contents/packages?ref=main",
					{status: 200, body: $contentsBody}
				);
				fake.seed(
					"https://raw.githubusercontent.com/acme/pkgs/main/packages/wheels-sentry/manifest.json",
					{status: 200, body: "{""description"": ""no name key""}"}  // malformed — missing required 'name'
				);
				fake.seed(
					"https://raw.githubusercontent.com/acme/pkgs/main/packages/wheels-hotwire/manifest.json",
					{status: 200, body: $manifest("wheels-hotwire")}
				);

				var result = r.listAll();
				expect(ArrayLen(result)).toBe(1);
				expect(result[1].name).toBe("wheels-hotwire");
			});

			it("propagates Wheels.Packages.RegistryUnavailable from listPackageNames", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var r = new modules.wheels.services.packages.Registry(
					httpClient = fake, cache = $freshCache(), registryRepo = "acme/pkgs"
				);
				fake.seed(
					"https://api.github.com/repos/acme/pkgs/contents/packages?ref=main",
					{status: 503, body: "service unavailable"}
				);

				var thrown = "";
				try {
					r.listAll();
				} catch (Wheels.Packages.RegistryUnavailable e) {
					thrown = e.type;
				}
				expect(thrown).toBe("Wheels.Packages.RegistryUnavailable");
			});

		});
	}
}
