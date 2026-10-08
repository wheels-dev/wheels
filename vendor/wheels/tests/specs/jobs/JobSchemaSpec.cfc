/**
 * The job schema is defined once (wheels.JobSchema). Auto-create builds wheels_jobs from it, and
 * `wheels jobs install` writes a migration from it that builds the same table, or tops up one
 * auto-create already built. With jobsAutoCreateTables = false nothing is created or altered at
 * runtime. These specs drop and rebuild wheels_jobs, so each ends by restoring the auto-created
 * layout (a warm PostgreSQL connection rejects plans prepared against another layout).
 */
component extends="wheels.WheelsTest" {

	function afterAll() {
		$removeGeneratedMigration();
		try {
			queryExecute(
				"DELETE FROM #application.wheels.migratorTableName# WHERE version = :version",
				{version = {value = $installVersion(), cfsqltype = "cf_sql_varchar"}},
				{datasource = application.wheels.dataSourceName}
			);
		} catch (any e) {
		}
	}

	function run() {

		describe("wheels.JobSchema", function() {

			afterEach(function() {
				application.wheels.jobsAutoCreateTables = true;
				StructDelete(application.wheels, "$jobsSchemaMissingLogged");
				$rebuildAutoCreated();
			});

			it("is what auto-create builds: every table, column and index", function() {
				$rebuildAutoCreated();
				var schema = new wheels.JobSchema();
				for (var tableDef in schema.tables()) {
					expect(schema.hasTable(tableDef.name)).toBeTrue(tableDef.name);
					for (var column in tableDef.columns) {
						expect(schema.hasColumn(tableDef.name, column.name)).toBeTrue(tableDef.name & "." & column.name);
					}
					for (var index in tableDef.indexes) {
						expect(schema.hasIndex(tableDef.name, index.name)).toBeTrue(index.name);
					}
				}
				expect(schema.hasTable("wheels_jobs")).toBeTrue();
				expect(schema.hasTable("wheels_no_such_table")).toBeFalse();
				expect(schema.hasColumn("wheels_jobs", "noSuchColumn")).toBeFalse();
			});

			it("writes an install migration that builds the same tables as auto-create", function() {
				$rebuildAutoCreated();
				var schema = new wheels.JobSchema();
				var autoCreated = $snapshot(schema, "catalogColumns");

				$dropAllJobTables();
				var migration = $generatedMigration();
				migration.up();

				expect($snapshot(schema, "catalogColumns")).toBe(autoCreated, "same tables, columns and nullability");
				for (var index in schema.tableDef("wheels_jobs").indexes) {
					expect(schema.hasIndex("wheels_jobs", index.name)).toBeTrue(index.name);
				}
				// It works as a jobs table: a keyed enqueue de-duplicates.
				$clearUniqueKeyMemos();
				var job = new wheels.tests._assets.jobs.ProcessOrdersJob();
				var first = job.enqueue(queue = "test_schema_install", uniqueKey = "schema:1");
				var second = job.enqueue(queue = "test_schema_install", uniqueKey = "schema:1");
				expect(second.duplicate).toBeTrue();
				expect(second.id).toBe(first.id);
			});

			it("adopts a table auto-create built earlier, adding only what it lacks, and runs again as a no-op", function() {
				$createLegacyJobTable();
				var legacyId = CreateUUID();
				$insertLegacyRow(legacyId);
				var schema = new wheels.JobSchema();
				expect(schema.hasColumn("wheels_jobs", "uniqueKey")).toBeFalse();

				var migration = $generatedMigration();
				migration.up();
				for (var tableDef in schema.tables()) {
					for (var column in tableDef.columns) {
						expect(schema.hasColumn(tableDef.name, column.name)).toBeTrue(tableDef.name & "." & column.name);
					}
				}
				expect(schema.hasIndex("wheels_jobs", "idx_wjobs_unique_key")).toBeTrue();
				var row = queryExecute(
					"SELECT uniqueKey FROM wheels_jobs WHERE id = :id",
					{id = {value = legacyId, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(row.uniqueKey).toBe(legacyId, "existing rows get their id as their key, as the automatic upgrade does");

				migration.up();
				expect(schema.hasColumn("wheels_jobs", "uniqueKey")).toBeTrue();
			});

			it("runs up, down and up again through the migrator, building auto-create's column types", function() {
				$rebuildAutoCreated();
				var schema = new wheels.JobSchema();
				var autoFamilies = $snapshot(schema, "catalogColumnFamilies");
				var autoColumns = $snapshot(schema, "catalogColumns");
				expect(autoFamilies.wheels_jobs.id).toBe(schema.databaseType() == "sqlite" ? "text" : "string");
				expect(autoFamilies.wheels_jobs.priority).toBe("integer");
				expect(autoFamilies.wheels_jobs.runat).toBe("datetime");
				expect(autoFamilies.wheels_job_locks.expiresat).toBe("integer");

				$dropAllJobTables();
				var migrator = $installMigrator();
				var output = migrator.migrateTo($installVersion());
				expect(schema.hasTable("wheels_jobs")).toBeTrue(output);
				expect($snapshot(schema, "catalogColumnFamilies")).toBe(autoFamilies, "same type family for every column");
				expect($snapshot(schema, "catalogColumns")).toBe(autoColumns, "same nullability");
				if (schema.databaseType() == "sqlserver") {
					// Type families can't tell VARCHAR from NVARCHAR; the result column must be NVARCHAR.
					var resultType = queryExecute(
						"SELECT DATA_TYPE AS dt FROM INFORMATION_SCHEMA.COLUMNS WHERE LOWER(TABLE_NAME) = 'wheels_jobs' AND LOWER(COLUMN_NAME) = 'result'",
						{},
						{datasource = application.wheels.dataSourceName}
					);
					expect(LCase(resultType.dt)).toBe("nvarchar");
				}

				output = migrator.migrateTo("0");
				for (var tableDef in schema.tables()) {
					expect(schema.hasTable(tableDef.name)).toBeFalse("down() drops " & tableDef.name & ": " & output);
				}

				output = migrator.migrateTo($installVersion());
				expect(schema.hasTable("wheels_jobs")).toBeTrue(output);
				expect($snapshot(schema, "catalogColumnFamilies")).toBe(autoFamilies);
				for (var index in schema.tableDef("wheels_jobs").indexes) {
					expect(schema.hasIndex("wheels_jobs", index.name)).toBeTrue(index.name);
				}
				migrator.migrateTo("0");
			});

			it("with jobsAutoCreateTables = false, creates nothing and says how to install the schema", function() {
				$dropJobTable();
				application.wheels.jobsAutoCreateTables = false;
				var ensured = {type = "", message = ""};
				try {
					new wheels.Job().$ensureJobTable();
				} catch (any e) {
					ensured.type = e.type;
					ensured.message = e.message;
				}
				expect(ensured.type).toBe("Wheels.Job.SchemaMissing");
				expect(ensured.message).toInclude("wheels jobs install");
				expect(new wheels.JobSchema().hasTable("wheels_jobs")).toBeFalse();

				var enqueued = {type = ""};
				try {
					new wheels.tests._assets.jobs.ProcessOrdersJob().enqueue(queue = "test_schema_off");
				} catch (any e) {
					enqueued.type = e.type;
				}
				expect(enqueued.type).toBe("Wheels.Job.SchemaMissing", "enqueue reports the missing schema, not a generic failure");

				var polled = {type = ""};
				try {
					new wheels.JobWorker().processNext(queues = "test_schema_off");
				} catch (any e) {
					polled.type = e.type;
				}
				expect(polled.type).toBe("Wheels.Job.SchemaMissing", "a worker poll doesn't pass for an empty queue");
				expect(new wheels.JobSchema().hasTable("wheels_jobs")).toBeFalse();
			});

			it("with jobsAutoCreateTables = false, reports a probe failure as itself when the table exists", function() {
				// The catalog says the table is there but the probe fails (here: a datasource that
				// doesn't exist, as for a lost connection): that error surfaces, not a misleading
				// "missing table". Independent of the table's state, so no DROP is involved.
				application.wheels.jobsAutoCreateTables = false;
				var schema = new wheels.JobSchema();
				prepareMock(schema);
				schema.$("hasTable", true);
				var job = new wheels.Job();
				prepareMock(job);
				job.$("$jobSchema", schema);
				job.$property(propertyName = "$datasource", propertyScope = "variables", mock = "wheels_spec_no_such_datasource");
				var probed = {type = "", message = ""};
				try {
					job.$ensureJobTable();
				} catch (any e) {
					probed.type = e.type;
					probed.message = e.message;
				}
				expect(Len(probed.message)).toBeGT(0, "the probe's own error is rethrown");
				expect(probed.type).notToBe("Wheels.Job.SchemaMissing");
				expect(probed.message).notToInclude("jobsAutoCreateTables");
			});

			it("with jobsAutoCreateTables = false, doesn't alter an existing table", function() {
				$createLegacyJobTable();
				application.wheels.jobsAutoCreateTables = false;
				expect(new wheels.Job().$ensureJobTable()).toBeTrue();
				expect(new wheels.JobSchema().hasColumn("wheels_jobs", "uniqueKey")).toBeFalse("no column upgrade at runtime");
			});

			it("builds each database's DDL", function() {
				var schema = new wheels.JobSchema();
				expect(schema.indexSql(tableName = "wheels_jobs", indexName = "idx_wjobs_unique_key", dbType = "sqlserver")).toBe(
					"CREATE UNIQUE INDEX idx_wjobs_unique_key ON wheels_jobs (uniqueKey) WHERE uniqueKey IS NOT NULL"
				);
				expect(schema.indexSql(tableName = "wheels_jobs", indexName = "idx_wjobs_unique_key", dbType = "postgresql")).toBe(
					"CREATE UNIQUE INDEX idx_wjobs_unique_key ON wheels_jobs (uniqueKey)"
				);
				expect(schema.addColumnSql(tableName = "wheels_jobs", columnName = "claimedBy", dbType = "oracle")).toBe("ALTER TABLE wheels_jobs ADD (claimedBy VARCHAR2(128))");
				expect(schema.addColumnSql(tableName = "wheels_jobs", columnName = "claimTimeout", dbType = "sqlserver")).toBe("ALTER TABLE wheels_jobs ADD claimTimeout INT");
				expect(schema.addColumnSql(tableName = "wheels_jobs", columnName = "uniqueKey", dbType = "mysql")).toBe("ALTER TABLE wheels_jobs ADD COLUMN uniqueKey VARCHAR(255)");
				var create = schema.createTableSql(tableName = "wheels_jobs", dbType = "h2");
				expect(create).toInclude("id VARCHAR(36) NOT NULL PRIMARY KEY");
				expect(create).toInclude("queue VARCHAR(100) DEFAULT 'default' NOT NULL");
				expect(create).toInclude("data CLOB");
				expect(create).toInclude("runAt TIMESTAMP");
			});

		});
	}

	/**
	 * Writes the install migration's source to a component under tests/_assets and returns an
	 * instance of it, so the spec runs exactly what `wheels jobs install` would write.
	 */
	private any function $generatedMigration() {
		var dir = ExpandPath("/wheels/tests/_assets/jobs_install");
		if (!DirectoryExists(dir)) {
			DirectoryCreate(dir);
		}
		FileWrite(dir & "/CreateWheelsJobTablesProbe.cfc", new wheels.JobSchema().migrationSource());
		return CreateObject("component", "wheels.tests._assets.jobs_install.CreateWheelsJobTablesProbe").init();
	}

	/**
	 * A Migrator over a directory holding just the install migration, under a version later than
	 * any other spec's, so migrateTo() runs it through the migrator's own transaction and lock.
	 */
	private any function $installMigrator() {
		// One level at a time: Adobe's DirectoryCreate() takes only the path.
		var parent = ExpandPath("/wheels/tests/_assets/jobs_install");
		if (!DirectoryExists(parent)) {
			DirectoryCreate(parent);
		}
		var dir = parent & "/migrations";
		if (!DirectoryExists(dir)) {
			DirectoryCreate(dir);
		}
		FileWrite(dir & "/#$installVersion()#_CreateWheelsJobTables.cfc", new wheels.JobSchema().migrationSource());
		return CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/jobs_install/migrations/",
			sqlPath = "/wheels/tests/_assets/jobs_install/sql/"
		);
	}

	private string function $installVersion() {
		return "20991231000200";
	}

	private void function $removeGeneratedMigration() {
		var dir = ExpandPath("/wheels/tests/_assets/jobs_install");
		if (DirectoryExists(dir)) {
			DirectoryDelete(dir, true);
		}
	}

	/**
	 * Drops wheels_jobs and makes sure it's gone: a DROP that fails (a lock) must fail the spec
	 * with its own error, not leave the table in place for the spec to misread.
	 */
	private void function $dropJobTable() {
		$dropTableOrFail("wheels_jobs");
		$clearUniqueKeyMemos();
	}

	private void function $dropTableOrFail(required string tableName) {
		var outcome = {error = ""};
		var schema = new wheels.JobSchema();
		if (!schema.hasTable(arguments.tableName)) {
			return;
		}
		try {
			queryExecute("DROP TABLE #arguments.tableName#", {}, {datasource = application.wheels.dataSourceName});
		} catch (any e) {
			outcome.error = e.message & " " & e.detail;
		}
		if (schema.hasTable(arguments.tableName)) {
			Throw(type = "Spec.DropFailed", message = "Could not drop #arguments.tableName# for the spec: #outcome.error#");
		}
	}

	/**
	 * Every job table rebuilt by auto-create, in the layout the rest of the suite expects.
	 */
	private void function $rebuildAutoCreated() {
		$dropAllJobTables();
		var job = new wheels.Job();
		job.$ensureJobTable();
		job.$ensureHostsTable();
		new wheels.JobScheduler().$ensureSchedulesTable();
		job.$jobLeaseLock();
		$clearUniqueKeyMemos();
	}

	private void function $dropAllJobTables() {
		for (var tableDef in new wheels.JobSchema().tables()) {
			$dropTableOrFail(tableDef.name);
		}
		$clearUniqueKeyMemos();
	}

	/**
	 * One catalog view of every job table: table name -> schema.catalogColumns() or
	 * schema.catalogColumnFamilies().
	 */
	private struct function $snapshot(required any schema, required string view) {
		var rv = {};
		for (var tableDef in arguments.schema.tables()) {
			if (arguments.view == "catalogColumns") {
				rv[tableDef.name] = arguments.schema.catalogColumns(tableDef.name);
			} else {
				rv[tableDef.name] = arguments.schema.catalogColumnFamilies(tableDef.name);
			}
		}
		return rv;
	}

	private void function $clearUniqueKeyMemos() {
		if (StructKeyExists(application.wheels, "$jobsUniqueKeyIndexVerified")) {
			StructDelete(application.wheels, "$jobsUniqueKeyIndexVerified");
		}
		StructDelete(application.wheels, "$uniqueKeyAlterFailedAt");
	}

	/**
	 * wheels_jobs as an older version auto-created it: no claim-fencing or uniqueKey columns, and
	 * none of the indexes.
	 */
	private void function $createLegacyJobTable() {
		var dbType = new wheels.Job().$detectDatabaseType();
		var types = {varchar = "VARCHAR", text = "TEXT", stamp = "DATETIME"};
		if (dbType == "oracle") {
			types = {varchar = "VARCHAR2", text = "CLOB", stamp = "TIMESTAMP"};
		} else if (dbType == "postgresql") {
			types = {varchar = "VARCHAR", text = "TEXT", stamp = "TIMESTAMP"};
		} else if (dbType == "h2") {
			types = {varchar = "VARCHAR", text = "CLOB", stamp = "TIMESTAMP"};
		}
		$dropJobTable();
		queryExecute(
			"CREATE TABLE wheels_jobs (
				id #types.varchar#(36) NOT NULL PRIMARY KEY,
				jobClass #types.varchar#(255) NOT NULL,
				queue #types.varchar#(100) DEFAULT 'default' NOT NULL,
				data #types.text#,
				priority INT DEFAULT 0 NOT NULL,
				status #types.varchar#(20) DEFAULT 'pending' NOT NULL,
				attempts INT DEFAULT 0 NOT NULL,
				maxRetries INT DEFAULT 3 NOT NULL,
				claimTimeout INT,
				lastError #types.text#,
				runAt #types.stamp#,
				completedAt #types.stamp#,
				failedAt #types.stamp#,
				createdAt #types.stamp#,
				updatedAt #types.stamp#
			)",
			{},
			{datasource = application.wheels.dataSourceName}
		);
	}

	private void function $insertLegacyRow(required string id) {
		queryExecute(
			"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
			VALUES (:id, 'wheels.tests._assets.jobs.ProcessOrdersJob', 'test_schema_legacy', '{}', 0, 'completed', 1, 3, :stamp, :stamp2, :stamp3)",
			{
				id = {value = arguments.id, cfsqltype = "cf_sql_varchar"},
				stamp = {value = Now(), cfsqltype = "cf_sql_timestamp"},
				stamp2 = {value = Now(), cfsqltype = "cf_sql_timestamp"},
				stamp3 = {value = Now(), cfsqltype = "cf_sql_timestamp"}
			},
			{datasource = application.wheels.dataSourceName}
		);
	}

}
