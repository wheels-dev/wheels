component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("SemVer (CLI copy)", () => {

			var sv = new cli.lucli.services.SemVer();

			describe("compare()", () => {

				it("orders MAJOR.MINOR.PATCH numerically", () => {
					expect(sv.compare("1.2.0", "1.10.0")).toBe(-1);
					expect(sv.compare("2.0.0", "1.99.99")).toBe(1);
					expect(sv.compare("v1.2.3", "1.2.3")).toBe(0);
				});

				it("ranks a pre-release below the same release", () => {
					expect(sv.compare("1.2.0-rc.1", "1.2.0")).toBe(-1);
					expect(sv.compare("1.2.0", "1.2.0-rc.1")).toBe(1);
					expect(sv.compare("1.2.0-rc.1", "1.1.9")).toBe(1);
				});

				it("compares numeric identifiers numerically", () => {
					expect(sv.compare("1.0.0-rc.1", "1.0.0-rc.2")).toBe(-1);
					expect(sv.compare("1.0.0-rc.2", "1.0.0-rc.10")).toBe(-1);
					expect(sv.compare("4.1.2-snapshot.999", "4.1.2-snapshot.1000")).toBe(-1);
					expect(sv.compare("1.0.0-rc.1", "1.0.0-rc.1")).toBe(0);
				});

				it("compares alphanumeric identifiers in ASCII order", () => {
					expect(sv.compare("1.0.0-alpha", "1.0.0-beta")).toBe(-1);
					expect(sv.compare("1.0.0-beta", "1.0.0-alpha")).toBe(1);
					expect(sv.compare("1.0.0-SNAPSHOT", "1.0.0-snapshot")).toBe(-1);
				});

				it("ranks a numeric identifier below an alphanumeric one", () => {
					expect(sv.compare("1.0.0-1", "1.0.0-alpha")).toBe(-1);
					expect(sv.compare("1.0.0-alpha.1", "1.0.0-alpha.beta")).toBe(-1);
				});

				it("ranks a longer label higher when shared identifiers tie", () => {
					expect(sv.compare("1.0.0-alpha", "1.0.0-alpha.1")).toBe(-1);
					expect(sv.compare("1.0.0-alpha.1", "1.0.0-alpha")).toBe(1);
				});

				it("follows the SemVer 2.0.0 precedence example", () => {
					var ordered = [
						"1.0.0-alpha", "1.0.0-alpha.1", "1.0.0-alpha.beta", "1.0.0-beta",
						"1.0.0-beta.2", "1.0.0-beta.11", "1.0.0-rc.1", "1.0.0"
					];
					for (var i = 1; i < ArrayLen(ordered); i++) {
						expect(sv.compare(ordered[i], ordered[i + 1])).toBe(-1, ordered[i] & " < " & ordered[i + 1]);
					}
				});

				it("ignores build metadata", () => {
					expect(sv.compare("1.0.0+build.5", "1.0.0")).toBe(0);
					expect(sv.compare("1.0.0-rc.1+build-7", "1.0.0-rc.1")).toBe(0);
					expect(sv.parse("1.0.0+build-7").preRelease).toBe("");
				});
			});

			describe("satisfies()", () => {

				it("matches an exact pin only to the identical version", () => {
					expect(sv.satisfies("1.2.0", "1.2.0")).toBeTrue();
					expect(sv.satisfies("1.2.0-rc.1", "1.2.0")).toBeFalse();
					expect(sv.satisfies("1.2.0-rc.1", "1.2.0-rc.1")).toBeTrue();
					expect(sv.satisfies("1.2.0", "=1.2.0-rc.1")).toBeFalse();
				});

				it("orders pre-releases in range constraints", () => {
					expect(sv.satisfies("1.2.0-rc.1", ">=1.2.0")).toBeFalse();
					expect(sv.satisfies("1.2.0-rc.1", "<1.2.0")).toBeTrue();
					expect(sv.satisfies("1.2.0", ">1.2.0-rc.1")).toBeTrue();
				});
			});
		});
	}
}
