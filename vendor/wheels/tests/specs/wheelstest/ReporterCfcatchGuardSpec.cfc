/**
 * Guards for optional cfcatch members in the forked TestBox runtime
 * (vendor/wheels/wheelstest/system).
 *
 * A cfcatch-shaped object is not guaranteed to carry the optional members
 * `stackTrace` / `extendedInfo` / `errorCode`: engine variants and
 * custom-thrown or deserialized exception objects can omit them. Before the
 * guards, a single missing member crashed spec-result recording or report
 * generation, nuking the entire bundle's results.
 *
 * The BaseSpec recording seams (runSpec / runTestMethod catch blocks) cannot
 * be exercised with a synthetic member-less exception in-process: their catch
 * blocks only ever receive real engine cfcatch objects, and CFML `throw()`
 * always synthesizes the full member set on the engines CI runs. The
 * data-driven seams below (ANTJUnitReporter renders stats/error structs that
 * are plain data) exercise the guarded reads directly; a structural scan
 * pins the guard idiom for every remaining site, including the BaseSpec ones.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Reporter guards for optional cfcatch members", function() {

			it("ANTJUnit buildTestCase renders an error spec whose exception lacks stackTrace and extendedInfo", function() {
				var reporter = new wheels.wheelstest.system.reports.ANTJUnitReporter();
				makePublic(reporter, "buildTestCase");
				var buffer = CreateObject("java", "java.lang.StringBuilder").init("");
				// struct-shaped exception with only message/detail/type — no
				// stackTrace, no extendedInfo, no errorCode
				var fakeException = {
					type = "Custom.Type",
					message = "boom message",
					detail = "boom detail"
				};
				var specStats = {
					name = "guarded error spec",
					totalDuration = 10,
					status = "Error",
					failMessage = "boom message",
					failOrigin = [],
					error = fakeException
				};
				var state = {threw = false, xml = ""};
				try {
					reporter.buildTestCase(
						buffer      = buffer,
						results     = {},
						specStats   = specStats,
						bundleStats = {path = "tests.specs.FakeBundle"},
						fullName    = "Fake Suite"
					);
					state.xml = buffer.toString();
				} catch (any e) {
					state.threw = true;
				}
				expect(state.threw).toBeFalse();
				expect(state.xml).toInclude("boom message");
				expect(state.xml).toInclude("Custom.Type");
				// the guarded stack-trace read defaulted to empty string and
				// the error element still closed cleanly
				expect(state.xml).toInclude("</error>");
				expect(state.xml).toInclude("</testcase>");
			});

			it("ANTJUnit buildTestCase renders a failed spec whose stats lack failExtendedInfo entirely", function() {
				var reporter = new wheels.wheelstest.system.reports.ANTJUnitReporter();
				makePublic(reporter, "buildTestCase");
				var buffer = CreateObject("java", "java.lang.StringBuilder").init("");
				// no failDetail / failExtendedInfo keys at all — the isNull()
				// guards must skip them instead of throwing
				var specStats = {
					name = "guarded failed spec",
					totalDuration = 5,
					status = "Failed",
					failMessage = "assertion failed",
					failOrigin = []
				};
				var state = {threw = false, xml = ""};
				try {
					reporter.buildTestCase(
						buffer      = buffer,
						results     = {},
						specStats   = specStats,
						bundleStats = {path = "tests.specs.FakeBundle"},
						fullName    = "Fake Suite"
					);
					state.xml = buffer.toString();
				} catch (any e) {
					state.threw = true;
				}
				expect(state.threw).toBeFalse();
				expect(state.xml).toInclude("assertion failed");
				expect(state.xml).toInclude("</failure>");
			});

			it("ANTJUnit buildTestSuites renders a bundle global exception that lacks stackTrace", function() {
				var reporter = new wheels.wheelstest.system.reports.ANTJUnitReporter();
				makePublic(reporter, "buildTestSuites");
				var buffer = CreateObject("java", "java.lang.StringBuilder").init("");
				var bundleStats = {
					name = "FakeBundle",
					totalDuration = 25,
					path = "tests.specs.FakeBundle",
					globalException = {type = "Custom.Type", message = "global boom"}
				};
				var state = {threw = false, xml = ""};
				try {
					reporter.buildTestSuites(
						buffer      = buffer,
						results     = {},
						bundleStats = bundleStats,
						suiteStats  = []
					);
					state.xml = buffer.toString();
				} catch (any e) {
					state.threw = true;
				}
				expect(state.threw).toBeFalse();
				expect(state.xml).toInclude("global boom");
				expect(state.xml).toInclude("globalException");
				expect(state.xml).toInclude("</testcase>");
			});

			it("Assertion.throws still surfaces the real stack trace when the exception carries one", function() {
				// behavior-preservation check for the guarded read: with a real
				// engine exception the Elvis default must never kick in
				var assertion = new wheels.wheelstest.system.Assertion();
				var thrower = function() {
					throw(type = "Some.Other.Type", message = "not the expected one");
				};
				var state = {caught = false, failDetail = ""};
				try {
					assertion.throws(target = thrower, type = "Expected.Type");
				} catch ("TestBox.AssertionFailed" e) {
					state.caught = true;
					state.failDetail = e.detail ?: "";
				}
				expect(state.caught).toBeTrue();
				expect(Len(state.failDetail)).toBeGT(0);
			});

		});

		describe("Structural guard: optional cfcatch member reads stay null-safe", function() {

			it("every stackTrace/extendedInfo/errorCode member read under wheelstest/system is guarded", function() {
				// Any line that reads one of the optional members must guard it
				// on the same line with ?: (Elvis), isNull(), or structKeyExists().
				// Scan rules follow BareCfabortGuardSpec: line-anchored on
				// purpose (a whole-file comment-strip regex hangs Lucee 7) and
				// comment-only lines are skipped.
				var memberPattern = "\.(stackTrace|extendedInfo|errorCode)\b";
				var root = ExpandPath("/wheels/wheelstest/system");
				var files = DirectoryList(root, true, "path", "*.cfc");
				var offenders = [];

				for (var filePath in files) {
					var content = FileRead(filePath);
					if (!REFindNoCase(memberPattern, content)) {
						continue;
					}
					var fileLines = ListToArray(content, Chr(10), true);
					var lineNumber = 0;
					for (var rawLine in fileLines) {
						lineNumber++;
						var trimmed = Trim(Replace(rawLine, Chr(13), "", "all"));
						if (Left(trimmed, 2) == "//" || Left(trimmed, 1) == "*" || Left(trimmed, 2) == "/*") {
							continue;
						}
						if (!REFindNoCase(memberPattern, trimmed)) {
							continue;
						}
						if (
							Find("?:", trimmed) || FindNoCase("isNull(", trimmed)
								|| FindNoCase("structKeyExists(", trimmed)
						) {
							continue;
						}
						ArrayAppend(offenders, Replace(filePath, root, "") & ":" & lineNumber);
					}
				}

				expect(ArrayLen(offenders)).toBe(
					0,
					"Found unguarded optional cfcatch member read(s) at: #ArrayToList(offenders, ', ')#. "
					& "stackTrace / extendedInfo / errorCode are optional on exception objects — guard the "
					& "read with the Elvis operator (member ?: '') or an isNull()/structKeyExists() check "
					& "so a member-less exception cannot crash the test reporter."
				);
			});

		});

	}

}
