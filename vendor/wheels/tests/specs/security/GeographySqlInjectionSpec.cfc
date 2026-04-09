component extends="wheels.WheelsTest" {

	function run() {

		describe("Geography/WKT SQL injection prevention", () => {

			beforeEach(() => {
				misc = new wheels.model.miscellaneous();
			});

			describe("$sanitizeWktValue", () => {

				it("strips SQL injection payloads from coordinate values", () => {
					var malicious = "1 2); DROP TABLE users; --";
					var sanitized = misc.$sanitizeWktValue(malicious);
					expect(sanitized).notToInclude("DROP");
					expect(sanitized).notToInclude("TABLE");
					expect(sanitized).notToInclude("users");
					expect(sanitized).notToInclude(";");
					// Note: -- passes through since - is valid in coordinates like -122.4
					// The protection is that ; is stripped, breaking SQL comment syntax
				});

				it("strips single-quote based injection attempts", () => {
					var malicious = "1 2' OR '1'='1";
					var sanitized = misc.$sanitizeWktValue(malicious);
					expect(sanitized).notToInclude("'");
					expect(sanitized).notToInclude("OR");
				});

				it("strips UNION SELECT injection payloads", () => {
					var malicious = "1 2) UNION SELECT password FROM users --";
					var sanitized = misc.$sanitizeWktValue(malicious);
					expect(sanitized).notToInclude("UNION");
					expect(sanitized).notToInclude("SELECT");
					expect(sanitized).notToInclude("password");
					expect(sanitized).notToInclude("FROM");
				});

				it("preserves valid POINT coordinates", () => {
					var coords = "-122.4194 37.7749";
					var sanitized = misc.$sanitizeWktValue(coords);
					expect(sanitized).toBe("-122.4194 37.7749");
				});

				it("preserves valid POLYGON coordinates with parentheses", () => {
					var coords = "(0 0, 1 0, 1 1, 0 1, 0 0)";
					var sanitized = misc.$sanitizeWktValue(coords);
					expect(sanitized).toBe("(0 0, 1 0, 1 1, 0 1, 0 0)");
				});

				it("preserves valid MULTIPOLYGON coordinates with nested parentheses", () => {
					var coords = "((0 0, 1 0, 1 1, 0 0)),((2 2, 3 2, 3 3, 2 2))";
					var sanitized = misc.$sanitizeWktValue(coords);
					expect(sanitized).toBe("((0 0, 1 0, 1 1, 0 0)),((2 2, 3 2, 3 3, 2 2))");
				});

				it("preserves negative coordinates and decimals", () => {
					var coords = "-73.9857 40.7484, -73.9851 40.7490";
					var sanitized = misc.$sanitizeWktValue(coords);
					expect(sanitized).toBe("-73.9857 40.7484, -73.9851 40.7490");
				});

				it("returns empty string for purely malicious input", () => {
					var malicious = "DELETE FROM geography_columns";
					var sanitized = misc.$sanitizeWktValue(malicious);
					expect(sanitized).notToInclude("DELETE");
					expect(sanitized).notToInclude("FROM");
					expect(Trim(sanitized)).toBe("");
				});

			});

		});

	}

}
