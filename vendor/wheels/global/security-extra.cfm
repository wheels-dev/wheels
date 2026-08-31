<cfscript>
/**
 * Whether an existing bcrypt hash should be re-hashed because its cost
 * factor differs from the target, or because it is malformed.
 *
 * Self-contained (regex cost parse) so it can ship on EVERY engine —
 * including RustCFML, which provides bcryptHash/bcryptVerify as native
 * builtins and therefore skips the main security.cfm include.
 */
public boolean function bcryptNeedsRehash(required string hash, numeric cost = 10) {
	$bcryptNeedsRehashValidateCost(arguments.cost);
	// Accept $2a$ / $2b$ / $2y$ prefixes; the cost is always two digits.
	var m = reFind("^\$2[aby]\$([0-9]{2})\$", arguments.hash, 1, true);
	if (arrayLen(m.len) < 2 || m.len[2] == 0) {
		return true;
	}
	var hashCost = mid(arguments.hash, m.pos[2], m.len[2]);
	// Normalize the two-digit string ("04") to a number before comparing —
	// RustCFML's string/number != does not coerce the way Lucee/Adobe do.
	return Val(hashCost) != arguments.cost;
}

/**
 * Cost-factor bounds shared by bcryptNeedsRehash (public with $ prefix —
 * cross-engine invariant #7).
 */
public void function $bcryptNeedsRehashValidateCost(required numeric cost) {
	if (arguments.cost < 4 || arguments.cost > 31) {
		Throw(
			type = "Wheels.InvalidArgument",
			message = "bcrypt cost must be between 4 and 31, received #arguments.cost#."
		);
	}
}
</cfscript>
