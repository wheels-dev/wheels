component extends="wheels.WheelsTest" {

	function beforeAll() {
		// Ensure Vite settings exist in BOTH application scopes.
		// $get() reads from application.$wheels (via $appKey()), so we must set there.
		var defaults = {
			viteDevMode = false,
			viteDevServerUrl = "http://localhost:5173",
			viteBuildPath = "build",
			viteManifestFile = ".vite/manifest.json"
		};
		for (var key in defaults) {
			if (StructKeyExists(application, "$wheels") && !StructKeyExists(application.$wheels, key)) {
				application.$wheels[key] = defaults[key];
			}
			if (StructKeyExists(application, "wheels") && !StructKeyExists(application.wheels, key)) {
				application.wheels[key] = defaults[key];
			}
		}
	}

	function run() {

		g = application.wo

		describe("Tests that Vite config settings", () => {

			beforeEach(() => {
				_controller = g.controller(name="dummy")
				// Save original settings
				_origDevMode = application.wheels.viteDevMode
				_origDevUrl = application.wheels.viteDevServerUrl
				_origBuildPath = application.wheels.viteBuildPath
				_origManifestFile = application.wheels.viteManifestFile
				_origEnvironment = application.wheels.environment
			})

			afterEach(() => {
				// Restore original settings
				application.wheels.viteDevMode = _origDevMode
				application.wheels.viteDevServerUrl = _origDevUrl
				application.wheels.viteBuildPath = _origBuildPath
				application.wheels.viteManifestFile = _origManifestFile
				application.wheels.environment = _origEnvironment
				if (StructKeyExists(application, "$wheels")) {
					StructDelete(application.$wheels, "viteManifestCache")
				}
			})

			it("has viteDevServerUrl default matching standard Vite port", () => {
				// The default Vite dev server port is 5173
				expect(application.wheels.viteDevServerUrl).toInclude("5173")
			})

			it("has viteBuildPath default of build", () => {
				// Vite config template outputs to public/build/
				expect(application.wheels.viteBuildPath).toBe("build")
			})

			it("has viteManifestFile default matching Vite 5+ manifest location", () => {
				// Vite 5+ generates manifest at .vite/manifest.json
				expect(application.wheels.viteManifestFile).toBe(".vite/manifest.json")
			})

			it("enables viteDevMode in development environment", () => {
				// The viteDevMode setting is derived from environment
				application.wheels.environment = "development"
				application.wheels.viteDevMode = (application.wheels.environment == "development")

				expect(application.wheels.viteDevMode).toBeTrue()
			})

			it("disables viteDevMode in production environment", () => {
				application.wheels.environment = "production"
				application.wheels.viteDevMode = (application.wheels.environment == "development")

				expect(application.wheels.viteDevMode).toBeFalse()
			})
		})

		describe("Tests that Vite proxy dev mode workflow", () => {

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
				if (StructKeyExists(application, "$wheels")) {
					StructDelete(application.$wheels, "viteManifestCache")
				}
			})

			it("generates script tags pointing to Vite dev server in dev mode", () => {
				application.wheels.viteDevMode = true
				application.wheels.viteDevServerUrl = "http://localhost:5173"

				e = _controller.viteScriptTag("src/main.js")

				// In proxy mode, browser loads from Vite dev server
				expect(e).toInclude("http://localhost:5173/src/main.js")
				expect(e).toInclude("http://localhost:5173/@vite/client")
			})

			it("generates fingerprinted paths matching build output in production", () => {
				application.wheels.viteDevMode = false
				application.wheels.viteBuildPath = "build"
				application.$wheels.viteManifestCache = {
					"src/main.js": {
						file: "assets/main-abc123.js",
						src: "src/main.js",
						isEntry: true,
						css: ["assets/main-def456.css"]
					}
				}

				e = _controller.viteScriptTag("src/main.js")

				// Production paths match Vite build output structure
				expect(e).toInclude("build/assets/main-abc123.js")
				expect(e).toInclude("build/assets/main-def456.css")
			})

			it("uses custom dev server URL when configured", () => {
				application.wheels.viteDevMode = true
				application.wheels.viteDevServerUrl = "http://localhost:3001"

				e = _controller.viteScriptTag("src/main.js")

				expect(e).toInclude("http://localhost:3001/src/main.js")
			})
		})
	}
}
