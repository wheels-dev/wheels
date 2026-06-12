component extends="wheels.WheelsTest" {

	// Regression coverage for issue #3178: release stamping clobbers
	// PackageLoader's "@build.version@" dev-build sentinel.
	//
	// tools/build/scripts/prepare-core.sh does a GLOBAL
	// `sed s/@build.version@/<version>/g` over every .cfc in the artifact. If a
	// literal "@build.version@" sits inside $normalizeWheelsVersion()'s guard,
	// that occurrence is rewritten too — on a shipped 4.0.3 build the guard
	// becomes `local.raw == "4.0.3"`, so the real runtime version normalises to
	// "0.0.0" and $isCompatibleVersion() skips enforcement for EVERY package.
	// Net effect: wheelsVersion constraints are silently disabled on every
	// released build. Detection must be STRUCTURAL (prefix `@build.` + suffix
	// `@`), mirroring BuildInfo.cfc::isDev(), so global stamping can't break it.

	function run() {

		describe("PackageLoader release-stamp safety", () => {

			describe("dev-build detection is sed-safe (structural, not literal)", () => {

				it("source contains zero '@build.version@' sentinels (regression guard)", () => {
					// prepare-core.sh's line-oriented sed does not respect CFML
					// syntax: a "@build.version@" literal anywhere in this file —
					// in a comparison OR a comment — is rewritten at build time.
					// $normalizeWheelsVersion() must therefore detect dev builds
					// by the prefix/suffix shape (Left(raw, 7) == "@build." &&
					// Right(raw, 1) == "@"), never by literal equality. Unlike
					// BuildInfo.cfc (which legitimately seeds the placeholder into
					// its `version:` field), PackageLoader receives the runtime
					// version as a constructor arg, so the sentinel should appear
					// nowhere in this source at all.
					var src = FileRead(ExpandPath("/wheels/PackageLoader.cfc"));
					var token = "@" & "build.version" & "@"; // split so this file isn't itself a sentinel
					var occurrences = (Len(src) - Len(Replace(src, token, "", "all"))) / Len(token);
					expect(occurrences).toBe(
						0,
						"PackageLoader.cfc must contain zero '" & token & "' literals (found "
							& occurrences & "). Any occurrence is rewritten by prepare-core.sh's "
							& "global sed and disables wheelsVersion enforcement on every released build. "
							& "Use the structural Left/Right check that BuildInfo.cfc::isDev() uses."
					);
				});

			});

			describe("a stamped release runtime still enforces wheelsVersion constraints", () => {

				it("rejects an incompatible package when the runtime reports a concrete release version", () => {
					// This is exactly the state a shipped artifact is in: a
					// concrete version string like "4.0.3". A package pinned to
					// ">=99.0" must NOT load. (Before the fix this passes on the
					// unstamped source tree but breaks once sed turns the guard
					// into `local.raw == "4.0.3"`; the structural check keeps it
					// honest in both worlds — and the source-scan guard above is
					// what fails on the unpatched tree.)
					var loader = new wheels.PackageLoader(
						vendorPath = ExpandPath("/wheels/tests/_assets/packages"),
						componentPrefix = "wheels.tests._assets.packages",
						wheelsVersion = "4.0.3"
					);
					var pkgs = loader.getPackages();
					expect(pkgs).notToHaveKey("incompatversion");
					expect(pkgs).toHaveKey("compatversion");
				});

			});

			describe("a placeholder-shaped runtime stays permissive in local dev", () => {

				it("loads strictly-pinned packages when the version has the unstamped placeholder shape", () => {
					var loader = new wheels.PackageLoader(
						vendorPath = ExpandPath("/wheels/tests/_assets/packages"),
						componentPrefix = "wheels.tests._assets.packages",
						wheelsVersion = "@build.version@"
					);
					var pkgs = loader.getPackages();
					// Even the ">=99.0" fixture loads on an unstamped dev build.
					expect(pkgs).toHaveKey("incompatversion");
					expect(pkgs).toHaveKey("compatversion");
				});

			});

		});

	}

}
