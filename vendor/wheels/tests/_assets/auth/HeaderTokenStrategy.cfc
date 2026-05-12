/**
 * Test strategy that checks for a specific header token.
 * Supports the request only when an Authorization header is present.
 */
component implements="wheels.auth.AuthStrategy" output="false" {

	public HeaderTokenStrategy function init(string validToken = "secret-123") {
		variables.validToken = arguments.validToken;
		return this;
	}

	public string function getName() {
		return "headerToken";
	}

	public boolean function supports(required struct request) {
		return StructKeyExists(arguments.request, "headers")
			&& StructKeyExists(arguments.request.headers, "authorization");
	}

	public struct function authenticate(required struct request) {
		local.token = arguments.request.headers.authorization;

		// Strip "Bearer " prefix if present
		if (Left(local.token, 7) == "Bearer ") {
			local.token = Mid(local.token, 8, Len(local.token) - 7);
		}

		if (local.token == variables.validToken) {
			return {
				success = true,
				principal = {id = 42, role = "user", token = local.token},
				strategy = getName(),
				error = "",
				statusCode = 200
			};
		}

		return {
			success = false,
			principal = {},
			strategy = getName(),
			error = "Invalid token",
			statusCode = 401
		};
	}

}
