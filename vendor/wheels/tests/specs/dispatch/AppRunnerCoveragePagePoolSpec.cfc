/**
 * `wheels coverage` instruments app/ and then asks the app runner to run the
 * suite with ?coverage=true. Under Lucee's inspectTemplate=once a server that
 * had already compiled the app kept running the uninstrumented code and
 * reported 0% coverage, so coverage mode must clear the compiled-page pool
 * first. pagePoolClear() is Lucee-only, so the call must be guarded.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("app runner coverage mode", () => {

			it("clears the compiled-page pool before the run, guarded for engines without pagePoolClear", () => {
				var src = FileRead(ExpandPath("/wheels/tests/app-runner.cfm"));
				var start = Find("StructKeyExists(url, ""coverage"") && url.coverage", src);
				expect(start).toBeGT(0, "the coverage block is missing");
				var block = Mid(src, start, 900);
				expect(block).toInclude("server.__wheels_cov = {};");
				expect(block).toInclude("StructKeyExists(GetFunctionList(), ""pagePoolClear"")");
				expect(block).toInclude("pagePoolClear();");
				expect(Find("pagePoolClear();", block)).toBeGT(Find("StructKeyExists(GetFunctionList(), ""pagePoolClear"")", block));
			});

			it("the engine guard evaluates on this engine", () => {
				expect(IsBoolean(StructKeyExists(GetFunctionList(), "pagePoolClear"))).toBeTrue();
			});

		});

	}

}
