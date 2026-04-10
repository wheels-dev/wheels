component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("guideImage path traversal prevention", () => {

			it("strips directory components from file parameter", () => {
				var file = "../../etc/passwd";
				var sanitized = getFileFromPath(file);
				expect(sanitized).toBe("passwd");
			});

			it("strips backslash directory components", () => {
				var file = "..\..\windows\system32\config\sam";
				var sanitized = getFileFromPath(file);
				expect(sanitized).notToInclude("..");
			});

			it("allows a simple filename with no path components", () => {
				var file = "screenshot.png";
				var sanitized = getFileFromPath(file);
				expect(sanitized).toBe("screenshot.png");
				expect(find("..", sanitized)).toBe(0);
				expect(reFind("[/\\]", sanitized)).toBe(0);
			});

			it("rejects path traversal with forward slashes", () => {
				var file = "../../../etc/passwd";
				var sanitized = getFileFromPath(file);
				expect(sanitized).notToInclude("/");
				expect(sanitized).notToInclude("..");
			});

			it("validates canonical path stays within assets directory", () => {
				var assetsDir = expandPath("/wheels/docs/src/.gitbook/assets/");
				var canonicalAssets = createObject("java", "java.io.File").init(assetsDir).getCanonicalPath();

				var traversalPath = assetsDir & "../../Public.cfc";
				var canonicalTraversal = createObject("java", "java.io.File").init(traversalPath).getCanonicalPath();

				expect(CompareNoCase(left(canonicalTraversal, len(canonicalAssets)), canonicalAssets)).notToBe(0);
			});

			it("validates canonical path for a legitimate file stays within assets directory", () => {
				var assetsDir = expandPath("/wheels/docs/src/.gitbook/assets/");
				var canonicalAssets = createObject("java", "java.io.File").init(assetsDir).getCanonicalPath();

				var normalPath = assetsDir & "test.png";
				var canonicalNormal = createObject("java", "java.io.File").init(normalPath).getCanonicalPath();

				expect(CompareNoCase(left(canonicalNormal, len(canonicalAssets)), canonicalAssets)).toBe(0);
			});

		});

		describe("Partial path traversal prevention", () => {

			beforeEach(() => {
				params = {controller="dummy", action="dummy"};
				_controller = g.controller("dummy", params);
			});

			it("rejects partial names with dot-dot sequences", () => {
				expect(function() {
					_controller.$generateIncludeTemplatePath($name="../../etc/passwd", $type="partial");
				}).toThrow("Wheels.InvalidPartialPath");
			});

			it("rejects partial names with backslashes", () => {
				expect(function() {
					_controller.$generateIncludeTemplatePath($name=".." & Chr(92) & "secret", $type="partial");
				}).toThrow("Wheels.InvalidPartialPath");
			});

			it("rejects page template names with dot-dot sequences", () => {
				expect(function() {
					_controller.$generateIncludeTemplatePath($name="../../config/settings", $type="page");
				}).toThrow("Wheels.InvalidPartialPath");
			});

			it("allows normal partial names without path traversal", () => {
				expect(function() {
					_controller.$generateIncludeTemplatePath($name="sidebar", $type="partial");
				}).notToThrow();
			});

			it("allows partial names with forward slash subfolder paths", () => {
				expect(function() {
					_controller.$generateIncludeTemplatePath($name="users/card", $type="partial");
				}).notToThrow();
			});

			it("allows partial names with leading slash", () => {
				expect(function() {
					_controller.$generateIncludeTemplatePath($name="/shared/header", $type="partial");
				}).notToThrow();
			});

		});

	}

}
