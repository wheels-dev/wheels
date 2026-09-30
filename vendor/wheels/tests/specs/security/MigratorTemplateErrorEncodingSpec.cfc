component extends="wheels.WheelsTest" {

	function beforeAll() {
		// Uses the demo app's snippet templates (/app/snippets/dbmigrate/) as the
		// allow-list source. Only invalid template names are exercised below, so
		// no migration file is ever written.
		variables.migrator = CreateObject("component", "wheels.Migrator").init();
	}

	function run() {
		describe("migrator template errors do not reflect attacker markup", () => {

			it("rejects an HTML/markup template name without reflecting it", () => {
				var result = variables.migrator.createMigration("ReviewCanary", "<img src=x onerror=alert(1)>");
				expect(result).toInclude("could not be found");
				// The attacker-supplied markup must never appear in the message.
				expect(FindNoCase("<img", result)).toBe(0, "raw markup must not be reflected");
				expect(FindNoCase("onerror", result)).toBe(0, "raw markup must not be reflected");
				// The message lists the real templates instead, so it stays useful.
				expect(FindNoCase("blank", result)).toBeGT(0, "should list available templates");
			});

			it("rejects a path-traversal template name", () => {
				var result = variables.migrator.createMigration("ReviewCanary", "../../../../etc/passwd");
				expect(result).toInclude("could not be found");
				expect(FindNoCase("passwd", result)).toBe(0, "must not reflect the traversal input");
			});

			it("builds the allow-list from the real snippet names", () => {
				var names = variables.migrator.$getAvailableTemplateNames();
				expect(ListFindNoCase(names, "blank")).toBeGT(0, "a real snippet must be allow-listed");
				expect(ListFindNoCase(names, "<img src=x onerror=alert(1)>")).toBe(0, "markup is not a valid name");
			});

		});

		describe("the migrator template output is HTML-encoded", () => {

			it("templating.cfm encodes the result message with EncodeForHTML", () => {
				var src = FileRead(ExpandPath("/wheels/public/migrator/templating.cfm"));
				expect(src).toInclude("EncodeForHTML(message)");
			});

		});
	}
}
