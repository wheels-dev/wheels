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
				var before = jobsNow();
				var rv = enqueue({job = "wheels.tests._assets.jobs.ProbeJob", queue = variables.queue, delaySeconds = "120"});
				expect(rv.success).toBeTrue();
				expect(rv.job.delaySeconds).toBe(120);
				// Compared in the database against typed timestamps (as JobHardenerSpec
				// does): JDBC hands runAt back as a different type per engine and
				// database (an Oracle TIMESTAMP, epoch milliseconds on BoxLang SQLite).
				var stored = jobsQuery(
					"SELECT COUNT(*) AS cnt FROM wheels_jobs WHERE id = :id AND status = 'pending' AND runAt > :earliest AND runAt < :latest",
					{
						id = {value = rv.job.id, cfsqltype = "cf_sql_varchar"},
						earliest = {value = before + 110, cfsqltype = "wheels_epoch"},
						latest = {value = before + 180, cfsqltype = "wheels_epoch"}
					},
					{datasource = variables.ds}
				);
				expect(stored.cnt).toBe(1);
			});

			it("refuses a component on the jobs path that doesn't extend wheels.Job, without instantiating it", () => {
				var rv = enqueue({job = "wheels.tests._assets.jobs.NotAJobSideEffect", queue = variables.queue});
				expect(rv.success).toBeFalse();
				expect(rv.message).toInclude("doesn't extend wheels.Job");
				expect(StructKeyExists(application, "$wheelsNotAJobInstantiated")).toBeFalse();
				expect(enqueue({job = "wheels.tests._assets.jobs.NoPerformStub"}).success).toBeFalse();
			});

			it("refuses a component whose only extends text is inside another attribute's value, without loading it", () => {
				StructDelete(application, "$wheelsHintExtendsInstantiated");
				var rv = enqueue({job = "wheels.tests._assets.jobs.HintExtendsSideEffect", queue = variables.queue});
				expect(rv.success).toBeFalse();
				expect(rv.message).toInclude("doesn't extend wheels.Job");
				expect(StructKeyExists(application, "$wheelsHintExtendsInstantiated")).toBeFalse();
			});

			it("refuses components whose only extends is inside a comment, without loading them", () => {
				StructDelete(application, "$wheelsTagWrappedInstantiated");
				StructDelete(application, "$wheelsNestedCommentInstantiated");
				var wrapped = enqueue({job = "wheels.tests._assets.jobs.TagWrappedCommentSideEffect", queue = variables.queue});
				var nested = enqueue({job = "wheels.tests._assets.jobs.NestedCommentSideEffect", queue = variables.queue});
				expect(wrapped.success).toBeFalse();
				expect(nested.success).toBeFalse();
				expect(StructKeyExists(application, "$wheelsTagWrappedInstantiated")).toBeFalse();
				expect(StructKeyExists(application, "$wheelsNestedCommentInstantiated")).toBeFalse();
			});

			it("enqueues a job whose declaration has { and > inside a quoted value", () => {
				var rv = enqueue({job = "wheels.tests._assets.jobs.QuotedPunctuationJob", queue = variables.queue});
				expect(rv.success).toBeTrue();
				expect(rv.job.jobClass).toBe("wheels.tests._assets.jobs.QuotedPunctuationJob");
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

			it("reads extends only as an attribute, never inside another attribute's quoted value", () => {
				expect(bridge.$sourceExtends('component hint="extends=wheels.Job" {}')).toBe("");
				expect(bridge.$sourceExtends("component hint='extends=wheels.Job' {}")).toBe("");
				expect(bridge.$sourceExtends('component hint="extends=wheels.Job" extends="ProbeJob" {}')).toBe("ProbeJob");
				expect(bridge.$sourceExtends('component displayname="a{b>c" extends="wheels.Job" {}')).toBe("wheels.Job");
				expect(bridge.$sourceExtends('component myextends="wheels.Job" {}')).toBe("");
				expect(bridge.$sourceExtends('component extends=wheels.Job {}')).toBe("wheels.Job");
				expect(bridge.$sourceExtends('component hint="say ""extends=wheels.Job"" here" {}')).toBe("");
				expect(bridge.$sourceExtends('component // extends="wheels.Job"' & Chr(10) & '{}')).toBe("");
				expect(bridge.$sourceExtends('component output=false // a note' & Chr(10) & 'extends="wheels.Job" {}')).toBe("wheels.Job");
			});

			it("finds the declaration only in code, never in a comment or a string", () => {
				// Tag names and comment markers are assembled from pieces. (Not a variable
				// named after the less-than operator: Adobe fails to compile that.)
				var openAngle = Chr(60);
				var nl = Chr(10);
				var scriptTag = "cf" & "script";
				var componentTag = "cf" & "component";
				var tagOpen = openAngle & Chr(33) & "---";
				var tagClose = "---" & Chr(62);
				var job = 'extends="wheels.Job"';
				// An inline line comment that isn't at the start of its line.
				expect(bridge.$sourceExtends(openAngle & scriptTag & "> // component " & job & nl & "component {}" & nl & openAngle & "/" & scriptTag & ">")).toBe("");
				// Nested tag comments: the outer one only ends at its own closer.
				expect(bridge.$sourceExtends(tagOpen & " a " & tagOpen & " b " & tagClose & " " & openAngle & componentTag & " " & job & "> " & tagClose & nl & openAngle & componentTag & ">" & openAngle & "/" & componentTag & ">")).toBe("");
				// A block comment and a string before the real declaration.
				expect(bridge.$sourceExtends(Chr(47) & Chr(42) & " component " & job & " " & Chr(42) & Chr(47) & nl & 'x = "component extends=wheels.Job";' & nl & 'component extends="ProbeJob" {}')).toBe("ProbeJob");
				// A real tag-based job after a nested comment.
				expect(bridge.$sourceExtends(tagOpen & " " & tagOpen & " " & tagClose & " " & tagClose & nl & openAngle & componentTag & " " & job & ">" & openAngle & "/" & componentTag & ">")).toBe("wheels.Job");
			});

			it("doesn't count an extends outside the declaration", () => {
				expect(bridge.$sourceExtends('component {' & Chr(10) & 'x = "extends=wheels.Job";' & Chr(10) & '}')).toBe("");
			});

		});

	}

	/**
	 * Now on the jobs clock (wheels.JobClock): UTC epoch seconds from the database's clock, which
	 * job rows are stamped with.
	 */
	private numeric function jobsNow() {
		return new wheels.Job().$jobClock().nowEpoch();
	}

	/**
	 * queryExecute() with wheels_epoch timestamp parameters, as the jobs code binds them.
	 */
	private any function jobsQuery(required string sql, struct params = {}, struct options = {}) {
		return new wheels.Job().$jobClock().query(arguments.sql, arguments.params, arguments.options);
	}

}
