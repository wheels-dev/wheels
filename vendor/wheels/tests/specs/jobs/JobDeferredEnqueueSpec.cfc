/**
 * A job enqueued inside a Wheels-managed transaction whose writes go to another datasource (a
 * tenant's) is written to the job store when that transaction commits, and dropped if it
 * rolls back. A transaction on the job store's own datasource (including a shared model's
 * under a tenant) is joined, and with no transaction open the job is written immediately.
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
			var tenantState = {available = tenantAvailable};

			beforeEach(function() {
				if (!tenantState.available) {
					return;
				}
				// The job store's datasource may be any database: create the table portably there.
				var migration = CreateObject("component", "wheels.migrator.Migration").init();
				try {
					migration.dropTable("tenant_job_products");
				} catch (any e) {
				}
				var t = migration.createTable(name = "tenant_job_products");
				t.string(columnNames = "name");
				t.create();
				QueryExecute("DROP TABLE IF EXISTS tenant_job_products", [], {datasource = dsB});
				QueryExecute("CREATE TABLE tenant_job_products (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(255))", [], {datasource = dsB});
				// the job store exists before any transaction
				new wheels.tests._assets.jobs.ProbeJob().enqueue(data = {}, queue = "deferred_warmup");
				QueryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'deferred_%'", [], {datasource = dsA});
				request.tenantJobResult = {};
				StructDelete(request, "tenantJobClass");
			});

			afterEach(function() {
				if (!tenantState.available) {
					return;
				}
				if (IsDefined("request.wheels.tenant")) {
					StructDelete(request.wheels, "tenant");
				}
				StructDelete(request, "tenantJobClass");
				QueryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'deferred_%'", [], {datasource = dsA});
				try {
					QueryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'deferred_%'", [], {datasource = dsB});
				} catch (any e) {
				}
				try {
					CreateObject("component", "wheels.migrator.Migration").init().dropTable("tenant_job_products");
				} catch (any e) {
				}
				QueryExecute("DROP TABLE IF EXISTS tenant_job_products", [], {datasource = dsB});
			});

			// The core test runner sets transactionMode = "none", so specs ask for the mode.

			it("writes the job to the job store once the tenant transaction commits", function() {
				if (!tenantState.available) {
					skip("The wheelstestdb_sqlite_tenant_b datasource is not configured on this engine.");
				}
				request.tenantJobQueue = "deferred_commit";
				$activateTenantB(dsB);
				application.wo.model("TenantJobProduct").create(name = "committed", transaction = "commit");
				StructDelete(request.wheels, "tenant");

				expect(request.tenantJobResult.deferred ?: false).toBeTrue("the enqueue inside the transaction should be deferred");
				expect($jobCount(dsA, "deferred_commit")).toBe(1);
				expect($jobCount(dsB, "deferred_commit")).toBe(0);
				expect($tenantRows(dsB)).toBe(1);
			});

			it("drops the job when the tenant transaction rolls back", function() {
				if (!tenantState.available) {
					skip("The wheelstestdb_sqlite_tenant_b datasource is not configured on this engine.");
				}
				request.tenantJobQueue = "deferred_rollback";
				$activateTenantB(dsB);
				application.wo.model("TenantJobProduct").create(name = "rolled back", transaction = "rollback");
				StructDelete(request.wheels, "tenant");

				expect($jobCount(dsA, "deferred_rollback")).toBe(0);
				expect($jobCount(dsB, "deferred_rollback")).toBe(0);
				expect($tenantRows(dsB)).toBe(0);
			});

			it("drops only the job of a savepoint unit that rolls back", function() {
				if (!tenantState.available) {
					skip("The wheelstestdb_sqlite_tenant_b datasource is not configured on this engine.");
				}
				$activateTenantB(dsB);
				application.wo.model("TenantJobProduct").invokeWithTransaction(method = "txnKeepThenFailingUnit", transaction = "commit");
				StructDelete(request.wheels, "tenant");

				expect($jobCount(dsA, "deferred_kept")).toBe(1);
				expect($jobCount(dsA, "deferred_unit")).toBe(0);
				expect($tenantRows(dsB)).toBe(1);
			});

			it("throws Wheels.Job.EnqueueFailed after the commit when the deferred write fails", function() {
				if (!tenantState.available) {
					skip("The wheelstestdb_sqlite_tenant_b datasource is not configured on this engine.");
				}
				request.tenantJobQueue = "deferred_fail";
				request.tenantJobClass = "wheels.tests._assets.jobs.PersistFailJob";
				$activateTenantB(dsB);
				var state = {type = ""};
				try {
					application.wo.model("TenantJobProduct").create(name = "committed, job lost", transaction = "commit");
				} catch (any e) {
					state.type = e.type;
				}
				StructDelete(request.wheels, "tenant");

				expect(state.type).toBe("Wheels.Job.EnqueueFailed");
				expect($tenantRows(dsB)).toBe(1);
			});

			it("joins a shared model's transaction under a tenant, since it is on the job store's datasource", function() {
				if (!tenantState.available) {
					skip("The wheelstestdb_sqlite_tenant_b datasource is not configured on this engine.");
				}
				request.tenantJobQueue = "deferred_shared";
				$activateTenantB(dsB);
				application.wo.model("SharedJobProduct").create(name = "shared", transaction = "commit");
				StructDelete(request.wheels, "tenant");

				expect(request.tenantJobResult.persisted).toBeTrue();
				expect(request.tenantJobResult.deferred ?: false).toBeFalse();
				expect($jobCount(dsA, "deferred_shared")).toBe(1);
			});

			it("writes immediately on the job store's own datasource", function() {
				if (!tenantState.available) {
					skip("The wheelstestdb_sqlite_tenant_b datasource is not configured on this engine.");
				}
				request.tenantJobQueue = "deferred_same";
				application.wo.model("TenantJobProduct").create(name = "same datasource", transaction = "commit");

				expect(request.tenantJobResult.persisted).toBeTrue();
				expect(request.tenantJobResult.deferred ?: false).toBeFalse();
				expect($jobCount(dsA, "deferred_same")).toBe(1);
			});

			it("writes immediately under a tenant when no transaction is open", function() {
				if (!tenantState.available) {
					skip("The wheelstestdb_sqlite_tenant_b datasource is not configured on this engine.");
				}
				request.tenantJobQueue = "deferred_none";
				$activateTenantB(dsB);
				application.wo.model("TenantJobProduct").create(name = "no transaction", transaction = "none");
				StructDelete(request.wheels, "tenant");

				expect(request.tenantJobResult.persisted).toBeTrue();
				expect($jobCount(dsA, "deferred_none")).toBe(1);
			});

		});

		describe("Choosing the transaction a deferred enqueue belongs to", function() {

			it("follows the innermost open owner, not the first one found", function() {
				var job = new wheels.tests._assets.jobs.ProbeJob();
				var store = application.wheels.dataSourceName;
				var saved = {
					stack = StructKeyExists(request.wheels, "$txnOwnerStack") ? request.wheels.$txnOwnerStack : "",
					callbacks = StructKeyExists(request.wheels, "$txnCallbacks") ? request.wheels.$txnCallbacks : ""
				};
				var picked = {};
				try {
					// outer owner on the job store, inner owner on another datasource
					request.wheels.$txnCallbacks = {
						ownerStore = {real = true, queue = [], dataSource = store},
						ownerTenant = {real = true, queue = [], dataSource = "some_tenant_ds"}
					};
					request.wheels.$txnOwnerStack = ["ownerStore", "ownerTenant"];
					picked.innerTenant = job.$crossDatasourceTransaction();
					// outer owner on another datasource, inner owner on the job store
					request.wheels.$txnOwnerStack = ["ownerTenant", "ownerStore"];
					picked.innerStore = job.$crossDatasourceTransaction();
				} finally {
					$restoreTransactionState(saved);
				}

				expect(picked.innerTenant).toBe("ownerTenant");
				expect(picked.innerStore).toBe("");
			});

		});

	}

	public void function $activateTenantB(required string dsB) {
		request.wheels.tenant = {id = "tenant_b", dataSource = arguments.dsB, config = {}, "$locked" = true};
	}

	public void function $restoreTransactionState(required struct saved) {
		if (IsSimpleValue(arguments.saved.stack)) {
			StructDelete(request.wheels, "$txnOwnerStack");
		} else {
			request.wheels.$txnOwnerStack = arguments.saved.stack;
		}
		if (IsSimpleValue(arguments.saved.callbacks)) {
			StructDelete(request.wheels, "$txnCallbacks");
		} else {
			request.wheels.$txnCallbacks = arguments.saved.callbacks;
		}
	}

	public numeric function $jobCount(required string datasource, required string queue) {
		try {
			return QueryExecute("SELECT COUNT(*) AS n FROM wheels_jobs WHERE queue = :queue", {queue = arguments.queue}, {datasource = arguments.datasource}).n;
		} catch (any e) {
			// no job table in that database
			return 0;
		}
	}

	public numeric function $tenantRows(required string datasource) {
		return QueryExecute("SELECT COUNT(*) AS n FROM tenant_job_products", [], {datasource = arguments.datasource}).n;
	}

}
