/**
 * `--offline` (request.$wheelsOffline) must keep HttpClient.get() off the
 * network. Registry gated its own calls, but other callers (the upgrade
 * check's latest-release lookup) used get() directly and phoned home anyway.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("packages offline: HttpClient.get()", () => {

			beforeEach(() => {
				request.$wheelsOffline = true;
			});

			afterEach(() => {
				StructDelete(request, "$wheelsOffline");
			});

			it("refuses the request before any network access", () => {
				var thrown = {type = "", message = ""};
				try {
					new cli.lucli.services.packages.HttpClient().get("https://example.invalid/releases/latest");
				} catch (any e) {
					thrown.type = e.type;
					thrown.message = e.message;
				}
				expect(thrown.type).toBe("Wheels.Packages.Offline");
				expect(thrown.message).toInclude("--offline");
			});

			it("still sends the request when offline mode is off", () => {
				StructDelete(request, "$wheelsOffline");
				var thrown = {type = ""};
				try {
					new cli.lucli.services.packages.HttpClient(timeoutSeconds = 2).get("https://example.invalid/releases/latest");
				} catch (any e) {
					thrown.type = e.type;
				}
				// example.invalid never resolves: any failure here is the network attempt, not the offline gate.
				expect(thrown.type).notToBe("Wheels.Packages.Offline");
			});
		});
	}
}
