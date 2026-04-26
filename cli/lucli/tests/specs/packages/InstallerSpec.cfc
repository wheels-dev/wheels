component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("Installer", () => {

			// Fixture tarball, built once and committed to tests/_fixtures/packages.
			// Its sha256 is computed live below (BSD vs GNU tar produce different
			// bytes but both are valid for our purposes — we just need a known-
			// good hash to verify the checksum path works).
			var fixturePath = ExpandPath("/cli/lucli/tests/_fixtures/packages/wheels-fake-1.0.0.tar.gz");

			var $scratch = () => {
				var root = GetTempDirectory() & "wheels-proj-" & CreateUUID() & "/";
				DirectoryCreate(root, true);
				return root;
			};

			var $sha = (path) => {
				return LCase(Hash(FileReadBinary(path), "SHA-256"));
			};

			// Seeds a FakeHttpClient to serve the fixture tarball bytes at
			// the URL the Installer will request. Named `href` here because
			// `url` is a CFML reserved scope and shadows inside closures.
			var $seededClient = (href) => {
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				fake.seed(href, {status: 200, body: FileReadBinary(fixturePath)});
				return fake;
			};

			it("fails loudly if the fixture tarball is missing", () => {
				expect(FileExists(fixturePath)).toBeTrue();
			});

			it("downloads, verifies checksum, extracts to vendor/<name>/", () => {
				var proj = $scratch();
				var tarballHref = "https://example/wheels-fake-1.0.0.tar.gz";
				var installer = new modules.wheels.services.packages.Installer(
					httpClient = $seededClient(tarballHref),
					projectRoot = proj
				);
				var path = installer.install("wheels-fake", {
					version: "1.0.0",
					tarball: tarballHref,
					sha256: $sha(fixturePath)
				});
				expect(DirectoryExists(path)).toBeTrue();
				expect(FileExists(path & "/package.json")).toBeTrue();
				expect(installer.isInstalled("wheels-fake")).toBeTrue();
				expect(installer.installedVersion("wheels-fake")).toBe("1.0.0");
				DirectoryDelete(proj, true);
			});

			it("aborts with ChecksumMismatch on bad sha256", () => {
				var proj = $scratch();
				var tarballHref = "https://example/wheels-fake-1.0.0.tar.gz";
				var installer = new modules.wheels.services.packages.Installer(
					httpClient = $seededClient(tarballHref),
					projectRoot = proj
				);
				var threw = false;
				try {
					installer.install("wheels-fake", {
						version: "1.0.0",
						tarball: tarballHref,
						sha256: "0000000000000000000000000000000000000000000000000000000000000000"
					});
				} catch (any e) {
					threw = true;
					expect(e.type).toBe("Wheels.Packages.ChecksumMismatch");
				}
				expect(threw).toBeTrue();
				expect(DirectoryExists(proj & "vendor/wheels-fake")).toBeFalse();
				DirectoryDelete(proj, true);
			});

			it("refuses to overwrite an existing package without --force", () => {
				var proj = $scratch();
				DirectoryCreate(proj & "vendor/wheels-fake", true);
				var tarballHref = "https://example/wheels-fake-1.0.0.tar.gz";
				var installer = new modules.wheels.services.packages.Installer(
					httpClient = $seededClient(tarballHref),
					projectRoot = proj
				);
				var threw = false;
				try {
					installer.install("wheels-fake", {
						version: "1.0.0",
						tarball: tarballHref,
						sha256: $sha(fixturePath)
					});
				} catch (any e) {
					threw = true;
					expect(e.type).toBe("Wheels.Packages.AlreadyInstalled");
				}
				expect(threw).toBeTrue();
				DirectoryDelete(proj, true);
			});

			it("overwrites when force=true", () => {
				var proj = $scratch();
				DirectoryCreate(proj & "vendor/wheels-fake", true);
				FileWrite(proj & "vendor/wheels-fake/leftover.txt", "old");
				var tarballHref = "https://example/wheels-fake-1.0.0.tar.gz";
				var installer = new modules.wheels.services.packages.Installer(
					httpClient = $seededClient(tarballHref),
					projectRoot = proj
				);
				installer.install("wheels-fake", {
					version: "1.0.0",
					tarball: tarballHref,
					sha256: $sha(fixturePath)
				}, true);
				expect(FileExists(proj & "vendor/wheels-fake/package.json")).toBeTrue();
				expect(FileExists(proj & "vendor/wheels-fake/leftover.txt")).toBeFalse();
				DirectoryDelete(proj, true);
			});

			it("refuses to install a version missing tarball URL", () => {
				var installer = new modules.wheels.services.packages.Installer(
					httpClient = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient(),
					projectRoot = $scratch()
				);
				var threw = false;
				try {
					installer.install("x", {version: "1.0.0", sha256: "abc"});
				} catch (any e) {
					threw = true;
					expect(e.type).toBe("Wheels.Packages.ManifestIncomplete");
				}
				expect(threw).toBeTrue();
			});

			it("uninstall refuses dirs without a package.json", () => {
				var proj = $scratch();
				DirectoryCreate(proj & "vendor/scary", true);
				FileWrite(proj & "vendor/scary/not-a-package.txt", "x");
				var installer = new modules.wheels.services.packages.Installer(
					httpClient = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient(),
					projectRoot = proj
				);
				var threw = false;
				try {
					installer.uninstall("scary");
				} catch (any e) {
					threw = true;
					expect(e.type).toBe("Wheels.Packages.NotAPackage");
				}
				expect(threw).toBeTrue();
				expect(DirectoryExists(proj & "vendor/scary")).toBeTrue();
				DirectoryDelete(proj, true);
			});

			it("uninstall removes a real package", () => {
				var proj = $scratch();
				DirectoryCreate(proj & "vendor/wheels-fake", true);
				FileWrite(proj & "vendor/wheels-fake/package.json", "{""name"":""wheels-fake""}");
				var installer = new modules.wheels.services.packages.Installer(
					httpClient = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient(),
					projectRoot = proj
				);
				installer.uninstall("wheels-fake");
				expect(DirectoryExists(proj & "vendor/wheels-fake")).toBeFalse();
				DirectoryDelete(proj, true);
			});
		});
	}
}
