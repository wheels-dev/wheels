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
	 * 3. Wraps execution in a transaction for atomicity.
	 *
	 * Partial-failure policy: if any `seedOnce()` call records `action="failed"`
	 * (validation failure on save), the wrapping transaction is rolled back —
	 * successful entries from earlier in the same run are NOT persisted. The
	 * return struct carries `success=false`, names the failing models in
	 * `message`, and surfaces the per-entry errors in `results`. This makes
	 * `wheels seed` exit non-zero so half-applied seeds can't silently land in
	 * CI or in shared dev environments. seedOnce() is idempotent, so the
	 * caller can fix the offending entry and re-run safely.
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

				// Partial-failure path: any seedOnce() that recorded action="failed"
				// invalidates the whole run. Roll back so we don't commit a
				// half-applied seed; surface the failed models in the message so
				// the CLI and CI can name them.
				if (this.totalFailed > 0) {
					transaction action="rollback";
					local.failedModels = [];
					for (local.r in this.results) {
						if (StructKeyExists(local.r, "action") && local.r.action == "failed") {
							ArrayAppend(local.failedModels, local.r.model);
						}
					}
					local.entryWord = (this.totalFailed == 1) ? "entry" : "entries";
					return {
						success = false,
						message = "Seeding failed: #this.totalFailed# #local.entryWord# failed validation (#ArrayToList(local.failedModels, ", ")#). Transaction rolled back; no records persisted.",
						environment = arguments.environment,
						results = this.results,
						totalCreated = 0,
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
			totalFailed = this.totalFailed
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

}
