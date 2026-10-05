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

		});

	}

}
