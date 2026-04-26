component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("PackagesMainCli", () => {

			var fixturePath = ExpandPath("/cli/lucli/tests/_fixtures/packages/wheels-fake-1.0.0.tar.gz");

			var $scratch = () => {
				var root = GetTempDirectory() & "wheels-proj-" & CreateUUID() & "/";
				DirectoryCreate(root, true);
				return root;
			};

			var $sha = (path) => LCase(Hash(FileReadBinary(path), "SHA-256"));

			// Builds a Registry pre-seeded with two fake packages + a FakeHttpClient.
			var $buildStack = (projRoot) => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var cacheRoot = GetTempDirectory() & "wheels-cache-" & CreateUUID() & "/";
				var cache = new cli.lucli.services.packages.ManifestCache(root = cacheRoot);
				var registry = new cli.lucli.services.packages.Registry(
					httpClient = fake, cache = cache, registryRepo = "test/reg"
				);
				fake.seed(
					"https://api.github.com/repos/test/reg/contents/packages?ref=main",
					{status: 200, body: SerializeJSON([
						{name: "wheels-fake",  type: "dir"},
						{name: "wheels-other", type: "dir"}
					])}
				);
				fake.seed(
					"https://raw.githubusercontent.com/test/reg/main/packages/wheels-fake/manifest.json",
					{status: 200, body: SerializeJSON({
						name: "wheels-fake",
						description: "Fake package for tests",
						tags: ["monitoring", "test"],
						versions: [{
							version: "1.0.0", wheelsVersion: ">=4.0",
							tarball: "https://example/wheels-fake-1.0.0.tar.gz",
							sha256: $sha(fixturePath)
						}]
					})}
				);
				fake.seed(
					"https://raw.githubusercontent.com/test/reg/main/packages/wheels-other/manifest.json",
					{status: 200, body: SerializeJSON({
						name: "wheels-other",
						description: "Another one",
						tags: ["ui"],
						versions: [{
							version: "2.0.0", wheelsVersion: ">=4.0",
							tarball: "https://example/wheels-other-2.0.0.tar.gz",
							sha256: "deadbeef"
						}]
					})}
				);
				fake.seed(
					"https://example/wheels-fake-1.0.0.tar.gz",
					{status: 200, body: FileReadBinary(fixturePath)}
				);
				var installer = new cli.lucli.services.packages.Installer(
					httpClient = fake, projectRoot = projRoot
				);
				var cli = new cli.lucli.services.packages.PackagesMainCli(
					registry = registry, installer = installer, runtimeVersion = "4.0.0"
				);
				return {cli: cli, fake: fake, cache: cache};
			};

			it("list returns all packages when no filter", () => {
				var proj = $scratch();
				var stack = $buildStack(proj);
				var out = stack.cli.list();
				expect(out).toInclude("wheels-fake");
				expect(out).toInclude("wheels-other");
				stack.cache.refresh();
				DirectoryDelete(proj, true);
			});

			it("list --tag filters to matching tag", () => {
				var proj = $scratch();
				var stack = $buildStack(proj);
				var out = stack.cli.list({tag: "ui"});
				expect(out).toInclude("wheels-other");
				expect(out).notToInclude("wheels-fake");
				stack.cache.refresh();
				DirectoryDelete(proj, true);
			});

			it("search matches against name, description, and tags", () => {
				var proj = $scratch();
				var stack = $buildStack(proj);
				expect(stack.cli.search({query: "monitoring"})).toInclude("wheels-fake");
				expect(stack.cli.search({query: "another"})).toInclude("wheels-other");
				expect(stack.cli.search({query: "zzzz-no-match"})).toInclude("No packages matched");
				stack.cache.refresh();
				DirectoryDelete(proj, true);
			});

			it("show renders package details and compatible versions", () => {
				var proj = $scratch();
				var stack = $buildStack(proj);
				var out = stack.cli.show({name: "wheels-fake"});
				expect(out).toInclude("wheels-fake");
				expect(out).toInclude("Fake package for tests");
				expect(out).toInclude("1.0.0");
				stack.cache.refresh();
				DirectoryDelete(proj, true);
			});

			it("install fetches manifest, picks latest compat, and extracts to vendor/", () => {
				var proj = $scratch();
				var stack = $buildStack(proj);
				var out = stack.cli.install({target: "wheels-fake"});
				expect(out).toInclude("Installed wheels-fake@1.0.0");
				expect(DirectoryExists(proj & "vendor/wheels-fake")).toBeTrue();
				expect(FileExists(proj & "vendor/wheels-fake/package.json")).toBeTrue();
				stack.cache.refresh();
				DirectoryDelete(proj, true);
			});

			it("install honours @version pin", () => {
				var proj = $scratch();
				var stack = $buildStack(proj);
				var out = stack.cli.install({target: "wheels-fake@1.0.0"});
				expect(out).toInclude("1.0.0");
				stack.cache.refresh();
				DirectoryDelete(proj, true);
			});

			it("update <name> without --yes throws ConfirmationRequired", () => {
				var proj = $scratch();
				var stack = $buildStack(proj);
				DirectoryCreate(proj & "vendor/wheels-fake", true);
				FileWrite(proj & "vendor/wheels-fake/package.json", "{""name"":""wheels-fake"",""version"":""1.0.0""}");
				var threw = false;
				try {
					stack.cli.update({target: "wheels-fake"});
				} catch (any e) {
					threw = true;
					expect(e.type).toBe("Wheels.Packages.ConfirmationRequired");
				}
				expect(threw).toBeTrue();
				stack.cache.refresh();
				DirectoryDelete(proj, true);
			});

			it("update --all without --yes throws ConfirmationRequired", () => {
				var proj = $scratch();
				var stack = $buildStack(proj);
				var threw = false;
				try {
					stack.cli.update({all: true});
				} catch (any e) {
					threw = true;
					expect(e.type).toBe("Wheels.Packages.ConfirmationRequired");
				}
				expect(threw).toBeTrue();
				stack.cache.refresh();
				DirectoryDelete(proj, true);
			});

			it("remove refuses a dir without package.json", () => {
				var proj = $scratch();
				var stack = $buildStack(proj);
				DirectoryCreate(proj & "vendor/scary", true);
				var threw = false;
				try {
					stack.cli.remove({target: "scary"});
				} catch (any e) {
					threw = true;
					expect(e.type).toBe("Wheels.Packages.NotAPackage");
				}
				expect(threw).toBeTrue();
				stack.cache.refresh();
				DirectoryDelete(proj, true);
			});

			it("install throws BadInput when target is missing", () => {
				var proj = $scratch();
				var stack = $buildStack(proj);
				var threw = false;
				try {
					stack.cli.install({});
				} catch (any e) {
					threw = true;
					expect(e.type).toBe("Wheels.Packages.BadInput");
				}
				expect(threw).toBeTrue();
				stack.cache.refresh();
				DirectoryDelete(proj, true);
			});

			it("install throws BadInput when target starts with '@' (empty name)", () => {
				// Regression guard: `@1.0.0` used to hit Left(str, 0), which
				// crashes on Lucee 7 and produces a cryptic error on other
				// engines. Must reject cleanly with BadInput.
				var proj = $scratch();
				var stack = $buildStack(proj);
				var threw = false;
				try {
					stack.cli.install({target: "@1.0.0"});
				} catch (any e) {
					threw = true;
					expect(e.type).toBe("Wheels.Packages.BadInput");
				}
				expect(threw).toBeTrue();
				stack.cache.refresh();
				DirectoryDelete(proj, true);
			});
		});

		describe("PackagesRegistryCli", () => {

			it("info prints registry details", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var cacheRoot = GetTempDirectory() & "wheels-cache-" & CreateUUID() & "/";
				var cache = new cli.lucli.services.packages.ManifestCache(root = cacheRoot);
				var registry = new cli.lucli.services.packages.Registry(
					httpClient = fake, cache = cache, registryRepo = "acme/pkgs"
				);
				var cli = new cli.lucli.services.packages.PackagesRegistryCli(registry = registry);
				var out = cli.info();
				expect(out).toInclude("acme/pkgs");
				expect(out).toInclude("main");
			});

			it("refresh wipes the cache", () => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var cacheRoot = GetTempDirectory() & "wheels-cache-" & CreateUUID() & "/";
				var cache = new cli.lucli.services.packages.ManifestCache(root = cacheRoot);
				cache.writeIndex(["a", "b"]);
				expect(DirectoryExists(cacheRoot)).toBeTrue();
				var registry = new cli.lucli.services.packages.Registry(
					httpClient = fake, cache = cache, registryRepo = "acme/pkgs"
				);
				var cli = new cli.lucli.services.packages.PackagesRegistryCli(registry = registry);
				cli.refresh();
				expect(DirectoryExists(cacheRoot)).toBeFalse();
			});
		});
	}
}
