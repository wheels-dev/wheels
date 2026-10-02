/**
 * The app runner clears Lucee's compiled-page pool before EVERY run (#3962):
 * under the default inspectTemplate ("auto") a run started just after a spec
 * was edited could still run the previous version. `wheels coverage` relies
 * on the same clear: it instruments app/ and then asks the runner for
 * ?coverage=true, and under inspectTemplate=once a server that had already
 * compiled the app kept running the uninstrumented code and reported 0%.
 * pagePoolClear() is Lucee-only, so the call must be guarded.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("app runner page-pool clear", () => {

			it("clears the compiled-page pool before every run, ahead of the coverage branch, guarded for engines without pagePoolClear", () => {
				var src = FileRead(ExpandPath("/wheels/tests/app-runner.cfm"));
				var coverageAt = Find("StructKeyExists(url, ""coverage"") && url.coverage", src);
				expect(coverageAt).toBeGT(0, "the coverage block is missing");
				var guardAt = Find("StructKeyExists(GetFunctionList(), ""pagePoolClear"")", src);
				var clearAt = Find("pagePoolClear();", src);
				expect(guardAt).toBeGT(0, "the pagePoolClear engine guard is missing");
				expect(clearAt).toBeGT(guardAt, "pagePoolClear() must sit inside its engine guard");
				expect(clearAt).toBeLT(coverageAt, "pagePoolClear() must run for every run, not only inside the coverage branch");
				var coverageBlock = Mid(src, coverageAt, 900);
				expect(coverageBlock).toInclude("server.__wheels_cov = {};");
			});

			it("also drops the cached controller and model classes so every config() runs again", () => {
				var src = FileRead(ExpandPath("/wheels/tests/app-runner.cfm"));
				var block = Mid(src, Find("StructKeyExists(url, ""coverage"") && url.coverage", src), 1800);
				expect(block).toInclude("[""controllers"", ""models""]");
				expect(block).toInclude("StructClear(application.wheels[local.classCache]);");
			});

			it("the engine guard evaluates on this engine", () => {
				expect(IsBoolean(StructKeyExists(GetFunctionList(), "pagePoolClear"))).toBeTrue();
			});

		});

	}

}
