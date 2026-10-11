/**
 * `wheels jobs enqueue <JobName>`: enqueue a job, now or after a delay, from the
 * command line. "Schedule" here means a delayed run (--in / --at), not a
 * recurring one; Wheels has no cron-style schedule.
 *
 * The CLI validates everything it can before any server call (the data is a
 * JSON object, --in and --at aren't both given, --at is a valid future time) and
 * turns --at into a delay in seconds, so the server never parses a date. The
 * framework's jobsEnqueue bridge command (a mutating POST) does the class
 * allowlisting; CliBridgeJobsEnqueueSpec covers it. `jobs` stays hidden from MCP.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	private any function enqueueModule(struct response = {}) {
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		m.$("out");
		m.$(method = "$requireOwnRunningServer", returns = 61999);
		var body = StructIsEmpty(arguments.response)
			? {success: true, job: {id: "abc-123", jobClass: "app.jobs.SendWelcomeEmailJob", queue: "default", priority: 0, delaySeconds: 0, status: "pending"}}
			: arguments.response;
		m.$("makeBridgePost", SerializeJSON(body));
		return m;
	}

	private string function printed(required any m) {
		var said = "";
		for (var call in arguments.m.$callLog().out) {
			said &= call[1] & chr(10);
		}
		return said;
	}

	private struct function thrown(required any fn) {
		var state = {type: "", message: ""};
		try {
			arguments.fn();
		} catch (any e) {
			state.type = e.type;
			state.message = e.message;
		}
		return state;
	}

	private string function postedUrl(required any m) {
		return arguments.m.$callLog().makeBridgePost[1][1];
	}

	function run() {

		describe("wheels jobs enqueue", () => {

			it("POSTs jobsEnqueue with the job name and prints the job id", () => {
				var m = enqueueModule();
				m.jobs(arg1 = "enqueue", arg2 = "SendWelcomeEmailJob");
				expect(m.$count("makeBridgePost")).toBe(1);
				expect(postedUrl(m)).toInclude("command=jobsEnqueue");
				expect(postedUrl(m)).toInclude("job=SendWelcomeEmailJob");
				var said = printed(m);
				expect(said).toInclude("Enqueued app.jobs.SendWelcomeEmailJob");
				expect(said).toInclude("abc-123");
				expect(said).toInclude("queue default");
				expect(said).toInclude("runs now");
			});

			it("passes the data, queue and priority through, URL-encoded", () => {
				var m = enqueueModule();
				m.jobs(arg1 = "enqueue", arg2 = "SendWelcomeEmailJob", data = '{"userId":7,"note":"a&b"}', queue = "mail", priority = 5);
				var posted = postedUrl(m);
				expect(posted).toInclude("data=" & URLEncodedFormat('{"userId":7,"note":"a&b"}'));
				expect(posted).toInclude("queue=mail");
				expect(posted).toInclude("priority=5");
			});

			it("delays the run with --in", () => {
				var m = enqueueModule({success: true, job: {id: "j1", jobClass: "app.jobs.X", queue: "default", priority: 0, delaySeconds: 600}});
				m.jobs(arg1 = "enqueue", arg2 = "X", "in" = 600);
				expect(postedUrl(m)).toInclude("delaySeconds=600");
				expect(printed(m)).toInclude("runs in 600 seconds");
			});

			it("turns --at into a delay in seconds", () => {
				var m = enqueueModule();
				var at = DateTimeFormat(DateAdd("h", 2, Now()), "yyyy-mm-dd'T'HH:nn:ss");
				m.jobs(arg1 = "enqueue", arg2 = "X", at = at);
				var delay = Val(ReReplace(postedUrl(m), ".*delaySeconds=([0-9]+).*", "\1"));
				expect(delay).toBeGT(7100);
				expect(delay).toBeLTE(7200);
			});

			it("reads an --at with a UTC offset in that offset", () => {
				var nowMs = 1790000000000;
				// 1790000000000 ms is 2026-09-21T14:13:20Z.
				expect(mod.$jobsDelayUntil("2026-09-21T15:13:20Z", nowMs)).toBe(3600);
				expect(mod.$jobsDelayUntil("2026-09-21T17:13:20+02:00", nowMs)).toBe(3600);
			});

			it("refuses a past or unreadable --at, and --in with --at, before any server call", () => {
				var m = enqueueModule();
				expect(thrown(() => m.jobs(arg1 = "enqueue", arg2 = "X", at = "2001-01-01T00:00:00Z")).message).toInclude("in the past");
				expect(thrown(() => m.jobs(arg1 = "enqueue", arg2 = "X", at = "tomorrow")).message).toInclude("--at");
				expect(thrown(() => m.jobs(arg1 = "enqueue", arg2 = "X", "in" = 60, at = "2099-01-01T00:00:00Z")).message).toInclude("either --in or --at");
				expect(thrown(() => m.jobs(arg1 = "enqueue", arg2 = "X", "in" = -1)).message).toInclude("--in");
				expect(m.$count("makeBridgePost")).toBe(0);
			});

			it("refuses --data that isn't a JSON object before any server call", () => {
				var m = enqueueModule();
				expect(thrown(() => m.jobs(arg1 = "enqueue", arg2 = "X", data = "[1,2]")).message).toInclude("JSON object");
				expect(thrown(() => m.jobs(arg1 = "enqueue", arg2 = "X", data = "{oops")).message).toInclude("JSON object");
				expect(m.$count("makeBridgePost")).toBe(0);
			});

			it("refuses a missing job name, with the usage in the message", () => {
				var state = thrown(() => enqueueModule().jobs(arg1 = "enqueue"));
				expect(state.type).toBe("Wheels.InvalidArguments");
				expect(state.message).toInclude("wheels jobs enqueue <JobName>");
			});

			it("fails non-zero with the server's reason when the bridge refuses", () => {
				var m = enqueueModule({success: false, message: "app.jobs.Nope isn't a job class: no app/jobs/Nope.cfc."});
				var state = thrown(() => m.jobs(arg1 = "enqueue", arg2 = "Nope"));
				expect(state.type).toBe("Wheels.JobEnqueueFailed");
				expect(state.message).toInclude("app/jobs/Nope.cfc");
			});

			it("prints the job as JSON with --format=json", () => {
				var m = enqueueModule();
				m.jobs(arg1 = "enqueue", arg2 = "SendWelcomeEmailJob", format = "json");
				expect(DeserializeJSON(printed(m)).id).toBe("abc-123");
			});

			it("stays hidden from MCP", () => {
				expect(ArrayFindNoCase(mod.mcpHiddenTools(), "jobs")).toBeGT(0);
			});

		});

	}

}
