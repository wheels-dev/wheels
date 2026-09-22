component extends="wheels.WheelsTest" {

	/**
	 * PACKAGE ENTRY-POINT RESOLUTION (PackageLoader##$resolveEntryPointCfc).
	 *
	 * The regression this pins: the rule used to be "<dirName>.cfc, else the
	 * FIRST *.cfc from DirectoryList()", and that listing order is filesystem
	 * dependent. Measured 2026-09-21 with wheels-sentry installed, Lucee
	 * returned ["SentryClient.cfc", "Sentry.cfc"] — even with sort="asc" — so the
	 * loader instantiated the TRANSPORT class, whose init() requires arguments,
	 * and the package died at boot naming none of the real causes:
	 *
	 *     The parameter [release] to function [init] is required but was not passed in.
	 *
	 * A package with two root CFCs was a coin flip; when the wrong CFC happened
	 * to have a no-argument init() the package loaded and silently did nothing.
	 * The fixtures below assert WHICH CFC was instantiated (each root CFC
	 * answers $entryMarker() differently), not merely that something loaded.
	 *
	 * Structure note: the loader is constructed INSIDE each `it` and beforeEach
	 * lives inside each describe — the same shape as the sibling
	 * PackageLoaderSpec, because a helper closure declared at run() scope cannot
	 * see what beforeEach assigns.
	 */
	function run() {

		describe("Package entry point", () => {

			beforeEach(() => {
				fixturesPath = ExpandPath("/wheels/tests/_assets/packages_entrypoint");
				componentPrefix = "wheels.tests._assets.packages_entrypoint";
			});

			it("honours an explicit manifest `main` when the root holds several CFCs", () => {
				var loader = new wheels.PackageLoader(vendorPath = fixturesPath, componentPrefix = componentPrefix);
				expect(loader.getPackages()).toHaveKey("maindeclared", "a package that declares `main` must load");
				expect(loader.getPackages()["maindeclared"].$entryMarker()).toBe(
					"maindeclared-entry",
					"`main` names the entry point — never the first CFC the directory listing happens to return"
				);
			});

			it("derives the entry point from the package NAME (wheels-naming-rules -> NamingRules.cfc)", () => {
				var loader = new wheels.PackageLoader(vendorPath = fixturesPath, componentPrefix = componentPrefix);
				expect(loader.getPackages()).toHaveKey("namingrules");
				expect(loader.getPackages()["namingrules"].$entryMarker()).toBe("namingrules-entry");
			});

			it("keeps working for a package with a single, differently-named root CFC", () => {
				var loader = new wheels.PackageLoader(vendorPath = fixturesPath, componentPrefix = componentPrefix);
				expect(loader.getPackages()).toHaveKey("solocfc");
				expect(loader.getPackages()["solocfc"].$entryMarker()).toBe("solocfc-entry");
			});

			it("REFUSES to guess between two ambiguous root CFCs, and names the candidates", () => {
				var loader = new wheels.PackageLoader(vendorPath = fixturesPath, componentPrefix = componentPrefix);
				expect(
					loader.getPackages()
				).notToHaveKey("ambiguous", "guessing is how a package loads while silently doing nothing");

				var record = {};
				for (var f in loader.getFailedPackages()) {
					if (f.name == "ambiguous") record = f;
				}
				expect(StructCount(record)).toBeTrue("the ambiguity must be reported");
				expect(record.detail).toInclude("Alpha");
				expect(record.detail).toInclude("Beta");
				expect(record.detail).toInclude("main");
			});

			it("treats a `main` that does not exist as an authoring error, never as a reason to fall back", () => {
				var loader = new wheels.PackageLoader(vendorPath = fixturesPath, componentPrefix = componentPrefix);
				expect(loader.getPackages()).notToHaveKey("mainmissing");

				var record = {};
				for (var f in loader.getFailedPackages()) {
					if (f.name == "mainmissing") record = f;
				}
				expect(StructCount(record)).toBeTrue("a missing declared entry point must be reported");
				expect(record.error).toInclude("Ghost");
				expect(record.detail).toInclude("Real", "the error must list what IS there");
			});

		});

		describe("Package mapping diagnostics", () => {

			beforeEach(() => {
				diagnosticFixturesPath = ExpandPath("/wheels/tests/_assets/packages_entrypoint");
				diagnosticPrefix = "wheels.tests._assets.packages_entrypoint";
			});

			it("reports every registered alias the engine does not actually resolve — and nothing else", () => {
				var loader = new wheels.PackageLoader(
					vendorPath = diagnosticFixturesPath,
					componentPrefix = diagnosticPrefix
				);
				var registered = loader.getPackageMappings();
				var unresolved = loader.getUnresolvedMappings();
				expect(StructCount(registered)).toBeGT(0, "fixtures must register at least one alias");

				// The contract: every registered alias is EITHER resolvable through
				// the engine OR listed as unresolved. An alias may never vanish from
				// both — that is the silent "could not find component" this accessor
				// exists to surface (GH issue 2712 follow-up).
				for (var alias in registered) {
					var resolved = ExpandPath("/" & Replace(alias, ".", "/", "all") & "/");
					var want = ReReplace(registered[alias], "[\\/]+$", "");
					var got = ReReplace(resolved, "[\\/]+$", "");
					if (Compare(LCase(got), LCase(want)) == 0) {
						expect(unresolved).notToHaveKey(alias, "alias '#alias#' resolves, so it must not be reported unresolved");
					} else {
						expect(unresolved).toHaveKey(alias, "alias '#alias#' does not resolve and must be reported");
					}
				}
			});

		});

	}

}
