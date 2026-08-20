/**
 * Helpers for the web test-runner's isolated CFML application context (issue #3374).
 *
 * A request-scoped config overlay cannot re-bake dialect adapters, model
 * caches, or routes (blockers B1–B9 on #3025). The supported isolation
 * model is a second application name, derived in Application.cfc's
 * constructor via events/testcontext.cfm. This CFC is the runtime twin
 * of that include: same suffix / header / cookie names, unit-testable
 * without booting a second application.
 *
 * Do not instantiate this from Application.cfc's constructor — `this.mappings`
 * is not guaranteed to be registered yet. The .cfm include inlines the
 * same checks.
 */
component {

	/**
	 * Suffix appended to this.name for isolated test requests.
	 */
	public string function applicationNameSuffix() {
		return "_wheelsTest";
	}

	/**
	 * HTTP header TestClient / ParallelRunner / Playwright send so fixture
	 * and browser requests (which are NOT /wheels/core/tests) bind the
	 * isolated application. CGI key is http_x_wheels_test_context.
	 */
	public string function headerName() {
		return "X-Wheels-Test-Context";
	}

	/**
	 * CGI struct key for headerName() after the engine's CGI mapping.
	 */
	public string function cgiHeaderKey() {
		return "http_x_wheels_test_context";
	}

	/**
	 * Cookie name (backup for Playwright follow-on navigations).
	 */
	public string function cookieName() {
		return "WHEELS_TEST_CONTEXT";
	}

	/**
	 * True when applicationName already carries the isolation suffix.
	 */
	public boolean function isIsolatedApplicationName(required string applicationName) {
		var suffix = applicationNameSuffix();
		var nameLen = Len(arguments.applicationName);
		var suffixLen = Len(suffix);
		if (nameLen < suffixLen) {
			return false;
		}
		return Right(arguments.applicationName, suffixLen) == suffix;
	}

	/**
	 * Return applicationName with the isolation suffix, idempotent.
	 */
	public string function isolatedApplicationName(required string applicationName) {
		if (isIsolatedApplicationName(arguments.applicationName)) {
			return arguments.applicationName;
		}
		return arguments.applicationName & applicationNameSuffix();
	}

	/**
	 * True when this request should bind the isolated test application.
	 *
	 * Markers (any one is enough):
	 *   - URL path contains /wheels/core/tests or /wheels/app/tests
	 *   - X-Wheels-Test-Context header (CGI http_x_wheels_test_context)
	 *   - WHEELS_TEST_CONTEXT cookie
	 *
	 * Parameter names avoid reserved CGI/cookie/url/request scopes
	 * (anti-pattern 11 / invariant 15).
	 */
	public boolean function requestIsTestContext(struct cgiScope = {}, struct cookieScope = {}) {
		var haystack = $cgiHaystack(arguments.cgiScope);
		if (FindNoCase("/wheels/core/tests", haystack) || FindNoCase("/wheels/app/tests", haystack)) {
			return true;
		}

		var headerKey = cgiHeaderKey();
		if (StructKeyExists(arguments.cgiScope, headerKey) && Len(ToString(arguments.cgiScope[headerKey]))) {
			return true;
		}

		var cName = cookieName();
		if (StructKeyExists(arguments.cookieScope, cName) && Len(ToString(arguments.cookieScope[cName]))) {
			return true;
		}

		return false;
	}

	/**
	 * Concatenate the CGI fields that can carry the runner path under
	 * rewrite, subdirectory, and query-string front-controller shapes.
	 */
	public string function $cgiHaystack(required struct cgiScope) {
		var haystack = "";
		var keys = "path_info,script_name,query_string,request_url,http_url";
		var i = 0;
		var key = "";
		var keyCount = ListLen(keys);
		for (i = 1; i <= keyCount; i++) {
			key = ListGetAt(keys, i);
			if (StructKeyExists(arguments.cgiScope, key)) {
				haystack &= " " & ToString(arguments.cgiScope[key]);
			}
		}
		return haystack;
	}

}
