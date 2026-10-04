/**
 * A job enqueued inside a Wheels-managed transaction on a tenant datasource is written to
 * the job store when that transaction commits, and dropped if it rolls back. On the job
 * store's own datasource, or with no transaction open, it is written immediately.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Job enqueue deferred to the commit of a tenant-datasource transaction", function() {

			var dsA = application.wheels.dataSourceName;
			var dsB = "wheelstestdb_sqlite_tenant_b";
			var tenantAvailable = true;
			try {
				QueryExecute("SELECT 1 AS t", [], {datasource = dsB});
			} catch (any e) {
				tenantAvailable = false;
			}
			// Always register the tests: skip() when the tenant datasource is missing, so an
			// absent datasource shows as skipped, never as a silent pass.
			// qc_products is created with SQLite DDL on the job store's datasource too, so the
			// specs need it to be the SQLite test datasource; other legs skip with that reason.
			var tenantState = {
				available = tenantAvailable && CompareNoCase(dsA, "wheelstestdb_sqlite") == 0,
				reason = !tenantAvailable
					? "The wheelstestdb_sqlite_tenant_b datasource is not configured on this engine."
					: "These specs need the SQLite test datasource as the job store; this leg uses #dsA#."
			};

			beforeEach(function() {
				if (!tenantState.available) {
					return;
				}
				for (var ds in [dsA, dsB]) {
					QueryExecute("DROP TABLE IF EXISTS qc_products", [], {datasource = ds});
					QueryExecute("CREATE TABLE qc_products (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(100) NOT NULL)", [], {datasource = ds});
				}
				// the job store exists before any transaction
				new wheels.tests._assets.jobs.ProbeJob().enqueue(data = {}, queue = "deferred_warmup");
				QueryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'deferred_%'", [], {datasource = dsA});
				request.tenantJobResult = {};
			});

			afterEach(function() {
				if (!tenantState.available) {
					return;
				}
				if (IsDefined("request.wheels.tenant")) {
					StructDelete(request.wheels, "tenant");
				}
				QueryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'deferred_%'", [], {datasource = dsA});
				try {
					QueryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'deferred_%'", [], {datasource = dsB});
				} catch (any e) {
				}
				for (var ds in [dsA, dsB]) {
					QueryExecute("DROP TABLE IF EXISTS qc_products", [], {datasource = ds});
				}
			});

			it("writes the job to the job store once the tenant transaction commits", function() {
				if (!tenantState.available) {
					skip(tenantState.reason);
				}
				request.tenantJobQueue = "deferred_commit";
				request.wheels.tenant = {id = "tenant_b", dataSource = dsB, config = {}, "$locked" = true};
				g = application.wo;
				// the core test runner sets transactionMode = "none", so ask for the commit transaction
				g.model("TenantJobProduct").create(name = "committed", transaction = "commit");
				StructDelete(request.wheels, "tenant");

				expect(request.tenantJobResult.deferred ?: false).toBeTrue("the enqueue inside the transaction should be deferred");
				expect($jobCount(dsA, "deferred_commit")).toBe(1);
				expect($jobCount(dsB, "deferred_commit")).toBe(0);
				expect(QueryExecute("SELECT COUNT(*) AS n FROM qc_products", [], {datasource = dsB}).n).toBe(1);
			});

			it("drops the job when the tenant transaction rolls back", function() {
				if (!tenantState.available) {
					skip(tenantState.reason);
				}
				request.tenantJobQueue = "deferred_rollback";
				request.wheels.tenant = {id = "tenant_b", dataSource = dsB, config = {}, "$locked" = true};
				g = application.wo;
				g.model("TenantJobProduct").create(name = "rolled back", transaction = "rollback");
				StructDelete(request.wheels, "tenant");

				expect($jobCount(dsA, "deferred_rollback")).toBe(0);
				expect($jobCount(dsB, "deferred_rollback")).toBe(0);
				expect(QueryExecute("SELECT COUNT(*) AS n FROM qc_products", [], {datasource = dsB}).n).toBe(0);
			});

			it("writes immediately on the job store's own datasource", function() {
				if (!tenantState.available) {
					skip(tenantState.reason);
				}
				request.tenantJobQueue = "deferred_same";
				g = application.wo;
				g.model("TenantJobProduct").create(name = "same datasource", transaction = "commit");

				expect(request.tenantJobResult.persisted).toBeTrue();
				expect(request.tenantJobResult.deferred ?: false).toBeFalse();
				expect($jobCount(dsA, "deferred_same")).toBe(1);
			});

			it("writes immediately under a tenant when no transaction is open", function() {
				if (!tenantState.available) {
					skip(tenantState.reason);
				}
				request.tenantJobQueue = "deferred_none";
				request.wheels.tenant = {id = "tenant_b", dataSource = dsB, config = {}, "$locked" = true};
				g = application.wo;
				g.model("TenantJobProduct").create(name = "no transaction", transaction = "none");
				StructDelete(request.wheels, "tenant");

				expect(request.tenantJobResult.persisted).toBeTrue();
				expect($jobCount(dsA, "deferred_none")).toBe(1);
			});

		});

	}

	public numeric function $jobCount(required string datasource, required string queue) {
		try {
			return QueryExecute("SELECT COUNT(*) AS n FROM wheels_jobs WHERE queue = :queue", {queue = arguments.queue}, {datasource = arguments.datasource}).n;
		} catch (any e) {
			// no job table in that database
			return 0;
		}
	}

}
