/**
 * Mixin-collision records reach application.wheels.mixinCollisions from three
 * producers: Plugins.cfc (legacy shape: existingPlugin/overridingPlugin),
 * PackageLoader.cfc, and the cross-system merge in Global.cfc::$loadPackages
 * (shared shape: firstProvider/secondProvider). The debug surfaces
 * (/wheels/plugins, the dev debug footer) consume the array unconditionally,
 * so every record must be normalized to ONE shape at the merge point —
 * previously a package-sourced record crashed both surfaces with
 * "key [EXISTINGPLUGIN] doesn't exist".
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("$normalizeMixinCollisions", () => {

			it("maps legacy plugin-shaped records to the shared shape", () => {
				var normalized = application.wo.$normalizeMixinCollisions([
					{
						method = "$collidingHelper",
						target = "controller",
						existingPlugin = "PluginA",
						overridingPlugin = "PluginB"
					}
				]);

				expect(ArrayLen(normalized)).toBe(1);
				expect(normalized[1].target).toBe("controller");
				expect(normalized[1].method).toBe("$collidingHelper");
				expect(normalized[1].firstProvider).toBe("PluginA");
				expect(normalized[1].secondProvider).toBe("PluginB");
				expect(normalized[1].acknowledged).toBeFalse();
				expect(normalized[1].source).toBe("plugin");
			});

			it("passes already-shared-shape records through unchanged", () => {
				var normalized = application.wo.$normalizeMixinCollisions([
					{
						method = "$pkgHelper",
						target = "model",
						firstProvider = "wheels-pkgA",
						secondProvider = "wheels-pkgB",
						acknowledged = true,
						source = "package"
					}
				]);

				expect(normalized[1].firstProvider).toBe("wheels-pkgA");
				expect(normalized[1].secondProvider).toBe("wheels-pkgB");
				expect(normalized[1].acknowledged).toBeTrue();
				expect(normalized[1].source).toBe("package");
			});

			it("normalizes mixed-shape arrays so every record exposes the shared keys", () => {
				var normalized = application.wo.$normalizeMixinCollisions([
					{
						method = "$one",
						target = "controller",
						existingPlugin = "PluginA",
						overridingPlugin = "PluginB"
					},
					{
						method = "$two",
						target = "controller",
						firstProvider = "wheels-pkgA",
						secondProvider = "wheels-pkgB",
						acknowledged = false,
						source = "cross"
					}
				]);

				for (var rec in normalized) {
					expect(rec).toHaveKey("firstProvider");
					expect(rec).toHaveKey("secondProvider");
					expect(rec).toHaveKey("acknowledged");
					expect(rec).toHaveKey("source");
				}
			});

			it("returns an empty array for no collisions", () => {
				expect(application.wo.$normalizeMixinCollisions([])).toHaveLength(0);
			});

		});

	}

}
