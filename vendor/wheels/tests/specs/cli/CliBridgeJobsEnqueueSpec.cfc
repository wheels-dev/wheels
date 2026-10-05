/**
 * The jobsEnqueue bridge command behind `wheels jobs enqueue`.
 *
 * It names a component to instantiate from request input, so it only accepts a
 * class on the worker's own allowlist (app.jobs plus any jobClassPrefixes) that
 * extends wheels.Job, and it decides that from the name and the component's
 * metadata before anything is instantiated. It is a mutating command (POST,
 * loopback, reload password); CliEndpointHardeningSpec pins that.
 *
 * Specs use wheels.tests._assets.jobs.*, which the allowlist admits outside
 * production, as the framework's own job specs do.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.ds = application.wheels.dataSourceName;
		variables.queue = "cli_enqueue_spec";
		var job = CreateObject("component", "wheels.Job").init();
		job.$ensureJobTable();
	}

	function afterAll() {
		cleanup();
	}

	private void function cleanup() {
		QueryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'cli_enqueue_spec%'", [], {datasource = variables.ds});
	}

	private struct function enqueue(required struct params) {
		var bridge = new wheels.public.CliBridge();
		return bridge.dispatch(command = "jobsEnqueue", context = {}, params = arguments.params);
	}

	private query function row(required string id) {
		return QueryExecute("SELECT * FROM wheels_jobs WHERE id = :id", {id = arguments.id}, {datasource = variables.ds});
	}

	function run() {

		describe("CliBridge jobsEnqueue", () => {

			beforeEach(() => {
				cleanup();
				StructDelete(application, "$wheelsNotAJobInstantiated");
			});

			it("enqueues an allowed job class with its data", () => {
				var rv = enqueue({job = "wheels.tests._assets.jobs.ProbeJob", data = '{"orderId":42}', queue = variables.queue});
				expect(rv.success).toBeTrue();
				expect(Len(rv.job.id)).toBeGT(0);
				expect(rv.job.jobClass).toBe("wheels.tests._assets.jobs.ProbeJob");
				expect(rv.job.queue).toBe(variables.queue);
				var stored = row(rv.job.id);
				expect(stored.recordCount).toBe(1);
				expect(stored.status).toBe("pending");
				expect(DeserializeJSON(stored.data).orderId).toBe(42);
			});

			it("uses the job's own queue and priority unless overridden", () => {
				var rv = enqueue({job = "wheels.tests._assets.jobs.ProbeJob", queue = variables.queue & "_p", priority = "7"});
				expect(rv.success).toBeTrue();
				expect(rv.job.priority).toBe(7);
				expect(row(rv.job.id).priority).toBe(7);
				var defaults = enqueue({job = "wheels.tests._assets.jobs.ProbeJob"});
				expect(defaults.job.queue).toBe("default");
				expect(defaults.job.priority).toBe(0);
				QueryExecute("DELETE FROM wheels_jobs WHERE id = :id", {id = defaults.job.id}, {datasource = variables.ds});
			});

			it("delays the run by delaySeconds", () => {
				var before = Now();
				var rv = enqueue({job = "wheels.tests._assets.jobs.ProbeJob", queue = variables.queue, delaySeconds = "120"});
				expect(rv.success).toBeTrue();
				expect(rv.job.delaySeconds).toBe(120);
				expect(DateDiff("s", before, row(rv.job.id).runAt)).toBeGTE(110);
			});

			it("refuses a component on the jobs path that doesn't extend wheels.Job, without instantiating it", () => {
				var rv = enqueue({job = "wheels.tests._assets.jobs.NotAJobSideEffect", queue = variables.queue});
				expect(rv.success).toBeFalse();
				expect(rv.message).toInclude("doesn't extend wheels.Job");
				expect(StructKeyExists(application, "$wheelsNotAJobInstantiated")).toBeFalse();
				expect(enqueue({job = "wheels.tests._assets.jobs.NoPerformStub"}).success).toBeFalse();
			});

			it("follows an extends chain through a sibling parent", () => {
				var rv = enqueue({job = "wheels.tests._assets.jobs.ChildOfProbeJob", queue = variables.queue});
				expect(rv.success).toBeTrue();
				expect(rv.job.jobClass).toBe("wheels.tests._assets.jobs.ChildOfProbeJob");
			});

			it("resolves a short name under app.jobs and refuses one that isn't there", () => {
				var rv = enqueue({job = "NoSuchCliEnqueueJob", queue = variables.queue});
				expect(rv.success).toBeFalse();
				expect(rv.message).toInclude("app.jobs.NoSuchCliEnqueueJob");
			});

			it("refuses names that aren't dotted identifiers, before resolving them", () => {
				for (var bad in ["../secrets", "a;b", "app.jobs..X", "app/jobs/X", ".X", "X.", ""]) {
					var rv = enqueue({job = bad, queue = variables.queue});
					expect(rv.success).toBeFalse("expected '" & bad & "' to be refused");
				}
			});

			it("never instantiates a component outside the jobs allowlist", () => {
				// Not a jobs-path name: it resolves under app.jobs, where it doesn't exist.
				var rv = enqueue({job = "wheels.Model", queue = variables.queue});
				expect(rv.success).toBeFalse();
				expect(rv.message).toInclude("app.jobs.wheels.Model");
				expect(QueryExecute("SELECT COUNT(*) AS n FROM wheels_jobs WHERE queue = :q", {q = variables.queue}, {datasource = variables.ds}).n).toBe(0);
			});

			it("refuses data that isn't a JSON object, and a bad priority or delay", () => {
				expect(enqueue({job = "wheels.tests._assets.jobs.ProbeJob", data = "[1,2]"}).message).toInclude("JSON object");
				expect(enqueue({job = "wheels.tests._assets.jobs.ProbeJob", data = "nope"}).message).toInclude("JSON object");
				expect(enqueue({job = "wheels.tests._assets.jobs.ProbeJob", priority = "high"}).message).toInclude("priority");
				expect(enqueue({job = "wheels.tests._assets.jobs.ProbeJob", delaySeconds = "-5"}).message).toInclude("delaySeconds");
			});

		});

		describe("CliBridge $sourceExtends (the extends check reads source, never loads it)", () => {

			beforeEach(() => {
				bridge = new wheels.public.CliBridge();
			});

			it("reads a script or tag component declaration", () => {
				expect(bridge.$sourceExtends('component extends="wheels.Job" {' & Chr(10) & '}')).toBe("wheels.Job");
				expect(bridge.$sourceExtends("component output=false extends='app.jobs.BaseJob' {}")).toBe("app.jobs.BaseJob");
				expect(bridge.$sourceExtends(Chr(60) & 'cfcomponent extends="wheels.Job" output="false">' & Chr(60) & "/cfcomponent>")).toBe("wheels.Job");
				expect(bridge.$sourceExtends("component {}")).toBe("");
			});

			it("ignores a commented-out declaration", () => {
				var block = Chr(47) & Chr(42) & ' component extends="wheels.Job" ' & Chr(42) & Chr(47);
				expect(bridge.$sourceExtends(block & Chr(10) & "component {}")).toBe("");
				expect(bridge.$sourceExtends('// component extends="wheels.Job" {' & Chr(10) & "component {}")).toBe("");
			});

			it("doesn't count an extends outside the declaration", () => {
				expect(bridge.$sourceExtends('component {' & Chr(10) & 'x = "extends=wheels.Job";' & Chr(10) & '}')).toBe("");
			});

		});

	}

}
