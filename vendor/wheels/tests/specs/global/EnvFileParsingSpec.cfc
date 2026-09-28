component extends="wheels.WheelsTest" {

	/**
	 * ENV / SETTINGS BOOLEAN COERCION — the numeric-1 trap.
	 *
	 * THE BUG. Every `.env` parser in the project tested booleans with `==`:
	 *
	 *     if (local.value == "true" || local.value == "false") {
	 *         local.value = (local.value == "true");
	 *
	 * Those operands compare NUMERICALLY wherever a string can be read as a
	 * number, so `"1.0" == "true"` is TRUE (1 == 1) and `"1" == "true"` likewise
	 * — while `"0.5" == "true"` is FALSE. Every value of numeric 1 therefore
	 * arrived as the BOOLEAN true, and code asking for a number either
	 * type-errored or silently took a fallback. Measured in a production
	 * application (2026-09-21): a session-replay sample rate of `1.0` rendered
	 * as `0.1`, so the feature simply never ran and nothing said why.
	 *
	 * The spec below pins the coercion on every engine in the matrix — Lucee 7,
	 * Adobe 2023, BoxLang and RustCFML all agree on it (verified 2026-09-21).
	 *
	 * Seven copies of that parser existed — four `public/Application.cfc` files
	 * (the generator template, this repo's own test app, two bundled examples)
	 * and three CLI commands (`config dump`, `get settings`, `reload`). All of
	 * them now compare as STRINGS, and this spec pins both the trap and the
	 * fact that no copy may go back.
	 */
	function run() {

		describe("Boolean coercion (the engine trap this pins)", () => {

			it('documents that == compares "1.0" and "true" NUMERICALLY', () => {
				expect("1.0" == "true", "this is why the old test was wrong").toBeTrue();
				expect("1" == "true").toBeTrue();
				expect("0.5" == "true", "and why it hid for so long: 0.5 does not coerce").toBeFalse();
				expect("0" == "false").toBeTrue();
				expect(Compare("1.0", "true"), "Compare() is a STRING comparison and keeps them apart").toBeLT(0);
				expect(Compare("true", "true")).toBe(0);
			});

		});

		describe(".env parsing through this app's real Application.cfc", () => {

			it("keeps a numeric 1 as a value, not as the boolean true", () => {
				// WHEELS_SPEC_NUMERIC_ONE=1.0 lives in the repo's tracked .env, and
				// this application's Application.cfc parsed it on boot — so this is
				// the real parser, not a copy of its logic.
				expect(application.env).toHaveKey("WHEELS_SPEC_NUMERIC_ONE");
				var parsed = application.env["WHEELS_SPEC_NUMERIC_ONE"];
				// Compare(), not toBe(): TestBox's toBe() uses CFML `==`, which is
				// the very trap under test — with the coercing parser this value is
				// the BOOLEAN true, and `"true" == "1.0"` is still true numerically,
				// so a toBe("1.0") assertion passes and hides the bug. Measured on
				// RustCFML 2026-09-21: that assertion passed while IsNumeric below
				// failed. Compare() is a string comparison and cannot be fooled.
				expect(Compare(ToString(parsed), "1.0"), "the value itself must survive").toBe(0);
				expect(IsNumeric(parsed), "and still be usable as a number").toBeTrue();
				expect(Val(parsed)).toBe(1);
			});

		});

		describe("No copy of the parser may reintroduce the coercing test", () => {

			it("every .env/settings parser compares booleans as strings", () => {
				// Derived from THIS spec's own path so a worktree or a CI runner
				// resolves the same files:
				//   <root>/vendor/wheels/tests/specs/global/EnvFileParsingSpec.cfc
				var specPath = Replace(GetCurrentTemplatePath(), "\", "/", "all");
				var marker = "/vendor/wheels/tests/specs/global/";
				var markerPos = Find(marker, specPath);
				expect(markerPos, "this spec must live under #marker# for the parser paths to resolve").toBeGT(0);
				var root = Left(specPath, markerPos) & "/";

				var parsers = [
					"public/Application.cfc",
					"cli/lucli/templates/app/public/Application.cfc",
					"examples/starter-app/public/Application.cfc",
					"examples/tweet/public/Application.cfc",
					"cli/src/commands/wheels/config/dump.cfc",
					"cli/src/commands/wheels/get/settings.cfc",
					"cli/src/commands/wheels/reload.cfc"
				];

				for (var relativePath in parsers) {
					// NOT ExpandPath(): these are already absolute filesystem paths,
					// and Adobe 2023 and RustCFML resolve a leading-slash path against
					// the WEBROOT instead of the filesystem — measured 2026-09-21,
					// root=/wheels-test-suite/ produced
					// ExpandPath("/wheels-test-suite/public/Application.cfc") =
					// "/wheels-test-suite/public/wheels-test-suite/public/Application.cfc",
					// so FileExists() was false for every parser and this guard failed
					// on those two engines while passing on Lucee and BoxLang. The
					// joined path is correct everywhere; only that extra call was wrong.
					var parserPath = root & relativePath;
					expect(FileExists(parserPath), "parser '#relativePath#' must exist — move it in this spec too").toBeTrue();
					var source = FileRead(parserPath, "utf-8");
					expect(
						source,
						"'#relativePath#' compares booleans with ==, which these engines evaluate numerically"
					).notToInclude('local.value == "true"');
					expect(
						source,
						"'#relativePath#' compares booleans with ==, which these engines evaluate numerically"
					).notToInclude('local.value == "false"');
				}
			});

		});

	}

}
