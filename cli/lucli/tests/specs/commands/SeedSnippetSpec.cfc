/**
 * `wheels generate snippets seed-data` writes the seed files where `wheels seed` reads
 * them, app/db/seeds.cfm and app/db/seeds/development.cfm (4434), and keeps a seed file
 * that already exists unless --force is given.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("seed-data snippet (4434)", () => {

			beforeEach(() => {
				variables.root = getTempDirectory() & "wheels-seed-snippet-" & CreateUUID();
				DirectoryCreate(variables.root & "/config", true);
				// generate only runs in a Wheels project.
				FileWrite(variables.root & "/config/settings.cfm", "");
				variables.mod = new cli.lucli.Module(cwd = variables.root);
				// Through the public command: the snippet registry finds its templates relative
				// to Module.cfc, which a makePublic() copy of a private method doesn't preserve.
			});

			afterEach(() => {
				if (DirectoryExists(variables.root)) {
					DirectoryDelete(variables.root, true);
				}
			});

			it("writes app/db/seeds.cfm and app/db/seeds/development.cfm", () => {
				variables.mod.generate(arg1 = "snippets", arg2 = "seed-data");
				expect(FileExists(variables.root & "/app/db/seeds.cfm")).toBeTrue();
				expect(FileExists(variables.root & "/app/db/seeds/development.cfm")).toBeTrue();
			});

			it("keeps an existing seed file unless forced", () => {
				DirectoryCreate(variables.root & "/app/db/seeds", true);
				FileWrite(variables.root & "/app/db/seeds.cfm", "<!--- mine --->");
				variables.mod.generate(arg1 = "snippets", arg2 = "seed-data");
				expect(FileRead(variables.root & "/app/db/seeds.cfm")).toBe("<!--- mine --->");
				expect(FileExists(variables.root & "/app/db/seeds/development.cfm")).toBeTrue();
				variables.mod.generate(arg1 = "snippets", arg2 = "seed-data", force = true);
				expect(FileRead(variables.root & "/app/db/seeds.cfm")).notToBe("<!--- mine --->");
			});

		});

	}

}
