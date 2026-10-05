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

	function activateMissingTenant(string dataSource = variables.missingDataSource) {
		request.wheels.tenant = {id = arguments.dataSource, dataSource = arguments.dataSource, config = {}, "$locked" = true};
	}

	// Starts a thread holding the in-application lock named `localName` (what withAdvisoryLock()
	// waits on first) for `holdMs`, and waits until it holds it. Started from a method, not a
	// closure, and sharing state through the application scope, like advisoryLockExclusionSpec.
	function startLocalHolder(required string localName, required numeric holdMs) {
		var threadName = "advisoryLockTenantHolder" & Replace(CreateUUID(), "-", "", "all");
		application.advisoryLockTenantSpec = {started = false};
		thread name="#threadName#" action="run" localName="#arguments.localName#" holdMs="#arguments.holdMs#" {
			lock name="#attributes.localName#" type="exclusive" timeout="5" {
				application.advisoryLockTenantSpec.started = true;
				sleep(attributes.holdMs);
			}
		}
		var waited = 0;
		while (!application.advisoryLockTenantSpec.started && waited < 5000) {
			sleep(50);
			waited += 50;
		}
		return threadName;
	}

	// The error type and text withAdvisoryLock() gives under the given tenant datasource, with a
	// 1 second timeout, and whether the callback ran.
	function lockUnderTenant(required string dataSource, required string name) {
		var state = {ran = false, type = "", text = ""};
		var saved = IsDefined("request.wheels.tenant") ? Duplicate(request.wheels.tenant) : "";
		activateMissingTenant(arguments.dataSource);
		try {
			variables.g.model("author").withAdvisoryLock(
				name = arguments.name,
				timeout = 1,
				callback = function() {
					state.ran = true;
				}
			);
		} catch (any e) {
			state.type = e.type;
			state.text = e.message & " " & e.detail & " " & (StructKeyExists(e, "extendedInfo") ? e.extendedInfo : "");
		} finally {
			restoreTenant(saved);
		}
		return state;
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

			// Two tenants using the same lock name on one server: while a caller holds tenant A's
			// in-application wait, tenant B gets past it at once (and reaches its own datasource,
			// which here doesn't exist), and a second tenant-A caller still waits and times out.
			it("doesn't make two tenants with the same lock name wait for each other on one server", () => {
				if (!variables.applies) {
					skip("Advisory locks: MySQL, PostgreSQL and SQL Server.");
				}
				var name = lockName();
				var tenantA = variables.missingDataSource & "_a";
				var tenantB = variables.missingDataSource & "_b";
				var saved = IsDefined("request.wheels.tenant") ? Duplicate(request.wheels.tenant) : "";
				activateMissingTenant(tenantA);
				try {
					var localNameA = variables.g.model("author").$advisoryLockLocalName(name);
				} finally {
					restoreTenant(saved);
				}
				var holder = startLocalHolder(localNameA, 4000);
				var other = lockUnderTenant(tenantB, name);
				var same = lockUnderTenant(tenantA, name);
				thread action="join" name="#holder#" timeout="15000";
				expect(application.advisoryLockTenantSpec.started).toBeTrue("the holder thread took tenant A's lock");
				expect(other.type).notToBe("Wheels.AdvisoryLockTimeout", "tenant B waited behind tenant A");
				expect(other.text).toInclude(tenantB);
				expect(same.type).toBe("Wheels.AdvisoryLockTimeout");
				expect(same.text).toInclude("Another caller in this application");
				expect(other.ran || same.ran).toBeFalse();
			});

			// The in-application wait (#4197) follows the lock's datasource: callers of another
			// tenant's database don't queue behind this one on the same server.
			it("keys the in-application wait on the datasource the lock is taken on", () => {
				var name = lockName();
				var author = variables.g.model("author");
				var shared = variables.g.model("sharedAuthor");
				var names = {defaultAuthor = author.$advisoryLockLocalName(name), defaultShared = shared.$advisoryLockLocalName(name)};
				var saved = IsDefined("request.wheels.tenant") ? Duplicate(request.wheels.tenant) : "";
				activateMissingTenant();
				try {
					names.tenantAuthor = author.$advisoryLockLocalName(name);
					names.tenantShared = shared.$advisoryLockLocalName(name);
				} finally {
					restoreTenant(saved);
				}
				expect(names.defaultShared).toBe(names.defaultAuthor, "without a tenant, both use the default datasource");
				expect(names.tenantAuthor).notToBe(names.defaultAuthor, "a tenant model waits per tenant datasource");
				expect(names.tenantShared).toBe(names.defaultAuthor, "a shared model keeps one wait for the whole application");
			});

		});

	}

}
