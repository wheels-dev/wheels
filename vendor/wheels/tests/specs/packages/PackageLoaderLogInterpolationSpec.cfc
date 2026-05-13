/**
 * GH#2630: the "Loading plugin..." / "Loading package..." INFO lines in
 * wheels_security.log emitted literal placeholder tokens
 * (`#arguments.dirName#`, `#local.pluginKey#`, etc.) instead of the resolved
 * values, because the `WriteLog(text="...")` strings escaped each `#` as
 * `##` — CFML's escape sequence for a literal `#`.
 *
 * This spec inspects the call sites in `vendor/wheels/PackageLoader.cfc` and
 * `vendor/wheels/Plugins.cfc` and asserts the malformed `##var##` patterns
 * are gone, so a future regression that re-introduces them fails fast
 * without anyone having to grep the log file.
 */
component extends="wheels.WheelsTest" {

	function run() {
		describe("Plugin & package loader log interpolation (##2630)", () => {

			it("does not escape pounds in the PackageLoader load-trace message", () => {
				var source = FileRead(ExpandPath("/wheels/PackageLoader.cfc"));

				// "####" in a CFML string literal evaluates to the two-char
				// sequence "##", so this search looks for the literal four
				// characters "####" in the source. That four-char sequence is
				// CFML's escape for "##" in a runtime string — the bug.
				expect(FindNoCase("####arguments.dirName####", source) GT 0).toBeFalse(
					"PackageLoader.cfc must not emit escaped pounds around "
					& "arguments.dirName in WriteLog text — CFML reads each "
					& "doubled pound as a literal pound, so the placeholder "
					& "never interpolates. Use a single pound on each side. "
					& "See issue ##2630."
				);

				expect(FindNoCase("####arguments.pkgDir####", source) GT 0).toBeFalse(
					"PackageLoader.cfc must not emit escaped pounds around "
					& "arguments.pkgDir in WriteLog text — see issue ##2630."
				);
			});

			it("does not escape pounds in the Plugins load-trace message", () => {
				var source = FileRead(ExpandPath("/wheels/Plugins.cfc"));

				expect(FindNoCase("####local.pluginKey####", source) GT 0).toBeFalse(
					"Plugins.cfc must not emit escaped pounds around "
					& "local.pluginKey in WriteLog text — CFML reads each "
					& "doubled pound as a literal pound, so the placeholder "
					& "never interpolates. Use a single pound on each side. "
					& "See issue ##2630."
				);

				expect(FindNoCase("####local.pluginValue.folderPath####", source) GT 0).toBeFalse(
					"Plugins.cfc must not emit escaped pounds around "
					& "local.pluginValue.folderPath in WriteLog text — see "
					& "issue ##2630."
				);
			});

		});
	}

}
