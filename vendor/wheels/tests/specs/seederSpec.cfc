component extends="wheels.WheelsTest" {

	function beforeAll() {
		seeder = CreateObject("component", "wheels.Seeder").init(
			seedPath = "/wheels/tests/_assets/seeder/"
		);
	}

	function run() {

		describe("Seeder", () => {

			describe("init()", () => {

				it("initializes with default seed path", () => {
					local.s = CreateObject("component", "wheels.Seeder").init();
					expect(local.s.seedPath).toInclude("app");
				});

				it("initializes with custom seed path", () => {
					expect(seeder.seedPath).toInclude("seeder");
				});

			});

			describe("hasSeedFiles()", () => {

				it("returns true when seeds.cfm exists", () => {
					local.s = CreateObject("component", "wheels.Seeder").init(
						seedPath = "/wheels/tests/_assets/seeder/"
					);
					expect(local.s.hasSeedFiles()).toBeTrue();
				});

				it("returns false when no seed files exist", () => {
					local.s = CreateObject("component", "wheels.Seeder").init(
						seedPath = "/wheels/tests/_assets/seeder/empty/"
					);
					expect(local.s.hasSeedFiles()).toBeFalse();
				});

			});

			describe("runSeeds()", () => {

				it("returns failure when no seed files found", () => {
					local.s = CreateObject("component", "wheels.Seeder").init(
						seedPath = "/wheels/tests/_assets/seeder/empty/"
					);
					local.result = local.s.runSeeds(environment = "testing");
					expect(local.result.success).toBeFalse();
					expect(local.result.message).toInclude("No seed files found");
				});

				it("runs main seeds.cfm file", () => {
					local.s = CreateObject("component", "wheels.Seeder").init(
						seedPath = "/wheels/tests/_assets/seeder/"
					);
					local.result = local.s.runSeeds(environment = "testing");
					expect(local.result.success).toBeTrue();
					expect(local.result.totalCreated).toBeGTE(0);
				});

				it("includes environment-specific seeds when available", () => {
					local.s = CreateObject("component", "wheels.Seeder").init(
						seedPath = "/wheels/tests/_assets/seeder/withenv/"
					);
					local.result = local.s.runSeeds(environment = "testing");
					expect(local.result.success).toBeTrue();
				});

				it("returns failure and rolls back when a seedOnce entry fails validation", () => {
					// Clean any leftover from earlier runs so seedOnce can't skip.
					local.leftover = model("user").findOne(where = "username = 'SeederPartialOK99'");
					if (IsObject(local.leftover)) {
						local.leftover.delete();
					}

					local.s = CreateObject("component", "wheels.Seeder").init(
						seedPath = "/wheels/tests/_assets/seeder/partialfailure/"
					);
					local.result = local.s.runSeeds(environment = "testing");

					expect(local.result.success).toBeFalse();
					expect(local.result.message).toInclude("failed");
					expect(local.result.message).toInclude("user");
					expect(local.result.totalFailed).toBe(1);

					// The successful first entry must have been rolled back along
					// with the failed one (atomicity: half-applied seed runs must
					// not look like fully-applied ones).
					local.leaked = model("user").findOne(where = "username = 'SeederPartialOK99'");
					expect(IsObject(local.leaked)).toBeFalse();
				});

				it("throws when the environment name contains path traversal characters", () => {
					expect(function() {
						seeder.runSeeds(environment = "../../../app/somefile");
					}).toThrow("Wheels.Seeder.InvalidEnvironment");
				});

				it("throws when the environment name contains other unsafe characters", () => {
					expect(function() {
						seeder.runSeeds(environment = "testing/extra");
					}).toThrow("Wheels.Seeder.InvalidEnvironment");
				});

			});

			describe("seedOnce()", () => {

				it("throws when uniqueProperties not found in properties struct", () => {
					expect(function() {
						seeder.seedOnce(
							modelName = "author",
							uniqueProperties = "nonexistent",
							properties = {firstName: "Test"}
						);
					}).toThrow("Wheels.Seeder.MissingProperty");
				});

				it("throws when a unique property value is not a simple value", () => {
					expect(function() {
						seeder.seedOnce(
							modelName = "author",
							uniqueProperties = "firstName",
							properties = {firstName: {nested: "struct"}, lastName: "Test"}
						);
					}).toThrow("Wheels.Seeder.InvalidUniqueValue");
				});

				it("throws when uniqueProperties yields no uniqueness conditions", () => {
					expect(function() {
						seeder.seedOnce(
							modelName = "author",
							uniqueProperties = "",
							properties = {firstName: "Test"}
						);
					}).toThrow("Wheels.Seeder.EmptyUniqueProperties");
				});

				it("creates a new record when no match exists", () => {
					// Use a unique value to avoid conflicts with other test data
					local.uniqueFirst = "SeederTest_#CreateUUID()#";
					local.result = seeder.seedOnce(
						modelName = "author",
						uniqueProperties = "firstName,lastName",
						properties = {firstName: local.uniqueFirst, lastName: "SeederSpec"}
					);
					expect(local.result.action).toBe("created");

					// Clean up
					local.record = model("author").findOne(where="firstName = '#local.uniqueFirst#'");
					if (IsObject(local.record)) {
						local.record.delete();
					}
				});

				it("skips creation when matching record exists", () => {
					// Create initial record
					local.uniqueFirst = "SeederDup_#CreateUUID()#";
					local.author = model("author").create(firstName=local.uniqueFirst, lastName="DupTest");

					// seedOnce should skip
					local.result = seeder.seedOnce(
						modelName = "author",
						uniqueProperties = "firstName,lastName",
						properties = {firstName: local.uniqueFirst, lastName: "DupTest"}
					);
					expect(local.result.action).toBe("skipped");

					// Clean up
					local.author.delete();
				});

				it("counts failed entries and reports them in the result", () => {
					seeder.totalFailed = 0;

					// Missing password (and firstname/lastname) fails the User
					// model's validatesPresenceOf, driving the "failed" action.
					local.result = seeder.seedOnce(
						modelName = "user",
						uniqueProperties = "username",
						properties = {username: "SeederFailCount99"}
					);

					expect(local.result.action).toBe("failed");
					expect(seeder.totalFailed).toBe(1);
				});

				it("tracks created and skipped counts", () => {
					// Reset counters
					seeder.totalCreated = 0;
					seeder.totalSkipped = 0;

					local.uniqueFirst = "SeederCount_#CreateUUID()#";

					// First call creates
					seeder.seedOnce(
						modelName = "author",
						uniqueProperties = "firstName,lastName",
						properties = {firstName: local.uniqueFirst, lastName: "CountTest"}
					);
					expect(seeder.totalCreated).toBe(1);

					// Second call skips
					seeder.seedOnce(
						modelName = "author",
						uniqueProperties = "firstName,lastName",
						properties = {firstName: local.uniqueFirst, lastName: "CountTest"}
					);
					expect(seeder.totalSkipped).toBe(1);

					// Clean up
					local.record = model("author").findOne(where="firstName = '#local.uniqueFirst#'");
					if (IsObject(local.record)) {
						local.record.delete();
					}
				});

			});

			describe("generateSeeds()", () => {

				it("creates fake records for the requested model and reports honest success", () => {
					// Capture existing Author ids so cleanup only removes our rows.
					local.beforeIds = ValueList(model("Author").findAll(select = "id").id);

					local.gen = CreateObject("component", "wheels.Seeder").init();
					local.result = local.gen.generateSeeds(models = "Author", count = 2);

					expect(local.result.success).toBeTrue();
					expect(local.result.mode).toBe("generate");
					expect(local.result.totalCreated).toBe(2);
					// CLI bridge contract: Module.cfc::runSeed() prints
					// `#result.totalSkipped# skipped` whenever totalCreated exists,
					// so generate results MUST carry the key (always 0 — generate
					// mode never skips) or a successful run throws in the CLI.
					expect(StructKeyExists(local.result, "totalSkipped")).toBeTrue();
					expect(local.result.totalSkipped).toBe(0);
					expect(local.result.totalFailed).toBe(0);
					expect(ArrayLen(local.result.seeded)).toBe(1);
					expect(local.result.seeded[1].model).toBe("Author");
					expect(local.result.seeded[1].count).toBe(2);
					expect(local.result.seeded[1].success).toBeTrue();

					// The rows must really exist — the old generate loop iterated the
					// $classData().properties STRUCT as if it were an array of property
					// structs, threw on every model, and created zero rows while still
					// reporting success (issue #3082).
					local.afterIds = ValueList(model("Author").findAll(select = "id").id);
					expect(ListLen(local.afterIds) - ListLen(local.beforeIds)).toBe(2);

					// Clean up only the rows we generated.
					if (Len(local.beforeIds)) {
						model("Author").deleteAll(where = "id NOT IN (#local.beforeIds#)", instantiate = false);
					} else {
						model("Author").deleteAll(instantiate = false);
					}
				});

				it("reports overall failure when a model cannot be seeded", () => {
					local.gen = CreateObject("component", "wheels.Seeder").init();
					local.result = local.gen.generateSeeds(
						models = "NoSuchModel_#Replace(CreateUUID(), '-', '', 'all')#",
						count = 2
					);

					// Honesty contract: a model that errors must not be reported as
					// success. Generate mode previously appended success=false entries
					// while leaving the overall result success=true and the CLI printing
					// "Seeding completed." with exit 0 (issue #3082).
					expect(local.result.success).toBeFalse();
					expect(local.result.totalCreated).toBe(0);
					expect(local.result.totalFailed).toBe(1);
					expect(ArrayLen(local.result.seeded)).toBe(1);
					expect(local.result.seeded[1].success).toBeFalse();
					expect(StructKeyExists(local.result.seeded[1], "error")).toBeTrue();
				});

				it("reports failure (not silent success) when an explicit list resolves to no models", () => {
					local.gen = CreateObject("component", "wheels.Seeder").init();
					// A delimiter-only list is a non-blank value (so it does NOT fall
					// back to auto-scanning /app/models) that still resolves to zero
					// usable model names — the run must report failure, not success.
					local.result = local.gen.generateSeeds(models = ",", count = 2);
					expect(local.result.success).toBeFalse();
					expect(local.result.totalCreated).toBe(0);
					expect(local.result.message).toInclude("No models");
				});

				it("auto-scan excludes the framework's parent Model.cfc base class", () => {
					// Every scaffolded app ships app/models/Model.cfc as the base
					// class for its models. It has no backing table, so including
					// it in the auto-scan makes model('Model') throw
					// Wheels.TableNotFound and — under the honesty rule — forces
					// every blank-models `wheels seed --generate` run to fail on a
					// conventional app. Mirrors the CLI's own enumeration, which
					// skips Model.cfc (Analysis.cfc / Module.cfc).
					local.gen = CreateObject("component", "wheels.Seeder").init();
					local.resolved = local.gen.$resolveGenerateModels("");
					expect(ArrayFindNoCase(local.resolved, "Model")).toBe(0);
				});

				it("keeps explicitly requested model names verbatim", () => {
					// The Model.cfc exclusion applies only to the auto-scan; an
					// explicit list is the caller's responsibility and passes
					// through untouched.
					local.gen = CreateObject("component", "wheels.Seeder").init();
					local.resolved = local.gen.$resolveGenerateModels(" Author , User ");
					expect(local.resolved).toBe(["Author", "User"]);
				});

			});

		});

	}

}
