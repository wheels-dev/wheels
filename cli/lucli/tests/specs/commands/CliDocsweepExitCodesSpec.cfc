/**
 * #4409: `wheels browser <bogus>`, `wheels browser test` (Playwright absent),
 * `wheels setup agents` outside a project, and `wheels generate snippets <bad>`
 * all printed a refusal and then exited 0, so scripts and CI could not detect
 * them. Each path now exits non-zero.
 *
 * Two paths are driven behaviourally (they throw a catchable Wheels.* type that
 * LuCLI turns into a non-zero exit); the two that first run argument parsing are
 * pinned at source, the way ConsoleCommandSpec pins console's exit wiring.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		// A directory that is NOT a Wheels project (no config/settings.cfm).
		variables.notAProject = getTempDirectory() & "wheels-cli-not-a-project-" & createUUID();
		directoryCreate(variables.notAProject, true, true);
		variables.moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
	}

	function afterAll() {
		if (Len(variables.notAProject) > 10 && directoryExists(variables.notAProject)) {
			directoryDelete(variables.notAProject, true);
		}
	}

	private any function mutedModule(string cwd = expandPath("/")) {
		var m = new cli.lucli.Module(cwd = arguments.cwd);
		prepareMock(m);
		m.$("out");
		return m;
	}

	private string function thrownType(required any fn) {
		var state = {type = ""};
		try {
			arguments.fn();
		} catch (any e) {
			state.type = e.type;
		}
		return state.type;
	}

	/**
	 * A window of source around a marker. `$refuse(` opens a line or two BEFORE its message argument,
	 * so the window reaches back `lead` chars to include the opening call.
	 */
	private string function bodyAround(required string marker, numeric lead = 140, numeric span = 300) {
		var idx = find(arguments.marker, variables.moduleSource);
		if (idx == 0) return "";
		var start = max(1, idx - arguments.lead);
		return mid(variables.moduleSource, start, arguments.lead + arguments.span);
	}

	function run() {

		describe("wheels setup agents outside a project (4409)", () => {

			it("throws Wheels.NotAWheelsProject instead of printing a note and exiting 0", () => {
				var m = mutedModule(variables.notAProject);
				makePublic(m, "$setupMcp");
				expect(thrownType(() => m.$setupMcp(["agents"]))).toBe("Wheels.NotAWheelsProject");
			});

		});

		describe("wheels browser test with Playwright absent (4409)", () => {

			it("throws Wheels.Browser.NotInstalled when the manifest is missing", () => {
				var m = mutedModule();
				makePublic(m, "$browserVerifyPlaywright");
				var missing = getTempDirectory() & "no-such-browser-manifest-" & createUUID() & ".json";
				expect(thrownType(() => m.$browserVerifyPlaywright(missing))).toBe("Wheels.Browser.NotInstalled");
			});

		});

		describe("wheels browser <unknown> (4409)", () => {

			it("refuses the unknown subcommand with Wheels.InvalidArguments, not a silent return", () => {
				var seg = bodyAround("Unknown browser command:");
				expect(Len(seg)).toBeGT(0);
				expect(seg).toInclude("$refuse(");
				expect(seg).toInclude("Wheels.InvalidArguments");
				expect(reFind('return\s+"";', seg)).toBe(0, "the default branch must throw, not return empty");
			});

		});

		describe("wheels generate snippets <unknown> (4409)", () => {

			it("refuses the unknown pattern with Wheels.Generate.Refused, not a silent return", () => {
				var seg = bodyAround("Unknown snippet pattern:");
				expect(Len(seg)).toBeGT(0);
				expect(seg).toInclude("$refuse(");
				expect(seg).toInclude("Wheels.Generate.Refused");
				expect(reFind('return\s+"";', seg)).toBe(0, "the unknown-pattern branch must throw, not return empty");
			});

		});

	}

}
