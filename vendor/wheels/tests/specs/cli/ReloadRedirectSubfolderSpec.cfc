/**
 * The reload of a running app redirects from public/Application.cfc's
 * $buildRedirectUrl(), not from the framework. On a subpath install (#3948) the
 * redirect has to put the subfolder back, as the framework's own reload redirect
 * does, so $buildRedirectUrl() passes the path through $reloadRedirectPath(),
 * with a local fallback when that helper isn't available. All four copies of the
 * template carry the same code.
 *
 * Structural (reads each copy): Application.cfc can't be instantiated inside the
 * suite. The helper's behaviour is covered by global/reloadRedirectPathSpec.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("$buildRedirectUrl keeps the subfolder", () => {

			var repoRoot = expandPath("/wheels/../..");
			var targets = [
				"cli/lucli/templates/app/public/Application.cfc",
				"public/Application.cfc",
				"examples/tweet/public/Application.cfc",
				"examples/starter-app/public/Application.cfc"
			];
			var inRepo = DirectoryExists(repoRoot & "/cli/lucli/templates");

			// Each spec gets its file through TestBox's data argument.
			for (var rel in targets) {
				it("passes the redirect through the framework helper in " & rel, (data) => {
					var content = FileRead(data.path);
					var fnStart = Find("public string function $buildRedirectUrl()", content);
					var fallbackStart = Find("public string function $normaliseRedirectPath(", content);
					expect(fnStart).toBeGT(0, "missing $buildRedirectUrl()");
					expect(fallbackStart).toBeGT(fnStart, "missing $normaliseRedirectPath() after $buildRedirectUrl()");
					var body = Mid(content, fnStart, fallbackStart - fnStart);
					var helperCall = Find("application.wo.$reloadRedirectPath(path = local.redirectPath)", body);
					var fallbackCall = Find("this.$normaliseRedirectPath(local.redirectPath)", body);
					var returnPos = Find("return local.redirectPath;", body);
					expect(helperCall).toBeGT(0, "$buildRedirectUrl() must call $reloadRedirectPath()");
					expect(Find("try {", body)).toBeGT(0, "the helper call must be inside a try");
					expect(fallbackCall).toBeGT(helperCall, "the fallback must follow the helper call");
					expect(returnPos).toBeGT(fallbackCall, "the result must be returned after both");
				}, [], !inRepo, {path = repoRoot & "/" & rel});
			}
		});
	}

}
