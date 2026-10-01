/**
 * An extracted package must be exactly one directory named after the package,
 * holding a package.json, with no links. Install extracts into a staging
 * directory, checks this layout, and only then moves the tree into vendor/.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("Package layout", () => {

			var $stage = () => {
				var dir = GetTempDirectory() & "wheels-stage-" & CreateUUID() & "/";
				DirectoryCreate(dir, true);
				return dir;
			};

			var $package = (stage, name) => {
				DirectoryCreate(stage & name & "/lib", true);
				FileWrite(stage & name & "/package.json", '{"name":"#name#","version":"1.0.0"}');
				FileWrite(stage & name & "/lib/Helper.cfc", "component {}");
			};

			var $layoutError = (stage, name) => {
				try {
					new cli.lucli.services.packages.PackageLayout().assertSingleTree(stage, name);
				} catch (any e) {
					return e.type;
				}
				return "";
			};

			it("accepts a single <name>/ directory with a package.json", () => {
				var stage = $stage();
				$package(stage, "wheels-sentry");
				expect($layoutError(stage, "wheels-sentry")).toBe("");
				DirectoryDelete(stage, true);
			});

			it("rejects an extra top-level folder next to the package", () => {
				var stage = $stage();
				$package(stage, "wheels-sentry");
				DirectoryCreate(stage & "other", true);
				expect($layoutError(stage, "wheels-sentry")).toBe("Wheels.Packages.ExtractionFailed");
				DirectoryDelete(stage, true);
			});

			it("rejects a second package next to the named one", () => {
				var stage = $stage();
				$package(stage, "wheels-sentry");
				$package(stage, "wheels-extra");
				expect($layoutError(stage, "wheels-sentry")).toBe("Wheels.Packages.ExtractionFailed");
				DirectoryDelete(stage, true);
			});

			it("rejects a loose top-level file", () => {
				var stage = $stage();
				$package(stage, "wheels-sentry");
				FileWrite(stage & "README.md", "hello");
				expect($layoutError(stage, "wheels-sentry")).toBe("Wheels.Packages.ExtractionFailed");
				DirectoryDelete(stage, true);
			});

			it("rejects a tree whose directory is named differently", () => {
				var stage = $stage();
				$package(stage, "wheels-other");
				expect($layoutError(stage, "wheels-sentry")).toBe("Wheels.Packages.ExtractionFailed");
				DirectoryDelete(stage, true);
			});

			it("rejects a tree without a package.json", () => {
				var stage = $stage();
				DirectoryCreate(stage & "wheels-sentry", true);
				expect($layoutError(stage, "wheels-sentry")).toBe("Wheels.Packages.ExtractionFailed");
				DirectoryDelete(stage, true);
			});

			it("rejects a tree that contains a symbolic link", () => {
				var stage = $stage();
				$package(stage, "wheels-sentry");
				var files = createObject("java", "java.nio.file.Files");
				var paths = createObject("java", "java.nio.file.Paths");
				files.createSymbolicLink(
					paths.get(stage & "wheels-sentry/lib/Alias.cfc", []),
					paths.get("Helper.cfc", []),
					[]
				);
				expect($layoutError(stage, "wheels-sentry")).toBe("Wheels.Packages.ExtractionFailed");
				DirectoryDelete(stage, true);
			});

			it("a failed --force reinstall keeps the installed package", () => {
				var proj = GetTempDirectory() & "wheels-proj-" & CreateUUID() & "/";
				DirectoryCreate(proj & "vendor/wheels-sentry", true);
				FileWrite(proj & "vendor/wheels-sentry/package.json", '{"name":"wheels-sentry","version":"1.0.0"}');
				// Nothing is seeded, so the download fails.
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				var installer = new cli.lucli.services.packages.Installer(httpClient = fake, projectRoot = proj);
				try {
					installer.install("wheels-sentry", {version: "1.1.0", tarball: "https://example/missing.tgz", sha256: "00"}, true);
				} catch (any e) {
				}
				var kept = FileExists(proj & "vendor/wheels-sentry/package.json");
				DirectoryDelete(proj, true);
				expect(kept).toBeTrue();
			});

			it("install leaves vendor/ untouched when the tarball's layout does not match the name", () => {
				// The committed fixture unpacks to wheels-fake/. Installing it
				// under another name must fail without writing into vendor/.
				var fixturePath = ExpandPath("/cli/lucli/tests/_fixtures/packages/wheels-fake-1.0.0.tar.gz");
				var proj = GetTempDirectory() & "wheels-proj-" & CreateUUID() & "/";
				DirectoryCreate(proj & "vendor", true);
				var href = "https://example/wheels-fake-1.0.0.tar.gz";
				var fake = new cli.lucli.tests.specs.packages._stubs.FakeHttpClient();
				fake.seed(href, {status: 200, body: FileReadBinary(fixturePath)});
				var installer = new cli.lucli.services.packages.Installer(httpClient = fake, projectRoot = proj);
				var threwType = "";
				try {
					installer.install("wheels-renamed", {
						version: "1.0.0",
						tarball: href,
						sha256: LCase(Hash(FileReadBinary(fixturePath), "SHA-256"))
					});
				} catch (any e) {
					threwType = e.type;
				}
				var leftovers = DirectoryList(proj & "vendor", false, "name");
				DirectoryDelete(proj, true);
				expect(threwType).toBe("Wheels.Packages.ExtractionFailed");
				expect(ArrayLen(leftovers)).toBe(0);
			});
		});
	}
}
