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
 * This spec pins how many raw HTTP call sites each CLI source file has. Every
 * pinned site talks to an external host. A new raw call anywhere, including a
 * second one in a pinned file, fails: route it through the verified
 * transport, or, if it really is an external download, raise the count here.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		// Comment stripping reuses the CLI's own helper (anti-pattern 14).
		variables.analysis = new cli.lucli.services.Analysis(
			helpers = new cli.lucli.services.Helpers(),
			projectRoot = expandPath("/")
		);
		makePublic(variables.analysis, "$stripCfmlComments");
	}

	function run() {

		describe("CLI raw HTTP call sites (##3768)", () => {

			it("only the pinned external-download sites use raw HTTP", () => {
				var expected = {
					// browser setup: Playwright JAR download from Maven Central
					"Module.cfc": 1,
					// release feed
					"services/UpdateChecker.cfc": 1,
					// package registry: JSON GET + file download
					"services/packages/HttpClient.cfc": 2
				};
				var found = $rawHttpSites(expandPath("/cli/lucli"));
				for (var path in found) {
					expect(found[path]).toBe(
						StructKeyExists(expected, path) ? expected[path] : 0,
						"#path# has #found[path]# raw HTTP call site(s). Requests to the dev server must use the"
						& " verified transport (makeHttpRequest* / makeHttpPost in Module.cfc)."
					);
				}
				// Every pinned file still has its sites, so the counts can't go stale.
				for (var path in expected) {
					expect(StructKeyExists(found, path) ? found[path] : 0).toBe(
						expected[path],
						"#path# no longer has #expected[path]# raw HTTP call site(s); update the pinned count."
					);
				}
			});

			it("counts every raw HTTP form, and nothing inside comments", () => {
				var lt = Chr(60);
				var nl = Chr(10);
				// Script function forms.
				expect($countRawHttp('r = new http(url = "x");')).toBe(1);
				expect($countRawHttp('h = new http();' & nl & 'h.send();')).toBe(1);
				expect($countRawHttp('cfhttp(url = "https://x", result = "r");')).toBe(1);
				// Lucee script-tag forms without parentheses.
				expect($countRawHttp('cfhttp url = "https://x" result = "r" {}')).toBe(1);
				expect($countRawHttp('cfhttp url="x" result="r";')).toBe(1);
				expect($countRawHttp('http url = "https://x" result = "r";')).toBe(1);
				expect($countRawHttp('if (a) { http url="x" result="r"; }')).toBe(1);
				expect($countRawHttp('x = 1; http method="get" url="x";')).toBe(1);
				// Tag form.
				expect($countRawHttp(lt & 'cfhttp url="https://x" result="r">')).toBe(1);
				// Several sites in one source are each counted.
				expect($countRawHttp('cfhttp(url="a");' & nl & 'http url="b";' & nl & 'new http();')).toBe(3);
				// Comments hide calls: line, block (also mid-line), doc and tag comments.
				expect($countRawHttp('// cfhttp(url="x");')).toBe(0);
				expect($countRawHttp('/* new http(url="x") */ x = 1;')).toBe(0);
				expect($countRawHttp('x = 1; /* cfhttp url="x" {} */ y = 2;')).toBe(0);
				expect($countRawHttp('/**' & nl & ' * Uses cfhttp (script syntax), not new http()' & nl & ' */')).toBe(0);
				expect($countRawHttp(lt & '!--- ' & lt & 'cfhttp url="x"> --->')).toBe(0);
				// A URL literal earlier on the line doesn't hide the call (##3794).
				expect($countRawHttp('u = "http://localhost:8190/"; cfhttp(url=u, result="r");')).toBe(1);
				expect($countRawHttp('out("see https://x"); http url=u result="r";')).toBe(1);
				expect($countRawHttp("u = 'http://x/'; new http(url=u);")).toBe(1);
				// Brace-less if / else bodies (##3794).
				expect($countRawHttp('if (x) http url=u result="r";')).toBe(1);
				expect($countRawHttp('if (x) y = 1; else http url=u result="r";')).toBe(1);
				// A call token inside a string is not a call.
				expect($countRawHttp('out("cfhttp(url=x) is not allowed here");')).toBe(0);
				// Names that only contain "http" are not calls.
				expect($countRawHttp('var httpResult = makeHttpRequest(requestUrl = u);')).toBe(0);
				expect($countRawHttp('c = new packages.HttpClient();')).toBe(0);
				expect($countRawHttp('out("Use http or https");')).toBe(0);
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
	 * Raw HTTP call-site counts, keyed by path relative to `root` (forward
	 * slashes), for the non-test .cfc/.cfm files that have any.
	 */
	public struct function $rawHttpSites(required string root) {
		var base = Replace(arguments.root, "\", "/", "all");
		if (Right(base, 1) != "/") {
			base &= "/";
		}
		var result = {};
		for (var file in DirectoryList(arguments.root, true, "path", "*.cfc|*.cfm")) {
			var rel = Replace(Replace(file, "\", "/", "all"), base, "");
			if (Left(rel, 6) == "tests/") {
				continue;
			}
			var count = $countRawHttp(FileRead(file));
			if (count > 0) {
				result[rel] = count;
			}
		}
		return result;
	}

	/**
	 * Raw HTTP call sites in CFML source, string literals blanked and comments
	 * stripped first:
	 * `new http`, `cfhttp(...)`, the parenthesis-free script-tag forms
	 * (`cfhttp url=... {}`, `http url=...;`) and the cfhttp tag.
	 */
	public numeric function $countRawHttp(required string src) {
		// Blank string literals first (quotes kept), so the "//" in a URL literal
		// can't read as a line comment and hide the rest of its line (##3794).
		// Neither pattern crosses a line break, so the scan stays line-anchored.
		var code = ReReplace(arguments.src, '"(?:[^"\r\n]|"")*"', '""', "all");
		code = ReReplace(code, "'(?:[^'\r\n]|'')*'", "''", "all");
		code = variables.analysis.$stripCfmlComments(code);
		var patterns = [
			// new http(...) and new http;
			"\bnew\s+http\b",
			// cfhttp(...), script-tag cfhttp url=... and the cfhttp tag: the \b
			// also sits between the tag opener and "cfhttp", so each counts once.
			"\bcfhttp(\s*\(|\s+[a-z]+\s*=)",
			// Lucee script-tag http url=...; at the start of a statement, including
			// the body of a brace-less if (...) / else (##3794).
			"(?m)(^|[;{})]|\belse)[ \t]*http\s+[a-z]+\s*="
		];
		var count = 0;
		for (var pattern in patterns) {
			count += ArrayLen(ReMatchNoCase(pattern, code));
		}
		return count;
	}

}
