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
			viteManifestFile = ".vite/manifest.json"
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
			})

			afterEach(() => {
				// Restore original settings
				application.wheels.viteDevMode = _origDevMode
				application.wheels.viteDevServerUrl = _origDevUrl
				application.wheels.viteBuildPath = _origBuildPath
				application.wheels.viteManifestFile = _origManifestFile
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

			it("throws when entrypoint not in manifest", () => {
				application.wheels.viteDevMode = false
				application.wheels.viteManifestCache = {}

				expect(function() {
					_controller.viteStyleTag("src/missing.css")
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
