/**
 * Database Seeder — runs convention-based seed files for repeatable, idempotent data seeding.
 *
 * Convention:
 *   app/db/seeds.cfm         — Main seed file (always runs first)
 *   app/db/seeds/<env>.cfm   — Environment-specific seeds (runs after main)
 *
 * Inside seed files, use model() for referential integrity and seedOnce() for idempotency:
 *   seedOnce(modelName="Role", uniqueProperties="name", properties={name: "admin", level: 1});
 *
 * [section: Seeder]
 * [category: Database Functions]
 */
component output="false" extends="wheels.Global" {

	/**
	 * Configure and return seeder object.
	 */
	public component function init(
		string seedPath = "/app/db/"
	) {
		// Store both the CFML mapping path (for include) and expanded filesystem path (for FileExists)
		this.seedMappingPath = arguments.seedPath;
		this.seedPath = ExpandPath(arguments.seedPath);
		this.results = [];
		this.totalCreated = 0;
		this.totalSkipped = 0;
		this.totalFailed = 0;
		return this;
	}

	/**
	 * Run seed files for the given environment.
	 *
	 * 1. Includes app/db/seeds.cfm (shared seeds) if it exists.
	 * 2. Includes app/db/seeds/<environment>.cfm if it exists.
	 * 3. Wraps execution in a transaction for atomicity: a thrown error OR any
	 *    seedOnce() entry that fails validation rolls back the entire run and
	 *    returns success=false naming the failed entries. Commit-with-report was
	 *    deliberately rejected — seedOnce() is idempotent, so a corrected rerun
	 *    re-applies everything, and a half-applied run must never look identical
	 *    to a fully-applied one (issue #2973).
	 *
	 * @environment The environment to seed for (defaults to current Wheels environment)
	 */
	public struct function runSeeds(string environment = get("environment")) {
		// The environment name is interpolated into an include path below, so restrict it to
		// safe characters (prevents path traversal like "../../../app/somefile").
		if (!ReFind("^[A-Za-z0-9_-]+$", arguments.environment)) {
			Throw(
				type = "Wheels.Seeder.InvalidEnvironment",
				message = "runSeeds(): invalid environment name '#arguments.environment#'. Environment names may only contain letters, numbers, underscores and hyphens."
			);
		}

		this.results = [];
		this.totalCreated = 0;
		this.totalSkipped = 0;
		this.totalFailed = 0;

		local.mainSeedFile = this.seedPath & "seeds.cfm";
		local.envSeedFile = this.seedPath & "seeds/" & arguments.environment & ".cfm";
		local.hasMain = FileExists(local.mainSeedFile);
		local.hasEnv = FileExists(local.envSeedFile);

		if (!local.hasMain && !local.hasEnv) {
			return {
				success = false,
				message = "No seed files found. Create app/db/seeds.cfm to get started.",
				results = [],
				totalCreated = 0,
				totalSkipped = 0,
				totalFailed = 0
			};
		}

		transaction action="begin" {
			try {
				// Make seedOnce() available inside included seed files
				request.$wheelsSeeder = this;

				if (local.hasMain) {
					include "#this.seedMappingPath#seeds.cfm";
				}

				if (local.hasEnv) {
					include "#this.seedMappingPath#seeds/#arguments.environment#.cfm";
				}

				// Entries that failed validation must not commit silently: roll
				// the whole run back and report them (see docblock for why
				// rollback was chosen over commit-with-report).
				if (this.totalFailed > 0) {
					transaction action="rollback";
					return {
						success = false,
						message = "Seeding failed: #this.totalFailed# #this.totalFailed == 1 ? 'entry' : 'entries'# failed validation (#$failedEntriesSummary()#). All changes were rolled back.",
						environment = arguments.environment,
						results = this.results,
						totalCreated = this.totalCreated,
						totalSkipped = this.totalSkipped,
						totalFailed = this.totalFailed
					};
				}

				transaction action="commit";
			} catch (any e) {
				transaction action="rollback";
				return {
					success = false,
					message = "Seed failed: " & e.message,
					detail = e.detail,
					results = this.results,
					totalCreated = this.totalCreated,
					totalSkipped = this.totalSkipped,
					totalFailed = this.totalFailed
				};
			}
		}

		return {
			success = true,
			message = "Seeding complete. Created #this.totalCreated# records, skipped #this.totalSkipped# existing.",
			environment = arguments.environment,
			results = this.results,
			totalCreated = this.totalCreated,
			totalSkipped = this.totalSkipped,
			totalFailed = 0
		};
	}

	/**
	 * Check whether convention seed files exist.
	 */
	public boolean function hasSeedFiles() {
		local.mainSeedFile = this.seedPath & "seeds.cfm";
		local.seedDir = this.seedPath & "seeds";
		if (FileExists(local.mainSeedFile)) {
			return true;
		}
		if (DirectoryExists(local.seedDir)) {
			local.files = DirectoryList(local.seedDir, false, "name", "*.cfm");
			return ArrayLen(local.files) > 0;
		}
		return false;
	}

	/**
	 * Idempotent seed helper — creates a record only if a matching one doesn't already exist.
	 *
	 * @modelName  The model name (e.g., "Role", "User")
	 * @uniqueProperties  Comma-delimited list of property names that define uniqueness (used for the WHERE check)
	 * @properties  Struct of ALL properties for the new record (must include the unique properties)
	 */
	public struct function seedOnce(
		required string modelName,
		required string uniqueProperties,
		required struct properties
	) {
		local.modelObj = model(arguments.modelName);

		// Build WHERE clause from unique properties
		local.whereParts = [];
		local.uniqueList = ListToArray(arguments.uniqueProperties);
		for (local.prop in local.uniqueList) {
			local.prop = Trim(local.prop);
			if (!StructKeyExists(arguments.properties, local.prop)) {
				Throw(
					type = "Wheels.Seeder.MissingProperty",
					message = "seedOnce(): uniqueProperties lists '#local.prop#' but it was not found in the properties struct."
				);
			}
			local.val = arguments.properties[local.prop];
			if (!IsSimpleValue(local.val)) {
				Throw(
					type = "Wheels.Seeder.InvalidUniqueValue",
					message = "seedOnce(): the value of unique property '#local.prop#' must be a simple value (string, number, date or boolean) so it can be used in the uniqueness check."
				);
			}
			ArrayAppend(local.whereParts, "#local.prop# = '#Replace(local.val, "'", "''", "all")#'");
		}
		local.whereClause = ArrayToList(local.whereParts, " AND ");

		// An empty WHERE clause would make findOne() match an arbitrary row and silently skip the seed
		if (!Len(local.whereClause)) {
			Throw(
				type = "Wheels.Seeder.EmptyUniqueProperties",
				message = "seedOnce(): uniqueProperties did not produce any uniqueness conditions. Pass at least one property name."
			);
		}

		// Check for existing record
		local.existing = local.modelObj.findOne(where = local.whereClause);

		if (IsObject(local.existing)) {
			this.totalSkipped++;
			local.result = {
				model = arguments.modelName,
				action = "skipped",
				uniqueProperties = arguments.uniqueProperties
			};
			ArrayAppend(this.results, local.result);
			return local.result;
		}

		// Create the record
		local.newRecord = local.modelObj.new(arguments.properties);
		local.saved = local.newRecord.save();

		if (local.saved) {
			this.totalCreated++;
			local.result = {
				model = arguments.modelName,
				action = "created",
				key = local.newRecord.key()
			};
		} else {
			this.totalFailed++;
			local.result = {
				model = arguments.modelName,
				action = "failed",
				errors = local.newRecord.allErrors()
			};
		}

		ArrayAppend(this.results, local.result);
		return local.result;
	}

	/**
	 * Generate fake records for one or more models — the legacy
	 * `wheels seed --generate` path. Unlike convention seeding this does not
	 * use seed files; it introspects each model's persisted properties and
	 * inserts `count` rows of plausible test data per model.
	 *
	 * Honesty contract (issue #3082): a model that throws, or whose generated
	 * rows do not all save, is recorded as a failed entry AND forces overall
	 * success=false. The previous CLI-view implementation iterated the
	 * $classData().properties STRUCT as if it were an array of property structs
	 * — so `prop.name` threw "there is no property with name [NAME] found in
	 * [string]" — created zero rows, yet still returned success=true and the
	 * CLI printed "Seeding completed." with exit 0.
	 *
	 * @models Comma-delimited list of model names. When blank, every *.cfc under
	 *         /app/models (excluding _-prefixed files and the framework's
	 *         parent Model.cfc base class) is used.
	 * @count  Number of rows to generate per model.
	 */
	public struct function generateSeeds(string models = "", numeric count = 10) {
		var result = {
			success = false,
			mode = "generate",
			seeded = [],
			totalCreated = 0,
			// Generate mode never skips rows, but the CLI bridge contract
			// requires the key: Module.cfc::runSeed() prints
			// `#result.totalSkipped# skipped` whenever totalCreated exists.
			totalSkipped = 0,
			totalFailed = 0,
			message = ""
		};

		var modelList = $resolveGenerateModels(arguments.models);

		if (!ArrayLen(modelList)) {
			result.message = "No models found to generate seed data for. Pass models=... or add models under /app/models.";
			return result;
		}

		for (var modelName in modelList) {
			try {
				var modelInstance = model(modelName);
				// $classData().properties is a STRUCT keyed by property name —
				// each value is the property's metadata struct. Iterate the keys.
				var properties = modelInstance.$classData().properties;
				var seededCount = 0;

				for (var i = 1; i <= arguments.count; i++) {
					var record = {};
					for (var propName in properties) {
						if (propName != "id" && !ListFindNoCase("createdAt,updatedAt,deletedAt", propName)) {
							var propType = StructKeyExists(properties[propName], "type") ? properties[propName].type : "string";
							record[propName] = $generateTestData(propName, propType, i);
						}
					}
					var newRecord = modelInstance.new(record);
					if (newRecord.save()) {
						seededCount++;
					}
				}

				var entrySuccess = (seededCount == arguments.count);
				ArrayAppend(result.seeded, {
					model = modelName,
					count = seededCount,
					success = entrySuccess
				});
				result.totalCreated += seededCount;
				if (!entrySuccess) {
					result.totalFailed++;
				}
			} catch (any modelError) {
				ArrayAppend(result.seeded, {
					model = modelName,
					count = 0,
					success = false,
					error = modelError.message
				});
				result.totalFailed++;
			}
		}

		result.success = (result.totalFailed == 0 && result.totalCreated > 0);
		if (result.success) {
			result.message = "Database seeding completed. Created #result.totalCreated# records across #ArrayLen(result.seeded)# #ArrayLen(result.seeded) == 1 ? 'model' : 'models'#.";
		} else {
			result.message = "Database seeding failed. Created #result.totalCreated# records; #result.totalFailed# of #ArrayLen(result.seeded)# #result.totalFailed == 1 ? 'model' : 'models'# failed (#$failedGenerateSummary(result.seeded)#).";
		}
		return result;
	}

	/**
	 * Internal function. Resolves the model list for generateSeeds(): an
	 * explicit comma-delimited list when provided (blank entries trimmed away),
	 * otherwise every *.cfc model file under /app/models except _-prefixed
	 * files and the framework's parent Model.cfc base class.
	 */
	public array function $resolveGenerateModels(string models = "") {
		var list = [];
		if (Len(Trim(arguments.models))) {
			for (var name in ListToArray(arguments.models)) {
				if (Len(Trim(name))) {
					ArrayAppend(list, Trim(name));
				}
			}
			return list;
		}
		var modelPath = ExpandPath("/app/models");
		if (DirectoryExists(modelPath)) {
			var modelFiles = DirectoryList(modelPath, false, "name", "*.cfc");
			for (var file in modelFiles) {
				// Skip the framework's parent Model.cfc — every scaffolded app
				// ships it as the base class for its models, it has no backing
				// table, and model("Model") throws Wheels.TableNotFound. Same
				// exclusion as the CLI's model enumeration (Analysis.cfc and
				// Module.cfc both skip it).
				if (Left(file, 1) != "_" && file != "Model.cfc") {
					ArrayAppend(list, ListFirst(file, "."));
				}
			}
		}
		return list;
	}

	/**
	 * Internal function. Builds a "model: reason" list for every failed entry
	 * recorded by generateSeeds(), used in its failure message.
	 */
	public string function $failedGenerateSummary(required array seeded) {
		var parts = [];
		for (var entry in arguments.seeded) {
			if (!entry.success) {
				var reason = StructKeyExists(entry, "error") ? entry.error : "only #entry.count# of the requested rows saved";
				ArrayAppend(parts, "#entry.model#: #reason#");
			}
		}
		return ArrayToList(parts, "; ");
	}

	/**
	 * Internal function. Produces a plausible fake value for a property based on
	 * its name and type — used by generateSeeds().
	 */
	public any function $generateTestData(required string propertyName, string propertyType = "string", numeric index = 1) {
		local.name = LCase(arguments.propertyName);

		// Email fields
		if (FindNoCase("email", local.name)) {
			return "test#arguments.index#@example.com";
		}

		// Name fields
		if (FindNoCase("firstname", local.name) || local.name == "fname") {
			local.firstNames = ["John", "Jane", "Bob", "Alice", "Charlie", "Diana", "Edward", "Fiona", "George", "Helen"];
			return local.firstNames[(arguments.index - 1) mod ArrayLen(local.firstNames) + 1];
		}

		if (FindNoCase("lastname", local.name) || local.name == "lname") {
			local.lastNames = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez"];
			return local.lastNames[(arguments.index - 1) mod ArrayLen(local.lastNames) + 1];
		}

		if (local.name == "name" || FindNoCase("username", local.name)) {
			return "TestUser#arguments.index#";
		}

		// Phone fields
		if (FindNoCase("phone", local.name) || FindNoCase("mobile", local.name)) {
			return "555-#NumberFormat(1000 + arguments.index, '0000')#";
		}

		// Address fields
		if (FindNoCase("address", local.name) || FindNoCase("street", local.name)) {
			return "#arguments.index# Test Street";
		}

		if (FindNoCase("city", local.name)) {
			local.cities = ["New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia", "San Antonio", "San Diego"];
			return local.cities[(arguments.index - 1) mod ArrayLen(local.cities) + 1];
		}

		if (FindNoCase("state", local.name) || FindNoCase("province", local.name)) {
			local.states = ["CA", "TX", "FL", "NY", "PA", "IL", "OH", "GA"];
			return local.states[(arguments.index - 1) mod ArrayLen(local.states) + 1];
		}

		if (FindNoCase("zip", local.name) || FindNoCase("postal", local.name)) {
			return NumberFormat(10000 + arguments.index, "00000");
		}

		// URL fields
		if (FindNoCase("url", local.name) || FindNoCase("website", local.name)) {
			return "https://example#arguments.index#.com";
		}

		// Password fields
		if (FindNoCase("password", local.name)) {
			return "TestPass#arguments.index#!";
		}

		// Boolean fields
		if (arguments.propertyType == "boolean" || FindNoCase("active", local.name) || FindNoCase("enabled", local.name) || FindNoCase("published", local.name)) {
			return (arguments.index mod 2) == 1;
		}

		// Numeric fields
		if (arguments.propertyType == "integer" || arguments.propertyType == "numeric") {
			if (FindNoCase("age", local.name)) {
				return 20 + (arguments.index mod 50);
			}
			if (FindNoCase("price", local.name) || FindNoCase("cost", local.name) || FindNoCase("amount", local.name)) {
				return (arguments.index * 10) + 0.99;
			}
			if (FindNoCase("quantity", local.name) || FindNoCase("count", local.name)) {
				return arguments.index * 5;
			}
			return arguments.index;
		}

		// Date fields
		if (arguments.propertyType == "date" || arguments.propertyType == "datetime" || FindNoCase("date", local.name) || FindNoCase("birthday", local.name) || FindNoCase("dob", local.name)) {
			return DateAdd("d", -arguments.index, Now());
		}

		// Text/description fields
		if (arguments.propertyType == "text" || FindNoCase("description", local.name) || FindNoCase("content", local.name) || FindNoCase("body", local.name)) {
			return "This is test content #arguments.index#. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
		}

		// Title fields
		if (FindNoCase("title", local.name) || FindNoCase("subject", local.name)) {
			return "Test Title #arguments.index#";
		}

		// Status fields
		if (FindNoCase("status", local.name)) {
			local.statuses = ["pending", "active", "completed", "cancelled"];
			return local.statuses[(arguments.index - 1) mod ArrayLen(local.statuses) + 1];
		}

		// Default string value
		return "#arguments.propertyName# Test #arguments.index#";
	}

	/**
	 * Internal function. Builds a "model: first error message" list for every
	 * failed entry recorded in this run, used in the runSeeds() failure message.
	 */
	public string function $failedEntriesSummary() {
		local.parts = [];
		for (local.entry in this.results) {
			if (local.entry.action == "failed") {
				local.msg = ArrayLen(local.entry.errors) ? local.entry.errors[1].message : "save failed";
				ArrayAppend(local.parts, "#local.entry.model#: #local.msg#");
			}
		}
		return ArrayToList(local.parts, "; ");
	}

}
