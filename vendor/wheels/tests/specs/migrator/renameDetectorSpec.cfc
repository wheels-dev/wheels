component extends="wheels.WheelsTest" {

	function beforeAll() {
		detector = CreateObject("component", "wheels.migrator.RenameDetector");
	}

	function run() {

		describe("RenameDetector", () => {

			describe("$normalizeToken", () => {

				it("lowercases input", () => {
					expect(detector.$normalizeToken("FULLNAME")).toBe("fullname");
				});

				it("removes underscores", () => {
					expect(detector.$normalizeToken("full_name")).toBe("fullname");
				});

				it("removes hyphens", () => {
					expect(detector.$normalizeToken("full-name")).toBe("fullname");
				});

				it("normalizes camelCase and snake_case to same token", () => {
					expect(detector.$normalizeToken("fullName")).toBe("fullname");
					expect(detector.$normalizeToken("full_name")).toBe("fullname");
				});

				it("handles empty string", () => {
					expect(detector.$normalizeToken("")).toBe("");
				});

				it("handles mixed case + separators", () => {
					expect(detector.$normalizeToken("FULL-Name_Field")).toBe("fullnamefield");
				});

			});

			describe("$levenshtein", () => {

				it("returns 0 for identical strings", () => {
					expect(detector.$levenshtein("abc", "abc")).toBe(0);
				});

				it("returns length of other when one string is empty", () => {
					expect(detector.$levenshtein("", "abc")).toBe(3);
					expect(detector.$levenshtein("abc", "")).toBe(3);
				});

				it("returns 1 for single substitution", () => {
					expect(detector.$levenshtein("cat", "bat")).toBe(1);
				});

				it("returns 1 for single insertion", () => {
					expect(detector.$levenshtein("cat", "cats")).toBe(1);
				});

				it("returns 1 for single deletion", () => {
					expect(detector.$levenshtein("cats", "cat")).toBe(1);
				});

				it("handles transposition as two edits", () => {
					expect(detector.$levenshtein("ab", "ba")).toBe(2);
				});

				it("computes distance for realistic column names", () => {
					// emailaddr → emailaddress: insert 'e', 's', 's' = 3
					expect(detector.$levenshtein("emailaddr", "emailaddress")).toBe(3);
				});

			});

		});

	}

}
