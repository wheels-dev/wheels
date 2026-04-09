/**
 * Tests that CORS security defaults are safe (deny-all, not wildcard).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("CORS security defaults", () => {

			it("defaults accessControlAllowOrigin to empty string not wildcard", () => {
				expect(application.wheels.accessControlAllowOrigin).toBe("");
			});

			it("defaults allowCorsRequests to false", () => {
				expect(application.wheels.allowCorsRequests).toBeFalse();
			});

		});

	}

}
