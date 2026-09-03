/**
 * Coverage for the RustCFML engine backend's pure helpers (platform→asset
 * mapping, project-key hashing, state path) and the source-level shape of
 * the process plumbing. The process-bound methods (install/start/stop)
 * shell out to curl/kill and are exercised end-to-end manually, not here.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		// Absolute dotted path (via the /cli mapping) — a bare `services.`
		// here would resolve relative to this spec's own package.
		variables.svc = new cli.lucli.services.rustcfml.RustCFMLEngine();
	}

	function run() {

		describe("RustCFMLEngine", () => {

			it("maps the current platform to one of the four known assets", () => {
				var asset = variables.svc.assetName();
				expect(
					listFindNoCase(
						"rustcfml-linux-x86_64,rustcfml-linux-aarch64,rustcfml-macos-aarch64,rustcfml-macos-x86_64",
						asset
					) > 0
				).toBeTrue("unexpected asset name: " & asset);
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

		});

	}

}
