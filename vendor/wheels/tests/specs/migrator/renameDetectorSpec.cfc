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

			describe("detect() — empty inputs", () => {

				it("returns all four keys with empty arrays given empty inputs", () => {
					local.result = detector.detect(
						addColumns = [],
						removeColumns = [],
						addTypes = {},
						removeTypes = {}
					);
					expect(local.result).toHaveKey("confirmedRenames");
					expect(local.result).toHaveKey("suggestedRenames");
					expect(local.result).toHaveKey("remainingAdds");
					expect(local.result).toHaveKey("remainingRemoves");
					expect(local.result.confirmedRenames).toBeArray();
					expect(ArrayLen(local.result.confirmedRenames)).toBe(0);
					expect(ArrayLen(local.result.suggestedRenames)).toBe(0);
					expect(ArrayLen(local.result.remainingAdds)).toBe(0);
					expect(ArrayLen(local.result.remainingRemoves)).toBe(0);
				});

				it("returns inputs unchanged when no hints and no heuristic matches", () => {
					local.result = detector.detect(
						addColumns = [{name: "bio", type: "text", nullable: true, "default": ""}],
						removeColumns = [{name: "legacy_flag"}],
						addTypes = {"bio": "text"},
						removeTypes = {"legacy_flag": "boolean"}
					);
					expect(ArrayLen(local.result.confirmedRenames)).toBe(0);
					expect(ArrayLen(local.result.suggestedRenames)).toBe(0);
					expect(ArrayLen(local.result.remainingAdds)).toBe(1);
					expect(ArrayLen(local.result.remainingRemoves)).toBe(1);
				});

			});

			describe("detect() — explicit hints", () => {

				it("confirms rename when hint maps existing remove to existing add", () => {
					local.result = detector.detect(
						addColumns = [{name: "fullName", type: "string", nullable: true, "default": ""}],
						removeColumns = [{name: "full_name"}],
						addTypes = {"fullName": "string"},
						removeTypes = {"full_name": "string"},
						hints = {renames: {"full_name": "fullName"}}
					);
					expect(ArrayLen(local.result.confirmedRenames)).toBe(1);
					expect(local.result.confirmedRenames[1].from).toBe("full_name");
					expect(local.result.confirmedRenames[1].to).toBe("fullName");
					expect(local.result.confirmedRenames[1].type).toBe("string");
					expect(local.result.confirmedRenames[1].source).toBe("hint");
					expect(ArrayLen(local.result.remainingAdds)).toBe(0);
					expect(ArrayLen(local.result.remainingRemoves)).toBe(0);
				});

				it("leaves non-hinted columns in remaining arrays", () => {
					local.result = detector.detect(
						addColumns = [
							{name: "fullName", type: "string", nullable: true, "default": ""},
							{name: "bio", type: "text", nullable: true, "default": ""}
						],
						removeColumns = [
							{name: "full_name"},
							{name: "legacy_flag"}
						],
						addTypes = {"fullName": "string", "bio": "text"},
						removeTypes = {"full_name": "string", "legacy_flag": "boolean"},
						hints = {renames: {"full_name": "fullName"}}
					);
					expect(ArrayLen(local.result.confirmedRenames)).toBe(1);
					expect(ArrayLen(local.result.remainingAdds)).toBe(1);
					expect(local.result.remainingAdds[1].name).toBe("bio");
					expect(ArrayLen(local.result.remainingRemoves)).toBe(1);
					expect(local.result.remainingRemoves[1].name).toBe("legacy_flag");
				});

				it("raises InvalidRenameHint when hint from-column is not in removes", () => {
					expect(() => {
						detector.detect(
							addColumns = [{name: "fullName", type: "string", nullable: true, "default": ""}],
							removeColumns = [{name: "legacy_flag"}],
							addTypes = {"fullName": "string"},
							removeTypes = {"legacy_flag": "boolean"},
							hints = {renames: {"nonexistent": "fullName"}}
						);
					}).toThrow("Wheels.InvalidRenameHint");
				});

				it("raises InvalidRenameHint when hint to-column is not in adds", () => {
					expect(() => {
						detector.detect(
							addColumns = [{name: "fullName", type: "string", nullable: true, "default": ""}],
							removeColumns = [{name: "full_name"}],
							addTypes = {"fullName": "string"},
							removeTypes = {"full_name": "string"},
							hints = {renames: {"full_name": "nonexistent"}}
						);
					}).toThrow("Wheels.InvalidRenameHint");
				});

				it("raises RenameHintTypeMismatch when hinted pair has different types", () => {
					expect(() => {
						detector.detect(
							addColumns = [{name: "fullName", type: "text", nullable: true, "default": ""}],
							removeColumns = [{name: "full_name"}],
							addTypes = {"fullName": "text"},
							removeTypes = {"full_name": "string"},
							hints = {renames: {"full_name": "fullName"}}
						);
					}).toThrow("Wheels.RenameHintTypeMismatch");
				});

				it("CFML struct keys are unique, so same from-key can't collide (no-op test)", () => {
					// CFML struct keys are inherently unique; duplicate-from detection is a
					// CLI-layer concern (Task 12). This spec just documents the expectation.
					expect(() => {
						detector.detect(
							addColumns = [
								{name: "fullName", type: "string", nullable: true, "default": ""},
								{name: "displayName", type: "string", nullable: true, "default": ""}
							],
							removeColumns = [{name: "full_name"}],
							addTypes = {"fullName": "string", "displayName": "string"},
							removeTypes = {"full_name": "string"},
							hints = {renames: {"full_name": "fullName"}}
						);
					}).notToThrow();
				});

				it("raises DuplicateRenameHint when two hints share the same to-column", () => {
					expect(() => {
						detector.detect(
							addColumns = [{name: "fullName", type: "string", nullable: true, "default": ""}],
							removeColumns = [
								{name: "full_name"},
								{name: "display_name"}
							],
							addTypes = {"fullName": "string"},
							removeTypes = {"full_name": "string", "display_name": "string"},
							hints = {renames: {"full_name": "fullName", "display_name": "fullName"}}
						);
					}).toThrow("Wheels.DuplicateRenameHint");
				});

			});

		});

	}

}
