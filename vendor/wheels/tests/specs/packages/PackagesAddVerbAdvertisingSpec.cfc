/**
 * User-facing surfaces must advertise `wheels packages add`, not
 * `wheels packages install`. LuCLI intercepts the literal `install`
 * subcommand before Module.cfc runs (#2610, #2706, #3378).
 *
 * Mentions of `install` that explicitly say it is not the verb are fine;
 * copy-to-clipboard snippets and recommended commands are not.
 */
component extends="wheels.WheelsTest" {

	function run() {

		var ctx = {repoRoot: expandPath("/wheels/../..")};

		describe("User-facing surfaces advertise `packages add`", () => {

			it("the in-app packages page copies `wheels packages add`", () => {
				var path = expandPath("/wheels/public/views/packagelist.cfm");
				expect(fileExists(path)).toBeTrue("Missing file: " & path);
				var source = fileRead(path);

				expect(source contains "wheels packages add ").toBeTrue(
					"packagelist.cfm copy snippet must use `wheels packages add`."
				);
				expect(source contains "wheels packages install ").toBeFalse(
					"packagelist.cfm must not put `wheels packages install` in a copy snippet. "
					& "LuCLI intercepts that verb before Module.cfc."
				);
			});

			it("the packages website copy snippets use `add`, not `install`", () => {
				var files = [
					ctx.repoRoot & "/web/sites/packages/src/pages/index.astro",
					ctx.repoRoot & "/web/sites/packages/src/pages/[name].astro",
					ctx.repoRoot & "/web/sites/packages/src/components/PackageCard.astro"
				];
				var i = 0;
				var n = arrayLen(files);
				for (i = 1; i <= n; i++) {
					expect(fileExists(files[i])).toBeTrue("Missing file: " & files[i]);
					var source = fileRead(files[i]);

					// Copy-to-clipboard / recommended command shapes.
					expect(find("wheels packages install {", source) > 0).toBeFalse(
						files[i] & " still has a copy snippet `wheels packages install {name}`. Use `add`."
					);
					expect(find("wheels packages install &lt;name&gt;", source) > 0).toBeFalse(
						files[i] & " still recommends `wheels packages install <name>`. Use `add`."
					);
				}
			});

			it("the packages website index recommends `wheels packages add`", () => {
				var path = ctx.repoRoot & "/web/sites/packages/src/pages/index.astro";
				var source = fileRead(path);
				expect(source contains "wheels packages add &lt;name&gt;").toBeTrue(
					"packages site index should recommend `wheels packages add <name>`."
				);
			});

		});

	}

}
