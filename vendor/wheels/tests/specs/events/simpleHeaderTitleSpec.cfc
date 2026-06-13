component extends="wheels.WheelsTest" {

	function run() {

		// GH #3175: the shared _header_simple.cfm hardcoded <title>Wheels - Error</title>.
		// That header is included by BOTH the error screen (EventMethods.$runOnError)
		// AND the congratulations/welcome page (Public.index → congratulations.cfm),
		// so a brand-new user's first browser tab read "Error". The header now reads
		// an optional request.wheels.simpleHeaderTitle override and falls back to the
		// error title when it isn't set.
		describe("_header_simple.cfm <title>", () => {

			it("defaults to 'Wheels - Error' when no override is set (error screen)", () => {
				var hadOverride = StructKeyExists(request, "wheels")
					&& IsStruct(request.wheels)
					&& StructKeyExists(request.wheels, "simpleHeaderTitle");
				var prior = hadOverride ? request.wheels.simpleHeaderTitle : "";
				try {
					if (StructKeyExists(request, "wheels") && IsStruct(request.wheels)) {
						StructDelete(request.wheels, "simpleHeaderTitle");
					}
					var actual = application.wo.$includeAndReturnOutput(
						$template = "/wheels/public/layout/_header_simple.cfm"
					);
					expect(actual).toInclude("<title>Wheels - Error</title>");
				} finally {
					if (hadOverride) {
						request.wheels.simpleHeaderTitle = prior;
					} else if (StructKeyExists(request, "wheels") && IsStruct(request.wheels)) {
						StructDelete(request.wheels, "simpleHeaderTitle");
					}
				}
			});

			it("uses request.wheels.simpleHeaderTitle when the including page sets it (welcome page)", () => {
				var hadOverride = StructKeyExists(request, "wheels")
					&& IsStruct(request.wheels)
					&& StructKeyExists(request.wheels, "simpleHeaderTitle");
				var prior = hadOverride ? request.wheels.simpleHeaderTitle : "";
				try {
					if (!StructKeyExists(request, "wheels") || !IsStruct(request.wheels)) {
						request.wheels = {};
					}
					request.wheels.simpleHeaderTitle = "Welcome to Wheels";
					var actual = application.wo.$includeAndReturnOutput(
						$template = "/wheels/public/layout/_header_simple.cfm"
					);
					expect(actual).toInclude("<title>Welcome to Wheels</title>");
					// And critically: the welcome page no longer says "Error".
					expect(actual).notToInclude("<title>Wheels - Error</title>");
				} finally {
					if (hadOverride) {
						request.wheels.simpleHeaderTitle = prior;
					} else if (StructKeyExists(request, "wheels") && IsStruct(request.wheels)) {
						StructDelete(request.wheels, "simpleHeaderTitle");
					}
				}
			});

			it("falls back to the error title when the override is an empty string", () => {
				var hadOverride = StructKeyExists(request, "wheels")
					&& IsStruct(request.wheels)
					&& StructKeyExists(request.wheels, "simpleHeaderTitle");
				var prior = hadOverride ? request.wheels.simpleHeaderTitle : "";
				try {
					if (!StructKeyExists(request, "wheels") || !IsStruct(request.wheels)) {
						request.wheels = {};
					}
					request.wheels.simpleHeaderTitle = "";
					var actual = application.wo.$includeAndReturnOutput(
						$template = "/wheels/public/layout/_header_simple.cfm"
					);
					expect(actual).toInclude("<title>Wheels - Error</title>");
				} finally {
					if (hadOverride) {
						request.wheels.simpleHeaderTitle = prior;
					} else if (StructKeyExists(request, "wheels") && IsStruct(request.wheels)) {
						StructDelete(request.wheels, "simpleHeaderTitle");
					}
				}
			});
		});
	}
}
