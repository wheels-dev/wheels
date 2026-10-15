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
				// The host application's own parser (public/Application.cfc's
				// loadEnvFile), run on a fixture that ships with this suite, so the
				// spec passes the same way in the framework repo and inside an app
				// built with `wheels new` (whose .env has no spec keys). "Application"
				// resolves to the app's webroot Application.cfc: there is none in
				// this spec's own directory.
				var hostApp = CreateObject("component", "Application");
				prepareMock(hostApp);
				makePublic(hostApp, "loadEnvFile");
				var parsedEnv = {};
				var fixture = ExpandPath("/wheels/tests/_assets/env/numeric-one.env");
				expect(FileExists(fixture), "fixture missing: #fixture#").toBeTrue();
				hostApp.loadEnvFile(fixture, parsedEnv);

				expect(parsedEnv).toHaveKey("WHEELS_SPEC_NUMERIC_ONE");
				var parsed = parsedEnv["WHEELS_SPEC_NUMERIC_ONE"];
				// Compare(), not toBe(): TestBox's toBe() uses CFML `==`, which is
				// the very trap under test — with the coercing parser this value is
				// the BOOLEAN true, and `"true" == "1.0"` is still true numerically,
				// so a toBe("1.0") assertion passes and hides the bug. Measured on
				// RustCFML 2026-09-21: that assertion passed while IsNumeric below
				// failed. Compare() is a string comparison and cannot be fooled.
				expect(Compare(ToString(parsed), "1.0"), "the value itself must survive").toBe(0);
				expect(IsNumeric(parsed), "and still be usable as a number").toBeTrue();
				expect(Val(parsed)).toBe(1);
				// A real boolean still becomes one.
				expect(IsBoolean(parsedEnv["WHEELS_SPEC_TRUE"]) && parsedEnv["WHEELS_SPEC_TRUE"]).toBeTrue();
			});

		});

		describe(".env value types beyond the numeric-1 case", () => {

			it("pins the parser's current coercion for each value shape", () => {
				// Same host-Application pattern as the numeric-1 spec above:
				// exercise public/Application.cfc's real loadEnvFile() against a
				// fixture that ships with the suite.
				var hostApp = CreateObject("component", "Application");
				prepareMock(hostApp);
				makePublic(hostApp, "loadEnvFile");
				var parsedEnv = {};
				var fixture = ExpandPath("/wheels/tests/_assets/env/value-types.env");
				expect(FileExists(fixture), "fixture missing").toBeTrue();
				hostApp.loadEnvFile(fixture, parsedEnv);

				// TRUE / False in any case become booleans.
				expect(IsBoolean(parsedEnv["WHEELS_SPEC_TRUE_UPPER"]), "TRUE must coerce to a boolean").toBeTrue();
				expect(parsedEnv["WHEELS_SPEC_TRUE_UPPER"]).toBeTrue();
				expect(Compare(ToString(parsedEnv["WHEELS_SPEC_TRUE_UPPER"]), "TRUE") != 0, "TRUE must not survive as the string TRUE").toBeTrue();
				expect(IsBoolean(parsedEnv["WHEELS_SPEC_FALSE_MIXED"]), "False must coerce to a boolean").toBeTrue();
				expect(parsedEnv["WHEELS_SPEC_FALSE_MIXED"]).toBeFalse();
				expect(Compare(ToString(parsedEnv["WHEELS_SPEC_FALSE_MIXED"]), "False") != 0, "False must not survive as the string False").toBeTrue();

				// 0 is the NUMBER zero, never the boolean false. IsBoolean() is TRUE
				// for any number on these engines, so "not coerced" is proved by the
				// STRING value: a coerced boolean stringifies as true/false (Adobe:
				// YES/NO), never as "0".
				expect(IsNumeric(parsedEnv["WHEELS_SPEC_ZERO"]), "0 must stay numeric").toBeTrue();
				expect(Compare(ToString(parsedEnv["WHEELS_SPEC_ZERO"]), "0"), "0 must stay the number zero, not the boolean false").toBe(0);
				expect(parsedEnv["WHEELS_SPEC_ZERO"]).toBe(0);

				// 42 becomes a number.
				expect(IsNumeric(parsedEnv["WHEELS_SPEC_INT"]), "42 must stay numeric").toBeTrue();
				expect(parsedEnv["WHEELS_SPEC_INT"]).toBe(42);

				// Decimals are deliberately left as strings. Again, prove "not
				// coerced" by the string value, not by IsBoolean().
				expect(IsNumeric(parsedEnv["WHEELS_SPEC_DECIMAL"]), "1.5 still reads as numeric").toBeTrue();
				expect(Compare(ToString(parsedEnv["WHEELS_SPEC_DECIMAL"]), "1.5"), "1.5 must survive as the string 1.5").toBe(0);

				// yes / no stay strings, never booleans. Compare() to the original
				// text is the proof; IsBoolean("yes"/"no") is TRUE on these engines.
				expect(Compare(ToString(parsedEnv["WHEELS_SPEC_YES"]), "yes"), "yes must survive verbatim").toBe(0);
				expect(Compare(ToString(parsedEnv["WHEELS_SPEC_NO"]), "no"), "no must survive verbatim").toBe(0);

				// Double quotes are stripped BEFORE coercion, so a quoted "True"
				// becomes a boolean — the capital T proves it was converted, not
				// merely kept as the string it was written as.
				expect(IsBoolean(parsedEnv["WHEELS_SPEC_DQUOTED_TRUE"]), 'a quoted "True" must coerce to a boolean').toBeTrue();
				expect(parsedEnv["WHEELS_SPEC_DQUOTED_TRUE"]).toBeTrue();
				expect(Compare(ToString(parsedEnv["WHEELS_SPEC_DQUOTED_TRUE"]), "True") != 0, 'a quoted "True" must be converted, not kept as the string True').toBeTrue();

				// Single quotes are stripped and the inner text survives verbatim.
				expect(Compare(ToString(parsedEnv["WHEELS_SPEC_SQUOTED_SPACE"]), "hello world"), "single quotes must be stripped").toBe(0);

				// Only the FIRST = splits key and value.
				expect(Compare(ToString(parsedEnv["WHEELS_SPEC_EQUALS"]), "a=b"), "everything after the first = is the value").toBe(0);

				// An empty value is an empty string, not a boolean and not a missing key.
				expect(StructKeyExists(parsedEnv, "WHEELS_SPEC_EMPTY"), "an empty value still creates the key").toBeTrue();
				expect(IsBoolean(parsedEnv["WHEELS_SPEC_EMPTY"]), "an empty value must not coerce to a boolean").toBeFalse();
				expect(Compare(ToString(parsedEnv["WHEELS_SPEC_EMPTY"]), ""), "an empty value must stay empty").toBe(0);

				// Comment lines and lines without = are ignored entirely.
				expect(StructKeyExists(parsedEnv, "WHEELS_SPEC_COMMENT"), "comment lines must be ignored").toBeFalse();
				expect(StructKeyExists(parsedEnv, "WHEELS_SPEC_NO_EQUALS"), "lines without = must be ignored").toBeFalse();
			});

		});

		describe(".env edge values: lone quotes and integer-only coercion", () => {

			it("keeps plain-integer coercion and survives lone quotes", () => {
				// Same host-Application pattern as the blocks above.
				var hostApp = CreateObject("component", "Application");
				prepareMock(hostApp);
				makePublic(hostApp, "loadEnvFile");
				var parsedEnv = {};
				var fixture = ExpandPath("/wheels/tests/_assets/env/edge-values.env");
				expect(FileExists(fixture), "fixture missing").toBeTrue();
				hostApp.loadEnvFile(fixture, parsedEnv);

				// Only plain integers coerce: a leading zero, scientific notation
				// and a leading plus all stay strings.
				expect(Compare(ToString(parsedEnv["WHEELS_SPEC_LEADING_ZERO"]), "007"), "007 must survive as the string 007").toBe(0);
				expect(Compare(ToString(parsedEnv["WHEELS_SPEC_SCI"]), "1e3"), "1e3 must survive as the string 1e3").toBe(0);
				expect(Compare(ToString(parsedEnv["WHEELS_SPEC_PLUS"]), "+5"), "+5 must survive as the string +5").toBe(0);

				// A plain negative integer still becomes a number.
				expect(Compare(ToString(parsedEnv["WHEELS_SPEC_NEGATIVE"]), "-5"), "-5 must survive as the string -5").toBe(0);
				expect(parsedEnv["WHEELS_SPEC_NEGATIVE"]).toBe(-5);

				// A lone quote is a 1-character string and must not be sliced away.
				expect(Len(parsedEnv["WHEELS_SPEC_LONE_SQUOTE"])).toBe(1);
				expect(Compare(ToString(parsedEnv["WHEELS_SPEC_LONE_SQUOTE"]), "'"), "a lone single quote must survive").toBe(0);
				expect(Len(parsedEnv["WHEELS_SPEC_LONE_DQUOTE"])).toBe(1);
				expect(Compare(ToString(parsedEnv["WHEELS_SPEC_LONE_DQUOTE"]), Chr(34)), "a lone double quote must survive").toBe(0);

				// Parsing continues after the lone-quote lines.
				expect(Compare(ToString(parsedEnv["WHEELS_SPEC_AFTER_LONE"]), "still-parsed"), "parsing must continue after a lone quote").toBe(0);
			});

		});

		describe("No copy of the parser may reintroduce the coercing test", () => {

			it("every .env/settings parser compares booleans as strings", () => {
				$requireRepoPath("cli/lucli/templates/app/public/Application.cfc");
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

			it("every Application.cfc parses numbers with the integer-only regex", () => {
				$requireRepoPath("cli/lucli/templates/app/public/Application.cfc");
				// Same path resolution as the guard above.
				var specPath = Replace(GetCurrentTemplatePath(), "\", "/", "all");
				var marker = "/vendor/wheels/tests/specs/global/";
				var markerPos = Find(marker, specPath);
				expect(markerPos, "this spec must live under #marker# for the parser paths to resolve").toBeGT(0);
				var root = Left(specPath, markerPos) & "/";

				// The four `public/Application.cfc` entries of the parsers array above.
				var parsers = [
					"public/Application.cfc",
					"cli/lucli/templates/app/public/Application.cfc",
					"examples/starter-app/public/Application.cfc",
					"examples/tweet/public/Application.cfc"
				];

				for (var relativePath in parsers) {
					var parserPath = root & relativePath;
					expect(FileExists(parserPath), "parser '#relativePath#' must exist — move it in this spec too").toBeTrue();
					var source = FileRead(parserPath, "utf-8");
					expect(
						source,
						"'#relativePath#' must coerce only plain integers (^-?(0|[1-9][0-9]*)$)"
					).toInclude("^-?(0|[1-9][0-9]*)$");
					expect(
						source,
						"'#relativePath#' still uses the old isNumeric/find('.') check, which mangles 007 and 1e3"
					).notToInclude('isNumeric(local.value) && !find(".", local.value)');
				}
			});

		});

	}

}
