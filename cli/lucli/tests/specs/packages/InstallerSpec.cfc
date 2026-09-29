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

			// Stands in for an already-installed older copy of a package.
			var $seedInstalled = (proj, name) => {
				var dir = proj & "vendor/" & name;
				DirectoryCreate(dir, true);
				FileWrite(dir & "/package.json", "{""name"":""#name#"",""version"":""0.9.0""}");
				FileWrite(dir & "/old-only.txt", "old");
			};

			// Everything directly under vendor/, dot-entries included, so a
			// leftover staging dir fails the assertion.
			var $vendorEntries = (proj) => {
				var names = DirectoryList(proj & "vendor", false, "name");
				ArraySort(names, "textnocase");
				return ArrayToList(names);
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
				expect($vendorEntries(proj)).toBe("wheels-fake");
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
				expect(DirectoryExists(proj & "vendor") ? $vendorEntries(proj) : "").toBe("");
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

			it("force=true replaces the installed copy and leaves nothing behind in vendor/", () => {
				var proj = $scratch();
				$seedInstalled(proj, "wheels-fake");
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
				expect(installer.installedVersion("wheels-fake")).toBe("1.0.0");
				expect(FileExists(proj & "vendor/wheels-fake/README.md")).toBeTrue();
				expect(FileExists(proj & "vendor/wheels-fake/old-only.txt")).toBeFalse();
				expect($vendorEntries(proj)).toBe("wheels-fake");
				DirectoryDelete(proj, true);
			});

			it("force=true keeps the installed copy when the download fails", () => {
				var proj = $scratch();
				$seedInstalled(proj, "wheels-fake");
				// Unseeded URL: FakeHttpClient.download() throws DownloadFailed.
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var installer = new cli.lucli.services.packages.Installer(
					httpClient = fake,
					projectRoot = proj
				);
				var threw = false;
				try {
					installer.install("wheels-fake", {
						version: "1.0.0",
						tarball: "https://example/offline.tar.gz",
						sha256: $sha(fixturePath)
					}, true);
				} catch (any e) {
					threw = true;
					expect(e.type).toBe("Wheels.Packages.DownloadFailed");
				}
				expect(threw).toBeTrue();
				expect(installer.installedVersion("wheels-fake")).toBe("0.9.0");
				expect(FileExists(proj & "vendor/wheels-fake/old-only.txt")).toBeTrue();
				expect($vendorEntries(proj)).toBe("wheels-fake");
				DirectoryDelete(proj, true);
			});

			it("force=true keeps the installed copy on a checksum mismatch", () => {
				var proj = $scratch();
				$seedInstalled(proj, "wheels-fake");
				var tarballHref = "https://example/wheels-fake-1.0.0.tar.gz";
				var fake = $seededClient(tarballHref);
				var installer = new cli.lucli.services.packages.Installer(
					httpClient = fake,
					projectRoot = proj
				);
				var threw = false;
				try {
					installer.install("wheels-fake", {
						version: "1.0.0",
						tarball: tarballHref,
						sha256: "0000000000000000000000000000000000000000000000000000000000000000"
					}, true);
				} catch (any e) {
					threw = true;
					expect(e.type).toBe("Wheels.Packages.ChecksumMismatch");
				}
				expect(threw).toBeTrue();
				expect(installer.installedVersion("wheels-fake")).toBe("0.9.0");
				expect(FileExists(proj & "vendor/wheels-fake/old-only.txt")).toBeTrue();
				expect($vendorEntries(proj)).toBe("wheels-fake");
				// The downloaded temp tarball is cleaned up too.
				expect(FileExists(fake.calls()[1].destPath)).toBeFalse();
				DirectoryDelete(proj, true);
			});

			it("force=true keeps the installed copy when the tarball has no <name>/ dir", () => {
				// The fixture's top-level dir is wheels-fake/, so installing it
				// as 'other-pkg' extracts cleanly but never produces other-pkg/.
				var proj = $scratch();
				$seedInstalled(proj, "other-pkg");
				var tarballHref = "https://example/wheels-fake-1.0.0.tar.gz";
				var installer = new cli.lucli.services.packages.Installer(
					httpClient = $seededClient(tarballHref),
					projectRoot = proj
				);
				var threw = false;
				try {
					installer.install("other-pkg", {
						version: "1.0.0",
						tarball: tarballHref,
						sha256: $sha(fixturePath)
					}, true);
				} catch (any e) {
					threw = true;
					expect(e.type).toBe("Wheels.Packages.ExtractionFailed");
				}
				expect(threw).toBeTrue();
				expect(installer.installedVersion("other-pkg")).toBe("0.9.0");
				expect(FileExists(proj & "vendor/other-pkg/old-only.txt")).toBeTrue();
				// Nothing from the mismatched tarball lands in vendor/ either.
				expect($vendorEntries(proj)).toBe("other-pkg");
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
