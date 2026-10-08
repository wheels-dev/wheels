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

		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	// A Module whose worker loop talks to canned bridge responses instead of a
	// server: each makeBridgePost() call returns the next one in turn.
	private any function workerModule(required array responses) {
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		m.$("out");
		m.$(method = "$requireOwnRunningServer", returns = 61999);
		m.$("makeBridgePost").$results(argumentCollection = $positional(arguments.responses));
		return m;
	}

	// $results() takes the responses as positional arguments.
	private struct function $positional(required array values) {
		var args = {};
		for (var i = 1; i <= arrayLen(arguments.values); i++) {
			args[i] = arguments.values[i];
		}
		return args;
	}

	private string function jobDone(required string id) {
		return serializeJSON({success: true, jobResult: {skipped: false, success: true, jobClass: "SpecJob", jobId: arguments.id}});
	}

	private string function idlePoll() {
		return serializeJSON({success: true, jobResult: {skipped: true}});
	}

	// A Module whose `jobs install` gets `source` back from a canned jobsInstallSource response.
	private any function installModule(required string source) {
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		m.$("out");
		m.$(method = "$requireRunningServer", returns = 61999);
		m.$("makeHttpRequest", serializeJSON({success: true, migrationName: "CreateWheelsJobTables", source: arguments.source}));
		return m;
	}

	private string function printed(required any m) {
		var said = "";
		for (var call in arguments.m.$callLog().out) {
			said &= call[1] & chr(10);
		}
		return said;
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

			it("parses --stop-when-empty for work, off by default", () => {
				expect(mod.$parseJobsArgs({arg1 = "work"}).stopWhenEmpty).toBeFalse();
				expect(mod.$parseJobsArgs({arg1 = "work", "stop-when-empty" = "true"}).stopWhenEmpty).toBeTrue();
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

		describe("work --stop-when-empty", () => {

			it("drains the ready jobs, then exits on the first empty poll", () => {
				var m = workerModule([jobDone("1"), jobDone("2"), idlePoll()]);
				expect(m.jobs(arg1 = "work", "stop-when-empty" = "true")).toBe("");
				expect(m.$count("makeBridgePost")).toBe(3);
				var said = printed(m);
				expect(said).toInclude("No job ready to run. Shutting down.");
				expect(said).toInclude("Processed: 2 | Failed: 0");
			});

			it("exits after one poll when nothing is ready", () => {
				var m = workerModule([idlePoll()]);
				expect(m.jobs(arg1 = "work", "stop-when-empty" = "true")).toBe("");
				expect(m.$count("makeBridgePost")).toBe(1);
				expect(printed(m)).toInclude("Processed: 0 | Failed: 0");
			});

			it("still stops at --max-jobs first when the queue outlasts it", () => {
				var m = workerModule([jobDone("1"), jobDone("2"), jobDone("3")]);
				m.jobs(arg1 = "work", "stop-when-empty" = "true", "max-jobs" = "2");
				expect(m.$count("makeBridgePost")).toBe(2);
				expect(printed(m)).toInclude("Reached max jobs limit (2). Shutting down.");
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

		describe("install", () => {

			it("parses install and --force", () => {
				expect(mod.$parseJobsArgs({arg1 = "install"}).action).toBe("install");
				expect(mod.$parseJobsArgs({arg1 = "install"}).force).toBeFalse();
				expect(mod.$parseJobsArgs({arg1 = "install", force = "true"}).force).toBeTrue();
			});

			it("writes the migration the server generates, once, and rewrites it in place with --force", () => {
				var dir = variables.tempRoot & "/app/migrator/migrations";
				if (directoryExists(dir)) {
					for (var old in directoryList(dir, false, "path", "*_CreateWheelsJobTables.cfc")) {
						fileDelete(old);
					}
				}
				var m = installModule("// first");
				m.jobs(arg1 = "install");
				var written = directoryList(dir, false, "name", "*_CreateWheelsJobTables.cfc");
				expect(arrayLen(written)).toBe(1);
				expect(fileRead(dir & "/" & written[1])).toBe("// first");
				expect(printed(m)).toInclude("jobsAutoCreateTables = false");

				var again = installModule("// second");
				again.jobs(arg1 = "install");
				expect(fileRead(dir & "/" & written[1])).toBe("// first", "without --force an existing migration is left alone");
				expect(printed(again)).toInclude("already exists");

				var forced = installModule("// third");
				forced.jobs(arg1 = "install", force = "true");
				expect(directoryList(dir, false, "name", "*_CreateWheelsJobTables.cfc")).toBe(written, "rewritten under the same name and version");
				expect(fileRead(dir & "/" & written[1])).toBe("// third");
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
