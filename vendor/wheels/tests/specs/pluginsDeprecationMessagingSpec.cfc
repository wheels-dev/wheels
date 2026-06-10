// Review follow-ups di-packages:7, upgrade-docs:2 and upgrade-docs:3: keep the
// routine plugin-load trace out of the security log, keep the deprecation
// messages pointing at live versioned guide URLs, and keep the remediation text
// aligned with the shipped package system (packages install into vendor/ —
// there is no packages/ staging directory).
component extends="wheels.WheelsTest" {

	function run() {

		describe("Plugins.cfc deprecation messaging and log routing", () => {

			it("routes the plugin-load trace to the standard wheels log, not the security log", () => {
				var source = FileRead(ExpandPath("/wheels/Plugins.cfc"));
				expect(FindNoCase("wheels_security", source) GT 0).toBeFalse(
					"Plugins.cfc must not write routine plugin-load entries to the "
					& "wheels_security log — startup noise pollutes the security "
					& "audit trail. Use file=""wheels"" like PackageLoader.cfc "
					& "(di-packages:7)."
				);
			});

			it("does not link to dead documentation URLs", () => {
				var source = FileRead(ExpandPath("/wheels/Plugins.cfc"));
				expect(FindNoCase("guides.wheels.dev/docs/", source) GT 0).toBeFalse(
					"Plugins.cfc must not link unversioned guides.wheels.dev/docs/ "
					& "paths — guides URLs are versioned (e.g. "
					& "guides.wheels.dev/v4-0-0/...) and the unversioned forms 404 "
					& "(upgrade-docs:2)."
				);
				expect(FindNoCase("wheels.dev/docs/packages", source) GT 0).toBeFalse(
					"Plugins.cfc must not link wheels.dev/docs/packages — the live "
					& "page is guides.wheels.dev/v4-0-0/digging-deeper/packages/ "
					& "(upgrade-docs:2)."
				);
				// Positive guard: at least one live versioned guide URL remains.
				expect(FindNoCase("https://guides.wheels.dev/v4-0-0/", source) GT 0).toBeTrue(
					"Plugins.cfc deprecation messages must point at live versioned "
					& "guide URLs (upgrade-docs:2)."
				);
			});

			it("does not describe the abandoned packages/ staging design or use future tense", () => {
				var source = FileRead(ExpandPath("/wheels/Plugins.cfc"));
				expect(FindNoCase("Move them to packages/", source) GT 0).toBeFalse(
					"Plugins.cfc must not tell users to move plugins to a packages/ "
					& "staging directory — the shipped loader discovers packages "
					& "from vendor/ only (upgrade-docs:3)."
				);
				expect(FindNoCase("will be deprecated", source) GT 0).toBeFalse(
					"Plugins.cfc deprecation text must use present tense — plugins "
					& "are deprecated as of Wheels 4.0, not at some future point "
					& "(upgrade-docs:3)."
				);
			});

		});

	}

}
