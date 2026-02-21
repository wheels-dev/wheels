/**
 * Migration: Create the _wheels_jobs table for the background job queue system.
 *
 * Run with: wheels dbmigrate latest
 */
component extends="wheels.migrator.Migration" {

	function up() {
		announce("Creating _wheels_jobs table for background job queue");

		t = createTable(name = "_wheels_jobs", id = false);
		t.string(columnNames = "id", limit = 36, null = false);
		t.string(columnNames = "jobClass", limit = 255, null = false);
		t.string(columnNames = "queue", limit = 100, null = false, default = "default");
		t.text(columnNames = "data");
		t.integer(columnNames = "priority", null = false, default = 0);
		t.string(columnNames = "status", limit = 20, null = false, default = "pending");
		t.integer(columnNames = "attempts", null = false, default = 0);
		t.integer(columnNames = "maxRetries", null = false, default = 3);
		t.text(columnNames = "lastError");
		t.datetime(columnNames = "runAt");
		t.datetime(columnNames = "completedAt");
		t.datetime(columnNames = "failedAt");
		t.timestamps();
		t.create();

		// Set primary key
		execute("ALTER TABLE _wheels_jobs ADD PRIMARY KEY (id)");

		// Index for queue processing: pending jobs ordered by priority and scheduled time
		addIndex(table = "_wheels_jobs", columnNames = "status,runAt,priority", indexName = "idx_wheels_jobs_processing");

		// Index for queue filtering
		addIndex(table = "_wheels_jobs", columnNames = "queue,status", indexName = "idx_wheels_jobs_queue");

		// Index for cleanup of completed jobs
		addIndex(table = "_wheels_jobs", columnNames = "status,completedAt", indexName = "idx_wheels_jobs_cleanup");

		announce("_wheels_jobs table created successfully");
	}

	function down() {
		announce("Dropping _wheels_jobs table");
		dropTable("_wheels_jobs");
	}

}
