// GH##2630: guard the PackageLoader / Plugins load-trace WriteLog calls against re-escaping #var# as ##var##.
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

				// Positive assertions: lock the single-pound form in place so a
				// future refactor that silently removes the log line fails the
				// test instead of staying green.
				expect(FindNoCase("'##arguments.dirName##'", source) GT 0).toBeTrue(
					"PackageLoader.cfc must retain single-pound interpolation "
					& "around arguments.dirName in WriteLog text — see issue ##2630."
				);

				expect(FindNoCase("from ##arguments.pkgDir##", source) GT 0).toBeTrue(
					"PackageLoader.cfc must retain single-pound interpolation "
					& "around arguments.pkgDir in WriteLog text — see issue ##2630."
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

				// Positive assertions: see PackageLoader block above for rationale.
				expect(FindNoCase("'##local.pluginKey##'", source) GT 0).toBeTrue(
					"Plugins.cfc must retain single-pound interpolation around "
					& "local.pluginKey in WriteLog text — see issue ##2630."
				);

				expect(FindNoCase("from ##local.pluginValue.folderPath##", source) GT 0).toBeTrue(
					"Plugins.cfc must retain single-pound interpolation around "
					& "local.pluginValue.folderPath in WriteLog text — see issue ##2630."
				);
			});

		});
	}

}
