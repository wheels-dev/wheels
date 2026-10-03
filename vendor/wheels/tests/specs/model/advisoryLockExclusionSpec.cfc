/**
 * withAdvisoryLock() keeps a second caller out and leaves no lock held (#4197). MySQL and
 * PostgreSQL advisory locks belong to a database session and a session can take the same lock
 * again, while Wheels runs the acquire and the release as separate pooled queries. On Lucee and
 * BoxLang a second caller borrowed the idle connection holding the lock, took it too, and the lock
 * stayed held after both finished.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.g = application.wo;
		variables.ds = variables.g.get("dataSourceName");
		variables.adapterName = variables.g.get("adapterName");
		variables.applies = ListFindNoCase("PostgreSQLModel,MySQLModel", variables.adapterName) > 0;
	}

	function lockName() {
		return "wheels_spec_" & Replace(CreateUUID(), "-", "", "all");
	}

	// True when any session holds the named lock, read straight from the database.
	function isHeld(required string name) {
		if (variables.adapterName == "PostgreSQLModel") {
			var q = QueryExecute(
				"SELECT COUNT(*) AS n FROM pg_locks WHERE locktype = 'advisory' AND granted AND objid = CAST((CAST(hashtext(?) AS bigint) & 4294967295) AS oid)",
				[arguments.name],
				{datasource = variables.ds}
			);
			return q.n > 0;
		}
		var m = QueryExecute("SELECT IS_USED_LOCK(?) AS id", [arguments.name], {datasource = variables.ds});
		return !IsNull(m.id) && Len(m.id) > 0;
	}

	// Starts a thread holding the lock for `holdMs` inside withAdvisoryLock(); returns the thread's
	// name, unique per call because thread names must be unique within a request.
	function startHolder(required string name, required numeric holdMs) {
		var threadName = "advisoryLockSpecHolder" & Replace(CreateUUID(), "-", "", "all");
		application.advisoryLockSpec = {started = false, done = false, error = ""};
		thread name="#threadName#" action="run" lockName="#arguments.name#" holdMs="#arguments.holdMs#" {
			try {
				var holdFor = attributes.holdMs;
				var body = function() {
					application.advisoryLockSpec.started = true;
					sleep(holdFor);
					return true;
				};
				application.wo.model("author").withAdvisoryLock(name = attributes.lockName, timeout = 10, callback = body);
			} catch (any e) {
				application.advisoryLockSpec.error = e.type & ": " & e.message;
			}
			application.advisoryLockSpec.done = true;
		}
		var waited = 0;
		while (!application.advisoryLockSpec.started && waited < 10000) {
			sleep(50);
			waited += 50;
		}
		return threadName;
	}

	function run() {

		describe("withAdvisoryLock() on MySQL and PostgreSQL", () => {

			it("keeps a second caller out while the first holds the lock, and frees it afterwards", () => {
				if (!variables.applies) {
					skip("Session advisory locks: MySQL and PostgreSQL.");
				}
				var name = lockName();
				var state = {entered = false, type = ""};
				var second = function() {
					state.entered = true;
					return true;
				};
				var holder = startHolder(name, 3000);
				expect(application.advisoryLockSpec.started).toBeTrue();
				try {
					variables.g.model("author").withAdvisoryLock(name = name, timeout = 1, callback = second);
				} catch (any e) {
					state.type = e.type;
				}
				thread action="join" name="#holder#" timeout="15000";
				expect(state.entered).toBeFalse();
				expect(state.type).toBe("Wheels.AdvisoryLockTimeout");
				expect(application.advisoryLockSpec.error).toBe("");
				expect(isHeld(name)).toBeFalse();
			});

			it("leaves the lock free after it returns and after its callback throws", () => {
				if (!variables.applies) {
					skip("Session advisory locks: MySQL and PostgreSQL.");
				}
				var name = lockName();
				var ok = function() {
					return "done";
				};
				expect(variables.g.model("author").withAdvisoryLock(name = name, callback = ok)).toBe("done");
				expect(isHeld(name)).toBeFalse();
				var failing = function() {
					Throw(type = "Wheels.SpecCallbackFailure", message = "callback failed");
				};
				var state = {type = ""};
				try {
					variables.g.model("author").withAdvisoryLock(name = name, callback = failing);
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels.SpecCallbackFailure");
				expect(isHeld(name)).toBeFalse();
			});

			it("frees the lock for the next caller once the first has finished", () => {
				if (!variables.applies) {
					skip("Session advisory locks: MySQL and PostgreSQL.");
				}
				var name = lockName();
				var holder = startHolder(name, 500);
				thread action="join" name="#holder#" timeout="15000";
				var next = function() {
					return "next";
				};
				expect(variables.g.model("author").withAdvisoryLock(name = name, timeout = 2, callback = next)).toBe("next");
				expect(isHeld(name)).toBeFalse();
			});

		});

		describe("Releasing an advisory lock", () => {

			it("throws Wheels.AdvisoryLockReleaseFailed naming the lock when it stays held", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLModel");
				prepareMock(adapter);
				adapter.$("$tryReleaseAdvisoryLock", false);
				adapter.$("$isAdvisoryLockHeld", true);
				var state = {type = "", message = ""};
				try {
					adapter.$releaseAdvisoryLockVerified(name = "spec-lock", retrySeconds = 0.2);
				} catch (any e) {
					state.type = e.type;
					state.message = e.message;
				}
				expect(state.type).toBe("Wheels.AdvisoryLockReleaseFailed");
				expect(state.message).toInclude("spec-lock");
			});

			it("treats a release as done when no session holds the lock any more", () => {
				var adapter = CreateObject("component", "wheels.databaseAdapters.PostgreSQL.PostgreSQLModel");
				prepareMock(adapter);
				adapter.$("$tryReleaseAdvisoryLock", false);
				adapter.$("$isAdvisoryLockHeld", false);
				adapter.$releaseAdvisoryLockVerified(name = "spec-lock", retrySeconds = 0.2);
				expect(adapter.$count("$tryReleaseAdvisoryLock")).toBe(1);
			});

		});

	}

}
