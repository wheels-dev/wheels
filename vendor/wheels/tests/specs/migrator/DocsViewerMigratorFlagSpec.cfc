component extends="wheels.WheelsTest" {

	function run() {

		describe("Docs viewer migrator feature flag", () => {

			// Convention guard for the embedded API docs viewer.
			// vendor/wheels/public/docs/core.cfm appends the migrator /
			// migration / tabledefinition documentation scopes and, in doing
			// so, dereferences application.wheels.migrator — an object that
			// only exists when enableMigratorComponent is true
			// (events/onapplicationstart.cfc). The block was originally gated
			// on enablePluginsComponent (the wrong flag), so
			// enablePluginsComponent=false + enableMigratorComponent=true
			// silently hid the migrator API reference, and the inverse
			// combination errored the page by dereferencing a non-existent
			// application.wheels.migrator.
			it("gates the migrator documentation scopes on enableMigratorComponent", () => {
				var source = FileRead(ExpandPath("/wheels/public/docs/core.cfm"));

				// Anchor on the dereference of application.wheels.migrator —
				// the statement that requires the migrator component to exist.
				var anchor = Find("application.wheels.migrator", source);
				expect(anchor).toBeGT(0, "core.cfm must append the migrator scope to the documentation set.");

				// Examine the ~200 chars before the anchor: wide enough to
				// capture the guarding if-statement, narrow enough not to
				// reach the unrelated enablePluginsComponent block at the top
				// of the file.
				var windowStart = Max(anchor - 200, 1);
				var guardWindow = Mid(source, windowStart, anchor - windowStart);

				expect(guardWindow).toInclude(
					"enableMigratorComponent",
					"The migrator documentation block in core.cfm must be gated on enableMigratorComponent — application.wheels.migrator only exists when that flag is true."
				);
				expect(guardWindow).notToInclude(
					"enablePluginsComponent",
					"The migrator documentation block in core.cfm must not be gated on enablePluginsComponent — that is the wrong feature flag for the migrator scope."
				);
			});

		});

	}

}
