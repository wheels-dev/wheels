/**
 * Which datasource withAdvisoryLock() takes its lock on, by default (no transaction), when a tenant
 * datasource is active (#4223). A tenant (non-shared) model locks on the tenant's datasource, like
 * its queries; a shared model keeps the application's default datasource, so a lock taken through a
 * shared model is one lock for every tenant.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.g = application.wo;
		variables.adapterName = variables.g.get("adapterName");
		variables.applies = ListFindNoCase("MySQLModel,PostgreSQLModel,MicrosoftSQLServerModel", variables.adapterName) > 0;
		variables.missingDataSource = "wheels_lock_tenant_missing";
	}

	function lockName() {
		return "wheels_tenant_lock_" & Replace(CreateUUID(), "-", "", "all");
	}

	function activateMissingTenant() {
		request.wheels.tenant = {id = "lock-probe", dataSource = variables.missingDataSource, config = {}, "$locked" = true};
	}

	function restoreTenant(required any saved) {
		if (IsStruct(arguments.saved)) {
			request.wheels.tenant = arguments.saved;
		} else {
			StructDelete(request.wheels, "tenant");
		}
	}

	function run() {

		describe("withAdvisoryLock() under a tenant datasource", () => {

			it("takes a tenant model's lock on the tenant's datasource", () => {
				if (!variables.applies) {
					skip("Advisory locks: MySQL, PostgreSQL and SQL Server.");
				}
				var state = {ran = false, error = ""};
				var saved = IsDefined("request.wheels.tenant") ? Duplicate(request.wheels.tenant) : "";
				activateMissingTenant();
				try {
					variables.g.model("author").withAdvisoryLock(
						name = lockName(),
						callback = function() {
							state.ran = true;
						}
					);
				} catch (any e) {
					state.error = e.message & " " & e.detail & " " & (StructKeyExists(e, "extendedInfo") ? e.extendedInfo : "");
				} finally {
					restoreTenant(saved);
				}
				// the tenant's datasource doesn't exist, so the lock can only fail there
				expect(state.ran).toBeFalse("the callback ran: the lock was not taken on the tenant datasource");
				expect(state.error).toInclude(variables.missingDataSource);
			});

			it("takes a shared model's lock on the default datasource, whatever the tenant", () => {
				if (!variables.applies) {
					skip("Advisory locks: MySQL, PostgreSQL and SQL Server.");
				}
				var name = lockName();
				var shared = variables.g.model("sharedAuthor");
				var adapter = shared.$classData().adapter;
				var state = {ran = false, held = false, lockDataSource = ""};
				var saved = IsDefined("request.wheels.tenant") ? Duplicate(request.wheels.tenant) : "";
				activateMissingTenant();
				try {
					shared.withAdvisoryLock(
						name = name,
						callback = function() {
							state.ran = true;
							state.lockDataSource = adapter.$advisoryLockConnection().datasource;
							state.held = adapter.$isAdvisoryLockHeld(name);
						}
					);
				} finally {
					restoreTenant(saved);
				}
				expect(state.ran).toBeTrue();
				expect(state.lockDataSource).toBe(variables.g.get("dataSourceName"));
				expect(state.held).toBeTrue("the lock is held on the default datasource while the callback runs");
				expect(adapter.$isAdvisoryLockHeld(name)).toBeFalse("released afterwards");
			});

		});

	}

}
