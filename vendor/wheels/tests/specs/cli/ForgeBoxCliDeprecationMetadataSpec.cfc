/**
 * Regression / posture guard for issue #3184.
 *
 * The legacy CommandBox `wheels-cli` module (cli/src/) is published to
 * ForgeBox on every stable release via tools/build/scripts/prepare-cli.sh.
 * The registry-visible metadata shipped with that artifact —
 * tools/build/cli/box.json (shortDescription / description / instructions /
 * name) and tools/build/cli/README.md — read as the *supported* CLI ("The
 * official Command Line Interface for the wheels framework", "Install via
 * CommandBox by typing 'box install wheels-cli'"), even though the module is
 * deprecated in favour of the LuCLI `wheels` binary and slated for removal in
 * v5.0 (#2227, #2634). The in-CLI deprecation banners fire on only two
 * sub-commands; a ForgeBox browser sees no deprecation signal before running
 * `box install wheels-cli`.
 *
 * Cross-framework research (issue comment wheels-bot:research:3184) found the
 * near-unanimous pattern: deprecate in place with a soft, non-breaking,
 * registry-page-visible signal that names the successor — never unpublish.
 * ForgeBox has no first-class soft-deprecate flag, so the only pre-install
 * lever is the box.json description/instructions text + README (the issue's
 * Option 1). This spec pins that posture so the registry metadata cannot
 * drift back to implying parity with the supported binary.
 *
 * Structural assertion against the metadata source — invoking the release
 * pipeline from a test would require a writable build context and release
 * inputs. Reading the committed template files mirrors the guard pattern used
 * by buildArtifactLicenseSpec.cfc, buildInfoSpec.cfc, and
 * LegacyUpgradeDeprecationSpec.cfc.
 *
 * The pipeline version-freeze half of the issue (decouple the CLI version
 * from @build.version@ in prepare-cli.sh) is a maintainer strategy call and
 * is intentionally NOT asserted here — see the PR body.
 */
component extends="wheels.WheelsTest" {

	function run() {

		// Shared context for nested it() closures (Adobe CF closures cannot
		// reliably read plain outer `var` locals — see CLAUDE.md). expandPath
		// ("/wheels") resolves to vendor/wheels; the repo root is two levels up.
		var ctx = {
			repoRoot: expandPath("/wheels/../.."),
			boxPath: expandPath("/wheels/../..") & "/tools/build/cli/box.json",
			readmePath: expandPath("/wheels/../..") & "/tools/build/cli/README.md",
			// Canonical successor pointers — must match the existing in-CLI
			// banner in cli/src/commands/wheels/upgrade.cfc so README + box.json
			// + banners all agree.
			brewPointer: "brew install wheels-dev/wheels/wheels",
			installGuide: "guides.wheels.dev/v4-0-0/command-line-tools/installation"
		};

		describe("tools/build/cli/box.json — ForgeBox registry metadata (issue ##3184)", () => {

			it("the box.json template exists", () => {
				expect(fileExists(ctx.boxPath)).toBeTrue("Missing file: " & ctx.boxPath);
			});

			it("leads the registry display name with the deprecation", () => {
				var meta = deserializeJSON(fileRead(ctx.boxPath));
				expect(findNoCase("DEPRECATED", meta.name) > 0).toBeTrue(
					"box.json `name` should signal the module is deprecated so the ForgeBox listing title is unambiguous."
				);
			});

			it("leads shortDescription with DEPRECATED and points at the supported CLI", () => {
				var meta = deserializeJSON(fileRead(ctx.boxPath));
				expect(reFindNoCase("^\s*DEPRECATED", meta.shortDescription) > 0).toBeTrue(
					"box.json `shortDescription` is the primary pre-install summary on the ForgeBox page — it must lead with DEPRECATED."
				);
				expect(findNoCase(ctx.brewPointer, meta.shortDescription) > 0).toBeTrue(
					"box.json `shortDescription` should name the supported CLI install (`" & ctx.brewPointer & "`)."
				);
			});

			it("describes the deprecation, the v5.0 removal, and the successor", () => {
				var meta = deserializeJSON(fileRead(ctx.boxPath));
				expect(findNoCase("DEPRECATED", meta.description) > 0).toBeTrue(
					"box.json `description` must lead with the deprecation, not read as the supported CLI."
				);
				expect(findNoCase("5.0", meta.description) > 0).toBeTrue(
					"box.json `description` should state the module is scheduled for removal in v5.0."
				);
				expect(findNoCase(ctx.brewPointer, meta.description) > 0).toBeTrue(
					"box.json `description` should point at the supported `wheels` binary (`" & ctx.brewPointer & "`)."
				);
				expect(findNoCase(ctx.installGuide, meta.description) > 0).toBeTrue(
					"box.json `description` should link the canonical v4 CLI install guide."
				);
				// The pre-fix copy framed it as the supported CLI; that framing
				// must be gone.
				expect(findNoCase("providing code generation, database migrations, testing, and development tools", meta.description) == 0).toBeTrue(
					"box.json `description` still reads as the supported CLI — replace the feature-parity blurb with the deprecation notice."
				);
			});

			it("leads instructions with DEPRECATED rather than an install command", () => {
				var meta = deserializeJSON(fileRead(ctx.boxPath));
				expect(reFindNoCase("^\s*DEPRECATED", meta.instructions) > 0).toBeTrue(
					"box.json `instructions` must lead with DEPRECATED, not `Install via CommandBox by typing 'box install wheels-cli'`."
				);
			});

		});

		describe("tools/build/cli/README.md — ForgeBox README (issue ##3184)", () => {

			it("the README template exists", () => {
				expect(fileExists(ctx.readmePath)).toBeTrue("Missing file: " & ctx.readmePath);
			});

			it("opens with a deprecation banner blockquote", () => {
				var content = fileRead(ctx.readmePath);
				expect(reFindNoCase("(?m)^>\s*\*\*DEPRECATED", content) > 0).toBeTrue(
					"README.md should open with a markdown blockquote deprecation banner (`> **DEPRECATED ...**`) so ForgeBox renders it above the fold."
				);
			});

			it("no longer advertises itself as the official CLI", () => {
				var content = fileRead(ctx.readmePath);
				expect(findNoCase("The official Command Line Interface for the wheels framework", content) == 0).toBeTrue(
					"README.md still calls the legacy module the official CLI — remove that framing."
				);
			});

			it("points readers at the supported Wheels CLI", () => {
				var content = fileRead(ctx.readmePath);
				expect(findNoCase(ctx.brewPointer, content) > 0).toBeTrue(
					"README.md should point readers at the supported CLI install (`" & ctx.brewPointer & "`)."
				);
				expect(findNoCase(ctx.installGuide, content) > 0).toBeTrue(
					"README.md should link the canonical v4 CLI install guide."
				);
			});

		});

	}

}
