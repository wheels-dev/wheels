/**
 * A job enqueued inside a Wheels-managed transaction whose writes go to another datasource
 * than the job store's is written to the job store when that transaction commits, and dropped
 * if it rolls back. A transaction on the job store's own datasource (including a shared
 * model's under a tenant) is joined, and with no transaction open the job is written
 * immediately.
 *
 * Most specs use SecondaryJobProduct, whose own datasource is wheelstestdb_sqlite_tenant_b,
 * so they run on every primary database. The tenant-routing spec needs a tenant datasource of
 * the same database type as the primary (a model's SQL dialect comes from its adapter), and
 * the test tenant datasource is SQLite, so it runs only when the primary is SQLite.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Job enqueue deferred to the commit of a transaction on another datasource", function() {

			var dsA = application.wheels.dataSourceName;
			var dsB = "wheelstestdb_sqlite_tenant_b";
			var secondaryAvailable = true;
			try {
				QueryExecute("SELECT 1 AS t", [], {datasource = dsB});
			} catch (any e) {
				secondaryAvailable = false;
			}
			// Always register the tests: skip() with the reason instead of returning early, so an
			// unavailable setup shows as skipped, never as a silent pass.
			var setup = {
				available = secondaryAvailable,
				reason = "The wheelstestdb_sqlite_tenant_b datasource is not configured on this engine.",
				primaryIsSQLite = CompareNoCase(CreateObject("component", "wheels.migrator.Migration").init().adapter.adapterName(), "SQLite") == 0
			};

			beforeEach(function() {
				if (!setup.available) {
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
				if (!setup.available) {
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

			it("writes the job to the job store once the transaction commits", function() {
				if (!setup.available) {
					skip(setup.reason);
				}
				request.tenantJobQueue = "deferred_commit";
				application.wo.model("SecondaryJobProduct").create(name = "committed", transaction = "commit");

				expect(request.tenantJobResult.deferred ?: false).toBeTrue("the enqueue inside the transaction should be deferred");
				expect($jobCount(dsA, "deferred_commit")).toBe(1);
				expect($jobCount(dsB, "deferred_commit")).toBe(0);
				expect($secondaryRows(dsB)).toBe(1);
			});

			it("drops the job when the transaction rolls back", function() {
				if (!setup.available) {
					skip(setup.reason);
				}
				request.tenantJobQueue = "deferred_rollback";
				application.wo.model("SecondaryJobProduct").create(name = "rolled back", transaction = "rollback");

				expect($jobCount(dsA, "deferred_rollback")).toBe(0);
				expect($jobCount(dsB, "deferred_rollback")).toBe(0);
				expect($secondaryRows(dsB)).toBe(0);
			});

			it("drops only the job of a savepoint unit that rolls back", function() {
				if (!setup.available) {
					skip(setup.reason);
				}
				application.wo.model("SecondaryJobProduct").invokeWithTransaction(method = "txnKeepThenFailingUnit", transaction = "commit");

				expect($jobCount(dsA, "deferred_kept")).toBe(1);
				expect($jobCount(dsA, "deferred_unit")).toBe(0);
				expect($secondaryRows(dsB)).toBe(1);
			});

			it("throws Wheels.Job.EnqueueFailed after the commit when the deferred write fails", function() {
				if (!setup.available) {
					skip(setup.reason);
				}
				request.tenantJobQueue = "deferred_fail";
				request.tenantJobClass = "wheels.tests._assets.jobs.PersistFailJob";
				var state = {type = ""};
				try {
					application.wo.model("SecondaryJobProduct").create(name = "committed, job lost", transaction = "commit");
				} catch (any e) {
					state.type = e.type;
				}

				expect(state.type).toBe("Wheels.Job.EnqueueFailed");
				expect($secondaryRows(dsB)).toBe(1);
			});

			it("writes immediately when no transaction is open", function() {
				if (!setup.available) {
					skip(setup.reason);
				}
				request.tenantJobQueue = "deferred_none";
				application.wo.model("SecondaryJobProduct").create(name = "no transaction", transaction = "none");

				expect(request.tenantJobResult.persisted).toBeTrue();
				expect($jobCount(dsA, "deferred_none")).toBe(1);
			});

			it("writes immediately inside a transaction on the job store's own datasource", function() {
				if (!setup.available) {
					skip(setup.reason);
				}
				request.tenantJobQueue = "deferred_same";
				application.wo.model("TenantJobProduct").create(name = "same datasource", transaction = "commit");

				expect(request.tenantJobResult.persisted).toBeTrue();
				expect(request.tenantJobResult.deferred ?: false).toBeFalse();
				expect($jobCount(dsA, "deferred_same")).toBe(1);
			});

			it("joins a shared model's transaction under a tenant, since it is on the job store's datasource", function() {
				if (!setup.available) {
					skip(setup.reason);
				}
				request.tenantJobQueue = "deferred_shared";
				$activateTenantB(dsB);
				application.wo.model("SharedJobProduct").create(name = "shared", transaction = "commit");
				StructDelete(request.wheels, "tenant");

				expect(request.tenantJobResult.persisted).toBeTrue();
				expect(request.tenantJobResult.deferred ?: false).toBeFalse();
				expect($jobCount(dsA, "deferred_shared")).toBe(1);
			});

			it("defers inside a tenant model's transaction when a tenant routes it to its own datasource", function() {
				if (!setup.available) {
					skip(setup.reason);
				}
				if (!setup.primaryIsSQLite) {
					skip("Tenant routing keeps the model's adapter, so the tenant datasource must be the primary's database type; the test tenant datasource is SQLite and this leg's primary is not.");
				}
				request.tenantJobQueue = "deferred_tenant";
				$activateTenantB(dsB);
				application.wo.model("TenantJobProduct").create(name = "tenant", transaction = "commit");
				StructDelete(request.wheels, "tenant");

				expect(request.tenantJobResult.deferred ?: false).toBeTrue();
				expect($jobCount(dsA, "deferred_tenant")).toBe(1);
				expect($jobCount(dsB, "deferred_tenant")).toBe(0);
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
						ownerOther = {real = true, queue = [], dataSource = "some_other_ds"}
					};
					request.wheels.$txnOwnerStack = ["ownerStore", "ownerOther"];
					picked.innerOther = job.$crossDatasourceTransaction();
					// outer owner on another datasource, inner owner on the job store
					request.wheels.$txnOwnerStack = ["ownerOther", "ownerStore"];
					picked.innerStore = job.$crossDatasourceTransaction();
				} finally {
					$restoreTransactionState(saved);
				}

				expect(picked.innerOther).toBe("ownerOther");
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

	public numeric function $secondaryRows(required string datasource) {
		return QueryExecute("SELECT COUNT(*) AS n FROM tenant_job_products", [], {datasource = arguments.datasource}).n;
	}

}
