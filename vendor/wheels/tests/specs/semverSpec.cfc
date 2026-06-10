component extends="wheels.WheelsTest" {

	function run() {

		describe("SemVer parsing", function() {

			beforeEach(function() {
				semver = CreateObject("component", "wheels.SemVer")
			})

			it("parses a standard three-part version", function() {
				var v = semver.parse("1.2.3")
				expect(v.major).toBe(1)
				expect(v.minor).toBe(2)
				expect(v.patch).toBe(3)
				expect(v.preRelease).toBe("")
			})

			it("strips leading v prefix", function() {
				var v = semver.parse("v2.0.1")
				expect(v.major).toBe(2)
				expect(v.minor).toBe(0)
				expect(v.patch).toBe(1)
			})

			it("defaults missing minor and patch to zero", function() {
				var v = semver.parse("3")
				expect(v.major).toBe(3)
				expect(v.minor).toBe(0)
				expect(v.patch).toBe(0)
			})

			it("defaults missing patch to zero", function() {
				var v = semver.parse("1.5")
				expect(v.major).toBe(1)
				expect(v.minor).toBe(5)
				expect(v.patch).toBe(0)
			})

			it("extracts pre-release label", function() {
				var v = semver.parse("1.0.0-beta.1")
				expect(v.major).toBe(1)
				expect(v.minor).toBe(0)
				expect(v.patch).toBe(0)
				expect(v.preRelease).toBe("beta.1")
			})

			it("strips build metadata", function() {
				var v = semver.parse("1.0.0+build.123")
				expect(v.major).toBe(1)
				expect(v.patch).toBe(0)
			})
		})

		describe("SemVer comparison", function() {

			beforeEach(function() {
				semver = CreateObject("component", "wheels.SemVer")
			})

			it("returns 0 for equal versions", function() {
				expect(semver.compare("1.2.3", "1.2.3")).toBe(0)
			})

			it("returns 1 when first version is greater by major", function() {
				expect(semver.compare("2.0.0", "1.9.9")).toBe(1)
			})

			it("returns -1 when first version is less by minor", function() {
				expect(semver.compare("1.0.0", "1.1.0")).toBe(-1)
			})

			it("returns 1 when first version is greater by patch", function() {
				expect(semver.compare("1.0.2", "1.0.1")).toBe(1)
			})
		})

		describe("SemVer satisfies single constraint", function() {

			beforeEach(function() {
				semver = CreateObject("component", "wheels.SemVer")
			})

			it("matches exact version with = operator", function() {
				expect(semver.satisfies("1.2.3", "=1.2.3")).toBeTrue()
				expect(semver.satisfies("1.2.4", "=1.2.3")).toBeFalse()
			})

			it("matches bare version as exact", function() {
				expect(semver.satisfies("1.2.3", "1.2.3")).toBeTrue()
				expect(semver.satisfies("1.2.4", "1.2.3")).toBeFalse()
			})

			it("matches >= constraint", function() {
				expect(semver.satisfies("2.0.0", ">=1.0.0")).toBeTrue()
				expect(semver.satisfies("1.0.0", ">=1.0.0")).toBeTrue()
				expect(semver.satisfies("0.9.0", ">=1.0.0")).toBeFalse()
			})

			it("matches > constraint", function() {
				expect(semver.satisfies("1.0.1", ">1.0.0")).toBeTrue()
				expect(semver.satisfies("1.0.0", ">1.0.0")).toBeFalse()
			})

			it("matches < constraint", function() {
				expect(semver.satisfies("0.9.9", "<1.0.0")).toBeTrue()
				expect(semver.satisfies("1.0.0", "<1.0.0")).toBeFalse()
			})

			it("matches <= constraint", function() {
				expect(semver.satisfies("1.0.0", "<=1.0.0")).toBeTrue()
				expect(semver.satisfies("1.0.1", "<=1.0.0")).toBeFalse()
			})

			it("returns true for empty constraint", function() {
				expect(semver.satisfies("1.0.0", "")).toBeTrue()
			})

			it("returns true for wildcard * constraint", function() {
				expect(semver.satisfies("1.0.0", "*")).toBeTrue()
				expect(semver.satisfies("0.0.1", "*")).toBeTrue()
				expect(semver.satisfies("99.99.99", "*")).toBeTrue()
			})
		})

		describe("SemVer caret (^) constraints", function() {

			beforeEach(function() {
				semver = CreateObject("component", "wheels.SemVer")
			})

			it("allows minor and patch changes for major > 0", function() {
				expect(semver.satisfies("1.2.3", "^1.2.0")).toBeTrue()
				expect(semver.satisfies("1.9.9", "^1.2.0")).toBeTrue()
				expect(semver.satisfies("2.0.0", "^1.2.0")).toBeFalse()
			})

			it("restricts to patch changes for 0.x versions", function() {
				expect(semver.satisfies("0.2.5", "^0.2.3")).toBeTrue()
				expect(semver.satisfies("0.3.0", "^0.2.3")).toBeFalse()
			})

			it("pins exact patch for 0.0.x versions", function() {
				expect(semver.satisfies("0.0.3", "^0.0.3")).toBeTrue()
				expect(semver.satisfies("0.0.4", "^0.0.3")).toBeFalse()
			})

			it("rejects versions below the constraint", function() {
				expect(semver.satisfies("1.1.0", "^1.2.0")).toBeFalse()
			})
		})

		describe("SemVer tilde (~) constraints", function() {

			beforeEach(function() {
				semver = CreateObject("component", "wheels.SemVer")
			})

			it("allows patch-level changes within same minor", function() {
				expect(semver.satisfies("1.2.5", "~1.2.3")).toBeTrue()
				expect(semver.satisfies("1.2.3", "~1.2.3")).toBeTrue()
				expect(semver.satisfies("1.3.0", "~1.2.3")).toBeFalse()
			})

			it("rejects versions below the constraint", function() {
				expect(semver.satisfies("1.2.2", "~1.2.3")).toBeFalse()
			})
		})

		describe("SemVer satisfiesAll (compound constraints)", function() {

			beforeEach(function() {
				semver = CreateObject("component", "wheels.SemVer")
			})

			it("ANDs multiple space-separated constraints", function() {
				expect(semver.satisfiesAll("1.5.0", ">=1.0.0 <2.0.0")).toBeTrue()
				expect(semver.satisfiesAll("2.0.0", ">=1.0.0 <2.0.0")).toBeFalse()
				expect(semver.satisfiesAll("0.9.0", ">=1.0.0 <2.0.0")).toBeFalse()
			})

			it("returns true when all constraints match", function() {
				expect(semver.satisfiesAll("1.5.3", ">=1.5.0 <=1.5.9")).toBeTrue()
			})

			it("returns true for empty constraint string", function() {
				expect(semver.satisfiesAll("1.0.0", "")).toBeTrue()
			})

			it("returns true for wildcard * in satisfiesAll", function() {
				expect(semver.satisfiesAll("5.0.0", "*")).toBeTrue()
			})
		})

		describe("SemVer constraints with a space after the operator", function() {

			beforeEach(function() {
				semver = CreateObject("component", "wheels.SemVer")
			})

			it("treats '>= X' as a range constraint, not an exact match", function() {
				// Previously '>= 1.0.0' split into '>=' (empty target, always
				// true) AND '1.0.0' (exact match) — silently '=1.0.0'.
				expect(semver.satisfiesAll("1.5.0", ">= 1.0.0")).toBeTrue()
				expect(semver.satisfiesAll("1.0.0", ">= 1.0.0")).toBeTrue()
				expect(semver.satisfiesAll("0.9.0", ">= 1.0.0")).toBeFalse()
			})

			it("treats '^ X' as a caret range", function() {
				// Previously '^ 1.2.3' was unsatisfiable.
				expect(semver.satisfiesAll("1.5.0", "^ 1.2.3")).toBeTrue()
				expect(semver.satisfiesAll("1.2.3", "^ 1.2.3")).toBeTrue()
				expect(semver.satisfiesAll("2.0.0", "^ 1.2.3")).toBeFalse()
			})

			it("treats '~ X' as a tilde range", function() {
				expect(semver.satisfiesAll("1.2.5", "~ 1.2.3")).toBeTrue()
				expect(semver.satisfiesAll("1.3.0", "~ 1.2.3")).toBeFalse()
			})

			it("handles spaced operators inside compound constraints", function() {
				expect(semver.satisfiesAll("1.5.0", ">= 1.0.0 < 2.0.0")).toBeTrue()
				expect(semver.satisfiesAll("2.1.0", ">= 1.0.0 < 2.0.0")).toBeFalse()
				expect(semver.satisfiesAll("1.5.0", ">=1.0.0 < 2.0.0")).toBeTrue()
			})

			it("fails closed on an operator with no target", function() {
				expect(semver.satisfies("1.0.0", ">=")).toBeFalse()
				expect(semver.satisfies("1.0.0", "^")).toBeFalse()
				expect(semver.satisfies("1.0.0", "~")).toBeFalse()
				expect(semver.satisfiesAll("1.0.0", ">=")).toBeFalse()
				expect(semver.satisfiesAll("1.0.0", ">=1.0.0 <")).toBeFalse()
			})
		})

		describe("SemVer format", function() {

			beforeEach(function() {
				semver = CreateObject("component", "wheels.SemVer")
			})

			it("formats a parsed version back to string", function() {
				var v = semver.parse("1.2.3")
				expect(semver.format(v)).toBe("1.2.3")
			})
		})

	}

}
