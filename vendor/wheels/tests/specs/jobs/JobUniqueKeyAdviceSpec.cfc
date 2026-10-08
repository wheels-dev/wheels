/**
 * What the framework tells an operator when the uniqueKey upgrade can't finish: which step
 * failed, and the manual fix for their database. On SQL Server below compatibility level 100
 * the filtered unique index can't be built, so the advice names the level and the real options
 * instead of repeating a statement that fails the same way. The compatibility level is stubbed:
 * the local SQL Server image can't run a database below level 100.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("uniqueKey upgrade advice", function() {

			it("names the compatibility level and the real options on an old SQL Server", function() {
				var job = $jobOn("sqlserver", 90);
				var advice = job.$uniqueKeyManualFix();
				expect(advice).toInclude("compatibility level 90");
				expect(advice).toInclude("COMPATIBILITY_LEVEL = 100");
				expect(advice).toInclude("CREATE UNIQUE INDEX idx_wjobs_unique_key ON wheels_jobs (uniqueKey)");
				expect(advice).notToInclude("WHERE uniqueKey IS NOT NULL", "a filtered index fails the same way below level 100");
			});

			it("gives the filtered index on a current SQL Server", function() {
				var advice = $jobOn("sqlserver", 150).$uniqueKeyManualFix();
				expect(advice).toInclude("WHERE uniqueKey IS NOT NULL");
				expect(advice).notToInclude("compatibility level");
			});

			it("gives the plain index on other databases", function() {
				var advice = $jobOn("postgresql", 0).$uniqueKeyManualFix();
				expect(advice).toInclude("CREATE UNIQUE INDEX idx_wjobs_unique_key ON wheels_jobs (uniqueKey)");
				expect(advice).notToInclude("WHERE uniqueKey IS NOT NULL");
			});

			it("reads the real compatibility level on SQL Server", function() {
				var job = new wheels.Job();
				if (job.$detectDatabaseType() != "sqlserver") {
					return;
				}
				// The test image runs at a current level (100+), so the advice is the filtered index.
				expect(job.$sqlServerCompatibilityLevel()).toBeGTE(100);
				expect(job.$uniqueKeyManualFix()).toInclude("WHERE uniqueKey IS NOT NULL");
			});

			it("names the step that failed", function() {
				var job = new wheels.Job();
				prepareMock(job);
				job.$("$jobTableHasUniqueKeyIndex", false);
				job.$("$uniqueKeyIndexSql", "CREATE UNIQUE INDEX idx_wjobs_unique_key_bogus ON no_such_table_for_spec (nothing)");
				job.$ensureJobTable();
				var progress = {step = ""};
				var state = {threw = false};
				try {
					job.$upgradeUniqueKeyColumn(progress = progress);
				} catch (any e) {
					state.threw = true;
				}
				expect(state.threw).toBeTrue();
				expect(progress.step).toBe("index");
				var text = job.$uniqueKeyUpgradeFailureText(reason = "boom", step = "index");
				expect(text).toInclude("build the unique index idx_wjobs_unique_key");
				expect(text).toInclude("boom");
				expect($jobOn("postgresql", 0).$uniqueKeyUpgradeFailureText(reason = "boom", step = "column")).toInclude("add the wheels_jobs.uniqueKey column");
			});

		});
	}

	private any function $jobOn(required string dbType, required numeric compatibilityLevel) {
		var job = new wheels.Job();
		prepareMock(job);
		job.$("$detectDatabaseType", arguments.dbType);
		job.$("$sqlServerCompatibilityLevel", arguments.compatibilityLevel);
		return job;
	}

}
