component extends="wheels.WheelsTest" {

	function run() {

		describe("Tests that onerror", () => {

			it("cfmlerror shows wheels templates", () => {
				try {
					Throw(type = "UnitTestError")
				} catch (any e) {
					exception = e
				}

				actual = application.wo.$includeAndReturnOutput($template = "/wheels/events/onerror/cfmlerror.cfm", exception = exception)

				// Check filename without path separators (EncodeForHTML encodes "/" on Adobe/BoxLang)
				// and without :line suffix (template and line number are in separate HTML elements)
				expect(actual).toInclude("onerrorSpec.cfc")
			})

			// Regression coverage for GH ##2319: Wheels-typed errors rendered
			// in HTML format used to leave the status code at Lucee's default
			// (200), misleading anything monitoring/alerting/retrying on
			// status. The mapping below is the frozen contract. A helper that
			// only reimplements the regex would stay green if the LIVE map
			// flipped — EventsHardenerSpec S2 proves the same types against
			// $runOnError and a source-scan of EventMethods.cfc. Do not flip
			// the live status map.
			it("maps Wheels.RouteNotFound to HTTP 404 (##2319)", () => {
				expect($expectedStatusFor("Wheels.RouteNotFound")).toBe(404)
			})

			it("maps Wheels.RecordNotFound to HTTP 404 (##2319)", () => {
				expect($expectedStatusFor("Wheels.RecordNotFound")).toBe(404)
			})

			it("maps Wheels.ViewNotFound to HTTP 404 (##2319)", () => {
				expect($expectedStatusFor("Wheels.ViewNotFound")).toBe(404)
			})

			// sendFile() usually serves a client-addressed download route, so a
			// missing file is the client's "not found". A missing image file used by
			// imageTag is a server-side asset fault and stays 500.
			it("maps Wheels.FileNotFound (sendFile) to HTTP 404", () => {
				expect($expectedStatusFor("Wheels.FileNotFound")).toBe(404)
			})

			it("keeps Wheels.ImageFileNotFound at HTTP 500 (server-side asset)", () => {
				expect($expectedStatusFor("Wheels.ImageFileNotFound")).toBe(500)
			})

			// A-F4 allow-list: the 404 set is now client-URL-triggerable types only
			// (route/record/view/action). A missing package is a server-side
			// config/code fault, so it is 500 — as is any other non-client *NotFound
			// (Model/Method/Filter/Association/Vite*/JobClass/…), including future
			// types, which default to 500. (This reverses the earlier "any *NotFound
			// -> 404" rule.)
			it("maps Wheels.PackageNotFound to HTTP 500 (server-side, not client-triggerable)", () => {
				expect($expectedStatusFor("Wheels.PackageNotFound")).toBe(500)
			})

			it("maps Wheels.ModelNotFound to HTTP 500 (server-side)", () => {
				expect($expectedStatusFor("Wheels.ModelNotFound")).toBe(500)
			})

			it("maps Wheels.ViteManifestNotFound to HTTP 500 (server-side; allow-list defaults it)", () => {
				expect($expectedStatusFor("Wheels.ViteManifestNotFound")).toBe(500)
			})

			it("maps a future Wheels.SomethingNotFound to HTTP 500 by default (allow-list)", () => {
				expect($expectedStatusFor("Wheels.SomethingNotFound")).toBe(500)
			})

			it("maps Wheels.FormatNotAcceptable to HTTP 406 (##3866)", () => {
				expect($expectedStatusFor("Wheels.FormatNotAcceptable")).toBe(406)
			})

			// A-F4: a missing datasource, table or column is a misconfigured or
			// unmigrated deploy — a SERVER fault, not a client "page not found".
			// Serving 404 for these hid an unmigrated deploy (TableNotFound) and
			// a bad datasource from monitoring. They are now 500. (This reverses
			// the earlier "404 is the more honest status" choice for
			// DataSourceNotFound.)
			it("maps Wheels.DataSourceNotFound to HTTP 500 (server misconfig, A-F4)", () => {
				expect($expectedStatusFor("Wheels.DataSourceNotFound")).toBe(500)
			})

			it("maps Wheels.TableNotFound to HTTP 500 (unmigrated deploy, A-F4)", () => {
				expect($expectedStatusFor("Wheels.TableNotFound")).toBe(500)
			})

			it("maps Wheels.ColumnNotFound to HTTP 500 (schema mismatch, A-F4)", () => {
				expect($expectedStatusFor("Wheels.ColumnNotFound")).toBe(500)
			})

			// A-F7: a missing or invalid CSRF token is a client error (a forged or
			// expired-form post), not a server error — monitoring must not count it
			// as a 500.
			it("maps Wheels.InvalidAuthenticityToken to HTTP 403 (A-F7)", () => {
				expect($expectedStatusFor("Wheels.InvalidAuthenticityToken")).toBe(403)
			})

			// GH ##3075: the action-dispatch gate ($callAction) blocks framework
			// helpers and $-prefixed internals by throwing Wheels.ActionNotAllowed.
			// #2845 and CLAUDE.md Anti-Pattern 8 promise that resolves to a 404,
			// but the *NotFound-only regex sent it to 500. ActionNotAllowed is now
			// an explicit member of the 404 set alongside the *NotFound family.
			it("maps Wheels.ActionNotAllowed to HTTP 404 (##3075)", () => {
				expect($expectedStatusFor("Wheels.ActionNotAllowed")).toBe(404)
			})

			// GH ##3156: policy denials from the authorization layer throw
			// Wheels.NotAuthorized, which must surface as 403 — the same wiring
			// pattern that maps the *NotFound family to 404.
			it("maps Wheels.NotAuthorized to HTTP 403 (##3156)", () => {
				expect($expectedStatusFor("Wheels.NotAuthorized")).toBe(403)
			})

			it("maps Wheels.Policy.NotDefined to HTTP 500 (a programmer error, not a denial, ##3156)", () => {
				expect($expectedStatusFor("Wheels.Policy.NotDefined")).toBe(500)
			})

			it("maps a generic Wheels error type to HTTP 500 (##2319)", () => {
				expect($expectedStatusFor("Wheels.UnknownThingHappened")).toBe(500)
			})

			// Thrown only at Dispatch.cfc:415 — a /wheels/ GUI request that resolves
			// to controller=wheels with a null/empty action. Client-triggerable
			// (a dev-GUI URL that names no action), so it is "no such page" -> 404,
			// not a 500 server error. (Reverses the earlier "Missing != NotFound".)
			it("maps Wheels.ActionParameterMissing to HTTP 404 (client-triggerable dev-GUI URL)", () => {
				expect($expectedStatusFor("Wheels.ActionParameterMissing")).toBe(404)
			})
		})

		// Security regression: $getRequestFormat must reject non-alphanumeric url.format (LFI via $runOnError's error-template include path).
		describe("$getRequestFormat rejects unsafe format tokens (T4 LFI)", () => {

			it("coerces ../ traversal tokens to html", () => {
				expect($requestFormatFor("../../../wheels/public/layout/_header_simple")).toBe("html")
			})

			it("coerces tokens containing a slash or dot to html", () => {
				expect($requestFormatFor("onerror.cfm/../x")).toBe("html")
			})

			it("preserves a valid alphanumeric format", () => {
				expect($requestFormatFor("json")).toBe("json")
			})

			it("preserves another valid format", () => {
				expect($requestFormatFor("xml")).toBe("xml")
			})

			it("falls back to html for an empty format", () => {
				expect($requestFormatFor("")).toBe("html")
			})
		})
	}

	private string function $requestFormatFor(required string formatValue) {
		var em = CreateObject("component", "wheels.events.EventMethods")
		var hadFormat = StructKeyExists(url, "format")
		var prior = hadFormat ? url.format : ""
		var result = ""
		try {
			url.format = arguments.formatValue
			result = em.$getRequestFormat()
		} finally {
			if (hadFormat) {
				url.format = prior
			} else {
				StructDelete(url, "format")
			}
		}
		return result
	}

	private numeric function $expectedStatusFor(required string wheelsType) {
		// Exercise the real mapping (single source of truth) rather than a mirror.
		var em = CreateObject("component", "wheels.events.EventMethods")
		return em.$wheelsErrorStatusCode(arguments.wheelsType)
	}
}