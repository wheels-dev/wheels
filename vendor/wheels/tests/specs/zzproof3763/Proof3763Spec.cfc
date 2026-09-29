/**
 * THROWAWAY (#3763 proof, never merged): one deliberate failure and one
 * deliberate error, so the PR compat gate has to name both.
 */
component extends="wheels.WheelsTest" {
	function run() {
		describe("proof 3763 outer", () => {
			describe("inner suite", () => {
				it("deliberately fails", () => {
					expect(1).toBe(2, "deliberate failure for the issue 3763 proof");
				});
				it("deliberately errors", () => {
					throw(type = "Proof3763.Deliberate", message = "deliberate error for the issue 3763 proof");
				});
			});
		});
	}
}
