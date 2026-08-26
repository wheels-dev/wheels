/**
 * Dispatch / Public hardener proofs for desk IDs S2, S3, S6, S7, S8.
 * HOLD pins stay unflipped. Spec-only.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("S2 $parseJsonBody current branches", () => {

			beforeEach(() => {
				dispatch = CreateObject("component", "wheels.Dispatch")
				_hadHttpData = StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "httpRequestData")
				_priorHttpData = _hadHttpData ? request.wheels.httpRequestData : {}
			})

			afterEach(() => {
				if (_hadHttpData) {
					request.wheels.httpRequestData = _priorHttpData
				} else if (StructKeyExists(request, "wheels")) {
					StructDelete(request.wheels, "httpRequestData")
				}
			})

			it("S2: existing form keys win over JSON (StructAppend overwrite false)", () => {
				request.wheels.httpRequestData = {
					headers = {"Content-Type" = "application/json"},
					content = '{"title":"from-json","body":"json-only"}'
				}
				var result = dispatch.$parseJsonBody(params = {title = "from-form", extra = "keep"})

				expect(result.title).toBe("from-form")
				expect(result.body).toBe("json-only")
				expect(result.extra).toBe("keep")
			})

			it("S2: application/*+json content type is treated as JSON", () => {
				request.wheels.httpRequestData = {
					headers = {"Content-Type" = "application/vnd.api+json; charset=utf-8"},
					content = '{"tag":"plus-json"}'
				}
				var result = dispatch.$parseJsonBody(params = {})

				expect(result.tag).toBe("plus-json")
			})

			it("S2: array root is accepted on the _json key", () => {
				request.wheels.httpRequestData = {
					headers = {"Content-Type" = "application/json"},
					content = '["alpha","beta"]'
				}
				var result = dispatch.$parseJsonBody(params = {keep = "me"})

				expect(result.keep).toBe("me")
				expect(result).toHaveKey("_json")
				expect(result._json).toBeArray()
				expect(ArrayLen(result._json)).toBe(2)
				expect(result._json[1]).toBe("alpha")
				expect(result._json[2]).toBe("beta")
			})

			it("S2: invalid JSON is ignored and does not throw", () => {
				request.wheels.httpRequestData = {
					headers = {"Content-Type" = "application/json"},
					content = "{not-valid-json"
				}
				var threw = {flag = false}
				var result = {}
				try {
					result = dispatch.$parseJsonBody(params = {keep = "me"})
				} catch (any e) {
					threw.flag = true
				}

				expect(threw.flag).toBeFalse()
				expect(result.keep).toBe("me")
				expect(result).notToHaveKey("_json")
			})
		})

		describe("S3 $getPathFromRequest collapse to empty string", () => {

			beforeEach(() => {
				dispatch = CreateObject("component", "wheels.Dispatch")
			})

			it("S3: pathInfo equal to scriptName collapses to empty string", () => {
				expect(dispatch.$getPathFromRequest(pathInfo = "/index.cfm", scriptName = "/index.cfm")).toBe("")
			})

			it("S3: a lone slash collapses to empty string", () => {
				expect(dispatch.$getPathFromRequest(pathInfo = "/", scriptName = "/index.cfm")).toBe("")
			})

			it("S3: empty pathInfo collapses to empty string", () => {
				expect(dispatch.$getPathFromRequest(pathInfo = "", scriptName = "/index.cfm")).toBe("")
			})

			it("S3: a real path still drops only the leading slash", () => {
				expect(dispatch.$getPathFromRequest(pathInfo = "/users", scriptName = "/index.cfm")).toBe("users")
			})
		})

		describe("S6 $deobfuscateParams catch swallow", () => {

			beforeEach(() => {
				dispatch = CreateObject("component", "wheels.Dispatch")
				_priorObfuscate = application.wheels.obfuscateUrls
				application.wheels.obfuscateUrls = true
			})

			afterEach(() => {
				application.wheels.obfuscateUrls = _priorObfuscate
			})

			it("S6: a bad obfuscated value does not throw and the param survives", () => {
				var params = {controller = "users", action = "show", key = "not-valid-obf"}
				var threw = {flag = false}
				var result = {}
				try {
					result = dispatch.$deobfuscateParams(params = params)
				} catch (any e) {
					threw.flag = true
				}

				expect(threw.flag).toBeFalse()
				expect(result.key).toBe("not-valid-obf")
				expect(result.controller).toBe("users")
				expect(result.action).toBe("show")
			})

			it("S6: a non-string param does not throw and the value survives", () => {
				var nested = {inner = "keep-me"}
				var params = {controller = "users", action = "show", key = nested}
				var threw = {flag = false}
				var result = {}
				try {
					result = dispatch.$deobfuscateParams(params = params)
				} catch (any e) {
					threw.flag = true
				}

				expect(threw.flag).toBeFalse()
				expect(result.key.inner).toBe("keep-me")
			})

			it("S6: a valid obfuscated value still deobfuscates when the setting is on", () => {
				var result = dispatch.$deobfuscateParams(params = {controller = "users", action = "show", key = "9b1c6"})

				expect(result.key).toBe("1")
			})
		})

		describe("S7 $$findMatchingRoutes HEAD to GET and live regex write", () => {

			beforeEach(() => {
				_originalRoutes = Duplicate(application.wheels.routes)
				application.wheels.routes = [
					{
						pattern = "s7headget",
						methods = "GET",
						controller = "s7",
						action = "index",
						name = "s7headget"
					},
					{
						pattern = "s7postonly",
						methods = "POST",
						controller = "s7",
						action = "create",
						name = "s7postonly"
					}
				]
				publicCfc = CreateObject("component", "wheels.Public").$init()
				publicCfc.$scanAndPromoteIncludedGlobals()
			})

			afterEach(() => {
				application.wheels.routes = _originalRoutes
			})

			it("S7: HEAD requests match GET routes", () => {
				var result = publicCfc.$$findMatchingRoutes(path = "s7headget", requestMethod = "HEAD")

				expect(ArrayLen(result.errors)).toBe(0)
				expect(ArrayLen(result.matches)).toBe(1)
				expect(result.matches[1].name).toBe("s7headget")
				expect(result.matches[1].methods).toBe("GET")
			})

			it("S7: HEAD does not match a POST-only route", () => {
				var result = publicCfc.$$findMatchingRoutes(path = "s7postonly", requestMethod = "HEAD")

				expect(ArrayLen(result.matches)).toBe(0)
				expect(ArrayLen(result.errors)).toBeGT(0)
			})

			it("S7: pins the live .regex write on application.wheels.routes", () => {
				expect(application.wheels.routes[1]).notToHaveKey("regex")
				publicCfc.$$findMatchingRoutes(path = "s7headget", requestMethod = "GET")
				expect(application.wheels.routes[1]).toHaveKey("regex")
				expect(Len(application.wheels.routes[1].regex)).toBeGT(0)
			})
		})

		describe("S8 HOLD $safeApplicationMetadata whitelist and $resolveDocFormat fallback", () => {

			beforeEach(() => {
				publicCfc = CreateObject("component", "wheels.Public").$init()
			})

			it("S8 HOLD: whitelist is the six current keys and is not widened", () => {
				var fakeMeta = {
					applicationTimeout = 1,
					mappings = {wheels = "/wheels"},
					name = "s8-app",
					sessionManagement = true,
					sessionTimeout = 2,
					setClientCookies = false,
					datasources = {main = {password = "s8-secret"}},
					ormsettings = {dbcreate = "update"},
					extraKey = "must-drop"
				}
				var safe = publicCfc.$safeApplicationMetadata(fakeMeta)

				expect(StructCount(safe)).toBe(6)
				expect(safe).toHaveKey("applicationTimeout")
				expect(safe).toHaveKey("mappings")
				expect(safe).toHaveKey("name")
				expect(safe).toHaveKey("sessionManagement")
				expect(safe).toHaveKey("sessionTimeout")
				expect(safe).toHaveKey("setClientCookies")
				expect(safe.name).toBe("s8-app")
				expect(safe).notToHaveKey("datasources")
				expect(safe).notToHaveKey("ormsettings")
				expect(safe).notToHaveKey("extraKey")
			})

			it("S8 HOLD: $resolveDocFormat falls back to html and does not change that default", () => {
				expect(publicCfc.$resolveDocFormat("html")).toBe("html")
				expect(publicCfc.$resolveDocFormat("json")).toBe("json")
				expect(publicCfc.$resolveDocFormat("")).toBe("html")
				expect(publicCfc.$resolveDocFormat("../views/info")).toBe("html")
				expect(publicCfc.$resolveDocFormat("html.cfm")).toBe("html")
			})
		})
	}

}
