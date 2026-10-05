/**
 * Agent-readable development errors. In the development environment, an error
 * response asked for as JSON (Accept: application/json or ?format=json) is the
 * structured ErrorCopyPayload the error page's Copy button builds, and one asked
 * for as Markdown (Accept: text/markdown without application/json, or ?format=md)
 * is the same content as Markdown. Testing and production bodies are exactly what
 * they were. Runs the live $runOnError through OnErrorEventDouble, which records
 * headers instead of writing them.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Development: agent-readable error bodies", () => {

			beforeEach(() => {
				_saved = {environment = application.wheels.environment, showErrorInformation = application.wheels.showErrorInformation};
				application.wheels.environment = "development";
				application.wheels.showErrorInformation = true;
			});

			afterEach(() => {
				application.wheels.environment = _saved.environment;
				application.wheels.showErrorInformation = _saved.showErrorInformation;
			});

			it("answers JSON with the error-page payload, its status and a lower-case-key body", () => {
				var em = $double();
				em.formatOverride = "json";
				var body = em.$runOnError(exception = $wheelsTypedException("Wheels.RecordNotFound"), eventName = "onRequest");
				var payload = DeserializeJSON(body);
				expect(em.$lastStatusCode()).toBe(404);
				expect($contentType(em)).toBe("application/json; charset=utf-8");
				expect(payload.source).toBe("wheels-error-page");
				expect(payload.exception.type).toBe("Wheels.RecordNotFound");
				expect(payload.statusCode).toBe(404);
				expect(body).toInclude('"source":"wheels-error-page"');
				expect(body).toInclude('"exception":{');
				// What the request wrote before it failed is dropped.
				expect(em.contentResets).toBe(1);
			});

			it("answers JSON for a non-Wheels exception with status 500", () => {
				var em = $double();
				em.formatOverride = "json";
				var payload = DeserializeJSON(em.$runOnError(exception = $plainException(), eventName = "onRequest"));
				expect(em.$lastStatusCode()).toBe(500);
				expect(payload.source).toBe("wheels-error-page");
				expect(payload.exception.message).toBe("plain failure");
			});

			it("answers Markdown for Accept: text/markdown", () => {
				var em = $double();
				em.formatOverride = "html";
				em.acceptHeader = "text/markdown, text/plain;q=0.5";
				var body = em.$runOnError(exception = $wheelsTypedException("Wheels.RecordNotFound"), eventName = "onRequest");
				expect(em.$lastStatusCode()).toBe(404);
				expect($contentType(em)).toBe("text/markdown; charset=utf-8");
				// The heading: Chr(35) is the Markdown heading mark (a bare one starts a CFML expression).
				expect(Left(body, 25)).toBe(Chr(35) & " Wheels.RecordNotFound: ");
			});

			it("answers Markdown for ?format=md", () => {
				var em = $double();
				em.formatOverride = "md";
				em.formatParam = "md";
				var body = em.$runOnError(exception = $plainException(), eventName = "onRequest");
				expect($contentType(em)).toBe("text/markdown; charset=utf-8");
				expect(body).toInclude("plain failure");
			});

			it("prefers JSON when the Accept header lists JSON and Markdown", () => {
				var em = $double();
				em.formatOverride = "html";
				em.acceptHeader = "text/markdown, application/json";
				var body = em.$runOnError(exception = $plainException(), eventName = "onRequest");
				expect($contentType(em)).toBe("application/json; charset=utf-8");
				expect(DeserializeJSON(body).source).toBe("wheels-error-page");
			});

			it("is gated on the environment, not on showErrorInformation", () => {
				application.wheels.showErrorInformation = false;
				var em = $double();
				em.formatOverride = "json";
				expect(DeserializeJSON(em.$runOnError(exception = $plainException(), eventName = "onRequest")).source).toBe("wheels-error-page");
			});

			it("leaves an HTML request on the error page", () => {
				var em = $double();
				em.formatOverride = "html";
				var typed = $wheelsTypedException("Wheels.RecordNotFound");
				expect(em.$runOnError(exception = typed, eventName = "onRequest")).toBe($todaysWheelsErrorBody(typed, "html"));
			});

			it("falls back to the type and message when building the payload fails", () => {
				var em = $double();
				em.formatOverride = "json";
				em.payloadShouldThrow = true;
				var payload = DeserializeJSON(em.$runOnError(exception = $wheelsTypedException("Wheels.RecordNotFound"), eventName = "onRequest"));
				expect(em.$lastStatusCode()).toBe(404);
				expect(payload.source).toBe("wheels-error-page");
				expect(payload.exception.type).toBe("Wheels.RecordNotFound");
				var md = $double();
				md.formatOverride = "md";
				md.formatParam = "md";
				md.payloadShouldThrow = true;
				expect(md.$runOnError(exception = $plainException(), eventName = "onRequest")).toInclude("plain failure");
			});

		});

		describe("Testing and production: error bodies unchanged", () => {

			beforeEach(() => {
				_saved = {environment = application.wheels.environment, showErrorInformation = application.wheels.showErrorInformation};
			});

			afterEach(() => {
				application.wheels.environment = _saved.environment;
				application.wheels.showErrorInformation = _saved.showErrorInformation;
			});

			it("testing: JSON is still the raw serialized error, byte for byte", () => {
				application.wheels.environment = "testing";
				application.wheels.showErrorInformation = true;
				var em = $double();
				em.formatOverride = "json";
				var plain = $plainException();
				expect(em.$runOnError(exception = plain, eventName = "onRequest")).toBe(SerializeJSON(plain));
				var typed = $wheelsTypedException("Wheels.RecordNotFound");
				var resolved = em.$runOnErrorResolveWheelsError(typed);
				expect(em.$runOnError(exception = typed, eventName = "onRequest")).toBe(SerializeJSON(resolved));
			});

			it("testing: a Markdown request gets today's response, not the payload", () => {
				application.wheels.environment = "testing";
				application.wheels.showErrorInformation = true;
				var em = $double();
				em.formatOverride = "md";
				em.formatParam = "md";
				em.acceptHeader = "text/markdown";
				var typed = $wheelsTypedException("Wheels.RecordNotFound");
				var body = em.$runOnError(exception = typed, eventName = "onRequest");
				expect(body).toBe($todaysWheelsErrorBody(typed, "md"));
				expect(body).notToInclude("wheels-error-page");
			});

			it("production: JSON and Markdown requests get the app's error template", () => {
				application.wheels.environment = "production";
				application.wheels.showErrorInformation = false;
				var em = $double();
				em.formatOverride = "json";
				expect(em.$runOnError(exception = $plainException(), eventName = "onRequest")).toBe("on-error-double-body");
				var md = $double();
				md.formatOverride = "md";
				md.formatParam = "md";
				md.acceptHeader = "text/markdown";
				expect(md.$runOnError(exception = $plainException(), eventName = "onRequest")).toBe("on-error-double-body");
			});

		});

	}

	// What the unchanged Wheels-error renderer produces for a format: the oracle for
	// "today's response" on the paths this change must not touch.
	private string function $todaysWheelsErrorBody(required struct exception, required string format) {
		var em = $double();
		return em.$runOnErrorRenderWheelsError(em.$runOnErrorResolveWheelsError(arguments.exception), arguments.format);
	}

	private any function $double() {
		return CreateObject("component", "wheels.tests._assets.events.OnErrorEventDouble").init();
	}

	private string function $contentType(required any em) {
		var rv = "";
		for (var call in arguments.em.headerCalls) {
			if (StructKeyExists(call, "name") && call.name == "Content-Type") {
				rv = call.value;
			}
		}
		return rv;
	}

	private struct function $wheelsTypedException(required string wheelsType) {
		return {
			type = arguments.wheelsType,
			message = arguments.wheelsType,
			rootCause = {type = arguments.wheelsType, message = arguments.wheelsType}
		};
	}

	private struct function $plainException() {
		return {type = "java.lang.IllegalStateException", message = "plain failure", detail = "detail text"};
	}

}
