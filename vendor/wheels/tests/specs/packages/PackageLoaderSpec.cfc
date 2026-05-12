component extends="wheels.WheelsTest" {

	function run() {

		describe("PackageLoader", () => {

			beforeEach(() => {
				fixturesPath = ExpandPath("/wheels/tests/_assets/packages");
				componentPrefix = "wheels.tests._assets.packages";
				parseFixturesPath = ExpandPath("/wheels/tests/_assets/packages_parse");
				parsePrefix = "wheels.tests._assets.packages_parse";
				privateFixturesPath = ExpandPath("/wheels/tests/_assets/packages_private");
				privatePrefix = "wheels.tests._assets.packages_private";
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

			describe("wheelsVersion compatibility", () => {

				it("rejects packages whose wheelsVersion constraint the runtime cannot satisfy", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix,
						wheelsVersion = "4.0.0"
					);
					var pkgs = loader.getPackages();
					var meta = loader.getPackageMeta();
					var failed = loader.getFailedPackages();

					// Fixture declares ">=99.0" which 4.0.0 cannot satisfy
					expect(pkgs).notToHaveKey("incompatversion");
					expect(meta).notToHaveKey("incompatversion");

					var foundIncompat = false;
					for (var f in failed) {
						if (f.name == "incompatversion" && Find("wheelsVersion", f.error)) {
							foundIncompat = true;
						}
					}
					expect(foundIncompat).toBeTrue();
				});

				it("loads packages whose wheelsVersion constraint is satisfied", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix,
						wheelsVersion = "4.0.0"
					);
					var pkgs = loader.getPackages();

					// Fixture declares ">=3.0" which 4.0.0 satisfies
					expect(pkgs).toHaveKey("compatversion");
				});

				it("loads packages that omit wheelsVersion (backward compatible)", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix,
						wheelsVersion = "4.0.0"
					);
					var pkgs = loader.getPackages();

					// Existing fixtures like depA/depB/replacer have no wheelsVersion declared
					expect(pkgs).toHaveKey("depA");
					expect(pkgs).toHaveKey("depB");
					expect(pkgs).toHaveKey("replacer");
				});

				it("treats dev build stamp as permissive so strict constraints do not reject in local dev", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix,
						wheelsVersion = "@build.version@"
					);
					var pkgs = loader.getPackages();

					// Even the ">=99.0" fixture loads on an unstamped dev build
					expect(pkgs).toHaveKey("incompatversion");
					expect(pkgs).toHaveKey("compatversion");
				});

			});

			describe("Mixin target validation", () => {

				it("rejects packages with an unknown mixin target (typo)", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var pkgs = loader.getPackages();
					var failed = loader.getFailedPackages();

					// invalidmixin declares "controler" (typo) — must not load
					expect(pkgs).notToHaveKey("invalidmixin");

					var foundInvalid = false;
					var errorMessage = "";
					for (var f in failed) {
						if (f.name == "invalidmixin") {
							foundInvalid = true;
							errorMessage = f.error;
						}
					}
					expect(foundInvalid).toBeTrue();
					// Error must name the unknown target and list the allowlist
					expect(errorMessage).toInclude("controler");
					expect(errorMessage).toInclude("controller");
				});

				it("rejects packages whose target list contains any unknown entry", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var pkgs = loader.getPackages();
					var failed = loader.getFailedPackages();

					// invalidmixinview declares "controller,view" — "view" is not mixable
					expect(pkgs).notToHaveKey("invalidmixinview");

					var foundInvalid = false;
					var errorMessage = "";
					for (var f in failed) {
						if (f.name == "invalidmixinview") {
							foundInvalid = true;
							errorMessage = f.error;
						}
					}
					expect(foundInvalid).toBeTrue();
					expect(errorMessage).toInclude("view");
				});

				it("loads packages with valid single-target declarations", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var pkgs = loader.getPackages();

					// depA declares "controller" — a valid target
					expect(pkgs).toHaveKey("depA");
				});

				it("accepts the special none target", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var pkgs = loader.getPackages();

					// nomixin declares "none" — must still load
					expect(pkgs).toHaveKey("nomixin");
				});

				it("rejects packages whose per-method mixin metadata has an unknown target", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var failed = loader.getFailedPackages();

					// invalidmethodmixin has a method annotated mixin="controler" (typo)
					var foundInvalid = false;
					var errorMessage = "";
					for (var f in failed) {
						if (f.name == "invalidmethodmixin") {
							foundInvalid = true;
							errorMessage = f.error;
						}
					}
					expect(foundInvalid).toBeTrue();
					// Error must name the offending method, the unknown target, and the allowlist
					expect(errorMessage).toInclude("$badTarget");
					expect(errorMessage).toInclude("controler");
					expect(errorMessage).toInclude("controller");
				});

				it("loads packages with valid per-method mixin overrides", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var pkgs = loader.getPackages();
					var mixins = loader.getMixins();

					// validmethodmixin uses mixin="model" and mixin="none" — must still load
					expect(pkgs).toHaveKey("validmethodmixin");

					// Controller default reaches controller target
					expect(mixins.controller).toHaveKey("$validmethodmixinControllerHelper");
					// Override to model target takes effect
					expect(mixins.model).toHaveKey("$validmethodmixinModelHelper");
					// Opt-out method is not registered on any target
					expect(mixins.controller).notToHaveKey("$validmethodmixinInternal");
					expect(mixins.model).notToHaveKey("$validmethodmixinInternal");
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

				it("ignores lazy=true when the package also declares mixins", () => {
					// Packages that contribute to mixin tables must load eagerly
					// so the tables are complete by the time controllers/views
					// reference the mixed-in methods. The `canBeLazy` gate in
					// PackageLoader requires mixins=none AND no middleware.
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					var pkgs = loader.getPackages();

					// lazyignored declares lazy=true + mixins=controller;
					// it should be eagerly loaded despite the lazy flag.
					expect(pkgs).toHaveKey("lazyignored");
					expect(pkgs.lazyignored.initialized).toBeTrue();
				});

			});

			describe("Mixin collisions", () => {

				beforeEach(() => {
					collisionFixturesPath = ExpandPath("/wheels/tests/_assets/packages_collision");
					collisionPrefix = "wheels.tests._assets.packages_collision";
				});

				it("records no collisions when no method overlaps", () => {
					// Default shared fixtures path — none of those fixtures collide
					var loader = new wheels.PackageLoader(
						vendorPath = fixturesPath,
						componentPrefix = componentPrefix
					);
					expect(loader.getMixinCollisions()).toBeEmpty();
				});

				it("detects collisions when two packages provide the same method for the same target", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = collisionFixturesPath,
						componentPrefix = collisionPrefix
					);
					var collisions = loader.getMixinCollisions();

					// mixincolA, mixincolB, and mixincolOverride all provide $sharedHelper on controller.
					// Sorted load order means two collisions are recorded (A→B, B→Override)
					expect(ArrayLen(collisions)).toBeGTE(1);

					var found = false;
					for (var c in collisions) {
						if (c.method == "$sharedHelper" && c.target == "controller") {
							found = true;
						}
					}
					expect(found).toBeTrue();
				});

				it("both packages still load — collision doesn't block loading", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = collisionFixturesPath,
						componentPrefix = collisionPrefix
					);
					var pkgs = loader.getPackages();
					expect(pkgs).toHaveKey("mixincolA");
					expect(pkgs).toHaveKey("mixincolB");
				});

				it("marks collision as acknowledged when overriding package declares overrides", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = collisionFixturesPath,
						componentPrefix = collisionPrefix
					);
					var collisions = loader.getMixinCollisions();

					var acknowledgedFound = false;
					for (var c in collisions) {
						if (c.secondProvider == "mixincolOverride" && c.method == "$sharedHelper") {
							expect(c.acknowledged).toBeTrue();
							acknowledgedFound = true;
						}
					}
					expect(acknowledgedFound).toBeTrue();
				});

				it("records source as 'package' for package-to-package collisions", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = collisionFixturesPath,
						componentPrefix = collisionPrefix
					);
					var collisions = loader.getMixinCollisions();
					expect(ArrayLen(collisions)).toBeGTE(1);
					for (var c in collisions) {
						expect(c.source).toBe("package");
					}
				});

				it("records firstProvider and secondProvider correctly", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = collisionFixturesPath,
						componentPrefix = collisionPrefix
					);
					var collisions = loader.getMixinCollisions();
					for (var c in collisions) {
						expect(Len(c.firstProvider)).toBeGT(0);
						expect(Len(c.secondProvider)).toBeGT(0);
						expect(c.firstProvider).notToBe(c.secondProvider);
					}
				});

			});

			describe("Hidden directory skip", () => {

				it("ignores dot-prefixed directories even when they contain a package.json", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = parseFixturesPath,
						componentPrefix = parsePrefix
					);

					// `.hiddenpkg` has a valid manifest but the loader must never look at it.
					expect(loader.getPackages()).notToHaveKey(".hiddenpkg");
					expect(loader.getPackages()).notToHaveKey("hiddenpkg");
					expect(loader.getPackageMeta()).notToHaveKey(".hiddenpkg");

					var failed = loader.getFailedPackages();
					for (var f in failed) {
						expect(f.name).notToBe(".hiddenpkg");
						expect(f.name).notToBe("hiddenpkg");
					}
				});

			});

			describe("Manifest validation", () => {

				it("records a failure when the manifest is missing the name field", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = parseFixturesPath,
						componentPrefix = parsePrefix
					);
					var failed = loader.getFailedPackages();

					var found = false;
					for (var f in failed) {
						if (f.name == "missingname" && FindNoCase("name", f.error)) {
							found = true;
						}
					}
					expect(found).toBeTrue();
					expect(loader.getPackages()).notToHaveKey("missingname");
				});

				it("records a failure when the manifest is missing the version field", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = parseFixturesPath,
						componentPrefix = parsePrefix
					);
					var failed = loader.getFailedPackages();

					var found = false;
					for (var f in failed) {
						if (f.name == "missingversion" && FindNoCase("version", f.error)) {
							found = true;
						}
					}
					expect(found).toBeTrue();
					expect(loader.getPackages()).notToHaveKey("missingversion");
				});

				it("isolates malformed JSON so sibling packages still load", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = parseFixturesPath,
						componentPrefix = parsePrefix
					);
					var failed = loader.getFailedPackages();
					var pkgs = loader.getPackages();

					var foundBroken = false;
					for (var f in failed) {
						if (f.name == "malformedjson") foundBroken = true;
					}
					expect(foundBroken).toBeTrue();

					// `goodafter` shares the same fixture root — it must still load,
					// proving error isolation at the manifest-parse boundary.
					expect(pkgs).toHaveKey("goodafter");
				});

				it("rejects a manifest whose root JSON value is not an object", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = parseFixturesPath,
						componentPrefix = parsePrefix
					);
					var failed = loader.getFailedPackages();

					var found = false;
					for (var f in failed) {
						if (f.name == "notobject") found = true;
					}
					expect(found).toBeTrue();
					expect(loader.getPackages()).notToHaveKey("notobject");
				});

				it("continues loading remaining packages after per-package manifest failures", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = parseFixturesPath,
						componentPrefix = parsePrefix
					);
					// At least one failure recorded AND the healthy sibling reached the packages map.
					expect(ArrayLen(loader.getFailedPackages())).toBeGTE(1);
					expect(loader.getPackages()).toHaveKey("goodafter");
				});

			});

			describe("Private method isolation", () => {

				it("mixes in public methods but ignores private ones", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = privateFixturesPath,
						componentPrefix = privatePrefix
					);
					var mixins = loader.getMixins();

					// Public method reaches the declared mixin target.
					expect(mixins.controller).toHaveKey("$publicHelper");
					// Private method is not exposed on the CFC's public surface, so it
					// must not leak into the mixin map on any target.
					expect(mixins.controller).notToHaveKey("$privateHelper");
					expect(mixins.model).notToHaveKey("$privateHelper");
					expect(mixins.application).notToHaveKey("$privateHelper");
				});

			});

			describe("Legacy plugin coexistence", () => {

				it("exposes its inventory alongside the legacy plugins loader in application state", () => {
					// Framework boot populates both inventories under application.wheels.
					// Each may be empty in a given test environment, but both must be
					// present so downstream code can iterate them uniformly.
					expect(StructKeyExists(application.wheels, "packages")).toBeTrue();
					expect(StructKeyExists(application.wheels, "plugins")).toBeTrue();
					expect(IsStruct(application.wheels.packages)).toBeTrue();
					expect(IsStruct(application.wheels.plugins)).toBeTrue();
				});

				it("does not share backing storage between the two loaders", () => {
					// The structs are independent — mutating one must not leak into the
					// other. This guards against a future refactor that accidentally
					// points both keys at the same reference.
					var pkgKey = "__pkgProbe_#CreateUUID()#";
					application.wheels.packages[pkgKey] = true;
					expect(StructKeyExists(application.wheels.plugins, pkgKey)).toBeFalse();
					StructDelete(application.wheels.packages, pkgKey);
				});

			});

		});

	}

}
