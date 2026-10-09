/**
 * The `/wheels/jobs/tick` endpoint: one JobRunner.tick() per call, for an engine scheduled task,
 * cron or systemd timer that wants to run jobs inside the app server instead of a worker process.
 *
 * The token is the security boundary, not the client's address. Many deployments put nginx or
 * Apache on the same host, so every proxied public request arrives from 127.0.0.1. So:
 * - the route doesn't exist (404) unless set(jobsRunnerToken = "...") is set;
 * - every call must present the token in the X-Wheels-Jobs-Token header (or, only when
 *   set(jobsRunnerTokenInQuery = true), as ?token=), compared in constant time; else 403;
 * - a request carrying any forwarding header (see $forwardingHeaders()), even an empty one,
 *   came through a proxy, so it is refused (403) whatever its token;
 * - a request whose method or headers can't be read is refused (500) without running a tick,
 *   rather than being judged on missing information;
 * - each tick runs with the jobsRunnerTickMaxJobs / jobsRunnerTickTimeout / jobsRunnerTickQueues
 *   settings, never with values from the request.
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
		for (local.name in $forwardingHeaders()) {
			if ($hasHeader(arguments.headers, local.name)) {
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
	 * tick on this server returns at once instead of stacking. Its batch size, timeout and queues
	 * come from the app's settings ($tickArguments()), never from the request.
	 */
	public struct function $runTick() {
		local.started = GetTickCount();
		local.job = new wheels.Job();
		local.host = local.job.$jobHostName();
		local.tickArgs = $tickArguments();
		var outcome = {ran = false, summary = {}, error = ""};
		lock name="wheels.jobs.tick.#local.host#" type="exclusive" timeout="1" throwOnTimeout="false" {
			outcome.ran = true;
			try {
				outcome.summary = $newRunner().tick(argumentCollection = local.tickArgs);
			} catch (any e) {
				outcome.error = e.message;
			}
		}
		if (!outcome.ran) {
			return {ok = true, skipped = "A tick is already running on this server.", host = local.host};
		}
		if (Len(outcome.error)) {
			// The caller gets a reference, not the error: details stay in the server log.
			local.requestId = CreateUUID();
			writeLog(text = "Job tick #local.requestId# failed: #outcome.error#", type = "error", file = "wheels_jobs");
			return {ok = false, error = "tick failed", requestId = local.requestId};
		}
		local.rv = Duplicate(outcome.summary);
		local.rv.ok = true;
		local.rv.durationMs = GetTickCount() - local.started;
		return local.rv;
	}

	/**
	 * Internal: the arguments each tick runs with, from settings so that a caller holding the token
	 * can't widen the work one request does: jobsRunnerTickMaxJobs (most jobs per call, default 1),
	 * jobsRunnerTickTimeout (seconds per job, default 300) and jobsRunnerTickQueues (comma list,
	 * default every queue). maxJobs must be a whole number from 1 to 1000 and timeout one from 1 to
	 * 86400 (a day); a missing, fractional or out-of-range value falls back to its default.
	 */
	public struct function $tickArguments() {
		local.queues = $setting("jobsRunnerTickQueues", "");
		return {
			maxJobs = $wholeSetting(name = "jobsRunnerTickMaxJobs", fallback = 1, maximum = 1000),
			timeout = $wholeSetting(name = "jobsRunnerTickTimeout", fallback = 300, maximum = 86400),
			queues = IsSimpleValue(local.queues) ? Trim(local.queues) : ""
		};
	}

	/**
	 * Internal: a setting that must be a whole number from 1 to `maximum` (well inside the INTEGER
	 * columns it can end up in, such as a claimed job's claimTimeout). Anything else (missing, not
	 * a number, a fraction, zero or less, or above the maximum) is the fallback. Never through
	 * Int(), which Lucee truncates to 32 bits.
	 */
	public numeric function $wholeSetting(required string name, required numeric fallback, required numeric maximum) {
		local.value = $setting(arguments.name, arguments.fallback);
		if (!IsSimpleValue(local.value) || !IsNumeric(local.value)) {
			return arguments.fallback;
		}
		local.value = Val(local.value);
		if (local.value < 1 || local.value > arguments.maximum || local.value != Round(local.value)) {
			return arguments.fallback;
		}
		return local.value;
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
	 * Answers the current HTTP request: reads its method and headers, then handle(). If either
	 * can't be read, the request is refused (500) without running a tick: the proxy check can't be
	 * made on information that isn't there. Returns {status, contentType, body}.
	 */
	public struct function respond(required struct urlScope) {
		var incoming = {method = "", headers = {}, readable = true};
		try {
			incoming.method = $readMethod();
			incoming.headers = $readHeaders();
		} catch (any e) {
			incoming.readable = false;
			writeLog(text = "Job tick refused: the request could not be read (#e.message#)", type = "error", file = "wheels_jobs");
		}
		if (!incoming.readable || !Len(incoming.method)) {
			return $json(500, {ok = false, error = "The request could not be read."});
		}
		return handle(
			method = incoming.method,
			headers = incoming.headers,
			queryToken = StructKeyExists(arguments.urlScope, "token") && IsSimpleValue(arguments.urlScope.token) ? arguments.urlScope.token : ""
		);
	}

	/**
	 * Internal: the JobRunner a tick runs on.
	 */
	public any function $newRunner() {
		return new wheels.JobRunner();
	}

	/**
	 * Internal: the request's method.
	 */
	public string function $readMethod() {
		return GetHttpRequestData(false).method;
	}

	/**
	 * Internal: the request's headers.
	 */
	public struct function $readHeaders() {
		return GetHttpRequestData(false).headers;
	}

	/**
	 * Internal: the headers whose presence means a request came through a proxy or load balancer.
	 */
	public array function $forwardingHeaders() {
		return [
			"X-Forwarded-For",
			"X-Forwarded-Host",
			"X-Forwarded-Proto",
			"X-Forwarded-Port",
			"X-Forwarded-Prefix",
			"Forwarded",
			"X-Real-IP",
			"X-Client-IP",
			"CF-Connecting-IP",
			"True-Client-IP",
			"X-Cluster-Client-IP"
		];
	}

	/**
	 * Internal: whether a header is present at all (any value, even empty), matched without
	 * regard to case.
	 */
	public boolean function $hasHeader(required struct headers, required string name) {
		for (local.key in arguments.headers) {
			if (CompareNoCase(local.key, arguments.name) == 0) {
				return true;
			}
		}
		return false;
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
