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
	 * Whether `events/testcontext.cfm` should mark the request as isolation-configured (set
	 * `request.$wheelsTestContextConfigured`). True when the request is already in the isolated
	 * application, or the include's own environment gate (WHEELS_ENV is development/testing) allows
	 * isolation to bind. Deliberately NOT based on the runtime `application.wheels.environment`: an app
	 * configured for development only in `config/environment.cfm`, with WHEELS_ENV unset, never binds
	 * isolation in the constructor, so it must not be marked — otherwise the runner guard would refuse a
	 * run the app can only do through the live-scope swap. The inline copy in events/testcontext.cfm sets
	 * the marker in exactly these two spots; keep the two in lockstep.
	 */
	public boolean function requestIsTestContextConfigured(required boolean alreadyIsolated, required boolean environmentAllows) {
		return arguments.alreadyIsolated || arguments.environmentAllows;
	}

	/**
	 * True when a test-runner action (`testbox` / `tests_testbox`) must refuse to run in the current
	 * application rather than execute specs against it. It refuses only when isolation is configured AND
	 * could bind for this request — the `events/testcontext.cfm` include ran and its environment gate
	 * allowed it (`isolationConfigured`, i.e. `request.$wheelsTestContextConfigured`) — but the request
	 * did not bind the isolated `<name>_wheelsTest` scope, e.g. it arrived through a custom route the path
	 * trigger does not cover. An app WITHOUT the include, or whose WHEELS_ENV did not allow isolation
	 * (`isolationConfigured` false), is left alone: it keeps the existing live-scope test swap (with the
	 * #4354 warning), so upgraded apps and non-dev environments are not broken.
	 */
	public boolean function testRunnerMustRefuse(required boolean isolationConfigured, required string applicationName) {
		return arguments.isolationConfigured && !isIsolatedApplicationName(arguments.applicationName);
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

		// Path trigger — the request path must be, or start a path segment with, a runner endpoint.
		if ($pathTriggersTestContext(arguments.cgiScope)) {
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
	 * F23 — the test-supplied client address (the X-Wheels-Test-Remote-Addr header, as the mapped
	 * `http_x_wheels_test_remote_addr` CGI key) when the request qualifies, or "" otherwise. Two gates,
	 * both required:
	 *   - `isolated`: the caller (Dispatch) passes currentRequestIsIsolated(), true only inside the
	 *     isolated test application AND when the environment is development/testing (so production can
	 *     never qualify);
	 *   - `remoteAddr`: the REAL socket peer (raw cgi.remote_addr, never a forwarded header) must be a
	 *     loopback address. TestClient always connects over loopback, so legitimate use is unaffected,
	 *     and an outside (non-loopback) client cannot set the address no matter how its request reached
	 *     the isolated context.
	 * The caller sets the result on the middleware request context's `remoteAddr` field; this never
	 * mutates the cgi scope.
	 */
	public string function $testClientRemoteAddr(required struct cgiScope, required boolean isolated, required string remoteAddr) {
		if (!arguments.isolated || !$isLoopbackPeer(arguments.remoteAddr)) {
			return "";
		}
		var headerKey = "http_x_wheels_test_remote_addr";
		if (!StructKeyExists(arguments.cgiScope, headerKey)) {
			return "";
		}
		return Trim(ToString(arguments.cgiScope[headerKey]));
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
	 * True when the request path targets a test-runner endpoint, anchored at the START of the path.
	 * For each of `path_info` and `script_name`: lowercase/trim, cut the query string off FIRST (so a
	 * `//` or `..` living inside a query cannot reject a legitimate runner URL), reject any remaining
	 * `..` traversal or `//` empty segment, then start-anchored match against
	 * `^/wheels/(core/tests|app/tests|testbox|tests_testbox)(/|$)` — i.e. the value must EQUAL `/wheels/core/tests` /
	 * `/wheels/app/tests` or start with one followed by `/`. Because the match is anchored at position
	 * 0 of a canonical path, a runner path that merely appears later in an application route
	 * (`/files/x/wheels/app/tests`), or is reached via a traversal (`/wheels/app/tests/../../files/x`)
	 * or a double slash, does NOT match. `path_info` is the post-context path, so a context-root-mounted
	 * app's runner still matches there.
	 *
	 * Keep this rule in lockstep with the inline copy in events/testcontext.cfm, which cannot call this
	 * method (it runs in Application.cfc's pseudo-constructor, before this.mappings is registered).
	 */
	public boolean function $pathTriggersTestContext(required struct cgiScope) {
		var keys = ["path_info", "script_name"];
		for (var key in keys) {
			if (!StructKeyExists(arguments.cgiScope, key)) {
				continue;
			}
			var path = ReReplace(LCase(Trim(ToString(arguments.cgiScope[key]))), "\?.*$", "");
			if (
				!ReFind("\.\.|//", path)
				&& ReFindNoCase("^/wheels/(core/tests|app/tests|testbox|tests_testbox)(/|$)", path) > 0
			) {
				return true;
			}
		}
		return false;
	}

}
