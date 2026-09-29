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
				// A quote inside a comment doesn't hide a call on its line (##3794 review).
				expect($countRawHttp('/* it''s */ cfhttp(url = "x");')).toBe(1);
				expect($countRawHttp('x = 1; /* say "hi */ new http(url = u);')).toBe(1);
				// A call inside a #...# interpolation is still a call.
				expect($countRawHttp('out("status: ##new http(url = u).send().getPrefix().statusCode##");')).toBe(1);
				expect($countRawHttp("msg = 'got ##cfhttp(url = u, result = ""r"")##';")).toBe(1);
				// Doubled quotes stay inside their string; an escaped ## is not interpolation.
				expect($countRawHttp('x = "a""b"; new http(url = u);')).toBe(1);
				expect($countRawHttp('x = "####cfhttp(url = u)";')).toBe(0);
				// A CFML string in script source may span lines (issue 3800): a call
				// after one counts, and a token inside one doesn't.
				expect($countRawHttp('x = "line one' & nl & 'line two"; new http(url = u);')).toBe(1);
				expect($countRawHttp('x = "a' & nl & 'cfhttp(url = u) b";')).toBe(0);
				// In .cfm template text a stray apostrophe ends at its line break.
				expect($countRawHttp("<p>Don't worry</p>" & nl & lt & 'cfhttp url="x" result="r">', true)).toBe(1);
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
			var count = $countRawHttp(FileRead(file), LCase(ListLast(file, ".")) == "cfm");
			if (count > 0) {
				result[rel] = count;
			}
		}
		return result;
	}

	/**
	 * The code in CFML source, in one left-to-right pass (##3794): line, block
	 * and tag comments are removed (their line breaks kept), and string text
	 * becomes spaces (quotes kept), except `#...#` interpolations, which are
	 * code. Doing it in one pass is what makes it right: a comment stripper
	 * that is not string-aware reads the "//" of a URL literal as a comment,
	 * and blanking strings first lets a quote inside a comment swallow code.
	 * In `.cfm` template text (`templateText`) a string or interpolation ends
	 * at a line break, so a stray apostrophe in HTML hides at most the rest of
	 * its line; in script source a CFML string may span lines (issue 3800). The CLI's
	 * $stripCfmlComments() is not string-aware, so it isn't used here.
	 */
	public string function $codeOnly(required string src, boolean templateText = false) {
		var s = arguments.src;
		var n = Len(s);
		var out = CreateObject("java", "java.lang.StringBuilder").init();
		var tagCommentOpen = Chr(60) & "!---";
		var stack = [];
		var i = 1;
		while (i <= n) {
			var c = Mid(s, i, 1);
			var mode = ArrayLen(stack) ? stack[ArrayLen(stack)].mode : "code";
			if (c == Chr(10) || c == Chr(13)) {
				if (arguments.templateText) {
					stack = [];
				}
				out.append(c);
				i++;
				continue;
			}
			if (mode == "string") {
				var q = stack[ArrayLen(stack)].q;
				if (Compare(c, q) == 0) {
					if (Compare(Mid(s, i + 1, 1), q) == 0) {
						out.append("  ");
						i += 2;
						continue;
					}
					ArrayDeleteAt(stack, ArrayLen(stack));
					out.append(c);
					i++;
					continue;
				}
				if (c == "##") {
					if (Mid(s, i + 1, 1) == "##") {
						out.append("  ");
						i += 2;
						continue;
					}
					ArrayAppend(stack, {mode = "interpolation"});
				}
				out.append(" ");
				i++;
				continue;
			}
			if (mode == "interpolation" && c == "##") {
				ArrayDeleteAt(stack, ArrayLen(stack));
				out.append(" ");
				i++;
				continue;
			}
			var two = Mid(s, i, 2);
			if (two == "//") {
				while (i <= n && Mid(s, i, 1) != Chr(10) && Mid(s, i, 1) != Chr(13)) {
					i++;
				}
				continue;
			}
			var closer = "";
			if (two == "/*") {
				closer = "*/";
			} else if (Mid(s, i, 5) == tagCommentOpen) {
				closer = "--->";
			}
			if (Len(closer)) {
				var stop = Find(closer, s, i + 2);
				stop = stop ? stop + Len(closer) - 1 : n;
				out.append(ReReplace(Mid(s, i, stop - i + 1), "[^\r\n]", "", "all"));
				i = stop + 1;
				continue;
			}
			if (c == '"' || c == "'") {
				ArrayAppend(stack, {mode = "string", q = c});
			}
			out.append(c);
			i++;
		}
		return out.toString();
	}

	/**
	 * Raw HTTP call sites in CFML source, read through $codeOnly() (comments
	 * and string text removed, #...# interpolations kept):
	 * `new http`, `cfhttp(...)`, the parenthesis-free script-tag forms
	 * (`cfhttp url=... {}`, `http url=...;`) and the cfhttp tag.
	 */
	public numeric function $countRawHttp(required string src, boolean templateText = false) {
		var code = $codeOnly(arguments.src, arguments.templateText);
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
