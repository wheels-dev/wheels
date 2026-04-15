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

	/**
	 * Initialize the test client with a base URL.
	 *
	 * @baseUrl The base URL for all requests (e.g. "http://localhost:8080")
	 */
	public TestClient function init(string baseUrl = "http://localhost:8080") {
		variables.baseUrl = arguments.baseUrl;
		variables.lastResponse = {};
		variables.defaultHeaders = {};
		variables.cookies = {};
		variables.sendAsJson = false;
		return this;
	}

	// ─── HTTP Methods ────────────────────────────────────────────────

	/**
	 * Make an HTTP GET request.
	 *
	 * @path    URL path (appended to baseUrl)
	 * @params  Query string parameters as a struct
	 * @headers Additional headers for this request
	 */
	public TestClient function get(
		required string path,
		struct params = {},
		struct headers = {}
	) {
		$makeRequest(method = "GET", path = arguments.path, params = arguments.params, headers = arguments.headers);
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
	 * Set a cookie to send with subsequent requests.
	 *
	 * @name  Cookie name
	 * @value Cookie value
	 */
	public TestClient function withCookie(required string name, required string value) {
		variables.cookies[arguments.name] = arguments.value;
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
	 * @statusCode Expected HTTP status code
	 */
	public TestClient function assertStatus(required numeric statusCode) {
		var actual = statusCode();
		if (actual != arguments.statusCode) {
			$assertionError("Expected status code #arguments.statusCode# but received #actual#.");
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
			lastPos = pos;
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
		var body = content();
		var parsed = {};
		try {
			parsed = DeserializeJSON(body);
		} catch (any e) {
			$assertionError("Expected response to be valid JSON but could not parse it. Body: #Left(body, 200)#");
		}
		if (!StructIsEmpty(arguments.expected)) {
			for (var key in arguments.expected) {
				if (!StructKeyExists(parsed, key)) {
					$assertionError("Expected JSON response to contain key '#key#' but it was not found.");
				}
				if (parsed[key] != arguments.expected[key]) {
					$assertionError("Expected JSON key '#key#' to be '#arguments.expected[key]#' but got '#parsed[key]#'.");
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
		var body = content();
		var parsed = {};
		try {
			parsed = DeserializeJSON(body);
		} catch (any e) {
			$assertionError("Expected response to be valid JSON for path assertion. Body: #Left(body, 200)#");
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
		if (current != arguments.expectedValue) {
			$assertionError("Expected JSON path '#arguments.path#' to be '#arguments.expectedValue#' but got '#current#'.");
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
	 * Get the response body as a string.
	 */
	public string function content() {
		if (StructKeyExists(variables.lastResponse, "fileContent")) {
			return ToString(variables.lastResponse.fileContent);
		}
		return "";
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
			return DeserializeJSON(body);
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
		struct headers = {}
	) {
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

		var result = {};

		cfhttp(url = fullUrl, method = arguments.method, timeout = "30", result = "result", redirect = false) {
			// Add merged headers
			for (var hName in mergedHeaders) {
				cfhttpparam(type = "header", name = hName, value = mergedHeaders[hName]);
			}

			// Add cookies
			for (var cName in variables.cookies) {
				cfhttpparam(type = "cookie", name = cName, value = variables.cookies[cName]);
			}

			// Add body for POST/PUT/PATCH
			if (ListFindNoCase("POST,PUT,PATCH", arguments.method) && !StructIsEmpty(arguments.body)) {
				if (variables.sendAsJson) {
					cfhttpparam(type = "body", value = SerializeJSON(arguments.body));
				} else {
					for (var fName in arguments.body) {
						cfhttpparam(type = "formfield", name = fName, value = arguments.body[fName]);
					}
				}
			}
		}

		variables.lastResponse = result;

		// Track cookies from response for subsequent requests (session support)
		if (StructKeyExists(result, "responseHeader") && StructKeyExists(result.responseHeader, "Set-Cookie")) {
			var setCookieHeader = result.responseHeader["Set-Cookie"];
			if (IsSimpleValue(setCookieHeader)) {
				setCookieHeader = [setCookieHeader];
			}
			for (var cookieStr in setCookieHeader) {
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
