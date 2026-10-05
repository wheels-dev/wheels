/**
 * `wheels <command> --help` prints the command's `hint:` line plus its
 * `Usage:` / `Examples:` sections, and nothing else from the docblock.
 *
 * It used to print the whole docblock, so maintainer notes (history, internals,
 * issue numbers) showed up as help text for reload, map, upgrade and packages.
 * Those notes now live in `//` comments; this spec keeps them out of help.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.mod = new cli.lucli.Module(cwd = getTempDirectory());
		variables.commands = [];
		for (var fn in getMetaData(variables.mod).functions) {
			if ((fn.access ?: "public") == "public" && left(fn.name, 1) != "$") {
				arrayAppend(variables.commands, {name = fn.name, hint = fn.hint ?: ""});
			}
		}
	}

	function run() {

		describe("wheels <command> --help", () => {

			it("finds the commands to check", () => {
				expect(arrayLen(commands)).toBeGT(20);
			});

			it("has no docblock text between the hint line and a Usage: or Examples: section", () => {
				var offenders = [];
				for (var command in commands) {
					var parts = mod.$commandHelpParts(command.hint);
					if (arrayLen(parts.stray)) {
						arrayAppend(offenders, command.name & " (" & parts.stray[1] & ")");
					}
				}
				expect(arrayToList(offenders, "; ")).toBe(
					"",
					"move maintainer notes to // comments above the docblock: --help shows only the hint line and Usage:/Examples: sections"
				);
			});

			it("prints no issue references for any command", () => {
				var offenders = [];
				for (var command in commands) {
					var help = mod.showHelp(command.name);
					if (reFind("##[0-9]{3,}", help)) {
						arrayAppend(offenders, command.name);
					}
				}
				expect(arrayToList(offenders, ", ")).toBe("", "--help text is for users, not maintainers");
			});

			it("prints the hint line but not the maintainer notes for reload, map, upgrade and packages", () => {
				var reload = mod.showHelp("reload");
				expect(reload).toInclude("Reload the running Wheels application");
				expect(reload).notToInclude("Rails");

				var map = mod.showHelp("map");
				expect(map).toInclude("forwards to `setup agents`");
				expect(map).notToInclude("snapshot");

				var upgrade = mod.showHelp("upgrade");
				expect(upgrade).toInclude("Upgrade the Wheels framework in your app");
				expect(upgrade).notToInclude("deliberately does nothing");

				var packages = mod.showHelp("packages");
				expect(packages).toInclude("verb is `add`, not `install`");
				expect(packages).notToInclude("chapter 8");
			});

			it("keeps the Usage: and Examples: sections, indented", () => {
				var deploy = mod.showHelp("deploy");
				expect(deploy).toInclude("Usage:" & chr(10) & "  wheels deploy ");
				expect(deploy).toInclude("  wheels deploy --dry-run");

				var packages = mod.showHelp("packages");
				expect(packages).toInclude("Usage:" & chr(10) & "  wheels packages list");

				var upgrade = mod.showHelp("upgrade");
				expect(upgrade).toInclude("Examples:" & chr(10) & "  wheels upgrade apply ");
			});

			it("prints a command's own help for coverage and engines", () => {
				expect(mod.showHelp("coverage")).toInclude("wheels coverage");
				expect(mod.showHelp("coverage")).toInclude("CRAP ranking");
				expect(mod.showHelp("engines")).toInclude("wheels engines");
				expect(mod.showHelp("engines")).toInclude("RustCFML");
			});

		});

		describe("$commandHelpParts()", () => {

			it("splits the hint line from the Usage: and Examples: sections", () => {
				var parts = mod.$commandHelpParts(
					"hint: Do a thing" & chr(10) & "Usage:" & chr(10) & "wheels thing a" & chr(10)
					& "Examples:" & chr(10) & "wheels thing b"
				);
				expect(parts.summary).toBe("Do a thing");
				expect(arrayLen(parts.sections)).toBe(2);
				expect(parts.sections[1].heading).toBe("Usage:");
				expect(parts.sections[1].lines).toBe(["wheels thing a"]);
				expect(parts.sections[2].lines).toBe(["wheels thing b"]);
				expect(parts.stray).toBeEmpty();
			});

			it("returns text before the first section as stray, which is never printed", () => {
				var parts = mod.$commandHelpParts("hint: Do a thing" & chr(10) & "Why this exists" & chr(10) & "Usage:" & chr(10) & "wheels thing");
				expect(parts.stray).toBe(["Why this exists"]);
				expect(arrayLen(parts.sections)).toBe(1);
			});

			it("treats a docblock without a hint: key as no command help", () => {
				var parts = mod.$commandHelpParts("Internal notes about a hook.");
				expect(parts.summary).toBe("");
			});

		});
	}

}
