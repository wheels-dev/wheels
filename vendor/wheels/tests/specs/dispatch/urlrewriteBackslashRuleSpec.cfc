/**
 * The Tuckey `urlrewrite.xml` files Wheels ships (used by CommandBox) answer 400 for a
 * path containing a backslash or `%5C` (#4114). Without the rule, the pretty-URL rule
 * forwards the path to index.cfm and the servlet container fails with a 500 before
 * Wheels runs, so the rewrite config is the only place this can be handled. The rule
 * must come before the pretty-URL rule.
 *
 * Runs only in the framework repository, where all four files exist.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Shipped urlrewrite.xml files reject a backslash in the path", () => {

			var repoRoot = ExpandPath("/wheels") & "/../../";
			var files = [
				"public/urlrewrite.xml",
				"cli/lucli/templates/app/public/urlrewrite.xml",
				"examples/starter-app/public/urlrewrite.xml",
				"examples/tweet/public/urlrewrite.xml"
			];
			var inRepo = DirectoryExists(repoRoot & "cli/lucli/templates");

			// Each spec gets its file through TestBox's data argument: a closure would see
			// only the loop variable's last value.
			for (var relativePath in files) {
				it("#relativePath# has the rule ahead of the pretty-URL rule", (data) => {
					var content = FileRead(data.path);
					var rulePos = Find("<name>Reject a backslash in the path</name>", content);
					var prettyPos = Find("<name>Wheels pretty URLs</name>", content);
					expect(rulePos).toBeGT(0, "the backslash rule is missing");
					expect(prettyPos).toBeGT(rulePos, "the backslash rule must come before the pretty-URL rule");
					var rule = Mid(content, rulePos, prettyPos - rulePos);
					expect(rule).toInclude('<from casesensitive="false">(\\|%5C)</from>');
					expect(rule).toInclude('<set type="status">400</set>');
					expect(rule).toInclude("<to>null</to>");
				}, [], !inRepo, {path = repoRoot & relativePath});
			}
		});
	}

}
