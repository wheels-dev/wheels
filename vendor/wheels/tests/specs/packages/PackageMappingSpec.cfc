// GH#2712: PackageLoader should auto-register a per-package CFML mapping so
// packages installed at vendor/wheels-sentry/ (or any hyphenated dir) can
// reference their own internal CFCs by a static, identifier-safe alias.
//
// Fixture invariants the loader depends on:
//   - Every package directory has both a package.json AND a matching CFC so
//     $instantiatePackage succeeds. A CFC-less package would land in
//     failedPackages for the wrong reason and mask the bug under test.
component extends="wheels.WheelsTest" {

	function run() {

		describe("PackageLoader — per-package CFML mapping (##2712)", () => {

			beforeEach(() => {
				mappingFixturesPath = ExpandPath("/wheels/tests/_assets/packages_mapping");
				mappingPrefix = "wheels.tests._assets.packages_mapping";
				collisionFixturesPath = ExpandPath("/wheels/tests/_assets/packages_mapping_collide");
				collisionPrefix = "wheels.tests._assets.packages_mapping_collide";
				invalidFixturesPath = ExpandPath("/wheels/tests/_assets/packages_mapping_invalid");
				invalidPrefix = "wheels.tests._assets.packages_mapping_invalid";
				staleFixturesPath = ExpandPath("/wheels/tests/_assets/packages_mapping_stale");
				stalePrefix = "wheels.tests._assets.packages_mapping_stale";
				lazyInvalidFixturesPath = ExpandPath("/wheels/tests/_assets/packages_mapping_lazy_invalid");
				lazyInvalidPrefix = "wheels.tests._assets.packages_mapping_lazy_invalid";
			});

			describe("Alias derivation from manifest name", () => {

				it("derives a camelCase alias from a hyphenated package name", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = mappingFixturesPath,
						componentPrefix = mappingPrefix
					);
					var mappings = loader.getPackageMappings();
					expect(mappings).toHaveKey("wheelsHyphenPkg");
				});

				it("points the alias at the package install directory", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = mappingFixturesPath,
						componentPrefix = mappingPrefix
					);
					var mappings = loader.getPackageMappings();
					expect(mappings).toHaveKey("wheelsHyphenPkg");
					// The mapping value is the absolute pkg dir; sanity-check the trailing
					// segment so the assertion is portable across CI checkout paths.
					expect(Find("hyphenpkg", mappings.wheelsHyphenPkg)).toBeGT(0);
				});

			});

			describe("Manifest mapping override", () => {

				it("honors an explicit `mapping` field when valid", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = mappingFixturesPath,
						componentPrefix = mappingPrefix
					);
					var mappings = loader.getPackageMappings();
					expect(mappings).toHaveKey("customAlias");
				});

				it("does not register the derived default when an override is supplied", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = mappingFixturesPath,
						componentPrefix = mappingPrefix
					);
					var mappings = loader.getPackageMappings();
					// overridemapping has name=wheels-overridden, mapping=customAlias
					expect(mappings).notToHaveKey("wheelsOverridden");
				});

				it("returns a defensive copy callers cannot use to corrupt the registry", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = mappingFixturesPath,
						componentPrefix = mappingPrefix
					);
					var snapshot = loader.getPackageMappings();
					snapshot["customAlias"] = "/tmp/injected";
					var fresh = loader.getPackageMappings();
					expect(fresh.customAlias).notToBe("/tmp/injected");
				});

			});

			describe("Invalid `mapping` values", () => {

				it("records the package as failed when `mapping` does not satisfy [A-Za-z_][A-Za-z0-9_]*", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = invalidFixturesPath,
						componentPrefix = invalidPrefix
					);
					var failedNames = $failedPackageNames(loader);
					expect(ArrayFindNoCase(failedNames, "invalidalias")).toBeGT(0);
					var mappings = loader.getPackageMappings();
					expect(mappings).notToHaveKey("123bad");
				});

				it("treats explicit empty-string `mapping` as invalid rather than falling back to name-derivation", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = invalidFixturesPath,
						componentPrefix = invalidPrefix
					);
					var failedNames = $failedPackageNames(loader);
					expect(ArrayFindNoCase(failedNames, "emptyalias")).toBeGT(0);
					var mappings = loader.getPackageMappings();
					// Documented contract: an explicit `mapping` field must satisfy
					// the regex; an empty value must NOT silently auto-derive.
					expect(mappings).notToHaveKey("wheelsEmptyAlias");
				});

				it("treats whitespace-only `mapping` the same as empty-string", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = invalidFixturesPath,
						componentPrefix = invalidPrefix
					);
					var failedNames = $failedPackageNames(loader);
					expect(ArrayFindNoCase(failedNames, "whitespacealias")).toBeGT(0);
					var mappings = loader.getPackageMappings();
					expect(mappings).notToHaveKey("wheelsWhitespaceAlias");
				});

				it("continues registering valid sibling packages past invalid ones", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = invalidFixturesPath,
						componentPrefix = invalidPrefix
					);
					var mappings = loader.getPackageMappings();
					expect(mappings).toHaveKey("wheelsValidSibling");
				});

			});

			describe("Alias collisions across packages", () => {

				// Two fixture packages both compute alias `wheelsCollide` — pkgone
				// via derived `wheels-collide` and pkgtwo via explicit `mapping`.
				// Whichever DirectoryList enumerates first claims the alias; the
				// second lands in failedPackages. Assertions are order-agnostic so
				// the spec is stable across filesystems with non-alphabetical sort.

				it("records exactly one package as a failed mapping collision", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = collisionFixturesPath,
						componentPrefix = collisionPrefix
					);
					var failed = loader.getFailedPackages();
					var collisions = [];
					for (var f in failed) {
						if (FindNoCase("Duplicate", f.error) && FindNoCase("mapping", f.error)) {
							ArrayAppend(collisions, f);
						}
					}
					expect(ArrayLen(collisions)).toBe(1);
					// Failed package must be one of the two collision fixtures —
					// guards against the slot being released onto a stranger.
					expect(ListFindNoCase("pkgone,pkgtwo", collisions[1].name)).toBeGT(0);
				});

				it("keeps the winning package's alias mapping intact on collision", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = collisionFixturesPath,
						componentPrefix = collisionPrefix
					);
					var mappings = loader.getPackageMappings();
					expect(mappings).toHaveKey("wheelsCollide");
					// The winner is whichever DirectoryList yielded first; the
					// mapping must point at one of the two fixture dirs.
					var wins = Find("pkgone", mappings.wheelsCollide) > 0
						|| Find("pkgtwo", mappings.wheelsCollide) > 0;
					expect(wins).toBeTrue();
				});

			});

			describe("Stale-mapping regression (registration must follow validation)", () => {

				// badmixin: name=wheels-stale-shared → derived alias wheelsStaleShared,
				//   declares `mixins: view` which $validateMixinTargets rejects.
				// samealias: name=wheels-other, mapping=wheelsStaleShared.
				//
				// Pre-fix behavior: badmixin claimed the alias slot before mixin
				// validation, then failed validation but left the slot occupied.
				// samealias then failed with a spurious "Duplicate mapping alias",
				// and wheelsStaleShared resolved to badmixin's directory despite
				// badmixin being in failedPackages.
				//
				// Post-fix behavior: badmixin fails first, never claims a slot,
				// samealias claims wheelsStaleShared cleanly.

				it("does not leak an alias slot when a package fails after mapping derivation", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = staleFixturesPath,
						componentPrefix = stalePrefix
					);
					var failedNames = $failedPackageNames(loader);
					expect(ArrayFindNoCase(failedNames, "badmixin")).toBeGT(0);
					// samealias must succeed — its alias would have collided with a
					// leaked badmixin claim under the pre-fix loader.
					expect(ArrayFindNoCase(failedNames, "samealias")).toBe(0);
				});

				it("points wheelsStaleShared at the surviving package, not the failed one", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = staleFixturesPath,
						componentPrefix = stalePrefix
					);
					var mappings = loader.getPackageMappings();
					expect(mappings).toHaveKey("wheelsStaleShared");
					expect(Find("samealias", mappings.wheelsStaleShared)).toBeGT(0);
					expect(Find("badmixin", mappings.wheelsStaleShared)).toBe(0);
				});

			});

			describe("Lazy package mapping failure", () => {

				// The lazy branch in $loadPackage has its own $tryRegisterPackageMapping
				// call and its own early-return on failure. Confirm rollback removes
				// both packageMeta AND lazyPackages so a failed lazy registration
				// can't leak into isPackageLoaded()/getPackage() either.

				it("records a lazy package with an invalid mapping as a failed package", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = lazyInvalidFixturesPath,
						componentPrefix = lazyInvalidPrefix
					);
					var failedNames = $failedPackageNames(loader);
					expect(ArrayFindNoCase(failedNames, "lazybadmapping")).toBeGT(0);
				});

				it("rolls back the lazyPackages entry so isPackageLoaded() returns false", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = lazyInvalidFixturesPath,
						componentPrefix = lazyInvalidPrefix
					);
					expect(loader.isPackageLoaded("lazybadmapping")).toBeFalse();
				});

				it("continues loading other lazy packages past the failure", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = lazyInvalidFixturesPath,
						componentPrefix = lazyInvalidPrefix
					);
					var mappings = loader.getPackageMappings();
					expect(mappings).toHaveKey("wheelsLazyGood");
					expect(loader.isPackageLoaded("lazygoodsibling")).toBeTrue();
				});

			});

		});

	}

	// Helper: extract package names from getFailedPackages() into a flat array
	// so callers can use ArrayFindNoCase rather than hand-rolling a for-loop.
	private array function $failedPackageNames(required any loader) {
		var names = [];
		var failed = arguments.loader.getFailedPackages();
		for (var f in failed) {
			ArrayAppend(names, f.name);
		}
		return names;
	}

}
