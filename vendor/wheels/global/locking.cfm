<cfscript>
/**
 * wheels.Global include: locking
 * Double-checked and simple named locks.
 *
 * Included from `vendor/wheels/Global.cfc` at component-body scope so
 * these functions compile into the Global component. Children inherit
 * them; there is no per-instance mixin copy. Keep every helper that
 * must mix onto models/controllers `public` and `$`-prefixed
 * (cross-engine invariant 7).
 */


	public any function $doubleCheckedLock(
		required string name,
		required string condition,
		required string execute,
		struct conditionArgs = "#StructNew()#",
		struct executeArgs = "#StructNew()#",
		numeric timeout = 30
	) {
		local.rv = $invoke(method = arguments.condition, invokeArgs = arguments.conditionArgs);
		if (StructKeyExists(local, "rv") AND IsBoolean(local.rv) AND NOT local.rv) {
			lock timeout="#arguments.timeout#" name="#arguments.name#" {
				local.rv = $invoke(method = arguments.condition, invokeArgs = arguments.conditionArgs);
				if (StructKeyExists(local, "rv") AND IsBoolean(local.rv) AND NOT local.rv) {
					local.rv = $invoke(method = arguments.execute, invokeArgs = arguments.executeArgs)
				}
			}
		}
		// Guard the read: on RustCFML assigning a void return DELETES the
		// key (null-assignment semantics), where JVM engines materialize a
		// null value. StructKeyExists keeps both engines uniform.
		if (StructKeyExists(local, "rv")) {
			return local.rv;
		}
	}


	public any function $simpleLock(
		required string name,
		required string type,
		required string execute,
		struct executeArgs = "#StructNew()#",
		numeric timeout = 30
	) {
		if (StructKeyExists(arguments, "object")) {
			lock name="#arguments.name#" type="#arguments.type#" timeout="#arguments.timeout#" {
				local.rv = $invoke(
					component = "#arguments.object#",
					method = "#arguments.execute#",
					argumentCollection = "#arguments.executeArgs#"
				);
			}
		} else {
			arguments.executeArgs.$locked = true;
			// Written only inside the lock body below; a struct (not local.) so
			// the finally reads it on every engine (cross-engine invariant 11).
			var restart = {token = ""};
			if (
				$isSessionEndDuringOwnRestart(
					name = arguments.name,
					type = arguments.type,
					execute = arguments.execute,
					executeArgs = arguments.executeArgs
				)
			) {
				// The exclusive holder is the restart, parked in applicationStop()
				// waiting for this very session end (BoxLang ends sessions on
				// ForkJoin worker threads there), so no other writer can exist and
				// the read lock could only wait out its timeout (issue 3770). A
				// scope already torn down has nothing left to run against
				// (invariant 19): return without running.
				if (
					StructKeyExists(arguments.executeArgs.applicationScope, "wheels")
					&& StructKeyExists(arguments.executeArgs.applicationScope.wheels, "eventPath")
				) {
					local.rv = $invoke(method = "#arguments.execute#", argumentCollection = "#arguments.executeArgs#");
				}
			} else if (CompareNoCase(arguments.type, "exclusive") == 0 && CompareNoCase(arguments.execute, "$handleRestartAppRequest") == 0) {
				lock name="#arguments.name#" type="#arguments.type#" timeout="#arguments.timeout#" {
					restart.token = $markRestartLock(name = arguments.name, timeout = arguments.timeout);
					try {
						local.rv = $invoke(method = "#arguments.execute#", argumentCollection = "#arguments.executeArgs#");
					} finally {
						$clearRestartLock(token = restart.token);
					}
				}
			} else {
				lock name="#arguments.name#" type="#arguments.type#" timeout="#arguments.timeout#" {
					local.rv = $invoke(method = "#arguments.execute#", argumentCollection = "#arguments.executeArgs#");
				}
			}
		}
		if (StructKeyExists(local, "rv")) {
			return local.rv;
		}
	}

	/**
	 * Record, in the application scope, that a restart holds the exclusive lock
	 * NAME (issue 3770). The token identifies this restart and expiresAt bounds
	 * how long the marker counts, so a marker a failed or aborted restart left
	 * behind is detectably stale. Returns the token for $clearRestartLock().
	 */
	public string function $markRestartLock(required string name, required numeric timeout) {
		local.token = CreateUUID();
		application["$wheelsRestartLock"] = {
			name = arguments.name,
			token = local.token,
			expiresAt = DateAdd("s", Max(arguments.timeout, 60), Now())
		};
		return local.token;
	}

	/**
	 * Remove this restart's marker. After a successful applicationStop() the
	 * marker went with the old application scope, and the scope itself can be
	 * torn down (invariant 19), so a missing marker or a failing read is fine.
	 */
	public void function $clearRestartLock(required string token) {
		try {
			if (
				StructKeyExists(application, "$wheelsRestartLock")
				&& IsStruct(application["$wheelsRestartLock"])
				&& StructKeyExists(application["$wheelsRestartLock"], "token")
				&& Compare(application["$wheelsRestartLock"].token, arguments.token) == 0
			) {
				StructDelete(application, "$wheelsRestartLock");
			}
		} catch (any e) {
			// The application scope is already gone; so is the marker.
		}
	}

	/**
	 * True for a read-locked session end whose application scope carries a
	 * live restart marker for the same lock (issue 3770): the only case in
	 * which $simpleLock runs its body without taking the lock.
	 */
	public boolean function $isSessionEndDuringOwnRestart(
		required string name,
		required string type,
		required string execute,
		required struct executeArgs
	) {
		if (CompareNoCase(arguments.type, "readOnly") != 0 || CompareNoCase(arguments.execute, "$runOnSessionEnd") != 0) {
			return false;
		}
		if (!StructKeyExists(arguments.executeArgs, "applicationScope") || !IsStruct(arguments.executeArgs.applicationScope)) {
			return false;
		}
		if (!StructKeyExists(arguments.executeArgs.applicationScope, "$wheelsRestartLock")) {
			return false;
		}
		// The restart can clear the marker between the check above and this
		// read ($clearRestartLock runs on its own thread): a missing or null
		// marker means no restart holds the lock, never an error.
		try {
			local.marker = arguments.executeArgs.applicationScope["$wheelsRestartLock"];
		} catch (any e) {
			return false;
		}
		if (!StructKeyExists(local, "marker")) {
			return false;
		}
		return IsStruct(local.marker)
			&& StructKeyExists(local.marker, "name")
			&& StructKeyExists(local.marker, "expiresAt")
			&& CompareNoCase(local.marker.name, arguments.name) == 0
			&& IsDate(local.marker.expiresAt)
			&& DateCompare(Now(), local.marker.expiresAt) < 0;
	}
</cfscript>
