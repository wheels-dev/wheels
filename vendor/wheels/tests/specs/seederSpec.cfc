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

		});

	}

}
