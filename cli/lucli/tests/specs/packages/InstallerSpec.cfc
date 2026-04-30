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
				var installer = new cli.lucli.services.packages.Installer(
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

			it("stamps extracted files with current mtime (Lucee 7 rejects mtime=0)", () => {
				// Production tarballs are built with `tar --mtime=@0` for
				// deterministic sha256. Lucee 7's class-resolver cannot compile
				// CFCs whose mtime is epoch-0 — it silently aborts with the
				// generic "invalid component definition, can't find component
				// [...]" error. The fixture's mtime is many days old (Apr 23
				// 2026), but with the `-m` flag on extract, every file lands
				// with current mtime. Assert that here so a regression that
				// drops `-m` (or swaps it for `--touch=once`) trips loudly.
				var proj = $scratch();
				var tarballHref = "https://example/wheels-fake-1.0.0.tar.gz";
				var installer = new cli.lucli.services.packages.Installer(
					httpClient = $seededClient(tarballHref),
					projectRoot = proj
				);
				var path = installer.install("wheels-fake", {
					version: "1.0.0",
					tarball: tarballHref,
					sha256: $sha(fixturePath)
				});
				var pkgInfo = GetFileInfo(path & "/package.json");
				var nowMs = Now().getTime();
				var pkgMs = pkgInfo.lastModified.getTime();
				// The fixture's stored mtime is well over a day ago. If `-m`
				// is dropped, lastModified will be the fixture's old time and
				// (now - lastModified) will be tens of thousands of seconds.
				// 60s window is generous for a single test run.
				expect(nowMs - pkgMs).toBeLT(60000);
				DirectoryDelete(proj, true);
			});

			it("aborts with ChecksumMismatch on bad sha256", () => {
				var proj = $scratch();
				var tarballHref = "https://example/wheels-fake-1.0.0.tar.gz";
				var installer = new cli.lucli.services.packages.Installer(
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
				var installer = new cli.lucli.services.packages.Installer(
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
				var installer = new cli.lucli.services.packages.Installer(
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
				var installer = new cli.lucli.services.packages.Installer(
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
				var installer = new cli.lucli.services.packages.Installer(
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
				var installer = new cli.lucli.services.packages.Installer(
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
