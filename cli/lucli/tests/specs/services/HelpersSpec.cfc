component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.helpers = new cli.lucli.services.Helpers();
	}

	function run() {

		describe("Helpers Service", () => {

			describe("capitalize()", () => {

				it("capitalizes the first letter", () => {
					expect(helpers.capitalize("user")).toBe("User");
				});

				it("handles single character", () => {
					expect(helpers.capitalize("a")).toBe("A");
				});

				it("returns empty string for empty input", () => {
					expect(helpers.capitalize("")).toBe("");
				});

				it("preserves rest of string", () => {
					expect(helpers.capitalize("firstName")).toBe("FirstName");
				});

			});

			describe("pluralize()", () => {

				it("pluralizes regular words", () => {
					expect(helpers.pluralize("user")).toBe("users");
				});

				it("handles -es suffix", () => {
					expect(helpers.pluralize("bus")).toBe("buses");
				});

				it("handles -ies suffix", () => {
					expect(helpers.pluralize("category")).toBe("categories");
				});

				it("handles irregular words", () => {
					expect(helpers.pluralize("person")).toBe("people");
					expect(helpers.pluralize("child")).toBe("children");
				});

				it("handles uncountable words", () => {
					expect(helpers.pluralize("sheep")).toBe("sheep");
					expect(helpers.pluralize("fish")).toBe("fish");
				});

			});

			describe("singularize()", () => {

				it("singularizes regular words", () => {
					expect(helpers.singularize("users")).toBe("user");
				});

				it("handles irregular words", () => {
					expect(helpers.singularize("people")).toBe("person");
					expect(helpers.singularize("children")).toBe("child");
				});

				it("handles uncountable words", () => {
					expect(helpers.singularize("sheep")).toBe("sheep");
				});

			});

			describe("stripSpecialChars()", () => {

				it("removes brackets and special characters", () => {
					expect(helpers.stripSpecialChars("hello[world]")).toBe("helloworld");
				});

				it("removes ampersands and percents", () => {
					expect(helpers.stripSpecialChars("a&b%c")).toBe("abc");
				});

				it("trims whitespace", () => {
					expect(helpers.stripSpecialChars("  hello  ")).toBe("hello");
				});

			});

			describe("generateMigrationTimestamp()", () => {

				it("returns a 14-digit string", () => {
					var ts = helpers.generateMigrationTimestamp();
					expect(len(ts)).toBe(14);
					expect(isNumeric(ts)).toBeTrue();
				});

			});

		});

	}

}
