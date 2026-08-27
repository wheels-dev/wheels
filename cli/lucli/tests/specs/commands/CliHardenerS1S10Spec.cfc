/**
 * CLI Hardener S1–S10 (LuCLI seam).
 *
 * S1 FIX lives in Destroy.cfc / DestroySpec (path-join escape).
 * This spec pins HOLD S3/S4/S5/S9 and proves S2/S7/S8 at source + evaluator
 * altitude. No exit-code flips. No SQLite pin unification.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.repoRoot = expandPath("/cli/../");
		variables.moduleSrc = fileRead(expandPath("/cli/lucli/Module.cfc"));
		variables.cliLocalScript = variables.repoRoot & "tools/test-cli-local.sh";
		variables.ciRunTests = variables.repoRoot & "tools/ci/run-tests.sh";
		variables.prYml = variables.repoRoot & ".github/workflows/pr.yml";
	}

	function run() {

		describe("S2 PROVE — generate controller ../X never hits validateName", () => {

			it("Module.generateController does not call validateName before CodeGen", () => {
				var body = $sliceFn(moduleSrc, "(?m)^[ \t]*private\s+string\s+function\s+generateController\s*\(", 500);
				expect(findNoCase("validateName", body)).toBe(0);
				expect(body).toInclude("codegen.generateController");
			});

		});

		describe("S3 HOLD — wheels doctor CRITICAL then return empty string", () => {

			it("doctor() prints CRITICAL then returns empty string and does not throw", () => {
				var body = $sliceFn(moduleSrc, "(?m)^[ \t]*public\s+string\s+function\s+doctor\s*\(", 6000);
				expect(body).toInclude('case "CRITICAL"');
				expect(body).toInclude("Status: CRITICAL");
				expect(body).toInclude("return """"");
				expect(findNoCase("throw(", body)).toBe(0);
				expect(findNoCase("rethrow", body)).toBe(0);
			});

			it("validate() already throws Wheels.ValidationFailed (contrast, not flipped)", () => {
				var body = $sliceFn(moduleSrc, "(?m)^[ \t]*public\s+string\s+function\s+validate\s*\(", 3000);
				expect(body).toInclude("Wheels.ValidationFailed");
				expect(body).toInclude("rethrow");
			});

		});

		describe("S4 HOLD — wheels analyze catch any then return empty string", () => {

			it("analyze() swallows catch (any) and still returns empty string", () => {
				var body = $sliceFn(moduleSrc, "(?m)^[ \t]*public\s+string\s+function\s+analyze\s*\(", 6000);
				expect(body).toInclude("catch (any e)");
				expect(body).toInclude("Analysis failed:");
				expect(body).toInclude("return """"");
				expect(findNoCase("rethrow", body)).toBe(0);
			});

		});

		describe("S5 HOLD — wheels start refuse paths return empty string", () => {

			it("start() not-a-project and name-collision refuses return empty string", () => {
				var body = $sliceFn(moduleSrc, "(?m)^[ \t]*public\s+string\s+function\s+start\s*\(", 8000);
				expect(body).toInclude("$isWheelsProjectDir");
				expect(body).toInclude("!reg.ours");
				expect(body).toInclude("return """"");
				expect(findNoCase("throw(", body)).toBe(0);
			});

		});

		describe("S7 PROVE — TestRunner.runViaHttp is a mirrored helper, not live wheels test", () => {

			it("$buildTestRunnerPath is app|core only — no /wheels/cli/tests", () => {
				var body = $sliceFn(moduleSrc, "(?m)^[ \t]*public\s+string\s+function\s+\$buildTestRunnerPath\s*\(", 500);
				expect(body).toInclude("/wheels/core/tests");
				expect(body).toInclude("/wheels/app/tests");
				expect(findNoCase("/wheels/cli/tests", body)).toBe(0);
			});

			it("CLI runner emits 417 on Fail/Error; test-cli-local.sh accepts 417 as a payload", () => {
				var runner = fileRead(expandPath("/cli/lucli/tests/runner.cfm"));
				expect(runner).toInclude("statuscode = 417");
				var sh = fileRead(cliLocalScript);
				expect(sh).toInclude("/wheels/cli/tests");
				expect(sh).toInclude('[ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "417" ]');
			});

		});

		describe("S8 PROVE — test-cli-local.sh STRICT default is 0; CI is strict", () => {

			it("pins WHEELS_CLI_TEST_STRICT default 0 and does not flip it to 1", () => {
				var sh = fileRead(cliLocalScript);
				expect(sh).toInclude('WHEELS_CLI_TEST_STRICT="${WHEELS_CLI_TEST_STRICT:-0}"');
				expect(find('WHEELS_CLI_TEST_STRICT="${WHEELS_CLI_TEST_STRICT:-1}"', sh)).toBe(0);
				expect(sh).toInclude("os.environ.get('WHEELS_CLI_TEST_STRICT', '0') == '1'");
			});

			it("CI tools/ci/run-tests.sh fail-closes on any CLI Fail/Error", () => {
				var ci = fileRead(ciRunTests);
				expect(ci).toInclude("CLI_TOTAL_FAILURES");
				expect(ci).toInclude('elif [ "$CLI_TOTAL_FAILURES" -gt 0 ]');
				expect(ci).toInclude("CLI_OK=false");
				expect(ci).toInclude('if [ "$CORE_OK" = false ] || [ "$CLI_OK" = false ]; then');
			});

			it("STRICT=0 exits 0 on a non-deploy fail; STRICT=1 fails closed", () => {
				var mockPath = getTempDirectory() & "cli-strict-nongate-" & createUUID() & ".json";
				fileWrite(mockPath, $nongatingFailJson());
				var loose = $evalCliLocalStrict(mockJsonPath = mockPath, strictFlag = "0");
				var tight = $evalCliLocalStrict(mockJsonPath = mockPath, strictFlag = "1");
				if (fileExists(mockPath)) {
					fileDelete(mockPath);
				}
				expect(loose).toBe(0);
				expect(tight).toBe(1);
			});

			it("STRICT=0 still gates a deploy-bundle fail (default is not 'always 0')", () => {
				var mockPath = getTempDirectory() & "cli-strict-deploy-" & createUUID() & ".json";
				fileWrite(mockPath, $deployFailJson());
				var code = $evalCliLocalStrict(mockJsonPath = mockPath, strictFlag = "0");
				if (fileExists(mockPath)) {
					fileDelete(mockPath);
				}
				expect(code).toBe(1);
			});

		});

		describe("S9 HOLD — SQLite JDBC pins stay forked", () => {

			it("wheels start stages 3.49.1.0; test-cli-local.sh downloads 3.49.1.0; CI pr.yml uses 3.50.3.0", () => {
				expect(moduleSrc).toInclude("sqlite-jdbc-3.49.1.0");
				expect(find("3.50.3.0", moduleSrc)).toBe(0);
				var sh = fileRead(cliLocalScript);
				expect(sh).toInclude("sqlite-jdbc/3.49.1.0/sqlite-jdbc-3.49.1.0.jar");
				expect(find("3.50.3.0", sh)).toBe(0);
				var pr = fileRead(prYml);
				expect(pr).toInclude("sqlite-jdbc/3.50.3.0/sqlite-jdbc-3.50.3.0.jar");
				expect(find("3.49.1.0", pr)).toBe(0);
			});

		});

	}

	private string function $sliceFn(required string src, required string pattern, numeric window = 800) {
		var startIdx = reFindNoCase(arguments.pattern, arguments.src);
		expect(startIdx).toBeGT(0);
		var chunk = mid(arguments.src, startIdx, arguments.window);
		// Trim at the next top-level function so a generous window cannot
		// leak the following method (e.g. analyze() into validate()).
		var nextFn = reFindNoCase("(?m)^[ \t]*(public|private)\s+\w+\s+function\s+", chunk, 2);
		if (isArray(nextFn)) {
			nextFn = arrayLen(nextFn) ? nextFn[1] : 0;
		}
		if (nextFn > 1) {
			chunk = left(chunk, nextFn - 1);
		}
		return chunk;
	}

	private string function $nongatingFailJson() {
		return '{"totalPass":10,"totalFail":1,"totalError":0,"bundleStats":[{"name":"cli.lucli.tests.specs.services.FooSpec","suiteStats":[{"specStats":[{"name":"fails on purpose","status":"Failed","failMessage":"boom"}]}]}]}';
	}

	private string function $deployFailJson() {
		return '{"totalPass":10,"totalFail":1,"totalError":0,"bundleStats":[{"name":"cli.lucli.tests.specs.deploy.cli.DeployMainCliSpec","suiteStats":[{"specStats":[{"name":"deploy fail","status":"Failed","failMessage":"boom"}]}]}]}';
	}

	private numeric function $evalCliLocalStrict(required string mockJsonPath, required string strictFlag) {
		var shSrc = fileRead(variables.cliLocalScript);
		var importAt = find("import json, os, sys", shSrc);
		var exitNeedle = "sys.exit(0 if gating_failures == 0 else 1)";
		var exitAt = find(exitNeedle, shSrc);
		expect(importAt).toBeGT(0);
		expect(exitAt).toBeGT(0);
		var inner = mid(shSrc, importAt, exitAt + len(exitNeedle) - importAt);

		var bs = chr(92);
		var q = chr(34);
		inner = replace(inner, "$RESULT_FILE", arguments.mockJsonPath, "all");
		inner = replace(inner, bs & q, q, "all");
		inner = replace(inner, bs & bs & "n", bs & "n", "all");

		var pyPath = getTempDirectory() & "cli-strict-eval-" & createUUID() & ".py";
		fileWrite(pyPath, inner);

		var cmd = createObject("java", "java.util.ArrayList").init();
		cmd.add("/usr/bin/python3");
		cmd.add(pyPath);
		var pb = createObject("java", "java.lang.ProcessBuilder").init(cmd);
		pb.redirectErrorStream(true);
		pb.environment().put("WHEELS_CLI_TEST_STRICT", arguments.strictFlag);
		var proc = pb.start();
		proc.getInputStream().readAllBytes();
		proc.waitFor();
		var code = proc.exitValue();
		if (fileExists(pyPath)) {
			fileDelete(pyPath);
		}
		return code;
	}

}
