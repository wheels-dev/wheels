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
	}

	function run() {

		describe("wheels.JobSchema", function() {

			afterEach(function() {
				StructDelete(application.wheels, "jobsAutoCreateTables");
				$rebuildAutoCreated();
			});

			it("is what auto-create builds: every column and index", function() {
				$rebuildAutoCreated();
				var schema = new wheels.JobSchema();
				for (var column in schema.tableDef("wheels_jobs").columns) {
					expect(schema.hasColumn("wheels_jobs", column.name)).toBeTrue(column.name);
				}
				for (var index in schema.tableDef("wheels_jobs").indexes) {
					expect(schema.hasIndex("wheels_jobs", index.name)).toBeTrue(index.name);
				}
				expect(schema.hasTable("wheels_jobs")).toBeTrue();
				expect(schema.hasTable("wheels_no_such_table")).toBeFalse();
				expect(schema.hasColumn("wheels_jobs", "noSuchColumn")).toBeFalse();
			});

			it("writes an install migration that builds the same table as auto-create", function() {
				$rebuildAutoCreated();
				var schema = new wheels.JobSchema();
				var autoCreated = schema.catalogColumns("wheels_jobs");

				$dropJobTable();
				var migration = $generatedMigration();
				migration.up();

				expect(schema.catalogColumns("wheels_jobs")).toBe(autoCreated, "same columns, same nullability");
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
				for (var column in schema.tableDef("wheels_jobs").columns) {
					expect(schema.hasColumn("wheels_jobs", column.name)).toBeTrue(column.name);
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

			it("creates and alters nothing with jobsAutoCreateTables = false", function() {
				$dropJobTable();
				application.wheels.jobsAutoCreateTables = false;
				var job = new wheels.Job();
				expect(job.$ensureJobTable()).toBeFalse();
				expect(new wheels.JobSchema().hasTable("wheels_jobs")).toBeFalse();

				StructDelete(application.wheels, "jobsAutoCreateTables");
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

	private void function $removeGeneratedMigration() {
		var dir = ExpandPath("/wheels/tests/_assets/jobs_install");
		if (DirectoryExists(dir)) {
			DirectoryDelete(dir, true);
		}
	}

	private void function $dropJobTable() {
		try {
			queryExecute("DROP TABLE wheels_jobs", {}, {datasource = application.wheels.dataSourceName});
		} catch (any e) {
		}
		$clearUniqueKeyMemos();
	}

	private void function $rebuildAutoCreated() {
		$dropJobTable();
		new wheels.Job().$ensureJobTable();
		$clearUniqueKeyMemos();
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
