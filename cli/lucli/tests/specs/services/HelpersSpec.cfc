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

			describe("normalizePath()", () => {

				// Regression: GH #2841 — `wheels new`/`wheels start` on Windows
				// failed with "lucee.runtime.exp.NativeException: there is no
				// Resource provider available with the name [c]". The CLI was
				// concatenating a Windows-form path (backslashes from
				// java.io.File.getCanonicalPath()) with "/vendor/wheels" and
				// feeding the mixed-slash result to Lucee's Resource API,
				// which then parsed "c:" as a URI scheme. Forward-slash
				// normalization makes the path unambiguous on Windows while
				// being a no-op on POSIX.

				it("converts Windows backslashes to forward slashes", () => {
					expect(helpers.normalizePath("C:\Users\tim\Projects"))
						.toBe("C:/Users/tim/Projects");
				});

				it("leaves POSIX paths unchanged", () => {
					expect(helpers.normalizePath("/home/runner/work/wheels"))
						.toBe("/home/runner/work/wheels");
				});

				it("returns an empty string for empty input", () => {
					expect(helpers.normalizePath("")).toBe("");
				});

				it("collapses doubled forward slashes from concatenation", () => {
					expect(helpers.normalizePath("/a/b//c")).toBe("/a/b/c");
				});

				it("preserves a Windows drive-letter prefix after normalization", () => {
					var normalized = helpers.normalizePath("C:\Users\tim\Projects");
					expect(normalized & "/vendor/wheels")
						.toBe("C:/Users/tim/Projects/vendor/wheels");
					// Sanity: no remaining backslash means downstream
					// directoryExists() won't trip Lucee's scheme parser on
					// a mixed-slash path.
					expect(find("\", normalized)).toBe(0);
				});

				it("preserves a UNC network-share prefix", () => {
					expect(helpers.normalizePath("//server/share/path"))
						.toBe("//server/share/path");
				});

				it("collapses doubled slashes inside a UNC path without eating the prefix", () => {
					expect(helpers.normalizePath("//server//share"))
						.toBe("//server/share");
				});

			});

		});

	}

}
