component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("guideImage path traversal prevention", () => {

			it("strips directory components from file parameter", () => {
				var file = "../../etc/passwd"
				var sanitized = getFileFromPath(file)
				expect(sanitized).toBe("passwd")
			})

			it("strips backslash directory components", () => {
				var file = "..\..\windows\system32\config\sam"
				var sanitized = getFileFromPath(file)
				expect(sanitized).notToInclude("..")
			})

			it("allows a simple filename with no path components", () => {
				var file = "screenshot.png"
				var sanitized = getFileFromPath(file)
				expect(sanitized).toBe("screenshot.png")
				expect(find("..", sanitized)).toBe(0)
				expect(reFind("[/\\]", sanitized)).toBe(0)
			})

			it("rejects path traversal with forward slashes", () => {
				var file = "../../../etc/passwd"
				var sanitized = getFileFromPath(file)
				expect(sanitized).notToInclude("/")
				expect(sanitized).notToInclude("..")
			})

			it("validates canonical path stays within assets directory", () => {
				var assetsDir = expandPath("/wheels/docs/src/.gitbook/assets/")
				var canonicalAssets = createObject("java", "java.io.File").init(assetsDir).getCanonicalPath()

				var traversalPath = assetsDir & "../../Public.cfc"
				var canonicalTraversal = createObject("java", "java.io.File").init(traversalPath).getCanonicalPath()

				expect(left(canonicalTraversal, len(canonicalAssets))).notToBe(canonicalAssets)
			})

			it("validates canonical path for a legitimate file stays within assets directory", () => {
				var assetsDir = expandPath("/wheels/docs/src/.gitbook/assets/")
				var canonicalAssets = createObject("java", "java.io.File").init(assetsDir).getCanonicalPath()

				var normalPath = assetsDir & "test.png"
				var canonicalNormal = createObject("java", "java.io.File").init(normalPath).getCanonicalPath()

				expect(left(canonicalNormal, len(canonicalAssets))).toBe(canonicalAssets)
			})
		})
	}
}
