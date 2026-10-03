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
	public boolean function requestIsTestContext(
		struct cgiScope = {},
		struct cookieScope = {},
		string environment = "",
		string expectedSecret = "",
		string remoteAddr = ""
	) {
		// Defense-in-depth environment gate. Honour the markers
		// only when the environment is development or testing; fail closed
		// for production and any unknown value.
		if (!$environmentAllowsTestContext(arguments.environment)) {
			return false;
		}

		// Path trigger — anchored to the request PATH (see $cgiHaystack).
		var haystack = $cgiHaystack(arguments.cgiScope);
		if (FindNoCase("/wheels/core/tests", haystack) || FindNoCase("/wheels/app/tests", haystack)) {
			return true;
		}

		// Header / cookie trigger — the runner secret is required.
		// Require a non-empty expected secret AND a loopback socket peer, then a
		// constant-time match. A bare or wrong value, or a non-loopback peer, is
		// ignored.
		if (!Len(arguments.expectedSecret) || !$isLoopbackPeer(arguments.remoteAddr)) {
			return false;
		}

		var headerKey = cgiHeaderKey();
		if (
			StructKeyExists(arguments.cgiScope, headerKey)
			&& Len(ToString(arguments.cgiScope[headerKey]))
			&& $secureEquals(ToString(arguments.cgiScope[headerKey]), arguments.expectedSecret)
		) {
			return true;
		}

		var cName = cookieName();
		if (
			StructKeyExists(arguments.cookieScope, cName)
			&& Len(ToString(arguments.cookieScope[cName]))
			&& $secureEquals(ToString(arguments.cookieScope[cName]), arguments.expectedSecret)
		) {
			return true;
		}

		return false;
	}

	/**
	 * The resolved environment may honour the test-context markers.
	 * Allow-list: development and testing only. Everything else — production,
	 * maintenance, blank/unknown — fails closed.
	 */
	public boolean function $environmentAllowsTestContext(string environment = "") {
		var env = LCase(Trim(arguments.environment));
		return env == "development" || env == "testing";
	}

	/**
	 * True only when remoteAddr is a loopback socket peer (127.0.0.0/8, ::1).
	 * Resolved through java.net.InetAddress so IPv4/IPv6 forms are covered.
	 * Fails closed (false) on a blank address or any resolution error. The
	 * caller must pass cgi.remote_addr (the real socket peer), never a
	 * forwarded header such as X-Forwarded-For.
	 */
	public boolean function $isLoopbackPeer(string remoteAddr = "") {
		if (!Len(Trim(arguments.remoteAddr))) {
			return false;
		}
		try {
			return CreateObject("java", "java.net.InetAddress")
				.getByName(Trim(arguments.remoteAddr))
				.isLoopbackAddress();
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Constant-time string equality. Both sides are hashed to equal-length
	 * hex first, so the comparison loop runs over a fixed width and leaks
	 * neither length nor a shared prefix. Mirrors the inline compare in
	 * events/testcontext.cfm (which cannot CreateObject this CFC from the
	 * Application.cfc constructor).
	 */
	public boolean function $secureEquals(required string a, required string b) {
		var ha = Hash(arguments.a, "SHA-256");
		var hb = Hash(arguments.b, "SHA-256");
		var diff = 0;
		var n = Len(ha);
		var i = 0;
		for (i = 1; i <= n; i++) {
			diff = BitOr(diff, BitXor(Asc(Mid(ha, i, 1)), Asc(Mid(hb, i, 1))));
		}
		return diff == 0;
	}

	/**
	 * Primary start-backstop decision: an isolated (`_wheelsTest`)
	 * application must be refused at onApplicationStart unless the
	 * config-resolved environment is development or testing. This is the
	 * authoritative gate (the constructor runs on WHEELS_ENV, which is not a
	 * trustworthy production signal); events/onapplicationstart.cfc inlines the
	 * same decision before the app's onapplicationstart.cfm, autoMigrate, and
	 * job/scheduler registration run.
	 */
	public boolean function startRefused(required string applicationName, required string environment) {
		return isIsolatedApplicationName(arguments.applicationName)
			&& !$environmentAllowsTestContext(arguments.environment);
	}

	/**
	 * True when the current request already runs in the isolated test
	 * application in development or testing, i.e. inside a test-runner request.
	 * TestClient uses it to send the test context with its requests by default,
	 * so in-test HTTP reaches the same application as the spec code.
	 */
	public boolean function currentRequestIsIsolated() {
		if (!IsDefined("application.applicationName") || !isIsolatedApplicationName(application.applicationName)) {
			return false;
		}
		return StructKeyExists(application, "wheels")
			&& StructKeyExists(application.wheels, "environment")
			&& $environmentAllowsTestContext(application.wheels.environment);
	}

	/**
	 * The per-process test-runner secret. Lazily generated into the server
	 * scope the first time a runner (or TestClient/BrowserTest) needs it, so
	 * only server-side code in an already-running test process can learn it.
	 * events/testcontext.cfm reads server.$wheelsTestContextSecret directly and
	 * compares the incoming header/cookie against it.
	 */
	public string function testSecret() {
		if (!StructKeyExists(server, "$wheelsTestContextSecret") || !Len(server.$wheelsTestContextSecret)) {
			lock name="wheelsTestContextSecret" type="exclusive" timeout="5" {
				if (!StructKeyExists(server, "$wheelsTestContextSecret") || !Len(server.$wheelsTestContextSecret)) {
					server.$wheelsTestContextSecret = Hash(CreateUUID() & GetTickCount() & CreateUUID(), "SHA-256");
				}
			}
		}
		return server.$wheelsTestContextSecret;
	}

	/**
	 * Concatenate the CGI fields that carry the runner PATH: path_info and
	 * script_name.
	 */
	public string function $cgiHaystack(required struct cgiScope) {
		var haystack = "";
		var keys = "path_info,script_name";
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
