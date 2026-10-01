<cfscript>
/**
 * Spec helper for RateLimiter fixedWindow sequences (#3773).
 *
 * fixedWindow counts requests per window `Int(now / windowSeconds)`, with
 * `now = GetTickCount() / 1000`, so windows align to the clock: a 60-second
 * window turns over at every minute. A spec that sends two requests and
 * expects the second to be limited fails whenever the two land on either side
 * of that boundary (seen once: 16:16:59.948 -> 16:17:00.010).
 *
 * Call this right before such a sequence. When the current window has less
 * than `minRemainingSeconds` left, it sleeps just past the boundary, so the
 * whole sequence runs inside one fresh window. It never changes the limiter or
 * the assertions, and it only waits in the last few seconds of a window.
 *
 * Public and $-prefixed per the cross-engine invariants; included into a spec
 * component the same way ../migrator/helperFunctions.cfm is.
 */
public void function $awaitRateLimitWindow(required numeric windowSeconds, numeric minRemainingSeconds = 3) {
	var nowSeconds = GetTickCount() / 1000;
	var elapsedInWindow = nowSeconds - Int(nowSeconds / arguments.windowSeconds) * arguments.windowSeconds;
	var remainingSeconds = arguments.windowSeconds - elapsedInWindow;
	if (remainingSeconds < arguments.minRemainingSeconds) {
		Sleep(Ceiling((remainingSeconds + 0.05) * 1000));
	}
}
</cfscript>
