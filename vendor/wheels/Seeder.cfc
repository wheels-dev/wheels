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
		return this;
	}

	/**
	 * Run seed files for the given environment.
	 *
	 * 1. Includes app/db/seeds.cfm (shared seeds) if it exists.
	 * 2. Includes app/db/seeds/<environment>.cfm if it exists.
	 * 3. Wraps execution in a transaction for atomicity.
	 *
	 * @environment The environment to seed for (defaults to current Wheels environment)
	 */
	public struct function runSeeds(string environment = get("environment")) {
		this.results = [];
		this.totalCreated = 0;
		this.totalSkipped = 0;

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
				totalSkipped = 0
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

				transaction action="commit";
			} catch (any e) {
				transaction action="rollback";
				return {
					success = false,
					message = "Seed failed: " & e.message,
					detail = e.detail,
					results = this.results,
					totalCreated = this.totalCreated,
					totalSkipped = this.totalSkipped
				};
			}
		}

		return {
			success = true,
			message = "Seeding complete. Created #this.totalCreated# records, skipped #this.totalSkipped# existing.",
			environment = arguments.environment,
			results = this.results,
			totalCreated = this.totalCreated,
			totalSkipped = this.totalSkipped
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
			if (IsSimpleValue(local.val)) {
				ArrayAppend(local.whereParts, "#local.prop# = '#Replace(local.val, "'", "''", "all")#'");
			}
		}
		local.whereClause = ArrayToList(local.whereParts, " AND ");

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
			local.result = {
				model = arguments.modelName,
				action = "failed",
				errors = local.newRecord.allErrors()
			};
		}

		ArrayAppend(this.results, local.result);
		return local.result;
	}

}
