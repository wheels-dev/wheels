component extends="wheels.WheelsTest" {

	function beforeAll() {
		// Ensure Vite settings exist in the active application scope.
		// After framework init, application.$wheels is deleted and application.wheels
		// is the sole settings struct. $appKey() returns the correct key.
		var appKey = application.wo.$appKey();
		var defaults = {
			viteDevMode = false,
			viteDevServerUrl = "http://localhost:5173",
			viteBuildPath = "build",
			viteManifestFile = ".vite/manifest.json",
			viteStrictManifest = true
		};
		for (var key in defaults) {
			if (!StructKeyExists(application[appKey], key)) {
				application[appKey][key] = defaults[key];
			}
		}
	}

	function run() {

		g = application.wo

		describe("Tests that viteAsset", () => {

			beforeEach(() => {
				_controller = g.controller(name="dummy")
				// Save original settings
				_origDevMode = application.wheels.viteDevMode
				_origDevUrl = application.wheels.viteDevServerUrl
				_origBuildPath = application.wheels.viteBuildPath
				_origManifestFile = application.wheels.viteManifestFile
				_origStrict = application.wheels.viteStrictManifest
				_origShowErr = application.wheels.showErrorInformation
			})

			afterEach(() => {
				// Restore original settings
				application.wheels.viteDevMode = _origDevMode
				application.wheels.viteDevServerUrl = _origDevUrl
				application.wheels.viteBuildPath = _origBuildPath
				application.wheels.viteManifestFile = _origManifestFile
				application.wheels.viteStrictManifest = _origStrict
				application.wheels.showErrorInformation = _origShowErr
				// Clear manifest cache from the active application scope
				var appKey = application.wo.$appKey()
				StructDelete(application[appKey], "viteManifestCache")
			})

			it("returns dev server URL in dev mode", () => {
				application.wheels.viteDevMode = true
				application.wheels.viteDevServerUrl = "http://localhost:5173"

				e = _controller.viteAsset("src/main.js")

				expect(e).toBe("http://localhost:5173/src/main.js")
			})

			it("returns dev server URL with leading slash", () => {
				application.wheels.viteDevMode = true
				application.wheels.viteDevServerUrl = "http://localhost:5173"

				e = _controller.viteAsset("/src/main.js")

				expect(e).toBe("http://localhost:5173/src/main.js")
			})

			it("handles trailing slash on dev server URL", () => {
				application.wheels.viteDevMode = true
				application.wheels.viteDevServerUrl = "http://localhost:5173/"

				e = _controller.viteAsset("src/main.js")

				expect(e).toBe("http://localhost:5173/src/main.js")
			})

			it("resolves fingerprinted path from manifest in production", () => {
				application.wheels.viteDevMode = false
				application.wheels.viteManifestCache = {
					"src/main.js": {
						file: "assets/main-BRBhM4rY.js",
						src: "src/main.js",
						isEntry: true
					}
				}

				e = _controller.viteAsset("src/main.js")

				expect(e).toInclude("build/assets/main-BRBhM4rY.js")
			})

			it("throws when entrypoint not in manifest", () => {
				application.wheels.viteDevMode = false
				application.wheels.viteManifestCache = {}

				expect(function() {
					_controller.viteAsset("src/missing.js")
				}).toThrow("Wheels.ViteAssetNotFound")
			})

			it("throws under strict mode even when showErrorInformation is false", () => {
				application.wheels.viteDevMode = false
				application.wheels.viteStrictManifest = true
				application.wheels.showErrorInformation = false
				application.wheels.viteManifestCache = {}

				expect(function() {
					_controller.viteAsset("src/missing.js")
				}).toThrow("Wheels.ViteAssetNotFound")
			})

			it("returns entrypoint silently when strict=false and showErrorInformation=false", () => {
				application.wheels.viteDevMode = false
				application.wheels.viteStrictManifest = false
				application.wheels.showErrorInformation = false
				application.wheels.viteManifestCache = {}

				e = _controller.viteAsset("src/missing.js")

				expect(e).toBe("src/missing.js")
			})
		})

		describe("Tests that viteScriptTag", () => {

			beforeEach(() => {
				_controller = g.controller(name="dummy")
				_origDevMode = application.wheels.viteDevMode
				_origDevUrl = application.wheels.viteDevServerUrl
				_origBuildPath = application.wheels.viteBuildPath
			})

			afterEach(() => {
				application.wheels.viteDevMode = _origDevMode
				application.wheels.viteDevServerUrl = _origDevUrl
				application.wheels.viteBuildPath = _origBuildPath
				var appKey = application.wo.$appKey()
				StructDelete(application[appKey], "viteManifestCache")
			})

			it("includes vite client and module script in dev mode", () => {
				application.wheels.viteDevMode = true
				application.wheels.viteDevServerUrl = "http://localhost:5173"

				e = _controller.viteScriptTag("src/main.js")

				expect(e).toInclude("@vite/client")
				expect(e).toInclude('type="module"')
				expect(e).toInclude("http://localhost:5173/src/main.js")
			})

			it("returns script tag with fingerprinted path in production", () => {
				application.wheels.viteDevMode = false
				application.wheels.viteManifestCache = {
					"src/main.js": {
						file: "assets/main-BRBhM4rY.js",
						src: "src/main.js",
						isEntry: true
					}
				}

				e = _controller.viteScriptTag("src/main.js")

				expect(e).toInclude("assets/main-BRBhM4rY.js")
				expect(e).toInclude('type="module"')
			})

			it("includes CSS link tags from manifest in production", () => {
				application.wheels.viteDevMode = false
				application.wheels.viteManifestCache = {
					"src/main.js": {
						file: "assets/main-BRBhM4rY.js",
						src: "src/main.js",
						isEntry: true,
						css: ["assets/main-DiwrgTda.css"]
					}
				}

				e = _controller.viteScriptTag("src/main.js")

				expect(e).toInclude("assets/main-DiwrgTda.css")
				expect(e).toInclude('rel="stylesheet"')
				expect(e).toInclude("assets/main-BRBhM4rY.js")
			})

			it("emits stylesheet links for transitive chunk CSS", () => {
				application.wheels.viteDevMode = false
				application.wheels.viteManifestCache = {
					"src/main.js": {
						file: "assets/main-ABC.js",
						isEntry: true,
						imports: ["_chunk-SHARED.js"],
						css: ["assets/main-MAIN.css"]
					},
					"_chunk-SHARED.js": {
						file: "assets/chunk-SHARED.js",
						imports: [],
						css: ["assets/chunk-SHARED.css"]
					}
				}

				e = _controller.viteScriptTag("src/main.js")

				expect(e).toInclude("assets/main-MAIN.css")
				expect(e).toInclude("assets/chunk-SHARED.css")
			})

			it("emits modulepreload links for transitive chunks via $viteHtmlHead", () => {
				application.wheels.viteDevMode = false
				application.wheels.viteManifestCache = {
					"src/main.js": {
						file: "assets/main-ABC.js",
						isEntry: true,
						imports: ["_chunk-SHARED.js"]
					},
					"_chunk-SHARED.js": {
						file: "assets/chunk-SHARED.js",
						imports: ["_chunk-VENDOR.js"]
					},
					"_chunk-VENDOR.js": {
						file: "assets/chunk-VENDOR.js",
						imports: []
					}
				}
				request.$viteHeadCapture = []

				_controller.viteScriptTag("src/main.js")

				var captured = ArrayToList(request.$viteHeadCapture, Chr(10))
				expect(captured).toInclude('rel="modulepreload"')
				expect(captured).toInclude("assets/chunk-SHARED.js")
				expect(captured).toInclude("assets/chunk-VENDOR.js")
				StructDelete(request, "$viteHeadCapture")
			})

			it("throws when entrypoint not in manifest", () => {
				application.wheels.viteDevMode = false
				application.wheels.viteManifestCache = {}

				expect(function() {
					_controller.viteScriptTag("src/missing.js")
				}).toThrow("Wheels.ViteAssetNotFound")
			})
		})

		describe("Tests that viteStyleTag", () => {

			beforeEach(() => {
				_controller = g.controller(name="dummy")
				_origDevMode = application.wheels.viteDevMode
				_origBuildPath = application.wheels.viteBuildPath
			})

			afterEach(() => {
				application.wheels.viteDevMode = _origDevMode
				application.wheels.viteBuildPath = _origBuildPath
				var appKey = application.wo.$appKey()
				StructDelete(application[appKey], "viteManifestCache")
			})

			it("returns empty string in dev mode", () => {
				application.wheels.viteDevMode = true

				e = _controller.viteStyleTag("src/main.css")

				expect(e).toHaveLength(0)
			})

			it("returns link tag with fingerprinted path in production", () => {
				application.wheels.viteDevMode = false
				application.wheels.viteManifestCache = {
					"src/main.css": {
						file: "assets/main-DiwrgTda.css",
						src: "src/main.css"
					}
				}

				e = _controller.viteStyleTag("src/main.css")

				expect(e).toInclude("assets/main-DiwrgTda.css")
				expect(e).toInclude('rel="stylesheet"')
			})

			it("emits stylesheet links for transitive chunk CSS", () => {
				application.wheels.viteDevMode = false
				application.wheels.viteManifestCache = {
					"src/main.css": {
						file: "assets/main-MAIN.css",
						imports: ["_chunk-SHARED.js"],
						css: []
					},
					"_chunk-SHARED.js": {
						file: "assets/chunk-SHARED.js",
						imports: [],
						css: ["assets/chunk-SHARED.css"]
					}
				}

				e = _controller.viteStyleTag("src/main.css")

				expect(e).toInclude("assets/main-MAIN.css")
				expect(e).toInclude("assets/chunk-SHARED.css")
			})

			it("throws when entrypoint not in manifest", () => {
				application.wheels.viteDevMode = false
				application.wheels.viteManifestCache = {}

				expect(function() {
					_controller.viteStyleTag("src/missing.css")
				}).toThrow("Wheels.ViteAssetNotFound")
			})
		})

		describe("Tests that vitePreloadTag", () => {

			beforeEach(() => {
				_controller = g.controller(name="dummy")
				_origDevMode = application.wheels.viteDevMode
				_origBuildPath = application.wheels.viteBuildPath
				_origStrict = application.wheels.viteStrictManifest
			})

			afterEach(() => {
				application.wheels.viteDevMode = _origDevMode
				application.wheels.viteBuildPath = _origBuildPath
				application.wheels.viteStrictManifest = _origStrict
				var appKey = application.wo.$appKey()
				StructDelete(application[appKey], "viteManifestCache")
				if (StructKeyExists(request, "$viteHeadCapture")) {
					StructDelete(request, "$viteHeadCapture")
				}
			})

			it("returns empty string in dev mode", () => {
				application.wheels.viteDevMode = true

				e = _controller.vitePreloadTag("src/main.js")

				expect(e).toBe("")
			})

			it("returns modulepreload for entry and each transitive chunk with head=false", () => {
				application.wheels.viteDevMode = false
				application.wheels.viteManifestCache = {
					"src/main.js": {
						file: "assets/main-ABC.js",
						isEntry: true,
						imports: ["_chunk-SHARED.js"]
					},
					"_chunk-SHARED.js": {
						file: "assets/chunk-SHARED.js",
						imports: []
					}
				}

				e = _controller.vitePreloadTag(entrypoint="src/main.js", head=false)

				expect(e).toInclude('rel="modulepreload"')
				expect(e).toInclude("assets/main-ABC.js")
				expect(e).toInclude("assets/chunk-SHARED.js")
			})

			it("emits via $viteHtmlHead and returns empty with default head=true", () => {
				application.wheels.viteDevMode = false
				application.wheels.viteManifestCache = {
					"src/main.js": {
						file: "assets/main-ABC.js",
						isEntry: true,
						imports: []
					}
				}
				request.$viteHeadCapture = []

				e = _controller.vitePreloadTag("src/main.js")

				expect(e).toBe("")
				var captured = ArrayToList(request.$viteHeadCapture, Chr(10))
				expect(captured).toInclude('rel="modulepreload"')
				expect(captured).toInclude("assets/main-ABC.js")
			})

			it("throws under strict mode when entry missing", () => {
				application.wheels.viteDevMode = false
				application.wheels.viteStrictManifest = true
				application.wheels.viteManifestCache = {}

				expect(function() {
					_controller.vitePreloadTag("src/missing.js")
				}).toThrow("Wheels.ViteAssetNotFound")
			})
		})

		describe("Tests that $viteDevMode", () => {

			beforeEach(() => {
				_controller = g.controller(name="dummy")
				_origDevMode = application.wheels.viteDevMode
			})

			afterEach(() => {
				application.wheels.viteDevMode = _origDevMode
			})

			it("returns true when setting is true", () => {
				application.wheels.viteDevMode = true

				expect(_controller.$viteDevMode()).toBeTrue()
			})

			it("returns false when setting is false", () => {
				application.wheels.viteDevMode = false

				expect(_controller.$viteDevMode()).toBeFalse()
			})
		})

		describe("Tests that $viteDevUrl", () => {

			beforeEach(() => {
				_controller = g.controller(name="dummy")
				_origDevUrl = application.wheels.viteDevServerUrl
			})

			afterEach(() => {
				application.wheels.viteDevServerUrl = _origDevUrl
			})

			it("joins URL and entrypoint with slash", () => {
				application.wheels.viteDevServerUrl = "http://localhost:5173"

				e = _controller.$viteDevUrl("src/main.js")

				expect(e).toBe("http://localhost:5173/src/main.js")
			})

			it("does not double slash", () => {
				application.wheels.viteDevServerUrl = "http://localhost:5173/"

				e = _controller.$viteDevUrl("/src/main.js")

				expect(e).toBe("http://localhost:5173/src/main.js")
			})
		})

		describe("Tests that $viteResolveAssets", () => {

			beforeEach(() => {
				_controller = g.controller(name="dummy")
				_origDevMode = application.wheels.viteDevMode
				_origBuildPath = application.wheels.viteBuildPath
				_origStrict = application.wheels.viteStrictManifest
				_origShowErr = application.wheels.showErrorInformation
				application.wheels.viteDevMode = false
				application.wheels.viteStrictManifest = true
			})

			afterEach(() => {
				application.wheels.viteDevMode = _origDevMode
				application.wheels.viteBuildPath = _origBuildPath
				application.wheels.viteStrictManifest = _origStrict
				application.wheels.showErrorInformation = _origShowErr
				var appKey = application.wo.$appKey()
				StructDelete(application[appKey], "viteManifestCache")
			})

			it("returns scripts=[entry.file] and empty preloads for leaf entry", () => {
				application.wheels.viteManifestCache = {
					"src/main.js": {
						file: "assets/main-LEAF.js",
						isEntry: true
					}
				}

				e = _controller.$viteResolveAssets("src/main.js")

				expect(e).toBeTypeOf("struct")
				expect(e.scripts).toBeTypeOf("array")
				expect(ArrayLen(e.scripts)).toBe(1)
				expect(e.scripts[1]).toBe("assets/main-LEAF.js")
				expect(e.styles).toBeTypeOf("array")
				expect(ArrayLen(e.styles)).toBe(0)
				expect(e.preloads).toBeTypeOf("array")
				expect(ArrayLen(e.preloads)).toBe(0)
			})

			it("includes entry CSS in styles array", () => {
				application.wheels.viteManifestCache = {
					"src/main.js": {
						file: "assets/main.js",
						isEntry: true,
						css: ["assets/main-MAIN.css"]
					}
				}

				e = _controller.$viteResolveAssets("src/main.js")

				expect(ArrayLen(e.styles)).toBe(1)
				expect(e.styles[1]).toBe("assets/main-MAIN.css")
			})

			it("walks transitive imports and collects preloads + chunk CSS", () => {
				application.wheels.viteManifestCache = {
					"src/main.js": {
						file: "assets/main-ABC.js",
						isEntry: true,
						imports: ["_chunk-SHARED.js"],
						css: ["assets/main-MAIN.css"]
					},
					"_chunk-SHARED.js": {
						file: "assets/chunk-SHARED.js",
						imports: ["_chunk-VENDOR.js"],
						css: ["assets/chunk-SHARED.css"]
					},
					"_chunk-VENDOR.js": {
						file: "assets/chunk-VENDOR.js",
						imports: [],
						css: ["assets/chunk-VENDOR.css"]
					}
				}

				e = _controller.$viteResolveAssets("src/main.js")

				expect(ArrayLen(e.scripts)).toBe(1)
				expect(e.scripts[1]).toBe("assets/main-ABC.js")
				expect(ArrayLen(e.preloads)).toBe(2)
				expect(ArrayContains(e.preloads, "assets/chunk-SHARED.js")).toBeTrue()
				expect(ArrayContains(e.preloads, "assets/chunk-VENDOR.js")).toBeTrue()
				expect(ArrayLen(e.styles)).toBe(3)
				expect(ArrayContains(e.styles, "assets/main-MAIN.css")).toBeTrue()
				expect(ArrayContains(e.styles, "assets/chunk-SHARED.css")).toBeTrue()
				expect(ArrayContains(e.styles, "assets/chunk-VENDOR.css")).toBeTrue()
			})

			it("dedupes diamond-dependency imports (two chunks sharing a third)", () => {
				application.wheels.viteManifestCache = {
					"src/main.js": {
						file: "assets/main.js",
						isEntry: true,
						imports: ["_chunk-A.js", "_chunk-B.js"]
					},
					"_chunk-A.js": {
						file: "assets/chunk-A.js",
						imports: ["_chunk-SHARED.js"]
					},
					"_chunk-B.js": {
						file: "assets/chunk-B.js",
						imports: ["_chunk-SHARED.js"]
					},
					"_chunk-SHARED.js": {
						file: "assets/chunk-SHARED.js",
						imports: []
					}
				}

				e = _controller.$viteResolveAssets("src/main.js")

				expect(ArrayLen(e.preloads)).toBe(3)
				// Each chunk exactly once
				var sharedCount = 0
				for (var p in e.preloads) {
					if (p == "assets/chunk-SHARED.js") { sharedCount++ }
				}
				expect(sharedCount).toBe(1)
			})

			it("terminates on cyclic imports graph", () => {
				application.wheels.viteManifestCache = {
					"src/main.js": {
						file: "assets/main.js",
						isEntry: true,
						imports: ["_chunk-A.js"]
					},
					"_chunk-A.js": {
						file: "assets/chunk-A.js",
						imports: ["_chunk-B.js"]
					},
					"_chunk-B.js": {
						file: "assets/chunk-B.js",
						imports: ["_chunk-A.js"]
					}
				}

				e = _controller.$viteResolveAssets("src/main.js")

				expect(ArrayLen(e.preloads)).toBe(2)
			})

			it("throws under strict mode when entry missing regardless of showErrorInformation", () => {
				application.wheels.viteStrictManifest = true
				application.wheels.showErrorInformation = false
				application.wheels.viteManifestCache = {}

				expect(function() {
					_controller.$viteResolveAssets("src/missing.js")
				}).toThrow("Wheels.ViteAssetNotFound")
			})

			it("returns empty resolved set under non-strict mode when entry missing and showErrorInformation=false", () => {
				application.wheels.viteStrictManifest = false
				application.wheels.showErrorInformation = false
				application.wheels.viteManifestCache = {}

				e = _controller.$viteResolveAssets("src/missing.js")

				expect(ArrayLen(e.scripts)).toBe(0)
				expect(ArrayLen(e.styles)).toBe(0)
				expect(ArrayLen(e.preloads)).toBe(0)
			})
		})

		describe("Tests that $viteManifest", () => {

			beforeEach(() => {
				_controller = g.controller(name="dummy")
				_origBuildPath = application.wheels.viteBuildPath
				_origManifestFile = application.wheels.viteManifestFile
			})

			afterEach(() => {
				application.wheels.viteBuildPath = _origBuildPath
				application.wheels.viteManifestFile = _origManifestFile
				var appKey = application.wo.$appKey()
				StructDelete(application[appKey], "viteManifestCache")
			})

			it("returns cached manifest on second call", () => {
				local.testManifest = {
					"src/main.js": {file: "assets/main-abc123.js"}
				}
				application.wheels.viteManifestCache = local.testManifest

				e = _controller.$viteManifest()

				expect(e).toBe(local.testManifest)
			})

			it("throws when manifest file does not exist", () => {
				var appKey = application.wo.$appKey()
				StructDelete(application[appKey], "viteManifestCache")
				application.wheels.viteBuildPath = "nonexistent_build_path"
				application.wheels.viteManifestFile = "nonexistent_manifest.json"

				expect(function() {
					_controller.$viteManifest()
				}).toThrow("Wheels.ViteManifestNotFound")
			})
		})
	}
}
