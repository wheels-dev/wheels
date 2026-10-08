/**
 * The token-gated jobs tick route (`/wheels/jobs/tick`). The token is the boundary, not the
 * client's address: off (404) without jobsRunnerToken, 403 without the right token or with a
 * forwarding header, the token in the X-Wheels-Jobs-Token header (the query string only with
 * jobsRunnerTokenInQuery = true), compared in constant time. Answered before routing and the
 * public-component gate.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("the jobs tick endpoint", function() {

			beforeEach(function() {
				new wheels.Job().$ensureJobTable();
				application.wheels.jobsRunnerToken = "spec-tick-token";
				application.wheels.jobsRunnerTokenInQuery = false;
			});

			afterEach(function() {
				application.wheels.jobsRunnerToken = "";
				application.wheels.jobsRunnerTokenInQuery = false;
			});

			it("recognises the route, with or without a trailing slash", function() {
				var endpoint = new wheels.JobTickEndpoint();
				expect(endpoint.isTickPath("/wheels/jobs/tick")).toBeTrue();
				expect(endpoint.isTickPath("/wheels/jobs/tick/")).toBeTrue();
				expect(endpoint.isTickPath("/WHEELS/Jobs/Tick")).toBeTrue();
				expect(endpoint.isTickPath("/wheels/jobs")).toBeFalse();
				expect(endpoint.isTickPath("/wheels/jobs/tickle")).toBeFalse();
			});

			it("doesn't exist without a token set", function() {
				application.wheels.jobsRunnerToken = "";
				var response = new wheels.JobTickEndpoint().handle(method = "GET", headers = {"X-Wheels-Jobs-Token" = "anything"});
				expect(response.status).toBe(404);
			});

			it("refuses a missing or wrong token", function() {
				var endpoint = new wheels.JobTickEndpoint();
				expect(endpoint.handle(method = "GET", headers = {}).status).toBe(403);
				expect(endpoint.handle(method = "GET", headers = {"X-Wheels-Jobs-Token" = "spec-tick-tokeN"}).status).toBe(403);
				expect(endpoint.handle(method = "GET", headers = {"X-Wheels-Jobs-Token" = "spec-tick-token-longer"}).status).toBe(403);
			});

			it("refuses a request that came through a proxy, whatever its token", function() {
				var endpoint = new wheels.JobTickEndpoint();
				for (var name in ["X-Forwarded-For", "Forwarded", "X-Real-IP", "CF-Connecting-IP"]) {
					var headers = {"X-Wheels-Jobs-Token" = "spec-tick-token"};
					headers[name] = "203.0.113.9";
					expect(endpoint.handle(method = "GET", headers = headers).status).toBe(403, name);
				}
				expect(endpoint.handle(method = "GET", headers = {"x-forwarded-for" = "203.0.113.9", "x-wheels-jobs-token" = "spec-tick-token"}).status).toBe(403, "header names in any case");
			});

			it("refuses any forwarding header by its presence, even empty, including Host and Proto alone", function() {
				var endpoint = new wheels.JobTickEndpoint();
				for (var name in ["X-Forwarded-Host", "X-Forwarded-Proto", "X-Forwarded-Port", "X-Forwarded-Prefix", "X-Client-IP", "True-Client-IP", "X-Cluster-Client-IP"]) {
					var headers = {"X-Wheels-Jobs-Token" = "spec-tick-token"};
					headers[name] = "example.test";
					expect(endpoint.handle(method = "GET", headers = headers).status).toBe(403, name);
				}
				expect(endpoint.handle(method = "GET", headers = {"X-Wheels-Jobs-Token" = "spec-tick-token", "X-Forwarded-For" = ""}).status).toBe(403, "an empty X-Forwarded-For");
				expect(endpoint.handle(method = "GET", headers = {"X-Wheels-Jobs-Token" = "spec-tick-token", "Forwarded" = ""}).status).toBe(403, "an empty Forwarded");
			});

			it("refuses a request it can't read, without running a tick", function() {
				var endpoint = new wheels.JobTickEndpoint();
				prepareMock(endpoint);
				endpoint.$(method = "$readHeaders", throwException = true, throwType = "Spec.Unreadable", throwMessage = "no request data");
				endpoint.$("$readMethod", "GET");
				endpoint.$("$runTick", {ok = true, ran = true});
				var response = endpoint.respond(urlScope = {});
				expect(response.status).toBe(500);
				expect(endpoint.$count("$runTick")).toBe(0);
			});

			it("reports a failed tick without its error details", function() {
				var endpoint = new wheels.JobTickEndpoint();
				prepareMock(endpoint);
				var runner = createStub();
				runner.$(method = "tick", throwException = true, throwType = "Spec.TickFailed", throwMessage = "secret detail at /srv/app/db.cfc");
				endpoint.$("$newRunner", runner);
				var result = endpoint.$runTick();
				expect(result.ok).toBeFalse();
				expect(result.error).toBe("tick failed");
				expect(Len(result.requestId)).toBeGT(0);
				expect(SerializeJSON(result)).notToInclude("secret");
			});

			it("accepts the token in the query string only when jobsRunnerTokenInQuery is true", function() {
				var endpoint = new wheels.JobTickEndpoint();
				expect(endpoint.handle(method = "GET", headers = {}, queryToken = "spec-tick-token").status).toBe(403);
				application.wheels.jobsRunnerTokenInQuery = true;
				expect(endpoint.handle(method = "GET", headers = {}, queryToken = "spec-tick-token").status).toBe(200);
			});

			it("answers only GET and POST", function() {
				var endpoint = new wheels.JobTickEndpoint();
				expect(endpoint.handle(method = "PUT", headers = {"X-Wheels-Jobs-Token" = "spec-tick-token"}).status).toBe(405);
				expect(endpoint.handle(method = "POST", headers = {"X-Wheels-Jobs-Token" = "spec-tick-token"}).status).toBe(200);
			});

			it("runs one tick and returns its summary as JSON", function() {
				var response = new wheels.JobTickEndpoint().handle(method = "GET", headers = {"X-Wheels-Jobs-Token" = "spec-tick-token"});
				expect(response.status).toBe(200);
				expect(response.contentType).toBe("application/json");
				var body = DeserializeJSON(response.body);
				expect(body.ok).toBeTrue();
				expect(body.host).toBe(new wheels.Job().$jobHostName());
				expect(StructKeyExists(body, "processed")).toBeTrue();
				expect(StructKeyExists(body, "durationMs")).toBeTrue();
			});

			it("compares tokens in full, whatever their length", function() {
				var endpoint = new wheels.JobTickEndpoint();
				expect(endpoint.$tokensMatch("abc", "abc")).toBeTrue();
				expect(endpoint.$tokensMatch("abd", "abc")).toBeFalse();
				expect(endpoint.$tokensMatch("ab", "abc")).toBeFalse();
				expect(endpoint.$tokensMatch("", "abc")).toBeFalse();
			});

			it("is answered by the dispatcher before routing, even with the public component off", function() {
				var savedPublic = application.wheels.enablePublicComponent;
				var savedMethod = request.cgi.request_method;
				application.wheels.enablePublicComponent = false;
				application.wheels.jobsRunnerTokenInQuery = true;
				request.cgi["request_method"] = "GET";
				var dispatcher = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");
				var body = "";
				try {
					body = dispatcher.$request(pathInfo = "/wheels/jobs/tick", scriptName = "", formScope = {}, urlScope = {token = "spec-tick-token"});
				} finally {
					application.wheels.enablePublicComponent = savedPublic;
					request.cgi["request_method"] = savedMethod;
				}
				expect(IsJSON(body)).toBeTrue(body);
				expect(DeserializeJSON(body).ok).toBeTrue();
			});

		});
	}

}
