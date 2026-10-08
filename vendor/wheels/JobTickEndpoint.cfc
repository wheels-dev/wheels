/**
 * The `/wheels/jobs/tick` endpoint: one JobRunner.tick() per call, for an engine scheduled task,
 * cron or systemd timer that wants to run jobs inside the app server instead of a worker process.
 *
 * The token is the security boundary, not the client's address. Many deployments put nginx or
 * Apache on the same host, so every proxied public request arrives from 127.0.0.1. So:
 * - the route doesn't exist (404) unless set(jobsRunnerToken = "...") is set;
 * - every call must present the token in the X-Wheels-Jobs-Token header (or, only when
 *   set(jobsRunnerTokenInQuery = true), as ?token=), compared in constant time; else 403;
 * - a request carrying a forwarding header (X-Forwarded-For, Forwarded, X-Real-IP,
 *   CF-Connecting-IP) came through a proxy, so it is refused (403) whatever its token.
 *
 * handle() takes the request's parts and returns {status, contentType, body}, so the rules are
 * testable without HTTP. Dispatch calls it before routing and before the public-component gate.
 */
component {

	public any function init() {
		return this;
	}

	/**
	 * Whether a request path is the tick route.
	 */
	public boolean function isTickPath(required string pathInfo) {
		local.path = LCase(Trim(arguments.pathInfo));
		if (Len(local.path) > 1 && Right(local.path, 1) == "/") {
			local.path = Left(local.path, Len(local.path) - 1);
		}
		return local.path == "/wheels/jobs/tick";
	}

	/**
	 * Applies the rules above and, when they pass, runs one tick.
	 * @method The request method.
	 * @headers The request headers (any case).
	 * @queryToken The `token` URL parameter, "" when absent.
	 */
	public struct function handle(required string method, required struct headers, string queryToken = "") {
		local.configured = $setting("jobsRunnerToken", "");
		if (!IsSimpleValue(local.configured) || !Len(Trim(local.configured))) {
			return $response(404, "text/plain", "Not Found");
		}
		if (!ListFindNoCase("GET,POST", arguments.method)) {
			return $json(405, {ok = false, error = "Use GET or POST."});
		}
		for (local.name in ["X-Forwarded-For", "Forwarded", "X-Real-IP", "CF-Connecting-IP"]) {
			if (Len($header(arguments.headers, local.name))) {
				return $json(403, {ok = false, error = "Refused: the request came through a proxy (#local.name#). Call the tick route on the server itself."});
			}
		}
		local.presented = $header(arguments.headers, "X-Wheels-Jobs-Token");
		if (!Len(local.presented) && $setting("jobsRunnerTokenInQuery", false) == true) {
			local.presented = arguments.queryToken;
		}
		if (!Len(local.presented) || !$tokensMatch(local.presented, local.configured)) {
			return $json(403, {ok = false, error = "Refused: missing or wrong X-Wheels-Jobs-Token."});
		}
		return $json(200, $runTick());
	}

	/**
	 * Internal: one tick under a per-host lock taken try-once, so a call that overlaps a running
	 * tick on this server returns at once instead of stacking.
	 */
	public struct function $runTick() {
		local.started = GetTickCount();
		local.job = new wheels.Job();
		local.host = local.job.$jobHostName();
		var outcome = {ran = false, summary = {}, error = ""};
		lock name="wheels.jobs.tick.#local.host#" type="exclusive" timeout="1" throwOnTimeout="false" {
			outcome.ran = true;
			try {
				outcome.summary = new wheels.JobRunner().tick();
			} catch (any e) {
				outcome.error = e.message;
			}
		}
		if (!outcome.ran) {
			return {ok = true, skipped = "A tick is already running on this server.", host = local.host};
		}
		if (Len(outcome.error)) {
			writeLog(text = "Job tick failed: #outcome.error#", type = "error", file = "wheels_jobs");
			return {ok = false, error = outcome.error, host = local.host};
		}
		local.rv = Duplicate(outcome.summary);
		local.rv.ok = true;
		local.rv.durationMs = GetTickCount() - local.started;
		return local.rv;
	}

	/**
	 * Internal: compares two tokens in time that doesn't depend on where they differ. Both are
	 * hashed first, so the comparison is always over two 64-character digests.
	 */
	public boolean function $tokensMatch(required string presented, required string expected) {
		local.a = Hash(arguments.presented, "SHA-256", "utf-8");
		local.b = Hash(arguments.expected, "SHA-256", "utf-8");
		local.diff = 0;
		for (local.i = 1; local.i <= Len(local.b); local.i++) {
			local.diff = BitOr(local.diff, BitXor(Asc(Mid(local.a, local.i, 1)), Asc(Mid(local.b, local.i, 1))));
		}
		return local.diff == 0;
	}

	/**
	 * Internal: a header's value, matched without regard to case ("" when absent).
	 */
	public string function $header(required struct headers, required string name) {
		for (local.key in arguments.headers) {
			if (CompareNoCase(local.key, arguments.name) == 0) {
				local.value = arguments.headers[local.key];
				return IsSimpleValue(local.value) ? Trim(local.value) : "";
			}
		}
		return "";
	}

	public any function $setting(required string name, required any fallback) {
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, arguments.name)) {
			return application.wheels[arguments.name];
		}
		return arguments.fallback;
	}

	public struct function $json(required numeric status, required struct body) {
		return $response(arguments.status, "application/json", SerializeJSON(arguments.body));
	}

	public struct function $response(required numeric status, required string contentType, required string body) {
		return {status = arguments.status, contentType = arguments.contentType, body = arguments.body};
	}

}
