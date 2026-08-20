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
		if (IsBoolean(local.rv) AND NOT local.rv) {
			lock timeout="#arguments.timeout#" name="#arguments.name#" {
				local.rv = $invoke(method = arguments.condition, invokeArgs = arguments.conditionArgs);
				if (IsBoolean(local.rv) AND NOT local.rv) {
					local.rv = $invoke(method = arguments.execute, invokeArgs = arguments.executeArgs)
				}
			}
		}
		return local.rv;
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
			lock name="#arguments.name#" type="#arguments.type#" timeout="#arguments.timeout#" {
				local.rv = $invoke(method = "#arguments.execute#", argumentCollection = "#arguments.executeArgs#");
			}
		}
		if (StructKeyExists(local, "rv")) {
			return local.rv;
		}
	}
</cfscript>
