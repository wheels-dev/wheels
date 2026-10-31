/**
 * Regression guard for #4646: Adobe CF 2023 update 26 / 2025 update 14 treat the
 * \l and \U replacement case flags as literal letters. The three follow-up sites
 * must not reintroduce them, and must keep the engine-neutral implementations.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Adobe u26/u14 lower/upper replacement flags (##4646)", () => {

			it("keeps the removed replacement case flags out of the three follow-up files", () => {
				var files = [
					"/wheels/global/strings.cfm",
					"/wheels/controller/redirection.cfc",
					"/wheels/mapper/matching.cfc"
				]
				for (var path in files) {
					var source = FileRead(ExpandPath(path))
					expect(Find("\l", source)).toBe(0, path & " must not use the \l replacement case flag")
					expect(Find("\U", source)).toBe(0, path & " must not use the \U replacement case flag")
				}
			})

			it("keeps the engine-neutral implementations at the three sites", () => {
				expect(Find("$upperCaseAfterComma", FileRead(ExpandPath("/wheels/mapper/matching.cfc")))).toBeGT(0)
				expect(Find("RemoveChars", FileRead(ExpandPath("/wheels/controller/redirection.cfc")))).toBeGT(0)
			})

		})

	}

}
