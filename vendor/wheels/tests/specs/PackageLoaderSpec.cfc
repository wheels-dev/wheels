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
					// replacer replaces goodpkg, so check for replacer instead
					var pkgs = loader.getPackages();
					expect(pkgs).toHaveKey("replacer");
					expect(pkgs).toHaveKey("depA");
					expect(pkgs).toHaveKey("depB");
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

					// replacer should load (it replaces goodpkg), brokenpkg should fail
					expect(pkgs).toHaveKey("replacer");
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
					// replacer should have metadata (goodpkg is excluded from load but meta is only for loaded pkgs)
					expect(meta).toHaveKey("replacer");
					expect(meta.replacer.name).toBe("wheels-replacer");
					expect(meta.replacer.version).toBe("2.0.0");
				});

			});

			describe("Mixin collection", () => {

				it("collects methods into declared mixin targets", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var mixins = loader.getMixins();
					// replacer provides controller mixins
					expect(mixins.controller).toHaveKey("$replacerHelper");
				});

				it("does not inject into non-declared targets", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var mixins = loader.getMixins();
					// depA declares controller only, not model
					expect(mixins.model).notToHaveKey("$depAHelper");
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

			describe("Dependency ordering", () => {

				it("returns a load order array", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var order = loader.getLoadOrder();
					expect(IsArray(order)).toBeTrue();
					expect(ArrayLen(order)).toBeGT(0);
				});

				it("loads depB before depA (depA requires depB)", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var order = loader.getLoadOrder();
					var idxB = ArrayFind(order, "depB");
					var idxA = ArrayFind(order, "depA");

					// Both should be in load order
					expect(idxB).toBeGT(0);
					expect(idxA).toBeGT(0);
					// depB must load before depA
					expect(idxB).toBeLT(idxA);
				});

			});

			describe("Replacement", () => {

				it("excludes replaced packages", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var excluded = loader.getExcludedPackages();

					// replacer replaces goodpkg
					expect(StructKeyExists(excluded, "goodpkg")).toBeTrue();
				});

				it("does not load replaced packages", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var pkgs = loader.getPackages();
					var order = loader.getLoadOrder();

					// goodpkg is replaced, so it should not be in load order
					expect(ArrayFind(order, "goodpkg")).toBe(0);
					// replacer should be loaded
					expect(pkgs).toHaveKey("replacer");
				});

			});

			describe("Cycle detection", () => {

				it("reports circular dependencies as failures", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var failed = loader.getFailedPackages();

					var foundCycleA = false;
					var foundCycleB = false;
					for (var f in failed) {
						if (f.name == "cycleA" && Find("Circular dependency", f.error)) foundCycleA = true;
						if (f.name == "cycleB" && Find("Circular dependency", f.error)) foundCycleB = true;
					}
					expect(foundCycleA).toBeTrue();
					expect(foundCycleB).toBeTrue();
				});

				it("does not include cycled packages in load order", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var order = loader.getLoadOrder();

					expect(ArrayFind(order, "cycleA")).toBe(0);
					expect(ArrayFind(order, "cycleB")).toBe(0);
				});

			});

			describe("Missing requirements", () => {

				it("reports missing required packages as failures", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var failed = loader.getFailedPackages();

					var foundMissing = false;
					for (var f in failed) {
						if (f.name == "missingreq" && Find("not found", f.error)) foundMissing = true;
					}
					expect(foundMissing).toBeTrue();
				});

			});

			describe("Suggest ordering", () => {

				it("loads suggesting package even when suggested package is absent", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var order = loader.getLoadOrder();

					// suggestpkg suggests goodpkg, but goodpkg is replaced by replacer
					// suggestpkg should still load (suggests are soft dependencies)
					var idxSuggest = ArrayFind(order, "suggestpkg");
					expect(idxSuggest).toBeGT(0);
				});

			});

			describe("Lazy loading", () => {

				it("does not eagerly instantiate lazy packages", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var pkgs = loader.getPackages();

					// lazypkg declares lazy=true and mixins=none, so it should NOT
					// be in the eagerly-loaded packages struct yet
					expect(pkgs).notToHaveKey("lazypkg");
				});

				it("reports lazy packages as loaded via isPackageLoaded", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);

					expect(loader.isPackageLoaded("lazypkg")).toBeTrue();
				});

				it("instantiates lazy package on getPackage()", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);

					// Should not be in packages yet
					expect(loader.getPackages()).notToHaveKey("lazypkg");

					// Accessing it triggers instantiation
					var pkg = loader.getPackage("lazypkg");
					expect(pkg.initialized).toBeTrue();

					// Now it should be in the packages struct
					expect(loader.getPackages()).toHaveKey("lazypkg");
				});

			});

		});

	}

}
