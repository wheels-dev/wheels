component extends="wheels.WheelsTest" {

	function run() {

		describe("PackageLoader", () => {

			beforeEach(() => {
				fixturesPath = ExpandPath("/wheels/tests/_assets/packages");
				componentPrefix = "wheels.tests._assets.packages";
			});

			describe("Discovery", () => {

				it("discovers packages with package.json in subdirectories", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var pkgs = loader.getPackages();
					expect(pkgs).toHaveKey("goodpkg");
				});

				it("skips directories without package.json", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var pkgs = loader.getPackages();
					expect(pkgs).notToHaveKey("nomanifest");
				});

				it("skips the wheels directory", () => {
					// Use the real vendor/ path to verify wheels/ is excluded
					var loader = new wheels.PackageLoader(
						vendorPath = ExpandPath("/vendor")
					);
					var pkgs = loader.getPackages();
					expect(pkgs).notToHaveKey("wheels");
				});

				it("returns empty when vendor path does not exist", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = ExpandPath("/nonexistent_path_12345")
					);
					expect(loader.getPackages()).toBeEmpty();
					expect(loader.getFailedPackages()).toBeEmpty();
				});

			});

			describe("Error isolation", () => {

				it("catches package init errors and continues loading", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var pkgs = loader.getPackages();
					var failed = loader.getFailedPackages();

					// goodpkg should load, brokenpkg should fail
					expect(pkgs).toHaveKey("goodpkg");
					expect(pkgs).notToHaveKey("brokenpkg");
					expect(ArrayLen(failed)).toBeGTE(1);

					// Verify the failure was recorded
					var foundBroken = false;
					for (var f in failed) {
						if (f.name == "brokenpkg") foundBroken = true;
					}
					expect(foundBroken).toBeTrue();
				});

			});

			describe("Manifest parsing", () => {

				it("stores package metadata from package.json", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var meta = loader.getPackageMeta();
					expect(meta).toHaveKey("goodpkg");
					expect(meta.goodpkg.name).toBe("wheels-goodpkg");
					expect(meta.goodpkg.version).toBe("1.0.0");
				});

			});

			describe("Mixin collection", () => {

				it("collects methods into declared mixin targets", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var mixins = loader.getMixins();
					expect(mixins.controller).toHaveKey("$goodPkgTestHelper");
				});

				it("does not inject into non-declared targets", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var mixins = loader.getMixins();
					// goodpkg declares controller only, not model
					expect(mixins.model).notToHaveKey("$goodPkgTestHelper");
				});

				it("skips mixins when provides.mixins is none", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var mixins = loader.getMixins();
					// nomixin declares mixins=none
					expect(mixins.controller).notToHaveKey("$nomixinTestHelper");
					expect(mixins.model).notToHaveKey("$nomixinTestHelper");
				});

				it("excludes lifecycle hooks from mixin collection", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var mixins = loader.getMixins();
					expect(mixins.controller).notToHaveKey("init");
				});

			});

		});

	}

}
