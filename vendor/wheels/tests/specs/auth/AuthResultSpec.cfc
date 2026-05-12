component extends="wheels.WheelsTest" {

	function run() {

		describe("AuthResult factory", function() {

			beforeEach(function() {
				factory = new wheels.auth.AuthResult();
			});

			describe("success()", function() {

				it("returns a success struct with the given principal", function() {
					var result = factory.success(principal = {id = 42, role = "admin"}, strategy = "token");

					expect(result.success).toBeTrue();
					expect(result.principal.id).toBe(42);
					expect(result.principal.role).toBe("admin");
					expect(result.strategy).toBe("token");
					expect(result.error).toBe("");
					expect(result.statusCode).toBe(200);
				});

				it("defaults strategy to empty string", function() {
					var result = factory.success(principal = {id = 1});

					expect(result.strategy).toBe("");
				});

			});

			describe("failure()", function() {

				it("returns a failure struct with the given error", function() {
					var result = factory.failure(error = "Token expired", statusCode = 401, strategy = "jwt");

					expect(result.success).toBeFalse();
					expect(StructIsEmpty(result.principal)).toBeTrue();
					expect(result.strategy).toBe("jwt");
					expect(result.error).toBe("Token expired");
					expect(result.statusCode).toBe(401);
				});

				it("defaults to 401 status and generic message", function() {
					var result = factory.failure();

					expect(result.statusCode).toBe(401);
					expect(result.error).toBe("Authentication failed");
				});

				it("supports 403 forbidden status", function() {
					var result = factory.failure(error = "Insufficient permissions", statusCode = 403);

					expect(result.statusCode).toBe(403);
				});

			});

		});

	}

}
