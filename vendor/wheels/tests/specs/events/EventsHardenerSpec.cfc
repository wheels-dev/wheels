/**
 * Events hardener desks S2–S7 (S1 lives in interfaceBootstrapSpec;
 * S8 lives in TestContextIsolationSpec). Desk IDs are locked.
 *
 * Directory-scoped so `wheels test --core --ci --filter=events` discovers it.
 *
 * FIX: S1 assert on $verifyInterfaceContracts (interfaceBootstrapSpec).
 * PROVE: S2 live $runOnError status map, S3 $mail swallow, S6 writeLog
 * swallow, S7 wheelserror.cfm keep-going cfcatch.
 * HOLD / PIN: S4 non-Wheels JSON/XML serializes the full exception;
 * S5 OPTIONS abort stays, skipped when Cors middleware is active.
 * S9 leftover: do not split $runOnError / $runOnRequestStart.
 * S10 leftover: SecurityDefaultsSpec / reloadPasswordSpec already proven.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("S2 live $runOnError status map (not a mirrored regex)", () => {

			beforeEach(() => {
				_savedShowError = application.wheels.showErrorInformation;
				application.wheels.showErrorInformation = true;
			});

			afterEach(() => {
				application.wheels.showErrorInformation = _savedShowError;
			});

			it("EventMethods.$runOnError source holds the frozen 404/403/500 map", () => {
				var body = $functionBody("EventMethods.cfc", "$runOnError");
				expect(Find('ReFindNoCase("^Wheels\.([A-Za-z]*NotFound|ActionNotAllowed)$"', body)).toBeGT(
					0,
					"live $runOnError no longer maps Wheels.*NotFound / ActionNotAllowed via the frozen regex"
				);
				expect(Find('ReFindNoCase("^Wheels\.NotAuthorized$"', body)).toBeGT(
					0,
					"live $runOnError no longer maps Wheels.NotAuthorized via the frozen regex"
				);
				expect(Find("$header(statusCode = 404)", body)).toBeGT(0);
				expect(Find("$header(statusCode = 403)", body)).toBeGT(0);
				expect(Find("$header(statusCode = 500)", body)).toBeGT(0);
				var pos404 = Find("$header(statusCode = 404)", body);
				var pos403 = Find("$header(statusCode = 403)", body);
				expect(pos403).toBeGT(pos404, "403 mapping must follow the 404 *NotFound / ActionNotAllowed branch");
			});

			it("maps Wheels.RouteNotFound to 404 through live $runOnError", () => {
				var em = $onErrorDouble();
				em.$runOnError(exception = $wheelsTypedException("Wheels.RouteNotFound"), eventName = "onRequest");
				expect(em.$lastStatusCode()).toBe(404);
			});

			it("maps Wheels.ActionNotAllowed to 404 through live $runOnError", () => {
				var em = $onErrorDouble();
				em.$runOnError(exception = $wheelsTypedException("Wheels.ActionNotAllowed"), eventName = "onRequest");
				expect(em.$lastStatusCode()).toBe(404);
			});

			it("maps Wheels.NotAuthorized to 403 through live $runOnError", () => {
				var em = $onErrorDouble();
				em.$runOnError(exception = $wheelsTypedException("Wheels.NotAuthorized"), eventName = "onRequest");
				expect(em.$lastStatusCode()).toBe(403);
			});

			it("maps a generic Wheels type to 500 through live $runOnError", () => {
				var em = $onErrorDouble();
				em.$runOnError(exception = $wheelsTypedException("Wheels.UnknownThingHappened"), eventName = "onRequest");
				expect(em.$lastStatusCode()).toBe(500);
			});

		});

		describe("S3 $mail catch-any swallow stays (does not rethrow)", () => {

			beforeEach(() => {
				_savedSendEmail = application.wheels.sendEmailOnError;
				_savedFrom = application.wheels.errorEmailFromAddress;
				_savedTo = application.wheels.errorEmailToAddress;
				_savedAddr = application.wheels.errorEmailAddress;
				_savedShowError = application.wheels.showErrorInformation;
				application.wheels.sendEmailOnError = true;
				application.wheels.errorEmailFromAddress = "from@example.com";
				application.wheels.errorEmailToAddress = "to@example.com";
				application.wheels.errorEmailAddress = "webmaster@example.com";
				application.wheels.showErrorInformation = true;
			});

			afterEach(() => {
				application.wheels.sendEmailOnError = _savedSendEmail;
				application.wheels.errorEmailFromAddress = _savedFrom;
				application.wheels.errorEmailToAddress = _savedTo;
				application.wheels.errorEmailAddress = _savedAddr;
				application.wheels.showErrorInformation = _savedShowError;
			});

			it("does not rethrow when $mail fails inside $runOnError", () => {
				var em = $onErrorDouble();
				em.mailShouldThrow = true;
				var state = {threw = false, type = "", result = ""};
				try {
					state.result = em.$runOnError(
						exception = $plainException(),
						eventName = "onRequest"
					);
				} catch (any e) {
					state.threw = true;
					state.type = e.type;
				}
				expect(em.mailCalls).toBe(1, "$runOnError must reach $mail when sendEmailOnError is on");
				expect(state.threw).toBeFalse(
					"$mail catch-any must swallow (got #state.type#)"
				);
				expect(state.result).toInclude("full-exception-secret-detail");
			});

			it("keeps the empty catch-any around $mail in EventMethods source", () => {
				var body = $functionBody("EventMethods.cfc", "$runOnError");
				var mailPos = Find("$mail(argumentCollection", body);
				expect(mailPos).toBeGT(0, "$runOnError no longer calls $mail");
				var window = Mid(body, mailPos, 180);
				expect(Find("catch (any e)", window)).toBeGT(0);
				expect(FindNoCase("rethrow", window)).toBe(0);
				expect(FindNoCase("throw(", window)).toBe(0);
			});

		});

		describe("S4 HOLD pin: non-Wheels JSON/XML serializes the full exception", () => {

			beforeEach(() => {
				_savedShowError = application.wheels.showErrorInformation;
				application.wheels.showErrorInformation = true;
			});

			afterEach(() => {
				application.wheels.showErrorInformation = _savedShowError;
			});

			it("JSON error body is SerializeJSON of the raw exception, not a redacted struct", () => {
				var em = $onErrorDouble();
				em.formatOverride = "json";
				var exception = $plainException();
				var result = em.$runOnError(exception = exception, eventName = "onRequest");
				expect(em.$lastStatusCode()).toBe(500);
				expect(result).toInclude("full-exception-secret-detail");
				expect(result).toInclude("password=hunter2");
				expect(result).toInclude("java.sql.SQLException");
			});

			it("XML error body is $toXml of the raw exception, not a redacted struct", () => {
				var em = $onErrorDouble();
				em.formatOverride = "xml";
				var result = em.$runOnError(exception = $plainException(), eventName = "onRequest");
				expect(em.$lastStatusCode()).toBe(500);
				var xmlText = IsSimpleValue(result) ? result : ToString(result);
				expect(xmlText).toInclude("full-exception-secret-detail");
				expect(xmlText).toInclude("password=hunter2");
			});

			it("live $runOnError source serializes arguments.exception (HOLD: no redact flip)", () => {
				var body = $functionBody("EventMethods.cfc", "$runOnError");
				expect(Find("SerializeJSON(arguments.exception)", body)).toBeGT(
					0,
					"non-Wheels JSON path must keep SerializeJSON(arguments.exception)"
				);
				expect(Find("$toXml(arguments.exception)", body)).toBeGT(
					0,
					"non-Wheels XML path must keep $toXml(arguments.exception)"
				);
			});

		});

		describe("S5 HOLD pin: OPTIONS abort skipped when Cors middleware is active", () => {

			beforeEach(() => {
				_savedMiddleware = StructKeyExists(application.wheels, "middleware")
					? Duplicate(application.wheels.middleware) : [];
				_savedAllowCors = application.wheels.allowCorsRequests;
				_savedCacheModelConfig = application.wheels.cacheModelConfig;
				_savedCacheControllerConfig = application.wheels.cacheControllerConfig;
				_savedCacheDatabaseSchema = application.wheels.cacheDatabaseSchema;
				_savedMixins = application.wheels.mixins;
				_hadCgi = StructKeyExists(request, "cgi");
				_priorCgi = _hadCgi ? Duplicate(request.cgi) : {};
			});

			afterEach(() => {
				application.wheels.middleware = _savedMiddleware;
				application.wheels.allowCorsRequests = _savedAllowCors;
				application.wheels.cacheModelConfig = _savedCacheModelConfig;
				application.wheels.cacheControllerConfig = _savedCacheControllerConfig;
				application.wheels.cacheDatabaseSchema = _savedCacheDatabaseSchema;
				application.wheels.mixins = _savedMixins;
				if (_hadCgi) {
					request.cgi = _priorCgi;
				} else {
					StructDelete(request, "cgi");
				}
			});

			it("OPTIONS does not abort when a wheels.middleware.Cors instance is registered", () => {
				application.wheels.middleware = [
					new wheels.middleware.Cors(allowOrigins = "https://app.example")
				];
				application.wheels.allowCorsRequests = true;
				application.wheels.cacheModelConfig = true;
				application.wheels.cacheControllerConfig = true;
				application.wheels.cacheDatabaseSchema = true;
				application.wheels.mixins = {};
				if (!StructKeyExists(request, "cgi")) {
					request.cgi = {};
				}
				request.cgi.request_method = "OPTIONS";

				var em = CreateObject("component", "wheels.tests._assets.events.CorsArbitrationEventDouble").init();
				var state = {completed = false};
				em.$runOnRequestStart(targetPage = "/index.cfm");
				state.completed = true;

				expect(state.completed).toBeTrue(
					"$runOnRequestStart OPTIONS must skip abort when Cors middleware is active"
				);
				expect(em.corsHeaderCalls).toBe(
					0,
					"Cors-active skip must also defer $setCORSHeaders"
				);
			});

			it("live $runOnRequestStart still aborts OPTIONS when Cors middleware is not active", () => {
				var body = $functionBody("EventMethods.cfc", "$runOnRequestStart");
				expect(Find("!$corsMiddlewareActive()", body)).toBeGT(
					0,
					"$runOnRequestStart OPTIONS abort must stay gated on !$corsMiddlewareActive()"
				);
				expect(FindNoCase("request_method", body)).toBeGT(0);
				expect(FindNoCase("OPTIONS", body)).toBeGT(0);
				var abortPos = REFindNoCase("(^|[^.\w])abort\s*;", body);
				expect(abortPos).toBeGT(
					0,
					"HOLD: OPTIONS abort must remain (LuCLI poison leftover if flipped)"
				);
				var skipPos = Find("!$corsMiddlewareActive()", body);
				expect(abortPos).toBeGT(
					skipPos,
					"OPTIONS abort must sit after the Cors-active skip"
				);
			});

		});

		describe("S6 onapplicationstart writeLog catch-any swallow", () => {

			it("keeps the empty catch-any around the reloadPassword writeLog", () => {
				var src = FileRead(ExpandPath("/wheels/events/onapplicationstart.cfc"));
				var writeLogPos = FindNoCase('writeLog(file="wheels_security"', src);
				expect(writeLogPos).toBeGT(
					0,
					"onapplicationstart.cfc no longer writeLogs an empty reloadPassword warning"
				);
				var window = Mid(src, writeLogPos, 500);
				expect(Find("catch (any e)", window)).toBeGT(0);
				expect(FindNoCase("rethrow", window)).toBe(0);
				expect(FindNoCase("throw(", window)).toBe(0);
			});

		});

		describe("S7 wheelserror.cfm empty cfcatch keep-going", () => {

			it("keeps the empty cfcatch around the docs-link rewrite", () => {
				var src = FileRead(ExpandPath("/wheels/events/onerror/wheelserror.cfm"));
				// Concatenate so the CFML parser does not treat cf-tag text as tags.
				var emptyCatch = "<" & "cfcatch><" & "/cfcatch>";
				var rethrowTag = "<" & "cfrethrow";
				expect(FindNoCase("<" & "cfcatch>", src)).toBeGT(
					0,
					"wheelserror.cfm no longer has a cfcatch around the docs-link rewrite"
				);
				expect(FindNoCase(emptyCatch, src)).toBeGT(
					0,
					"wheelserror.cfm cfcatch must stay empty (keep-going, no rethrow)"
				);
				expect(FindNoCase(rethrowTag, src)).toBe(0);
			});

			it("still renders extendedInfo when the docs-link rewrite throws", () => {
				var wheelsError = {
					type = "Wheels.TestError",
					message = "s7-keep-going-message",
					extendedInfo = "s7-keep-going-marker-xyz",
					tagContext = [
						{template = "/tmp/a.cfm", line = 1},
						{template = "/tmp/b.cfm", line = 2}
					]
				};
				var hadCgi = StructKeyExists(request, "cgi");
				var priorCgi = hadCgi ? Duplicate(request.cgi) : {};
				var actual = "";
				var state = {threw = false, type = ""};
				try {
					// Force the docs-link ReReplace to throw (request.cgi.script_name).
					request.cgi = {};
					actual = application.wo.$includeAndReturnOutput(
						$template = "/wheels/events/onerror/wheelserror.cfm",
						wheelsError = wheelsError
					);
				} catch (any e) {
					state.threw = true;
					state.type = e.type;
				} finally {
					if (hadCgi) {
						request.cgi = priorCgi;
					} else {
						StructDelete(request, "cgi");
					}
				}
				expect(state.threw).toBeFalse(
					"wheelserror.cfm empty cfcatch must keep going (got #state.type#)"
				);
				expect(actual).toInclude("s7-keep-going-marker-xyz");
				expect(actual).toInclude("Wheels.TestError");
			});

		});

	}

	private any function $onErrorDouble() {
		var em = CreateObject("component", "wheels.tests._assets.events.OnErrorEventDouble").init();
		em.formatOverride = "json";
		return em;
	}

	private struct function $wheelsTypedException(required string wheelsType) {
		// Both engines: BoxLang reads exception.type, Lucee/Adobe read rootCause.type.
		return {
			type = arguments.wheelsType,
			message = arguments.wheelsType,
			rootCause = {
				type = arguments.wheelsType,
				message = arguments.wheelsType
			}
		};
	}

	private struct function $plainException() {
		return {
			type = "java.sql.SQLException",
			message = "full-exception-secret-detail",
			detail = "password=hunter2"
		};
	}

	/**
	 * Extracts one function body from an events/ CFC. Same line-scan shape as
	 * RequestStartPluginsConstructionSpec (no global comment-strip — that
	 * hangs Lucee 7 on large sources).
	 */
	private string function $functionBody(required string fileName, required string functionName) {
		var content = FileRead(ExpandPath("/wheels/events/#arguments.fileName#"));
		var fileLines = ListToArray(content, Chr(10), true);
		var declarationPattern = "(public|private)\s+\w+\s+function\s+";
		var lines = [];
		var inBody = false;
		var escapedName = Replace(Replace(arguments.functionName, "$", "\$", "all"), ".", "\.", "all");

		for (var rawLine in fileLines) {
			if (!inBody) {
				if (REFindNoCase(declarationPattern & escapedName & "\b", rawLine)) {
					inBody = true;
					ArrayAppend(lines, rawLine);
				}
				continue;
			}
			if (REFindNoCase(declarationPattern & "[\w$]+\s*\(", rawLine)) {
				break;
			}
			ArrayAppend(lines, rawLine);
		}

		expect(ArrayLen(lines)).toBeGT(
			0,
			"Could not locate #arguments.functionName# in events/#arguments.fileName#"
		);
		return ArrayToList(lines, Chr(10));
	}

}
