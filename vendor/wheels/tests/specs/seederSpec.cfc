/**
 * Seeder suite plus hardener proofs for desk IDs S1–S10. Desk IDs stay locked.
 *
 * S4 and S5 are flipped (no longer HOLDs). S1–S3 / S6–S10 stay as proven on develop.
 *
 * This is the only seeder spec file. Do not invent wheels.tests.specs.seeder.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		seeder = CreateObject("component", "wheels.Seeder").init(
			seedPath = "/wheels/tests/_assets/seeder/"
		);
	}

	function run() {

		describe("Seeder", () => {

			describe("init()", () => {

				it("S9: default seedPath is ExpandPath of /app/db/", () => {
					local.s = CreateObject("component", "wheels.Seeder").init();
					expect(local.s.seedMappingPath).toBe("/app/db/");
					expect(local.s.seedPath).toBe(ExpandPath("/app/db/"));
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

				it("S3: hasSeedFiles is true for a stray seeds/*.cfm that runSeeds will not include", () => {
					// hasSeedFiles() returns true if ANY seeds/*.cfm exists.
					// runSeeds() only includes seeds.cfm + seeds/<environment>.cfm.
					local.s = CreateObject("component", "wheels.Seeder").init(
						seedPath = "/wheels/tests/_assets/seeder/stray/"
					);
					expect(local.s.hasSeedFiles()).toBeTrue();

					$deleteAuthorByFirstName("SeederStrayOrphan99");
					local.result = local.s.runSeeds(environment = "testing");
					expect(local.result.success).toBeFalse();
					expect(local.result.message).toInclude("No seed files found");
					expect(IsObject(model("author").findOne(where = "firstName = 'SeederStrayOrphan99'"))).toBeFalse();
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

				it("S1: runs main seeds.cfm and creates the fixture record", () => {
					$deleteAuthorByFirstName("SeederMainOK99");

					local.s = CreateObject("component", "wheels.Seeder").init(
						seedPath = "/wheels/tests/_assets/seeder/"
					);
					local.result = local.s.runSeeds(environment = "testing");

					expect(local.result.success).toBeTrue();
					expect(local.result.totalCreated).toBe(1);
					expect(local.result.totalSkipped).toBe(0);
					local.created = model("author").findOne(where = "firstName = 'SeederMainOK99'");
					expect(IsObject(local.created)).toBeTrue();
					expect(local.created.lastName).toBe("MainSeed");
					local.created.delete();
				});

				it("S2: includes environment-specific seeds when available", () => {
					$deleteAuthorByFirstName("SeederEnvMain99");
					$deleteAuthorByFirstName("SeederEnvTest99");

					local.s = CreateObject("component", "wheels.Seeder").init(
						seedPath = "/wheels/tests/_assets/seeder/withenv/"
					);
					local.result = local.s.runSeeds(environment = "testing");

					expect(local.result.success).toBeTrue();
					expect(local.result.totalCreated).toBe(2);
					expect(local.result.environment).toBe("testing");
					local.mainRow = model("author").findOne(where = "firstName = 'SeederEnvMain99'");
					local.envRow = model("author").findOne(where = "firstName = 'SeederEnvTest99'");
					expect(IsObject(local.mainRow)).toBeTrue();
					expect(IsObject(local.envRow)).toBeTrue();
					expect(local.mainRow.lastName).toBe("EnvMain");
					expect(local.envRow.lastName).toBe("EnvTest");
					local.mainRow.delete();
					local.envRow.delete();
				});

				it("S2: an environment without a matching file does not include seeds/testing.cfm", () => {
					$deleteAuthorByFirstName("SeederEnvMain99");
					$deleteAuthorByFirstName("SeederEnvTest99");

					local.s = CreateObject("component", "wheels.Seeder").init(
						seedPath = "/wheels/tests/_assets/seeder/withenv/"
					);
					local.result = local.s.runSeeds(environment = "development");

					expect(local.result.success).toBeTrue();
					expect(local.result.totalCreated).toBe(1);
					expect(local.result.environment).toBe("development");
					expect(IsObject(model("author").findOne(where = "firstName = 'SeederEnvMain99'"))).toBeTrue();
					expect(IsObject(model("author").findOne(where = "firstName = 'SeederEnvTest99'"))).toBeFalse();
					$deleteAuthorByFirstName("SeederEnvMain99");
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

				it("S7: include-throw is caught, reported, and rolled back", () => {
					$deleteAuthorByFirstName("SeederThrowOK99");

					local.s = CreateObject("component", "wheels.Seeder").init(
						seedPath = "/wheels/tests/_assets/seeder/includethrow/"
					);
					local.result = local.s.runSeeds(environment = "testing");

					expect(local.result.success).toBeFalse();
					expect(local.result.message).toInclude("Seed failed:");
					expect(local.result.message).toInclude("intentional include throw");
					expect(StructKeyExists(local.result, "detail")).toBeTrue();
					expect(IsObject(model("author").findOne(where = "firstName = 'SeederThrowOK99'"))).toBeFalse();
				});

				it("S8: request.$wheelsSeeder is left set after a successful run", () => {
					$deleteAuthorByFirstName("SeederMainOK99");
					StructDelete(request, "$wheelsSeeder");

					local.s = CreateObject("component", "wheels.Seeder").init(
						seedPath = "/wheels/tests/_assets/seeder/"
					);
					local.result = local.s.runSeeds(environment = "testing");

					expect(local.result.success).toBeTrue();
					expect(StructKeyExists(request, "$wheelsSeeder")).toBeTrue();
					expect(request.$wheelsSeeder.seedMappingPath).toBe("/wheels/tests/_assets/seeder/");
					$deleteAuthorByFirstName("SeederMainOK99");
				});

				it("S8: a later run still sees request.$wheelsSeeder", () => {
					$deleteAuthorByFirstName("SeederMainOK99");
					$deleteAuthorByFirstName("SeederEnvMain99");
					$deleteAuthorByFirstName("SeederEnvTest99");
					StructDelete(request, "$wheelsSeeder");

					local.first = CreateObject("component", "wheels.Seeder").init(
						seedPath = "/wheels/tests/_assets/seeder/"
					);
					local.first.runSeeds(environment = "testing");
					expect(StructKeyExists(request, "$wheelsSeeder")).toBeTrue();

					local.second = CreateObject("component", "wheels.Seeder").init(
						seedPath = "/wheels/tests/_assets/seeder/withenv/"
					);
					local.second.runSeeds(environment = "testing");

					// Never cleared — a later run overwrites the leftover, it does not delete it.
					expect(StructKeyExists(request, "$wheelsSeeder")).toBeTrue();
					expect(request.$wheelsSeeder.seedMappingPath).toBe("/wheels/tests/_assets/seeder/withenv/");
					$deleteAuthorByFirstName("SeederMainOK99");
					$deleteAuthorByFirstName("SeederEnvMain99");
					$deleteAuthorByFirstName("SeederEnvTest99");
				});

				it("S8: the include-throw catch path also leaves request.$wheelsSeeder set", () => {
					$deleteAuthorByFirstName("SeederThrowOK99");
					StructDelete(request, "$wheelsSeeder");

					local.s = CreateObject("component", "wheels.Seeder").init(
						seedPath = "/wheels/tests/_assets/seeder/includethrow/"
					);
					local.result = local.s.runSeeds(environment = "testing");

					expect(local.result.success).toBeFalse();
					expect(StructKeyExists(request, "$wheelsSeeder")).toBeTrue();
					expect(request.$wheelsSeeder.seedMappingPath).toBe("/wheels/tests/_assets/seeder/includethrow/");
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

				it("S4: seedOnce binds unique values so an apostrophe unique key skips on the second call", () => {
					// Kill-case: quote-escape interpolation (`Replace(val, "'", "''")`
					// into findOne(where=)) left doubled apostrophes in the bound
					// value, so the second seedOnce missed the stored O'Brien row
					// and created again. Placeholders + findOne(parameterize=true)
					// must skip (action="skipped") and leave a single row.
					local.uniqueFirst = "O'Brien_#Replace(CreateUUID(), '-', '', 'all')#";

					local.first = seeder.seedOnce(
						modelName = "author",
						uniqueProperties = "firstName",
						properties = {firstName: local.uniqueFirst, lastName: "QuoteEscape"}
					);
					expect(local.first.action).toBe("created");
					expect(StructKeyExists(local.first, "key")).toBeTrue();

					local.second = seeder.seedOnce(
						modelName = "author",
						uniqueProperties = "firstName",
						properties = {firstName: local.uniqueFirst, lastName: "QuoteEscape"}
					);
					expect(local.second.action).toBe("skipped");
					expect(StructKeyExists(local.second, "key")).toBeFalse();

					// Count matches in CFML — a findOne(where=) assertion would
					// re-introduce the same apostrophe extraction bug.
					local.allAuthors = model("author").findAll(select = "id,firstName");
					local.matchCount = 0;
					for (local.i = 1; local.i <= local.allAuthors.recordCount; local.i++) {
						if (local.allAuthors.firstName[local.i] == local.uniqueFirst) {
							local.matchCount++;
						}
					}
					expect(local.matchCount).toBe(1);

					local.firstRow = model("author").findByKey(local.first.key);
					if (IsObject(local.firstRow)) {
						local.firstRow.delete();
					}
					local.leftoverQuery = model("author").findAll(select = "id,firstName");
					for (local.i = 1; local.i <= local.leftoverQuery.recordCount; local.i++) {
						if (local.leftoverQuery.firstName[local.i] == local.uniqueFirst) {
							local.leftover = model("author").findByKey(local.leftoverQuery.id[local.i]);
							if (IsObject(local.leftover)) {
								local.leftover.delete();
							}
						}
					}
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
					// Adobe CF's compiler only accepts a plain `query.column` reference inside
					// ValueList(); a chained expression is a COMPILE error that crashes the
					// whole bundle. Assign the query to a variable first.
					local.beforeQuery = model("Author").findAll(select = "id");
					local.beforeIds = ValueList(local.beforeQuery.id);

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
					local.afterQuery = model("Author").findAll(select = "id");
					local.afterIds = ValueList(local.afterQuery.id);
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

				it("S5: generateSeeds write is transactional — a mixed list leaves no rows", () => {
					// Mixed list still reports honesty (success=false, totalFailed=1).
					// totalCreated stays the in-transaction count after rollback,
					// same as runSeeds (it reports totals even though rows were
					// rolled back). After the call, no new Author rows remain vs
					// the before-ids snapshot.
					local.beforeQuery = model("Author").findAll(select = "id");
					local.beforeIds = ValueList(local.beforeQuery.id);

					local.gen = CreateObject("component", "wheels.Seeder").init();
					local.result = local.gen.generateSeeds(
						models = "Author,NoSuchModel_SeederS5",
						count = 1
					);

					expect(local.result.success).toBeFalse();
					expect(local.result.totalCreated).toBe(1);
					expect(local.result.totalFailed).toBe(1);
					expect(ArrayLen(local.result.seeded)).toBe(2);
					expect(local.result.seeded[1].model).toBe("Author");
					expect(local.result.seeded[1].success).toBeTrue();
					expect(local.result.seeded[2].success).toBeFalse();

					local.afterQuery = model("Author").findAll(select = "id");
					local.afterIds = ValueList(local.afterQuery.id);
					expect(local.afterIds).toBe(local.beforeIds);

					if (Len(local.beforeIds)) {
						model("Author").deleteAll(where = "id NOT IN (#local.beforeIds#)", instantiate = false);
					} else {
						model("Author").deleteAll(instantiate = false);
					}
				});

				it("S6: count=0 reports overall failure even when the per-model entry succeeds", () => {
					// success requires totalCreated>0. The per-model loop does not
					// run (1 <= 0), so seededCount==count and the entry is success=true.
					local.beforeQuery = model("Author").findAll(select = "id");
					local.beforeIds = ValueList(local.beforeQuery.id);

					local.gen = CreateObject("component", "wheels.Seeder").init();
					local.result = local.gen.generateSeeds(models = "Author", count = 0);

					expect(local.result.success).toBeFalse();
					expect(local.result.totalCreated).toBe(0);
					expect(local.result.totalFailed).toBe(0);
					expect(ArrayLen(local.result.seeded)).toBe(1);
					expect(local.result.seeded[1].count).toBe(0);
					expect(local.result.seeded[1].success).toBeTrue();

					local.afterQuery = model("Author").findAll(select = "id");
					expect(ValueList(local.afterQuery.id)).toBe(local.beforeIds);
				});

				it("S6: a negative count creates no rows and marks the model failed", () => {
					// The for-loop does not run. seededCount (0) != count (-1), so
					// the entry is success=false and totalFailed increments.
					local.beforeQuery = model("Author").findAll(select = "id");
					local.beforeIds = ValueList(local.beforeQuery.id);

					local.gen = CreateObject("component", "wheels.Seeder").init();
					local.result = local.gen.generateSeeds(models = "Author", count = -1);

					expect(local.result.success).toBeFalse();
					expect(local.result.totalCreated).toBe(0);
					expect(local.result.totalFailed).toBe(1);
					expect(ArrayLen(local.result.seeded)).toBe(1);
					expect(local.result.seeded[1].count).toBe(0);
					expect(local.result.seeded[1].success).toBeFalse();

					local.afterQuery = model("Author").findAll(select = "id");
					expect(ValueList(local.afterQuery.id)).toBe(local.beforeIds);
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

			describe("$generateTestData()", () => {

				it("S10: email names return an example.com address", () => {
					expect(seeder.$generateTestData(propertyName = "email", propertyType = "string", index = 1)).toBe("test1@example.com");
					expect(seeder.$generateTestData(propertyName = "userEmail", propertyType = "integer", index = 4)).toBe("test4@example.com");
				});

				it("S10: firstname / fname cycle the first-name list", () => {
					expect(seeder.$generateTestData(propertyName = "firstName", propertyType = "string", index = 1)).toBe("John");
					expect(seeder.$generateTestData(propertyName = "fname", propertyType = "string", index = 2)).toBe("Jane");
					expect(seeder.$generateTestData(propertyName = "firstName", propertyType = "string", index = 11)).toBe("John");
				});

				it("S10: lastname / lname cycle the last-name list", () => {
					expect(seeder.$generateTestData(propertyName = "lastName", propertyType = "string", index = 1)).toBe("Smith");
					expect(seeder.$generateTestData(propertyName = "lname", propertyType = "string", index = 2)).toBe("Johnson");
				});

				it("S10: exact name and username return TestUserN", () => {
					expect(seeder.$generateTestData(propertyName = "name", propertyType = "string", index = 3)).toBe("TestUser3");
					expect(seeder.$generateTestData(propertyName = "userName", propertyType = "string", index = 3)).toBe("TestUser3");
					expect(seeder.$generateTestData(propertyName = "displayName", propertyType = "string", index = 3)).toBe("displayName Test 3");
				});

				it("S10: phone / mobile, address / street, and geo names", () => {
					expect(seeder.$generateTestData(propertyName = "phone", propertyType = "string", index = 1)).toBe("555-1001");
					expect(seeder.$generateTestData(propertyName = "mobile", propertyType = "string", index = 2)).toBe("555-1002");
					expect(seeder.$generateTestData(propertyName = "address", propertyType = "string", index = 4)).toBe("4 Test Street");
					expect(seeder.$generateTestData(propertyName = "street", propertyType = "string", index = 4)).toBe("4 Test Street");
					expect(seeder.$generateTestData(propertyName = "city", propertyType = "string", index = 1)).toBe("New York");
					expect(seeder.$generateTestData(propertyName = "city", propertyType = "string", index = 2)).toBe("Los Angeles");
					expect(seeder.$generateTestData(propertyName = "state", propertyType = "string", index = 1)).toBe("CA");
					expect(seeder.$generateTestData(propertyName = "province", propertyType = "string", index = 2)).toBe("TX");
					expect(seeder.$generateTestData(propertyName = "zip", propertyType = "string", index = 1)).toBe("10001");
					expect(seeder.$generateTestData(propertyName = "postal", propertyType = "string", index = 2)).toBe("10002");
				});

				it("S10: url / website and password names", () => {
					expect(seeder.$generateTestData(propertyName = "url", propertyType = "string", index = 5)).toBe("https://example5.com");
					expect(seeder.$generateTestData(propertyName = "website", propertyType = "string", index = 5)).toBe("https://example5.com");
					expect(seeder.$generateTestData(propertyName = "password", propertyType = "string", index = 5)).toBe("TestPass5!");
				});

				it("S10: boolean type and active / enabled / published names", () => {
					expect(seeder.$generateTestData(propertyName = "flag", propertyType = "boolean", index = 1)).toBeTrue();
					expect(seeder.$generateTestData(propertyName = "flag", propertyType = "boolean", index = 2)).toBeFalse();
					expect(seeder.$generateTestData(propertyName = "isActive", propertyType = "string", index = 1)).toBeTrue();
					expect(seeder.$generateTestData(propertyName = "enabled", propertyType = "string", index = 2)).toBeFalse();
					// publishedAt matches "published" before the later date-name branch.
					expect(seeder.$generateTestData(propertyName = "publishedAt", propertyType = "string", index = 1)).toBeTrue();
				});

				it("S10: integer / numeric type — age, price, quantity, and default", () => {
					expect(seeder.$generateTestData(propertyName = "age", propertyType = "integer", index = 1)).toBe(21);
					expect(seeder.$generateTestData(propertyName = "price", propertyType = "numeric", index = 1)).toBe(10.99);
					expect(seeder.$generateTestData(propertyName = "cost", propertyType = "integer", index = 2)).toBe(20.99);
					expect(seeder.$generateTestData(propertyName = "amount", propertyType = "integer", index = 3)).toBe(30.99);
					expect(seeder.$generateTestData(propertyName = "quantity", propertyType = "integer", index = 2)).toBe(10);
					expect(seeder.$generateTestData(propertyName = "count", propertyType = "integer", index = 3)).toBe(15);
					expect(seeder.$generateTestData(propertyName = "views", propertyType = "integer", index = 7)).toBe(7);
				});

				it("S10: date type and date / birthday / dob names", () => {
					local.typed = seeder.$generateTestData(propertyName = "foo", propertyType = "date", index = 3);
					expect(IsDate(local.typed)).toBeTrue();
					expect(DateDiff("d", local.typed, Now())).toBe(3);

					local.named = seeder.$generateTestData(propertyName = "startDate", propertyType = "string", index = 2);
					expect(IsDate(local.named)).toBeTrue();
					expect(DateDiff("d", local.named, Now())).toBe(2);

					local.birthday = seeder.$generateTestData(propertyName = "birthday", propertyType = "string", index = 1);
					expect(IsDate(local.birthday)).toBeTrue();
					local.dob = seeder.$generateTestData(propertyName = "dob", propertyType = "datetime", index = 4);
					expect(IsDate(local.dob)).toBeTrue();
					expect(DateDiff("d", local.dob, Now())).toBe(4);
				});

				it("S10: text type and description / content / body / title / status", () => {
					local.lorem = "This is test content 1. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
					expect(seeder.$generateTestData(propertyName = "foo", propertyType = "text", index = 1)).toBe(local.lorem);
					expect(seeder.$generateTestData(propertyName = "description", propertyType = "string", index = 1)).toBe(local.lorem);
					expect(seeder.$generateTestData(propertyName = "content", propertyType = "string", index = 1)).toBe(local.lorem);
					expect(seeder.$generateTestData(propertyName = "body", propertyType = "string", index = 1)).toBe(local.lorem);
					expect(seeder.$generateTestData(propertyName = "title", propertyType = "string", index = 8)).toBe("Test Title 8");
					expect(seeder.$generateTestData(propertyName = "subject", propertyType = "string", index = 8)).toBe("Test Title 8");
					expect(seeder.$generateTestData(propertyName = "status", propertyType = "string", index = 1)).toBe("pending");
					expect(seeder.$generateTestData(propertyName = "status", propertyType = "string", index = 2)).toBe("active");
					expect(seeder.$generateTestData(propertyName = "status", propertyType = "string", index = 5)).toBe("pending");
				});

				it("S10: unmatched names fall through to the default string", () => {
					expect(seeder.$generateTestData(propertyName = "zzz", propertyType = "string", index = 9)).toBe("zzz Test 9");
					expect(seeder.$generateTestData(propertyName = "notes", index = 1)).toBe("notes Test 1");
				});

			});

		});

	}

	public void function $deleteAuthorByFirstName(required string firstName) {
		local.escaped = Replace(arguments.firstName, "'", "''", "all");
		local.record = model("author").findOne(where = "firstName = '#local.escaped#'");
		if (IsObject(local.record)) {
			local.record.delete();
		}
	}

}
