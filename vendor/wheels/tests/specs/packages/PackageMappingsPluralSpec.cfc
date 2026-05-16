// GH#2705: PackageLoader should support a plural `mappings` field in
// package.json so a package can declare additional CFML mapping aliases
// beyond the singular identifier-form one (e.g. legacy compatibility paths
// like `plugins.sentry` for wheels-sentry@1.0.0, or namespaces pointing at
// internal subdirectories).
//
// Fixture invariants every scenario relies on:
//   - Each fixture directory contains a package.json AND a matching CFC so
//     $instantiatePackage doesn't fail for an unrelated reason.
//   - Scenarios that need to be isolated from one another live in separate
//     vendor fixture directories — the loader scans one vendor root per
//     instantiation, so co-locating unrelated fixtures would cross-contaminate
//     mapping collisions.
component extends="wheels.WheelsTest" {

	function run() {

		describe("PackageLoader — plural `mappings` field (##2705)", () => {

			beforeEach(() => {
				basicPath = ExpandPath("/wheels/tests/_assets/packages_mappings_plural_basic");
				basicPrefix = "wheels.tests._assets.packages_mappings_plural_basic";
				invalidNamePath = ExpandPath("/wheels/tests/_assets/packages_mappings_plural_invalid_name");
				invalidNamePrefix = "wheels.tests._assets.packages_mappings_plural_invalid_name";
				invalidPathPath = ExpandPath("/wheels/tests/_assets/packages_mappings_plural_invalid_path");
				invalidPathPrefix = "wheels.tests._assets.packages_mappings_plural_invalid_path";
				collidePath = ExpandPath("/wheels/tests/_assets/packages_mappings_plural_collide");
				collidePrefix = "wheels.tests._assets.packages_mappings_plural_collide";
				crossFormPath = ExpandPath("/wheels/tests/_assets/packages_mappings_plural_cross_form");
				crossFormPrefix = "wheels.tests._assets.packages_mappings_plural_cross_form";
				invalidBlockPath = ExpandPath("/wheels/tests/_assets/packages_mappings_plural_invalid_block");
				invalidBlockPrefix = "wheels.tests._assets.packages_mappings_plural_invalid_block";
			});

			describe("Basic registration", () => {

				it("registers a dotted legacy-style mapping pointing at the package root (the wheels-sentry case)", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = basicPath,
						componentPrefix = basicPrefix
					);
					var mappings = loader.getPackageMappings();
					expect(mappings).toHaveKey("plugins.sentry");
					expect(Find("sentrystyle", mappings["plugins.sentry"])).toBeGT(0);
				});

				it("registers all entries when a package declares multiple plural mappings", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = basicPath,
						componentPrefix = basicPrefix
					);
					var mappings = loader.getPackageMappings();
					expect(mappings).toHaveKey("multiOne");
					expect(mappings).toHaveKey("multi.two");
					expect(mappings).toHaveKey("multi.three.four");
				});

				it("preserves the auto-derived singular alias alongside plural entries", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = basicPath,
						componentPrefix = basicPrefix
					);
					var mappings = loader.getPackageMappings();
					// `wheels-sentrystyle` derives to `wheelsSentrystyle` by the
					// existing name-camelcase rule; plural shouldn't suppress it.
					expect(mappings).toHaveKey("wheelsSentrystyle");
				});

				it("resolves a relative subdirectory path against the package directory", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = basicPath,
						componentPrefix = basicPrefix
					);
					var mappings = loader.getPackageMappings();
					expect(mappings).toHaveKey("relpath.sub");
					// Trailing segment must reflect the subdir join, not the
					// package root alone.
					expect(Find("relpath/sub", Replace(mappings["relpath.sub"], "\", "/", "all"))).toBeGT(0);
				});

			});

			describe("Invalid mappings block", () => {

				it("fails a package whose `mappings` field is not a struct", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = invalidBlockPath,
						componentPrefix = invalidBlockPrefix
					);
					var failedNames = $failedPackageNames(loader);
					expect(ArrayFindNoCase(failedNames, "notastruct")).toBeGT(0);
				});

				it("rolls back the singular alias of a package whose `mappings` field is not a struct", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = invalidBlockPath,
						componentPrefix = invalidBlockPrefix
					);
					var mappings = loader.getPackageMappings();
					// `wheels-notastruct` would derive to `wheelsNotastruct`.
					// The IsStruct guard rejects the block before any plural
					// entry is read, so the only thing to unwind is the
					// singular alias.
					expect(mappings).notToHaveKey("wheelsNotastruct");
				});

			});

			describe("Invalid mapping names", () => {

				it("fails a package whose plural mapping name has a non-identifier segment", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = invalidNamePath,
						componentPrefix = invalidNamePrefix
					);
					var failedNames = $failedPackageNames(loader);
					expect(ArrayFindNoCase(failedNames, "invalidname")).toBeGT(0);
				});

				it("does not register a plural alias whose validation failed", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = invalidNamePath,
						componentPrefix = invalidNamePrefix
					);
					var mappings = loader.getPackageMappings();
					expect(mappings).notToHaveKey("plugins.bad-name");
				});

				it("rolls back the singular alias of a package whose plural validation failed", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = invalidNamePath,
						componentPrefix = invalidNamePrefix
					);
					var mappings = loader.getPackageMappings();
					// `wheels-invalidname` would derive to `wheelsInvalidname`.
					// Because the plural entry failed, the singular must be
					// unwound too — leaves the registries internally consistent
					// for any future load attempt.
					expect(mappings).notToHaveKey("wheelsInvalidname");
				});

			});

			describe("Invalid mapping paths", () => {

				it("rejects an absolute path so a package can't claim mappings outside its install tree", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = invalidPathPath,
						componentPrefix = invalidPathPrefix
					);
					var failedNames = $failedPackageNames(loader);
					expect(ArrayFindNoCase(failedNames, "invalidpath")).toBeGT(0);
				});

				it("rejects a '..' traversal so a package can't reach a sibling's directory", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = invalidPathPath,
						componentPrefix = invalidPathPrefix
					);
					var failedNames = $failedPackageNames(loader);
					expect(ArrayFindNoCase(failedNames, "traversal")).toBeGT(0);
				});

			});

			describe("Plural-vs-plural collision", () => {

				// Two fixtures both claim `shared.collide`. Whichever
				// DirectoryList enumerates first wins; the other lands in
				// failedPackages. Assertions are order-agnostic so this stays
				// stable on filesystems that don't sort alphabetically.

				it("records exactly one collidefirst/collidesecond as a failed mapping collision", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = collidePath,
						componentPrefix = collidePrefix
					);
					var failed = loader.getFailedPackages();
					var collisions = [];
					for (var f in failed) {
						if (FindNoCase("Duplicate", f.error) && FindNoCase("mapping", f.error)) {
							ArrayAppend(collisions, f);
						}
					}
					expect(ArrayLen(collisions)).toBe(1);
					expect(ListFindNoCase("collidefirst,collidesecond", collisions[1].name)).toBeGT(0);
				});

				it("keeps the winner's plural mapping intact after the collider rolls back", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = collidePath,
						componentPrefix = collidePrefix
					);
					var mappings = loader.getPackageMappings();
					expect(mappings).toHaveKey("shared.collide");
					var winnerDir = Find("collidefirst", mappings["shared.collide"]) > 0
						|| Find("collidesecond", mappings["shared.collide"]) > 0;
					expect(winnerDir).toBeTrue();
				});

			});

			describe("Cross-form (plural vs singular) collision", () => {

				// singularholder claims `crossFormShared` via the singular
				// `mapping` field. zpluralcollider claims the same name via a
				// plural `mappings` entry. The two-letter prefix on
				// zpluralcollider is meant to push it to the end of
				// DirectoryList alphabetical enumeration on most filesystems,
				// but assertions stay order-agnostic so the spec doesn't fail
				// on FS that don't sort. The invariants we *do* care about
				// hold regardless of which one wins.

				it("records exactly one of the two packages as a failed cross-form collision", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = crossFormPath,
						componentPrefix = crossFormPrefix
					);
					var failed = loader.getFailedPackages();
					var collisions = [];
					for (var f in failed) {
						if (ListFindNoCase("singularholder,zpluralcollider", f.name)
							&& FindNoCase("Duplicate", f.error)
							&& FindNoCase("mapping", f.error)) {
							ArrayAppend(collisions, f);
						}
					}
					expect(ArrayLen(collisions)).toBe(1);
				});

				it("keeps the winner's crossFormShared mapping intact regardless of load order", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = crossFormPath,
						componentPrefix = crossFormPrefix
					);
					var mappings = loader.getPackageMappings();
					expect(mappings).toHaveKey("crossFormShared");
					// Whichever package loaded first owns the slot — assertion
					// covers both orderings.
					var wins = Find("singularholder", mappings.crossFormShared) > 0
						|| Find("zpluralcollider", mappings.crossFormShared) > 0;
					expect(wins).toBeTrue();
				});

				it("rolls back the plural collider's own singular alias when its plural entry loses the race", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = crossFormPath,
						componentPrefix = crossFormPrefix
					);
					var failedNames = $failedPackageNames(loader);
					var mappings = loader.getPackageMappings();
					// The unwind contract only fires when the plural-side
					// package was the loser. If singularholder lost, there's
					// no separate alias to clean — its only declaration was
					// `mapping: "crossFormShared"`, which never made it into
					// the registry. Test the contract conditionally so both
					// orderings pass cleanly.
					if (ArrayFindNoCase(failedNames, "zpluralcollider")) {
						expect(mappings).notToHaveKey("wheelsPluralcollider");
					}
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
