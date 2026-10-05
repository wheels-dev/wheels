/**
 * Fluent HTTP test client for Wheels integration testing.
 *
 * Inspired by Laravel's HTTP test client. Provides a chainable API
 * for making HTTP requests and asserting on responses within test specs.
 *
 * Usage:
 *   visit("/users").assertOk().assertSee("John")
 *   post("/users", {firstName: "Jane"}).assertCreated()
 *   get("/api/users").asJson().assertJson({total: 5})
 */
component {

	// State
	variables.baseUrl = "";
	variables.lastResponse = {};
	variables.defaultHeaders = {};
	variables.cookies = {};
	variables.sendAsJson = false;
	// Memoized views of the immutable last response, so assertion chains
	// don't re-ToString()/re-DeserializeJSON() the body on every call.
	// Invalidated whenever variables.lastResponse changes.
	variables.contentCached = false;
	variables.contentCache = "";
	variables.jsonCached = false;
	variables.jsonCache = "";

	/**
	 * Initialize the test client with a base URL.
	 *
	 * @baseUrl     The base URL for all requests (e.g. "http://localhost:8080").
	 * @testContext Send the test context (header and cookie) with every request
	 *              when the client is created inside a test-runner request and
	 *              baseUrl points at the test server (see $isTestHost()), so the
	 *              requests reach the same isolated test application as the spec
	 *              code. Pass false to address the live application.
	 */
	public TestClient function init(string baseUrl = "http://localhost:8080", boolean testContext = true) {
		variables.baseUrl = arguments.baseUrl;
		variables.lastResponse = {};
		variables.defaultHeaders = {};
		variables.cookies = {};
		variables.sendAsJson = false;
		$clearResponseCaches();
		if (arguments.testContext) {
			$attachTestContext();
		}
		return this;
	}

	/**
	 * Adds the test-context header and cookie when this client is created
	 * inside a test-runner request (the isolated test application, in
	 * development or testing; a thread started during the run is in the same
	 * application) and baseUrl points at the test server. A client created
	 * outside a test run, such as in a scheduled task or a script, or one aimed
	 * at any other host, sends nothing extra.
	 */
	private void function $attachTestContext() {
		var ctx = new wheels.events.TestContext();
		if (!ctx.currentRequestIsIsolated() || !$isTestHost(variables.baseUrl)) {
			return;
		}
		var testSecret = ctx.testSecret();
		withHeader(ctx.headerName(), testSecret);
		withCookie(ctx.cookieName(), testSecret);
	}

	/**
	 * True when `target` points at the test server: its host is a loopback address
	 * (localhost, 127.x.x.x, [::1]) or the host of an explicitly configured test
	 * base URL (the testClientBaseUrl setting, -Dwheels.testClient.baseUrl, or
	 * WHEELS_TEST_CLIENT_BASE_URL). Hosts are compared exactly after the URL is
	 * parsed, with no DNS lookup, so localhost.example.com or
	 * 127.0.0.1.example.com do not match. Public for specs.
	 */
	public boolean function $isTestHost(required string target) {
		var host = $urlHost(arguments.target);
		if (!Len(host)) {
			return false;
		}
		if (host == "localhost" || host == "[::1]" || host == "::1" || $isLoopbackIPv4(host)) {
			return true;
		}
		for (var configured in $configuredTestBaseUrls()) {
			if (Compare($urlHost(configured), host) == 0) {
				return true;
			}
		}
		return false;
	}

	/**
	 * The lower-cased host of an absolute http(s) URL, or "" when it has none or
	 * is not one. Parsed with java.net.URI where the engine provides it, and
	 * with $lexicalUrlHost() otherwise (an engine without a JVM). Both paths
	 * first refuse anything $lexicalUrlHost() refuses: another scheme, or an
	 * authority holding a backslash, whitespace, '%' or a control character.
	 * Public for specs.
	 */
	public string function $urlHost(required string target) {
		var lexical = $lexicalUrlHost(arguments.target);
		if (!Len(lexical) || !$uriAvailable()) {
			return lexical;
		}
		var state = {host = ""};
		try {
			state.parsed = CreateObject("java", "java.net.URI").init(Trim(arguments.target)).getHost();
			if (!IsNull(state.parsed)) {
				state.host = LCase(state.parsed);
			}
		} catch (any e) {
			// Not a parseable absolute URL: no host.
		}
		return state.host;
	}

	/** True when java.net.URI can be created and parses a known URL. Public for specs. */
	public boolean function $uriAvailable() {
		var state = {ok = false};
		try {
			state.probe = CreateObject("java", "java.net.URI").init("http://localhost:1/").getHost();
			state.ok = !IsNull(state.probe) && Compare(state.probe, "localhost") == 0;
		} catch (any e) {
			// No JVM: java.net.URI is not available.
		}
		return state.ok;
	}

	/**
	 * The lower-cased host of an absolute http(s) URL, parsed without
	 * java.net.URI, or "" when it has none or is not one. The authority runs from
	 * '://' to the first '/', '?' or '#'; anything up to its LAST '@' is user
	 * information; a port must be digits; an IPv6 host keeps its brackets. An
	 * authority holding a backslash, whitespace, '%' or a control character is
	 * refused outright. Public for specs.
	 */
	public string function $lexicalUrlHost(required string target) {
		var raw = Trim(arguments.target);
		if (REFindNoCase("^https?://", raw) != 1) {
			return "";
		}
		var rest = Mid(raw, Find("://", raw) + 3, Len(raw));
		var cutAt = REFind("[/?##]", rest);
		var authority = rest;
		if (cutAt == 1) {
			return "";
		} else if (cutAt > 1) {
			authority = Left(rest, cutAt - 1);
		}
		if (!Len(authority) || !$isPlainAuthority(authority)) {
			return "";
		}
		var hostPort = authority;
		var atFromEnd = Find("@", Reverse(authority));
		if (atFromEnd > 0) {
			hostPort = Mid(authority, Len(authority) - atFromEnd + 2, Len(authority));
		}
		var host = "";
		var port = "";
		if (Left(hostPort, 1) == "[") {
			var closeAt = Find("]", hostPort);
			if (closeAt < 3) {
				return "";
			}
			host = Left(hostPort, closeAt);
			var afterHost = Mid(hostPort, closeAt + 1, Len(hostPort));
			if (Len(afterHost) && (Left(afterHost, 1) != ":")) {
				return "";
			}
			port = Len(afterHost) ? Mid(afterHost, 2, Len(afterHost)) : "";
			if (!REFind("^\[[0-9A-Fa-f:.]+\]$", host)) {
				return "";
			}
		} else {
			var colonAt = Find(":", hostPort);
			if (colonAt == 0) {
				host = hostPort;
			} else {
				host = colonAt > 1 ? Left(hostPort, colonAt - 1) : "";
				port = Mid(hostPort, colonAt + 1, Len(hostPort));
			}
			if (!$isHostName(host)) {
				return "";
			}
		}
		if (Len(port) && !REFind("^[0-9]{1,5}$", port)) {
			return "";
		}
		return LCase(host);
	}

	/**
	 * A host name or IPv4 address in the RFC 2396 sense java.net.URI applies:
	 * either four dot-separated numbers of 0-255, or dot-separated labels of
	 * letters, digits and inner hyphens whose last label starts with a letter.
	 */
	private boolean function $isHostName(required string host) {
		var labels = ListToArray(arguments.host, ".", true);
		if (!ArrayLen(labels)) {
			return false;
		}
		var allNumeric = true;
		for (var label in labels) {
			if (!REFind("^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$", label)) {
				return false;
			}
			if (!REFind("^[0-9]+$", label)) {
				allNumeric = false;
			}
		}
		if (allNumeric) {
			if (ArrayLen(labels) != 4) {
				return false;
			}
			for (var octet in labels) {
				if (Len(octet) > 3 || Val(octet) > 255) {
					return false;
				}
			}
			return true;
		}
		return REFind("^[A-Za-z]", labels[ArrayLen(labels)]) == 1;
	}

	/** False when the authority holds a backslash, whitespace, '%' or a control character. */
	private boolean function $isPlainAuthority(required string authority) {
		var i = 0;
		for (i = 1; i <= Len(arguments.authority); i++) {
			var ch = Mid(arguments.authority, i, 1);
			var code = Asc(ch);
			if (code <= 32 || code == 127 || ch == "\" || ch == "%") {
				return false;
			}
		}
		return true;
	}

	private boolean function $isLoopbackIPv4(required string host) {
		if (!ReFind("^127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$", arguments.host)) {
			return false;
		}
		for (var octet in ListToArray(arguments.host, ".")) {
			if (Val(octet) > 255) {
				return false;
			}
		}
		return true;
	}

	/** Test base URLs configured outside the request: the Wheels setting, the JVM property and the environment variable. */
	private array function $configuredTestBaseUrls() {
		var urls = [];
		if (
			StructKeyExists(application, "wheels")
			&& StructKeyExists(application.wheels, "testClientBaseUrl")
			&& IsSimpleValue(application.wheels.testClientBaseUrl)
			&& Len(application.wheels.testClientBaseUrl)
		) {
			ArrayAppend(urls, application.wheels.testClientBaseUrl);
		}
		var state = {};
		try {
			state.property = CreateObject("java", "java.lang.System").getProperty("wheels.testClient.baseUrl");
			if (!IsNull(state.property) && Len(state.property)) {
				ArrayAppend(urls, state.property);
			}
		} catch (any e) {
			// No JVM: no system property.
		}
		if (
			StructKeyExists(server, "system")
			&& StructKeyExists(server.system, "environment")
			&& StructKeyExists(server.system.environment, "WHEELS_TEST_CLIENT_BASE_URL")
			&& Len(server.system.environment.WHEELS_TEST_CLIENT_BASE_URL)
		) {
			ArrayAppend(urls, server.system.environment.WHEELS_TEST_CLIENT_BASE_URL);
		}
		return urls;
	}

	// ─── HTTP Methods ────────────────────────────────────────────────

	/**
	 * Make an HTTP GET request.
	 *
	 * @path    URL path (appended to baseUrl)
	 * @params  Query string parameters as a struct
	 * @headers Additional headers for this request
	 * @timeout cfhttp timeout in seconds (default 30). Lower it to bound a request that may hang so
	 *          the caller's assertion fails rather than the whole test leg timing out.
	 */
	public TestClient function get(
		required string path,
		struct params = {},
		struct headers = {},
		numeric timeout = 30
	) {
		$makeRequest(method = "GET", path = arguments.path, params = arguments.params, headers = arguments.headers, timeout = arguments.timeout);
		return this;
	}

	/**
	 * Make an HTTP POST request.
	 *
	 * @path    URL path (appended to baseUrl)
	 * @body    Request body as a struct
	 * @headers Additional headers for this request
	 */
	public TestClient function post(
		required string path,
		struct body = {},
		struct headers = {}
	) {
		$makeRequest(method = "POST", path = arguments.path, body = arguments.body, headers = arguments.headers);
		return this;
	}

	/**
	 * Make an HTTP PUT request.
	 *
	 * @path    URL path (appended to baseUrl)
	 * @body    Request body as a struct
	 * @headers Additional headers for this request
	 */
	public TestClient function put(
		required string path,
		struct body = {},
		struct headers = {}
	) {
		$makeRequest(method = "PUT", path = arguments.path, body = arguments.body, headers = arguments.headers);
		return this;
	}

	/**
	 * Make an HTTP PATCH request.
	 *
	 * @path    URL path (appended to baseUrl)
	 * @body    Request body as a struct
	 * @headers Additional headers for this request
	 */
	public TestClient function patch(
		required string path,
		struct body = {},
		struct headers = {}
	) {
		$makeRequest(method = "PATCH", path = arguments.path, body = arguments.body, headers = arguments.headers);
		return this;
	}

	/**
	 * Make an HTTP DELETE request.
	 *
	 * @path    URL path (appended to baseUrl)
	 * @headers Additional headers for this request
	 */
	public TestClient function delete(
		required string path,
		struct headers = {}
	) {
		$makeRequest(method = "DELETE", path = arguments.path, headers = arguments.headers);
		return this;
	}

	/**
	 * Alias for get(). Reads more naturally in tests: visit("/").assertOk()
	 *
	 * @path URL path (appended to baseUrl)
	 */
	public TestClient function visit(required string path) {
		return get(path = arguments.path);
	}

	// ─── Request Configuration ───────────────────────────────────────

	/**
	 * Set multiple default headers for subsequent requests.
	 *
	 * @headers Struct of header name/value pairs
	 */
	public TestClient function withHeaders(required struct headers) {
		structAppend(variables.defaultHeaders, arguments.headers, true);
		return this;
	}

	/**
	 * Set a single default header for subsequent requests.
	 *
	 * @name  Header name
	 * @value Header value
	 */
	public TestClient function withHeader(required string name, required string value) {
		variables.defaultHeaders[arguments.name] = arguments.value;
		return this;
	}

	/**
	 * Set the client address (REMOTE_ADDR) for subsequent requests, so per-client behaviour
	 * (RateLimiter, IP allow/deny rules) can be exercised. Sent as the X-Wheels-Test-Remote-Addr
	 * header; in the isolated test application (development/testing only) the framework maps it onto
	 * the middleware request context's `remoteAddr` field. It is ignored outside the isolated test
	 * context and never changes the cgi scope, so app code reading cgi.remote_addr directly is
	 * unaffected.
	 *
	 * @ip Client IP address the request should appear to come from.
	 */
	public TestClient function fromAddress(required string ip) {
		return withHeader("X-Wheels-Test-Remote-Addr", arguments.ip);
	}

	/**
	 * Set a cookie to send with subsequent requests.
	 *
	 * @name  Cookie name
	 * @value Cookie value
	 */
	public TestClient function withCookie(required string name, required string value) {
		// Kept URL-encoded, the form a server sets it in: the jar goes back out as
		// one Cookie header with each value as stored (see $cookieHeaderValue()).
		variables.cookies[arguments.name] = URLEncodedFormat(arguments.value);
		return this;
	}

	/**
	 * Configure the client to send and accept JSON.
	 * Sets Content-Type and Accept headers to application/json.
	 */
	public TestClient function asJson() {
		variables.sendAsJson = true;
		variables.defaultHeaders["Content-Type"] = "application/json";
		variables.defaultHeaders["Accept"] = "application/json";
		return this;
	}

	// ─── Assertions ──────────────────────────────────────────────────

	/**
	 * Assert the response has the given HTTP status code.
	 *
	 * @expectedStatus Expected HTTP status code
	 */
	public TestClient function assertStatus(required numeric expectedStatus) {
		var actual = statusCode();
		if (actual != arguments.expectedStatus) {
			$assertionError("Expected status code #arguments.expectedStatus# but received #actual#.");
		}
		return this;
	}

	/**
	 * Assert the response has HTTP 200 OK status.
	 */
	public TestClient function assertOk() {
		return assertStatus(200);
	}

	/**
	 * Assert the response has HTTP 201 Created status.
	 */
	public TestClient function assertCreated() {
		return assertStatus(201);
	}

	/**
	 * Assert the response has HTTP 204 No Content status.
	 */
	public TestClient function assertNoContent() {
		return assertStatus(204);
	}

	/**
	 * Assert the response has HTTP 404 Not Found status.
	 */
	public TestClient function assertNotFound() {
		return assertStatus(404);
	}

	/**
	 * Assert the response is a redirect (3xx status).
	 * Optionally check the Location header matches a given path.
	 *
	 * @to Optional expected Location header value
	 */
	public TestClient function assertRedirect(string to = "") {
		var code = statusCode();
		if (code < 300 || code >= 400) {
			$assertionError("Expected redirect status (3xx) but received #code#.");
		}
		if (Len(arguments.to)) {
			var hdrs = headers();
			var loc = "";
			if (StructKeyExists(hdrs, "Location")) {
				loc = hdrs.Location;
			}
			if (!FindNoCase(arguments.to, loc)) {
				$assertionError("Expected redirect to '#arguments.to#' but Location header is '#loc#'.");
			}
		}
		return this;
	}

	/**
	 * Assert the response body contains the given text.
	 *
	 * @text Text to search for in the response body
	 */
	public TestClient function assertSee(required string text) {
		var body = content();
		if (!FindNoCase(arguments.text, body)) {
			$assertionError("Expected to see '#arguments.text#' in response body but it was not found.");
		}
		return this;
	}

	/**
	 * Assert the response body does NOT contain the given text.
	 *
	 * @text Text that should be absent from the response body
	 */
	public TestClient function assertDontSee(required string text) {
		var body = content();
		if (FindNoCase(arguments.text, body)) {
			$assertionError("Expected NOT to see '#arguments.text#' in response body but it was found.");
		}
		return this;
	}

	/**
	 * Assert the given texts appear in the response body in order.
	 *
	 * @texts Array of strings that should appear in order
	 */
	public TestClient function assertSeeInOrder(required array texts) {
		var body = content();
		var lastPos = 0;
		for (var i = 1; i <= ArrayLen(arguments.texts); i++) {
			var text = arguments.texts[i];
			var pos = FindNoCase(text, body, lastPos + 1);
			if (pos == 0) {
				$assertionError("Expected to see '#text#' in order in response body (item #i# of #ArrayLen(arguments.texts)#) but it was not found after position #lastPos#.");
			}
			// Advance past the full match so the next text can't match
			// inside the previous one (e.g. ["John Smith", "Smith"] must
			// not pass against a single "John Smith" occurrence).
			lastPos = pos + Len(text) - 1;
		}
		return this;
	}

	/**
	 * Assert the response is valid JSON. Optionally assert it contains
	 * a subset of the expected key/value pairs.
	 *
	 * @expected Optional struct of expected key/value pairs to match
	 */
	public TestClient function assertJson(struct expected = {}) {
		var parsed = "";
		try {
			parsed = $parsedJson();
		} catch (any e) {
			$assertionError("Expected response to be valid JSON but could not parse it. Body: #Left(content(), 200)#");
		}
		if (!StructIsEmpty(arguments.expected)) {
			// Guard before StructKeyExists: a top-level JSON array (the normal
			// list-API response shape) would otherwise throw an engine cast
			// error instead of reporting a test failure.
			if (!IsStruct(parsed)) {
				var shape = IsArray(parsed) ? "a JSON array" : "a simple value";
				$assertionError("Expected JSON response to be an object so keys can be matched, but it deserialized to #shape#.");
			}
			for (var key in arguments.expected) {
				if (!StructKeyExists(parsed, key)) {
					$assertionError("Expected JSON response to contain key '#key#' but it was not found.");
				}
				if (!$jsonValuesMatch(parsed[key], arguments.expected[key])) {
					$assertionError("Expected JSON key '#key#' to be '#$describeJsonValue(arguments.expected[key])#' but got '#$describeJsonValue(parsed[key])#'.");
				}
			}
		}
		return this;
	}

	/**
	 * Assert a value at a dot-notation path in the JSON response.
	 * Array indices are 1-based (matching CFML convention).
	 *
	 * Example: assertJsonPath("users.1.name", "John")
	 *
	 * @path          Dot-notation path into the JSON structure
	 * @expectedValue Expected value at that path
	 */
	public TestClient function assertJsonPath(required string path, any expectedValue) {
		var parsed = "";
		try {
			parsed = $parsedJson();
		} catch (any e) {
			$assertionError("Expected response to be valid JSON for path assertion. Body: #Left(content(), 200)#");
		}
		var segments = ListToArray(arguments.path, ".");
		var current = parsed;
		for (var i = 1; i <= ArrayLen(segments); i++) {
			var segment = segments[i];
			if (IsNumeric(segment) && IsArray(current)) {
				var idx = Int(segment);
				if (idx < 1 || idx > ArrayLen(current)) {
					$assertionError("JSON path '#arguments.path#' failed: array index #segment# is out of bounds (array length: #ArrayLen(current)#).");
				}
				current = current[idx];
			} else if (IsStruct(current) && StructKeyExists(current, segment)) {
				current = current[segment];
			} else {
				$assertionError("JSON path '#arguments.path#' failed: key '#segment#' not found at this level.");
			}
		}
		if (!$jsonValuesMatch(current, arguments.expectedValue)) {
			$assertionError("Expected JSON path '#arguments.path#' to be '#$describeJsonValue(arguments.expectedValue)#' but got '#$describeJsonValue(current)#'.");
		}
		return this;
	}

	/**
	 * Assert a response header exists and optionally matches a value.
	 *
	 * @name  Header name to check
	 * @value Optional expected header value
	 */
	public TestClient function assertHeader(required string name, string value = "") {
		var hdrs = headers();
		if (!StructKeyExists(hdrs, arguments.name)) {
			$assertionError("Expected response to have header '#arguments.name#' but it was not found.");
		}
		if (Len(arguments.value) && hdrs[arguments.name] != arguments.value) {
			$assertionError("Expected header '#arguments.name#' to be '#arguments.value#' but got '#hdrs[arguments.name]#'.");
		}
		return this;
	}

	/**
	 * Assert a cookie exists in the response and optionally matches a value.
	 *
	 * @name  Cookie name to check
	 * @value Optional expected cookie value
	 */
	public TestClient function assertCookie(required string name, string value = "") {
		var responseCookies = {};
		if (StructKeyExists(variables.lastResponse, "cookies")) {
			responseCookies = variables.lastResponse.cookies;
		}
		if (!StructKeyExists(responseCookies, arguments.name)) {
			$assertionError("Expected response to have cookie '#arguments.name#' but it was not found.");
		}
		if (Len(arguments.value) && responseCookies[arguments.name] != arguments.value) {
			$assertionError("Expected cookie '#arguments.name#' to be '#arguments.value#' but got '#responseCookies[arguments.name]#'.");
		}
		return this;
	}

	// ─── Response Accessors ──────────────────────────────────────────

	/**
	 * Get the full response struct from the last request.
	 */
	public struct function response() {
		return variables.lastResponse;
	}

	/**
	 * Get the response body as a string. Memoized per response — the
	 * cache is invalidated whenever a new response arrives.
	 */
	public string function content() {
		if (!variables.contentCached) {
			if (StructKeyExists(variables.lastResponse, "fileContent")) {
				variables.contentCache = ToString(variables.lastResponse.fileContent);
			} else {
				variables.contentCache = "";
			}
			variables.contentCached = true;
		}
		return variables.contentCache;
	}

	/**
	 * Get the HTTP status code of the last response.
	 */
	public numeric function statusCode() {
		if (StructKeyExists(variables.lastResponse, "statusCode")) {
			// cfhttp returns statusCode as "200 OK" — extract the numeric part
			var raw = ToString(variables.lastResponse.statusCode);
			return Val(raw);
		}
		return 0;
	}

	/**
	 * Parse and return the JSON response body as a struct/array.
	 */
	public any function json() {
		var body = content();
		if (!Len(body)) {
			return {};
		}
		try {
			return $parsedJson();
		} catch (any e) {
			$assertionError("Cannot parse response body as JSON. Body: #Left(body, 200)#");
		}
	}

	/**
	 * Get the response headers as a struct.
	 */
	public struct function headers() {
		if (StructKeyExists(variables.lastResponse, "responseHeader")) {
			return variables.lastResponse.responseHeader;
		}
		return {};
	}

	// ─── Test Helpers ────────────────────────────────────────────

	/**
	 * Set a fake response for unit-testing assertions without making HTTP calls.
	 * Used by test specs to verify assertion logic in isolation.
	 */
	public void function $setFakeResponse(
		string statusCode = "200 OK",
		string fileContent = "",
		struct responseHeader = {}
	) {
		variables.lastResponse = {
			statusCode: arguments.statusCode,
			fileContent: arguments.fileContent,
			responseHeader: arguments.responseHeader
		};
		$clearResponseCaches();
	}

	// ─── Private Helpers ─────────────────────────────────────────────

	/**
	 * Execute an HTTP request using cfhttp.
	 *
	 * @method  HTTP method (GET, POST, PUT, PATCH, DELETE)
	 * @path    URL path
	 * @params  Query string parameters
	 * @body    Request body struct
	 * @headers Per-request headers
	 */
	private void function $makeRequest(
		required string method,
		required string path,
		struct params = {},
		struct body = {},
		struct headers = {},
		numeric timeout = 30
	) {
		$requireLeadingSlash(arguments.path);

		var fullUrl = variables.baseUrl & arguments.path;

		// Append query string params to the URL
		if (!StructIsEmpty(arguments.params)) {
			var qs = [];
			for (var key in arguments.params) {
				ArrayAppend(qs, EncodeForURL(key) & "=" & EncodeForURL(arguments.params[key]));
			}
			var separator = Find("?", fullUrl) ? "&" : "?";
			fullUrl = fullUrl & separator & ArrayToList(qs, "&");
		}

		// Merge default headers with per-request headers
		var mergedHeaders = StructCopy(variables.defaultHeaders);
		StructAppend(mergedHeaders, arguments.headers, true);

		// The cookie jar goes out as one Cookie header, each value exactly as the
		// server set it, as a browser sends it. Not cfhttpparam type="cookie": it
		// URL-encodes the value again, so a value the server had already encoded
		// (Adobe sends a+b as a%2Bb) arrived double-encoded and unreadable.
		if (!StructIsEmpty(variables.cookies)) {
			var cookieHeaderName = "Cookie";
			for (var headerKey in mergedHeaders) {
				if (CompareNoCase(headerKey, "Cookie") == 0) {
					cookieHeaderName = headerKey;
				}
			}
			var jarValue = $cookieHeaderValue();
			mergedHeaders[cookieHeaderName] = StructKeyExists(mergedHeaders, cookieHeaderName) && Len(mergedHeaders[cookieHeaderName])
				? mergedHeaders[cookieHeaderName] & "; " & jarValue
				: jarValue;
		}

		var result = {};

		cfhttp(url = fullUrl, method = arguments.method, timeout = arguments.timeout, result = "result", redirect = false) {
			// Add merged headers
			for (var hName in mergedHeaders) {
				cfhttpparam(type = "header", name = hName, value = mergedHeaders[hName]);
			}


			// Add body for POST/PUT/PATCH. Adobe CF rejects a POST/PUT/PATCH
			// cfhttp with zero cfhttpparam tags ("requires at least one
			// cfhttpparam tag for a POST operation"), so always emit a body
			// param for these methods — an empty body is valid — instead of
			// skipping when the body struct is empty.
			if (ListFindNoCase("POST,PUT,PATCH", arguments.method)) {
				if (!StructIsEmpty(arguments.body) && !variables.sendAsJson) {
					for (var fName in arguments.body) {
						cfhttpparam(type = "formfield", name = fName, value = arguments.body[fName]);
					}
				} else {
					// This branch covers both JSON posts (any body) and empty-body
					// form posts — the latter still needs a body param so the POST
					// isn't left with zero cfhttpparam tags.
					cfhttpparam(type = "body", value = StructIsEmpty(arguments.body) ? "" : SerializeJSON(arguments.body));
				}
			}
		}

		variables.lastResponse = result;
		$clearResponseCaches();

		// Track cookies from response for subsequent requests (session support)
		if (StructKeyExists(result, "responseHeader") && IsStruct(result.responseHeader)) {
			$absorbSetCookies(result.responseHeader);
		}
	}

	/**
	 * Keep each Set-Cookie's name=value for later requests (session support).
	 * cfhttp hands Set-Cookie over as a simple value (one cookie), an array
	 * (Lucee), or a struct keyed "1", "2", … (Adobe CF). A for-in over that
	 * struct walks its keys, not the cookies, so on Adobe no cookie was kept and
	 * every request started a new session. Public for specs ($-prefixed).
	 */
	public void function $absorbSetCookies(required struct responseHeader) {
		if (!StructKeyExists(arguments.responseHeader, "Set-Cookie")) {
			return;
		}
		var raw = arguments.responseHeader["Set-Cookie"];
		var headerValues = [];
		if (IsSimpleValue(raw)) {
			headerValues = [raw];
		} else if (IsArray(raw)) {
			headerValues = raw;
		} else if (IsStruct(raw)) {
			var keys = StructKeyArray(raw);
			var allNumeric = true;
			for (var key in keys) {
				if (!IsNumeric(key)) {
					allNumeric = false;
				}
			}
			ArraySort(keys, allNumeric ? "numeric" : "textnocase");
			for (var key in keys) {
				ArrayAppend(headerValues, raw[key]);
			}
		}
		for (var cookieStr in headerValues) {
			if (!IsSimpleValue(cookieStr)) {
				continue;
			}
			var cookieParts = ListToArray(cookieStr, ";");
			if (ArrayLen(cookieParts)) {
				var pair = Trim(cookieParts[1]);
				var eqPos = Find("=", pair);
				if (eqPos > 0) {
					variables.cookies[Left(pair, eqPos - 1)] = Mid(pair, eqPos + 1, Len(pair) - eqPos);
				}
			}
		}
	}

	/**
	 * The Cookie header for the jar: name=value pairs, values as stored. Public
	 * for specs ($-prefixed).
	 */
	public string function $cookieHeaderValue() {
		var pairs = [];
		for (var name in variables.cookies) {
			ArrayAppend(pairs, name & "=" & variables.cookies[name]);
		}
		return ArrayToList(pairs, "; ");
	}

	/**
	 * A copy of the cookies this client sends, values as sent. Public for specs
	 * ($-prefixed).
	 */
	public struct function $cookieJar() {
		return Duplicate(variables.cookies);
	}

	/**
	 * Reject paths without a leading slash. Without this guard,
	 * visit("users") silently produced "http://localhost:8080users",
	 * which failed to connect and surfaced as a misleading
	 * "Expected 200 but received 0." failure.
	 *
	 * @path URL path to validate
	 */
	private void function $requireLeadingSlash(required string path) {
		if (Left(arguments.path, 1) != "/") {
			Throw(
				type = "Wheels.TestClientInvalidPath",
				message = "TestClient paths must start with '/': " & arguments.path
			);
		}
	}

	/**
	 * Parse and memoize the JSON response body. Throws if the body is not
	 * valid JSON — callers wrap this in try/catch to report a test failure.
	 */
	private any function $parsedJson() {
		if (!variables.jsonCached) {
			variables.jsonCache = DeserializeJSON(content());
			variables.jsonCached = true;
		}
		return variables.jsonCache;
	}

	/**
	 * Invalidate the memoized body string and parsed JSON. Called whenever
	 * variables.lastResponse changes.
	 */
	private void function $clearResponseCaches() {
		variables.contentCached = false;
		variables.contentCache = "";
		variables.jsonCached = false;
		variables.jsonCache = "";
	}

	/**
	 * Compare an actual JSON value against an expected one. Simple values
	 * use plain equality; struct/array values are compared via
	 * SerializeJSON, because a raw != on complex values throws an engine
	 * "can't compare complex object types" error.
	 */
	private boolean function $jsonValuesMatch(any actual, any expected) {
		var actualIsNull = IsNull(arguments.actual);
		var expectedIsNull = IsNull(arguments.expected);
		if (actualIsNull || expectedIsNull) {
			return actualIsNull && expectedIsNull;
		}
		if (IsSimpleValue(arguments.actual) && IsSimpleValue(arguments.expected)) {
			return arguments.actual == arguments.expected;
		}
		if (IsSimpleValue(arguments.actual) || IsSimpleValue(arguments.expected)) {
			return false;
		}
		return SerializeJSON(arguments.actual) == SerializeJSON(arguments.expected);
	}

	/**
	 * Render a JSON value for assertion messages without crashing on
	 * struct/array values.
	 */
	private string function $describeJsonValue(any jsonValue) {
		if (IsNull(arguments.jsonValue)) {
			return "null";
		}
		if (IsSimpleValue(arguments.jsonValue)) {
			return ToString(arguments.jsonValue);
		}
		return SerializeJSON(arguments.jsonValue);
	}

	/**
	 * Throw a typed exception for assertion failures.
	 * TestBox catches these as test failures.
	 *
	 * @message Descriptive error message
	 */
	private void function $assertionError(required string message) {
		Throw(type = "TestBox.AssertionFailed", message = arguments.message);
	}

}
