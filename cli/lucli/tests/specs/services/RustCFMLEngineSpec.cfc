/**
 * Coverage for the RustCFML engine backend's pure helpers (platform→asset
 * mapping, project-key hashing, state path) and the source-level shape of
 * the process plumbing. install()'s download verification is covered by
 * RustCFMLEngineInstallSpec; start/stop shell out to kill and are exercised
 * end-to-end manually, not here.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		// Absolute dotted path (via the /cli mapping) — a bare `services.`
		// here would resolve relative to this spec's own package.
		variables.svc = new cli.lucli.services.rustcfml.RustCFMLEngine();
	}

	function run() {

		describe("RustCFMLEngine", () => {

			it("maps the current platform to one of the published assets, or refuses it clearly", () => {
				var state = {asset = "", type = ""};
				try {
					state.asset = variables.svc.assetName();
				} catch (any e) {
					state.type = e.type;
				}
				if (Len(state.type)) {
					expect(state.type).toBe("Wheels.RustCFML.UnsupportedPlatform");
				} else {
					expect(
						listFindNoCase("rustcfml-linux-x86_64,rustcfml-linux-aarch64,rustcfml-macos-aarch64", state.asset) > 0
					).toBeTrue("unexpected asset name: " & state.asset);
				}
			});

			it("maps each published platform to its release asset", () => {
				expect(variables.svc.$assetFor("Mac OS X", "aarch64")).toBe("rustcfml-macos-aarch64");
				expect(variables.svc.$assetFor("Mac OS X", "arm64")).toBe("rustcfml-macos-aarch64");
				expect(variables.svc.$assetFor("Linux", "amd64")).toBe("rustcfml-linux-x86_64");
				expect(variables.svc.$assetFor("Linux", "x86_64")).toBe("rustcfml-linux-x86_64");
				expect(variables.svc.$assetFor("Linux", "aarch64")).toBe("rustcfml-linux-aarch64");
			});

			it("refuses an Intel Mac with a clear unsupported-platform error, not a 404 download", () => {
				for (var arch in ["x86_64", "amd64"]) {
					var state = {type = "", message = ""};
					try {
						variables.svc.$assetFor("Mac OS X", arch);
					} catch (any e) {
						state.type = e.type;
						state.message = e.message & " " & e.detail;
					}
					expect(state.type).toBe("Wheels.RustCFML.UnsupportedPlatform", "Mac OS X / #arch#");
					expect(state.message).toInclude("Intel");
					expect(state.message).toInclude("wheels start");
				}
			});

			it("gives an x86_64 JVM on Apple Silicon (Rosetta) the native arm64 build", () => {
				expect(variables.svc.$assetFor("Mac OS X", "x86_64", true)).toBe("rustcfml-macos-aarch64");
				expect(variables.svc.$assetFor("Mac OS X", "amd64", true)).toBe("rustcfml-macos-aarch64");
				// The hardware flag never turns Linux x86_64 into an arm build.
				expect(variables.svc.$assetFor("Linux", "amd64", true)).toBe("rustcfml-linux-x86_64");
			});

			it("reads the Mac's hardware arch as a boolean, false off macOS", () => {
				var answer = variables.svc.$macHasArm64Hardware();
				expect(isBoolean(answer)).toBeTrue();
				if (!findNoCase("mac", createObject("java", "java.lang.System").getProperty("os.name"))) {
					expect(answer).toBeFalse();
				}
			});

			it("refuses a platform RustCFML has no build for", () => {
				expect(() => variables.svc.$assetFor("Windows 11", "amd64")).toThrow(type = "Wheels.RustCFML.UnsupportedPlatform");
				expect(() => variables.svc.$assetFor("FreeBSD", "amd64")).toThrow(type = "Wheels.RustCFML.UnsupportedPlatform");
			});

			it("hashes a project root to a stable filesystem key", () => {
				var key = variables.svc.$projectKey("/Users/me/myapp");
				expect(len(key)).toBe(32);
				expect(key).toBe(variables.svc.$projectKey("/Users/me/myapp"));
				expect(key == variables.svc.$projectKey("/Users/me/other")).toBeFalse();
			});

			it("derives the state path under the wheels home, keyed by the project", () => {
				var path = variables.svc.$statePath("/Users/me/myapp");
				expect(findNoCase("/rustcfml/servers/", path) > 0).toBeTrue(path);
				expect(findNoCase(variables.svc.$projectKey("/Users/me/myapp") & ".json", path) > 0).toBeTrue(path);
			});

			it("declares the pinned version and detached-serve plumbing in source", () => {
				var src = fileRead(expandPath("/cli/lucli/services/rustcfml/RustCFMLEngine.cfc"));
				expect(findNoCase("engineVersion", src) > 0).toBeTrue();
				expect(findNoCase("--serve", src) > 0).toBeTrue();
				expect(findNoCase("ProcessBuilder", src) > 0).toBeTrue();
				expect(findNoCase("redirectOutput", src) > 0).toBeTrue();
			});

			it("wires `wheels start --engine=rustcfml` and auto-detecting `stop` to the backend", () => {
				var src = fileRead(expandPath("/cli/lucli/Module.cfc"));
				expect(findNoCase('engine == "rustcfml"', src) > 0).toBeTrue();
				expect(findNoCase("new services.rustcfml.RustCFMLEngine()", src) > 0).toBeTrue();
				expect(findNoCase("rustSvc.status(variables.projectRoot)", src) > 0).toBeTrue();
			});

			it("prefixes /index.cfm on the server URL base so RustCFML path-info routes resolve", () => {
				var src = fileRead(expandPath("/cli/lucli/Module.cfc"));
				expect(findNoCase("$serverUrlBase", src) > 0).toBeTrue();
				expect(findNoCase("$serverUrlBase(serverPort)", src) > 0).toBeTrue();
				expect(findNoCase("/index.cfm", src) > 0).toBeTrue();

				// Regression guard: the helper is private `$serverUrlBase`. A call
				// site missing the `$` (bare `serverUrlBase(serverPort)`) throws
				// "No matching function [serverUrlBase] found" at runtime. Strip the
				// prefixed form and assert no bare call remains.
				var stripped = reReplaceNoCase(src, "\$serverUrlBase\(serverPort\)", "", "all");
				expect(findNoCase("serverUrlBase(serverPort)", stripped) == 0).toBeTrue();
			});

		});

	}

}
