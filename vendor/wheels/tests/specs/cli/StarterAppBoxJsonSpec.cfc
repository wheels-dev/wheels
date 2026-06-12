/**
 * Regression (issue #3181): examples/starter-app/box.json declared
 * "wheels-authenticateThis":"^1" as a ForgeBox dependency, but that slug was
 * never published to ForgeBox. `box install wheels-starter-app` fetched
 * wheels-core, then aborted with:
 *
 *   ERROR: Error getting ForgeBox entry [wheels-authenticateThis]
 *          The entry slug sent is invalid or does not exist
 *
 * leaving the install broken with no usable app.
 *
 * The authenticateThis plugin already ships BUNDLED under
 * examples/starter-app/plugins/authenticateThis/ (alongside
 * FlashMessagesBootstrap and jsconfirm), and flashMessages() lives in core
 * (vendor/wheels/view/miscellaneous.cfc). So no plugin needs to be fetched
 * from ForgeBox at all — the only resolvable ForgeBox dependency the starter
 * app requires is wheels-core. Declaring a bundled plugin as a ForgeBox
 * dependency is exactly what breaks the install.
 *
 * Structural assertion against the published manifest — mirrors the
 * file-source regression-guard pattern in
 * ApplicationCfcInjectorAssignmentSpec.cfc / buildArtifactLicenseSpec.cfc.
 * Running the box.install itself would require network access to ForgeBox.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Starter App box.json dependency contract", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the
			// configured Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var boxJsonPath = repoRoot & "/examples/starter-app/box.json";
			var pluginsDir = repoRoot & "/examples/starter-app/plugins";

			it("does not declare the unpublished wheels-authenticateThis ForgeBox dependency", () => {
				expect(fileExists(boxJsonPath)).toBeTrue("Missing file: " & boxJsonPath);

				var manifest = deserializeJSON(fileRead(boxJsonPath));
				var deps = structKeyExists(manifest, "dependencies") ? manifest.dependencies : {};

				expect(structKeyExists(deps, "wheels-authenticateThis")).toBeFalse(
					"box.json must not declare 'wheels-authenticateThis' as a ForgeBox dependency — the slug is unpublished, so `box install wheels-starter-app` 404s and aborts (##3181). The plugin ships bundled under plugins/authenticateThis/ instead."
				);
			});

			it("keeps wheels-core as the only ForgeBox dependency", () => {
				var manifest = deserializeJSON(fileRead(boxJsonPath));
				var deps = structKeyExists(manifest, "dependencies") ? manifest.dependencies : {};

				expect(structKeyExists(deps, "wheels-core")).toBeTrue(
					"box.json must still depend on the published wheels-core package."
				);
				expect(structCount(deps)).toBe(1,
					"wheels-core must be the starter app's only ForgeBox dependency; auth ships bundled under plugins/ and flash lives in core (##3181)."
				);
			});

			it("does not leave a stale installPaths entry for the removed dependency", () => {
				var manifest = deserializeJSON(fileRead(boxJsonPath));
				var installPaths = structKeyExists(manifest, "installPaths") ? manifest.installPaths : {};

				expect(structKeyExists(installPaths, "wheels-authenticateThis")).toBeFalse(
					"box.json installPaths must not reference 'wheels-authenticateThis' once the dependency is dropped — every installPaths key should correspond to a declared dependency (##3181)."
				);
			});

			it("bundles the authenticateThis plugin so the app boots without a ForgeBox fetch", () => {
				expect(fileExists(pluginsDir & "/authenticateThis/authenticateThis.cfc")).toBeTrue(
					"plugins/authenticateThis/authenticateThis.cfc must ship in the artifact so app/models/User.cfc's authenticateThis() call resolves without the unpublished ForgeBox dependency (##3181)."
				);
			});

		});

	}

}
