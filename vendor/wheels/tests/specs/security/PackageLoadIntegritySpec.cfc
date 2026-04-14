component extends="wheels.WheelsTest" {

	function run() {

		describe("Package and plugin load integrity logging", () => {

			beforeEach(() => {
				fixturesPath = ExpandPath("/wheels/tests/_assets/packages");
				componentPrefix = "wheels.tests._assets.packages";
			});

			describe("Package security logging", () => {

				it("loads packages without checksums normally (backward compatible)", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var pkgs = loader.getPackages();
					// checksumpkg has no checksums field and should load fine
					expect(pkgs).toHaveKey("checksumpkg");
				});

				it("skips packages with mismatched checksums", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var pkgs = loader.getPackages();
					var failed = loader.getFailedPackages();

					// badchecksumpkg has a deliberately wrong checksum
					expect(pkgs).notToHaveKey("badchecksumpkg");

					// verify it was recorded as failed
					var foundBadChecksum = false;
					for (var f in failed) {
						if (f.name == "badchecksumpkg" && FindNoCase("checksum", f.error)) {
							foundBadChecksum = true;
						}
					}
					expect(foundBadChecksum).toBeTrue();
				});

				it("records checksum failure detail in failedPackages", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var failed = loader.getFailedPackages();

					var foundEntry = false;
					for (var f in failed) {
						if (f.name == "badchecksumpkg") {
							foundEntry = true;
							expect(f.error).toBe("Checksum verification failed");
							expect(f.detail).toInclude("checksums");
						}
					}
					expect(foundEntry).toBeTrue();
				});

			});

			describe("Checksum verification", () => {

				it("accepts packages with valid checksums", () => {
					// compute the actual hash of the checksumpkg CFC so we can
					// write a matching manifest, then verify it loads
					var cfcPath = fixturesPath & "/checksumpkg/Checksumpkg.cfc";
					var actualHash = Hash(FileRead(cfcPath), "SHA-256");

					// create a temporary manifest with correct checksums
					var manifestPath = fixturesPath & "/checksumpkg/package.json";
					var originalManifest = FileRead(manifestPath);

					try {
						var manifest = DeserializeJSON(originalManifest);
						manifest["checksums"] = {"Checksumpkg.cfc" = actualHash};
						FileWrite(manifestPath, SerializeJSON(manifest));

						var loader = new wheels.PackageLoader(
							vendorPath = fixturesPath,
							componentPrefix = componentPrefix
						);
						var pkgs = loader.getPackages();
						expect(pkgs).toHaveKey("checksumpkg");

						// should not appear in failed packages
						var failed = loader.getFailedPackages();
						var foundChecksumFail = false;
						for (var f in failed) {
							if (f.name == "checksumpkg") foundChecksumFail = true;
						}
						expect(foundChecksumFail).toBeFalse();
					} finally {
						// restore original manifest
						FileWrite(manifestPath, originalManifest);
					}
				});

			});

		});

	}

}
