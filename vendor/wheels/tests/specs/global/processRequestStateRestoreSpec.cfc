/**
 * processRequest() changes several pieces of global / request state on the way in — the request
 * method (for a non-GET call), the transaction mode (with rollback=true), and the sendEmail / sendFile
 * deliver flags — and must restore them on EVERY exit, including when the action throws and the spec
 * catches it. If the restore only ran on the success path, a caught throw would leak the changed state
 * into every later spec in the same run (e.g. request.cgi.request_method stays "post", so a later
 * redirectTo() answers 303 instead of 302). Reported by a downstream app.
 *
 * This pins the restore: call processRequest() on an action that throws, with method="post" and
 * rollback=true, catch it, then assert the method, transaction mode and both deliver flags are back to
 * their prior values.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("processRequest() restores global and request state when the action throws", () => {

			it("restores request_method, transactionMode and the deliver flags after a thrown POST", () => {
				var wo = application.wo;
				var before = {
					method = (StructKeyExists(request, "cgi") && StructKeyExists(request.cgi, "request_method")) ? request.cgi.request_method : "get",
					txMode = wo.$get("transactionMode"),
					email = wo.$get(functionName = "sendEmail", name = "deliver"),
					file = wo.$get(functionName = "sendFile", name = "deliver")
				};

				// struct field so the write survives the catch on BoxLang (cross-engine invariant 11)
				var state = {threw = false};
				try {
					wo.processRequest(
						params = {controller = "ProcessRequestProbe", action = "boom"},
						method = "post",
						rollback = true,
						returnAs = "struct"
					);
				} catch (any e) {
					state.threw = true;
				}

				expect(state.threw).toBeTrue("the probe action should have thrown");
				expect(request.cgi.request_method).toBe(before.method, "request_method leaked after a thrown processRequest()");
				expect(wo.$get("transactionMode")).toBe(before.txMode, "transactionMode leaked after a thrown processRequest()");
				expect(wo.$get(functionName = "sendEmail", name = "deliver")).toBe(before.email, "sendEmail deliver flag leaked");
				expect(wo.$get(functionName = "sendFile", name = "deliver")).toBe(before.file, "sendFile deliver flag leaked");
			});

			it("restores the PREVIOUS request method exactly, not a hard-coded GET", () => {
				// The runner's own method is GET, and toBe compares strings case-insensitively, so a
				// restore that just writes "get" back would pass the case above. Set a non-GET prior
				// method and assert it comes back exactly (case-sensitive Compare) — this is also the
				// nested-call semantics in miniature. Reset it afterwards so this spec can't leak.
				var wo = application.wo;
				var original = (StructKeyExists(request, "cgi") && StructKeyExists(request.cgi, "request_method")) ? request.cgi.request_method : "get";
				request.cgi.request_method = "put";
				var state = {threw = false};
				try {
					try {
						wo.processRequest(
							params = {controller = "ProcessRequestProbe", action = "boom"},
							method = "post",
							rollback = true,
							returnAs = "struct"
						);
					} catch (any e) {
						state.threw = true;
					}
					expect(state.threw).toBeTrue("the probe action should have thrown");
					expect(Compare(request.cgi.request_method, "put")).toBe(
						0,
						"processRequest() must restore the previous method exactly ('put'), not a hard-coded 'get'"
					);
				} finally {
					request.cgi.request_method = original;
				}
			});

			it("a GET redirect answers 302 after a caught POST whose action threw", () => {
				// The reported symptom, end to end: if the caught POST leaked request_method = post, the
				// later GET redirect would be upgraded to 303. With the method restored it is 302.
				var wo = application.wo;
				var state = {threw = false};
				try {
					wo.processRequest(
						params = {controller = "ProcessRequestProbe", action = "boom"},
						method = "post",
						returnAs = "struct"
					);
				} catch (any e) {
					state.threw = true;
				}
				expect(state.threw).toBeTrue("the probe action should have thrown");

				var result = wo.processRequest(
					params = {controller = "ProcessRequestProbe", action = "goHome"},
					method = "get",
					returnAs = "struct"
				);
				expect(result.status).toBe(
					302,
					"a GET redirect after a caught POST should answer 302, not 303 from a leaked POST method"
				);
			});

		});

	}

}
