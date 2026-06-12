/**
 * Tests the jobs command via Module.cfc (issue #3090).
 *
 * `wheels jobs work|status` was advertised by the guides and root CLAUDE.md
 * since the original CommandBox-era implementation (#1934), but the command
 * functions were lost in the LuCLI migration while the framework half
 * (vendor/wheels/JobWorker.cfc + the jobs* bridge cases in
 * vendor/wheels/public/views/cli.cfm) survived. These specs cover the
 * restored CLI surface: argument parsing, verb routing, the deterministic
 * no-server failure mode for `work`, the status table renderer, and the
 * MCP hidden-tools entry.
 *
 * Server-dependent paths (a live `jobsStatus` / `jobsProcessNext` bridge
 * round trip) are not unit-testable here — the stateless TestBox harness has
 * no running Wheels server (see MigrateCommandSpec / #2829) — so they are
 * exercised against the existing bridge cases manually and by the framework
 * suite's JobWorkerSpec.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));

		// Create vendor/wheels stub
		directoryCreate(tempRoot & "/vendor/wheels", true, true);

		// scaffoldTempProject() copies the repo's lucee.json (which carries a
		// `port`) into the temp project. Strip the port so detectServerPort()
		// can never resolve a live server for this project — the "work refuses
		// to run without a project-bound server port" case must
		// deterministically take the ServerNotRunning refusal path
		// (requireProjectConfig=true refuses the common-port fallback). Without
		// this, a dev server bound to the configured port (the local CLI
		// harness default) makes runJobsWork() enter its poll loop for real:
		// the empty queue idles into sleep() forever (maxJobs=0), hanging the
		// suite — or worse, processes real jobs from a unit spec. Mirrors
		// MigrationExitCodeSpec.
		fileWrite(tempRoot & "/lucee.json", "{}");

		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("$parseJobsArgs — argument parsing", () => {

			it("defaults to the status action with table format", () => {
				var opts = mod.$parseJobsArgs({});
				expect(opts.action).toBe("status");
				expect(opts.queue).toBe("");
				expect(opts.interval).toBe(5);
				expect(opts.maxJobs).toBe(0);
				expect(opts.quiet).toBeFalse();
				expect(opts.format).toBe("table");
			});

			it("parses work with --queue and --interval", () => {
				var opts = mod.$parseJobsArgs({arg1 = "work", queue = "mailers", interval = "3"});
				expect(opts.action).toBe("work");
				expect(opts.queue).toBe("mailers");
				expect(opts.interval).toBe(3);
			});

			it("parses --max-jobs and --quiet for work", () => {
				var opts = mod.$parseJobsArgs({arg1 = "work", "max-jobs" = "100", quiet = "true"});
				expect(opts.maxJobs).toBe(100);
				expect(opts.quiet).toBeTrue();
			});

			it("parses a comma-delimited queue list", () => {
				var opts = mod.$parseJobsArgs({arg1 = "work", queue = "critical,default,low"});
				expect(opts.queue).toBe("critical,default,low");
			});

			it("parses status with --format=json", () => {
				var opts = mod.$parseJobsArgs({arg1 = "status", format = "json"});
				expect(opts.action).toBe("status");
				expect(opts.format).toBe("json");
			});

			it("throws Wheels.InvalidArguments when --interval is zero or negative", () => {
				expect(() => mod.$parseJobsArgs({arg1 = "work", interval = "0"})).toThrow(type = "Wheels.InvalidArguments");
			});

			it("throws Wheels.InvalidArguments when --max-jobs is negative", () => {
				expect(() => mod.$parseJobsArgs({arg1 = "work", "max-jobs" = "-1"})).toThrow(type = "Wheels.InvalidArguments");
			});

			it("throws Wheels.InvalidArguments on an unknown --format", () => {
				expect(() => mod.$parseJobsArgs({arg1 = "status", format = "xml"})).toThrow(type = "Wheels.InvalidArguments");
			});

		});

		describe("wheels jobs — verb routing", () => {

			it("throws Wheels.InvalidArguments on an unknown action", () => {
				expect(() => mod.jobs(arg1 = "bogus")).toThrow(type = "Wheels.InvalidArguments");
			});

			it("throws Wheels.InvalidArguments for the deferred retry verb", () => {
				expect(() => mod.jobs(arg1 = "retry")).toThrow(type = "Wheels.InvalidArguments");
			});

			it("throws Wheels.InvalidArguments for the deferred purge verb", () => {
				expect(() => mod.jobs(arg1 = "purge")).toThrow(type = "Wheels.InvalidArguments");
			});

			it("throws Wheels.InvalidArguments for the deferred monitor verb", () => {
				expect(() => mod.jobs(arg1 = "monitor")).toThrow(type = "Wheels.InvalidArguments");
			});

			it("work refuses to run without a project-bound server port", () => {
				// The temp project has no lucee.json / .env port config, and
				// `work` is write-side (processes jobs), so detectServerPort's
				// strict mode (#2878) deterministically finds no server.
				expect(() => mod.jobs(arg1 = "work")).toThrow(type = "Wheels.ServerNotRunning");
			});

			it("rejects invalid options before touching server detection", () => {
				// Parse-stage validation must fire first so a bad flag yields
				// a usage error, not a misleading "no server" diagnostic.
				expect(() => mod.jobs(arg1 = "work", interval = "0")).toThrow(type = "Wheels.InvalidArguments");
			});

		});

		describe("$formatJobsStatusTable — status rendering", () => {

			it("reports no jobs for an empty stats struct", () => {
				var rendered = mod.$formatJobsStatusTable({
					queues = {},
					totals = {pending = 0, processing = 0, completed = 0, failed = 0, total = 0}
				});
				expect(rendered).toInclude("No jobs found");
			});

			it("renders one row per queue plus a totals row", () => {
				var rendered = mod.$formatJobsStatusTable({
					queues = {
						"mailers" = {pending = 3, processing = 1, completed = 10, failed = 2, total = 16},
						"default" = {pending = 0, processing = 0, completed = 5, failed = 0, total = 5}
					},
					totals = {pending = 3, processing = 1, completed = 15, failed = 2, total = 21}
				});
				expect(rendered).toInclude("mailers");
				expect(rendered).toInclude("default");
				expect(rendered).toInclude("TOTAL");
				expect(rendered).toInclude("Pending");
				expect(rendered).toInclude("Processing");
				expect(rendered).toInclude("Completed");
				expect(rendered).toInclude("Failed");
				expect(rendered).toInclude("21");
			});

			it("tolerates a stats struct with missing keys", () => {
				// The bridge response is deserialized JSON — defend against a
				// partial payload instead of throwing mid-render.
				var rendered = mod.$formatJobsStatusTable({});
				expect(rendered).toInclude("No jobs found");
			});

		});

		describe("MCP surface", () => {

			it("hides the jobs command from MCP tools/list", () => {
				// `jobs work` is a long-lived poll loop — it doesn't translate
				// to single-call MCP semantics (same reasoning as start/stop).
				var hidden = mod.mcpHiddenTools();
				expect(arrayFindNoCase(hidden, "jobs")).toBeGT(0);
			});

		});

	}

}
