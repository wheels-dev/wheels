component extends="wheels.WheelsTest" {

	/*
	 * The JSON reporter serialized each spec's raw exception object. On BoxLang a
	 * JDBC exception's Java object graph sent the serializer into a
	 * StackOverflowError, so the whole run came back as an error envelope with no
	 * results at all (#3905). The reporter now reduces errors to plain values and,
	 * if serialization still fails, returns the totals and the failing specs.
	 */
	function run() {

		describe("JSON reporter with spec errors", () => {

			it("reports a spec's exception as plain type, message and detail", () => {
				var report = $report(error = $caught("Custom.Probe", "boom", "the detail"));
				var err = report.bundleStats[1].suiteStats[1].specStats[1].error;
				expect(err.type).toBe("Custom.Probe");
				expect(err.message).toBe("boom");
				expect(err.detail).toBe("the detail");
			});

			it("keeps only plain fields on the error and its stack frames", () => {
				var report = $report(error = $caught("Custom.Probe", "boom", ""));
				var spec = report.bundleStats[1].suiteStats[1].specStats[1];
				for (var key in spec.error) {
					expect(ListFindNoCase("type,message,detail,extendedInfo,errorCode,stackTrace,tagContext", key)).toBeGT(0, "unexpected error key #key#");
				}
				expect(IsArray(spec.error.tagContext)).toBeTrue();
				expect(ArrayLen(spec.error.tagContext)).toBeGT(0);
				for (var frame in spec.failOrigin) {
					for (var key in frame) {
						expect(ListFindNoCase("template,line,column,raw_trace", key)).toBeGT(0, "unexpected frame key #key#");
					}
				}
			});

			it("reports a database driver exception as plain values", () => {
				// The issue's trigger: a JDBC exception, whose Java object graph is
				// what sent BoxLang's serializer into a StackOverflowError.
				var report = $report(error = $databaseError());
				var err = report.bundleStats[1].suiteStats[1].specStats[1].error;
				// BoxLang raises a message-less java.lang.NullPointerException here,
				// so only the type is guaranteed (its class name when there is no CFML type).
				expect(Len(err.type)).toBeGT(0);
				expect(IsSimpleValue(err.message)).toBeTrue();
				for (var key in err) {
					expect(ListFindNoCase("type,message,detail,extendedInfo,errorCode,stackTrace,tagContext", key)).toBeGT(0, "unexpected error key #key#");
				}
			});

			it("keeps line numbers on stack frames", () => {
				var report = $report(error = $caught("Custom.Probe", "boom", ""));
				var frames = report.bundleStats[1].suiteStats[1].specStats[1].failOrigin;
				expect(ArrayLen(frames)).toBeGT(0);
				expect(Val(frames[1].line)).toBeGT(0);
			});

			it("reports a bundle-level exception as plain values too", () => {
				var report = $report(globalException = $caught("Custom.BundleProbe", "before all failed", ""));
				expect(report.bundleStats[1].globalException.type).toBe("Custom.BundleProbe");
				expect(report.bundleStats[1].globalException.message).toBe("before all failed");
			});

			it("still returns the totals when a result value can't be serialized", () => {
				var loop = {};
				loop.self = loop;
				var report = $report(error = $caught("Custom.Probe", "boom", ""), debugValue = loop);
				expect(report.totalSpecs).toBe(1);
				expect(report.totalError).toBe(1);
				expect(report.bundleStats[1].suiteStats[1].specStats[1].name).toBe("probe spec");
			});
		});
	}

	private any function $caught(required string type, required string message, required string detail) {
		try {
			throw(type = arguments.type, message = arguments.message, detail = arguments.detail);
		} catch (any e) {
			return e;
		}
	}

	private any function $databaseError() {
		try {
			QueryExecute("SELECT * FROM wheels_no_such_table_3905", {}, {datasource = application.wheels.dataSourceName});
		} catch (any e) {
			return e;
		}
		throw(type = "Wheels.Test", message = "expected the query against a missing table to fail");
	}

	// Builds a one-bundle, one-suite, one-spec TestResult with the given error,
	// runs the JSON reporter on it and returns the parsed report.
	private struct function $report(any error, any globalException, any debugValue) {
		var results = new wheels.wheelstest.system.TestResult(bundleCount = 1);
		var bundleStats = results.startBundleStats(bundlePath = "probe.ProbeSpec", name = "probe.ProbeSpec");
		var suiteStats = results.startSuiteStats(suite = {id = CreateUUID(), name = "probe suite"}, bundleStats = bundleStats);
		var specStats = results.startSpecStats(
			spec = {id = CreateUUID(), name = "probe spec", displayName = "probe spec", focused = false, skip = false, labels = []},
			suiteStats = suiteStats
		);
		results.incrementSpecs();
		if (!IsNull(arguments.error)) {
			specStats.status = "Error";
			specStats.error = arguments.error;
			specStats.failMessage = arguments.error.message;
			specStats.failOrigin = arguments.error.tagContext;
			results.incrementSpecStat(type = "error", stats = specStats);
		}
		if (!IsNull(arguments.globalException)) {
			bundleStats.globalException = arguments.globalException;
		}
		if (!IsNull(arguments.debugValue)) {
			ArrayAppend(bundleStats.debugBuffer, arguments.debugValue);
		}
		var json = new wheels.wheelstest.system.reports.JSONReporter().runReport(
			results = results,
			testbox = new wheels.wheelstest.system.TestBox(bundles = []),
			justReturn = true
		);
		expect(IsJSON(json)).toBeTrue("the report is not valid JSON");
		return DeserializeJSON(json);
	}

}
