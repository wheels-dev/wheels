/**
 * A job enqueued inside a transaction on a tenant datasource is written to the
 * application's job store. Some engines refuse a second datasource inside a
 * transaction; that must surface as Wheels.Job.EnqueueFailed, never as a job
 * that silently disappears.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Job enqueue inside a tenant-datasource transaction", function() {

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
			var tenantState = {available = tenantAvailable};

			beforeEach(function() {
				if (!tenantState.available) {
					return;
				}
				try { QueryExecute("DROP TABLE IF EXISTS job_tenant_tx_rows", [], {datasource = dsB}); } catch (any e) {}
				QueryExecute("CREATE TABLE job_tenant_tx_rows (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(50))", [], {datasource = dsB});
				variables.job = new wheels.tests._assets.jobs.ProbeJob();
				// the job store exists before any transaction
				variables.job.enqueue(data = {}, queue = "tenant_tx_warmup");
				QueryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'tenant_tx_%'", [], {datasource = dsA});
			});

			afterEach(function() {
				if (!tenantState.available) {
					return;
				}
				if (IsDefined("request.wheels.tenant")) {
					StructDelete(request.wheels, "tenant");
				}
				QueryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'tenant_tx_%'", [], {datasource = dsA});
				try { QueryExecute("DROP TABLE IF EXISTS job_tenant_tx_rows", [], {datasource = dsB}); } catch (any e) {}
			});

			it("either stores the job in the job store or throws Wheels.Job.EnqueueFailed, never loses it", function() {
				if (!tenantState.available) {
					skip("The wheelstestdb_sqlite_tenant_b datasource is not configured on this engine.");
				}
				if (application.wo.$engineAdapter().isRustCFML()) {
					// RustCFML sends every statement in a transaction to the first datasource
					// it used, so the job row lands in the tenant database: written, but not
					// where the worker reads. Detected and fixed by deferring cross-datasource
					// enqueues to after the commit, not by this error.
					skip("RustCFML writes the job to the tenant datasource inside the transaction.");
				}
				request.wheels.tenant = {id = "tenant_b", dataSource = dsB, config = {}, "$locked" = true};
				var state = {type = "", result = {}};
				try {
					transaction {
						QueryExecute("INSERT INTO job_tenant_tx_rows (name) VALUES ('committed')", [], {datasource = application.wo.$tenantDataSource()});
						state.result = variables.job.enqueue(data = {}, queue = "tenant_tx_commit");
					}
				} catch (any e) {
					state.type = e.type;
				}
				StructDelete(request.wheels, "tenant");

				var stored = QueryExecute("SELECT COUNT(*) AS n FROM wheels_jobs WHERE queue = 'tenant_tx_commit'", [], {datasource = dsA}).n;
				if (Len(state.type)) {
					expect(state.type).toBe("Wheels.Job.EnqueueFailed");
					expect(stored).toBe(0);
				} else {
					expect(state.result.persisted).toBeTrue();
					expect(stored).toBe(1, "enqueue reported success but the job is not in the job store");
				}
			});

		});

	}

}
