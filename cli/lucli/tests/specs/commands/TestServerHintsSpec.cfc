/**
 * What `wheels test` says when no server is running (issue 3972).
 *
 * tools/test-local.sh exists only in the Wheels framework repository, so an
 * app is told to run `wheels start` and nothing else; the framework repository
 * (tools/test-local.sh AND vendor/wheels/tests/specs) also gets the script.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.roots = [];
		// A generated app: it vendors the framework's specs but has no tools/test-local.sh.
		variables.appRoot = newRoot("app", ["/vendor/wheels/tests/specs"], []);
		// The framework repository.
		variables.repoRoot = newRoot("repo", ["/vendor/wheels/tests/specs", "/tools"], ["/tools/test-local.sh"]);
		// An app that happens to have its own tools/test-local.sh but no framework specs.
		variables.toolsOnlyRoot = newRoot("tools-only", ["/tools"], ["/tools/test-local.sh"]);
	}

	function afterAll() {
		for (var root in variables.roots) {
			if (Len(root) > 10 && directoryExists(root)) {
				directoryDelete(root, true);
			}
		}
	}

	private string function newRoot(required string label, required array dirs, required array files) {
		var root = getTempDirectory() & "wheels-cli-server-hints-" & arguments.label & "-" & createUUID();
		directoryCreate(root, true, true);
		for (var dir in arguments.dirs) {
			directoryCreate(root & dir, true, true);
		}
		for (var file in arguments.files) {
			fileWrite(root & file, "##!/usr/bin/env bash" & chr(10));
		}
		arrayAppend(variables.roots, root);
		return root;
	}

	function run() {

		describe("$testServerHints (issue 3972)", () => {

			it("tells an app to start its server, and nothing about tools/test-local.sh", () => {
				var hints = new cli.lucli.Module(cwd = variables.appRoot).$testServerHints();
				expect(arrayLen(hints)).toBe(1);
				expect(hints[1]).toInclude("wheels start");
				expect(arrayToList(hints, " ")).notToInclude("test-local.sh");
			});

			it("also suggests tools/test-local.sh in the framework repository", () => {
				var hints = new cli.lucli.Module(cwd = variables.repoRoot).$testServerHints();
				expect(arrayLen(hints)).toBe(2);
				expect(hints[1]).toInclude("wheels start");
				expect(hints[2]).toInclude("bash tools/test-local.sh");
			});

			it("needs the framework specs as well as the script", () => {
				var hints = new cli.lucli.Module(cwd = variables.toolsOnlyRoot).$testServerHints();
				expect(arrayToList(hints, " ")).notToInclude("test-local.sh");
			});

		});

	}

}
