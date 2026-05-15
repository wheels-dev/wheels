// GH#2712: PackageLoader should auto-register a per-package CFML mapping so
// packages installed at vendor/wheels-sentry/ (or any hyphenated dir) can
// reference their own internal CFCs by a static, identifier-safe alias.
component extends="wheels.WheelsTest" {

	function run() {

		describe("PackageLoader — per-package CFML mapping (##2712)", () => {

			beforeEach(() => {
				mappingFixturesPath = ExpandPath("/wheels/tests/_assets/packages_mapping");
				mappingPrefix = "wheels.tests._assets.packages_mapping";
				collisionFixturesPath = ExpandPath("/wheels/tests/_assets/packages_mapping_collide");
				collisionPrefix = "wheels.tests._assets.packages_mapping_collide";
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

			});

			describe("Alias collisions across packages", () => {

				it("records the second colliding package as a failed package", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = collisionFixturesPath,
						componentPrefix = collisionPrefix
					);
					var failed = loader.getFailedPackages();
					var foundCollision = false;
					for (var f in failed) {
						if (f.name == "pkgtwo" && FindNoCase("mapping", f.error)) {
							foundCollision = true;
						}
					}
					expect(foundCollision).toBeTrue();
				});

				it("keeps the first package's alias mapping intact on collision", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = collisionFixturesPath,
						componentPrefix = collisionPrefix
					);
					var mappings = loader.getPackageMappings();
					expect(mappings).toHaveKey("wheelsCollide");
					expect(Find("pkgone", mappings.wheelsCollide)).toBeGT(0);
				});

			});

		});

	}

}
