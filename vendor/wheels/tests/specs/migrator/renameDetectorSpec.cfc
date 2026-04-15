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

			describe("$score", () => {

				it("scores identical normalized tokens as 1.0", () => {
					expect(detector.$score("full_name", "fullName")).toBe(1.0);
				});

				it("scores identical raw strings as 1.0", () => {
					expect(detector.$score("bio", "bio")).toBe(1.0);
				});

				it("scores case-only differences as 1.0", () => {
					expect(detector.$score("FULLNAME", "fullname")).toBe(1.0);
				});

				it("scores near-matches above threshold", () => {
					// emailaddr vs emailaddress: distance 3, maxLen 12, score ≈ 0.75
					local.s = detector.$score("email_addr", "emailAddress");
					expect(local.s >= 0.70 && local.s < 1.0).toBeTrue();
				});

				it("scores unrelated strings below threshold", () => {
					local.s = detector.$score("bio", "description");
					expect(local.s < 0.5).toBeTrue();
				});

				it("returns 0 for both empty strings", () => {
					expect(detector.$score("", "")).toBe(0);
				});

			});

		});

	}

}
