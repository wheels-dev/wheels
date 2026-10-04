/**
 * Unit coverage for parseGeneratorArgs() column-size brace modifiers.
 *
 * Rails-style `name:type{N}` / `name:decimal{P,S}` tokens must land as
 * structured prop fields without breaking colon-based enum values.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.probe = new cli.lucli.tests._fixtures.commands.ModuleArgvProbe(
			cwd = expandPath("/")
		);
	}

	function run() {

		describe("parseGeneratorArgs — property tokens", () => {

			it("defaults a bare name to type string with no size override", () => {
				var parsed = probe.$parseGeneratorArgs(["title"]);
				expect(arrayLen(parsed.properties)).toBe(1);
				expect(parsed.properties[1].name).toBe("title");
				expect(parsed.properties[1].type).toBe("string");
				expect(structKeyExists(parsed.properties[1], "limit")).toBeFalse();
			});

			it("parses name:type without braces", () => {
				var parsed = probe.$parseGeneratorArgs(["title:string"]);
				expect(parsed.properties[1].name).toBe("title");
				expect(parsed.properties[1].type).toBe("string");
				expect(structKeyExists(parsed.properties[1], "limit")).toBeFalse();
			});

			it("parses title:string{50} as type string with limit 50", () => {
				var parsed = probe.$parseGeneratorArgs(["title:string{50}"]);
				expect(parsed.properties[1].name).toBe("title");
				expect(parsed.properties[1].type).toBe("string");
				expect(parsed.properties[1].limit).toBe("50");
			});

			it("parses price:decimal{10,2} as precision 10 and scale 2", () => {
				var parsed = probe.$parseGeneratorArgs(["price:decimal{10,2}"]);
				expect(parsed.properties[1].name).toBe("price");
				expect(parsed.properties[1].type).toBe("decimal");
				expect(parsed.properties[1].precision).toBe("10");
				expect(parsed.properties[1].scale).toBe("2");
				expect(structKeyExists(parsed.properties[1], "limit")).toBeFalse();
			});

			it("applies a brace limit to integer / text / binary / varchar aliases", () => {
				var parsed = probe.$parseGeneratorArgs([
					"count:integer{8}",
					"body:text{1000}",
					"blob:binary{4096}",
					"sku:varchar{80}"
				]);
				expect(parsed.properties[1].type).toBe("integer");
				expect(parsed.properties[1].limit).toBe("8");
				expect(parsed.properties[2].type).toBe("text");
				expect(parsed.properties[2].limit).toBe("1000");
				expect(parsed.properties[3].type).toBe("binary");
				expect(parsed.properties[3].limit).toBe("4096");
				expect(parsed.properties[4].type).toBe("varchar");
				expect(parsed.properties[4].limit).toBe("80");
			});

			it("still parses status:enum:a,b values after the type token", () => {
				var parsed = probe.$parseGeneratorArgs(["status:enum:draft,published"]);
				expect(parsed.properties[1].name).toBe("status");
				expect(parsed.properties[1].type).toBe("enum");
				expect(parsed.properties[1].values).toBe("draft,published");
				expect(structKeyExists(parsed.properties[1], "limit")).toBeFalse();
			});

			it("does not treat enum value lists as brace modifiers", () => {
				var parsed = probe.$parseGeneratorArgs(["status:enum:a,b,c"]);
				expect(parsed.properties[1].type).toBe("enum");
				expect(parsed.properties[1].values).toBe("a,b,c");
			});

			it("still collects association flags alongside sized properties", () => {
				var parsed = probe.$parseGeneratorArgs([
					"title:string{50}",
					"--belongsTo=user",
					"price:decimal{12,4}"
				]);
				expect(arrayLen(parsed.properties)).toBe(2);
				expect(parsed.belongsTo[1]).toBe("user");
				expect(parsed.properties[1].limit).toBe("50");
				expect(parsed.properties[2].precision).toBe("12");
				expect(parsed.properties[2].scale).toBe("4");
			});

		});

		describe("parseGeneratorArgs — unknown flags", () => {

			// A misspelled association flag used to fall through every branch
			// and vanish. `--belogsTo=post` then produced a clean-looking
			// scaffold with no association and no parent wiring, and nothing
			// in the output hinted why (live-demo rehearsal, 2026-09-13).
			// This is the second flag this loop swallowed — #2327 was --force.

			it("rejects a misspelled association flag instead of ignoring it", () => {
				expect(() => {
					probe.$parseGeneratorArgs(["body:text", "--belogsTo=post"]);
				}).toThrow(type = "Wheels.CLI.UnknownFlag");
			});

			it("names the flag and suggests the nearest real one", () => {
				var message = "";
				try {
					probe.$parseGeneratorArgs(["--belogsTo=post"]);
				} catch (Wheels.CLI.UnknownFlag e) {
					message = e.message;
				}
				expect(message).toInclude("--belogsTo");
				expect(message).toInclude("Did you mean --belongsTo?");
			});

			it("suggests --hasMany for --hasMnay", () => {
				var message = "";
				try {
					probe.$parseGeneratorArgs(["--hasMnay=post"]);
				} catch (Wheels.CLI.UnknownFlag e) {
					message = e.message;
				}
				expect(message).toInclude("Did you mean --hasMany?");
			});

			it("omits the suggestion when nothing is close", () => {
				var message = "";
				try {
					probe.$parseGeneratorArgs(["--completely-wrong=1"]);
				} catch (Wheels.CLI.UnknownFlag e) {
					message = e.message;
				}
				expect(message).toInclude("Unknown flag --completely-wrong");
				expect(message).notToInclude("Did you mean");
				// Still lists the valid flags so the user is never stranded.
				expect(message).toInclude("--belongsTo=");
			});

			it("still accepts the three real flags in any case", () => {
				var parsed = probe.$parseGeneratorArgs([
					"--BELONGSTO=user", "--hasmany=comments", "--HasOne=profile"
				]);
				expect(parsed.belongsTo[1]).toBe("user");
				expect(parsed.hasMany[1]).toBe("comments");
				expect(parsed.hasOne[1]).toBe("profile");
			});

			it("does not treat a property token containing dashes as a flag", () => {
				// Only a leading `--` is a flag; a dash inside a name is property data.
				// A CFML property name can't hold a hyphen, so it becomes an underscore.
				expect(probe.$parseGeneratorArgs(["display-name:string"]).properties[1].name).toBe("display_name");
				expect(probe.$parseGeneratorArgs(["display_name:string"]).properties[1].name).toBe("display_name");
			});

		});

		describe("parseGeneratorArgs — required-by-default and the :optional / =value markers", () => {

			it("marks an unmarked column required", () => {
				var p = probe.$parseGeneratorArgs(["title:string"]).properties[1];
				expect(p.required).toBeTrue();
				expect(structKeyExists(p, "default")).toBeFalse();
			});

			it("marks a :optional column not required", () => {
				var p = probe.$parseGeneratorArgs(["note:text:optional"]).properties[1];
				expect(p.name).toBe("note");
				expect(p.type).toBe("text");
				expect(p.required).toBeFalse();
			});

			it("captures a =value default and keeps the column required", () => {
				var p = probe.$parseGeneratorArgs(["status:string=draft"]).properties[1];
				expect(p.name).toBe("status");
				expect(p.type).toBe("string");
				expect(p.default).toBe("draft");
				expect(p.required).toBeTrue();
			});

			it("combines =value with :optional (nullable, defaulted)", () => {
				var p = probe.$parseGeneratorArgs(["note:string=none:optional"]).properties[1];
				expect(p.type).toBe("string");
				expect(p.default).toBe("none");
				expect(p.required).toBeFalse();
			});

			it("keeps a =value alongside a brace size modifier", () => {
				var p = probe.$parseGeneratorArgs(["title:string{120}=untitled"]).properties[1];
				expect(p.type).toBe("string");
				expect(p.limit).toBe("120");
				expect(p.default).toBe("untitled");
				expect(p.required).toBeTrue();
			});

			it("treats an empty =value ('name:string=') as no default", () => {
				var p = probe.$parseGeneratorArgs(["code:string="]).properties[1];
				expect(p.type).toBe("string");
				expect(structKeyExists(p, "default")).toBeFalse();
				expect(p.required).toBeTrue();
			});

			it("strips :optional before the enum value list, leaving values intact", () => {
				var p = probe.$parseGeneratorArgs(["status:enum:draft,published:optional"]).properties[1];
				expect(p.type).toBe("enum");
				expect(p.values).toBe("draft,published");
				expect(p.required).toBeFalse();
			});

			// LuCLI parses a positional "status:string=active" as a key=value named
			// option and hands the module back the exact token "--status:string=active".
			// parseGeneratorArgs must recover it as a defaulted property, not reject it
			// as an unknown flag.
			it("recovers the LuCLI-mangled --name:type=value form as a property", () => {
				var parsed = probe.$parseGeneratorArgs(["name:string", "--status:string=active"]);
				expect(arrayLen(parsed.properties)).toBe(2);
				var p = parsed.properties[2];
				expect(p.name).toBe("status");
				expect(p.type).toBe("string");
				expect(p.default).toBe("active");
				expect(p.required).toBeTrue();
			});

			it("still rejects a genuine unknown --flag that is not a mangled property", () => {
				// The recovery keys on the ":" every property token carries; a real flag
				// typo has none, so it must still fail loudly rather than be swallowed.
				expect(() => {
					probe.$parseGeneratorArgs(["name:string", "--bogusflag"]);
				}).toThrow(type = "Wheels.CLI.UnknownFlag");
			});

		});

	}

}
