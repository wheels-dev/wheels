/**
 * Dev-UI asset serving (issue #2959, slice P11):
 *
 * Every dev-UI page previously inlined ~1MB of JS/CSS per render
 * (jquery + semantic + marked + highlight via cfinclude, plus a ~53KB
 * base64 icon-font data URI). Assets are now served from the
 * `wheelsAssets` route (`/wheels/assets/<subpath>`) with immutable cache
 * headers and a framework-version cache-buster.
 *
 * The serving action mirrors guideImage()'s canonicalize-and-confine
 * shape but must ALLOW subdirectory paths (css/woff_files/icons.woff2)
 * while still blocking traversal, absolute paths, backslashes, and
 * non-asset extensions. The path resolution and MIME mapping live in
 * unit-testable `$`-helpers on wheels.Public.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Dev-UI asset serving (issue ##2959)", () => {

			describe("$resolveDevAssetPath()", () => {

				it("resolves a top-level asset to a canonical path inside the assets dir", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					var result = publicCfc.$resolveDevAssetPath("css/semantic.min.css");
					expect(Len(result) > 0).toBeTrue("Expected css/semantic.min.css to resolve to a non-empty path.");
					expect(FileExists(result)).toBeTrue("Expected the resolved path to exist on disk.");
					var canonicalAssets = CreateObject("java", "java.io.File")
						.init(ExpandPath("/wheels/public/assets/"))
						.getCanonicalPath();
					expect(CompareNoCase(Left(result, Len(canonicalAssets)), canonicalAssets)).toBe(
						0,
						"Expected the resolved path to be confined to the assets directory."
					);
				});

				it("resolves a nested font asset", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					var result = publicCfc.$resolveDevAssetPath("css/woff_files/icons.woff2");
					expect(Len(result) > 0).toBeTrue("Expected the nested woff2 asset to resolve.");
					expect(FileExists(result)).toBeTrue("Expected the resolved nested path to exist on disk.");
				});

				it("returns empty for traversal payloads", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					var payloads = [
						"../../Public.cfc",
						"../../../etc/passwd",
						"..\..\windows",
						"css/../../Public.cfc"
					];
					for (var payload in payloads) {
						expect(publicCfc.$resolveDevAssetPath(payload)).toBe(
							"",
							"Expected traversal payload `" & payload & "` to be rejected."
						);
					}
				});

				it("returns empty for URL-encoded traversal payloads", () => {
					// The charset allowlist [^A-Za-z0-9_\-./] rejects `%`, so a
					// raw-undecoded payload that slipped past a buggy decoder
					// upstream still gets blocked here. Parallels the
					// guideImage-era PathTraversalSpec coverage.
					var publicCfc = createObject("component", "wheels.Public").$init();
					var payloads = [
						"%2e%2e/etc/passwd",
						"%2E%2E%2Fetc%2Fpasswd",
						"css/%2e%2e/Public.cfc",
						"%2fetc/passwd"
					];
					for (var payload in payloads) {
						expect(publicCfc.$resolveDevAssetPath(payload)).toBe(
							"",
							"Expected URL-encoded traversal payload `" & payload & "` to be rejected."
						);
					}
				});

				it("returns empty for empty, absolute, and backslash inputs", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					expect(publicCfc.$resolveDevAssetPath("")).toBe("", "Expected empty input to be rejected.");
					expect(publicCfc.$resolveDevAssetPath("/etc/passwd")).toBe(
						"",
						"Expected an absolute path to be rejected."
					);
					expect(publicCfc.$resolveDevAssetPath("js\jquery.min.js")).toBe(
						"",
						"Expected a backslash path to be rejected."
					);
				});

				it("returns empty for disallowed extensions", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					expect(publicCfc.$resolveDevAssetPath("foo.cfm")).toBe(
						"",
						"Expected a .cfm extension to be rejected by the allowlist."
					);
					expect(publicCfc.$resolveDevAssetPath("helpers.cfm")).toBe(
						"",
						"Expected source files to be unservable even if dropped under assets/."
					);
				});

				it("returns empty for missing files", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					expect(publicCfc.$resolveDevAssetPath("js/does-not-exist.js")).toBe(
						"",
						"Expected a missing file to resolve to empty."
					);
				});

			});

			describe("$devAssetMimeType()", () => {

				it("maps known asset extensions to their MIME types", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					expect(publicCfc.$devAssetMimeType("css/semantic.min.css")).toBe("text/css");
					expect(publicCfc.$devAssetMimeType("js/jquery.min.js")).toBe("application/javascript");
					expect(publicCfc.$devAssetMimeType("css/woff_files/icons.woff2")).toBe("font/woff2");
					expect(publicCfc.$devAssetMimeType("css/woff_files/icons.woff")).toBe("font/woff");
					expect(publicCfc.$devAssetMimeType("img/logo.png")).toBe("image/png");
					expect(publicCfc.$devAssetMimeType("img/logo.svg")).toBe("image/svg+xml");
				});

				it("falls back to application/octet-stream for unknown extensions", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					expect(publicCfc.$devAssetMimeType("file.unknownext")).toBe("application/octet-stream");
				});

			});

			describe("route and URL helper", () => {

				it("registers the wheelsAssets route", () => {
					var found = false;
					var routePattern = "";
					for (var route in application.wheels.routes) {
						if (StructKeyExists(route, "name") && CompareNoCase(route.name, "wheelsAssets") == 0) {
							found = true;
							routePattern = route.pattern;
							break;
						}
					}
					expect(found).toBeTrue("Expected a route named wheelsAssets to be registered.");
					expect(routePattern).toInclude("assets/");
				});

				it("builds a versioned asset URL", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					var result = publicCfc.devAssetUrl("js/jquery.min.js");
					expect(result).toInclude("js/jquery.min.js");
					expect(result).toInclude("v=");
				});

			});

		});

	}

}
