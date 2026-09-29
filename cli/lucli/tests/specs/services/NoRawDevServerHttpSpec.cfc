/**
 * Guards the verified server transport (##3768).
 *
 * Requests to a running dev server must go through Module.cfc's
 * makeHttpRequest / makeHttpRequestWithStatus / makeHttpPost, which prove the
 * listener is this project's own server before sending anything (the reload
 * password included). MigrationRunner.runViaHttp and TestRunner.runViaHttp
 * used a raw `new http` to localhost and skipped that proof; they had no
 * callers and were removed.
 *
 * This spec pins the set of CLI source files that make raw HTTP calls. Each
 * allowlisted file only talks to an external host. A new file on the list
 * must either do the same or switch to the verified transport.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("CLI raw HTTP call sites (##3768)", () => {

			it("only the allowlisted external-download files use raw HTTP", () => {
				var allowed = [
					"Module.cfc", // browser setup: Playwright JAR download from Maven Central
					"services/UpdateChecker.cfc", // release feed
					"services/packages/HttpClient.cfc" // package registry
				];
				var found = $filesWithRawHttp(expandPath("/cli/lucli"));
				for (var path in found) {
					expect(ArrayFindNoCase(allowed, path) > 0).toBeTrue(
						"#path# makes a raw HTTP call. Requests to the dev server must use the"
						& " verified transport (makeHttpRequest* / makeHttpPost in Module.cfc)."
					);
				}
				// Every allowlisted entry is still real, so the list can't go stale.
				for (var path in allowed) {
					expect(ArrayFindNoCase(found, path) > 0).toBeTrue(
						"#path# no longer makes a raw HTTP call; drop it from the allowlist."
					);
				}
			});

			it("the removed runViaHttp helpers stay removed", () => {
				for (var name in ["MigrationRunner", "TestRunner"]) {
					var src = FileRead(expandPath("/cli/lucli/services/#name#.cfc"));
					expect(FindNoCase("runViaHttp", src)).toBe(0, "#name#.cfc still defines runViaHttp");
				}
			});

		});

	}

	/**
	 * Relative paths (forward slashes) of non-test .cfc/.cfm files under
	 * `root` with a raw HTTP call on a non-comment line.
	 */
	public array function $filesWithRawHttp(required string root) {
		var base = Replace(arguments.root, "\", "/", "all");
		if (Right(base, 1) != "/") {
			base &= "/";
		}
		var result = [];
		// Copy DirectoryList into our own array before appending (BoxLang's is fixed-size).
		for (var file in DirectoryList(arguments.root, true, "path", "*.cfc|*.cfm")) {
			var rel = Replace(Replace(file, "\", "/", "all"), base, "");
			if (Left(rel, 6) == "tests/") {
				continue;
			}
			if ($hasRawHttp(FileRead(file))) {
				ArrayAppend(result, rel);
			}
		}
		return result;
	}

	/** True when a non-comment line holds `new http(`, `cfhttp(` or a cfhttp tag. */
	public boolean function $hasRawHttp(required string src) {
		for (var line in ListToArray(arguments.src, Chr(10))) {
			var trimmed = Trim(line);
			if (
				Left(trimmed, 1) == "*"
				|| Left(trimmed, 2) == "//"
				|| Left(trimmed, 2) == "/*"
				|| Left(trimmed, 5) == Chr(60) & "!---"
			) {
				continue;
			}
			// Chr(60) keeps a literal tag opener out of this file (Lucee's tag scanner).
			if (ReFindNoCase("\bnew\s+http\s*\(|\bcfhttp\s*\(|" & Chr(60) & "cfhttp\b", trimmed)) {
				return true;
			}
		}
		return false;
	}

}
